
if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
	return
end

local _, sm = ...
sm.movers = {}

local mod = sm.movers
local L = sm.L

local options = {
	type = "group",
	name = L["Movers"],
	args = {
		desc = {
			order = 1,
			name = "Enable the ability to move specific UI elements.",
			type = "description",
			width = "full",
		},
		moveVehicleAndDurability = {
			order = 2,
			name = "Enable Vehicle Seat and Durability (Armored Man)",
			type = "toggle",
			width = "full",
			confirm = function(info, v)
				if not v then
					return "Disabling this will reload your UI. Are you sure?"
				end
			end,
			get = function()
				return mod.db.moveVehicleAndDurability
			end,
			set = function(info, v)
				mod.db.moveVehicleAndDurability = v
				if v then
					mod:EnableDurabilityMover()
					mod:EnableVehicleMover()
				else
					mod.db.lockVehicleAndDurability = false
					mod.db.positions.durability = nil
					mod.db.positions.vehicle = nil
					ReloadUI()
				end
			end,
		},
		lockVehicleAndDurability = {
			order = 3,
			name = "Lock Vehicle Seat and Durability (Armored Man)",
			type = "toggle",
			width = "full",
			get = function()
				return mod.db.lockVehicleAndDurability
			end,
			set = function(info, v)
				mod.db.lockVehicleAndDurability = v
				if v then
					SexyMapDurabilityMover:Hide()
					SexyMapVehicleMover:Hide()
				else
					SexyMapDurabilityMover:Show()
					SexyMapVehicleMover:Show()
				end
			end,
			disabled = function() return not mod.db.moveVehicleAndDurability end,
		},
		spacer = {
			order = 4,
			name = " ",
			type = "description",
			width = "full",
		},
		moveObjectives = {
			order = 5,
			name = "Enable Quest Tracker",
			type = "toggle",
			width = "full",
			confirm = function(info, v)
				if not v then
					return "Disabling this will reload your UI. Are you sure?"
				end
			end,
			get = function()
				return mod.db.moveObjectives
			end,
			set = function(info, v)
				mod.db.moveObjectives = v
				if v then
					mod:EnableObjectivesMover()
				else
					mod.db.lockObjectives = false
					mod.db.positions.objectives = nil
					ReloadUI()
				end
			end,
		},
		lockObjectives = {
			order = 6,
			name = "Lock Quest Tracker",
			type = "toggle",
			width = "full",
			get = function()
				return mod.db.lockObjectives
			end,
			set = function(info, v)
				mod.db.lockObjectives = v
				if v then
					SexyMapObjectivesMover:Hide()
				else
					SexyMapObjectivesMover:Show()
				end
			end,
			disabled = function() return not mod.db.moveObjectives end,
		},
	},
}

function mod:OnInitialize(profile)
	if type(profile.movers) ~= "table" or profile.movers.framePositions then
		profile.movers = {
			moveObjectives = false,
			lockObjectives = false,
			moveVehicleAndDurability = false,
			lockVehicleAndDurability = false,
			positions = {},
		}
	end
	self.db = profile.movers
end

function mod:OnEnable()
	sm.core:RegisterModuleOptions("Movers", options, L["Movers"])
	if self.db.moveVehicleAndDurability then
		self:EnableDurabilityMover()
		self:EnableVehicleMover()
	end
	if self.db.moveObjectives then
		self:EnableObjectivesMover()
	end
end

function mod:EnableDurabilityMover()
	if SexyMapDurabilityMover then return end
	local DurabilityFrame = DurabilityFrame

	local frame = CreateFrame("Frame", "SexyMapDurabilityMover")
	if self.db.positions.durability then
		local tbl = self.db.positions.durability
		frame:SetPoint(tbl[1], UIParent, tbl[2], tbl[3], tbl[4])
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
	frame:SetSize(65, 80) -- defaults: 60, 75
	if self.db.lockVehicleAndDurability then
		frame:Hide()
	else
		frame:Show()
	end
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetMovable(true)

	hooksecurefunc(DurabilityFrame, "SetWidth", function(self)
		local width = self:GetWidth()
		frame:SetWidth(width + 5)
	end)

	local function SetPoint(self)
		sm.core.frame.ClearAllPoints(self)
		-- TOPRIGHT is our only choice or we'd create SetPoint errors in UIParent.lua
		-- Where SetPoint is called by Blizz without performing a ClearAllPoints first
		sm.core.frame.SetPoint(self, "TOPRIGHT", frame, "TOPRIGHT")
	end
	hooksecurefunc(DurabilityFrame, "SetPoint", SetPoint)
	SetPoint(DurabilityFrame)

	frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local a, _, b, c, d = self:GetPoint()
		mod.db.positions.durability = {a, b, c, d}
	end)

	local bg = frame:CreateTexture()
	bg:SetAllPoints(frame)
	bg:SetColorTexture(0, 1, 0, 0.3)
	bg:Show()

	local header = frame:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
	header:SetPoint("BOTTOM", frame, "TOP")
	header:SetText(L["Armored Man"])
	header:Show()
end

function mod:EnableVehicleMover()
	if SexyMapVehicleMover then return end

	local VehicleSeatIndicator = VehicleSeatIndicator

	local frame = CreateFrame("Frame", "SexyMapVehicleMover")
	if self.db.positions.vehicle then
		local tbl = self.db.positions.vehicle
		frame:SetPoint(tbl[1], UIParent, tbl[2], tbl[3], tbl[4])
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
	frame:SetSize(100, 100) -- defaults: 128, 128
	if self.db.lockVehicleAndDurability then
		frame:Hide()
	else
		frame:Show()
	end
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetMovable(true)

	local function SetPoint(self)
		sm.core.frame.ClearAllPoints(self)
		-- TOPRIGHT is our only choice or we'd create SetPoint errors in UIParent.lua
		-- Where SetPoint is called by Blizz without performing a ClearAllPoints first
		sm.core.frame.SetPoint(self, "TOPRIGHT", frame, "TOPRIGHT")
	end
	hooksecurefunc(VehicleSeatIndicator, "SetPoint", SetPoint)
	SetPoint(VehicleSeatIndicator)

	frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local a, _, b, c, d = self:GetPoint()
		mod.db.positions.vehicle = {a, b, c, d}
	end)

	local bg = frame:CreateTexture()
	bg:SetAllPoints(frame)
	bg:SetColorTexture(0, 1, 0, 0.3)
	bg:Show()

	local header = frame:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
	header:SetPoint("BOTTOM", frame, "TOP")
	header:SetText(L["Vehicle Seat"])
	header:Show()
end

function mod:EnableObjectivesMover()
	if SexyMapObjectivesMover then return end

	local ObjectiveTrackerFrame = ObjectiveTrackerFrame

	local frame = CreateFrame("Frame", "SexyMapObjectivesMover")
	if self.db.positions.objectives then
		local tbl = self.db.positions.objectives
		frame:SetPoint(tbl[1], UIParent, tbl[2], tbl[3], tbl[4])
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
	frame:SetSize(235, 600) -- defaults: 235, 140
	if self.db.lockObjectives then
		frame:Hide()
	else
		frame:Show()
	end
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetMovable(true)

	local function SetPoint(self)
		sm.core.frame.ClearAllPoints(self)
		sm.core.frame.SetPoint(self, "TOPRIGHT", frame, "TOPRIGHT")
		sm.core.frame.SetPoint(self, "BOTTOMRIGHT", frame, "BOTTOMRIGHT")
	end
	hooksecurefunc(ObjectiveTrackerFrame, "SetPoint", SetPoint)
	SetPoint(ObjectiveTrackerFrame)

	-- Allows the sorting that occurs in UIParent.lua to skip the ObjectiveTrackerFrame
	ObjectiveTrackerFrame:SetMovable(true)
	ObjectiveTrackerFrame:SetUserPlaced(true)
	ObjectiveTrackerFrame:SetMovable(false)

	frame:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local a, _, b, c, d = self:GetPoint()
		mod.db.positions.objectives = {a, b, c, d}
	end)

	local bg = frame:CreateTexture()
	bg:SetAllPoints(frame)
	bg:SetColorTexture(0, 1, 0, 0.3)
	bg:Show()

	local header = frame:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
	header:SetPoint("BOTTOM", frame, "TOP")
	header:SetText(L["Objectives Tracker"])
	header:Show()
end
