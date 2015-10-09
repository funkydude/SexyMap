
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
	GarrisonLandingPageMinimapButton = L["Garrison Button (When Available)"],
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
	D32MiniMapButton = "Mistra's Diablo Orbs",
	DKPBidderMapIcon = "DKP-Bidder",
	HealiumMiniMap = "Healium",
	HealBot_MMButton = "HealBot",
	IonMinimapButton = "Ion",
	OutfitterMinimapButton = "Outfitter",
	FlightMapEnhancedMinimapButton = "Flight Map Enhanced",
	NXMiniMapBut = "Carbonite",
	RaidTrackerAceMMI = "Raid Tracker",
	TellTrackAceMMI = "Tell Track",
	TenTonHammer_MinimapButton = "PlayerScore",
	ZygorGuidesViewerMapIcon = "Zygor",
	RBSMinimapButton = "Raid Buff Status",
	BankItems_MinimapButton = "BankItems",
	OQ_MinimapButton = "oQueue",
	ItemRackMinimapFrame = "ItemRack",
	MageNug_MinimapFrame = "Mage Nuggets",
	CraftBuster_MinimapFrame = "CraftBuster",
	wlMinimapButton = "Wowhead Looter",
	AtlasLoot_MiniMapButton = "AtlasLoot",
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
			name = L["Show %s:"]:format(blizzButtons[name] or dynamicButtons[name] or addonButtons[name] or name:gsub("LibDBIcon10_", "")),
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
				MinimapZoomIn = "never",
				MinimapZoomOut = "never",
				MiniMapWorldMapButton = "never",
				MinimapZoneTextButton = "always",
				TimeManagerClockButton = "always",
				MiniMapMailFrame = "always",
				QueueStatusMinimapButton = "always",
				GarrisonLandingPageMinimapButton = "always",
			},
			allowDragging = true,
			lockDragging = false,
			controlVisibility = true
		}
	end

	self.db = profile.buttons
	-- XXX temp
	if not self.db.TEMP then
		self.db.visibilitySettings.QueueStatusMinimapButton = "always"
		self.db.TEMP = true
	end
	if not self.db.TEMP2 then
		self.db.visibilitySettings.GarrisonLandingPageMinimapButton = "always"
		self.db.TEMP2 = true
	end
end

function mod:OnEnable()
	-- Customize the world map: Defaults!
	-- Interface\\minimap\\UI-Minimap-WorldMapSquare
	-- MiniMapWorldMapButton:GetRegions():SetTexCoord(0,0,0,0.5,1,0,1,0.5) -- Normal
	-- MiniMapWorldMapButton:GetRegions():SetTexCoord(0,0.5,0,1,1,0.5,1,1) -- Pushed

	local overlay = MiniMapWorldMapButton:CreateTexture(nil, "OVERLAY")
	overlay:SetSize(53,53)
	overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	overlay:SetPoint("TOPLEFT")
	local background = MiniMapWorldMapButton:CreateTexture(nil, "BACKGROUND")
	background:SetSize(25,25)
	background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
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

	MiniMapWorldMapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	highlight:ClearAllPoints()
	highlight:SetPoint("TOPLEFT", MiniMapWorldMapButton, "TOPLEFT", 2, -2)

	-- Shrink the Garrison button
	GarrisonLandingPageMinimapButton:SetSize(38, 38)

	sm.core:RegisterModuleOptions("Buttons", options, L["Buttons"])

	mod:StartFrameGrab()
end

--------------------------------------------------------------------------------
-- Fading
--

do
	local fadeStop = false -- Use a variable to prevent fadeout/in when moving the mouse around minimap/icons
	local restoreGarrisonButtonAnimation = false
	local restoreLFGButtonAnimation = false

	local OnFinished = function(anim)
		-- Work around issues with buttons that have a pulse/fade ring animation.
		if restoreGarrisonButtonAnimation and anim:GetParent():GetName() == "GarrisonLandingPageMinimapButton" then
			anim:GetParent().MinimapLoopPulseAnim:Play()
			restoreGarrisonButtonAnimation = false
		end
		if restoreLFGButtonAnimation and anim:GetParent():GetName() == "QueueStatusMinimapButton" then
			anim:GetParent().EyeHighlightAnim:Play()
			restoreLFGButtonAnimation = false
		end
	end

	local OnEnter = function()
		if not mod.db.controlVisibility or fadeStop or moving then return end

		for i = 1, #animFrames do
			local f = animFrames[i]
			local n = f:GetName()
			if not mod.db.visibilitySettings[n] or mod.db.visibilitySettings[n] == "hover" then
				f.sexyMapFadeIn:Stop()
				f.sexyMapFadeOut:Stop()

				-- Work around issues with buttons that have a pulse/fade ring animation.
				if n == "GarrisonLandingPageMinimapButton" and f.MinimapLoopPulseAnim:IsPlaying() then
					restoreGarrisonButtonAnimation = true
					f.MinimapLoopPulseAnim:Stop()
				end
				if n == "QueueStatusMinimapButton" and f.EyeHighlightAnim:IsPlaying() then
					restoreLFGButtonAnimation = true
					f.EyeHighlightAnim:Stop()
				end
				--

				f.sexyMapFadeIn:Play()
			end
		end
	end
	local OnLeave = function()
		if not mod.db.controlVisibility or moving then return end
		local focus = GetMouseFocus() -- Minimap or Minimap icons including nil checks to compensate for other addons
		if focus and not focus:IsForbidden() and ((focus:GetName() == "Minimap") or (focus:GetParent() and focus:GetParent():GetName() and focus:GetParent():GetName():find("Mini[Mm]ap"))) then
			fadeStop = true
			return
		end
		fadeStop = false

		for i = 1, #animFrames do
			local f = animFrames[i]
			local n = f:GetName()
			if not mod.db.visibilitySettings[n] or mod.db.visibilitySettings[n] == "hover" then
				f.sexyMapFadeIn:Stop()
				f.sexyMapFadeOut:Stop()

				-- Work around issues with buttons that have a pulse/fade ring animation.
				if n == "GarrisonLandingPageMinimapButton" and f.MinimapLoopPulseAnim:IsPlaying() then
					restoreGarrisonButtonAnimation = true
					f.MinimapLoopPulseAnim:Stop()
				end
				if n == "QueueStatusMinimapButton" and f.EyeHighlightAnim:IsPlaying() then
					restoreLFGButtonAnimation = true
					f.EyeHighlightAnim:Stop()
				end
				--

				f.sexyMapFadeOut:Play()
			end
		end
	end

	function mod:NewFrame(f)
		local n = f:GetName()
		-- Only add Blizz buttons, addon buttons & LibDBIcon buttons
		if blizzButtons[n] or dynamicButtons[n] or addonButtons[n] or n:find("LibDBIcon") then
			-- Create the animations
			f.sexyMapFadeIn = f:CreateAnimationGroup()
			local smAlphaAnimIn = f.sexyMapFadeIn:CreateAnimation("Alpha")
			smAlphaAnimIn:SetOrder(1)
			smAlphaAnimIn:SetDuration(0.2)
			smAlphaAnimIn:SetFromAlpha(0)
			smAlphaAnimIn:SetToAlpha(1)
			f.sexyMapFadeIn:SetToFinalAlpha(true)

			f.sexyMapFadeOut = f:CreateAnimationGroup()
			local smAlphaAnimOut = f.sexyMapFadeOut:CreateAnimation("Alpha")
			smAlphaAnimOut:SetOrder(1)
			smAlphaAnimOut:SetDuration(0.2)
			smAlphaAnimOut:SetFromAlpha(1)
			smAlphaAnimOut:SetToAlpha(0)
			smAlphaAnimOut:SetStartDelay(1)
			f.sexyMapFadeOut:SetToFinalAlpha(true)

			-- Work around issues with buttons that have a pulse/fade ring animation.
			if n == "GarrisonLandingPageMinimapButton" or n == "QueueStatusMinimapButton" then
				f.sexyMapFadeIn:SetScript("OnFinished", OnFinished)
				f.sexyMapFadeOut:SetScript("OnFinished", OnFinished)
			end

			animFrames[#animFrames+1] = f

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
				elseif n == "CraftBuster_MinimapFrame" then
					if CraftBuster_MinimapButtonButton then
						self:MakeMovable(CraftBuster_MinimapButtonButton, f)
					end
				else
					self:MakeMovable(f)
				end
			end
		end
		f:HookScript("OnEnter", OnEnter)
		f:HookScript("OnLeave", OnLeave)
	end

	local hideFrame = CreateFrame("Frame") -- Dummy frame we use for hiding buttons to prevent other addons re-showing them
	hideFrame:Hide()
	local frameParents = {} -- Store the original button parents for restoration
	function mod:ChangeFrameVisibility(frame, vis)
		if vis == "always" then
			if frameParents[frame] then
				frame:SetParent(frameParents[frame])
				frameParents[frame] = nil
			end
			frame:SetAlpha(1)
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
			frame:SetAlpha(0)
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
			for i = 1, #animFrames do
				local f = animFrames[i]
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

--------------------------------------------------------------------------------
-- Button grab
--

do
	local alreadyGrabbed = {}
	local grabFrames = function(...)
		for i=1, select("#", ...) do
			local f = select(i, ...)
			local n = f:GetName()
			if n and not alreadyGrabbed[n] then
				alreadyGrabbed[n] = true
				mod:NewFrame(f)
			end
		end
	end

	local CTimerAfter = C_Timer.After
	local grabNewFrames = function()
		grabFrames(Minimap:GetChildren())
	end
	dragFrame:SetScript("OnEvent", function()
		CTimerAfter(2, grabNewFrames)
	end)

	function mod:StartFrameGrab()
		-- We'd use ADDON_LOADED directly but it's too early, some addons load a minimap icon afterwards
		CTimerAfter(2, function()
			grabFrames(
				Minimap, MiniMapTrackingButton, MinimapZoneTextButton, MiniMapTracking, TimeManagerClockButton, GameTimeFrame,
				MinimapZoomIn, MinimapZoomOut, MiniMapWorldMapButton, GuildInstanceDifficulty, MiniMapChallengeMode, MiniMapInstanceDifficulty,
				MiniMapMailFrame, MiniMapRecordingButton, MiniMapVoiceChatFrame, QueueStatusMinimapButton, GarrisonLandingPageMinimapButton
			)
			grabNewFrames()
			dragFrame:RegisterEvent("ADDON_LOADED")
		end)

		self.StartFrameGrab = nil
	end
end

