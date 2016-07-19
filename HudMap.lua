
local _, sm = ...
sm.hudmap = {}
if sm then return end -- XXX disable for now

local mod = sm.hudmap
local L = sm.L

local updateFrame = CreateFrame("Frame")
local updateRotations, HudMapCluster, SexyMapHudMap

local onShow = function(self)
	self.rotSettings = GetCVar("rotateMinimap")
	SetCVar("rotateMinimap", "1")

	if mod.db.useGatherMate ~= false and GatherMate2 then
		GatherMate2:GetModule("Display"):ReparentMinimapPins(HudMapCluster)
		GatherMate2:GetModule("Display"):ChangedVars(nil, "ROTATE_MINIMAP", "1")
	end

	if mod.db.useQuestHelper ~= false and QuestHelper then
		QuestHelper:SetMinimapObject(HudMapCluster)
	end

	if mod.db.useRoutes ~= false and Routes then
		Routes:ReparentMinimap(HudMapCluster)
		Routes:CVAR_UPDATE(nil, "ROTATE_MINIMAP", "1")
	end

	--[[if mod.db.useTomTom ~= false and TomTom then
		TomTom:ReparentMinimap(HudMapCluster)
		local Astrolabe = DongleStub("Astrolabe-1.0") -- Astrolabe is bundled with TomTom (it's not packaged with SexyMap)
		Astrolabe.processingFrame:SetParent(HudMapCluster)
	end]]

	if mod.db.useNpcScan ~= false and _NPCScan and _NPCScan.Overlay then
		_NPCScan.Overlay.Modules.List["Minimap"]:SetMinimapFrame(HudMapCluster)
	end

	updateFrame:SetScript("OnUpdate", updateRotations)
	Minimap:Hide()
	mod:SetScales()
end

local onHide = function(self, force)
	updateFrame:SetScript("OnUpdate", nil)
	SetCVar("rotateMinimap", self.rotSettings)

	if (force or mod.db.useGatherMate ~= false) and GatherMate2 then
		GatherMate2:GetModule("Display"):ReparentMinimapPins(Minimap)
		GatherMate2:GetModule("Display"):ChangedVars(nil, "ROTATE_MINIMAP", self.rotSettings)
	end

	if (force or mod.db.useQuestHelper ~= false) and QuestHelper then
		QuestHelper:SetMinimapObject(Minimap)
	end

	if (force or mod.db.useRoutes ~= false) and Routes then
		Routes:ReparentMinimap(Minimap)
		Routes:CVAR_UPDATE(nil, "ROTATE_MINIMAP", self.rotSettings)
	end

	--[[if (force or mod.db.useTomTom ~= false) and TomTom then
		TomTom:ReparentMinimap(Minimap)
		local Astrolabe = DongleStub("Astrolabe-1.0") -- Astrolabe is bundled with TomTom (it's not packaged with SexyMap)
		Astrolabe.processingFrame:SetParent(Minimap)
	end]]

	if (force or mod.db.useNpcScan ~= false) and _NPCScan and _NPCScan.Overlay then
		_NPCScan.Overlay.Modules.List["Minimap"]:SetMinimapFrame(Minimap)
	end

	Minimap:Show()
end

local options = {
	type = "group",
	name = "HudMap",
	args = {
		desc = {
			type = "description",
			order = 0,
			name = L["Enable a HUD minimap. This is very useful for gathering resources, but for technical reasons, the HUD map and the normal minimap can't be shown at the same time. Showing the HUD map will turn off the normal minimap."]
		},
		enable = {
			type = "toggle",
			name = L["Enable Hudmap"],
			order = 1,
			get = function()
				return HudMapCluster:IsVisible()
			end,
			set = function(info, v)
				mod:Toggle(v)
			end,
		},
		binding = {
			type = "keybinding",
			name = L["Keybinding"],
			order = 2,
			get = function()
				return GetBindingKey("TOGGLESEXYMAPGATHERMAP")
			end,
			set = function(info, v)
				SetBinding(v, "TOGGLESEXYMAPGATHERMAP")
				SaveBindings(GetCurrentBindingSet())
			end
		},
		color = {
			type = "color",
			hasAlpha = true,
			order = 3,
			name = L["HUD Color"],
			get = function()
				local c = mod.db.hudColor
				return c.r or 0, c.g or 1, c.b or 0, c.a or 1
			end,
			set = function(info, r, g, b, a)
				local c = mod.db.hudColor
				c.r, c.g, c.b, c.a = r, g, b, a
				mod:UpdateColors()
			end
		},
		textcolor = {
			type = "color",
			hasAlpha = true,
			name = L["Text Color"],
			order = 4,
			get = function()
				local c = mod.db.textColor
				return c.r or 0, c.g or 1, c.b or 0, c.a or 1
			end,
			set = function(info, r, g, b, a)
				local c = mod.db.textColor
				c.r, c.g, c.b, c.a = r, g, b, a
				mod:UpdateColors()
			end
		},
		scale = {
			type = "range",
			name = L["Scale"],
			order = 5,
			min = 1.0,
			max = 3.0,
			step = 0.1,
			bigStep = 0.1,
			get = function()
				return mod.db.scale
			end,
			set = function(info, v)
				mod.db.scale = v
				mod:SetScales()
			end
		},
		alpha = {
			type = "range",
			name = L["Opacity"],
			order = 6,
			min = 0,
			max = 1,
			step = 0.01,
			bigStep = 0.01,
			get = function()
				return mod.db.alpha
			end,
			set = function(info, v)
				mod.db.alpha = v
				HudMapCluster:SetAlpha(v)
			end
		},
		addonsHeader = {
			order = 7,
			type = "header",
			name = ADDONS,
		},
		addonDesc = {
			type = "description",
			name = L["The HudMap supports several addons. If you have any of the addons below installed, they will be shown on the HudMap."],
			order = 8
		},
		npcscan = {
			type = "toggle",
			order = 100,
			name = "_NPCScan.Overlay",
			width = "full",
			disabled = function()
				return _NPCScan == nil or _NPCScan.Overlay == nil
			end,
			get = function()
				return mod.db.useNpcScan ~= false
			end,
			set = function(info, v)
				mod.db.useNpcScan = v
				if HudMapCluster:IsVisible() then
					onHide(HudMapCluster, true)
					onShow(HudMapCluster)
				end
			end
		},
		gathermate = {
			type = "toggle",
			order = 105,
			name = "Gathermate",
			width = "full",
			disabled = function()
				return GatherMate2 == nil
			end,
			get = function()
				return mod.db.useGatherMate ~= false
			end,
			set = function(info, v)
				mod.db.useGatherMate = v
				if HudMapCluster:IsVisible() then
					onHide(HudMapCluster, true)
					onShow(HudMapCluster)
				end
			end
		},
		questhelper = {
			type = "toggle",
			order = 106,
			name = "QuestHelper",
			width = "full",
			disabled = function()
				return QuestHelper == nil
			end,
			get = function()
				return mod.db.useQuestHelper ~= false
			end,
			set = function(info, v)
				mod.db.useQuestHelper = v
				if HudMapCluster:IsVisible() then
					onHide(HudMapCluster, true)
					onShow(HudMapCluster)
				end
			end
		},
		routes = {
			type = "toggle",
			name = "Routes",
			width = "full",
			order = 110,
			disabled = function()
				return Routes == nil
			end,
			get = function()
				return mod.db.useRoutes ~= false
			end,
			set = function(info, v)
				mod.db.useRoutes = v
				if HudMapCluster:IsVisible() then
					onHide(HudMapCluster, true)
					onShow(HudMapCluster)
				end
			end
		},
		tomtom = {
			type = "toggle",
			name = "TomTom",
			width = "full",
			order = 115,
			disabled = function()
				return true
			end,
			get = function()
				return mod.db.useTomTom ~= false
			end,
			set = function(info, v)
				mod.db.useTomTom = v
				if HudMapCluster:IsVisible() then
					onHide(HudMapCluster, true)
					onShow(HudMapCluster)
				end
			end
		},
	}
}

local directions = {}
local playerDot

local coloredTextures = {}
local gatherCircle, gatherLine
local indicators = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"}

do
	local target = 1 / 90
	local total = 0

	function updateRotations(self, t)
		total = total + t
		if total < target then return end

		-- Sometimes, somehow, rotating gets turned off, so force it on when HudMap is on
		if GetCVar("rotateMinimap") == "0" then
			SetCVar("rotateMinimap", "1")
		end

		while total > target do total = total - target end
		local bearing = GetPlayerFacing()
		for k, v in ipairs(directions) do
			local x, y = math.sin(v.rad + bearing), math.cos(v.rad + bearing)
			v:ClearAllPoints()
			v:SetPoint("CENTER", HudMapCluster, "CENTER", x * v.radius, y * v.radius)
		end
	end
end

function mod:OnInitialize(profile)
	if type(profile.hudmap) ~= "table" then
		profile.hudmap = {
			hudColor = {},
			textColor = {r = 0.5, g = 1, b = 0.5, a = 1},
			scale = 1.4,
			alpha = 0.7
		}
	end
	self.db = profile.hudmap
end

function mod:OnEnable()
	sm.core:RegisterModuleOptions("HudMap", options, "HudMap")

	HudMapCluster = CreateFrame("Frame", "HudMapCluster", UIParent)
	HudMapCluster:SetWidth(140)
	HudMapCluster:SetHeight(140)
	HudMapCluster:SetPoint("CENTER", UIParent, "CENTER")

	SexyMapHudMap = CreateFrame("Minimap", "SexyMapHudMap", HudMapCluster)
	SexyMapHudMap:SetWidth(140)
	SexyMapHudMap:SetHeight(140)
	SexyMapHudMap:SetPoint("CENTER", HudMapCluster, "CENTER")

	-- Removes the circular "waffle-like" texture that shows when using a non-circular minimap in the blue quest objective area.
	SexyMapHudMap:SetArchBlobRingScalar(0)
	SexyMapHudMap:SetArchBlobRingAlpha(0)
	SexyMapHudMap:SetQuestBlobRingScalar(0)
	SexyMapHudMap:SetQuestBlobRingAlpha(0)

	HudMapCluster:SetFrameStrata("BACKGROUND")
	HudMapCluster:SetAlpha(mod.db.alpha)
	SexyMapHudMap:SetAlpha(0)
	SexyMapHudMap:EnableMouse(false)

	setmetatable(HudMapCluster, { __index = SexyMapHudMap })

	BINDING_HEADER_SexyMap = "SexyMap"
	BINDING_NAME_TOGGLESEXYMAPGATHERMAP = L["Toggle HudMap On/Off"]
	gatherCircle = HudMapCluster:CreateTexture()
	gatherCircle:SetTexture([[SPELLS\CIRCLE.BLP]])
	gatherCircle:SetBlendMode("ADD")
	gatherCircle:SetPoint("CENTER")
	local radius = SexyMapHudMap:GetWidth() * 0.45
	gatherCircle:SetWidth(radius)
	gatherCircle:SetHeight(radius)
	gatherCircle.alphaFactor = 0.5
	tinsert(coloredTextures, gatherCircle)

	gatherLine = HudMapCluster:CreateTexture("GatherLine")
	gatherLine:SetTexture([[Interface\BUTTONS\WHITE8X8.BLP]])
	gatherLine:SetBlendMode("ADD")
	local nudge = 0.65
	gatherLine:SetPoint("BOTTOM", HudMapCluster, "CENTER", 0, nudge)
	gatherLine:SetWidth(0.2)
	gatherLine:SetHeight((SexyMapHudMap:GetWidth() * 0.214) - nudge)
	tinsert(coloredTextures, gatherLine)

	playerDot = HudMapCluster:CreateTexture()
	playerDot:SetTexture([[Interface\GLUES\MODELS\UI_Tauren\gradientCircle.blp]])
	playerDot:SetBlendMode("ADD")
	playerDot:SetPoint("CENTER")
	playerDot.alphaFactor = 2
	tinsert(coloredTextures, playerDot)

	local indicators = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"}
	local radius = SexyMapHudMap:GetWidth() * 0.214
	for k, v in ipairs(indicators) do
		local rot = (0.785398163 * (k-1))
		local ind = HudMapCluster:CreateFontString(nil, nil, "GameFontNormalSmall")
		local x, y = math.sin(rot), math.cos(rot)
		ind:SetPoint("CENTER", HudMapCluster, "CENTER", x * radius, y * radius)
		ind:SetText(v)
		ind:SetShadowOffset(0.2,-0.2)
		ind.rad = rot
		ind.radius = radius
		tinsert(directions, ind)
	end

	HudMapCluster:Hide()
	HudMapCluster:SetScript("OnShow", onShow)
	HudMapCluster:SetScript("OnHide", onHide)
	Minimap:HookScript("OnShow", self.Minimap_OnShow)

	self:UpdateColors()
	self:SetScales()

	HudMapCluster._GetScale = HudMapCluster.GetScale
	HudMapCluster.GetScale = function()
		return 1
	end

	updateFrame:RegisterEvent("PLAYER_LOGOUT")
end

updateFrame:SetScript("OnEvent", function()
	mod:Toggle(false)
end)

function mod:Minimap_OnShow()
	if HudMapCluster:IsVisible() then
		HudMapCluster:Hide()
	end
end

function mod:Toggle(flag)
	if flag then
		HudMapCluster:Show()
	else
		HudMapCluster:Hide()
	end
end

function mod:UpdateColors()
	local c = mod.db.hudColor
	for k, v in ipairs(coloredTextures) do
		v:SetVertexColor(c.r or 0, c.g or 1, c.b or 0, (c.a or 1) * (v.alphaFactor or 1) / HudMapCluster:GetAlpha())
	end

	c = mod.db.textColor
	for k, v in ipairs(directions) do
		v:SetTextColor(c.r, c.g, c.b, c.a)
	end
end

function mod:SetScales()
	SexyMapHudMap:ClearAllPoints()
	SexyMapHudMap:SetPoint("CENTER", UIParent, "CENTER")

	HudMapCluster:ClearAllPoints()
	HudMapCluster:SetPoint("CENTER")

	local size = UIParent:GetHeight() / mod.db.scale
	SexyMapHudMap:SetWidth(size)
	SexyMapHudMap:SetHeight(size)
	HudMapCluster:SetHeight(size)
	HudMapCluster:SetWidth(size)
	gatherCircle:SetWidth(size * 0.45)
	gatherCircle:SetHeight(size * 0.45)
	gatherLine:SetHeight((SexyMapHudMap:GetWidth() * 0.214) - 0.65)

	HudMapCluster:SetScale(mod.db.scale)
	playerDot:SetWidth(15)
	playerDot:SetHeight(15)

	for k, v in ipairs(directions) do
		v.radius = SexyMapHudMap:GetWidth() * 0.214
	end
end
