
if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
	return
end

local _, sm = ...
sm.clock = {}

local mod = sm.clock
local L = sm.L

local media = LibStub("LibSharedMedia-3.0")

local options = {
	type = "group",
	name = L["Clock"],
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
			name = " ",
			width = "full",
		},
		fontSize = {
			type = "range",
			name = L["Font Size"],
			order = 4,
			min = 4,
			max = 30,
			step = 1,
			bigStep = 1,
			get = function() return mod.db.fontsize or select(2, TimeManagerClockTicker:GetFont()) end,
			set = function(info, v)
				mod.db.fontsize = v
				mod:UpdateLayout()
			end
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
		spacer2 = {
			order = 6,
			type = "description",
			name = " ",
			width = "full",
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
					return TimeManagerClockTicker:GetTextColor()
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
				return (sm.buttons.db.visibilitySettings.TimeManagerClockButton or "hover") == v
			end,
			set = function(info, v)
				sm.buttons.db.visibilitySettings.TimeManagerClockButton = v
				TimeManagerClockButton:SetParent(Minimap) -- Activate the hooksecurefunc we defined in Buttons.lua -- sm.buttons:ChangeFrameVisibility(TimeManagerClockButton, v)
			end,
			disabled = function()
				return not sm.buttons.db.controlVisibility
			end,
		}
	}
}

function mod:OnInitialize(profile)
	if type(profile.clock) ~= "table" then
		profile.clock = {
			xOffset = 0,
			yOffset = 0,
			bgColor = {r = 0, g = 0, b = 0, a = 1},
			borderColor = {r = 0, g = 0, b = 0, a = 1},
			fontColor = {},
			font = media:GetDefault("font"),
		}
	end
	self.db = profile.clock
	-- XXX temp 8.0.1
	if not profile.clock.font then
		profile.clock.font = media:GetDefault("font")
	end
end

-- Some objects are no longer being called directly using ":" to work around issues with other addons
-- messing with these Blizzard-created widgets (addon conflicts)
function mod:OnEnable()
	sm.core:RegisterModuleOptions("Clock", options, L["Clock"])

	sm.core.font.ClearAllPoints(TimeManagerClockTicker)
	sm.core.font.SetAllPoints(TimeManagerClockTicker)
	local border = sm.core.button.GetRegions(TimeManagerClockButton)
	border:Hide() -- Hide the clock border
	Mixin(TimeManagerClockButton, BackdropTemplateMixin)
	TimeManagerClockButton:SetBackdrop(sm.backdrop)
	sm.core.button.SetClampedToScreen(TimeManagerClockButton, true)
	sm.core.button.SetClampRectInsets(TimeManagerClockButton, 4,-4,-4,4) -- Allow kissing the edge of the screen when hiding the backdrop border (size 4)
	sm.core.button.Show(TimeManagerClockButton)
	do
		local TimeManagerClockButton = TimeManagerClockButton -- Safety
		hooksecurefunc(TimeManagerClockButton, "Hide", function()
			sm.core.button.Show(TimeManagerClockButton)
		end)
		hooksecurefunc(TimeManagerClockButton, "SetPoint", function()
			sm.core.button.ClearAllPoints(TimeManagerClockButton)
			sm.core.button.SetPoint(TimeManagerClockButton, "TOP", Minimap, "BOTTOM", mod.db.xOffset, mod.db.yOffset)
		end)
	end

	-- For some reason PLAYER_LOGIN is too early for a rare subset of users (even when only using SexyMap)
	-- which results in a clock width too small. Use this delayed repeater to try and fix the clock width for them.
	local CTimerAfter = C_Timer.After
	for i = 1, 5 do
		CTimerAfter(i, mod.UpdateLayout)
	end
end

function mod:UpdateLayout()
	sm.core.button.ClearAllPoints(TimeManagerClockButton)
	sm.core.button.SetPoint(TimeManagerClockButton, "TOP", Minimap, "BOTTOM", mod.db.xOffset, mod.db.yOffset)
	TimeManagerClockButton:SetBackdropColor(mod.db.bgColor.r, mod.db.bgColor.g, mod.db.bgColor.b, mod.db.bgColor.a)
	TimeManagerClockButton:SetBackdropBorderColor(mod.db.borderColor.r, mod.db.borderColor.g, mod.db.borderColor.b, mod.db.borderColor.a)
	local a, b, c = GameFontHighlightSmall:GetFont()
	sm.core.font.SetFont(TimeManagerClockTicker, mod.db.font and media:Fetch("font", mod.db.font) or a, mod.db.fontsize or b, c)
	if mod.db.fontColor.r then
		sm.core.font.SetTextColor(TimeManagerClockTicker, mod.db.fontColor.r, mod.db.fontColor.g, mod.db.fontColor.b, mod.db.fontColor.a)
	end
	sm.core.font.SetText(TimeManagerClockTicker, "44:44")
	sm.core.button.SetWidth(TimeManagerClockButton, sm.core.font.GetStringWidth(TimeManagerClockTicker) + 16)
	sm.core.button.SetHeight(TimeManagerClockButton, sm.core.font.GetStringHeight(TimeManagerClockTicker) + 10)
end

