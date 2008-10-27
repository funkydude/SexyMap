local parent = SexyMap
local modName = "Buttons"
local mod = SexyMap:NewModule(modName, "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SexyMap")

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

local buttons
do
	local translations = {
		calendar 	= L["Calendar"],
		worldmap 	= L["Map Button"],
		tracking 	= L["Tracking Button"],
		zoom 		= L["Zoom Buttons"],
		mapclock 	= L["Clock"],
		close 		= L["Close button"],
		direction	= L["Compass labels"],
		mail		= L["New mail indicator"]
	}
	
	buttons = {
		calendar	= {"GameTimeFrame"},
		worldmap 	= {"MiniMapWorldMapButton"},
		tracking	= {"MiniMapTracking"},
		zoom		= {"MinimapZoomIn", "MinimapZoomOut"},
		mapclock	= {"TimeManagerClockButton"},
		close	 	= {"MinimapToggleButton"},
		direction	= {"MinimapNorthTag"},
		mail		= {"MiniMapMailFrame"}
	}

	local hideValues = {
		["always"] = L["Always"],
		["never"] = L["Never"],
		["hover"] = L["On hover"]	
	}

	local function hideGet(info, v)		
		return db[info.arg].hide == v
	end
	
	local function hideSet(info, v)
		db[info.arg].hide = v
		mod:Update()
	end

	for k, v in pairs(buttons) do
		defaults.profile[k] = { hide = "hover" }
		local t = {
			type = "multiselect",
			name = ("Show %s..."):format(translations[k]),
			values = hideValues,
			arg = k,
			get = hideGet,
			set = hideSet
		}
		options.args[k] = t
	end
end

function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
	db = self.db.profile
	parent:RegisterModuleOptions(modName, options, modName)
	self:AddMouseWheelZoom()
end

function mod:OnEnable()
	self.findClock = self:ScheduleRepeatingTimer("FindClock", 0.5)
	self:Update()
end

function mod:FindClock()
	if _G.TimeManagerClockButton then
		self:CancelTimer(self.findClock, true)
		self.findClock = nil
		self:Update()
	end
end

function mod:Update()
	for k, v in pairs(buttons) do
		if db[k].hide ~= "hover" then
			for _, f in ipairs(v) do
				parent:UnregisterHoverButton(f)
			end
		end
		if db[k].hide == "hover" then
			for _, f in ipairs(v) do
				parent:RegisterHoverButton(f)
			end
		elseif db[k].hide == "never" then
			for _, f in ipairs(v) do
				_G[f]:Hide()
			end
		else
			for _, f in ipairs(v) do
				_G[f]:SetAlpha(1)
				_G[f]:Show()
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
