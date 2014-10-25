
local _, sm = ...
sm.movers = {}

local mod = sm.movers
local L = sm.L

local options = {
	type = "group",
	name = L["Movers"],
	args = {
		--desc = {
		--	order = 0.5,
		--	name = L["Movers Warning"],
		--	type = "description",
		--},
		enable = {
			order = 1,
			name = L["Enable Movers"],
			type = "toggle",
			confirm = function(info, v)
				if not v then
					return L["Disabling the movers will make them reset next time you relog, are you sure?"]
				end
			end,
			get = function()
				return mod.db.enabled
			end,
			set = function(info, v)
				mod.db.enabled = v
				mod:SetMovers()
				if v then
					mod:Start()
				end
			end,
		},
		lock = {
			order = 2,
			name = L["Lock Movers"],
			type = "toggle",
			get = function()
				return mod.db.lock
			end,
			set = function(info, v)
				mod.db.lock = v
				mod:SetMovers()
			end,
			disabled = function() return not mod.db.enabled end,
		},
	},
}

local movables = {
	["DurabilityFrame"] = L["Armored Man"],
	["ObjectiveTrackerFrame"] = L["Objectives Tracker"],
	["VehicleSeatIndicator"] = L["Vehicle Seat"],
	--["Boss1TargetFrame"] = L["Boss Frames"],
}
local movers = {}

function mod:OnInitialize(profile)
	if type(profile.movers) ~= "table" then
		profile.movers = {
			enabled = false,
			lock = false,
			framePositions = {},
		}
	end
	self.db = profile.movers
end

function mod:OnEnable()
	sm.core:RegisterModuleOptions("Movers", options, L["Movers"])
	self.db.framePositions.WatchFrame = nil -- XXX temp
	if self.db.enabled then
		self:SetMovers()
		self:Start()
	end
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

