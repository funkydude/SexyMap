
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
			monochrome = false,
			outline = "NONE",
		}
	end

	-- XXX temp 10.1.0
	if not profile.clock.monochrome then
		profile.clock.monochrome = false
	end
	if not profile.clock.outline then
		profile.clock.outline = "NONE"
	end

	self.db = profile.clock
end

-- Some objects are no longer being called directly using ":" to work around issues with other addons
-- messing with these Blizzard-created widgets (addon conflicts)
function mod:OnEnable()
	sm.core:RegisterModuleOptions("Clock", options, L["Clock"])

	sm.core.font.ClearAllPoints(TimeManagerClockTicker)
	sm.core.font.SetAllPoints(TimeManagerClockTicker)
	if MiniMapMailFrame then
		local border = sm.core.button.GetRegions(TimeManagerClockButton)
		border:Hide() -- Hide the clock border
	end
	Mixin(TimeManagerClockButton, BackdropTemplateMixin)
	TimeManagerClockButton:SetBackdrop(sm.backdrop)
	sm.core.button.SetFrameStrata(TimeManagerClockButton, "LOW")
	sm.core.button.SetFixedFrameStrata(TimeManagerClockButton, true)
	sm.core.button.SetFrameLevel(TimeManagerClockButton, 20) -- Above Questie minimap blips
	sm.core.button.SetFixedFrameLevel(TimeManagerClockButton, true)
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

	self:UpdateLayout()
end

function mod:OnLoadingScreenOver()
	self:UpdateLayout()
end

function mod:UpdateLayout()
	sm.core.button.ClearAllPoints(TimeManagerClockButton)
	sm.core.button.SetPoint(TimeManagerClockButton, "TOP", Minimap, "BOTTOM", mod.db.xOffset, mod.db.yOffset)
	TimeManagerClockButton:SetBackdropColor(mod.db.bgColor.r, mod.db.bgColor.g, mod.db.bgColor.b, mod.db.bgColor.a)
	TimeManagerClockButton:SetBackdropBorderColor(mod.db.borderColor.r, mod.db.borderColor.g, mod.db.borderColor.b, mod.db.borderColor.a)
	local a, b = GameFontHighlightSmall:GetFont()
	local flags = nil
	if mod.db.monochrome and mod.db.outline ~= "NONE" then
		flags = "MONOCHROME," .. mod.db.outline
	elseif mod.db.monochrome then
		flags = "MONOCHROME"
	elseif mod.db.outline ~= "NONE" then
		flags = mod.db.outline
	end
	sm.core.font.SetFont(TimeManagerClockTicker, mod.db.font and media:Fetch("font", mod.db.font) or a, mod.db.fontsize or b, flags)
	if mod.db.fontColor.r then
		sm.core.font.SetTextColor(TimeManagerClockTicker, mod.db.fontColor.r, mod.db.fontColor.g, mod.db.fontColor.b, mod.db.fontColor.a)
	end
	sm.core.font.SetText(TimeManagerClockTicker, "44:44")
	sm.core.button.SetWidth(TimeManagerClockButton, sm.core.font.GetUnboundedStringWidth(TimeManagerClockTicker) + 12)
	sm.core.button.SetHeight(TimeManagerClockButton, sm.core.font.GetStringHeight(TimeManagerClockTicker) + 10)
end

