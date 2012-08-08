
local _, addon = ...
local parent = addon.SexyMap
local modName = "Fader"
local mod = addon.SexyMap:NewModule(modName, "AceHook-3.0")
local L = addon.L
local db

local options = {
	type = "group",
	name = modName,
	childGroups = "tab",
	disabled = function() return not db.enabled end,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enable fader"],
			desc = L["Enable fader functionality"],
			get = function()
				return db.enabled
			end,
			set = function(info, v)
				db.enabled = v
				return v and mod:Enable() or mod:Disable()
			end,
			disabled = false,
			order = 1,
			width = "full",
		},
		normalOpacity = {
			type = "range",
			name = L["Normal Opacity"],
			min = 0,
			max = 1,
			step = 0.01,
			isPercent = true,
			get = function()
				return db.normalOpacity
			end,
			set = function(info, v)
				db.normalOpacity = math.max(0.0001, v)
				MinimapCluster:SetAlpha(v)
			end,
			order = 2
		},
		hoverOpacity = {
			type = "range",
			name = L["Hover Opacity"],
			min = 0,
			max = 1,
			step = 0.01,
			isPercent = true,
			get = function()
				return db.hoverOpacity
			end,
			set = function(info, v)
				db.hoverOpacity = math.max(0.0001, v)
			end,
			order = 3
		},
	}
}

local defaults = {
	profile = {
		enabled = false,
		hoverOpacity = 0.25,
		normalOpacity = 1
	}
}
function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
	parent:RegisterModuleOptions(modName, options, modName)
	db = self.db.profile
	self:SetEnabledState(db.enabled)
end

do
	local faderFrame = CreateFrame("Frame")
	local fading = {}
	local fadeTarget = 0
	local fadeTime
	local totalTime = 0

	local function fade(self, t)
		totalTime = totalTime + t
		local pct = min(1, totalTime / fadeTime)
		local total = 0
		for k, v in pairs(fading) do
			local alpha = v + ((fadeTarget - v) * pct)
			total = total + 1
			if not k.SetAlpha then
				print("|cFF33FF99SexyMap|r: No SetAlpha for", k:GetName())
			end

			k:SetAlpha(alpha)
			k:Show()
			if pct == 1 then
				fading[k] = nil
				total = total - 1
				if fadeTarget == 0 then
					k:Hide()
				end
			end
		end

		if total == 0 then
			faderFrame:SetScript("OnUpdate", nil)
		end
	end

	local function startFade(f, t, to)
		fading[f] = f:GetAlpha()
		fadeTarget = to
		fadeTime = t or 0.2
		totalTime = 0
		faderFrame:SetScript("OnUpdate", fade)
	end

	local updateTimer
	function mod:OnEnable()
		self:HookAll(MinimapCluster, "OnEnter", MinimapCluster:GetChildren())
		startFade(MinimapCluster, 0.2, db.normalOpacity)
		if not updateTimer then
			updateTimer = CreateFrame("Frame"):CreateAnimationGroup()
			local anim = updateTimer:CreateAnimation()
			updateTimer:SetScript("OnLoop", self.CheckExited)
			anim:SetOrder(1)
			anim:SetDuration(0.1)
			updateTimer:SetLooping("REPEAT")
		end
	end

	function mod:OnDisable()
		self:UnhookAll(MinimapCluster, "OnEnter", MinimapCluster:GetChildren())
		startFade(MinimapCluster, 0.2, 1)
		updateTimer:Stop()
	end

	function mod:OnEnter()
		updateTimer:Play()
		startFade(MinimapCluster, 0.2, db.hoverOpacity)
	end

	function mod:OnLeave()
		updateTimer:Stop()
		startFade(MinimapCluster, 0.2, db.normalOpacity)
	end

	function mod:CheckExited()
		local f = GetMouseFocus()
		if f then
			local p = f:GetParent()
			while(p and p ~= UIParent) do
				if p == MinimapCluster then return true end
				p = p:GetParent()
			end
			mod:OnLeave()
		end
	end
end

function mod:HookAll(frame, script, ...)
	self:HookScript(frame, script)
	for i = 1, select("#", ...) do
		local f = select(i, ...)
		self:HookScript(f, script)
	end
end

function mod:UnookAll(frame, script, ...)
	self:Unhook(frame, script)
	for i = 1, select("#", ...) do
		local f = select(i, ...)
		self:Unhook(f, script)
	end
end