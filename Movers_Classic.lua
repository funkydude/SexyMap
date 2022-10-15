
local _, sm = ...
sm.movers = {}

local mod = sm.movers
local L = sm.L
local ClearAllPoints = sm.core.frame.ClearAllPoints
local SetPoint = sm.core.frame.SetPoint

local options = {
	type = "group",
	name = L["Movers"],
	args = {
		desc = {
			order = 1,
			name = L.moversDescription,
			type = "description",
			width = "full",
		},
		moveDurability = {
			order = 2,
			name = L.enableObject:format(L["Armored Man"]),
			type = "toggle",
			width = "full",
			confirm = function(info, v)
				if not v then
					return L.disableWarning
				end
			end,
			get = function()
				return mod.db.moveDurability
			end,
			set = function(info, v)
				mod.db.moveDurability = v
				if v then
					mod:EnableDurabilityMover()
				else
					mod.db.lockDurability = false
					mod.db.moverPositions.durability = nil
					ReloadUI()
				end
			end,
		},
		lockDurability = {
			order = 3,
			name = L.lockObject:format(L["Armored Man"]),
			type = "toggle",
			width = "full",
			get = function()
				return mod.db.lockDurability
			end,
			set = function(info, v)
				mod.db.lockDurability = v
				if v then
					SexyMapDurabilityMover:Hide()
				else
					SexyMapDurabilityMover:Show()
				end
			end,
			disabled = function() return not mod.db.moveDurability end,
		},
		spacer = {
			order = 4,
			name = " ",
			type = "description",
			width = "full",
		},
		moveVehicle = {
			order = 5,
			name = L.enableObject:format(L["Vehicle Seat"]),
			type = "toggle",
			width = "full",
			confirm = function(info, v)
				if not v then
					return L.disableWarning
				end
			end,
			get = function()
				return mod.db.moveVehicle
			end,
			set = function(info, v)
				mod.db.moveVehicle = v
				if v then
					mod:EnableVehicleMover()
				else
					mod.db.lockVehicle = false
					mod.db.moverPositions.vehicle = nil
					ReloadUI()
				end
			end,
			disabled = function() return not VehicleSeatIndicator end,
		},
		lockVehicle = {
			order = 6,
			name = L.lockObject:format(L["Vehicle Seat"]),
			type = "toggle",
			width = "full",
			get = function()
				return mod.db.lockVehicle
			end,
			set = function(info, v)
				mod.db.lockVehicle = v
				if v then
					SexyMapVehicleMover:Hide()
				else
					SexyMapVehicleMover:Show()
				end
			end,
			disabled = function() return not mod.db.moveVehicle end,
		},
		spacer2 = {
			order = 7,
			name = " ",
			type = "description",
			width = "full",
		},
		moveObjectives = {
			order = 8,
			name = L.enableObject:format(L["Objectives Tracker"]),
			type = "toggle",
			width = "full",
			confirm = function(info, v)
				if not v then
					return L.disableWarning
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
					mod.db.moverPositions.objectives = nil
					ReloadUI()
				end
			end,
		},
		lockObjectives = {
			order = 9,
			name = L.lockObject:format(L["Objectives Tracker"]),
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
		spacer3 = {
			order = 10,
			name = " ",
			type = "description",
			width = "full",
		},
		moveCaptureBar = {
			order = 11,
			name = L.enableObject:format(L.pvpCaptureBar),
			type = "toggle",
			width = "full",
			confirm = function(info, v)
				if not v then
					return L.disableWarning
				end
			end,
			get = function()
				return mod.db.moveCaptureBar
			end,
			set = function(info, v)
				mod.db.moveCaptureBar = v
				if v then
					mod:EnableCaptureBarMover()
				else
					mod.db.lockCaptureBar = false
					mod.db.moverPositions.capturebar = nil
					ReloadUI()
				end
			end,
		},
		lockCaptureBar = {
			order = 12,
			name = L.lockObject:format(L.pvpCaptureBar),
			type = "toggle",
			width = "full",
			get = function()
				return mod.db.lockCaptureBar
			end,
			set = function(info, v)
				mod.db.lockCaptureBar = v
				if v then
					SexyMapCaptureBarMover:Hide()
				else
					SexyMapCaptureBarMover:Show()
				end
			end,
			disabled = function() return not mod.db.moveCaptureBar end,
		},
		spacer4 = {
			order = 13,
			name = " ",
			type = "description",
			width = "full",
		},
		moveBuffs = {
			order = 14,
			name = L.enableObject:format(L.buffs),
			type = "toggle",
			width = "full",
			confirm = function(info, v)
				if not v then
					return L.disableWarning
				end
			end,
			get = function()
				return mod.db.moveBuffs
			end,
			set = function(info, v)
				mod.db.moveBuffs = v
				if v then
					mod:EnableBuffsMover()
				else
					mod.db.lockBuffs = false
					mod.db.moverPositions.buffs = nil
					ReloadUI()
				end
			end,
		},
		lockBuffs = {
			order = 15,
			name = L.lockObject:format(L.buffs),
			type = "toggle",
			width = "full",
			get = function()
				return mod.db.lockBuffs
			end,
			set = function(info, v)
				mod.db.lockBuffs = v
				if v then
					SexyMapBuffsFrameMover:Hide()
				else
					SexyMapBuffsFrameMover:Show()
				end
			end,
			disabled = function() return not mod.db.moveBuffs end,
		},
		spacer5 = {
			order = 16,
			name = " ",
			type = "description",
			width = "full",
		},
		moveTopCenterObjectivesWidget = {
			order = 17,
			name = L.enableObject:format(L.topCenterObjectivesWidget),
			type = "toggle",
			width = "full",
			confirm = function(info, v)
				if not v then
					return L.disableWarning
				end
			end,
			get = function()
				return mod.db.moveTopWidget
			end,
			set = function(info, v)
				mod.db.moveTopWidget = v
				if v then
					mod:EnableTopWidgetMover()
				else
					mod.db.lockTopWidget = false
					mod.db.moverPositions.topWidget = nil
					ReloadUI()
				end
			end,
		},
		lockTopCenterObjectivesWidget = {
			order = 18,
			name = L.lockObject:format(L.topCenterObjectivesWidget),
			type = "toggle",
			width = "full",
			get = function()
				return mod.db.lockTopWidget
			end,
			set = function(info, v)
				mod.db.lockTopWidget = v
				if v then
					SexyMapTopCenterWidgetMover:Hide()
				else
					SexyMapTopCenterWidgetMover:Show()
				end
			end,
			disabled = function() return not mod.db.moveTopWidget end,
		},
	},
}

function mod:OnInitialize(profile)
	if type(profile.movers) ~= "table" or not profile.movers.moverPositions then
		profile.movers = {
			moveObjectives = false,
			lockObjectives = false,
			moveDurability = false,
			lockDurability = false,
			moveVehicle = false,
			lockVehicle = false,
			moveCaptureBar = false,
			lockCaptureBar = false,
			moveBuffs = false,
			lockBuffs = false,
			moveTopWidget = false,
			lockTopWidget = false,
			moverPositions = {},
		}
	end
	self.db = profile.movers
end

function mod:OnEnable()
	sm.core:RegisterModuleOptions("Movers", options, L["Movers"])
	if self.db.moveDurability then
		self:EnableDurabilityMover()
	end
	if self.db.moveVehicle then
		self:EnableVehicleMover()
	end
	if self.db.moveObjectives then
		self:EnableObjectivesMover()
	end
	if self.db.moveCaptureBar then
		self:EnableCaptureBarMover()
	end
	if self.db.moveBuffs then
		self:EnableBuffsMover()
	end
	if self.db.moveTopWidget then
		self:EnableTopWidgetMover()
	end
end

function mod:EnableDurabilityMover()
	if SexyMapDurabilityMover then return end
	local DurabilityFrame = DurabilityFrame

	local frame = CreateFrame("Frame", "SexyMapDurabilityMover")
	if self.db.moverPositions.durability then
		local tbl = self.db.moverPositions.durability
		frame:SetPoint(tbl[1], UIParent, tbl[2], tbl[3], tbl[4])
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
	frame:SetSize(65, 80) -- defaults: 60, 75
	if self.db.lockDurability then
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

	local function SetNewPoint(self)
		ClearAllPoints(self)
		-- TOPRIGHT is our only choice or we'd create SetPoint errors in UIParent.lua
		-- Where SetPoint is called by Blizz without performing a ClearAllPoints first
		SetPoint(self, "TOPRIGHT", frame, "TOPRIGHT")
	end
	hooksecurefunc(DurabilityFrame, "SetPoint", SetNewPoint)
	SetNewPoint(DurabilityFrame)

	frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local a, _, b, c, d = self:GetPoint()
		mod.db.moverPositions.durability = {a, b, c, d}
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
	if not VehicleSeatIndicator then return end

	local frame = CreateFrame("Frame", "SexyMapVehicleMover")
	if self.db.moverPositions.vehicle then
		local tbl = self.db.moverPositions.vehicle
		frame:SetPoint(tbl[1], UIParent, tbl[2], tbl[3], tbl[4])
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
	frame:SetSize(100, 100) -- defaults: 128, 128
	if self.db.lockVehicle then
		frame:Hide()
	else
		frame:Show()
	end
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetMovable(true)

	local function SetNewPoint(self)
		ClearAllPoints(self)
		-- TOPRIGHT is our only choice or we'd create SetPoint errors in UIParent.lua
		-- Where SetPoint is called by Blizz without performing a ClearAllPoints first
		SetPoint(self, "TOPRIGHT", frame, "TOPRIGHT")
	end
	hooksecurefunc(VehicleSeatIndicator, "SetPoint", SetNewPoint)
	SetNewPoint(VehicleSeatIndicator)

	frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local a, _, b, c, d = self:GetPoint()
		mod.db.moverPositions.vehicle = {a, b, c, d}
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

	local ObjectiveTrackerFrame = WatchFrame or QuestWatchFrame -- Classic version of objective tracker. WatchFrame = Wrath, QuestWatchFrame = TBC/Vanilla

	local frame = CreateFrame("Frame", "SexyMapObjectivesMover")
	if self.db.moverPositions.objectives then
		local tbl = self.db.moverPositions.objectives
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

	local function SetNewPoint(self)
		ClearAllPoints(self)
		SetPoint(self, "TOPRIGHT", frame, "TOPRIGHT")
		SetPoint(self, "BOTTOMRIGHT", frame, "BOTTOMRIGHT")
	end
	hooksecurefunc(ObjectiveTrackerFrame, "SetPoint", SetNewPoint)
	SetNewPoint(ObjectiveTrackerFrame)

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
		mod.db.moverPositions.objectives = {a, b, c, d}
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

function mod:EnableCaptureBarMover()
	if SexyMapCaptureBarMover then return end
	local UIWidgetBelowMinimapContainerFrame = UIWidgetBelowMinimapContainerFrame

	local frame = CreateFrame("Frame", "SexyMapCaptureBarMover")
	if self.db.moverPositions.capturebar then
		local tbl = self.db.moverPositions.capturebar
		frame:SetPoint(tbl[1], UIParent, tbl[2], tbl[3], tbl[4])
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
	frame:SetSize(150, 30) -- No defaults, dynamically resizes
	if self.db.lockCaptureBar then
		frame:Hide()
	else
		frame:Show()
	end
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetMovable(true)

	local function SetNewPoint(self)
		ClearAllPoints(self)
		SetPoint(self, "TOPRIGHT", frame, "TOPRIGHT")
	end
	hooksecurefunc(UIWidgetBelowMinimapContainerFrame, "SetPoint", SetNewPoint)
	SetNewPoint(UIWidgetBelowMinimapContainerFrame)

	frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local a, _, b, c, d = self:GetPoint()
		mod.db.moverPositions.capturebar = {a, b, c, d}
	end)

	local bg = frame:CreateTexture()
	bg:SetAllPoints(frame)
	bg:SetColorTexture(0, 1, 0, 0.3)
	bg:Show()

	local header = frame:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
	header:SetPoint("BOTTOM", frame, "TOP")
	header:SetText(L.pvpCaptureBar)
	header:Show()
end

function mod:EnableBuffsMover()
	if SexyMapBuffsFrameMover then return end
	local BuffFrame = BuffFrame

	local frame = CreateFrame("Frame", "SexyMapBuffsFrameMover")
	if self.db.moverPositions.buffs then
		local tbl = self.db.moverPositions.buffs
		frame:SetPoint(tbl[1], UIParent, tbl[2], tbl[3], tbl[4])
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
	frame:SetSize(190, 225) -- defaults: 50, 50
	if self.db.lockBuffs then
		frame:Hide()
	else
		frame:Show()
	end
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetMovable(true)

	local function SetNewPoint(self)
		ClearAllPoints(self)
		SetPoint(self, "TOPRIGHT", frame, "TOPRIGHT")
	end
	hooksecurefunc(BuffFrame, "SetPoint", SetNewPoint)
	SetNewPoint(BuffFrame)

	frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local a, _, b, c, d = self:GetPoint()
		mod.db.moverPositions.buffs = {a, b, c, d}
	end)

	local bg = frame:CreateTexture()
	bg:SetAllPoints(frame)
	bg:SetColorTexture(0, 1, 0, 0.3)
	bg:Show()

	local header = frame:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
	header:SetPoint("BOTTOM", frame, "TOP")
	header:SetText(L.buffs)
	header:Show()
end

function mod:EnableTopWidgetMover()
	if SexyMapTopCenterWidgetMover then return end
	local UIWidgetTopCenterContainerFrame = UIWidgetTopCenterContainerFrame

	local frame = CreateFrame("Frame", "SexyMapTopCenterWidgetMover")
	if self.db.moverPositions.topWidget then
		local tbl = self.db.moverPositions.topWidget
		frame:SetPoint(tbl[1], UIParent, tbl[2], tbl[3], tbl[4])
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
	frame:SetSize(220, 40) -- No defaults, dynamically resizes
	if self.db.lockTopWidget then
		frame:Hide()
	else
		frame:Show()
	end
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetMovable(true)

	local function SetNewPoint(self)
		ClearAllPoints(self)
		SetPoint(self, "TOP", frame, "TOP")
	end
	hooksecurefunc(UIWidgetTopCenterContainerFrame, "SetPoint", SetNewPoint)
	SetNewPoint(UIWidgetTopCenterContainerFrame)

	frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local a, _, b, c, d = self:GetPoint()
		mod.db.moverPositions.topWidget = {a, b, c, d}
	end)

	local bg = frame:CreateTexture()
	bg:SetAllPoints(frame)
	bg:SetColorTexture(0, 1, 0, 0.3)
	bg:Show()

	local header = frame:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
	header:SetPoint("BOTTOM", frame, "TOP")
	header:SetText(L.topCenterObjectivesWidget)
	header:Show()
end
