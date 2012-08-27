
local _, sm = ...
sm.Ping = {}

local parent = sm.Core
local mod = sm.Ping
local L = sm.L

local pingFrame

local options = {
	type = "group",
	name = L["Ping"],
	disabled = function() return not mod.db.profile.showPing end,
	args = {
		show = {
			type = "toggle",
			order = 1,
			name = L["Show who pinged"],
			width = "full",
			get = function()
				return mod.db.profile.showPing
			end,
			set = function(info, v)
				mod.db.profile.showPing = v
				if v then
					pingFrame:RegisterEvent("MINIMAP_PING")
				else
					pingFrame:UnregisterEvent("MINIMAP_PING")
				end
			end,
			disabled = false,
		},
		fade = {
			type = "multiselect",
			name = "",
			order = 2,
			values = {
				["chat"] = L["Show inside chat"],
				["map"] = L["Show on minimap"],
			},
			get = function(info, v)
				return mod.db.profile.showAt == v
			end,
			set = function(info, v)
				mod.db.profile.showAt = v
			end,
		}
	}
}

function mod:OnEnable()
	local defaults = {
		profile = {
			showPing = true,
			showAt = "map"
		}
	}
	self.db = parent.db:RegisterNamespace("Ping", defaults)
	parent:RegisterModuleOptions("Ping", options, L["Ping"])

	pingFrame = CreateFrame("Frame", "SexyMapPingFrame", Minimap)
	pingFrame:SetBackdrop(sm.backdrop)
	pingFrame:SetBackdropColor(0,0,0,0.8)
	pingFrame:SetBackdropBorderColor(0,0,0,0.6)
	pingFrame:SetHeight(20)
	pingFrame:SetWidth(100)
	pingFrame:SetPoint("TOP", Minimap, "TOP", 0, 15)
	pingFrame:SetFrameStrata("HIGH")
	pingFrame.name = pingFrame:CreateFontString(nil, nil, "GameFontNormalSmall")
	pingFrame.name:SetAllPoints()
	pingFrame:Hide()

	local animGroup = pingFrame:CreateAnimationGroup()
	local anim = animGroup:CreateAnimation("Alpha")
	animGroup:SetScript("OnFinished", function() pingFrame:Hide() end)
	anim:SetChange(-1)
	anim:SetOrder(1)
	anim:SetDuration(3)
	anim:SetStartDelay(3)

	pingFrame:SetScript("OnEvent", function(_, _, unit)
		local class = select(2, UnitClass(unit))
		local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class] or GRAY_FONT_COLOR
		if mod.db.profile.showAt == "chat" then
			DEFAULT_CHAT_FRAME:AddMessage(("Ping: |cFF%02x%02x%02x%s|r"):format(color.r * 255, color.g * 255, color.b * 255, UnitName(unit)))
		else
			pingFrame.name:SetFormattedText("|cFF%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, UnitName(unit))
			pingFrame:SetWidth(pingFrame.name:GetStringWidth() + 14)
			pingFrame:SetHeight(pingFrame.name:GetStringHeight() + 10)
			animGroup:Stop()
			pingFrame:Show()
			animGroup:Play()
		end
	end)

	if self.db.profile.showPing then
		pingFrame:RegisterEvent("MINIMAP_PING")
	end
end

