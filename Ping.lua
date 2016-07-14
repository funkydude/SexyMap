
local _, sm = ...
sm.ping = {}

local mod = sm.ping
local L = sm.L

local pingFrame

local options = {
	type = "group",
	name = L["Ping"],
	disabled = function() return not mod.db.showPing end,
	args = {
		show = {
			type = "toggle",
			order = 1,
			name = L["Show who pinged"],
			width = "full",
			get = function()
				return mod.db.showPing
			end,
			set = function(info, v)
				mod.db.showPing = v
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
				return mod.db.showAt == v
			end,
			set = function(info, v)
				mod.db.showAt = v
			end,
		}
	}
}

function mod:OnInitialize(profile)
	if type(profile.ping) ~= "table" then
		profile.ping = {
			showPing = true,
			showAt = "map"
		}
	end
	self.db = profile.ping
end

function mod:OnEnable()
	sm.core:RegisterModuleOptions("Ping", options, L["Ping"])

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
	anim:SetFromAlpha(0)
	anim:SetToAlpha(1)
	anim:SetOrder(1)
	anim:SetDuration(3)
	anim:SetStartDelay(3)

	pingFrame:SetScript("OnEvent", function(_, _, unit)
		local class = select(2, UnitClass(unit))
		local color
		if class then
			color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
		else
			color = GRAY_FONT_COLOR
		end
		if mod.db.showAt == "chat" then
			DEFAULT_CHAT_FRAME:AddMessage(("%s: |cFF%02x%02x%02x%s|r"):format(L["Ping"], color.r * 255, color.g * 255, color.b * 255, UnitName(unit)))
		else
			pingFrame.name:SetFormattedText("|cFF%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, UnitName(unit))
			pingFrame:SetWidth(pingFrame.name:GetStringWidth() + 14)
			pingFrame:SetHeight(pingFrame.name:GetStringHeight() + 10)
			animGroup:Stop()
			pingFrame:Show()
			animGroup:Play()
		end
	end)

	if mod.db.showPing then
		pingFrame:RegisterEvent("MINIMAP_PING")
	end
end

