local parent = SexyMap
local modName = "HudMap"
local mod = SexyMap:NewModule(modName, "AceTimer-3.0", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SexyMap")
local db

local updateFrame = CreateFrame("Frame")
local updateRotations

local onShow = function(self)
	self.rotSettings = GetCVar("rotateMinimap")
	SetCVar("rotateMinimap", "1")
	if db.useGatherMate and GatherMate then
		GatherMate:GetModule("Display"):ReparentMinimapPins(HudMapCluster)
		GatherMate:GetModule("Display"):ChangedVars(nil, "ROTATE_MINIMAP", "1")
	end
	
	if db.useRoutes and Routes and Routes.ReparentMinimap then
		Routes:ReparentMinimap(HudMapCluster)
		Routes:CVAR_UPDATE(nil, "ROTATE_MINIMAP", "1")
	end
	
	updateFrame:SetScript("OnUpdate", updateRotations)
	MinimapCluster:Hide()
end

local onHide = function(self, force)
	SetCVar("rotateMinimap", self.rotSettings)
	if (db.useGatherMate or force) and GatherMate then
		GatherMate:GetModule("Display"):ReparentMinimapPins(Minimap)
		GatherMate:GetModule("Display"):ChangedVars(nil, "ROTATE_MINIMAP", self.rotSettings)
	end
	
	if (db.useRoutes or force) and Routes and Routes.ReparentMinimap then
		Routes:ReparentMinimap(Minimap)
		Routes:CVAR_UPDATE(nil, "ROTATE_MINIMAP", self.rotSettings)
	end
	
	updateFrame:SetScript("OnUpdate", nil)
	MinimapCluster:Show()
end

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
		},
		gathermate = {
			type = "toggle",
			name = L["Use GatherMate pins"],
			disabled = function()
				return GatherMate == nil
			end,
			get = function()
				return db.useGatherMate
			end,
			set = function(info, v)
				db.useGatherMate = v
				if HudMapCluster:IsVisible() then
					onHide(HudMapCluster, true)
					onShow(HudMapCluster)
				end
			end
		},
		routes = {
			type = "toggle",
			name = L["Use Routes"],
			disabled = function()
				return Routes == nil or Routes.ReparentMinimap == nil
			end,
			get = function()
				return db.useRoutes
			end,
			set = function(info, v)
				db.useRoutes = v
				if HudMapCluster:IsVisible() then
					onHide(HudMapCluster, true)
					onShow(HudMapCluster)
				end
			end
		},
		color = {
			type = "color",
			hasAlpha = true,
			name = L["HUD Color"],
			get = function()
				local c = db.hudColor
				return c.r or 0, c.g or 1, c.b or 0, c.a or 1
			end,
			set = function(info, r, g, b, a)
				local c = db.hudColor
				c.r, c.g, c.b, c.a = r, g, b, a
				mod:UpdateColors()
			end
		}
	}
}

local directions = {}
local defaults = {
	profile = {
		useGatherMate = true,
		useRoutes = true,
		hudColor = {}
	}
}

local coloredTextures = {}
function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
	db = self.db.profile
	
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
	local radius = SexyMapHudMap:GetWidth() * 0.45
	gatherCircle:SetWidth(radius)
	gatherCircle:SetHeight(radius)
	gatherCircle.alphaFactor = 0.5
	tinsert(coloredTextures, gatherCircle)
	
	local gatherLine = HudMapCluster:CreateTexture("GatherLine")
	gatherLine:SetTexture([[Interface\BUTTONS\WHITE8X8.BLP]])
	gatherLine:SetBlendMode("ADD")
	local nudge = 4 / HudMapCluster:GetScale()
	gatherLine:SetPoint("BOTTOM", HudMapCluster, "CENTER", 0, nudge)
	gatherLine:SetWidth(0.2)
	gatherLine:SetHeight((SexyMapHudMap:GetWidth() * 0.214) - nudge)
	tinsert(coloredTextures, gatherLine)
	
	local playerDot = HudMapCluster:CreateTexture()
	playerDot:SetTexture([[Interface\GLUES\MODELS\UI_Tauren\gradientCircle.blp]])
	playerDot:SetBlendMode("ADD")
	playerDot:SetPoint("CENTER")
	playerDot:SetWidth(25 / HudMapCluster:GetScale())
	playerDot:SetHeight(25 / HudMapCluster:GetScale())
	playerDot.alphaFactor = 2
	tinsert(coloredTextures, playerDot)
	
	local indicators = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"}
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
	self:UpdateColors()
end

do
	local target = 1 / 90
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

function mod:UpdateColors()
	local c = db.hudColor
	for k, v in ipairs(coloredTextures) do
		v:SetVertexColor(c.r or 0, c.g or 1, c.b or 0, (c.a or 1) * (v.alphaFactor or 1) / HudMapCluster:GetAlpha())
	end
end
