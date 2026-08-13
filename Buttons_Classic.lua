
local _, sm = ...
sm.buttons = {}

local mod = sm.buttons
local L = sm.L
local ldbi = LibStub("LibDBIcon-1.0")

local moving, ButtonFadeOut

local animFrames = {}
local blizzButtons = {
	GameTimeFrame = sm.API.isVanilla and L.dayNightButton or sm.API.isTBC and L.dayNightButton or L["Calendar"],
	MiniMapTracking = L["Tracking Button"],
	SexyMapZoneTextButton = L["Zone Text"],
	MinimapZoomIn = L["Zoom In Button"],
	MinimapZoomOut = L["Zoom Out Button"],
	MiniMapWorldMapButton = MiniMapWorldMapButton and L["Map Button"] or nil,
	TimeManagerClockButton = L["Clock"],
}
local dynamicButtons = {
	MiniMapChallengeMode = MiniMapChallengeMode and L["Challenge Mode Button (When Available)"] or nil,
	GuildInstanceDifficulty = GuildInstanceDifficulty and L["Guild Dungeon Difficulty Indicator (When Available)"] or nil,
	MiniMapInstanceDifficulty = MiniMapInstanceDifficulty and L["Dungeon Difficulty Indicator (When Available)"] or nil,
	MiniMapMailFrame = L["New Mail Indicator (When Available)"],
	MiniMapBattlefieldFrame = L.classicPVPButton,
	--GarrisonLandingPageMinimapButton = L["Garrison Button (When Available)"],
	LFGMinimapFrame = L.classicLFGButton,
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
			width = 2,
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
				for i = 1, #animFrames do
					local f = animFrames[i]
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
			name = blizzButtons[name] or dynamicButtons[name] or name:gsub("LibDBIcon10_", "") or "???",
			values = hideValues,
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
				GameTimeFrame = sm.API.isVanilla and "never" or sm.API.isTBC and "never" or "hover",
				MinimapZoomIn = "never",
				MinimapZoomOut = "never",
				MiniMapWorldMapButton = "never",
				SexyMapZoneTextButton = "always",
				TimeManagerClockButton = "always",
				MiniMapMailFrame = "always",
				MiniMapBattlefieldFrame = "always",
				LFGMinimapFrame = "always",
				GarrisonLandingPageMinimapButton = "always",
			},
			allowDragging = true,
			lockDragging = false,
			controlVisibility = true
		}
	end

	self.db = profile.buttons

	if self.db.tempWrathUpgrade then
		self.db.tempWrathUpgrade = nil
		if sm.API.isVanilla or sm.API.isTBC then
			self.db.visibilitySettings.GameTimeFrame = "never"
		else
			self.db.visibilitySettings.GameTimeFrame = "hover"
		end
	end
end

function mod:OnEnable()
	--GarrisonLandingPageMinimapButton:SetSize(36, 36) -- Shrink the missions button
	---- Stop Blizz changing the icon size || GarrisonLandingPageMinimapButton_UpdateIcon() >> SetLandingPageIconFromAtlases() >> self:SetSize()
	--hooksecurefunc(GarrisonLandingPageMinimapButton, "SetSize", function()
	--	sm.core.button.SetSize(GarrisonLandingPageMinimapButton, 36, 36)
	--end)
	---- Stop Blizz moving the icon || GarrisonLandingPageMinimapButton_UpdateIcon() >> ApplyGarrisonTypeAnchor() >> anchor:SetPoint()
	--hooksecurefunc("GarrisonLandingPageMinimapButton_UpdateIcon", function()
	--	mod:UpdateDraggables(GarrisonLandingPageMinimapButton)
	--end)

	sm.core:RegisterModuleOptions("Buttons", options, L["Buttons"])

	C_Timer.After(1, self.StartFrameGrab)

	if MiniMapTrackingButton then
		-- MiniMapTrackingButton is a child of MiniMapTracking and sits on top of it eating all mouse events
		-- We need to let mouse events pass through into MiniMapTracking, so dragging actually works
		sm.core.button.SetPropagateMouseClicks(MiniMapTrackingButton, true)
		sm.core.button.SetPropagateMouseMotion(MiniMapTrackingButton, true)
	end

	if MiniMapWorldMapButton and self.db.controlVisibility then
		sm.core.button.Show(MiniMapWorldMapButton) -- Default hidden by Blizz on specific WoW flavors. Force show it initially then let the user control if they want it visible.
	end

	-- On classic (vanilla) only, when reloading UI, there's a bug where the tracking icon doesn't re-show.
	if sm.API.isVanilla then
		local icon = GetTrackingTexture()
		if icon then
			MiniMapTrackingIcon:SetTexture(icon)
			MiniMapTracking:Show()
		end
	end
end

--------------------------------------------------------------------------------
-- Fading
--

local OnFinished, KillAnimation
local fadeStop = false -- Use a variable to prevent fadeout/in when moving the mouse around minimap/icons
do
	local restoreGarrisonButtonAnimation = false
	local restoreLFGButtonAnimation = false

	OnFinished = function(anim)
		-- Work around issues with buttons that have a pulse/fade ring animation.
		--if restoreGarrisonButtonAnimation and anim:GetParent():GetName() == "GarrisonLandingPageMinimapButton" then
		--	anim:GetParent().MinimapLoopPulseAnim:Play()
		--	restoreGarrisonButtonAnimation = false
		--end
		--if restoreLFGButtonAnimation and anim:GetParent():GetName() == "QueueStatusMinimapButton" then
		--	anim:GetParent().EyeHighlightAnim:Play()
		--	restoreLFGButtonAnimation = false
		--end
	end

	KillAnimation = function(n, f)
		-- Work around issues with buttons that have a pulse/fade ring animation.
		--if n == "GarrisonLandingPageMinimapButton" and (f.MinimapLoopPulseAnim:IsPlaying() or restoreGarrisonButtonAnimation) then
		--	restoreGarrisonButtonAnimation = true
		--	f.MinimapLoopPulseAnim:Stop()
		--	return f.MinimapLoopPulseAnim
		--end
		--if n == "QueueStatusMinimapButton" and (f.EyeHighlightAnim:IsPlaying() or restoreLFGButtonAnimation) then
		--	restoreLFGButtonAnimation = true
		--	f.EyeHighlightAnim:Stop()
		--	return f.EyeHighlightAnim
		--end
	end

	local OnEnter = function()
		if not mod.db.controlVisibility or fadeStop or moving then return end

		for i = 1, #animFrames do
			local f = animFrames[i]
			local n = f:GetName()
			if not mod.db.visibilitySettings[n] or mod.db.visibilitySettings[n] == "hover" then
				f.sexyMapFadeOut:Stop()

				local anim = KillAnimation(n, f)

				f:SetAlpha(1)
				if anim then
					OnFinished(anim)
				end
			end
		end
	end
	local OnLeave = function()
		if not mod.db.controlVisibility or moving then return end
		local focus = GetMouseFocus and GetMouseFocus() or GetMouseFoci and GetMouseFoci()[1] -- Minimap or Minimap icons including nil checks to compensate for other addons
		if focus and not focus:IsForbidden() and ((focus:GetName() == "Minimap") or (focus:GetParent() and focus:GetParent():GetName() and focus:GetParent():GetName():find("Mini[Mm]ap"))) then
			fadeStop = true
			return
		end
		fadeStop = false

		for i = 1, #animFrames do
			local f = animFrames[i]
			local n = f:GetName()

			if not mod.db.visibilitySettings[n] or mod.db.visibilitySettings[n] == "hover" then
				if n ~= "GameTimeFrame" or (n == "GameTimeFrame" and C_Calendar.GetNumPendingInvites() < 1) then
					f.sexyMapFadeOut:Play()

					KillAnimation(n, f)
				end
			end
		end
	end

	local hideFrame = CreateFrame("Frame") -- Dummy frame we use for hiding buttons to prevent other addons re-showing them
	hideFrame:Hide()
	function mod:NewFrame(f)
		local n = f:GetName()
		-- Only add Blizz buttons & LibDBIcon buttons
		if blizzButtons[n] or dynamicButtons[n] or n:find("LibDBIcon") then
			-- Create the animation
			f.sexyMapFadeOut = f:CreateAnimationGroup()
			local smAlphaAnimOut = f.sexyMapFadeOut:CreateAnimation("Alpha")
			smAlphaAnimOut:SetOrder(1)
			smAlphaAnimOut:SetDuration(0.2)
			smAlphaAnimOut:SetFromAlpha(1)
			smAlphaAnimOut:SetToAlpha(0)
			smAlphaAnimOut:SetStartDelay(1)
			f.sexyMapFadeOut:SetToFinalAlpha(true)
			animFrames[#animFrames+1] = f

			-- Make sure everything is parented to the Minimap and set to the correct strata and frame level
			if blizzButtons[n] or dynamicButtons[n] then
				sm.core.button.SetParent(f, Minimap)
				sm.core.button.SetFrameStrata(f, "MEDIUM")
				sm.core.button.SetFixedFrameStrata(f, true)
				sm.core.button.SetFrameLevel(f, 8)
				sm.core.button.SetFixedFrameLevel(f, true)
			end

			-- Correctly position frames that aren't parents to the Minimap by default
			if n == "MiniMapInstanceDifficulty" or n == "GuildInstanceDifficulty" or n == "MiniMapChallengeMode" then
				f:ClearAllPoints()
				f:SetPoint("CENTER", Minimap, "CENTER", -60, 55)
			end
			if n == "GameTimeFrame" then
				f:ClearAllPoints()
				f:SetPoint("CENTER", Minimap, "TOPRIGHT", 4, -37)
			end
			if n == "LFGMinimapFrame" then
				f:ClearAllPoints()
				f:SetPoint("CENTER", Minimap, "CENTER", -60, -55)
			end

			-- Configure fading
			if n == "TimeManagerClockButton" then -- This is disgusting but have to work around other addons messing with it
				hooksecurefunc(f, "SetParent", function(self)
					local vis = mod.db.visibilitySettings[n] or "hover"
					if vis == "always" then
						sm.core.button.SetParent(self, Minimap)
						self:SetAlpha(1)
					elseif vis == "never" then
						sm.core.button.SetParent(self, hideFrame)
					else
						sm.core.button.SetParent(self, Minimap)
						self:SetAlpha(0)
					end
				end)
				f:SetParent(Minimap) -- Run the hook
			elseif mod.db.controlVisibility then
				self:ChangeFrameVisibility(f, mod.db.visibilitySettings[n] or "hover")
			end

			-- Don't add config or moving capability to the Zone Text and Clock buttons, handled in their own modules
			if n ~= "SexyMapZoneTextButton" and n ~= "TimeManagerClockButton" then
				self:AddButtonOptions(n)

				-- Configure dragging
				--if not sm.API.isVanilla and n == "MiniMapTracking" then
				--	self:MakeMovable(MiniMapTrackingButton, f)
				--else
					self:MakeMovable(f)
				--end
			end
		end
		f:HookScript("OnEnter", OnEnter)
		f:HookScript("OnLeave", OnLeave)
	end

	local frameParents = {} -- Store the original button parents for restoration
	function mod:ChangeFrameVisibility(frame, vis)
		if vis == "always" then
			if frameParents[frame] then
				frame:SetParent(frameParents[frame])
				frameParents[frame] = nil
			end
			if frame.MinimapLoopPulseAnim or frame.EyeHighlightAnim then
				KillAnimation(frame:GetName(), frame)
				frame:SetAlpha(1)
				OnFinished(frame.MinimapLoopPulseAnim or frame.EyeHighlightAnim)
			else
				frame:SetAlpha(1)
			end
		elseif vis == "never" then
			if not frameParents[frame] then
				frameParents[frame] = frame:GetParent()
			end
			frame:SetParent(hideFrame)
		else
			if frameParents[frame] then
				frame:SetParent(frameParents[frame])
				frameParents[frame] = nil
			end
			if frame.MinimapLoopPulseAnim or frame.EyeHighlightAnim then
				KillAnimation(frame:GetName(), frame)
				frame:SetAlpha(0)
				OnFinished(frame.MinimapLoopPulseAnim or frame.EyeHighlightAnim)
			else
				frame:SetAlpha(0)
			end
		end
	end

	ButtonFadeOut = OnLeave
end

--------------------------------------------------------------------------------
-- Dragging
--

local dragFrame = CreateFrame("Frame")

do
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
		fadeStop = true
		for i = 1, #animFrames do
			local f = animFrames[i]
			local n = f:GetName()
			if not mod.db.visibilitySettings[n] or mod.db.visibilitySettings[n] == "hover" then
				f.sexyMapFadeOut:Stop()

				local anim = KillAnimation(n, f)

				f:SetAlpha(1)
				if anim then
					OnFinished(anim)
				end
			end
		end
		dragFrame:SetScript("OnUpdate", updatePosition)
	end
	local OnDragStop = function()
		dragFrame:SetScript("OnUpdate", nil)
		moving = nil
		fadeStop = false
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
			for i = 1, #animFrames do
				local f = animFrames[i]
				local n = f:GetName()
				-- Don't move the Clock or Zone Text when changing shape/preset
				if n ~= "SexyMapZoneTextButton" and n ~= "TimeManagerClockButton" then
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

--------------------------------------------------------------------------------
-- Button grab
--

do
	local tbl = {
		Minimap, MiniMapTracking, TimeManagerClockButton, GameTimeFrame,
		MinimapZoomIn, MinimapZoomOut,
		MiniMapMailFrame, MiniMapBattlefieldFrame,
	}

	function mod:AddButton(_, button)
		self:NewFrame(button)
	end

	local function CheckCalendar()
		if not mod.db.controlVisibility then return end
		local vis = mod.db.visibilitySettings.GameTimeFrame
		if not vis or vis == "hover" then
			if C_Calendar.GetNumPendingInvites() < 1 then
				mod:ChangeFrameVisibility(GameTimeFrame, "hover")
			else
				mod:ChangeFrameVisibility(GameTimeFrame, "always")
			end
		end
	end

	function mod:StartFrameGrab()
		if LFGMinimapFrame then -- Loads after PLAYER_ENTERING_WORLD
			tbl[#tbl+1] = LFGMinimapFrame
		end
		if MiniMapWorldMapButton then
			tbl[#tbl+1] = MiniMapWorldMapButton
		end
		if MiniMapInstanceDifficulty then
			tbl[#tbl+1] = MiniMapInstanceDifficulty
		end
		if GuildInstanceDifficulty then
			tbl[#tbl+1] = GuildInstanceDifficulty
		end
		if MiniMapChallengeMode then
			tbl[#tbl+1] = MiniMapChallengeMode
		end

		for i = 1, #tbl do
			mod:NewFrame(tbl[i])
		end

		local ldbiTbl = ldbi:GetButtonList()
		for i = 1, #ldbiTbl do
			mod:NewFrame(ldbi:GetMinimapButton(ldbiTbl[i]))
		end
		ldbi.RegisterCallback(mod, "LibDBIcon_IconCreated", "AddButton")

		-- If calendar is set to "hover" and we have pending invites, force show it
		if not sm.API.isVanilla and not sm.API.isTBC then -- Wrath+
			local frame = CreateFrame("Frame")
			frame:SetScript("OnEvent", CheckCalendar)
			frame:RegisterEvent("CALENDAR_UPDATE_PENDING_INVITES")
			frame:RegisterEvent("CALENDAR_ACTION_PENDING")
			CheckCalendar()
		end

		mod.StartFrameGrab = nil
	end
end

