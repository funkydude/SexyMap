
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
	if self.db.moveCaptureBar then
		self:EnableCaptureBarMover()
	end
	if self.db.moveTopWidget then
		self:EnableTopWidgetMover()
	end
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
