
local _, sm = ...
sm.Buttons = {}

local parent = sm.Core
local mod = sm.Buttons
local L = sm.L

local Shape, db, moving, ButtonFadeOut

local animFrames = {}
local blizzButtons = {
	GameTimeFrame = L["Calendar"],
	MiniMapTracking = L["Tracking Button"],
	MinimapZoneTextButton = L["Zone Text"],
	MinimapZoomIn = L["Zoom In Button"],
	MinimapZoomOut = L["Zoom Out Button"],
	MiniMapWorldMapButton = L["Map Button"],
	TimeManagerClockButton = L["Clock"],
}
local dynamicButtons = {
	GuildInstanceDifficulty = L["Guild Dungeon Difficulty Indicator (When Available)"],
	MiniMapChallengeMode = L["Challenge Mode Button (When Available)"],
	MiniMapInstanceDifficulty = L["Dungeon Difficulty Indicator (When Available)"],
	MiniMapMailFrame = L["New Mail Indicator (When Available)"],
	MiniMapRecordingButton = L["Video Recording Button (Mac OSX Only, When Available)"],
	MiniMapVoiceChatFrame = L["Voice Chat Button (When Available)"],
	QueueStatusMinimapButton = L["Queue Status Button (When Available)"],

	MiniMapBattlefieldFrame = "PVP", -- XXX mop temp
	MiniMapLFGFrame = "LFG", -- XXX mop temp
}

local options = {
	type = "group",
	name = L["Buttons"],
	childGroups = "tab",
	args = {
		custom = {
			type = "group",
			name = L["Addon Buttons"],
			disabled = function()
				return not db.controlVisibility
			end,
			args = {},
			order = 3,
		},
		dynamic = {
			type = "group",
			name = L["Dynamic Buttons"],
			disabled = function()
				return not db.controlVisibility
			end,
			args = {},
			order = 2,
		},
		stock = {
			type = "group",
			disabled = function()
				return not db.controlVisibility
			end,
			name = L["Standard Buttons"],
			args = {},
			order = 1,
		},
		enableDragging = {
			type = "toggle",
			name = L["Let SexyMap handle button dragging"],
			desc = L["Allow SexyMap to assume drag ownership for buttons attached to the minimap. Turn this off if you have another mod that you want to use to position your minimap buttons."],
			width = "double",
			order = 101,
			get = function()
				return db.allowDragging
			end,
			set = function(info, v)
				db.allowDragging = v
				if v then mod:UpdateDraggables() end
			end
		},
		lockDragging = {
			type = "toggle",
			name = L["Lock Button Dragging"],
			order = 102,
			disabled = function()
				return not db.allowDragging
			end,
			get = function()
				return db.lockDragging
			end,
			set = function(info, v)
				db.lockDragging = v
			end
		},
		dragRadius = {
			type = "range",
			name = L["Drag Radius"],
			min = -30,
			max = 100,
			step = 1,
			bigStep = 1,
			order = 103,
			disabled = function()
				return not db.allowDragging
			end,
			get = function()
				return db.radius
			end,
			set = function(info, v)
				db.radius = v
				mod:UpdateDraggables()
			end
		},
		visSpacer = {
			order = 104,
			type = "header",
			name = L["Visibility"],
		},
		controlVisibility = {
			type = "toggle",
			name = L["Let SexyMap control button visibility"],
			desc = L["Turn this off if you want another mod to handle which buttons are visible on the minimap."],
			width = "full",
			order = 105,
			get = function()
				return db.controlVisibility
			end,
			set = function(info, v)
				db.controlVisibility = v
				for _,f in pairs(animFrames) do
					if not v then
						mod:ChangeFrameVisibility(f, "always")
					else
						mod:ChangeFrameVisibility(f, db.visibilitySettings[f:GetName()] or "hover")
					end
				end
			end
		},
	}
}

do
	local hideValues = {
		["always"] = L["Always"],
		["never"] = L["Never"],
		["hover"] = L["On Hover"],
	}
	local dynamicValues = {
		["always"] = L["Always"],
		["hover"] = L["On Hover"],
	}

	local function hideGet(info, v)
		return (db.visibilitySettings[info[#info]] or "hover") == v
	end

	local function hideSet(info, v)
		local name = info[#info]
		db.visibilitySettings[name] = v
		mod:ChangeFrameVisibility(_G[name], v)
	end

	function mod:AddButtonOptions(name, blizzIcon, dynamic)
		local p
		if blizzIcon then
			p = options.args.stock.args -- Blizz icon = stock section
		elseif dynamic then
			p = options.args.dynamic.args -- Blizz dynamic (off by default) icon = dynamic section
		else
			p = options.args.custom.args -- Addon icon = custom section
		end
		p[name] = {
			type = "multiselect",
			name = L["Show %s:"]:format(blizzButtons[name] or dynamicButtons[name] or name:gsub("LibDBIcon10_", "")),
			values = dynamic and dynamicValues or hideValues,
			get = hideGet,
			set = hideSet,
		}
	end
end

function mod:OnEnable()
	local defaults = {
		profile = {
			radius = 10,
			dragPositions = {},
			visibilitySettings = {
				MinimapZoomIn = "never",
				MinimapZoomOut = "never",
				MiniMapWorldMapButton = "never",
				MinimapZoneTextButton = "always",
				TimeManagerClockButton = "always",
				MiniMapMailFrame = "always",
			},
			allowDragging = true,
			lockDragging = false,
			controlVisibility = true
		}
	}
	self.db = parent.db:RegisterNamespace("Buttons", defaults)
	db = self.db.profile
	parent:RegisterModuleOptions("Buttons", options, L["Buttons"])

	parent:GetModule("Shapes").RegisterCallback(self, "SexyMap_ShapeChanged", "UpdateDraggables")
end

--------------------------------------------------------------------------------
-- Fading
--

do
	local fadeIgnore = {
		Minimap = true,
		MinimapBackdrop = true,
		SexyMapPingFrame = true,
		SexyMapCustomBackdrop = true,
		SexyMapCoordFrame = true,
		MiniMapTrackingButton = true, -- Child of MiniMapTracking which is faded
	}

	local OnFinished = function(anim)
		-- Minimap or Minimap icons including nil checks to compensate for other addons
		local f, focus = anim:GetParent(), GetMouseFocus()
		if focus and ((focus:GetName() == "Minimap") or (focus:GetParent() and focus:GetParent():GetName() and focus:GetParent():GetName():find("Mini[Mm]ap"))) then
			f:SetAlpha(1)
		else
			f:SetAlpha(0)
		end
	end

	local fadeStop -- Use a variable to prevent fadeout/in when moving the mouse around minimap/icons

	local OnEnter = function()
		if not db.controlVisibility or fadeStop or moving then return end

		for _,f in pairs(animFrames) do
			local n = f:GetName()
			if not db.visibilitySettings[n] or db.visibilitySettings[n] == "hover" then
				f.smAnimGroup:Stop()
				f:SetAlpha(0)
				f.smAlphaAnim:SetChange(1)
				f.smAnimGroup:Play()
			end
		end
	end
	local OnLeave = function()
		if not db.controlVisibility or moving then return end
		local focus = GetMouseFocus() -- Minimap or Minimap icons including nil checks to compensate for other addons
		if focus and ((focus:GetName() == "Minimap") or (focus:GetParent() and focus:GetParent():GetName() and focus:GetParent():GetName():find("Mini[Mm]ap"))) then
			fadeStop = true
			return
		end
		fadeStop = nil

		for _,f in pairs(animFrames) do
			local n = f:GetName()
			if not db.visibilitySettings[n] or db.visibilitySettings[n] == "hover" then
				f.smAnimGroup:Stop()
				f:SetAlpha(1)
				f.smAlphaAnim:SetChange(-1)
				f.smAnimGroup:Play()
			end
		end
	end

	function mod:SexyMap_NewFrame(_, f)
		local n, w, h = f:GetName(), f:GetWidth(), f:GetHeight()
		-- Always allow Blizz frames, skip ignored frames, dynamically try to skip frames that may not be minimap buttons by checking size
		if (blizzButtons[n] or dynamicButtons[n]) or (not fadeIgnore[n] and w > 26 and w < 35 and h > 26 and h < 35) then
			-- Create the animations
			f.smAnimGroup = f:CreateAnimationGroup()
			f.smAlphaAnim = f.smAnimGroup:CreateAnimation("Alpha")
			f.smAlphaAnim:SetOrder(1)
			f.smAlphaAnim:SetDuration(0.5)
			f.smAnimGroup:SetScript("OnFinished", OnFinished)
			tinsert(animFrames, f)

			-- Configure fading
			if db.controlVisibility then
				self:ChangeFrameVisibility(f, db.visibilitySettings[n] or "hover")
			end

			-- Don't add config or moving capability to the Zone Text and Clock buttons, handled in their own modules
			if n ~= "MinimapZoneTextButton" and n ~= "TimeManagerClockButton" then
				self:AddButtonOptions(n, blizzButtons[n], dynamicButtons[n])

				-- These two frames are parented to MinimapCluster, if the map scale is changed they won't drag properly, so we parent to Minimap
				if n == "MiniMapInstanceDifficulty" or n == "GuildInstanceDifficulty" then
					f:ClearAllPoints()
					f:SetParent(Minimap)
					f:SetPoint("CENTER", Minimap, "CENTER", -60, 55)
				end

				-- Configure dragging
				if n == "MiniMapTracking" then
					self:MakeMovable(MiniMapTrackingButton, f)
				else
					self:MakeMovable(f)
				end
			end
		end
		f:HookScript("OnEnter", OnEnter)
		f:HookScript("OnLeave", OnLeave)
	end

	function mod:ChangeFrameVisibility(frame, vis)
		if vis == "always" then
			if not dynamicButtons[frame:GetName()] then frame:Show() end
			frame:SetAlpha(1)
		elseif vis == "never" then
			frame:Hide()
		else
			if not dynamicButtons[frame:GetName()] then frame:Show() end
			frame:SetAlpha(0)
		end
	end

	ButtonFadeOut = OnLeave
end

--------------------------------------------------------------------------------
-- Dragging
--

do

	local dragFrame = CreateFrame("Frame")

	local getCurrentAngle = function(parent, bx, by)
		local mx, my = parent:GetCenter()
		if not mx or not my or not bx or not by then return 0 end
		local h, w = (by - my), (bx - mx)
		if w == 0 then w = 0.001 end -- Prevent /0
		local angle = atan(h / w)
		if w < 0 then
			angle = angle + 180
		end
		return angle
	end

	local setPosition = function(frame, angle)
		local radius = (Minimap:GetWidth() / 2) + db.radius
		local bx, by = parent:GetModule("Shapes"):GetPosition(angle, radius)

		frame:ClearAllPoints()
		frame:SetPoint("CENTER", Minimap, "CENTER", bx, by)
	end

	local updatePosition = function()
		local x, y = GetCursorPosition()
		x, y = x / Minimap:GetEffectiveScale(), y / Minimap:GetEffectiveScale()
		local angle = getCurrentAngle(Minimap, x, y)
		db.dragPositions[moving:GetName()] = angle
		setPosition(moving, angle)
	end

	local OnDragStart = function(frame)
		if db.lockDragging or not db.allowDragging then return end

		moving = frame
		dragFrame:SetScript("OnUpdate", updatePosition)
	end
	local OnDragStop = function()
		dragFrame:SetScript("OnUpdate", nil)
		moving = nil
		ButtonFadeOut() -- Call the fade out function
	end

	function mod:MakeMovable(frame, tracking)
		frame:EnableMouse(true)
		frame:RegisterForDrag("LeftButton")
		if tracking then
			frame:SetScript("OnDragStart", function()
				if db.lockDragging or not db.allowDragging then return end

				moving = tracking
				dragFrame:SetScript("OnUpdate", updatePosition)
			end)
		else
			frame:SetScript("OnDragStart", OnDragStart)
		end
		frame:SetScript("OnDragStop", OnDragStop)
		self:UpdateDraggables(tracking or frame)
	end

	function mod:UpdateDraggables(frame)
		if not db.allowDragging then return end

		if frame and type(frame) == "table" then -- Type check because we have a callback sending a string on shape change
			local x, y = frame:GetCenter()
			local angle = db.dragPositions[frame:GetName()] or getCurrentAngle(frame:GetParent(), x, y)
			if angle then
				setPosition(frame, angle)
			end
		else
			for _,f in pairs(animFrames) do
				local x, y = f:GetCenter()
				local angle = db.dragPositions[f:GetName()] or getCurrentAngle(f:GetParent(), x, y)
				if angle then
					setPosition(f, angle)
				end
			end
		end
	end
end

parent.RegisterCallback(mod, "SexyMap_NewFrame")

