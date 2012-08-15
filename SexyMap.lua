
local sexymap, addon = ...
addon.SexyMap = LibStub("AceAddon-3.0"):NewAddon(sexymap, "AceEvent-3.0", "AceHook-3.0")
local mod = addon.SexyMap
local L = addon.L

local _G = getfenv(0)
local pairs, ipairs, type, select = _G.pairs, _G.ipairs, _G.type, _G.select

local min = _G.math.min
local MinimapCluster = _G.MinimapCluster
local GetMouseFocus = _G.GetMouseFocus

local defaults = {
	profile = {}
}

mod.backdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	insets = {left = 4, top = 4, right = 4, bottom = 4},
	edgeSize = 16,
	tile = true
}

function mod:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("SexyMapDB", defaults)

	-- Configure Slash Handler
	SlashCmdList[sexymap] = function() InterfaceOptionsFrame_OpenToCategory(sexymap) end
	SLASH_SexyMap1 = "/minimap"
	SLASH_SexyMap2 = "/sexymap"
end

local updateTimer, fadeTimer, fadeAnim
function mod:OnEnable()
	if not self.profilesRegistered then
		self:RegisterModuleOptions("Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db), L["Profiles"])
		self.profilesRegistered = true
	end

	Minimap:SetScript("OnMouseUp", mod.Minimap_OnClick)
	self:HookAll(MinimapCluster, "OnEnter", MinimapCluster:GetChildren())

	self.db.RegisterCallback(self, "OnProfileChanged", "ReloadAddon")
	self.db.RegisterCallback(self, "OnProfileCopied", "ReloadAddon")
	self.db.RegisterCallback(self, "OnProfileReset", "ReloadAddon")

	-- Terrible, clean this up
	if not updateTimer then
		updateTimer = CreateFrame("Frame"):CreateAnimationGroup()
		local anim = updateTimer:CreateAnimation()
		updateTimer:SetScript("OnLoop", self.CheckExited)
		anim:SetOrder(1)
		anim:SetDuration(0.1)
		updateTimer:SetLooping("REPEAT")
	end
	if not fadeTimer then
		fadeTimer = CreateFrame("Frame"):CreateAnimationGroup()
		fadeAnim = fadeTimer:CreateAnimation()
		fadeTimer:SetScript("OnFinished", self.EnableFade)
		fadeAnim:SetOrder(1)
		fadeAnim:SetDuration(1)
		fadeTimer:SetLooping("NONE")
	end
end

function mod:ReloadAddon()
	self:Disable()
	self:Enable()
end

function mod:HookAll(frame, script, ...)
	self:HookScript(frame, script)
	for i = 1, select("#", ...) do
		local f = select(i, ...)
		self:HookScript(f, script)
	end
end

function mod.Minimap_OnClick(frame, button)
	if button == "RightButton" and mod:GetModule("General").db.profile.rightClickToConfig then
		InterfaceOptionsFrame_OpenToCategory(sexymap)
	else
		Minimap_OnClick(frame, button)
	end
end

function mod:OnDisable()
end

function mod:RegisterModuleOptions(name, optionTbl, displayName)
	if name == "General" then
		LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(sexymap, optionTbl)
		LibStub("AceConfigDialog-3.0"):AddToBlizOptions(sexymap)
	else
		LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(sexymap..name, optionTbl)
		LibStub("AceConfigDialog-3.0"):AddToBlizOptions(sexymap..name, displayName, sexymap)
	end
end

do
	local faderFrame = CreateFrame("Frame")
	local fading = {}
	local fadeTarget = 0
	local fadeTime
	local totalTime = 0
	local hoverOverrides, hoverExempt = {}, {}

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
			-- k:Show()
			if alpha == fadeTarget then
				fading[k] = nil
				total = total - 1
				-- if fadeTarget == 0 then
					-- k:Hide()
				-- end
			end
		end

		if total == 0 then
			faderFrame:SetScript("OnUpdate", nil)
		end
	end

	local function startFade(t)
		fadeTime = t or 0.2
		totalTime = 0
		faderFrame:SetScript("OnUpdate", fade)
	end

	local hoverButtons = {}
	function mod:RegisterHoverButton(frame, showFunc)
		local frameName = frame
		if type(frame) == "string" then
			frame = _G[frame]
		elseif frame then
			frameName = frame:GetName()
		end
		if not frame then
			-- print("|cFF33FF99SexyMap|r: Unable to register", frameName, ", does not exit")
			return
		end
		if hoverButtons[frame] then return end
		if not hoverExempt[frame] then
			frame:SetAlpha(0)
		end
		-- frame:Hide()
		hoverButtons[frame] = showFunc or true
	end

	function mod:UnregisterHoverButton(frame)
		if type(frame) == "string" then
			frame = _G[frame]
		end
		if not frame then return end
		if hoverButtons[frame] == true or type(hoverButtons[frame]) == "function" and hoverButtons[frame](frame) then
			frame:SetAlpha(1)
			-- frame:Show()
		end
		hoverButtons[frame] = nil
	end

	local function UpdateHoverOverrides(self, e)
		for k, v in pairs(hoverOverrides) do
			local ret = v(k, e)
			if ret then
				hoverExempt[k] = true
				k:SetAlpha(1)
				fading[k] = nil
			else
				hoverExempt[k] = false
				mod:OnExit()
			end
		end
	end

	function mod:RegisterHoverOverride(frame, func, ...)
		local frameName = frame
		if type(frame) == "string" then
			frame = _G[frame]
		elseif frame then
			frameName = frame:GetName()
		end

		hoverOverrides[frame] = func
		for i = 1, select("#", ...) do
			local event = select(i, ...)
			if not faderFrame:IsEventRegistered(event) then
				faderFrame:RegisterEvent(event)
			end
		end
		faderFrame:SetScript("OnEvent", UpdateHoverOverrides)
	end

	function mod:OnEnter()
		updateTimer:Play()
		fadeTarget = 1
		for k, v in pairs(hoverButtons) do
			if not hoverExempt[k] and (v == true or type(v) == "function" and v(k)) then
				fading[k] = k:GetAlpha()
			end
		end
		startFade()
	end

	function mod:OnExit()
		updateTimer:Stop()

		fadeTarget = 0
		for k, v in pairs(hoverButtons) do
			if not hoverExempt[k] then
				fading[k] = k:GetAlpha()
			end
		end
		startFade()
	end

	function mod:CheckExited()
		if mod.fadeDisabled then return end
		local f = GetMouseFocus()
		if f then
			local p = f:GetParent()
			while(p and p ~= UIParent) do
				if p == MinimapCluster then return true end
				p = p:GetParent()
			end
			mod:OnExit()
		end
	end

	function mod:EnableFade()
		mod.fadeDisabled = false
	end

	function mod:DisableFade(forHowLong)
		self.fadeDisabled = true
		self:OnEnter()
		if forHowLong and forHowLong > 0 then
			fadeTimer:Stop()
			fadeAnim:SetDuration(forHowLong)
			fadeTimer:Play()
		end
	end
end
