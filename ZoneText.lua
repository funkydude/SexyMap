
local _, sm = ...
sm.zonetext = {}

local mod = sm.zonetext
local L = sm.L

local media = LibStub("LibSharedMedia-3.0")

local options = {
	type = "group",
	name = L["Zone Text"],
	args = {
		xOffset = {
			type = "range",
			name = L["Horizontal Position"],
			order = 1,
			min = -250,
			max = 250,
			step = 1,
			bigStep = 5,
			get = function() return mod.db.xOffset end,
			set = function(info, v) mod.db.xOffset = v mod:UpdateLayout() end
		},
		yOffset = {
			type = "range",
			name = L["Vertical Position"],
			order = 2,
			min = -250,
			max = 250,
			step = 1,
			bigStep = 5,
			get = function() return mod.db.yOffset end,
			set = function(info, v) mod.db.yOffset = v mod:UpdateLayout() end
		},
		spacer1 = {
			order = 3,
			type = "description",
			width = "normal",
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
			get = function() return MinimapZoneTextButton:GetWidth() end,
			set = function(info, v) mod.db.width = v mod:UpdateLayout() end
		},
		font = {
			type = "select",
			name = L["Font"],
			order = 5,
			dialogControl = "LSM30_Font",
			values = AceGUIWidgetLSMlists.font,
			get = function()
				local font = nil
				local curFont = MinimapZoneText:GetFont()
				for k,v in pairs(AceGUIWidgetLSMlists.font) do
					if v == curFont then
						font = k
						break
					end
				end
				return mod.db.font or font
			end,
			set = function(info, v)
				mod.db.font = v
				mod:UpdateLayout()
			end
		},
		fontSize = {
			type = "range",
			name = L["Font Size"],
			order = 6,
			min = 4,
			max = 30,
			step = 1,
			bigStep = 1,
			get = function() return mod.db.fontsize or select(2, MinimapZoneText:GetFont()) end,
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
					return MinimapZoneText:GetTextColor()
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
				return (sm.buttons.db.visibilitySettings.MinimapZoneTextButton or "hover") == v
			end,
			set = function(info, v)
				sm.buttons.db.visibilitySettings.MinimapZoneTextButton = v
				sm.buttons:ChangeFrameVisibility(MinimapZoneTextButton, v)
			end,
			disabled = function()
				return not sm.buttons.db.controlVisibility
			end,
		}
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
		}
	end
	self.db = profile.zonetext
end

function mod:OnEnable()
	sm.core:RegisterModuleOptions("ZoneText", options, L["Zone Text"])

	MinimapZoneText:ClearAllPoints()
	MinimapZoneText:SetAllPoints()
	MinimapZoneTextButton:SetHeight(26)
	MinimapZoneTextButton:SetBackdrop(sm.backdrop)
	MinimapZoneTextButton:SetFrameStrata("MEDIUM")

	self:UpdateLayout()
	-- Hook Minimap.xml function "Minimap_Update", we let Blizz update the text and customize it afterwards.
	MinimapCluster:HookScript("OnEvent", self.ZoneChanged)
end

function mod:UpdateLayout()
	MinimapZoneTextButton:ClearAllPoints()
	MinimapZoneTextButton:SetParent(Minimap)
	MinimapZoneTextButton:SetPoint("BOTTOM", Minimap, "TOP", mod.db.xOffset, mod.db.yOffset)
	MinimapZoneTextButton:SetBackdropColor(mod.db.bgColor.r, mod.db.bgColor.g, mod.db.bgColor.b, mod.db.bgColor.a)
	MinimapZoneTextButton:SetBackdropBorderColor(mod.db.borderColor.r, mod.db.borderColor.g, mod.db.borderColor.b, mod.db.borderColor.a)
	local a, b, c = GameFontNormal:GetFont()
	MinimapZoneText:SetFont(mod.db.font and media:Fetch("font", mod.db.font) or a, mod.db.fontsize or b, c)

	self:ZoneChanged()
end

function mod:ZoneChanged()
	local width = max(MinimapZoneText:GetStringWidth() * 1.3, mod.db.width or 0)
	MinimapZoneTextButton:SetHeight(MinimapZoneText:GetStringHeight() + 10)
	MinimapZoneTextButton:SetWidth(width)
	if mod.db.fontColor.r then
		MinimapZoneText:SetTextColor(mod.db.fontColor.r, mod.db.fontColor.g, mod.db.fontColor.b, mod.db.fontColor.a)
	end
end

