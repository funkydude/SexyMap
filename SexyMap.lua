
local name, sm = ...
sm.Core = {}
local mod = sm.Core
local L = sm.L

local cbh = LibStub:GetLibrary("CallbackHandler-1.0"):New(mod)
local frame = CreateFrame("Frame")
sm.backdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	insets = {left = 4, top = 4, right = 4, bottom = 4},
	edgeSize = 16,
	tile = true
}

function mod:OnCoreEnable()
	local defaults = {
		profile = {}
	}
	mod.db = LibStub("AceDB-3.0"):New("SexyMapDB", defaults)

	-- Configure Slash Handler
	SlashCmdList[name] = function() InterfaceOptionsFrame_OpenToCategory(name) end
	SLASH_SexyMap1 = "/minimap"
	SLASH_SexyMap2 = "/sexymap"

	Minimap:SetScript("OnMouseUp", function(frame, button)
		if button == "RightButton" and mod:GetModule("General").db.profile.rightClickToConfig then
			InterfaceOptionsFrame_OpenToCategory(name)
		else
			Minimap_OnClick(frame, button)
		end
	end)

	mod.db.RegisterCallback(mod, "OnProfileChanged", ReloadUI)
	mod.db.RegisterCallback(mod, "OnProfileCopied", ReloadUI)
	mod.db.RegisterCallback(mod, "OnProfileReset", ReloadUI)

	sm.General:OnGeneralEnable()
	sm.Shapes:OnShapesEnable()
	local tbl = {}
	for k,v in pairs(sm) do
		if v.OnEnable then
			tinsert(tbl, k)
		end
	end
	-- Arrange the config screens A-Z
	table.sort(tbl)
	for i=1, #tbl do
		sm[tbl[i]]:OnEnable()
	end
	wipe(tbl)
	tbl = nil

	mod:StartFrameGrab()

	mod:RegisterModuleOptions("Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(mod.db), L["Profiles"])

	frame:UnregisterEvent("PLAYER_LOGIN")
	frame:SetScript("OnEvent", nil)
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", mod.OnCoreEnable)

function mod:GetModule(module)
	return sm[module]
end

function mod:RegisterModuleOptions(modName, optionTbl, displayName)
	if modName == "General" then
		LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(name, optionTbl)
		LibStub("AceConfigDialog-3.0"):AddToBlizOptions(name)
	else
		LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(name..modName, optionTbl)
		LibStub("AceConfigDialog-3.0"):AddToBlizOptions(name..modName, displayName, name)
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

	function mod:StartFrameGrab()
		-- Try to capture new frames periodically
		-- We'd use ADDON_LOADED but it's too early, some addons load a minimap icon afterwards
		local updateTimer = frame:CreateAnimationGroup()
		local anim = updateTimer:CreateAnimation()
		updateTimer:SetScript("OnLoop", function() grabFrames(Minimap:GetChildren()) end)
		anim:SetOrder(1)
		anim:SetDuration(1)
		updateTimer:SetLooping("REPEAT")
		updateTimer:Play()

		grabFrames(MinimapZoneTextButton, Minimap, MiniMapTrackingButton, MinimapBackdrop:GetChildren()) -- More Icons
	end
end

