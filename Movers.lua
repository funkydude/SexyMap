
local _, addon = ...
local parent = addon.SexyMap
local mod = addon.SexyMap:NewModule("Movers")
local L = addon.L

local db
local options = {
	type = "group",
	name = "General",
	args = {
		movers = {
			order = 3,
			name = L["Show movers"],
			type = "toggle",
			get = function()
				return db.movers
			end,
			set = function(info, v)
				db.movers = v
				--mod:SetMovers()
			end,
		},
	},
}

local movables = {
	["DurabilityFrame"] = L["Armored Man"],
	["WatchFrame"] = L["Objectives Tracker"],
	["Boss1TargetFrame"] = L["Boss frames (Gunships, etc)"],
}
local movers = {}

function mod:OnInitialize()
	local defaults = {
		profile = {
			enabled = false,
			framePositions = {}
		}
	}
	self.db = parent.db:RegisterNamespace("Movers", defaults)
	db = self.db.profile
	parent:RegisterModuleOptions("General", options, "General")

	if updateContainerFrameAnchors then --XXX MoP compat
		self:SecureHook("updateContainerFrameAnchors", "CreateMoversAndSetMovables")
	else
		self:SecureHook("UpdateContainerFrameAnchors", "CreateMoversAndSetMovables")
	end
end

function mod:WatchFrame_Update(...)
	if not WatchFrame:IsUserPlaced() then reanchorWatchFrame() end
	self.hooks.WatchFrame_Update(...)
	-- updateWatchFrameHeight()
	-- WatchFrame:SetHeight(WatchFrame.realHeight or WatchFrame:GetHeight())
end

function mod:OnEnable()
	db = self.db.profile
	--self:SetLock(db.lock)
	--self:Update()
	--[[if not _G.Capping then
		self:RegisterEvent("UPDATE_WORLD_STATES")
		self:UPDATE_WORLD_STATES()
		movables["VehicleSeatIndicator"] = L["Vehicle Seat"]
	end
	self:CreateMoversAndSetMovables()
	self:RawHook("WatchFrame_Update", true)]]
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
		f:SetClampedToScreen(false)
	end

	local function stop(self)
		local f = self:GetParent()
		f:StopMovingOrSizing()

		local x, y = f:GetLeft(), f:GetTop()
		local n = f:GetName()

		db.framePositions[n] = db.framePositions[n] or {}
		db.framePositions[n].x = x
		db.framePositions[n].y = y
		f:SetUserPlaced(true)
		-- f:SetClampedToScreen(f.clamped)
	end

	function mod:CreateMoversAndSetMovables()
		if InCombatLockdown() then return end
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

				if not db.lock then
					f:Hide()
				end

				if db.framePositions[frame] then
					local x, y = db.framePositions[frame].x, db.framePositions[frame].y
					pf:ClearAllPoints()
					pf:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
					pf:SetUserPlaced(true)
				end
			end
		end
		self:SetMovers()
	end
end

do

	function reanchorWatchFrame()
		local mx, my = MinimapCluster:GetCenter()
		local sx, sy = UIParent:GetCenter()
		local change, from, to, side = false, nil, nil, nil
		if my < sy then
			from = "BOTTOM"
			to = "TOP"
			side = to
		else
			from = "TOP"
			to = "BOTTOM"
			side = to
		end
		if mx < sx then
			from = from .. "LEFT"
			to = to .. "LEFT"
		else
			from = from .. "RIGHT"
			to = to .. "RIGHT"
		end
		WatchFrame:ClearAllPoints()
		WatchFrame:SetPoint(from, MinimapCluster, to)
		-- WatchFrame:SetHeight(1000)
		WatchFrame:SetPoint(side, UIParent, side)
	end

	function updateWatchFrameHeight()
		-- local ofrom, frm, oto = WatchFrame:GetPoint(1)
		-- print("|cFF33FF99SexyMap|r: Got point for watchframe:", ofrom, oto)
		-- if ofrom and ofrom:match("BOTTOM") then
			local highest, lowest = -9999, 9999
			for i = 1, 200 do
				local l = _G["WatchFrameLine"..i]
				if l and l:IsVisible() then
					local top, bottom = l:GetTop(), l:GetBottom()
					if top and top > highest then
						highest = top
					end
					if bottom and bottom < lowest then
						lowest = bottom
					end
				end
			end
			if highest ~= -9999 and lowest ~= 9999 then
				ht = highest - lowest + 50
				WatchFrame:SetHeight(ht)
				WatchFrame.realHeight = ht
			end
		-- end
	end

	local function dragUpdate()
		mod:WatchFrame_Update(WatchFrame)
	end
	local function start(self)
		MinimapCluster:StartMoving()
		MinimapCluster:SetScript("OnUpdate", dragUpdate)
	end

	local function stop(self)
		MinimapCluster:StopMovingOrSizing()
		MinimapCluster:SetScript("OnUpdate", nil)
	end

	function mod:Update()
		MinimapCluster:SetScale(db.scale or 1)
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
		WatchFrame:SetPoint("BOTTOM", UIParent, "BOTTOM")
	end
end

