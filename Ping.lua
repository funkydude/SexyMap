local parent = SexyMap
local modName = "Ping"
local mod = SexyMap:NewModule(modName, "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SexyMap")
local db

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
		}
	}
}

local defaults = {
	profile = {
		showPing = true
	}
}
function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
	db = self.db.profile
	parent:RegisterModuleOptions(modName, options, modName)
end

function mod:OnEnable()
	db = self.db.profile
	self:RegisterEvent("MINIMAP_PING")
end

function mod:MINIMAP_PING(self, arg1)
	if not UnitIsUnit(arg1, "player") then
		if db.showPing then
			local t = RAID_CLASS_COLORS[select(2, UnitClass(arg1))]
			local r, g, b = t.r, t.g, t.b
			DEFAULT_CHAT_FRAME:AddMessage(("Ping: |cFF%x%x%x%s"):format(r * 255, g * 255, b * 255, UnitName(arg1)))
		end
	end
end
