
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
		enabled = {
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
			max = 2000,
			softMax = 250,
			min = -2000,
			softMin = -250,
			step = 1,
			bigStep = 5,
			get = function() return mod.db.xOffset end,
			set = function(info, v) mod.db.xOffset = v mod:Update() end
		},
		yOffset = {
			type = "range",
			name = L["Vertical Position"],
			order = 3,
			max = 2000,
			softMax = 250,
			min = -2000,
			softMin = -250,
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
		monochrome = {
			type = "toggle",
			name = L.monochrome,
			desc = L.monochromeDesc,
			order = 10.1,
			get = function() return mod.db.monochrome end,
			set = function(_, v)
				mod.db.monochrome = v
				mod:Update()
			end
		},
		outline = {
			type = "select",
			name = L.outline,
			order = 10.2,
			values = {
				NONE = L.none,
				OUTLINE = L.thin,
				THICKOUTLINE = L.thick,
			},
			get = function() return mod.db.outline end,
			set = function(_, v)
				mod.db.outline = v
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
		coordPrecision = {
			type = "multiselect",
			name = L.Precision,
			order = 12,
			values = {"70,70", "70.1, 70.1", "70.11, 70.11"},
			get = function(info, v)
				if v == 1 and mod.db.coordPrecision == "%d,%d" then
					return true
				elseif v == 2 and mod.db.coordPrecision == "%.1f, %.1f" then
					return true
				elseif v == 3 and mod.db.coordPrecision == "%.2f, %.2f" then
					return true
				end
			end,
			set = function(info, v)
				if v == 1 then
					mod.db.coordPrecision = "%d,%d"
				elseif v == 2 then
					mod.db.coordPrecision = "%.1f, %.1f"
				elseif v == 3 then
					mod.db.coordPrecision = "%.2f, %.2f"
				end
				mod:Update()
			end,
		}
	}
}

function mod:OnInitialize(profile)
	if type(profile.coordinates) ~= "table" then
		profile.coordinates = {
			borderColor = {},
			backgroundColor = {},
			fontColor = {},
			enabled = true,
			coordPrecision = "%d,%d",
			updateRate = 1,
			xOffset = 0,
			yOffset = 10,
			font = media:GetDefault("font"),
			monochrome = false,
			outline = "NONE",
		}
	end

	-- XXX temp 9.0.1
	if not profile.coordinates.coordPrecision then
		profile.coordinates.enabled = true
		profile.coordinates.coordPrecision = "%d,%d"
	end
	-- XXX temp 10.1.0
	if not profile.coordinates.monochrome then
		profile.coordinates.monochrome = false
	end
	if not profile.coordinates.outline then
		profile.coordinates.outline = "NONE"
	end

	self.db = profile.coordinates
end

function mod:OnEnable()
	sm.core:RegisterModuleOptions("Coordinates", options, L["Coordinates"])

	if mod.db.enabled then
		self:CreateFrame()
	end
end

function mod:OnLoadingScreenOver()
	if mod.db.enabled then
		self:Update()
	end
end

function mod:CreateFrame()
	if not coordFrame then
		coordFrame = CreateFrame("Frame", "SexyMapCoordFrame", Minimap, "BackdropTemplate")
		coordFrame:SetBackdrop(sm.backdrop)
		coordFrame:SetFrameStrata("LOW")
		coordFrame:SetFixedFrameStrata(true)
		coordFrame:SetFrameLevel(20) -- Above Questie minimap blips
		coordFrame:SetFixedFrameLevel(true)
		coordsText = coordFrame:CreateFontString(nil, nil, "GameFontNormalSmall")
		coordsText:SetPoint("CENTER", coordFrame, "CENTER")
		coordsText:SetJustifyH("CENTER")
		coordsText:SetText("0,0")
		coordFrame:SetClampedToScreen(true)
		coordFrame:SetClampRectInsets(4,-4,-4,4) -- Allow kissing the edge of the screen when hiding the backdrop border (size 4)

		local GetPlayerMapPosition = C_Map.GetPlayerMapPosition
		local GetBestMapForUnit = C_Map.GetBestMapForUnit
		local CTimerAfter = C_Timer.After
		local function updateCoords()
			local uiMapID = GetBestMapForUnit"player"
			if uiMapID then
				local tbl = GetPlayerMapPosition(uiMapID, "player")
				if tbl then
					CTimerAfter(mod.db.updateRate, updateCoords)
					coordsText:SetFormattedText(mod.db.coordPrecision, tbl.x*100, tbl.y*100)
				else
					CTimerAfter(5, updateCoords)
					coordsText:SetText("0,0")
				end
			else
				CTimerAfter(5, updateCoords)
				coordsText:SetText("0,0")
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

	local _, b = coordsText:GetFont()
	local flags = nil
	if mod.db.monochrome and mod.db.outline ~= "NONE" then
		flags = "MONOCHROME," .. mod.db.outline
	elseif mod.db.monochrome then
		flags = "MONOCHROME"
	elseif mod.db.outline ~= "NONE" then
		flags = mod.db.outline
	end
	coordsText:SetFont(media:Fetch("font", mod.db.font), mod.db.fontSize or b, flags)

	if mod.db.coordPrecision == "%.2f, %.2f" then
		coordsText:SetText("99.99, 99.99")
	elseif mod.db.coordPrecision == "%.1f, %.1f" then
		coordsText:SetText("99.9, 99.9")
	else
		coordsText:SetText("99, 99")
	end
	coordFrame:SetWidth(coordsText:GetUnboundedStringWidth() + 12)
	coordFrame:SetHeight(coordsText:GetStringHeight() + 10)
end

