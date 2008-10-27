local parent = SexyMap
local modName = "Buttons"
local mod = SexyMap:NewModule(modName, "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SexyMap")

local buttons
local function iterateChildren(...)
	local gotLast = false
	for val = 1, select("#", ...) do
		local child = select(val, ...)
		if gotLast and not buttons[child:GetName()] then
			buttons[child:GetName() or ("Button #" .. val)] = {child}
		end
		if child == MiniMapVoiceChatFrame then
			gotLast = true
		end
	end
end

local options = {
	type = "group",
	name = modName,
	args = {}
}

local defaults = {
	profile = {
		closeButton = false
	}
}

do
	local translations = {
		calendar 	= L["Calendar"],
		worldmap 	= L["Map Button"],
		tracking 	= L["Tracking Button"],
		zoom 		= L["Zoom Buttons"],
		mapclock 	= L["Clock"],
		close 		= L["Close button"],
		direction	= L["Compass labels"],
		mail		= L["New mail indicator"],
		voice		= L["Voice chat"],
		pvp			= L["Battlegrounds icon"],
	}
	
	buttons = {
		calendar	= {"GameTimeFrame"},
		worldmap 	= {"MiniMapWorldMapButton"},
		tracking	= {"MiniMapTracking"},
		zoom		= {"MinimapZoomIn", "MinimapZoomOut"},
		mapclock	= {"TimeManagerClockButton"},
		close	 	= {"MinimapToggleButton"},
		direction	= {"MinimapNorthTag"},
		mail		= {"MiniMapMailFrame"},
		voice 		= {"MiniMapVoiceChatFrame", show = function(f)
						return IsVoiceChatEnabled() and GetNumVoiceSessions()
					end},
		pvp 		= {"MiniMapBattlefieldFrame", show = function(f)
						return not ( BattlefieldFrame.numQueues == 0 and (not CanHearthAndResurrectFromArea()) )
					end}
	}

	local hideValues = {
		["always"] = L["Always"],
		["never"] = L["Never"],
		["hover"] = L["On hover"]	
	}

	local function hideGet(info, v)		
		return v == (db[info[#info]] and db[info[#info]].hide or "hover")
	end
	
	local function hideSet(info, v)
		db[info[#info]] = db[info[#info]] or {}
		db[info[#info]].hide = v
		mod:Update()
	end

	function mod:addButtonOptions(k, v)
		options.args[k] = options.args[k] or {
			type = "multiselect",
			name = ("Show %s..."):format(translations[k] or k),
			values = hideValues,
			get = hideGet,
			set = hideSet
		}
	end	
end

function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
	db = self.db.profile
	parent:RegisterModuleOptions(modName, options, modName)
	self:AddMouseWheelZoom()
end

function mod:OnEnable()
	local gotLast = false

	self.findClock = self:ScheduleRepeatingTimer("FindClock", 0.5)
	self:Update()
end

function mod:FindClock()
	if _G.TimeManagerClockButton then
		self:CancelTimer(self.findClock, true)
		self.findClock = nil

		iterateChildren(Minimap:GetChildren())
		for k, v in pairs(buttons) do
			mod:addButtonOptions(k)
		end

		self:Update()
	end
end

function mod:Update()
	for k, v in pairs(buttons) do
		local hide = db[k] and db[k].hide or "hover"
		if hide ~= "hover" then
			for _, f in ipairs(v) do
				parent:UnregisterHoverButton(f)
			end
		end
		if hide == "hover" then
			for _, f in ipairs(v) do
				parent:RegisterHoverButton(f, v.show)
			end
		elseif hide == "never" then
			for _, f in ipairs(v) do
				f = type(f) == "string" and _G[f] or f
				f:Hide()
			end
		else
			for _, f in ipairs(v) do
				f = type(f) == "string" and _G[f] or f
				f:SetAlpha(1)
				f:Show()
			end
		end				
	end
end

do
	local function wheel(self, dir)
		if dir == -1 and Minimap:GetZoom() > 0 then
			Minimap_ZoomOutClick()
		elseif dir == 1 and Minimap:GetZoom() < Minimap:GetZoomLevels() then
			Minimap_ZoomInClick()
		end
	end
	
	function mod:AddMouseWheelZoom()
		Minimap:EnableMouseWheel()
		Minimap:SetScript("OnMouseWheel", wheel)
	end
end
