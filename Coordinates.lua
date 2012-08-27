
local _, sm = ...
sm.Coordinates = {}

local parent = sm.Core
local mod = sm.Coordinates
local L = sm.L

local coordFrame, coordsText

local options = {
	type = "group",
	name = L["Coordinates"],
	childGroups = "tab",
	disabled = function() return not mod.db.profile.enabled end,
	args = {
		enable = {
			type = "toggle",
			name = L["Enable Coordinates"],
			order = 1,
			get = function()
				return mod.db.profile.enabled
			end,
			set = function(info, v)
				mod.db.profile.enabled = v
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
				return mod.db.profile.locked
			end,
			set = function(info, v)
				mod.db.profile.locked = v
			end,
		},
		fontColor = {
			type = "color",
			name = L["Font Color"],
			order = 3,
			hasAlpha = true,
			get = function()
				local c = mod.db.profile.fontColor
				local r, g, b, a = c.r or 0, c.g or 0, c.b or 0, c.a or 1
				return r, g, b, a
			end,
			set = function(info, r, g, b, a)
				local c = mod.db.profile.fontColor
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
				local c = mod.db.profile.backgroundColor
				local r, g, b, a = c.r or 0, c.g or 0, c.b or 0, c.a or 1
				return r, g, b, a
			end,
			set = function(info, r, g, b, a)
				local c = mod.db.profile.backgroundColor
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
				local c = mod.db.profile.borderColor
				local r, g, b, a = c.r or 0, c.g or 0, c.b or 0, c.a or 1
				return r, g, b, a
			end,
			set = function(info, r, g, b, a)
				local c = mod.db.profile.borderColor
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
				return mod.db.profile.fontSize or 12
			end,
			set = function(info, v)
				mod.db.profile.fontSize = v
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

function mod:OnEnable()
	local defaults = {
		profile = {
			borderColor = {},
			backgroundColor = {},
			locked = false,
			fontColor = {},
			enabled = false
		}
	}
	self.db = parent.db:RegisterNamespace("Coordinates", defaults)
	parent:RegisterModuleOptions("Coordinates", options, L["Coordinates"])

	if self.db.profile.enabled then
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
			if not mod.db.profile.locked then
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
				mod.db.profile.x = dx
				mod.db.profile.y = dy
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
	if self.db.profile.x then
		coordFrame:ClearAllPoints()
		coordFrame:SetPoint("CENTER", Minimap, "CENTER", -self.db.profile.x, -self.db.profile.y)
	else
		coordFrame:SetPoint("CENTER", Minimap, "BOTTOM", 0, 10)
	end

	coordFrame:Show()
	self:Update()
end

function mod:Update()
	if self.db.profile.borderColor then
		local c = self.db.profile.borderColor
		coordFrame:SetBackdropBorderColor(c.r or 0, c.g or 0, c.b or 0, c.a or 1)
	end

	if self.db.profile.backgroundColor then
		local c = self.db.profile.backgroundColor
		coordFrame:SetBackdropColor(c.r or 0, c.g or 0, c.b or 0, c.a or 1)
	end

	if self.db.profile.fontColor then
		local c = self.db.profile.fontColor
		coordsText:SetTextColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
	end

	if self.db.profile.fontSize then
		local f, s, flags = coordsText:GetFont()
		coordsText:SetFont(f, self.db.profile.fontSize, flags)
	end

	coordFrame:SetWidth(coordsText:GetStringWidth() * 1.2)
	coordFrame:SetHeight(coordsText:GetStringHeight() + 10)
end

function mod:ResetPosition()
	coordFrame:ClearAllPoints()
	coordFrame:SetPoint("CENTER", Minimap, "BOTTOM")
	self.db.profile.x, self.db.profile.y = nil, nil
end

