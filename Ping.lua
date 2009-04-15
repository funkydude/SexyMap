local parent = SexyMap
local modName = "Ping"
local mod = SexyMap:NewModule(modName, "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SexyMap")
local db

local pingFrame

local options = {
	type = "group",
	name = modName,
	args = {
		show = {
			type = "toggle",
			name = L["Show who pinged"],
			get = function()
				return db.showPing
			end,
			set = function(info, v)
				db.showPing = v
			end
		},
		showAt = {
			type = "multiselect",
			name = L["Show..."],
			values = {
				map = L["On minimap"],
				chat = L["In chat"]
			},
			get = function(info, v)
				return db.showAt == v
			end,
			set = function(info, v)
				db.showAt = v
			end
		}
	}
}

local defaults = {
	profile = {
		showPing = true,
		showAt = "map"
	}
}
function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
	db = self.db.profile
	parent:RegisterModuleOptions(modName, options, modName)
	pingFrame = CreateFrame("Frame", "SexyMapPingFrame", MinimapPing)
	pingFrame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		insets = {left = 2, top = 2, right = 2, bottom = 2},
		edgeSize = 12,
		tile = true
	})
	pingFrame:SetBackdropColor(0,0,0,0.8)
	pingFrame:SetBackdropBorderColor(0,0,0,0.6)
	pingFrame:SetHeight(20)
	pingFrame:SetWidth(100)
	pingFrame:SetPoint("TOP", MinimapPing, "BOTTOM", 0, 15)
	pingFrame:SetFrameStrata("HIGH")
	pingFrame.name = pingFrame:CreateFontString(nil, nil, "GameFontNormalSmall")
	pingFrame.name:SetAllPoints()
	pingFrame:Hide()
end

function mod:OnEnable()
	db = self.db.profile
	self:RegisterEvent("MINIMAP_PING")
end

function mod:MINIMAP_PING(self, arg1)
	if not UnitIsUnit(arg1, "player") or true then
		if db.showPing then
			local t = RAID_CLASS_COLORS[select(2, UnitClass(arg1))]
			local r, g, b = t.r, t.g, t.b
			if db.showAt == "chat" then
				DEFAULT_CHAT_FRAME:AddMessage(("Ping: |cFF%02x%02x%02x%s|r"):format(r * 255, g * 255, b * 255, UnitName(arg1)))
				pingFrame:Hide()
			else
				pingFrame.name:SetText(("|cFF%02x%02x%02x%s|r"):format(r * 255, g * 255, b * 255, UnitName(arg1)))
				pingFrame:SetWidth(pingFrame.name:GetStringWidth() + 14)
				pingFrame:SetHeight(pingFrame.name:GetStringHeight() + 10)
				pingFrame:Show()
			end
		end
	end
end
