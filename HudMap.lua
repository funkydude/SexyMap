local parent = SexyMap
local modName = "HudMap"
local mod = SexyMap:NewModule(modName, "AceTimer-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SexyMap")
local db

local options = {
	type = "group",
	name = modName,
	args = {
		desc = {
			type = "description",
			order = 1,
			name = L["Enable a HUD minimap. This is very useful for gathering resources, but for technical reasons, the HUD map and the normal minimap can't be shown at the same time. Showing the HUD map will turn off the normal minimap."]
		},
		enable = {
			type = "toggle",
			name = L["Enable"],
			get = function()
				return HudMapCluster:IsVisible()
			end,
			set = function(info, v)
				mod:Toggle(v)
			end
		},
		binding = {
			type = "keybinding",
			name = L["Keybinding"],
			get = function()
				return GetBindingKey("TOGGLESEXYMAPGATHERMAP")
			end,
			set = function(info, v)
				SetBinding(v, "TOGGLESEXYMAPGATHERMAP")
			end
		}
	}
}

local onShow = function(self)
	self.rotSettings = GetCVar("rotateMinimap")
	SetCVar("rotateMinimap", "1")
	if GatherMate then
		GatherMate:GetModule("Display"):ReparentMinimapPins(HudMapCluster)
		GatherMate:GetModule("Display"):ChangedVars(nil, "ROTATE_MINIMAP", "1")
	end
	
	MinimapCluster:Hide()
end

local onHide = function(self)
	SetCVar("rotateMinimap", self.rotSettings)
	if GatherMate then
		GatherMate:GetModule("Display"):ReparentMinimapPins(Minimap)
		GatherMate:GetModule("Display"):ChangedVars(nil, "ROTATE_MINIMAP", self.rotSettings)
	end
	MinimapCluster:Show()
end

local arrow
function mod:OnInitialize()
	SexyMapHudMap:SetPoint("CENTER")
 	HudMapCluster:SetScale(8)
	SexyMapHudMap:SetAlpha(0)
	SexyMapHudMap:EnableMouse(false)
	setmetatable(HudMapCluster, { __index = SexyMapHudMap })
	
	local gatherCircle = HudMapCluster:CreateTexture()
	gatherCircle:SetTexture([[SPELLS\CIRCLE.BLP]])
	gatherCircle:SetBlendMode("ADD")
	gatherCircle:SetPoint("CENTER")
	gatherCircle:SetVertexColor(0,1,0,0.2)
	local radius = SexyMapHudMap:GetWidth() * 0.45
	gatherCircle:SetWidth(radius)
	gatherCircle:SetHeight(radius)

	HudMapCluster:Hide()	
	HudMapCluster:SetScript("OnShow", onShow)
	HudMapCluster:SetScript("OnHide", onHide)	
	
	arrow = HudMapCluster:CreateTexture()
	arrow:SetTexture([[Interface\Minimap\ROTATING-MINIMAPARROW]])
	arrow:SetWidth(30 / HudMapCluster:GetScale())
	arrow:SetHeight(30 / HudMapCluster:GetScale())
	arrow:SetPoint("CENTER", SexyMapHudMap, "CENTER")
	
	parent:RegisterModuleOptions(modName, options, modName)
end

function mod:OnEnable()
	self:RegisterEvent("PLAYER_LOGOUT")
end

function mod:PLAYER_LOGOUT()
	self:Toggle(false)
end

function mod:Toggle(flag)
	if flag == nil then
		if HudMapCluster:IsVisible() then
			HudMapCluster:Hide()
		else
			HudMapCluster:Show()
		end
	else
		if flag then
			HudMapCluster:Show()
		else
			HudMapCluster:Hide()
		end
	end
end
