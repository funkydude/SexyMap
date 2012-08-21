
local _, addon = ...
local parent = addon.SexyMap
local modName = "ZoneText"
local media = LibStub("LibSharedMedia-3.0")
local mod = addon.SexyMap:NewModule(modName)
local L = addon.L

local updateLayout = function()
	MinimapZoneTextButton:ClearAllPoints()
	MinimapZoneTextButton:SetParent(Minimap)
	MinimapZoneTextButton:SetPoint("BOTTOM", Minimap, "TOP", mod.db.profile.xOffset, mod.db.profile.yOffset)
	MinimapZoneTextButton:SetBackdropColor(mod.db.profile.bgColor.r, mod.db.profile.bgColor.g, mod.db.profile.bgColor.b, mod.db.profile.bgColor.a)
	MinimapZoneTextButton:SetBackdropBorderColor(mod.db.profile.borderColor.r, mod.db.profile.borderColor.g, mod.db.profile.borderColor.b, mod.db.profile.borderColor.a)
	local a, b, c = MinimapZoneText:GetFont()
	MinimapZoneText:SetFont(mod.db.profile.font and media:Fetch("font", mod.db.profile.font) or a, mod.db.profile.fontsize or b, c)

	mod:ZoneChanged()
end

local options = {
	type = "group",
	name = modName,
	args = {
		width = {
			type = "range",
			name = L["Text Width"],
			order = 0,
			min = 50,
			max = 400,
			step = 1,
			bigStep = 5,
			get = function() return MinimapZoneTextButton:GetWidth() end,
			set = function(info, v) mod.db.profile.width = v updateLayout() end
		},
		font = {
			type = "select",
			name = L["Font"],
			order = 1,
			dialogControl = "LSM30_Font",
			values = AceGUIWidgetLSMlists.font,
			get = function() return mod.db.profile.font end,
			set = function(info, v)
				mod.db.profile.font = v
				updateLayout()
			end
		},
		fontSize = {
			type = "range",
			name = L["Font Size"],
			order = 2,
			min = 4,
			max = 30,
			step = 1,
			bigStep = 1,
			get = function() return mod.db.profile.fontsize or select(2, MinimapZoneText:GetFont()) end,
			set = function(info, v)
				mod.db.profile.fontsize = v
				updateLayout()
			end
		},
		fontColor = {
			type = "color",
			name = L["Font Color"],
			order = 3,
			hasAlpha = true,
			get = function()
				if mod.db.profile.fontColor.r then
					return mod.db.profile.fontColor.r, mod.db.profile.fontColor.g, mod.db.profile.fontColor.b, mod.db.profile.fontColor.a
				else
					return MinimapZoneText:GetTextColor()
				end
			end,
			set = function(info, r, g, b, a)
				mod.db.profile.fontColor.r, mod.db.profile.fontColor.g, mod.db.profile.fontColor.b, mod.db.profile.fontColor.a = r, g, b, a
				updateLayout()
			end
		},
		xOffset = {
			type = "range",
			name = L["Horizontal Position"],
			order = 6,
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
			order = 6,
			min = -250,
			max = 250,
			step = 1,
			bigStep = 5,
			get = function() return mod.db.profile.yOffset end,
			set = function(info, v) mod.db.profile.yOffset = v updateLayout() end
		},
		bgColor = {
			type = "color",
			name = L["Background Color"],
			order = 7,
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
			order = 8,
			hasAlpha = true,
			get = function()
				return mod.db.profile.borderColor.r, mod.db.profile.borderColor.g, mod.db.profile.borderColor.b, mod.db.profile.borderColor.a
			end,
			set = function(info, r, g, b, a)
				mod.db.profile.borderColor.r, mod.db.profile.borderColor.g, mod.db.profile.borderColor.b, mod.db.profile.borderColor.a = r, g, b, a
				updateLayout()
			end
		},
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
	parent:RegisterModuleOptions(modName, options, L["Zone Text"])
end

local hooked
function mod:OnEnable()
	MinimapZoneText:ClearAllPoints()
	MinimapZoneText:SetAllPoints()
	MinimapZoneTextButton:SetHeight(26)
	MinimapZoneTextButton:SetBackdrop(parent.backdrop)
	MinimapZoneTextButton:SetFrameStrata("MEDIUM")

	updateLayout()
	if not hooked then
		hooked = true
		MinimapCluster:HookScript("OnEvent", self.ZoneChanged)
	end
end

function mod:ZoneChanged()
	local width = max(MinimapZoneText:GetStringWidth() * 1.3, mod.db.profile.width or 0)
	MinimapZoneTextButton:SetHeight(MinimapZoneText:GetStringHeight() + 10)
	MinimapZoneTextButton:SetWidth(width)
	if mod.db.profile.fontColor.r then
		MinimapZoneText:SetTextColor(mod.db.profile.fontColor.r, mod.db.profile.fontColor.g, mod.db.profile.fontColor.b, mod.db.profile.fontColor.a)
	end
end

