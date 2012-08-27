
local _, sm = ...
sm.coordinates = {}

local mod = sm.coordinates
local L = sm.L

local coordFrame, coordsText, db

local options = {
	type = "group",
	name = L["Coordinates"],
	childGroups = "tab",
	disabled = function() return not db.enabled end,
	args = {
		enable = {
			type = "toggle",
			name = L["Enable Coordinates"],
			order = 1,
			get = function()
				return db.enabled
			end,
			set = function(info, v)
				db.enabled = v
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
				return db.locked
			end,
			set = function(info, v)
				db.locked = v
			end,
		},
		fontColor = {
			type = "color",
			name = L["Font Color"],
			order = 3,
			hasAlpha = true,
			get = function()
				local c = db.fontColor
				local r, g, b, a = c.r or 0, c.g or 0, c.b or 0, c.a or 1
				return r, g, b, a
			end,
			set = function(info, r, g, b, a)
				local c = db.fontColor
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
				local c = db.backgroundColor
				local r, g, b, a = c.r or 0, c.g or 0, c.b or 0, c.a or 1
				return r, g, b, a
			end,
			set = function(info, r, g, b, a)
				local c = db.backgroundColor
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
				local c = db.borderColor
				local r, g, b, a = c.r or 0, c.g or 0, c.b or 0, c.a or 1
				return r, g, b, a
			end,
			set = function(info, r, g, b, a)
				local c = db.borderColor
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
				return db.fontSize or 12
			end,
			set = function(info, v)
				db.fontSize = v
				mod:Update()
			end
		},
		spacer = {
			order = 7,
			type = "description",
			width = "normal",
			name = "",
			width = "double",
		},
		reset = {
			type = "execute",
			name = L["Reset Position"],
			order = 8,
			func = function()
				mod:ResetPosition()
			end,
		},
	}
}

function mod:OnInitialize()
	local defaults = {
		profile = {
			borderColor = {},
			backgroundColor = {},
			locked = false,
			fontColor = {},
			enabled = false
		}
	}
	self.db = sm.core.db:RegisterNamespace("Coordinates", defaults)
	db = self.db.profile
end

function mod:OnEnable()
	sm.core:RegisterModuleOptions("Coordinates", options, L["Coordinates"])

	if db.enabled then
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
		coordFrame.sexyMapIgnore = true

		coordFrame:SetScript("OnMouseDown", function(self)
			if not db.locked then
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
				db.x = dx
				db.y = dy
			end
		end)

		local animgroup = coordFrame:CreateAnimationGroup()
		local anim = animgroup:CreateAnimation()
		local GetPlayerMapPosition = GetPlayerMapPosition
		animgroup:SetScript("OnLoop", function(self)
			local x, y = GetPlayerMapPosition"player"
			coordsText:SetFormattedText("%.1f, %.1f", x*100, y*100)
		end)
		anim:SetOrder(1)
		anim:SetDuration(0.1)
		animgroup:SetLooping("REPEAT")
		animgroup:Play()
	end
	if db.x then
		coordFrame:ClearAllPoints()
		coordFrame:SetPoint("CENTER", Minimap, "CENTER", -db.x, -db.y)
	else
		coordFrame:SetPoint("CENTER", Minimap, "BOTTOM", 0, 10)
	end

	coordFrame:Show()
	self:Update()
end

function mod:Update()
	if db.borderColor then
		local c = db.borderColor
		coordFrame:SetBackdropBorderColor(c.r or 0, c.g or 0, c.b or 0, c.a or 1)
	end

	if db.backgroundColor then
		local c = db.backgroundColor
		coordFrame:SetBackdropColor(c.r or 0, c.g or 0, c.b or 0, c.a or 1)
	end

	if db.fontColor then
		local c = db.fontColor
		coordsText:SetTextColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
	end

	if db.fontSize then
		local f, s, flags = coordsText:GetFont()
		coordsText:SetFont(f, db.fontSize, flags)
	end

	coordFrame:SetWidth(coordsText:GetStringWidth() * 1.2)
	coordFrame:SetHeight(coordsText:GetStringHeight() + 10)
end

function mod:ResetPosition()
	coordFrame:ClearAllPoints()
	coordFrame:SetPoint("CENTER", Minimap, "BOTTOM")
	db.x, db.y = nil, nil
end

