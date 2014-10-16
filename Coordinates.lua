
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
		lock = {
			type = "toggle",
			name = L["Lock Coordinates"],
			order = 2,
			width = "double",
			get = function()
				return mod.db.locked
			end,
			set = function(info, v)
				mod.db.locked = v
			end,
		},
		fontColor = {
			type = "color",
			name = L["Font Color"],
			order = 3,
			hasAlpha = true,
			get = function()
				local c = mod.db.fontColor
				local r, g, b, a = c.r or 0, c.g or 0, c.b or 0, c.a or 1
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
			order = 4,
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
			order = 5,
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
		fontSize = {
			type = "range",
			name = L["Font Size"],
			order = 6,
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
			order = 7,
			dialogControl = "LSM30_Font",
			values = AceGUIWidgetLSMlists.font,
			get = function()
				if not coordsText then return end
				local font = nil
				local curFont = coordsText:GetFont()
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
				mod:Update()
			end
		},
		spacer = {
			order = 8,
			type = "description",
			width = "normal",
			name = "",
		},
		reset = {
			type = "execute",
			name = L["Reset Position"],
			order = 9,
			func = function()
				mod:ResetPosition()
			end,
		},
	}
}

function mod:OnInitialize(profile)
	if type(profile.coordinates) ~= "table" then
		profile.coordinates = {
			borderColor = {},
			backgroundColor = {},
			locked = false,
			fontColor = {},
			enabled = false,
		}
	end
	self.db = profile.coordinates
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
		coordsText:SetText("00.0, 00.0")

		coordFrame:SetMovable(true)
		coordFrame:EnableMouse()

		coordFrame:SetScript("OnMouseDown", function(self)
			if not mod.db.locked then
				self:StartMoving()
				self.moving = true
			end
		end)
		coordFrame:SetScript("OnMouseUp", function(self)
			if self.moving then
				self.moving = nil
				self:StopMovingOrSizing()
				local x, y = self:GetCenter()
				local mx, my = Minimap:GetCenter()
				local dx, dy = mx - x, my - y
				self:ClearAllPoints()
				self:SetPoint("CENTER", Minimap, "CENTER", -dx, -dy)
				mod.db.x = dx
				mod.db.y = dy
			end
		end)

		local GetPlayerMapPosition = GetPlayerMapPosition
		local CTimerAfter = C_Timer.After
		local function updateCoords()
			CTimerAfter(0.1, updateCoords)
			local x, y = GetPlayerMapPosition"player"
			coordsText:SetFormattedText("%.1f, %.1f", x*100, y*100)
		end
		updateCoords()
	end
	if mod.db.x then
		coordFrame:ClearAllPoints()
		coordFrame:SetPoint("CENTER", Minimap, "CENTER", -mod.db.x, -mod.db.y)
	else
		coordFrame:SetPoint("CENTER", Minimap, "BOTTOM", 0, 10)
	end

	coordFrame:Show()
	self:Update()
end

function mod:Update()
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

	local a, b, c = coordsText:GetFont()
	coordsText:SetFont(mod.db.font and media:Fetch("font", mod.db.font) or a, mod.db.fontSize or b, c)

	coordFrame:SetWidth(coordsText:GetStringWidth() * 1.2)
	coordFrame:SetHeight(coordsText:GetStringHeight() + 10)
end

function mod:ResetPosition()
	coordFrame:ClearAllPoints()
	coordFrame:SetPoint("CENTER", Minimap, "BOTTOM")
	mod.db.x, mod.db.y = nil, nil
end

