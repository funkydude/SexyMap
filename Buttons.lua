local parent = SexyMap
local modName = "Buttons"
local mod = SexyMap:NewModule(modName, "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SexyMap")

local buttons
local function iterateChildren(...)
	local gotLast = false
	for val = 1, select("#", ...) do
		local child = select(val, ...)
		local sizeOk = child.GetWidth and child:GetWidth() < 100 and child.GetHeight and child:GetHeight() < 100
		if sizeOk and gotLast and not buttons[child:GetName()] and child ~= TimeManagerClockButton and child.SetAlpha then
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
		},
		dragRadius = {
			type = "range",
			name = L["Drag Radius"],
			min = -30,
			max = 100,
			step = 1,
			bigStep = 1,
			get = function()
				return db.radius
			end,
			set = function(info, v)
				db.radius = v
				mod:UpdateDraggables()
			end
		}
	}
}

local defaults = {
	profile = {
		radius = 0,
		dragPositions = {}
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
	db = self.db.profile
	local gotLast = false

	self.findClock = self:ScheduleRepeatingTimer("FindClock", 0.5)
	self:Update()

	self.movableTimer = self:ScheduleRepeatingTimer("MakeMovables", 2)
	MiniMapWorldMapButton:SetParent(Minimap)
	MiniMapTracking:SetParent(Minimap)
	self:MakeMovable(MiniMapTracking, MiniMapTrackingButton)
	self:MakeMovables()
end

function mod:OnDisable()
	self:CancelTimer(self.movableTimer, true)
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
				if (v.custom and f:IsVisible() or not v.custom) and type(f) == "table" then
					if type(v.show) == "function" and v.show(f) or type(v.show) ~= "function" then
						f:SetAlpha(1)
						f:Show()
					end
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

do
	local moving
	local movables = {}
	local dragFrames = {}
	local dragFrame = CreateFrame("Frame", nil, UIParent)
	
	local GetCursorPosition = _G.GetCursorPosition
	
	local function setPosition(frame, mx, my, angle)
		if not angle then
			local x, y = Minimap:GetCenter()
			x, y = x * Minimap:GetEffectiveScale(), y * Minimap:GetEffectiveScale()
			
			local dx, dy = mx - x, my - y
			angle = atan(dy / dx)
			if dx < 0 then angle = angle + 180 end
			db.dragPositions[frame:GetName()] = angle
		end		

		local radius = (Minimap:GetWidth() / 2) + db.radius
		local bx = cos(angle) * radius
		local by = sin(angle) * radius
		
		frame:ClearAllPoints()
		frame:SetPoint("CENTER", Minimap, "CENTER", bx, by)
	end
	
	local function updatePosition()
		local mx, my =  GetCursorPosition()
		setPosition(moving, mx, my)
	end
	
	local function start(frame)
		dragFrame:SetScript("OnUpdate", updatePosition)
		parent:DisableFade()
		moving = dragFrames[frame] or frame
	end
	
	local function finish(frame)
		moving = nil
		parent:EnableFade()
		dragFrame:SetScript("OnUpdate", nil)
	end
	
	function mod:MakeMovable(frame, toDrag)
		if not frame then return end
		movables[frame] = true
		if toDrag then
			dragFrames[toDrag] = frame
		end
		toDrag = toDrag or frame
		toDrag:RegisterForDrag("LeftButton")
		toDrag:SetScript("OnDragStart", start)
		toDrag:SetScript("OnDragStop", finish)
	end
	
	function mod:UpdateDraggables()
		for f, v in pairs(movables) do
			local angle = db.dragPositions[f:GetName()]
			if angle then
				local x, y = f:GetCenter()
				setPosition(f, x, y, angle)
			end
		end
	end
	
	local lastChildCount = 0
	function mod:MakeMovables()
		local childCount = Minimap:GetNumChildren()
		if childCount == lastChildCount then return end
		lastChildCount = childCount
		for i = 1, childCount do
			local child = select(i, Minimap:GetChildren())
			local sizeOk = child and child.GetWidth and child:GetWidth() < 100 and child.GetHeight and child:GetHeight() < 100
			if sizeOk and not movables[child] and child:GetName() then
				self:MakeMovable(child)
			end
		end
		self:UpdateDraggables()
	end
end
