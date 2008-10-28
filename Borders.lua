local parent = SexyMap
local modName = "Borders"
local mod = SexyMap:NewModule(modName)
local L = LibStub("AceLocale-3.0"):GetLocale("SexyMap")
local db
local textures = {}
local texturePool = {}
local rotateTextures = {}
local defaultSize = 180
local rotFrame = CreateFrame("Frame")
local layers = {
	BACKGROUND = L["1. Background"],
	BORDER = L["2. Border"],
	ARTWORK = L["3. Artwork"],
	OVERLAY = L["4. Overlay"],
	HIGHLIGHT = L["5. Highlight"],
}
local blendModes = {
	BLEND = L["Blend (normal)"],
	DISABLE = L["Disable (opaque)"],
	ALPHAKEY = L["Alpha Key (1-bit alpha)"],
	MOD = L["Mod Blend (modulative)"],
	ADD = L["Add Blend (additive)"],
}

local _G = getfenv(0)
local tinsert, tremove, pairs, ipairs, type, select = _G.tinsert, _G.tremove, _G.pairs, _G.ipairs, _G.type, _G.select
local sin, cos = _G.sin, _G.cos

local Minimap, MinimapCluster, MinimapBorder = _G.Minimap, _G.MinimapCluster, _G.MinimapBorder

local presets = {}
for k, v in pairs(parent.borderPresets) do
	presets[k] = k
end

local function deepCopyHash(t)
	local nt = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			nt[k] = deepCopyHash(v)
		else
			nt[k] = v
		end
	end
	return nt
end

local GetPlayerBearing
function GetPlayerBearing()
	local obj; -- Remains an upvalue
	do
		for i = 1, Minimap:GetNumChildren() do
			local v = select(i, Minimap:GetChildren())
			if v:IsObjectType("Model") and not v:GetName() then
				local model = v:GetModel():lower()
				if model:match("interface\\minimap\\minimaparrow") then 
					obj = v; break;
				end
			end
		end
	end
	if not obj then return; end

	-- If we've found what we were looking for, rewrite function to skip the search next time.
	GetPlayerBearing = function() 
		if GetCVar("rotateMinimap") ~= "0" then
			return (MiniMapCompassRing:GetFacing() * -1)
		else
			return obj:GetFacing(); 
		end
	end
	return GetPlayerBearing();
end
		
local function RotateTexture(self, inc, set)
	if type(inc) == "string" then
		local bearing = GetPlayerBearing()
		if inc ~= "normal" then
			bearing = bearing * -1
		end
		bearing = bearing * 57.2957795
		RotateTexture(self, bearing, true)
	else
		self.hAngle = (set and 0 or self.hAngle or 0) - inc;
		local s = sin(self.hAngle);
		local c = cos(self.hAngle);
		
		self:SetTexCoord(
			0.5 - s, 0.5 + c,
			0.5 + c, 0.5 + s,
			0.5 - c, 0.5 - s,
			0.5 + s, 0.5 - c
		)
	end
end

local selectedPreset
local options = {
	type = "group",
	name = "Borders",
	args = {
		newDesc = {
			type = "description",
			name = L["Enter a name to create a new border. The name can be anything you like to help you identify that border."],
			order = 1
		},
		new = {
			type = "input",
			name = L["Create new border"],
			order = 2,
			width = "full",
			set = function(info, v)
				mod:NewBorder(v)
			end
		},
		preset = {
			type = "select",
			name = L["Preset"],
			width = "double",
			desc = L["Select a preset to load settings from. This will erase any of your current borders."],
			confirm = true,
			confirmText = L["This will wipe out any current settings!"],
			values = presets,
			get = function()
				return selectedPreset
			end,
			set = function(info, v)
				selectedPreset = v
				mod:ApplyPreset(v)
			end
		},
		hideBlizzard = {
			type = "toggle",
			name = L["Hide default border"],
			desc = L["Hide the default border on the minimap."],
			get = function() return db.hideBlizzard end,
			set = function(info, v) db.hideBlizzard = v; mod:Update() end,
		},
		borders = {
			name = L["Borders"],
			type = "group",
			args = {
			}
		}
	}
}

local function getTextureAndDB(info)
	local key = info.options.args[info[1]].args[info[2]].args[info[3]].arg
	return textures[key]
end

local borderOptions = {
	header1 = {
		type = "header",
		name = L["Entry options"],
		order = 1
	},
	name = {
		type = "input",
		name = L["Name"],
		order = 2,
		get = function(info)
			return info.options.args[info[1]].args[info[2]].args[info[3]].name
		end,
		set = function(info, name)
			info.options.args[info[1]].args[info[2]].args[info[3]].name = name
			local tex = getTextureAndDB(info)
			tex.settings.name = name
		end
	},
	delete = {
		type = "execute",
		name = L["Delete"],
		confirm = true,
		confirmText = L["Really delete this border?"],
		order = 3,
		func = function(info)
			local index = info.options.args[info[1]].args[info[2]].args[info[3]].arg
			for k, v in ipairs(db.borders) do
				if v == textures[index].settings then
					tremove(db.borders, k)
					break
				end
			end
			info.options.args[info[1]].args[info[2]].args[index] = nil
			rotateTextures[textures[index]] = nil
			tinsert(texturePool, textures[index])
			textures[index]:Hide()
			textures[index] = nil
		end
	},
	header2 = {
		type = "header",
		name = L["Texture path"],
		order = 50
	},
	textureText = {
		type = "description",
		name = L["Enter the full path to a texture to use. It's recommended that you use something like |cffff6600TexBrowser|r to find textures to use."],
		order = 51
	},
	openTexBrowser = {
		type = "execute",
		name = function()
			if GetAddOnInfo("TexBrowser") ~= nil then
				return L["Open TexBrowser"]
			else
				return L["TexBrowser Not Installed"]
			end
		end,
		order = 52,
		func = function()
			if not IsAddOnLoaded("TexBrowser") then
				EnableAddOn("TexBrowser")
				LoadAddOn("TexBrowser")
			end
			TexBrowser:OnEnable()
		end,
		disabled = function()
			return GetAddOnInfo("TexBrowser") == nil
		end
	},
	texture = {
		type = "input",
		name = L["Texture path"],
		order = 53,
		width = "full",
		get = function(info)
			local tex = getTextureAndDB(info)
			return tex.settings.texture
		end,
		set = function(info, v)
			local tex = getTextureAndDB(info)
			tex.settings.texture = v
			tex:SetTexture(v)
		end
	},
	header3 = {
		type = "header",
		name = L["Texture options"],
		order = 99
	},	
	scale = {
		type = "range",
		name = L["Scale"],
		min = 0.2,
		max = 3.0,
		step = 0.01,
		bigStep = 0.01,
		width = "full",
		get = function(info)
			local tex = getTextureAndDB(info)
			return tex.settings.scale or 1
		end,
		set = function(info, v)
			local tex = getTextureAndDB(info)
			tex.settings.scale = v
			tex:SetWidth(defaultSize * v)
			tex:SetHeight(defaultSize * v)
		end
	},
	rotation = {
		type = "range",
		name = L["Rotation Speed"],
		desc = L["Speed to rotate the texture at. A setting of 0 turns off rotation."],
		min = -120,
		max = 120,
		step = 1,
		bigStep = 1,
		disabled = function(info)
			local tex = getTextureAndDB(info)
			return tex.settings.disableRotation or type(rotateTextures[tex]) == "string"
		end,
		width = "full",
		get = function(info)
			local tex = getTextureAndDB(info)
			return tex.settings.rotSpeed or 0
		end,
		set = function(info, v)
			local tex = getTextureAndDB(info)
			tex.settings.rotSpeed = v
			tex.rotSpeed = v
			rotateTextures[tex] = v ~= 0 and v or nil
		end
	},
	staticRotation = {
		type = "range",
		name = L["Static Rotation"],
		desc = L["A static amount to rotate the texture by."],
		min = 0,
		max = 360,
		disabled = function(info)
			local tex = getTextureAndDB(info)
			return tex.settings.disableRotation or type(rotateTextures[tex]) == "string"
		end,
		step = 1,
		bigStep = 1,
		width = "full",
		get = function(info)
			local tex = getTextureAndDB(info)
			return tex.settings.rotation or 0
		end,
		set = function(info, v)
			local tex = getTextureAndDB(info)
			tex.settings.rotation = v
			RotateTexture(tex, v, true)
			tex.rotSpeed = 0
			tex.settings.rotSpeed = 0
			rotateTextures[tex] = nil
		end
	},
	playerRotation = {
		type = "multiselect",
		name = L["Match player rotation"],
		values = {
			normal = L["Normal rotation"],
			reverse = L["Reverse rotation"],
			none = L["Do not match player rotation"],
		},
		get = function(info, v)
			local tex = getTextureAndDB(info)
			return rotateTextures[tex] == v or (not rotateTextures[tex] and v == "none")
		end,
		set = function(info, v)
			local tex = getTextureAndDB(info)
			if v ~= "none" then
				rotateTextures[tex] = v
			else
				rotateTextures[tex] = nil
			end
			tex.settings.playerRotation = v
		end
	},
	color = {
		type = "color",
		name = L["Texture tint"],
		hasAlpha = true,
		get = function(info)
			local tex = getTextureAndDB(info)
			return tex.settings.r or 1, tex.settings.g or 1, tex.settings.b or 1, tex.settings.a or 1
		end,
		set = function(info, r, g, b, a)
			local tex = getTextureAndDB(info)
			tex.settings.r, tex.settings.g, tex.settings.b, tex.settings. a = r, g, b, a
			tex:SetVertexColor(r,g,b,a)
		end
	},
	hNudge = {
		type = "range",
		name = L["Horizontal nudge"],
		min = -100,
		max = 100,
		step = 1,
		bigStep = 1,
		order = 149,
		get = function(info)
			local tex = getTextureAndDB(info)
			return tex.settings.hNudge or 0
		end,
		set = function(info, v)
			local tex = getTextureAndDB(info)
			tex:ClearAllPoints()
			tex.settings.hNudge = v
			tex:SetPoint("CENTER", Minimap, "CENTER", tex.settings.hNudge, tex.settings.vNudge)
		end
	},
	vNudge = {
		type = "range",
		name = L["Vertical nudge"],
		min = -100,
		max = 100,
		step = 1,
		bigStep = 1,
		order = 150,
		get = function(info)
			local tex = getTextureAndDB(info)
			return tex.settings.vNudge or 0
		end,
		set = function(info, v)
			local tex = getTextureAndDB(info)
			tex:ClearAllPoints()
			tex.settings.vNudge = v
			tex:SetPoint("CENTER", Minimap, "CENTER", tex.settings.hNudge, tex.settings.vNudge)
		end
	},
	layer = {
		type = "select",
		name = L["Layer"],
		values = layers,
		get = function(info)
			local tex = getTextureAndDB(info)
			return tex:GetDrawLayer()
		end,
		set = function(info, v)
			local tex = getTextureAndDB(info)
			tex.settings.drawLayer = v
			tex:SetDrawLayer(v)
		end
	},
	blend = {
		type = "select",
		name = L["Blend Mode"],
		values = blendModes,
		get = function(info)
			local tex = getTextureAndDB(info)
			return tex:GetBlendMode()
		end,
		set = function(info, v)
			local tex = getTextureAndDB(info)
			tex.settings.blendMode = v
			tex:SetBlendMode(v)
		end	
	},
	disableRotation = {
		type = "toggle",
		name = L["Disable Rotation"],
		desc = L["Force a square texture. Fixed distortion on square textures."],
		get = function(info)
			local tex = getTextureAndDB(info)
			return tex.settings.disableRotation
		end,
		set = function(info, v)
			local tex = getTextureAndDB(info)
			tex.settings.disableRotation = v
			if v then
				tex:SetTexCoord(0, 1, 0, 1)
				rotateTextures[tex] = nil
			else
				rotateTextures[tex] = tex.settings.rotSpeed
				RotateTexture(tex, tex.settings.rotation or 0, true)
			end
		end
	}
}

local defaults = {
	profile = {
		hideBlizzard = true,
		borders = {},
		userPresets = {},
		applyPreset = "Blue Rune Circles"
	}
}

function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
	db = self.db.profile
	parent:RegisterModuleOptions(modName, options, modName)
	local args = parent:GetModule("General").options.args
	args.preset = deepCopyHash(options.args.preset)
	args.preset.order = 2
	-- args.presetDesc = {
		-- type = "description",
		-- name = [[
			-- A preset is a set of borders and behaviors for your minimap.
		-- ]],
		-- order = 1
	-- }

	if db.applyPreset then
		self:ApplyPreset(db.applyPreset)
		db.applyPreset = false
	else
		for _, v in ipairs(db.borders) do
			self:CreateBorderFromParams(v)
		end
	end
end

local updateTime = 1/60
local totalTime = 0
local function updateRotations(self, t)
	totalTime = totalTime + t
	if totalTime >= updateTime then
		for k, v in pairs(rotateTextures) do
			if type(v) == "number" then
				RotateTexture(k, v * totalTime)
			else
				RotateTexture(k, v)
			end
		end
		while totalTime > updateTime do
			totalTime = totalTime - updateTime
		end
	end
end

function mod:OnEnable()
	self:Update()
	rotFrame:SetScript("OnUpdate", updateRotations)
end

function mod:ApplyPreset(preset)
	local preset = parent.borderPresets[preset]
	db.borders = deepCopyHash(preset.borders)
	if preset.shape then
		parent:GetModule("General"):ApplyShape(preset.shape)
	end
	options.args.borders.args = {}		-- leaky
	for k, v in pairs(textures) do
		tinsert(texturePool, v)
		v:Hide()
		textures[k] = nil
	end
	for k, v in pairs(rotateTextures) do
		rotateTextures[k] = nil
	end
	
	for _, v in ipairs(db.borders) do
		self:CreateBorderFromParams(v)
	end
end

function mod:NewBorder(name)
	local t = {name = name}
	tinsert(db.borders, t)	
	self:CreateBorderFromParams(t)
end

local inc = 0
function mod:CreateBorderFromParams(t)
	inc = inc + 1
	local tex = tremove(texturePool) or Minimap:CreateTexture()
	tex:SetWidth(t.width or defaultSize)
	tex:SetHeight(t.height or defaultSize)
	tex:SetTexture(t.texture)
	tex:SetBlendMode(t.blendMode or "ADD")
	tex:SetVertexColor(t.r or 1, t.g or 1, t.b or 1, t.a or 1)
	tex:SetPoint("CENTER", Minimap, "CENTER", t.hNudge or 0, t.vNudge or 0)
	tex:SetWidth(defaultSize * (t.scale or 1))
	tex:SetHeight(defaultSize * (t.scale or 1))
	tex:SetDrawLayer(t.drawLayer or "ARTWORK")
	
	tex.rotSpeed = t.rotSpeed or 0
	tex.settings = t
	tex:Show()
	if t.disableRotation then
		tex:SetTexCoord(0, 1, 0, 1)
	else
		if t.playerRotation and t.playerRotation ~= "none" then
			rotateTextures[tex] = t.playerRotation
		else
			rotateTextures[tex] = t.rotSpeed ~= 0 and t.rotSpeed or nil
		end
		RotateTexture(tex, t.rotation or 0, true)
	end
	
	local r,g,b,a = t.r or 1, t.g or 1, t.b or 1, t.a or 1
	tex:SetVertexColor(r,g,b,a)
	textures["tex" .. inc] = tex
	
	options.args.borders.args["tex" .. inc] = {
		type = "group",
		name = t.name or ("Border #" .. inc),
		arg = "tex" .. inc,
		args = borderOptions
	}
	return tex
end

function mod:Update()
	if db.hideBlizzard then
		MinimapBorder:Hide()
	else
		MinimapBorder:Show()
	end
end
