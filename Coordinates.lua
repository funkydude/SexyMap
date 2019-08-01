
local _, sm = ...
sm.coordinates = {}

local mod = sm.coordinates
local L = sm.L

local media = LibStub("LibSharedMedia-3.0")
local coordFrame, coordsText

local options = {
	type = "group",
	name = L["Coordinates"],
	childGroups = "tab",
	disabled = function() return not mod.db.enabled end,
	args = {
		enable = {
			type = "toggle",
			name = L["Enable Coordinates"],
			order = 1,
			width = "full",
			get = function()
				return mod.db.enabled
			end,
			set = function(info, v)
				mod.db.enabled = v
				if v then
					mod:CreateFrame()
				else
					if coordFrame then
						coordFrame:Hide()
					end
				end
			end,
			disabled = false,
		},
		xOffset = {
			type = "range",
			name = L["Horizontal Position"],
			order = 2,
			min = -250,
			max = 250,
			step = 1,
			bigStep = 5,
			get = function() return mod.db.xOffset end,
			set = function(info, v) mod.db.xOffset = v mod:Update() end
		},
		yOffset = {
			type = "range",
			name = L["Vertical Position"],
			order = 3,
			min = -250,
			max = 250,
			step = 1,
			bigStep = 5,
			get = function() return mod.db.yOffset end,
			set = function(info, v) mod.db.yOffset = v mod:Update() end
		},
		spacer1 = {
			order = 4,
			type = "description",
			name = " ",
		},
		fontSize = {
			type = "range",
			name = L["Font Size"],
			order = 5,
			min = 8,
			max = 30,
			step = 1,
			bigStep = 1,
			get = function()
				return mod.db.fontSize or 12
			end,
			set = function(info, v)
				mod.db.fontSize = v
				mod:Update()
			end
		},
		font = {
			type = "select",
			name = L["Font"],
			order = 6,
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
				mod:Update()
			end,
		},
		spacer2 = {
			order = 7,
			type = "description",
			name = " ",
		},
		fontColor = {
			type = "color",
			name = L["Font Color"],
			order = 8,
			hasAlpha = true,
			get = function()
				local c = mod.db.fontColor
				local r, g, b, a = c.r or 1, c.g or 1, c.b or 1, c.a or 1
				return r, g, b, a
			end,
			set = function(info, r, g, b, a)
				local c = mod.db.fontColor
				c.r, c.g, c.b, c.a = r, g, b, a
				mod:Update()
			end
		},
		backgroundColor = {
			type = "color",
			name = L["Backdrop Color"],
			order = 9,
			hasAlpha = true,
			get = function()
				local c = mod.db.backgroundColor
				local r, g, b, a = c.r or 0, c.g or 0, c.b or 0, c.a or 1
				return r, g, b, a
			end,
			set = function(info, r, g, b, a)
				local c = mod.db.backgroundColor
				c.r, c.g, c.b, c.a = r, g, b, a
				mod:Update()
			end
		},
		borderColor = {
			type = "color",
			name = L["Border Color"],
			order = 10,
			hasAlpha = true,
			get = function()
				local c = mod.db.borderColor
				local r, g, b, a = c.r or 0, c.g or 0, c.b or 0, c.a or 1
				return r, g, b, a
			end,
			set = function(info, r, g, b, a)
				local c = mod.db.borderColor
				c.r, c.g, c.b, c.a = r, g, b, a
				mod:Update()
			end
		},
		updateRate = {
			type = "range",
			name = L.updateRate,
			desc = L.updateRateDesc,
			order = 11,
			width = "full",
			min = 0.1,
			max = 1,
			step = 0.1,
			get = function()
				return mod.db.updateRate
			end,
			set = function(info, v)
				mod.db.updateRate = v
			end
		},
	}
}

function mod:OnInitialize(profile)
	if type(profile.coordinates) ~= "table" then
		profile.coordinates = {
			borderColor = {},
			backgroundColor = {},
			fontColor = {},
			enabled = false,
			updateRate = 1,
			xOffset = 0,
			yOffset = 10,
			font = media:GetDefault("font"),
		}
	end
	self.db = profile.coordinates
	-- XXX temp 7.3.5
	if not profile.coordinates.updateRate then
		profile.coordinates.updateRate = 1
	end
	-- XXX temp 8.0.1
	if not profile.coordinates.xOffset then
		profile.coordinates.xOffset = 0
		profile.coordinates.yOffset = 10
		profile.coordinates.x = nil
		profile.coordinates.y = nil
		profile.coordinates.locked = nil
	end
	if not profile.coordinates.font then
		profile.coordinates.font = media:GetDefault("font")
	end
end

function mod:OnEnable()
	sm.core:RegisterModuleOptions("Coordinates", options, L["Coordinates"])

	if mod.db.enabled then
		self:CreateFrame()
	end
end

function mod:CreateFrame()
	if not coordFrame then
		coordFrame = CreateFrame("Frame", "SexyMapCoordFrame", Minimap)
		coordFrame:SetBackdrop(sm.backdrop)
		coordsText = coordFrame:CreateFontString(nil, nil, "GameFontNormalSmall")
		coordsText:SetPoint("CENTER", coordFrame, "CENTER")
		coordsText:SetJustifyH("CENTER")
		coordsText:SetText("0.0, 0.0")
		coordFrame:SetClampedToScreen(true)

		local GetPlayerMapPosition = C_Map.GetPlayerMapPosition
		local GetBestMapForUnit = C_Map.GetBestMapForUnit
		local CTimerAfter = C_Timer.After
		local function updateCoords()
			CTimerAfter(mod.db.updateRate, updateCoords)
			local uiMapID = GetBestMapForUnit"player"
			if uiMapID then
				local tbl = GetPlayerMapPosition(uiMapID, "player")
				if tbl then
					coordsText:SetFormattedText("%.1f, %.1f", tbl.x*100, tbl.y*100)
				else
					coordsText:SetText("0.0, 0.0")
				end
			end
		end
		updateCoords()
	end

	coordFrame:Show()
	self:Update()
end

function mod:Update()
	coordFrame:SetPoint("CENTER", Minimap, "BOTTOM", mod.db.xOffset, mod.db.yOffset)

	if mod.db.borderColor then
		local c = mod.db.borderColor
		coordFrame:SetBackdropBorderColor(c.r or 0, c.g or 0, c.b or 0, c.a or 1)
	end

	if mod.db.backgroundColor then
		local c = mod.db.backgroundColor
		coordFrame:SetBackdropColor(c.r or 0, c.g or 0, c.b or 0, c.a or 1)
	end

	if mod.db.fontColor then
		local c = mod.db.fontColor
		coordsText:SetTextColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
	end

	local _, b, c = coordsText:GetFont()
	coordsText:SetFont(media:Fetch("font", mod.db.font), mod.db.fontSize or b, c)

	coordsText:SetText("99.9, 99.9")
	coordFrame:SetWidth(coordsText:GetStringWidth() * 1.2)
	coordFrame:SetHeight(coordsText:GetStringHeight() + 10)
end

