
local name, sm = ...
sm.core = {}
sm.core.frame = CreateFrame("Frame")

local mod = sm.core
local L = sm.L

sm.backdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	insets = {left = 4, top = 4, right = 4, bottom = 4},
	edgeSize = 16,
	tile = true
}

sm.general = {}
local gen = sm.general -- Temp hack to preserve settings

local db
local options = {
	type = "group",
	name = name,
	args = {
		lock = {
			order = 1,
			name = L["Lock Minimap"],
			type = "toggle",
			get = function()
				return db.lock
			end,
			set = function(info, v)
				db.lock = v
				Minimap:SetMovable(not db.lock)
			end,
		},
		clamp = {
			order = 2,
			type = "toggle",
			name = L["Clamp to screen"],
			desc = L["Prevent the minimap from being moved off the screen"],
			get = function()
				return db.clamp
			end,
			set = function(info, v)
				db.clamp = v
				Minimap:SetClampedToScreen(v)
			end,
		},
		rotate = {
			order = 3,
			type = "toggle",
			name = ROTATE_MINIMAP,
			desc = OPTION_TOOLTIP_ROTATE_MINIMAP,
			get = function()
				return GetCVar("rotateMinimap") == "1"
			end,
			set = ToggleMiniMapRotation,
		},
		rightClickToConfig = {
			order = 4,
			type = "toggle",
			name = L["Right Click Configure"],
			desc = L["Right clicking the map will open the SexyMap options"],
			get = function()
				return db.rightClickToConfig
			end,
			set = function(info, v)
				db.rightClickToConfig = v
			end,
		},
		scale = {
			order = 5,
			type = "range",
			name = L["Scale"],
			min = 0.2,
			max = 3.0,
			step = 0.01,
			bigStep = 0.01,
			width = "double",
			get = function(info)
				return db.scale or 1
			end,
			set = function(info, v)
				db.scale = v
				Minimap:SetScale(v)
			end,
		},
		northTag = {
			order = 6,
			type = "toggle",
			name = L["Show North Tag"],
			get = function()
				return db.northTag
			end,
			set = function(info, v)
				if v then
					MinimapNorthTag.Show = MinimapNorthTag.oldShow
					MinimapNorthTag.oldShow = nil
					MinimapNorthTag:Show()
				else
					MinimapNorthTag:Hide()
					MinimapNorthTag.oldShow = MinimapNorthTag.Show
					MinimapNorthTag.Show = MinimapNorthTag.Hide
				end
				db.northTag = v
			end,
		},
		zoom = {
			order = 7,
			type = "range",
			name = L["Auto Zoom-Out Delay"],
			desc = L["If you zoom into the map, this feature will automatically zoom out after the selected period of time (seconds)"],
			width = "double",
			min = 0,
			max = 30,
			step = 1,
			bigStep = 1,
			get = function()
				return db.autoZoom
			end,
			set = function(info, v)
				db.autoZoom = v
			end,
		},
		presetSpacer = {
			order = 8,
			type = "header",
			name = L["Preset"],
		},
	}
}

gen.options = options

function mod:ADDON_LOADED(addon)
	if addon == "SexyMap" then
		local defaults = {
			profile = {}
		}
		mod.db = LibStub("AceDB-3.0"):New("SexyMapDB", defaults)

		local genDefaults = {  -- Temp hack to preserve settings
			profile = {
				lock = true,
				clamp = true,
				rightClickToConfig = true,
				autoZoom = 5,
				northTag = true,
			}
		}
		gen.db = mod.db:RegisterNamespace("General", genDefaults)
		db = gen.db.profile

		mod.loadModules = {}
		for k,v in pairs(sm) do
			if v.OnInitialize then
				v:OnInitialize()
				v.OnInitialize = nil
				tinsert(mod.loadModules, k)
			end
		end

		mod.frame:UnregisterEvent("ADDON_LOADED")
		mod.frame:RegisterEvent("PLAYER_LOGIN")
		mod.ADDON_LOADED = nil
	end
end

function mod:PLAYER_LOGIN()
	-- Setup config
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(name, options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(name)

	-- Configure slash handler
	SlashCmdList[name] = function() InterfaceOptionsFrame_OpenToCategory(name) end
	SLASH_SexyMap1 = "/minimap"
	SLASH_SexyMap2 = "/sexymap"

	Minimap:SetScript("OnMouseUp", function(frame, button)
		if button == "RightButton" and db.rightClickToConfig then
			InterfaceOptionsFrame_OpenToCategory(name)
		else
			Minimap_OnClick(frame, button)
		end
	end)

	mod.db.RegisterCallback(mod, "OnProfileChanged", ReloadUI)
	mod.db.RegisterCallback(mod, "OnProfileCopied", ReloadUI)
	mod.db.RegisterCallback(mod, "OnProfileReset", ReloadUI)

	mod:SetupMap()

	-- Load the modules in alphabetical order
	table.sort(mod.loadModules)
	for i=1, #mod.loadModules do
		sm[mod.loadModules[i]]:OnEnable()
		sm[mod.loadModules[i]].OnEnable = nil
	end
	wipe(mod.loadModules)
	mod.loadModules = nil

	mod:StartFrameGrab()

	mod:RegisterModuleOptions("Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(mod.db), L["Profiles"])

	mod.frame:UnregisterEvent("PLAYER_LOGIN")
	mod.PLAYER_LOGIN = nil
end

-- Make sure the various minimap buttons follow the minimap
-- We do this before login to prevent button placement issues
MinimapBackdrop:ClearAllPoints()
MinimapBackdrop:SetParent(Minimap)
MinimapBackdrop:SetPoint("CENTER", Minimap, "CENTER", -8, -23)

function mod:SetupMap()
	local Minimap = Minimap

	--[[ Auto Zoom Out ]]--
	local animGroup = Minimap:CreateAnimationGroup()
	local anim = animGroup:CreateAnimation()
	animGroup:SetScript("OnFinished", function()
		for i = 1, 5 do
			MinimapZoomOut:Click()
		end
	end)
	anim:SetOrder(1)
	anim:SetDuration(1)

	-- XXX temp, kill the tracker fix addon
	if select(2, GetAddOnInfo("SexyMapTrackerButtonFix")) then
		DisableAddOn("SexyMapTrackerButtonFix")
		local c = CreateFrame"Frame"
		local t = GetTime()
		c:SetScript("OnUpdate", function()
			if GetTime()-t > 7 then
				ChatFrame1:AddMessage("SexyMapTrackerButtonFix: I'm no longer needed, please remove this addon.", 0, 0.3, 1)
				c:SetScript("OnUpdate", nil)
			end
		end)
	end

	--[[ MouseWheel Zoom ]]--
	Minimap:EnableMouseWheel(true)
	Minimap:SetScript("OnMouseWheel", function(frame, d)
		if d > 0 then
			MinimapZoomIn:Click()
		elseif d < 0 then
			MinimapZoomOut:Click()
		end
		if db.autoZoom > 0 then
			animGroup:Stop()
			anim:SetDuration(db.autoZoom)
			animGroup:Play()
		end
	end)
	if db.autoZoom > 0 then
		animGroup:Play()
	end

	MinimapCluster:EnableMouse(false) -- Don't leave an invisible dead zone

	if not db.northTag then
		MinimapNorthTag:Hide()
		MinimapNorthTag.oldShow = MinimapNorthTag.Show
		MinimapNorthTag.Show = MinimapNorthTag.Hide
	end

	MinimapBorderTop:Hide()
	Minimap:RegisterForDrag("LeftButton")
	Minimap:SetClampedToScreen(db.clamp)
	Minimap:SetScale(db.scale or 1)
	Minimap:SetMovable(not db.lock)

	Minimap:SetScript("OnDragStart", function(self) if self:IsMovable() then self:StartMoving() end end)
	Minimap:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local p, _, rp, x, y = Minimap:GetPoint()
		db.point, db.relpoint, db.x, db.y = p, rp, x, y
	end)

	if db.point then
		Minimap:ClearAllPoints()
		Minimap:SetParent(UIParent)
		Minimap:SetPoint(db.point, UIParent, db.relpoint, db.x, db.y)
	end
end

sm.core.frame:RegisterEvent("ADDON_LOADED")
sm.core.frame:SetScript("OnEvent", function(_, event, ...)
	mod[event](sm, ...)
end)

function mod:RegisterModuleOptions(modName, optionTbl, displayName)
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(name..modName, optionTbl)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(name..modName, displayName, name)
end

do
	local alreadyGrabbed = {}
	local grabFrames = function(...)
		for i=1, select("#", ...) do
			local f = select(i, ...)
			local n = f:GetName()
			if n and not alreadyGrabbed[n] then
				alreadyGrabbed[n] = true
				sm.buttons:NewFrame(f)
				sm.fader:NewFrame(f)
			end
		end
	end

	function mod:StartFrameGrab()
		-- Try to capture new frames periodically
		-- We'd use ADDON_LOADED but it's too early, some addons load a minimap icon afterwards
		local updateTimer = sm.core.frame:CreateAnimationGroup()
		local anim = updateTimer:CreateAnimation()
		updateTimer:SetScript("OnLoop", function() grabFrames(Minimap:GetChildren()) end)
		anim:SetOrder(1)
		anim:SetDuration(1)
		updateTimer:SetLooping("REPEAT")
		updateTimer:Play()

		-- Grab Icons
		grabFrames(MinimapZoneTextButton, Minimap, MiniMapTrackingButton,
			MiniMapInstanceDifficulty, GuildInstanceDifficulty, MinimapBackdrop:GetChildren()
		)
		self.StartFrameGrab = nil
	end
end

