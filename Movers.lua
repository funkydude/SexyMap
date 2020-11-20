
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
					--
				else
					mod.db.lockObjectives = false
					mod.db.positions.objectives = nil
					ReloadUI()
				end
			end,
			disabled = function() return true end,
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
					--
				else
					--
				end
			end,
			disabled = function() return not mod.db.moveObjectives end,
		},
	},
}

local movables = {
	--["ObjectiveTrackerFrame"] = L["Objectives Tracker"],
	--["VehicleSeatIndicator"] = L["Vehicle Seat"],
	--["Boss1TargetFrame"] = L["Boss Frames"],
}
local movers = {}

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

do
	local started = nil
	function mod:Start()
		if started then return end
		started = true

		hooksecurefunc("UpdateContainerFrameAnchors", self.CreateMoversAndSetMovables)

		self:CreateMoversAndSetMovables()
	end
end

do
	local function start(self)
		local f = self:GetParent()
		f:StartMoving()
	end

	local function stop(self)
		local f = self:GetParent()
		f:StopMovingOrSizing()

		local x, y = f:GetLeft(), f:GetTop()
		local n = f:GetName()

		mod.db.framePositions[n] = mod.db.framePositions[n] or {}
		mod.db.framePositions[n].x = x
		mod.db.framePositions[n].y = y
	end

	function mod:CreateMoversAndSetMovables()
		for frame, text in pairs(movables) do
			local pf = _G[frame]
			if pf then
				local name = "SexyMapMover" .. frame
				local f = _G[name]
				if not f then
					f = CreateFrame("Frame", name, pf, "BackdropTemplate")
					tinsert(movers, f)
					local l = f:CreateFontString(nil, nil, "GameFontNormalSmall")
					f:EnableMouse(true)
					pf:SetMovable(true)
					f:SetScript("OnMouseDown", start)
					f:SetScript("OnMouseUp", stop)
					f:SetScript("OnLeave", stop)
					l:SetText(("%s mover"):format(text))
					l:SetPoint("BOTTOM", f, "TOP")
					f:SetBackdrop(sm.backdrop)
					f:SetBackdropColor(0, 0.6, 0, 1)
				end

				f:ClearAllPoints()
				f:SetAllPoints()

				if not mod.db.lock then
					f:Hide()
				end

				if mod.db.framePositions[frame] then
					local x, y = mod.db.framePositions[frame].x, mod.db.framePositions[frame].y
					pf:ClearAllPoints()
					pf:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
					if frame == "ObjectiveTrackerFrame" then
						pf:SetPoint("BOTTOM", UIParent, "BOTTOM")
					end
				end
			end
		end
		mod:SetMovers()
	end
end

function mod:SetMovers()
	local v = mod.db.enabled and (not mod.db.lock)
	if v then
		for _, f in ipairs(movers) do
			f.showParent = not not f:GetParent():IsVisible() -- convert nil -> false
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
end

