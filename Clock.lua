
local _, addon = ...
local parent = addon.SexyMap
local modName = "Clock"
local media = LibStub("LibSharedMedia-3.0")
local mod = addon.SexyMap:NewModule(modName)
local L = addon.L

local updateLayout = function()
	TimeManagerClockButton:ClearAllPoints()
	TimeManagerClockButton:SetPoint("TOP", Minimap, "BOTTOM", mod.db.profile.xOffset, mod.db.profile.yOffset)
	TimeManagerClockButton:SetBackdropColor(mod.db.profile.bgColor.r, mod.db.profile.bgColor.g, mod.db.profile.bgColor.b, mod.db.profile.bgColor.a)
	TimeManagerClockButton:SetBackdropBorderColor(mod.db.profile.borderColor.r, mod.db.profile.borderColor.g, mod.db.profile.borderColor.b, mod.db.profile.borderColor.a)
	local a, b, c = TimeManagerClockTicker:GetFont()
	TimeManagerClockTicker:SetFont(mod.db.profile.font and media:Fetch("font", mod.db.profile.font) or a, mod.db.profile.fontsize or b, c)
	if mod.db.profile.fontColor.r then
		TimeManagerClockTicker:SetTextColor(mod.db.profile.fontColor.r, mod.db.profile.fontColor.g, mod.db.profile.fontColor.b, mod.db.profile.fontColor.a)
	end
	local width = max(TimeManagerClockTicker:GetStringWidth() * 1.3, 0)
	TimeManagerClockButton:SetHeight(TimeManagerClockTicker:GetStringHeight() + 10)
	TimeManagerClockButton:SetWidth(width)
end

local options = {
	type = "group",
	name = modName,
	args = {
		xOffset = {
			type = "range",
			name = L["Horizontal Position"],
			order = 1,
			min = -250,
			max = 250,
			step = 1,
			bigStep = 5,
			get = function() return mod.db.profile.xOffset end,
			set = function(info, v) mod.db.profile.xOffset = v updateLayout() end
		},
		yOffset = {
			type = "range",
			name = L["Vertical Position"],
			order = 2,
			min = -250,
			max = 250,
			step = 1,
			bigStep = 5,
			get = function() return mod.db.profile.yOffset end,
			set = function(info, v) mod.db.profile.yOffset = v updateLayout() end
		},
		spacer1 = {
			order = 3,
			type = "description",
			width = "normal",
			name = "",
		},
		fontSize = {
			type = "range",
			name = L["Font Size"],
			order = 4,
			min = 4,
			max = 30,
			step = 1,
			bigStep = 1,
			get = function() return mod.db.profile.fontsize or select(2, TimeManagerClockTicker:GetFont()) end,
			set = function(info, v)
				mod.db.profile.fontsize = v
				updateLayout()
			end
		},
		font = {
			type = "select",
			name = L["Font"],
			order = 5,
			dialogControl = "LSM30_Font",
			values = AceGUIWidgetLSMlists.font,
			get = function()
				local font = nil
				local curFont = TimeManagerClockTicker:GetFont()
				for k,v in pairs(AceGUIWidgetLSMlists.font) do
					if v == curFont then
						font = k
						break
					end
				end
				return mod.db.profile.font or font
			end,
			set = function(info, v)
				mod.db.profile.font = v
				updateLayout()
			end
		},
		spacer2 = {
			order = 6,
			type = "description",
			width = "normal",
			name = "",
		},
		fontColor = {
			type = "color",
			name = L["Font Color"],
			order = 7,
			hasAlpha = true,
			get = function()
				if mod.db.profile.fontColor.r then
					return mod.db.profile.fontColor.r, mod.db.profile.fontColor.g, mod.db.profile.fontColor.b, mod.db.profile.fontColor.a
				else
					return TimeManagerClockTicker:GetTextColor()
				end
			end,
			set = function(info, r, g, b, a)
				mod.db.profile.fontColor.r, mod.db.profile.fontColor.g, mod.db.profile.fontColor.b, mod.db.profile.fontColor.a = r, g, b, a
				updateLayout()
			end
		},
		bgColor = {
			type = "color",
			name = L["Background Color"],
			order = 8,
			hasAlpha = true,
			get = function()
				return mod.db.profile.bgColor.r, mod.db.profile.bgColor.g, mod.db.profile.bgColor.b, mod.db.profile.bgColor.a
			end,
			set = function(info, r, g, b, a)
				mod.db.profile.bgColor.r, mod.db.profile.bgColor.g, mod.db.profile.bgColor.b, mod.db.profile.bgColor.a = r, g, b, a
				updateLayout()
			end
		},
		borderColor = {
			type = "color",
			name = L["Border Color"],
			order = 9,
			hasAlpha = true,
			get = function()
				return mod.db.profile.borderColor.r, mod.db.profile.borderColor.g, mod.db.profile.borderColor.b, mod.db.profile.borderColor.a
			end,
			set = function(info, r, g, b, a)
				mod.db.profile.borderColor.r, mod.db.profile.borderColor.g, mod.db.profile.borderColor.b, mod.db.profile.borderColor.a = r, g, b, a
				updateLayout()
			end
		},
		fade = {
			type = "multiselect",
			name = function()
				local btn = parent:GetModule("Buttons")
				if btn.db.profile.controlVisibility then
					return L["Show %s:"]:format(L["Clock"])
				else
					return L["Show %s:"]:format(L["Clock"]) .. " |cFF0276FD" .. L["(Requires button visibility control in the Buttons menu)"] .. "|r"
				end
			end,
			order = 10,
			values = {
				["always"] = L["Always"],
				["never"] = L["Never"],
				["hover"] = L["On Hover"],
			},
			get = function(info, v)
				local btn = parent:GetModule("Buttons")
				return (btn.db.profile.visibilitySettings.TimeManagerClockButton or "hover") == v
			end,
			set = function(info, v)
				local btn = parent:GetModule("Buttons")
				btn.db.profile.visibilitySettings.TimeManagerClockButton = v
				btn:ChangeFrameVisibility(TimeManagerClockButton, v)
			end,
			disabled = function()
				local btn = parent:GetModule("Buttons")
				return not btn.db.profile.controlVisibility
			end,
		}
	}
}

function mod:OnInitialize()
	local defaults = {
		profile = {
			xOffset = 0,
			yOffset = 0,
			bgColor = {r = 0, g = 0, b = 0, a = 1},
			borderColor = {r = 0, g = 0, b = 0, a = 1},
			fontColor = {},
		}
	}

	self.db = parent.db:RegisterNamespace(modName, defaults)
	parent:RegisterModuleOptions(modName, options, L["Clock"])
end

function mod:OnEnable()
	TimeManagerClockTicker:ClearAllPoints()
	TimeManagerClockTicker:SetAllPoints()
	TimeManagerClockButton:GetRegions():Hide() -- Hide the border
	TimeManagerClockButton:SetBackdrop(addon.backdrop)

	updateLayout()
end

