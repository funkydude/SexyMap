
local _, addon = ...
local parent = addon.SexyMap
local modName = "Coordinates"
local mod = addon.SexyMap:NewModule(modName, "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SexyMap")

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
					parent:EnableModule(modName)
				else
					parent:DisableModule(modName)
				end
			end,
			disabled = false,
		},
		lock = {
			type = "toggle",
			name = L["Lock coordinates"],
			order = 2,
			get = function()
				return mod.db.profile.locked
			end,
			set = function(info, v)
				mod.db.profile.locked = v
			end,
			width = "full",
		},
		fontSize = {
			type = "range",
			name = L["Font size"],
			order = 3,
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
				mod:UpdateCoords()
			end
		},
		fontColor = {
			type = "color",
			name = L["Font color"],
			order = 4,
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
			name = L["Backdrop color"],
			order = 5,
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
			name = L["Border color"],
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
		reset = {
			type = "execute",
			name = L["Reset position"],
			order = 6,
			func = function()
				mod:ResetPosition()
			end,
		},
	}
}

local defaults = {
	profile = {
		borderColor = {},
		backgroundColor = {},
		locked = false,
		fontColor = {},
		enabled = false
	}
}

function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
	parent:RegisterModuleOptions(modName, options, modName)
end

local coordFrame, coordsText
function mod:OnEnable()
	if not self.db.profile.enabled then
		parent:DisableModule(modName)
		return
	end

	if not coordFrame then
		coordFrame = CreateFrame("Frame", "SexyMapCoordFrame", Minimap)
		coordFrame:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			insets = {left = 2, top = 2, right = 2, bottom = 2},
			edgeSize = 12,
			tile = true
		})
		coordsText = coordFrame:CreateFontString(nil, nil, "GameFontNormalSmall")
		coordsText:SetPoint("CENTER", coordFrame, "CENTER")
		coordsText:SetJustifyH("CENTER")

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

		self:UpdateCoords()
		self:Update()
	end
	if self.db.profile.x then
		coordFrame:ClearAllPoints()
		coordFrame:SetPoint("CENTER", Minimap, "CENTER", -self.db.profile.x, -self.db.profile.y)
	else
		coordFrame:SetPoint("CENTER", Minimap, "BOTTOM")
	end

	coordFrame:Show()
	self:ScheduleRepeatingTimer("UpdateCoords", 0.2)
end

function mod:OnDisable()
	if coordFrame then
		self:CancelAllTimers()
		coordFrame:Hide()
	end
end

do
	local GetPlayerMapPosition = GetPlayerMapPosition
	local txt = "%.1f, %.1f"
	function mod:UpdateCoords()
		local x, y = GetPlayerMapPosition"player"
		coordsText:SetFormattedText(txt, x*100, y*100)
	end
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

