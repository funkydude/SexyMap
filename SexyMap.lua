
local name, sm = ...
sm.core = {}

local mod = sm.core
local L = sm.L

sm.backdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	insets = {left = 4, top = 4, right = 4, bottom = 4},
	edgeSize = 16,
	tile = true,
}

mod.frame = CreateFrame("Frame")
mod.frame:Show()
mod.deepCopyHash = function(t)
	local nt = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			nt[k] = mod.deepCopyHash(v)
		else
			nt[k] = v
		end
	end
	return nt
end

mod.options = {
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
				return InterfaceOptionsDisplayPanelRotateMinimap:GetValue() == "1" and true
			end,
			set = function()
				InterfaceOptionsDisplayPanelRotateMinimap:Click()
			end,
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
			desc = L["If you zoom into the map, this feature will automatically zoom out after the selected period of time (seconds). Using a value of 0 will disable Auto Zoom-Out."],
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
		spacer1 = {
			order = 8,
			type = "description",
			width = "full",
			name = "\n\n",
		},
		presetHeader = {
			order = 9,
			type = "header",
			name = L["Preset"],
		},
		spacer2 = {
			order = 10,
			type = "description",
			width = "full",
			name = L["Quickly change the look of your minimap by using a minimap preset."].."\n",
		},
		spacer3 = {
			order = 12,
			type = "description",
			width = "half",
			name = "",
		},
		spacer4 = {
			order = 14,
			type = "description",
			width = "full",
			name = "\n",
		},
		profilesHeader = {
			order = 15,
			type = "header",
			name = L["Profiles"],
		},
		spacer5 = {
			order = 16,
			type = "description",
			width = "full",
			name = L["Use the global profile if you want the same look on every character, or use a character-specific profile for a unique look on each character."].."\n",
		},
		globalProf = {
			order = 17,
			type = "toggle",
			name = L["Use Global Profile"],
			width = "full",
			confirm = function(info, v)
				if v and SexyMap2DB.global then
					return L["A global profile already exists. You will be switched over to it and your UI will be reloaded, are you sure?"]
				elseif v and not SexyMap2DB.global then
					return L["No global profile exists. Your current profile will be copied over and used as the global profile, are you sure? This will also reload your UI."]
				elseif not v then
					return L["Are you sure you want to switch back to using a character specific profile? This will reload your UI."]
				end
			end,
			get = function()
				local char = (UnitName("player").."-"..GetRealmName())
				return type(SexyMap2DB[char]) == "string"
			end,
			set = function(info, v)
				local char = (UnitName("player").."-"..GetRealmName())
				if v then
					if not SexyMap2DB.global then
						SexyMap2DB.global = mod.deepCopyHash(SexyMap2DB[char])
					end
					SexyMap2DB[char] = "global"
					ReloadUI()
				else
					SexyMap2DB[char] = nil
					ReloadUI()
				end
			end,
		},
		copy = {
			type = "select",
			name = L["Copy a Profile"],
			order = 18,
			confirm = true,
			confirmText = L["Copying this profile will reload your UI, are you sure?"],
			values = function()
				local tbl = {}
				for k,v in pairs(SexyMap2DB) do
					if k ~= "presets" and k ~= "global" and k ~= (UnitName("player").."-"..GetRealmName()) and type(v) == "table" then
						tbl[k]=k
					end
				end
				return tbl
			end,
			set = function(info, v)
				local char = (UnitName("player").."-"..GetRealmName())
				SexyMap2DB[char] = mod.deepCopyHash(SexyMap2DB[v])
				ReloadUI()
			end,
			disabled = function()
				local char = (UnitName("player").."-"..GetRealmName())
				if type(SexyMap2DB[char]) == "string" then
					return true
				end
				for k,v in pairs(SexyMap2DB) do
					if k ~= "presets" and k ~= "global" and k ~= char and type(v) == "table" then
						return false
					end
				end
				return true
			end,
		},
		delete = {
			type = "select",
			name = L["Delete a Profile"],
			order = 19,
			confirm = true,
			confirmText = L["Really delete this profile?"],
			values = function()
				local tbl = {}
				for k,v in pairs(SexyMap2DB) do
					if k ~= "presets" and k ~= "global" and k ~= (UnitName("player").."-"..GetRealmName()) and type(v) == "table" then
						tbl[k]=k
					end
				end
				return tbl
			end,
			set = function(info, v)
				SexyMap2DB[v] = nil
			end,
			disabled = function()
				local char = (UnitName("player").."-"..GetRealmName())
				if type(SexyMap2DB[char]) == "string" then
					return true
				end
				for k,v in pairs(SexyMap2DB) do
					if k ~= "presets" and k ~= "global" and k ~= char and type(v) == "table" then
						return false
					end
				end
				return true
			end,
		},
		reset = {
			type = "execute",
			name = L["Reset Current Profile"],
			confirm = true,
			confirmText = L["Resetting this profile will reload your UI, are you sure?"],
			order = 20,
			func = function()
				local char = UnitName("player").."-"..GetRealmName()
				SexyMap2DB[char] = nil
				ReloadUI()
			end,
			disabled = function()
				local char = (UnitName("player").."-"..GetRealmName())
				if type(SexyMap2DB[char]) == "string" then
					return true
				end
			end,
		},
	}
}

function mod:ADDON_LOADED(addon)
	if addon == "SexyMap" then
		if not SexyMap2DB then
			SexyMap2DB = {}
		end

		local char = UnitName("player").."-"..GetRealmName()
		if not SexyMap2DB[char] then
			SexyMap2DB[char] = {}
		end

		local dbToDispatch
		if type(SexyMap2DB[char]) == "string" then
			if not SexyMap2DB.global then
				SexyMap2DB.global = {}
			end
			dbToDispatch = SexyMap2DB.global
		else
			dbToDispatch = SexyMap2DB[char]
		end

		if not dbToDispatch.core then
			dbToDispatch.core = {
				lock = false,
				clamp = true,
				rightClickToConfig = true,
				autoZoom = 5,
				northTag = true,
				shape = "Interface\\AddOns\\SexyMap\\shapes\\circle.tga",
			}
		end
		mod.db = dbToDispatch.core

		mod.loadModules = {}
		for k,v in pairs(sm) do
			if v.OnInitialize then
				v:OnInitialize(dbToDispatch)
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
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(name, mod.options, true)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(name)

	-- Configure slash handler
	SlashCmdList.SexyMap = function()
		-- Twice to work around a Blizz bug, opens to wrong panel on first try
		InterfaceOptionsFrame_OpenToCategory(name)
		InterfaceOptionsFrame_OpenToCategory(name)
	end
	SLASH_SexyMap1 = "/minimap"
	SLASH_SexyMap2 = "/sexymap"

	Minimap:SetScript("OnMouseUp", function(frame, button)
		if button == "RightButton" and mod.db.rightClickToConfig then
			SlashCmdList.SexyMap()
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
	mod.loadModules = nil

	mod.frame:UnregisterEvent("PLAYER_LOGIN")
	mod.PLAYER_LOGIN = nil

	-- XXX temp, kill the tracker fix addon
	local _, exists = GetAddOnInfo("SexyMapTrackerButtonFix")
	if exists then
		C_Timer.After(5, function()
			message("SexyMapTrackerButtonFix: I'm no longer needed, please remove this addon.")
		end)
	end
end

-- Make sure the various minimap buttons follow the minimap
-- We do this before login to prevent button placement issues
MinimapBackdrop:ClearAllPoints()
MinimapBackdrop:SetParent(Minimap)
MinimapBackdrop:SetPoint("CENTER", Minimap, "CENTER", -8, -23)

function mod:SetupMap()
	local Minimap = Minimap

	-- Hide the Minimap during a pet battle
	mod.frame:RegisterEvent("PET_BATTLE_OPENING_START")
	mod.PET_BATTLE_OPENING_START = function()
		Minimap:Hide()
	end
	mod.frame:RegisterEvent("PET_BATTLE_CLOSE")
	mod.PET_BATTLE_CLOSE = function()
		Minimap:Show()
	end

	-- Hide the Minimap during combat. Remove the comments (--) to enable.
	--mod.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
	--mod.PLAYER_REGEN_DISABLED = function()
	--	Minimap:Hide()
	--end
	--mod.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
	--mod.PLAYER_REGEN_ENABLED = function()
	--	Minimap:Show()
	--end

	-- This is our method of cancelling timers, we only let the very last scheduled timer actually run the code.
	-- We do this by using a simple counter, which saves us using the more expensive C_Timer.NewTimer API.
	local started, current = 0, 0
	--[[ Auto Zoom Out ]]--
	local zoomOut = function()
		current = current + 1
		if started == current then
			for i = 1, Minimap:GetZoom() or 0 do
				Minimap_ZoomOutClick() -- Call it directly so we don't run our own hook
			end
			started, current = 0, 0
		end
	end

	local zoomBtnFunc = function()
		if mod.db.autoZoom > 0 then
			started = started + 1
			C_Timer.After(mod.db.autoZoom, zoomOut)
		end
	end
	zoomBtnFunc()
	MinimapZoomIn:HookScript("OnClick", zoomBtnFunc)
	MinimapZoomOut:HookScript("OnClick", zoomBtnFunc)

	--[[ MouseWheel Zoom ]]--
	Minimap:EnableMouseWheel(true)
	Minimap:SetScript("OnMouseWheel", function(frame, d)
		if d > 0 then
			MinimapZoomIn:Click()
		elseif d < 0 then
			MinimapZoomOut:Click()
		end
	end)

	MinimapCluster:EnableMouse(false) -- Don't leave an invisible dead zone

	-- Removes the circular "waffle-like" texture that shows when using a non-circular minimap in the blue quest objective area.
	Minimap:SetArchBlobRingScalar(0)
	Minimap:SetArchBlobRingAlpha(0)
	Minimap:SetQuestBlobRingScalar(0)
	Minimap:SetQuestBlobRingAlpha(0)

	if not mod.db.northTag then
		MinimapNorthTag:Hide()
		MinimapNorthTag.oldShow = MinimapNorthTag.Show
		MinimapNorthTag.Show = MinimapNorthTag.Hide
	end

	MinimapBorderTop:Hide()
	Minimap:RegisterForDrag("LeftButton")
	Minimap:SetClampedToScreen(mod.db.clamp)
	Minimap:SetFrameStrata("LOW")
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
	self.SetupMap = nil
end

mod.frame:RegisterEvent("ADDON_LOADED")
mod.frame:SetScript("OnEvent", function(_, event, ...)
	mod[event](sm, ...)
end)

function mod:RegisterModuleOptions(modName, optionTbl, displayName)
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(name..modName, optionTbl, true)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(name..modName, displayName, name)
end

