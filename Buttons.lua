local parent = SexyMap
local modName = "Buttons"
local mod = SexyMap:NewModule(modName, "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SexyMap")

local buttons
local function iterateChildren(...)
	local gotLast = false
	for val = 1, select("#", ...) do
		local child = select(val, ...)
		if gotLast and not buttons[child:GetName()] and child ~= TimeManagerClockButton then
			buttons[child:GetName() or ("Button #" .. val)] = {child, custom = true}
		end
		if child == MiniMapVoiceChatFrame then
			gotLast = true
		end
	end
end

local options = {
	type = "group",
	name = modName,
	childGroups = "tab",
	args = {
		custom = {
			type = "group",
			name = "Addon Buttons",
			args = {},
			order = 2
		},
		stock = {
			type = "group",
			name = "Standard Buttons",
			args = {},
			order = 1
		}
	}
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
		mail		= {"MiniMapMailFrame", show = function(f)
						return HasNewMail()
					end},
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
		local key = info[#info]:gsub(" ", "_")
		return v == (db[key] and db[key].hide or "hover")
	end
	
	local function hideSet(info, v)
		local key = info[#info]:gsub(" ", "_")
		db[key] = db[key] or {}
		db[key].hide = v
		mod:Update()
	end

	function mod:addButtonOptions(k, v)
		local key = k:gsub(" ", "_")
		local p
		if v and v.custom then
			p = options.args.custom.args
		else
			p = options.args.stock.args
		end
		p[key] = p[key] or {
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
			mod:addButtonOptions(k, v)
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
				if v.custom and f:IsVisible() or not v.custom then
					parent:RegisterHoverButton(f, v.show)
				end
			end
		elseif hide == "never" then
			for _, f in ipairs(v) do
				f = type(f) == "string" and _G[f] or f
				f:Hide()
			end
		else
			for _, f in ipairs(v) do
				f = type(f) == "string" and _G[f] or f
				if v.custom and f:IsVisible() or not v.custom then
					f:SetAlpha(1)
					f:Show()
				end
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
