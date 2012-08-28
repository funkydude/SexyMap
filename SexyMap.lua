
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
	tile = true,
}

sm.core.deepCopyHash = function(t)
	local nt = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			nt[k] = sm.core.deepCopyHash(v)
		else
			nt[k] = v
		end
	end
	return nt
end

local options = {
	type = "group",
	name = name,
	args = {
		lock = {
			order = 1,
			name = L["Lock Minimap"],
			type = "toggle",
			get = function()
				return mod.db.lock
			end,
			set = function(info, v)
				mod.db.lock = v
				Minimap:SetMovable(not mod.db.lock)
			end,
		},
		clamp = {
			order = 2,
			type = "toggle",
			name = L["Clamp to screen"],
			desc = L["Prevent the minimap from being moved off the screen"],
			get = function()
				return mod.db.clamp
			end,
			set = function(info, v)
				mod.db.clamp = v
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
				return mod.db.rightClickToConfig
			end,
			set = function(info, v)
				mod.db.rightClickToConfig = v
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
				return mod.db.scale or 1
			end,
			set = function(info, v)
				mod.db.scale = v
				Minimap:SetScale(v)
			end,
		},
		northTag = {
			order = 6,
			type = "toggle",
			name = L["Show North Tag"],
			get = function()
				return mod.db.northTag
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
				mod.db.northTag = v
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
				return mod.db.autoZoom
			end,
			set = function(info, v)
				mod.db.autoZoom = v
			end,
		},
		profilesSpacer = {
			order = 8,
			type = "header",
			name = L["Profiles"],
		},
		copy = {
			type = "select",
			name = "Copy a profile",
			order = 9,
			confirm = true,
			confirmText = "This will reload your UI, are you sure?",
			values = function()
				local tbl = {}
				for k,_ in pairs(SexyMap2DB) do
					if k ~= "presets" and k ~= (UnitName("player").."-"..GetRealmName()) then
						tbl[k]=k
					end
				end
				return tbl
			end,
			set = function(info, v)
				local var = (UnitName("player").."-"..GetRealmName())
				SexyMap2DB[var] = sm.core.deepCopyHash(SexyMap2DB[v])
				ReloadUI()
			end,
			disabled = function()
				for k,_ in pairs(SexyMap2DB) do
					if k ~= "presets" and k ~= (UnitName("player").."-"..GetRealmName()) then
						return false
					end
				end
				return true
			end,
		},
		delete = {
			type = "select",
			name = "Delete a profile",
			order = 10,
			confirm = true,
			confirmText = "Really delete this profile?",
			values = function()
				local tbl = {}
				for k,_ in pairs(SexyMap2DB) do
					if k ~= "presets" and k ~= (UnitName("player").."-"..GetRealmName()) then
						tbl[k]=k
					end
				end
				return tbl
			end,
			set = function(info, v)
				print(v)
				SexyMap2DB[v] = nil
			end,
			disabled = function()
				for k,_ in pairs(SexyMap2DB) do
					if k ~= "presets" and k ~= (UnitName("player").."-"..GetRealmName()) then
						return false
					end
				end
				return true
			end,
		},
	reset = {
		type = "execute",
		name = "Reset your profile",
		confirm = true,
		confirmText = "This will reload your UI, are you sure?",
		order = 11,
		func = function()
			local var = UnitName("player").."-"..GetRealmName()
			SexyMap2DB[var] = nil
			ReloadUI()
		end,
	},
		presetSpacer = {
			order = 12,
			type = "header",
			name = L["Preset"],
		},
	}
}

mod.options = options

function mod:ADDON_LOADED(addon)
	if addon == "SexyMap" then
		if type(SexyMap2DB) ~= "table" then
			SexyMap2DB = {}
		end
		local var = UnitName("player").."-"..GetRealmName()
		if type(SexyMap2DB[var]) ~= "table" then
			SexyMap2DB[var] = {}
		end
		if type(SexyMap2DB[var].core) ~= "table" then
			SexyMap2DB[var].core = {
				lock = true,
				clamp = true,
				rightClickToConfig = true,
				autoZoom = 5,
				northTag = true,
				shape = "Textures\\MinimapMask",
			}
		end
		mod.db = SexyMap2DB[var].core

		mod.loadModules = {}
		for k,v in pairs(sm) do
			if v.OnInitialize then
				v:OnInitialize(SexyMap2DB[var])
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
		if button == "RightButton" and mod.db.rightClickToConfig then
			InterfaceOptionsFrame_OpenToCategory(name)
		else
			Minimap_OnClick(frame, button)
		end
	end)

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
		if mod.db.autoZoom > 0 then
			animGroup:Stop()
			anim:SetDuration(mod.db.autoZoom)
			animGroup:Play()
		end
	end)
	if mod.db.autoZoom > 0 then
		animGroup:Play()
	end

	MinimapCluster:EnableMouse(false) -- Don't leave an invisible dead zone

	if not mod.db.northTag then
		MinimapNorthTag:Hide()
		MinimapNorthTag.oldShow = MinimapNorthTag.Show
		MinimapNorthTag.Show = MinimapNorthTag.Hide
	end

	MinimapBorderTop:Hide()
	Minimap:RegisterForDrag("LeftButton")
	Minimap:SetClampedToScreen(mod.db.clamp)
	Minimap:SetScale(mod.db.scale or 1)
	Minimap:SetMovable(not mod.db.lock)

	Minimap:SetScript("OnDragStart", function(self) if self:IsMovable() then self:StartMoving() end end)
	Minimap:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local p, _, rp, x, y = Minimap:GetPoint()
		mod.db.point, mod.db.relpoint, mod.db.x, mod.db.y = p, rp, x, y
	end)

	if mod.db.point then
		Minimap:ClearAllPoints()
		Minimap:SetParent(UIParent)
		Minimap:SetPoint(mod.db.point, UIParent, mod.db.relpoint, mod.db.x, mod.db.y)
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
		grabFrames(MinimapZoneTextButton, Minimap, MiniMapTrackingButton, TimeManagerClockButton, MinimapBackdrop:GetChildren())
		grabFrames(MinimapCluster:GetChildren())
		self.StartFrameGrab = nil
	end
end

