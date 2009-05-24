local parent = SexyMap
local mod = SexyMap:NewModule("General", "AceTimer-3.0", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SexyMap")

local db

local options = {
	type = "group",
	name = "General",
	args = {
		lock = {
			name = L["Lock minimap"],
			type = "toggle",
			get = function()
				return db.lock
			end,
			set = function(info, v)
				db.lock = v
				mod:SetLock(v)
			end
		},
		movers = {
			name = L["Show movers"],
			type = "toggle",
			get = function()
				return db.movers
			end,
			set = function(info, v)
				db.movers = v
				mod:SetMovers()
			end
		},
		clamp = {
			type = "toggle",
			name = L["Clamp to screen"],
			get = function()
				return db.clamp
			end,
			set = function(info, v)
				db.clamp = v
				MinimapCluster:SetClampedToScreen(v)
			end
		},
		scale = {
			type = "range",
			name = L["Scale"],
			min = 0.2,
			max = 3.0,
			step = 0.01,
			bigStep = 0.01,
			order = 104,
			width = "full",
			get = function(info)
				return db.scale or 1
			end,
			set = function(info, v)
				db.scale = v
				mod:Update()
			end
		},
		-- alpha = {
			-- type = "range",
			-- name = L["Opacity"],
			-- min = 0,
			-- max = 1.0,
			-- step = 0.01,
			-- bigStep = 0.01,
			-- order = 105,
			-- width = "full",
			-- get = function(info)
				-- return db.alpha or 1
			-- end,
			-- set = function(info, v)
				-- db.alpha = v
				-- mod:Update()
			-- end
		-- },
		rightClickToConfig = {
			type = "toggle",
			name = L["Right click map to configure"],
			width = "double",
			get = function()
				return db.rightClickToConfig
			end,
			set = function(info, v)
				db.rightClickToConfig = v
			end
		}
	}
}

local defaults = {
	profile = {
		lock = true,
		clamp = true,
		movers = false,
		rightClickToConfig = true,
		framePositions = {}
	}
}

local movables = {
	["DurabilityFrame"] = L["Armored Man"], 
	["QuestTimerFrame"] = L["Quest Timer"]
}
local movers = {}

mod.options = options

function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace("Movers", defaults)
	db = self.db.profile
	parent:RegisterModuleOptions("Movers", options, "Movers")
	
	MinimapBorderTop:Hide()
	Minimap:RegisterForDrag("LeftButton")
	MinimapZoneTextButton:RegisterForDrag("LeftButton")
	self:SetLock(db.lock)
	
	self:SecureHook("updateContainerFrameAnchors", "CreateMoversAndSetMovables")
end

function mod:OnEnable()
	db = self.db.profile
	MinimapCluster:SetClampedToScreen(db.clamp)
	self:SetLock(db.lock)
	self:Update()
	self:RegisterEvent("UPDATE_WORLD_STATES")
	self:UPDATE_WORLD_STATES()
	self:CreateMoversAndSetMovables()
end

function mod:UPDATE_WORLD_STATES()
	for i = 1, NUM_EXTENDED_UI_FRAMES do
		local name = "WorldStateCaptureBar"..i
		local f = _G[name]
		if f and not movables[name] then
			movables[name] = L["Capture Bars"]
		end
	end
	self:CreateMoversAndSetMovables()
end

mod.movables = movables

do
	local function start(self)
		local f = self:GetParent()
		local x, y = f:GetLeft(), f:GetBottom()
		f:StartMoving()
	end

	local function stop(self)
		local f = self:GetParent()
		f:StopMovingOrSizing()
		
		local x, y = f:GetCenter()
		local n = f:GetName()
		
		db.framePositions[n] = db.framePositions[n] or {}
		db.framePositions[n].x = x
		db.framePositions[n].y = y
	end

	function mod:CreateMoversAndSetMovables()
		for frame, text in pairs(movables) do
			local pf = _G[frame]
			if pf then
				local name = "SexyMapMover" .. frame
				local f = _G[name]
				if not f then
					f = CreateFrame("Frame", name, pf)
					tinsert(movers, f)
					local l = f:CreateFontString(nil, nil, "GameFontNormalSmall")
					f:EnableMouse(true)
					pf:SetMovable(true)
					f:SetScript("OnMouseDown", start)
					f:SetScript("OnMouseUp", stop)
					f:SetScript("OnLeave", stop)
					l:SetText(("%s mover"):format(text))
					l:SetPoint("BOTTOM", f, "TOP")					
					f:SetBackdrop(parent.backdrop)
					f:SetBackdropColor(0, 0.6, 0, 1)
				end
				
				f:ClearAllPoints()
				f:SetAllPoints()
				if f:GetTop() - f:GetBottom() < 30 then
					f:ClearAllPoints()
					f:SetPoint("TOPLEFT", pf, "TOPLEFT")
					f:SetPoint("TOPRIGHT", pf, "TOPRIGHT")
					f:SetHeight(40)
				end
				
				if f:GetRight() - f:GetLeft() < 30 then
					f:ClearAllPoints()
					f:SetPoint("TOPLEFT", pf, "TOPLEFT")
					f:SetHeight(40)
					f:SetWidth(40)
				end
				
				pf:SetScript("OnShow", nil)
				pf:SetScript("OnHide", nil)
				
				if not db.lock then
					f:Hide()
				end
				
				if db.framePositions[frame] then
					local x, y = db.framePositions[frame].x, db.framePositions[frame].y
					pf:ClearAllPoints()
					pf:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)				
				end
			end
		end
		self:SetMovers(db.lock)
	end
end

do
	local function start(self)
		MinimapCluster:StartMoving()
	end

	local function stop(self)
		MinimapCluster:StopMovingOrSizing()
	end
	
	function mod:Update()
		MinimapCluster:SetScale(db.scale or 1)
		-- MinimapCluster:SetAlpha(db.alpha or 1)
	end

	function mod:SetLock(v)
		if v then
			Minimap:SetScript("OnDragStart", nil)
			Minimap:SetScript("OnDragStop", nil)
			MinimapZoneTextButton:SetScript("OnDragStart", nil)
			MinimapZoneTextButton:SetScript("OnDragStop", nil)
		else
			Minimap:SetScript("OnDragStart", start)
			Minimap:SetScript("OnDragStop", stop)
			MinimapZoneTextButton:SetScript("OnDragStart", start)
			MinimapZoneTextButton:SetScript("OnDragStop", stop)
		end
		MinimapCluster:SetMovable(true)
	end
	
	function mod:SetMovers()
		local v = db.movers
		if v then
			for _, f in ipairs(movers) do
				f.showParent = not not f:GetParent():IsVisible()		-- convert nil -> false
				f:GetParent():Show()
				f:Show()
			end	
		else
			for _, f in ipairs(movers) do
				if f.showParent == false then
					f:GetParent():Hide()
				end
				f.showParent = nil
				f:Hide()
			end
		end
		
		if v then
			self.watchFrameAdvancedStatus = GetCVar(InterfaceOptionsObjectivesPanelAdvancedWatchFrame.cvar)
			self.watchFrameLockStatus = WatchFrame.locked
			
			local button = InterfaceOptionsObjectivesPanelAdvancedWatchFrame
			button:SetChecked(true)
			InterfaceOptionsPanel_CheckButton_Update(button)
			
			WatchFrame_Unlock(WatchFrame)
		else
			local c = GetCVar(InterfaceOptionsObjectivesPanelAdvancedWatchFrame.cvar)
			
			if self.watchFrameLockStatus then
				WatchFrame_Lock(WatchFrame)
			end
		end
	end
end
