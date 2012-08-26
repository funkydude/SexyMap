
local sexymap, addon = ...
addon.SexyMap = LibStub("AceAddon-3.0"):NewAddon(sexymap)
local mod = addon.SexyMap
local L = addon.L

local cbh = LibStub:GetLibrary("CallbackHandler-1.0"):New(mod)

addon.backdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	insets = {left = 4, top = 4, right = 4, bottom = 4},
	edgeSize = 16,
	tile = true
}

function mod:OnInitialize()
	local defaults = {
		profile = {}
	}
	self.db = LibStub("AceDB-3.0"):New("SexyMapDB", defaults)

	-- Configure Slash Handler
	SlashCmdList[sexymap] = function() InterfaceOptionsFrame_OpenToCategory(sexymap) end
	SLASH_SexyMap1 = "/minimap"
	SLASH_SexyMap2 = "/sexymap"
end

function mod:OnEnable()
	if not self.profilesRegistered then
		self:RegisterModuleOptions("Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db), L["Profiles"])
		self.profilesRegistered = true
	end

	Minimap:SetScript("OnMouseUp", mod.Minimap_OnClick)

	self.db.RegisterCallback(self, "OnProfileChanged", "ReloadAddon")
	self.db.RegisterCallback(self, "OnProfileCopied", "ReloadAddon")
	self.db.RegisterCallback(self, "OnProfileReset", "ReloadAddon")
end

function mod:ReloadAddon()
	self:Disable()
	self:Enable()
end

function mod.Minimap_OnClick(frame, button)
	if button == "RightButton" and mod:GetModule("General").db.profile.rightClickToConfig then
		InterfaceOptionsFrame_OpenToCategory(sexymap)
	else
		Minimap_OnClick(frame, button)
	end
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
	local alreadyGrabbed = {}
	local grabFrames = function(...)
		for i=1, select("#", ...) do
			local f = select(i, ...)
			local n = f:GetName()
			if n and not alreadyGrabbed[n] then
				alreadyGrabbed[n] = true
				cbh:Fire("SexyMap_NewFrame", f)
			end
		end
	end

	local frame = CreateFrame("Frame")
	frame:RegisterEvent("PLAYER_LOGIN")
	frame:SetScript("OnEvent", function(f)
		-- Try to capture new frames periodically
		-- We'd use ADDON_LOADED but it's too early, some addons load a minimap icon afterwards
		local updateTimer = f:CreateAnimationGroup()
		local anim = updateTimer:CreateAnimation()
		updateTimer:SetScript("OnLoop", function() grabFrames(Minimap:GetChildren()) end)
		anim:SetOrder(1)
		anim:SetDuration(1)
		updateTimer:SetLooping("REPEAT")
		updateTimer:Play()

		grabFrames(MinimapZoneTextButton, Minimap, MiniMapTrackingButton, MinimapBackdrop:GetChildren()) -- More Icons

		f:UnregisterEvent("PLAYER_LOGIN")
		f:SetScript("OnEvent", nil)
	end)
end

