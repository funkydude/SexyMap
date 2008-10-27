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

local selectedPreset
local options = {
	type = "group",
	name = "Borders",
	args = {
		new = {
			type = "input",
			name = L["Create new border"],
			set = function(info, v)
				mod:NewBorder(v)
			end
		},
		preset = {
			type = "select",
			name = "Preset",
			confirm = true,
			confirmText = "This will wipe out any current settings!",
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

local deleteOffset = 0

local function getTextureAndDB(info)
	local index = info.options.args[info[1]].args[info[2]].args[info[3]].arg
	return textures[index], db.borders[index - deleteOffset]
end

local borderOptions = {
	texture = {
		type = "input",
		name = "Texture path",
		get = function(info)
			local tex, settings = getTextureAndDB(info)
			return settings.texture
		end,
		set = function(info, v)
			local tex, settings = getTextureAndDB(info)
			settings.texture = v
			tex:SetTexture(v)
		end
	},
	name = {
		type = "input",
		name = "Name",
		get = function(info)
			return info.options.args[info[1]].args[info[2]].args[info[3]].name
		end,
		set = function(info, name)
			info.options.args[info[1]].args[info[2]].args[info[3]].name = name
			local tex, settings = getTextureAndDB(info)
			settings.name = name
		end
	},
	delete = {
		type = "execute",
		name = "Delete",
		confirm = true,
		func = function(info)
			local index = info.options.args[info[1]].args[info[2]].args[info[3]].arg
			tremove(db.borders, index)
			deleteOffset = deleteOffset + 1
			info.options.args[info[1]].args[info[2]].args["border" .. index] = nil
			rotateTextures[textures[index]] = nil
			textures[index]:Hide()
		end
	},
	scale = {
		type = "range",
		name = L["Scale"],
		min = 0.2,
		max = 3.0,
		step = 0.1,
		bigStep = 0.1,
		get = function(info)
			local tex, settings = getTextureAndDB(info)
			return settings.scale or 1
		end,
		set = function(info, v)
			local tex, settings = getTextureAndDB(info)
			settings.scale = v
			tex:SetWidth(defaultSize * v)
			tex:SetHeight(defaultSize * v)
		end
	},
	rotation = {
		type = "range",
		name = L["Rotation Speed"],
		min = -120,
		max = 120,
		step = 1,
		bigStep = 2,
		get = function(info)
			local tex, settings = getTextureAndDB(info)
			return settings.rotSpeed or 0
		end,
		set = function(info, v)
			local tex, settings = getTextureAndDB(info)
			settings.rotSpeed = v
			tex.rotSpeed = v
			rotateTextures[tex] = v ~= 0 and v or nil
		end
	},
	color = {
		type = "color",
		name = L["Color"],
		hasAlpha = true,
		get = function(info)
			local tex, settings = getTextureAndDB(info)
			return settings.r or 1, settings.g or 1, settings.b or 1, settings.a or 1
		end,
		set = function(info, r, g, b, a)
			local tex, settings = getTextureAndDB(info)
			settings.r, settings.g, settings.b, settings. a = r, g, b, a
			tex:SetVertexColor(r,g,b,a)
		end
	}
}

local defaults = {
	profile = {
		hideBlizzard = true,
		borders = {},
		userPresets = {},
		defaultPreset = "Blue Runes"
	}
}

local function RotateTexture(self, inc)
	self.hAngle = (self.hAngle or 0) - inc;
	local s = sin(self.hAngle);
	local c = cos(self.hAngle);
	
	self:SetTexCoord(
		0.5 - s, 0.5 + c,
		0.5 + c, 0.5 + s,
		0.5 - c, 0.5 - s,
		0.5 + s, 0.5 - c
	)
end

function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
	db = self.db.profile
	parent:RegisterModuleOptions(modName, options, modName)

	if db.defaultPreset then
		self:ApplyPreset(db.defaultPreset)
		db.defaultPreset = nil
	else
		for _, v in ipairs(db.borders) do
			self:CreateBorderFromParams(v)
		end
	end
end

local function updateRotations(self, t)
	for k, v in pairs(rotateTextures) do
		RotateTexture(k, v * t)
	end
end

function mod:OnEnable()
	self:Update()
	rotFrame:SetScript("OnUpdate", updateRotations)
end

function mod:ApplyPreset(preset)
	local preset = parent.borderPresets[preset]
	db.borders = deepCopyHash(preset)
	options.args.borders.args = {}		-- leaky
	for i = 1, #textures do
		tinsert(texturePool, tremove(textures))
	end
	deleteOffset = 0
	for k, v in pairs(rotateTextures) do
		rotateTextures[k] = nil
	end
	
	for _, v in ipairs(db.borders) do
		self:CreateBorderFromParams(v)
	end
end

function mod:NewBorder(name)
	parent:Print("New border:", name)
	local t = {name = name}
	tinsert(db.borders, t)	
	self:CreateBorderFromParams(t)
end

function mod:CreateBorderFromParams(t)
	local tex = tremove(texturePool) or Minimap:CreateTexture()
	tex:SetWidth(t.width or defaultSize)
	tex:SetHeight(t.height or defaultSize)
	tex:SetTexture(t.texture)
	tex:SetBlendMode(t.mode or "ADD")
	tex:SetVertexColor(t.r or 1, t.g or 1, t.b or 1, t.a or 1)
	tex:SetPoint("CENTER", Minimap, "CENTER")
	tex:SetWidth(defaultSize * (t.scale or 1))
	tex:SetHeight(defaultSize * (t.scale or 1))
	tex.rotSpeed = t.rotSpeed or 0
	rotateTextures[tex] = t.rotSpeed ~= 0 and t.rotSpeed or nil
	RotateTexture(tex, 0)
	
	local r,g,b,a = t.r or 1, t.g or 1, t.b or 1, t.a or 1
	tex:SetVertexColor(r,g,b,a)
	
	tinsert(textures, tex)
	
	options.args.borders.args["border" .. #textures] = {
		type = "group",
		name = t.name or ("Border #" .. #textures),
		arg = #textures,
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
