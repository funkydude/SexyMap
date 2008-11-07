local parent = SexyMap
local modName = "HudMap"
local mod = SexyMap:NewModule(modName, "AceTimer-3.0", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SexyMap")
local db

local updateFrame = CreateFrame("Frame")
local updateRotations


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
	
	updateFrame:SetScript("OnUpdate", updateRotations)
	MinimapCluster:Hide()
end

local onHide = function(self)
	SetCVar("rotateMinimap", self.rotSettings)
	if GatherMate then
		GatherMate:GetModule("Display"):ReparentMinimapPins(Minimap)
		GatherMate:GetModule("Display"):ChangedVars(nil, "ROTATE_MINIMAP", self.rotSettings)
	end
	
	updateFrame:SetScript("OnUpdate", nil)
	MinimapCluster:Show()
end

local directions = {}

function mod:OnInitialize()
	SexyMapHudMap:SetPoint("CENTER")
 	HudMapCluster:SetScale(8)
	HudMapCluster:SetAlpha(0.7)
	SexyMapHudMap:SetAlpha(0)
	SexyMapHudMap:EnableMouse(false)
	setmetatable(HudMapCluster, { __index = SexyMapHudMap })
	
	local gatherCircle = HudMapCluster:CreateTexture()
	gatherCircle:SetTexture([[SPELLS\CIRCLE.BLP]])
	gatherCircle:SetBlendMode("ADD")
	gatherCircle:SetPoint("CENTER")
	gatherCircle:SetVertexColor(0,1,0,0.05 / HudMapCluster:GetAlpha())
	local radius = SexyMapHudMap:GetWidth() * 0.45
	gatherCircle:SetWidth(radius)
	gatherCircle:SetHeight(radius)
	
	local gatherLine = HudMapCluster:CreateTexture("GatherLine")
	gatherLine:SetTexture([[Interface\BUTTONS\WHITE8X8.BLP]])
	gatherLine:SetBlendMode("ADD")
	gatherLine:SetPoint("BOTTOM", HudMapCluster, "CENTER")
	gatherLine:SetVertexColor(0,1,0,0.1 / HudMapCluster:GetAlpha())
	gatherLine:SetWidth(0.2)
	gatherLine:SetHeight(SexyMapHudMap:GetWidth() * 0.214)
	
	local playerDot = HudMapCluster:CreateTexture()
	playerDot:SetTexture([[SPELLS\T_VFX_HERO_CIRCLE.BLP]])
	playerDot:SetBlendMode("ADD")
	playerDot:SetPoint("CENTER")
	playerDot:SetVertexColor(1,1,1, 1)
	playerDot:SetWidth(20 / HudMapCluster:GetScale())
	playerDot:SetHeight(20 / HudMapCluster:GetScale())
	
	local indicators = {"N", "NE", "E", "SE", "S", "SW", "S", "NW"}
	local radius = SexyMapHudMap:GetWidth() * 0.214
	local large, small = 16 / HudMapCluster:GetScale(), 10 / HudMapCluster:GetScale()
	for k, v in ipairs(indicators) do
		local rot = (0.785398163 * (k-1))
		local ind = HudMapCluster:CreateFontString(nil, nil, "GameFontNormalSmall")
		local x, y = math.sin(rot), math.cos(rot)
		ind:SetPoint("CENTER", HudMapCluster, "CENTER", x * radius, y * radius)
		
		local font, size, flags = ind:GetFont()
		ind:SetFont(font, k % 2 == 0 and small or large, flags)
		ind:SetTextColor(0.5,1,0.5,1)
		ind:SetText(v)
		-- ind:SetShadowColor(1,1,1,1)
		ind:SetShadowOffset(0.2,-0.2)
		ind.rad = rot
		ind.radius = radius
		tinsert(directions, ind)
	end
	

	HudMapCluster:Hide()	
	HudMapCluster:SetScript("OnShow", onShow)
	HudMapCluster:SetScript("OnHide", onHide)	
	self:HookScript(Minimap, "OnShow", "Minimap_OnShow")
	
	parent:RegisterModuleOptions(modName, options, modName)
end

do
	local target = 1 / 60
	local total = 0
	function updateRotations(self, t)
		total = total + t
		if total < target then return end
		while total > target do total = total - target end
		local bearing = MiniMapCompassRing:GetFacing()
		for k, v in ipairs(directions) do
			local x, y = math.sin(v.rad - bearing), math.cos(v.rad - bearing)
			v:ClearAllPoints()
			v:SetPoint("CENTER", HudMapCluster, "CENTER", x * v.radius, y * v.radius)
		end
	end
end

function mod:OnEnable()
	self:RegisterEvent("PLAYER_LOGOUT")
end

function mod:Minimap_OnShow()
	onHide(HudMapCluster)
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
