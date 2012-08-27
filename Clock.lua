
local _, sm = ...
sm.clock = {}

local parent = sm.core
local mod = sm.clock
local L = sm.L

local media = LibStub("LibSharedMedia-3.0")
local db

local options = {
	type = "group",
	name = L["Clock"],
	args = {
		xOffset = {
			type = "range",
			name = L["Horizontal Position"],
			order = 1,
			min = -250,
			max = 250,
			step = 1,
			bigStep = 5,
			get = function() return db.xOffset end,
			set = function(info, v) db.xOffset = v mod:UpdateLayout() end
		},
		yOffset = {
			type = "range",
			name = L["Vertical Position"],
			order = 2,
			min = -250,
			max = 250,
			step = 1,
			bigStep = 5,
			get = function() return db.yOffset end,
			set = function(info, v) db.yOffset = v mod:UpdateLayout() end
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
			get = function() return db.fontsize or select(2, TimeManagerClockTicker:GetFont()) end,
			set = function(info, v)
				db.fontsize = v
				mod:UpdateLayout()
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
				return db.font or font
			end,
			set = function(info, v)
				db.font = v
				mod:UpdateLayout()
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
				if db.fontColor.r then
					return db.fontColor.r, db.fontColor.g, db.fontColor.b, db.fontColor.a
				else
					return TimeManagerClockTicker:GetTextColor()
				end
			end,
			set = function(info, r, g, b, a)
				db.fontColor.r, db.fontColor.g, db.fontColor.b, db.fontColor.a = r, g, b, a
				mod:UpdateLayout()
			end
		},
		bgColor = {
			type = "color",
			name = L["Background Color"],
			order = 8,
			hasAlpha = true,
			get = function()
				return db.bgColor.r, db.bgColor.g, db.bgColor.b, db.bgColor.a
			end,
			set = function(info, r, g, b, a)
				db.bgColor.r, db.bgColor.g, db.bgColor.b, db.bgColor.a = r, g, b, a
				mod:UpdateLayout()
			end
		},
		borderColor = {
			type = "color",
			name = L["Border Color"],
			order = 9,
			hasAlpha = true,
			get = function()
				return db.borderColor.r, db.borderColor.g, db.borderColor.b, db.borderColor.a
			end,
			set = function(info, r, g, b, a)
				db.borderColor.r, db.borderColor.g, db.borderColor.b, db.borderColor.a = r, g, b, a
				mod:UpdateLayout()
			end
		},
		fade = {
			type = "multiselect",
			name = function()
				if sm.buttons.db.profile.controlVisibility then
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
				return (sm.buttons.db.profile.visibilitySettings.TimeManagerClockButton or "hover") == v
			end,
			set = function(info, v)
				sm.buttons.db.profile.visibilitySettings.TimeManagerClockButton = v
				sm.buttons:ChangeFrameVisibility(TimeManagerClockButton, v)
			end,
			disabled = function()
				return not sm.buttons.db.profile.controlVisibility
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
	self.db = parent.db:RegisterNamespace("Clock", defaults)
	db = self.db.profile
end

function mod:OnEnable()
	parent:RegisterModuleOptions("Clock", options, L["Clock"])

	TimeManagerClockTicker:ClearAllPoints()
	TimeManagerClockTicker:SetAllPoints()
	TimeManagerClockButton:GetRegions():Hide() -- Hide the border
	TimeManagerClockButton:SetBackdrop(sm.backdrop)

	self:UpdateLayout()
end

function mod:UpdateLayout()
	TimeManagerClockButton:ClearAllPoints()
	TimeManagerClockButton:SetPoint("TOP", Minimap, "BOTTOM", db.xOffset, db.yOffset)
	TimeManagerClockButton:SetBackdropColor(db.bgColor.r, db.bgColor.g, db.bgColor.b, db.bgColor.a)
	TimeManagerClockButton:SetBackdropBorderColor(db.borderColor.r, db.borderColor.g, db.borderColor.b, db.borderColor.a)
	local a, b, c = TimeManagerClockTicker:GetFont()
	TimeManagerClockTicker:SetFont(db.font and media:Fetch("font", db.font) or a, db.fontsize or b, c)
	if db.fontColor.r then
		TimeManagerClockTicker:SetTextColor(db.fontColor.r, db.fontColor.g, db.fontColor.b, db.fontColor.a)
	end
	local width = max(TimeManagerClockTicker:GetStringWidth() * 1.3, 0)
	TimeManagerClockButton:SetHeight(TimeManagerClockTicker:GetStringHeight() + 10)
	TimeManagerClockButton:SetWidth(width)
end

