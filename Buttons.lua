
local _, sm = ...
sm.buttons = {}

local mod = sm.buttons
local L = sm.L
local ldbi = LibStub("LibDBIcon-1.0")

local moving, ButtonFadeOut
-- XXX temp 10.2.6
local TrackingFrame = MinimapCluster.TrackingFrame or MinimapCluster.Tracking

local animFrames = {}
local blizzButtons = {
	GameTimeFrame = L["Calendar"],
	MiniMapTracking = L["Tracking Button"],
	SexyMapZoneTextButton = L["Zone Text"],
	MinimapZoomIn = L["Zoom In Button"],
	MinimapZoomOut = L["Zoom Out Button"],
	MiniMapWorldMapButton = L["Map Button"],
	TimeManagerClockButton = L["Clock"],
	AddonCompartmentFrame = L.addonCompartment,
}
local dynamicButtons = {
	GuildInstanceDifficulty = L["Guild Dungeon Difficulty Indicator (When Available)"],
	MiniMapChallengeMode = L["Challenge Mode Button (When Available)"],
	MiniMapInstanceDifficulty = L["Dungeon Difficulty Indicator (When Available)"],
	MiniMapMailFrame = L["New Mail Indicator (When Available)"],
	CraftingOrder = L.craftingOrder,
	GarrisonLandingPageMinimapButton = L["Garrison Button (When Available)"],
}

local buttonNicknames = {
	[ExpansionLandingPageMinimapButton] = "GarrisonLandingPageMinimapButton",
	[Minimap.ZoomIn] = "MinimapZoomIn",
	[Minimap.ZoomOut] = "MinimapZoomOut",
	[TrackingFrame] = "MiniMapTracking",
	[MinimapCluster.InstanceDifficulty] = "MiniMapInstanceDifficulty",
	[MinimapCluster.IndicatorFrame.MailFrame] = "MiniMapMailFrame",
	[MinimapCluster.IndicatorFrame.CraftingOrderFrame] = "CraftingOrder",
	[GameTimeFrame] = "GameTimeFrame", -- Just here to change parent to Minimap in :NewFrame
	[TrackingFrame.Button] = "none", -- Prevent error when being passed to :NewFrame
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
		scale = {
			order = 104,
			type = "range",
			name = L["Scale"],
			min = 0.5,
			max = 1,
			step = 0.01,
			disabled = function()
				return not mod.db.allowDragging
			end,
			get = function(info)
				return mod.db.scale
			end,
			set = function(info, v)
				mod.db.scale = v
				mod:UpdateDraggables()
			end,
		},
		visSpacer = {
			order = 105,
			type = "header",
			name = L["Visibility"],
		},
		controlVisibility = {
			type = "toggle",
			name = L["Let SexyMap control button visibility"],
			desc = L["Turn this off if you want another mod to handle which buttons are visible on the minimap."],
			width = "full",
			order = 106,
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
						local name = buttonNicknames[f] or f:GetName()
						mod:ChangeFrameVisibility(f, mod.db.visibilitySettings[name] or "hover")
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

	local function hideSet(info, value)
		local name = info[#info]
		mod.db.visibilitySettings[name] = value
		for k,v in next, buttonNicknames do
			if v == name then
				mod:ChangeFrameVisibility(k, value)
				return
			end
		end
		mod:ChangeFrameVisibility(_G[name], value)
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
			name = L["Show %s:"]:format(blizzButtons[name] or dynamicButtons[name] or name:gsub("LibDBIcon10_", "")),
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
			scale = 1,
			dragPositions = {},
			visibilitySettings = {
				MinimapZoomIn = "never",
				MinimapZoomOut = "never",
				MiniMapWorldMapButton = "never",
				SexyMapZoneTextButton = "always",
				TimeManagerClockButton = "always",
				MiniMapMailFrame = "always",
				CraftingOrder = "always",
				GarrisonLandingPageMinimapButton = "always",
				AddonCompartmentFrame = "never",
			},
			allowDragging = true,
			lockDragging = false,
			controlVisibility = true
		}
	end

	-- XXX temp 9.0.1
	if not profile.buttons.visibilitySettings.SexyMapZoneTextButton then
		profile.buttons.visibilitySettings.SexyMapZoneTextButton = "always"
		profile.buttons.visibilitySettings.MinimapZoneTextButton = nil
	end
	-- XXX temp 10.1.0
	if not profile.buttons.scale then
		profile.buttons.scale = 1
	end
	if not profile.buttons.visibilitySettings.CraftingOrder then
		profile.buttons.visibilitySettings.CraftingOrder = "always"
	end
	if not profile.buttons.visibilitySettings.AddonCompartmentFrame then
		profile.buttons.visibilitySettings.AddonCompartmentFrame = "never"
	end
	if not profile.buttons.visibilitySettings.QueueStatusMinimapButton then
		profile.buttons.visibilitySettings.QueueStatusMinimapButton = nil
	end

	self.db = profile.buttons
end

function mod:OnEnable()
	-- Customize the world map: Defaults!
	-- Interface\\minimap\\UI-Minimap-WorldMapSquare
	-- MiniMapWorldMapButton:GetRegions():SetTexCoord(0,0,0,0.5,1,0,1,0.5) -- Normal
	-- MiniMapWorldMapButton:GetRegions():SetTexCoord(0,0.5,0,1,1,0.5,1,1) -- Pushed

	if MiniMapWorldMapButton then
		local overlay = MiniMapWorldMapButton:CreateTexture(nil, "OVERLAY")
		overlay:SetSize(53,53)
		overlay:SetTexture(136430) -- 136430 = Interface\\Minimap\\MiniMap-TrackingBorder
		overlay:SetPoint("TOPLEFT")
		local background = MiniMapWorldMapButton:CreateTexture(nil, "BACKGROUND")
		background:SetSize(25,25)
		background:SetTexture(136467) -- 136467 = Interface\\Minimap\\UI-Minimap-Background
		background:SetPoint("TOPLEFT", MiniMapWorldMapButton, "TOPLEFT", 4, -2)

		local icon, pushedIcon, highlight = MiniMapWorldMapButton:GetRegions()
		icon:SetTexCoord(0.32,0,0.32,0.5,1,0,1,0.5)
		icon:ClearAllPoints()
		icon:SetPoint("BOTTOMRIGHT", MiniMapWorldMapButton, "BOTTOMRIGHT", -4, 2)
		icon:SetSize(20,30)
		pushedIcon:SetTexCoord(0.32,0.5,0.32,1,1,0.5,1,1)
		pushedIcon:ClearAllPoints()
		pushedIcon:SetPoint("BOTTOMRIGHT", MiniMapWorldMapButton, "BOTTOMRIGHT", -4, 2)
		pushedIcon:SetSize(20,30)

		MiniMapWorldMapButton:SetHighlightTexture(136477) -- 136477 = Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight
		highlight:ClearAllPoints()
		highlight:SetPoint("TOPLEFT", MiniMapWorldMapButton, "TOPLEFT", 2, -2)
	else
		-- Mail Button
		local overlay = MinimapCluster.IndicatorFrame.MailFrame:CreateTexture(nil, "OVERLAY")
		overlay:SetSize(53,53)
		overlay:SetTexture(136430) -- 136430 = Interface\\Minimap\\MiniMap-TrackingBorder
		overlay:SetPoint("CENTER", MiniMapMailIcon, "CENTER", 10, -10)
		local background = MinimapCluster.IndicatorFrame.MailFrame:CreateTexture(nil, "BACKGROUND")
		background:SetSize(25,25)
		background:SetTexture(136467) -- 136467 = Interface\\Minimap\\UI-Minimap-Background
		background:SetPoint("CENTER", MiniMapMailIcon, "CENTER")

		-- Tracking Button
		overlay = TrackingFrame:CreateTexture(nil, "OVERLAY")
		overlay:SetSize(53,53)
		overlay:SetTexture(136430) -- 136430 = Interface\\Minimap\\MiniMap-TrackingBorder
		overlay:SetPoint("CENTER", TrackingFrame.Button, "CENTER", 10, -10)
		background = TrackingFrame:CreateTexture(nil, "BACKGROUND")
		background:SetSize(25,25)
		background:SetTexture(136467) -- 136467 = Interface\\Minimap\\UI-Minimap-Background
		background:SetPoint("CENTER", TrackingFrame.Button, "CENTER")

		-- Crafting Order Button
		overlay = MinimapCluster.IndicatorFrame.CraftingOrderFrame:CreateTexture(nil, "OVERLAY")
		overlay:SetSize(53,53)
		overlay:SetTexture(136430) -- 136430 = Interface\\Minimap\\MiniMap-TrackingBorder
		overlay:SetPoint("CENTER", MiniMapCraftingOrderIcon, "CENTER", 10, -10)
		background = MinimapCluster.IndicatorFrame.CraftingOrderFrame:CreateTexture(nil, "BACKGROUND")
		background:SetSize(25,25)
		background:SetTexture(136467) -- 136467 = Interface\\Minimap\\UI-Minimap-Background
		background:SetPoint("CENTER", MiniMapCraftingOrderIcon, "CENTER")

		-- Calendar Button
		overlay = GameTimeFrame:CreateTexture(nil, "OVERLAY")
		overlay:SetSize(53,53)
		overlay:SetTexture(136430) -- 136430 = Interface\\Minimap\\MiniMap-TrackingBorder
		overlay:SetPoint("CENTER", GameTimeFrame, "CENTER", 10, -10)
		background = GameTimeFrame:CreateTexture(nil, "BACKGROUND")
		background:SetSize(25,25)
		background:SetTexture(136467) -- 136467 = Interface\\Minimap\\UI-Minimap-Background
		background:SetPoint("CENTER", GameTimeFrame, "CENTER")

		-- Addon compartment Button
		overlay = AddonCompartmentFrame:CreateTexture(nil, "OVERLAY")
		overlay:SetSize(53,53)
		overlay:SetTexture(136430) -- 136430 = Interface\\Minimap\\MiniMap-TrackingBorder
		overlay:SetPoint("CENTER", AddonCompartmentFrame, "CENTER", 10, -10)
		background = AddonCompartmentFrame:CreateTexture(nil, "BACKGROUND")
		background:SetSize(25,25)
		background:SetTexture(136467) -- 136467 = Interface\\Minimap\\UI-Minimap-Background
		background:SetPoint("CENTER", AddonCompartmentFrame, "CENTER")

		-- Zoom in Button
		overlay = Minimap.ZoomIn:CreateTexture(nil, "OVERLAY")
		overlay:SetSize(53,53)
		overlay:SetTexture(136430) -- 136430 = Interface\\Minimap\\MiniMap-TrackingBorder
		overlay:SetPoint("CENTER", Minimap.ZoomIn, "CENTER", 10, -10)
		background = Minimap.ZoomIn:CreateTexture(nil, "BACKGROUND")
		background:SetSize(25,25)
		background:SetTexture(136467) -- 136467 = Interface\\Minimap\\UI-Minimap-Background
		background:SetPoint("CENTER", Minimap.ZoomIn, "CENTER")

		-- Zoom out Button
		overlay = Minimap.ZoomOut:CreateTexture(nil, "OVERLAY")
		overlay:SetSize(53,53)
		overlay:SetTexture(136430) -- 136430 = Interface\\Minimap\\MiniMap-TrackingBorder
		overlay:SetPoint("CENTER", Minimap.ZoomOut, "CENTER", 10, -10)
		background = Minimap.ZoomOut:CreateTexture(nil, "BACKGROUND")
		background:SetSize(25,25)
		background:SetTexture(136467) -- 136467 = Interface\\Minimap\\UI-Minimap-Background
		background:SetPoint("CENTER", Minimap.ZoomOut, "CENTER")
	end

	sm.core.button.SetParent(ExpansionLandingPageMinimapButton, Minimap)
	-- Set parent again to compensate for garbage addons (Edit Mode Expanded) thinking it's a good idea to have wide ranging changes on by default, instead of having everything opt-in like Edit Mode itself...
	hooksecurefunc(ExpansionLandingPageMinimapButton, "SetParent", function()
		sm.core.button.SetParent(ExpansionLandingPageMinimapButton, Minimap)
		mod:UpdateDraggables(ExpansionLandingPageMinimapButton)
	end)

	sm.core.button.SetSize(ExpansionLandingPageMinimapButton, 36, 36) -- Shrink the missions button
	-- Stop Blizz changing the icon size || Minimap.lua ExpansionLandingPageMinimapButtonMixin:UpdateIcon() >> SetLandingPageIconFromAtlases() >> self:SetSize()
	hooksecurefunc(ExpansionLandingPageMinimapButton, "SetSize", function()
		sm.core.button.SetSize(ExpansionLandingPageMinimapButton, 36, 36)
	end)
	-- Stop Blizz moving the icon || Minimap.lua ExpansionLandingPageMinimapButtonMixin:UpdateIcon()>> self:UpdateIconForGarrison() >> ApplyGarrisonTypeAnchor() >> anchor:SetPoint()
	hooksecurefunc(ExpansionLandingPageMinimapButton, "UpdateIconForGarrison", function()
		mod:UpdateDraggables(ExpansionLandingPageMinimapButton)
	end)
	-- Stop Blizz moving the icon || Minimap.lua ExpansionLandingPageMinimapButtonMixin:SetLandingPageIconOffset() >> anchor:SetPoint()
	hooksecurefunc(ExpansionLandingPageMinimapButton, "SetLandingPageIconOffset", function()
		mod:UpdateDraggables(ExpansionLandingPageMinimapButton)
	end)
	sm.core:RegisterModuleOptions("Buttons", options, L["Buttons"])

	C_Timer.After(1, mod.StartFrameGrab)
end

--------------------------------------------------------------------------------
-- Fading
--

local OnFinished, KillAnimation
do
	local fadeStop = false -- Use a variable to prevent fadeout/in when moving the mouse around minimap/icons
	local restoreGarrisonButtonAnimation = false

	OnFinished = function(anim)
		-- Work around issues with buttons that have a pulse/fade ring animation.
		if restoreGarrisonButtonAnimation and anim:GetParent():GetName() == "ExpansionLandingPageMinimapButton" then
			anim:GetParent().MinimapLoopPulseAnim:Play()
			restoreGarrisonButtonAnimation = false
		end
	end

	KillAnimation = function(n, f)
		-- Work around issues with buttons that have a pulse/fade ring animation.
		if n == "ExpansionLandingPageMinimapButton" and (f.MinimapLoopPulseAnim:IsPlaying() or restoreGarrisonButtonAnimation) then
			restoreGarrisonButtonAnimation = true
			f.MinimapLoopPulseAnim:Stop()
			return f.MinimapLoopPulseAnim
		end
	end

	function mod:ShowAllButtons()
		if not mod.db.controlVisibility or fadeStop or moving then return end

		for i = 1, #animFrames do
			local f = animFrames[i]
			local n = buttonNicknames[f] or f:GetName()
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

	function mod:HideAllButtons()
		if not mod.db.controlVisibility or moving then return end
		local focus = GetMouseFocus and GetMouseFocus() or GetMouseFoci and GetMouseFoci()[1] -- Minimap or Minimap icons including nil checks to compensate for other addons
		if focus and not focus:IsForbidden() and ((focus:GetName() == "Minimap") or (focus:GetParent() and focus:GetParent():GetName() and focus:GetParent():GetName():find("Mini[Mm]ap"))) then
			fadeStop = true
			return
		end
		fadeStop = false

		for i = 1, #animFrames do
			local f = animFrames[i]
			local n = buttonNicknames[f] or f:GetName()

			if not mod.db.visibilitySettings[n] or mod.db.visibilitySettings[n] == "hover" then
				if n ~= "GameTimeFrame" or (n == "GameTimeFrame" and C_Calendar.GetNumPendingInvites() < 1) then
					f.sexyMapFadeOut:Play()

					KillAnimation(n, f)
				end
			end
		end
	end

	local OnEnter = function()
		mod:ShowAllButtons()
	end

	local OnLeave = function()
		mod:HideAllButtons()
	end

	local hideFrame = CreateFrame("Frame") -- Dummy frame we use for hiding buttons to prevent other addons re-showing them
	hideFrame:Hide()
	-- XXX hopefuly temporary workaround for line 376 of Minimap.lua
	hideFrame.Layout = function() end
	Minimap.Layout = hideFrame.Layout
	function mod:NewFrame(f)
		local n = buttonNicknames[f] or f:GetName()
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

			-- Work around issues with buttons that have a pulse/fade ring animation.
			if n == "ExpansionLandingPageMinimapButton" then
				f.sexyMapFadeOut:SetScript("OnFinished", OnFinished)
			end
			-- These frames are parented to MinimapCluster, if the map scale is changed they won't drag properly, so we parent to Minimap
			if n == "MiniMapInstanceDifficulty" or n == "GuildInstanceDifficulty" or n == "MiniMapChallengeMode" then
				f:ClearAllPoints()
				f:SetParent(Minimap)
				f:SetPoint("CENTER", Minimap, "CENTER", -60, 55)
			elseif buttonNicknames[f] or n == "AddonCompartmentFrame" then
				f:SetParent(Minimap)
			end

			animFrames[#animFrames+1] = f

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
				if n == "MiniMapTracking" then
					if MiniMapTrackingButton then
						self:MakeMovable(MiniMapTrackingButton, f)
					else
						self:MakeMovable(TrackingFrame.Button, f)
					end
				else
					self:MakeMovable(f)
				end
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
		frame:SetScale(mod.db.scale)

		frame:ClearAllPoints()
		frame:SetPoint("CENTER", Minimap, "CENTER", bx, by)
	end

	local updatePosition = function()
		local x, y = GetCursorPosition()
		x, y = x / Minimap:GetEffectiveScale(), y / Minimap:GetEffectiveScale()
		local angle = getCurrentAngle(Minimap, x, y)
		local name = buttonNicknames[moving] or moving:GetName()
		mod.db.dragPositions[name] = angle
		setPosition(moving, angle)
	end

	local OnDragStart = function(frame)
		if mod.db.lockDragging or not mod.db.allowDragging then return end

		moving = frame
		fadeStop = true
		for i = 1, #animFrames do
			local f = animFrames[i]
			local n = buttonNicknames[f] or f:GetName()
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

		mod:ShowAllButtons()

		if frame then
			local x, y = frame:GetCenter()
			local name = buttonNicknames[frame] or frame:GetName()
			local angle = mod.db.dragPositions[name] or getCurrentAngle(frame:GetParent(), x, y)
			if angle then
				setPosition(frame, angle)
			end
		else
			for i = 1, #animFrames do
				local f = animFrames[i]
				local n = buttonNicknames[f] or f:GetName()
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

		mod:HideAllButtons()

	end
end

--------------------------------------------------------------------------------
-- Button grab
--

do
	local buttonTable = {
		Minimap, TimeManagerClockButton, GameTimeFrame, TrackingFrame, TrackingFrame.Button,
		Minimap.ZoomIn, Minimap.ZoomOut, MinimapCluster.InstanceDifficulty, AddonCompartmentFrame,
		MinimapCluster.IndicatorFrame.MailFrame, MinimapCluster.IndicatorFrame.CraftingOrderFrame, ExpansionLandingPageMinimapButton
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
		for i = 1, #buttonTable do
			mod:NewFrame(buttonTable[i])
		end

		local ldbiTbl = ldbi:GetButtonList()
		for i = 1, #ldbiTbl do
			mod:NewFrame(ldbi:GetMinimapButton(ldbiTbl[i]))
		end
		ldbi.RegisterCallback(mod, "LibDBIcon_IconCreated", "AddButton")

		-- If calendar is set to "hover" and we have pending invites, force show it
		local frame = CreateFrame("Frame")
		frame:SetScript("OnEvent", CheckCalendar)
		frame:RegisterEvent("CALENDAR_UPDATE_PENDING_INVITES")
		frame:RegisterEvent("CALENDAR_ACTION_PENDING")
		CheckCalendar()

		mod.StartFrameGrab = nil
	end
end

