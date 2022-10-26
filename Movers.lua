
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
			moveDurability = false,
			lockDurability = false,
			moveVehicle = false,
			lockVehicle = false,
			moveCaptureBar = false,
			lockCaptureBar = false,
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
	if self.db.moveCaptureBar then
		self:EnableCaptureBarMover()
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
