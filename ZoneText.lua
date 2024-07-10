
local _, sm = ...
sm.zonetext = {}

local mod = sm.zonetext
local L = sm.L
local zoneTextButton, zoneTextFont = nil, nil

local media = LibStub("LibSharedMedia-3.0")

local options = {
	type = "group",
	name = L["Zone Text"],
	args = {
		xOffset = {
			type = "range",
			name = L["Horizontal Position"],
			order = 1,
			max = 2000,
			softMax = 250,
			min = -2000,
			softMin = -250,
			step = 1,
			bigStep = 5,
			get = function() return mod.db.xOffset end,
			set = function(info, v) mod.db.xOffset = v mod:UpdateLayout() end
		},
		yOffset = {
			type = "range",
			name = L["Vertical Position"],
			order = 2,
			max = 2000,
			softMax = 250,
			min = -2000,
			softMin = -250,
			step = 1,
			bigStep = 5,
			get = function() return mod.db.yOffset end,
			set = function(info, v) mod.db.yOffset = v mod:UpdateLayout() end
		},
		spacer1 = {
			order = 3,
			type = "description",
			name = "",
		},
		width = {
			type = "range",
			name = L["Text Width"],
			order = 4,
			min = 50,
			max = 400,
			step = 1,
			bigStep = 4,
			get = function() return zoneTextButton:GetWidth() end,
			set = function(info, v) mod.db.width = v mod:UpdateLayout() end
		},
		font = {
			type = "select",
			name = L["Font"],
			order = 5,
			values = media:List("font"),
			itemControl = "DDI-Font",
			get = function()
				for i, v in next, media:List("font") do
					if v == mod.db.font then return i end
				end
			end,
			set = function(_, value)
				local list = media:List("font")
				local font = list[value]
				mod.db.font = font
				mod:UpdateLayout()
			end,
		},
		fontSize = {
			type = "range",
			name = L["Font Size"],
			order = 6,
			min = 4,
			max = 30,
			step = 1,
			bigStep = 1,
			get = function() return mod.db.fontsize or (select(2, GameFontNormal:GetFont())) end,
			set = function(info, v)
				mod.db.fontsize = v
				mod:UpdateLayout()
			end
		},
		fontColor = {
			type = "color",
			name = L["Font Color"],
			order = 7,
			hasAlpha = true,
			get = function()
				if mod.db.fontColor.r then
					return mod.db.fontColor.r, mod.db.fontColor.g, mod.db.fontColor.b, mod.db.fontColor.a
				else
					return zoneTextFont:GetTextColor()
				end
			end,
			set = function(info, r, g, b, a)
				mod.db.fontColor.r, mod.db.fontColor.g, mod.db.fontColor.b, mod.db.fontColor.a = r, g, b, a
				mod:UpdateLayout()
			end
		},
		bgColor = {
			type = "color",
			name = L["Background Color"],
			order = 8,
			hasAlpha = true,
			get = function()
				return mod.db.bgColor.r, mod.db.bgColor.g, mod.db.bgColor.b, mod.db.bgColor.a
			end,
			set = function(info, r, g, b, a)
				mod.db.bgColor.r, mod.db.bgColor.g, mod.db.bgColor.b, mod.db.bgColor.a = r, g, b, a
				mod:UpdateLayout()
			end
		},
		borderColor = {
			type = "color",
			name = L["Border Color"],
			order = 9,
			hasAlpha = true,
			get = function()
				return mod.db.borderColor.r, mod.db.borderColor.g, mod.db.borderColor.b, mod.db.borderColor.a
			end,
			set = function(info, r, g, b, a)
				mod.db.borderColor.r, mod.db.borderColor.g, mod.db.borderColor.b, mod.db.borderColor.a = r, g, b, a
				mod:UpdateLayout()
			end
		},
		monochrome = {
			type = "toggle",
			name = L.monochrome,
			desc = L.monochromeDesc,
			order = 9.1,
			get = function() return mod.db.monochrome end,
			set = function(_, v)
				mod.db.monochrome = v
				mod:UpdateLayout()
			end
		},
		outline = {
			type = "select",
			name = L.outline,
			order = 9.2,
			values = {
				NONE = L.none,
				OUTLINE = L.thin,
				THICKOUTLINE = L.thick,
			},
			get = function() return mod.db.outline end,
			set = function(_, v)
				mod.db.outline = v
				mod:UpdateLayout()
			end
		},
		fade = {
			type = "multiselect",
			name = function()
				if sm.buttons.db.controlVisibility then
					return L["Show %s:"]:format(L["Zone Text"])
				else
					return L["Show %s:"]:format(L["Zone Text"]) .. " |cFF0276FD" .. L["(Requires button visibility control in the Buttons menu)"] .. "|r"
				end
			end,
			order = 10,
			values = {
				["always"] = L["Always"],
				["never"] = L["Never"],
				["hover"] = L["On Hover"],
			},
			get = function(info, v)
				return (sm.buttons.db.visibilitySettings.SexyMapZoneTextButton or "hover") == v
			end,
			set = function(info, v)
				sm.buttons.db.visibilitySettings.SexyMapZoneTextButton = v
				sm.buttons:ChangeFrameVisibility(SexyMapZoneTextButton, v) -- Buttons module
			end,
			disabled = function()
				return not sm.buttons.db.controlVisibility
			end,
		},
		useSecureButton = {
			order = 11,
			name = L.zoneTextSecureButtonEnable,
			desc = L.zoneTextSecureButtonEnableDesc,
			type = "toggle",
			width = "full",
			confirm = function() return L.disableWarning end,
			get = function()
				return mod.db.useSecureButton
			end,
			set = function(info, v)
				mod.db.useSecureButton = v
				ReloadUI()
			end,
			disabled = function()
				if MinimapZoneTextButton then return true end
			end,
		},
	}
}

function mod:OnInitialize(profile)
	if type(profile.zonetext) ~= "table" then
		profile.zonetext = {
			xOffset = 0,
			yOffset = 0,
			bgColor = {r = 0, g = 0, b = 0, a = 1},
			borderColor = {r = 0, g = 0, b = 0, a = 1},
			fontColor = {},
			font = media:GetDefault("font"),
			useSecureButton = false,
			monochrome = false,
			outline = "NONE",
		}
	end

	-- XXX temp 10.1.0
	if not profile.zonetext.monochrome then
		profile.zonetext.monochrome = false
	end
	if not profile.zonetext.outline then
		profile.zonetext.outline = "NONE"
	end

	self.db = profile.zonetext
end

function mod:OnEnable()
	sm.core:RegisterModuleOptions("ZoneText", options, L["Zone Text"])

	if MinimapZoneTextButton then
		-- Kill Blizz Frame
		sm.core.button.SetParent(MinimapZoneTextButton, sm.core.button)
		sm.core.font.SetParent(MinimapZoneText, sm.core.button)
		MinimapCluster:UnregisterEvent("ZONE_CHANGED") -- Minimap.xml line 719-722 script "<OnLoad>" as of wow 9.0.1
		MinimapCluster:UnregisterEvent("ZONE_CHANGED_INDOORS")
		MinimapCluster:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
		local MinimapZoneTextButton, MinimapZoneText = MinimapZoneTextButton, MinimapZoneText -- Safety
		hooksecurefunc(MinimapZoneTextButton, "SetParent", function()
			sm.core.button.SetParent(MinimapZoneTextButton, sm.core.button)
		end)
		hooksecurefunc(MinimapZoneText, "SetParent", function()
			sm.core.font.SetParent(MinimapZoneText, sm.core.button)
		end)
		zoneTextButton = CreateFrame("Button", "SexyMapZoneTextButton", Minimap, "BackdropTemplate") -- Create our own zone text
	else
		MinimapCluster.ZoneTextButton:SetParent(sm.core.button)
		MinimapCluster.BorderTop:SetParent(sm.core.button)
		if mod.db.useSecureButton then
			zoneTextButton = CreateFrame("Button", "SexyMapZoneTextButton", Minimap, "BackdropTemplate,SecureActionButtonTemplate") -- Create our own zone text
			zoneTextButton:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
			zoneTextButton:SetAttribute("type1", "click")
			zoneTextButton:SetAttribute("clickbutton1", MinimapCluster.ZoneTextButton)
		else
			zoneTextButton = CreateFrame("Button", "SexyMapZoneTextButton", Minimap, "BackdropTemplate") -- Create our own zone text
			zoneTextButton:SetScript("OnClick", function()
				if not InCombatLockdown() then
					ToggleWorldMap()
				else
					print(L.zoneTextCombatClick)
				end
			end)
		end
	end

	zoneTextButton:SetPoint("BOTTOM", Minimap, "TOP", mod.db.xOffset, mod.db.yOffset)
	zoneTextButton:SetClampedToScreen(true)
	zoneTextButton:SetClampRectInsets(4,-4,-4,4) -- Allow kissing the edge of the screen when hiding the backdrop border (size 4)
	zoneTextButton:SetFrameStrata("LOW")
	zoneTextButton:SetFixedFrameStrata(true)
	zoneTextButton:SetFrameLevel(20) -- Above Questie minimap blips
	zoneTextButton:SetFixedFrameLevel(true)
	zoneTextButton.oshow = function() end -- Silly workaround to prevent the MBB addon grabing this frame

	zoneTextFont = zoneTextButton:CreateFontString()
	zoneTextFont:SetPoint("CENTER", zoneTextButton, "CENTER")
	zoneTextFont:SetJustifyH("CENTER")
	zoneTextButton:SetBackdrop(sm.backdrop)

	--do
	--	local zoneTextFlags = nil
	--	if self.db.profile.zoneTextConfig.monochrome and self.db.profile.zoneTextConfig.outline ~= "NONE" then
	--		zoneTextFlags = "MONOCHROME," .. self.db.profile.zoneTextConfig.outline
	--	elseif self.db.profile.zoneTextConfig.monochrome then
	--		zoneTextFlags = "MONOCHROME"
	--	elseif self.db.profile.zoneTextConfig.outline ~= "NONE" then
	--		zoneTextFlags = self.db.profile.zoneTextConfig.outline
	--	end
	--	zoneTextFont:SetFont(media:Fetch("font", self.db.profile.zoneTextConfig.font), self.db.profile.zoneTextConfig.fontSize, zoneTextFlags)
	--end

	zoneTextButton:RegisterEvent("ZONE_CHANGED") -- Minimap.xml line 719-722 script "<OnLoad>" as of wow 9.0.1
	zoneTextButton:RegisterEvent("ZONE_CHANGED_INDOORS")
	zoneTextButton:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	zoneTextButton:SetScript("OnEvent", mod.ZoneChanged)

	do
		local tt = CreateFrame("GameTooltip", "SexyMapZoneTextTooltip", zoneTextButton, "GameTooltipTemplate")
		local GetZonePVPInfo, GetZoneText, GetSubZoneText = C_PvP and C_PvP.GetZonePVPInfo or GetZonePVPInfo, GetZoneText, GetSubZoneText
		zoneTextButton:SetScript("OnEnter", function(self) -- Minimap.lua line 68 function "Minimap_SetTooltip" as of wow 9.0.1
			tt:SetOwner(self, "ANCHOR_LEFT")
			local pvpType, _, factionName = GetZonePVPInfo()
			local zoneName = GetZoneText()
			local subzoneName = GetSubZoneText()
			if subzoneName == zoneName then
				subzoneName = ""
			end
			tt:AddLine(zoneName, 1.0, 1.0, 1.0)
			if pvpType == "sanctuary" then
				--tt:AddLine(subzoneName, unpack(frame.db.profile.zoneTextConfig.colorSanctuary))
				--tt:AddLine(SANCTUARY_TERRITORY, unpack(frame.db.profile.zoneTextConfig.colorSanctuary))
				tt:AddLine(subzoneName, 0.41, 0.8, 0.94)
				tt:AddLine(SANCTUARY_TERRITORY, 0.41, 0.8, 0.94)
			elseif pvpType == "arena" then
				--tt:AddLine(subzoneName, unpack(frame.db.profile.zoneTextConfig.colorArena))
				--tt:AddLine(FREE_FOR_ALL_TERRITORY, unpack(frame.db.profile.zoneTextConfig.colorArena))
				tt:AddLine(subzoneName, 1.0, 0.1, 0.1)
				tt:AddLine(FREE_FOR_ALL_TERRITORY, 1.0, 0.1, 0.1)
			elseif pvpType == "friendly" then
				if factionName and factionName ~= "" then
					--tt:AddLine(subzoneName, unpack(frame.db.profile.zoneTextConfig.colorFriendly))
					--tt:AddLine(format(FACTION_CONTROLLED_TERRITORY, factionName), unpack(frame.db.profile.zoneTextConfig.colorFriendly))
					tt:AddLine(subzoneName, 0.1, 1.0, 0.1)
					tt:AddLine(format(FACTION_CONTROLLED_TERRITORY, factionName), 0.1, 1.0, 0.1)
				end
			elseif pvpType == "hostile" then
				if factionName and factionName ~= "" then
					--tt:AddLine(subzoneName, unpack(frame.db.profile.zoneTextConfig.colorHostile))
					--tt:AddLine(format(FACTION_CONTROLLED_TERRITORY, factionName), unpack(frame.db.profile.zoneTextConfig.colorHostile))
					tt:AddLine(subzoneName, 1.0, 0.1, 0.1)
					tt:AddLine(format(FACTION_CONTROLLED_TERRITORY, factionName), 1.0, 0.1, 0.1)
				end
			elseif pvpType == "contested" then
				--tt:AddLine(subzoneName, unpack(frame.db.profile.zoneTextConfig.colorContested))
				--tt:AddLine(CONTESTED_TERRITORY, unpack(frame.db.profile.zoneTextConfig.colorContested))
				tt:AddLine(subzoneName, 1.0, 0.7, 0.0)
				tt:AddLine(CONTESTED_TERRITORY, 1.0, 0.7, 0.0)
			elseif pvpType == "combat" then
				--tt:AddLine(subzoneName, unpack(frame.db.profile.zoneTextConfig.colorArena))
				--tt:AddLine(COMBAT_ZONE, unpack(frame.db.profile.zoneTextConfig.colorArena))
				tt:AddLine(subzoneName, 1.0, 0.1, 0.1)
				tt:AddLine(COMBAT_ZONE, 1.0, 0.1, 0.1)
			else
				--tt:AddLine(subzoneName, unpack(frame.db.profile.zoneTextConfig.colorNormal))
				tt:AddLine(subzoneName, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
			end
			tt:Show()
		end)
		zoneTextButton:SetScript("OnLeave", function() tt:Hide() end)
	end

	self:UpdateLayout()
	sm.buttons:NewFrame(zoneTextButton) -- Buttons module
end

function mod:OnLoadingScreenOver()
	self:ZoneChanged()
end

function mod:UpdateLayout()
	zoneTextButton:ClearAllPoints()
	zoneTextButton:SetPoint("BOTTOM", Minimap, "TOP", mod.db.xOffset, mod.db.yOffset)
	zoneTextButton:SetBackdropColor(mod.db.bgColor.r, mod.db.bgColor.g, mod.db.bgColor.b, mod.db.bgColor.a)
	zoneTextButton:SetBackdropBorderColor(mod.db.borderColor.r, mod.db.borderColor.g, mod.db.borderColor.b, mod.db.borderColor.a)
	local a, b = GameFontNormal:GetFont()
	local flags = nil
	if mod.db.monochrome and mod.db.outline ~= "NONE" then
		flags = "MONOCHROME," .. mod.db.outline
	elseif mod.db.monochrome then
		flags = "MONOCHROME"
	elseif mod.db.outline ~= "NONE" then
		flags = mod.db.outline
	end
	zoneTextFont:SetFont(mod.db.font and media:Fetch("font", mod.db.font) or a, mod.db.fontsize or b, flags)

	self:ZoneChanged()
end

do
	local GetMinimapZoneText, GetZonePVPInfo = GetMinimapZoneText, C_PvP and C_PvP.GetZonePVPInfo or GetZonePVPInfo
	function mod:ZoneChanged()
		local text = GetMinimapZoneText()
		zoneTextFont:SetText(text)

		local width = max(zoneTextFont:GetUnboundedStringWidth() + 16, mod.db.width or 0)
		zoneTextButton:SetWidth(width)
		zoneTextButton:SetHeight(zoneTextFont:GetStringHeight() + 10)

		if mod.db.fontColor.r then
			zoneTextFont:SetTextColor(mod.db.fontColor.r, mod.db.fontColor.g, mod.db.fontColor.b, mod.db.fontColor.a)
		else
			-- Minimap.lua line 47 function "Minimap_Update" as of wow 9.0.1
			local pvpType = GetZonePVPInfo()
			if pvpType == "sanctuary" then
				--local c = frame.db.profile.zoneTextConfig.colorSanctuary
				--zoneTextFont:SetTextColor(c[1], c[2], c[3], c[4])
				zoneTextFont:SetTextColor(0.41, 0.8, 0.94)
			elseif pvpType == "arena" then
				--local c = frame.db.profile.zoneTextConfig.colorArena
				--zoneTextFont:SetTextColor(c[1], c[2], c[3], c[4])
				zoneTextFont:SetTextColor(1.0, 0.1, 0.1)
			elseif pvpType == "friendly" then
				--local c = frame.db.profile.zoneTextConfig.colorFriendly
				--zoneTextFont:SetTextColor(c[1], c[2], c[3], c[4])
				zoneTextFont:SetTextColor(0.1, 1.0, 0.1)
			elseif pvpType == "hostile" then
				--local c = frame.db.profile.zoneTextConfig.colorHostile
				--zoneTextFont:SetTextColor(c[1], c[2], c[3], c[4])
				zoneTextFont:SetTextColor(1.0, 0.1, 0.1)
			elseif pvpType == "contested" then
				--local c = frame.db.profile.zoneTextConfig.colorContested
				--zoneTextFont:SetTextColor(c[1], c[2], c[3], c[4])
				zoneTextFont:SetTextColor(1.0, 0.7, 0.0)
			else
				--local c = frame.db.profile.zoneTextConfig.colorNormal
				--zoneTextFont:SetTextColor(c[1], c[2], c[3], c[4])
				zoneTextFont:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
			end
		end

		if zoneTextButton:IsMouseOver() then
			zoneTextButton:GetScript("OnLeave")()
			zoneTextButton:GetScript("OnEnter")(zoneTextButton)
		end
	end
end
