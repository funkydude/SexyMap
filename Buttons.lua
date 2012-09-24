
local _, sm = ...
sm.buttons = {}

local mod = sm.buttons
local L = sm.L

local moving, ButtonFadeOut

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
	QueueStatusMinimapButton = L["Queue Status (PvP/LFG) Button (When Available)"],

	MiniMapBattlefieldFrame = "PVP", -- XXX mop temp
	MiniMapLFGFrame = "LFG", -- XXX mop temp
}
local addonButtons = { -- For the rare addons that don't use LibDBIcon for some reason :(
	EnxMiniMapIcon = "Enchantrix",
	["FuBarPluginBig BrotherFrameMinimapButton"] = "Big Brother",
	RA_MinimapButton = "RaidAchievement",
	DBMMinimapButton = "DBM (Deadly Boss Mods)",
	XPerl_MinimapButton_Frame = "X-Perl",
	WIM3MinimapButton = "WIM (WoW Instant Messenger)",
	VuhDoMinimapButton = "VuhDo",
	AltoholicMinimapButton = "Altoholic",
	DominosMinimapButton = "Dominos",
	Gatherer_MinimapOptionsButton = "Gatherer",
	DroodFocusMinimapButton = "Drood Focus",
	["FuBarPluginElkano's BuffBarsFrameMinimapButton"] = "EBB (Elkano's Buff Bars)",
	D32MiniMapButton = "Mistra's Diablo Orbs",
	DKPBidderMapIcon = "DKP-Bidder",
	HealiumMiniMap = "Healium",
	HealBot_ButtonFrame = "HealBot", -- HealBot_MMButton = "Healbot", -- Button parented to a frame, parented to the minimap, facepalm
	IonMinimapButton = "Ion",
	OutfitterMinimapButton = "Outfitter",
	FlightMapEnhancedMinimapButton = "Flight Map Enhanced",
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
				return not mod.db.controlVisibility
			end,
			args = {},
			order = 3,
		},
		dynamic = {
			type = "group",
			name = L["Dynamic Buttons"],
			disabled = function()
				return not mod.db.controlVisibility
			end,
			args = {},
			order = 2,
		},
		stock = {
			type = "group",
			disabled = function()
				return not mod.db.controlVisibility
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
				return mod.db.allowDragging
			end,
			set = function(info, v)
				mod.db.allowDragging = v
				if v then mod:UpdateDraggables() end
			end
		},
		lockDragging = {
			type = "toggle",
			name = L["Lock Button Dragging"],
			order = 102,
			disabled = function()
				return not mod.db.allowDragging
			end,
			get = function()
				return mod.db.lockDragging
			end,
			set = function(info, v)
				mod.db.lockDragging = v
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
				return not mod.db.allowDragging
			end,
			get = function()
				return mod.db.radius
			end,
			set = function(info, v)
				mod.db.radius = v
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
				return mod.db.controlVisibility
			end,
			set = function(info, v)
				mod.db.controlVisibility = v
				for _,f in pairs(animFrames) do
					if not v then
						mod:ChangeFrameVisibility(f, "always")
					else
						mod:ChangeFrameVisibility(f, mod.db.visibilitySettings[f:GetName()] or "hover")
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
		return (mod.db.visibilitySettings[info[#info]] or "hover") == v
	end

	local function hideSet(info, v)
		local name = info[#info]
		mod.db.visibilitySettings[name] = v
		mod:ChangeFrameVisibility(_G[name], v)
	end

	function mod:AddButtonOptions(name)
		local p
		if blizzButtons[name] then
			p = options.args.stock.args -- Blizz icon = stock section
		elseif dynamicButtons[name] then
			p = options.args.dynamic.args -- Blizz dynamic (off by default) icon = dynamic section
		else
			p = options.args.custom.args -- Addon icon = custom section
		end
		p[name] = {
			type = "multiselect",
			name = L["Show %s:"]:format(blizzButtons[name] or dynamicButtons[name] or addonButtons[name] or name:gsub("LibDBIcon10_", "")),
			values = dynamic and dynamicValues or hideValues,
			get = hideGet,
			set = hideSet,
		}
	end
end

function mod:OnInitialize(profile)
	if type(profile.buttons) ~= "table" then
		profile.buttons = {
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
	end
	if profile.buttons.dragPositions.AtlasButtonFrame then
		profile.buttons.dragPositions.AtlasButtonFrame = nil -- XXX temp
	end
	if profile.buttons.dragPositions.FishingBuddyMinimapFrame then
		profile.buttons.dragPositions.FishingBuddyMinimapFrame = nil -- XXX temp
	end
	self.db = profile.buttons
end

function mod:OnEnable()
	sm.core:RegisterModuleOptions("Buttons", options, L["Buttons"])
end

--------------------------------------------------------------------------------
-- Fading
--

do
	local OnFinished = function(anim)
		-- Minimap or Minimap icons including nil checks to compensate for other addons
		local f, focus = anim:GetParent(), GetMouseFocus()
		if focus and ((focus:GetName() == "Minimap" or focus:GetName() == "HealBot_MMButton") or (focus:GetParent() and focus:GetParent():GetName() and focus:GetParent():GetName():find("Mini[Mm]ap"))) then
			f:SetAlpha(1)
		else
			f:SetAlpha(0)
		end
	end

	local fadeStop -- Use a variable to prevent fadeout/in when moving the mouse around minimap/icons

	local OnEnter = function()
		if not mod.db.controlVisibility or fadeStop or moving then return end

		for _,f in pairs(animFrames) do
			local n = f:GetName()
			if not mod.db.visibilitySettings[n] or mod.db.visibilitySettings[n] == "hover" then
				local delayed = f.smAlphaAnim:IsDelaying()
				f.smAnimGroup:Stop()
				if not delayed then
					f:SetAlpha(0)
					f.smAlphaAnim:SetStartDelay(0)
					f.smAlphaAnim:SetChange(1)
					f.smAnimGroup:Play()
				end
			end
		end
	end
	local OnLeave = function()
		if not mod.db.controlVisibility or moving then return end
		local focus = GetMouseFocus() -- Minimap or Minimap icons including nil checks to compensate for other addons
		if focus and ((focus:GetName() == "Minimap" or focus:GetName() == "HealBot_MMButton") or (focus:GetParent() and focus:GetParent():GetName() and focus:GetParent():GetName():find("Mini[Mm]ap"))) then
			fadeStop = true
			return
		end
		fadeStop = nil

		for _,f in pairs(animFrames) do
			local n = f:GetName()
			if not mod.db.visibilitySettings[n] or mod.db.visibilitySettings[n] == "hover" then
				f.smAnimGroup:Stop()
				f:SetAlpha(1)
				f.smAlphaAnim:SetStartDelay(0.5)
				f.smAlphaAnim:SetChange(-1)
				f.smAnimGroup:Play()
			end
		end
	end

	function mod:NewFrame(f)
		local n = f:GetName()
		-- Only add Blizz buttons, addon buttons & LibDBIcon buttons
		if blizzButtons[n] or dynamicButtons[n] or addonButtons[n] or n:find("LibDBIcon") then
			-- Create the animations
			f.smAnimGroup = f:CreateAnimationGroup()
			f.smAlphaAnim = f.smAnimGroup:CreateAnimation("Alpha")
			f.smAlphaAnim:SetOrder(1)
			f.smAlphaAnim:SetDuration(0.3)
			f.smAnimGroup:SetScript("OnFinished", OnFinished)
			tinsert(animFrames, f)

			-- Configure fading
			if mod.db.controlVisibility then
				self:ChangeFrameVisibility(f, mod.db.visibilitySettings[n] or "hover")
			end

			-- Some non-LibDBIcon addon buttons don't set the strata properly and can appear behind things
			-- LibDBIcon sets the strata to MEDIUM and the frame level to 8, so we do the same to other buttons
			if addonButtons[n] then
				f:SetFrameStrata("MEDIUM")
				f:SetFrameLevel(8)
			end

			-- Don't add config or moving capability to the Zone Text and Clock buttons, handled in their own modules
			if n ~= "MinimapZoneTextButton" and n ~= "TimeManagerClockButton" then
				self:AddButtonOptions(n)

				-- These two frames are parented to MinimapCluster, if the map scale is changed they won't drag properly, so we parent to Minimap
				if n == "MiniMapInstanceDifficulty" or n == "GuildInstanceDifficulty" then
					f:ClearAllPoints()
					f:SetParent(Minimap)
					f:SetPoint("CENTER", Minimap, "CENTER", -60, 55)
				end

				-- Configure dragging
				if n == "MiniMapTracking" then
					self:MakeMovable(MiniMapTrackingButton, f)
				elseif n == "HealBot_ButtonFrame" then -- XXX Let's try get the author to make a better icon
					self:MakeMovable(HealBot_MMButton, f)
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
		local radius = (Minimap:GetWidth() / 2) + mod.db.radius
		local bx, by = sm.shapes:GetPosition(angle, radius)

		frame:ClearAllPoints()
		frame:SetPoint("CENTER", Minimap, "CENTER", bx, by)
	end

	local updatePosition = function()
		local x, y = GetCursorPosition()
		x, y = x / Minimap:GetEffectiveScale(), y / Minimap:GetEffectiveScale()
		local angle = getCurrentAngle(Minimap, x, y)
		mod.db.dragPositions[moving:GetName()] = angle
		setPosition(moving, angle)
	end

	local OnDragStart = function(frame)
		if mod.db.lockDragging or not mod.db.allowDragging then return end

		moving = frame
		dragFrame:SetScript("OnUpdate", updatePosition)
	end
	local OnDragStop = function()
		dragFrame:SetScript("OnUpdate", nil)
		moving = nil
		ButtonFadeOut() -- Call the fade out function
	end

	function mod:MakeMovable(frame, altFrame)
		frame:EnableMouse(true)
		frame:RegisterForDrag("LeftButton")
		if altFrame then
			frame:SetScript("OnDragStart", function()
				if mod.db.lockDragging or not mod.db.allowDragging then return end

				moving = altFrame
				dragFrame:SetScript("OnUpdate", updatePosition)
			end)
		else
			frame:SetScript("OnDragStart", OnDragStart)
		end
		frame:SetScript("OnDragStop", OnDragStop)
		self:UpdateDraggables(altFrame or frame)
	end

	function mod:UpdateDraggables(frame)
		if not mod.db.allowDragging then return end

		if frame then
			local x, y = frame:GetCenter()
			local angle = mod.db.dragPositions[frame:GetName()] or getCurrentAngle(frame:GetParent(), x, y)
			if angle then
				setPosition(frame, angle)
			end
		else
			for _,f in pairs(animFrames) do
				local n = f:GetName()
				-- Don't move the Clock or Zone Text when changing shape/preset
				if n ~= "MinimapZoneTextButton" and n ~= "TimeManagerClockButton" then
					local x, y = f:GetCenter()
					local angle = mod.db.dragPositions[n] or getCurrentAngle(f:GetParent(), x, y)
					if angle then
						setPosition(f, angle)
					end
				end
			end
		end
	end
end

