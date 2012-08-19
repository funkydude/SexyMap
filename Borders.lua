
local _, addon = ...
local parent = addon.SexyMap
local modName = "Borders"
local mod = addon.SexyMap:NewModule(modName)
local L = addon.L
local db
local textures = {}
local texturePool = {}
local rotateTextures = {}
local defaultSize = 180
local customBackdrop
local media = LibStub("LibSharedMedia-3.0")
local Shape

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

local Minimap, MinimapCluster, MinimapBorder = Minimap, MinimapCluster, MinimapBorder

local presets, userPresets = {}, {}

local function deepCopyHash(t)
	if t == nil then return nil end
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

local function RotateTexture(self, inc, set)
	if type(inc) == "string" then
		local bearing = GetPlayerFacing()
		if inc == "normal" then
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
	name = L["Borders"],
	childGroups = "tab",
	args = {
		hideBlizzard = {
			type = "toggle",
			name = L["Hide default border"],
			desc = L["Hide the default border on the minimap."],
			get = function() return db.hideBlizzard end,
			set = function(info, v) db.hideBlizzard = v; mod:UpdateBorder() end,
		},
		currentGroup = {
			type = "group",
			name = L["Current Borders"],
			args = {
				shape = parent:GetModule("Shapes"):GetShapeOptions(),
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
				clear = {
					name = L["Clear & start over"],
					desc = L["Clear the current borders and start fresh"],
					order = 3,
					type = "execute",
					func = function()
						mod:Clear()
					end
				},
				borders = {
					name = L["Borders"],
					type = "group",
					args = {
						default = {
							type = "group",
							name = L["Background/edge"],
							args = {
								explain = {
									type = "description",
									name = L["You can set a background and edge file for the minimap like you would with any frame. This is useful when you want to create static square backdrops for your minimap."]
								},
								show = {
									type = "toggle",
									name = L["Enable"],
									order = 2,
									desc = L["Enable a backdrop and border for the minimap. This will let you set square borders more easily."],
									get = function()
										return db.backdrop.show
									end,
									set = function(info, v)
										db.backdrop.show = v
										mod:UpdateBackdrop()
									end
								},
								scale = {
									type = "range",
									name = L["Scale"],
									order = 3,
									min = 0.5,
									max = 5,
									step = 0.01,
									bigStep = 0.01,
									width = "full",
									disabled = function()
										return not db.backdrop.show
									end,
									get = function()
										return db.backdrop.scale or 1
									end,
									set = function(info, v)
										db.backdrop.scale = v
										mod:UpdateBackdrop()
									end
								},
								alpha = {
									type = "range",
									name = L["Opacity"],
									order = 4,
									min = 0,
									max = 1,
									step = 0.05,
									bigStep = 0.05,
									width = "full",
									disabled = function()
										return not db.backdrop.show
									end,
									get = function()
										return db.backdrop.alpha or 1
									end,
									set = function(info, v)
										db.backdrop.alpha = v
										mod:UpdateBackdrop()
									end
								},
								texture = {
									type = "group",
									name = L["Background Texture"],
									disabled = function()
										return not db.backdrop.show
									end,
									args = {
										texture = {
											type = "input",
											name = L["Texture"],
											order = 10,
											width = "double",
											get = function()
												return db.backdrop.settings.bgFile
											end,
											set = function(info, v)
												db.backdrop.settings.bgFile = v
												mod:UpdateBackdrop()
											end
										},
										openTexBrowser = {
											type = "execute",
											name = function()
												if select(2, GetAddOnInfo("TexBrowser")) then
													return L["Open TexBrowser"]
												else
													return L["TexBrowser Not Installed"]
												end
											end,
											order = 11,
											func = function()
												if not IsAddOnLoaded("TexBrowser") then
													EnableAddOn("TexBrowser")
													LoadAddOn("TexBrowser")
												end
												TexBrowser:OnEnable()
											end,
											disabled = function()
												return not select(2, GetAddOnInfo("TexBrowser"))
											end
										},
										textureSelect = {
											type = "select",
											name = L["SharedMedia Texture"],
											order = 12,
											width = "full",
											dialogControl = 'LSM30_Background',
											values = AceGUIWidgetLSMlists.background,
											get = function()
												return db.backdrop.settings.bgFile
											end,
											set = function(info, v)
												db.backdrop.settings.bgFile = media:Fetch("background", v)
												mod:UpdateBackdrop()
											end
										},
										tile = {
											type = "toggle",
											name = L["Tile background"],
											order = 13,
											get = function()
												return db.backdrop.settings.tile
											end,
											set = function(info, v)
												db.backdrop.settings.tile = v
												mod:UpdateBackdrop()
											end
										},
										tileSize = {
											type = "range",
											name = L["Tile size"],
											order = 14,
											min = 0,
											max = 500,
											step = 1,
											bigStep = 1,
											width = "full",
											disabled = function()
												return not db.backdrop.settings.tile
											end,
											get = function()
												return db.backdrop.settings.tileSize
											end,
											set = function(info, v)
												db.backdrop.settings.tileSize = v
												mod:UpdateBackdrop()
											end
										},
										textureColor = {
											type = "color",
											name = L["Backdrop color"],
											order = 13,
											hasAlpha = true,
											get = function()
												local c = db.backdrop.textureColor
												local r, g, b, a = c.r or 0, c.g or 0, c.b or 0, c.a or 1
												return r, g, b, a
											end,
											set = function(info, r, g, b, a)
												local c = db.backdrop.textureColor
												c.r, c.g, c.b, c.a = r, g, b, a
												mod:UpdateBackdrop()
											end
										},
										inset = {
											type = "range",
											name = L["Backdrop insets"],
											order = 15,
											min = 0,
											max = 20,
											step = 1,
											bigStep = 1,
											width = "double",
											get = function()
												return db.backdrop.settings.insets.left
											end,
											set = function(info, v)
												db.backdrop.settings.insets.left = v
												db.backdrop.settings.insets.top = v
												db.backdrop.settings.insets.bottom = v
												db.backdrop.settings.insets.right = v
												mod:UpdateBackdrop()
											end
										},
									}
								},
								border = {
									type = "group",
									name = L["Border Texture"],
									disabled = function()
										return not db.backdrop.show
									end,
									args = {
										border = {
											type = "input",
											name = L["Border texture"],
											order = 20,
											width = "full",
											get = function()
												return db.backdrop.settings.edgeFile
											end,
											set = function(info, v)
												db.backdrop.settings.edgeFile = v
												mod:UpdateBackdrop()
											end
										},
										openTexBrowser = {
											type = "execute",
											name = function()
												if select(2, GetAddOnInfo("TexBrowser")) then
													return L["Open TexBrowser"]
												else
													return L["TexBrowser Not Installed"]
												end
											end,
											order = 21,
											func = function()
												if not IsAddOnLoaded("TexBrowser") then
													EnableAddOn("TexBrowser")
													LoadAddOn("TexBrowser")
												end
												TexBrowser:OnEnable()
											end,
											disabled = function()
												return not select(2, GetAddOnInfo("TexBrowser"))
											end
										},
										textureSelect = {
											type = "select",
											name = L["SharedMedia Border"],
											order = 22,
											width = "full",
											dialogControl = 'LSM30_Border',
											values = AceGUIWidgetLSMlists.border,
											get = function()
												return db.backdrop.settings.edgeFile
											end,
											set = function(info, v)
												db.backdrop.settings.edgeFile = media:Fetch("border", v)
												mod:UpdateBackdrop()
											end
										},
										borderColor = {
											type = "color",
											order = 23,
											name = L["Border color"],
											hasAlpha = true,
											get = function()
												local c = db.backdrop.borderColor
												local r, g, b, a = c.r or 0, c.g or 0, c.b or 0, c.a or 1
												return r, g, b, a
											end,
											set = function(info, r, g, b, a)
												local c = db.backdrop.borderColor
												c.r, c.g, c.b, c.a = r, g, b, a
												mod:UpdateBackdrop()
											end
										},
										edgeSize = {
											type = "range",
											name = L["Border edge size"],
											order = 25,
											min = 6,
											max = 48,
											step = 1,
											bigStep = 1,
											width = "double",
											get = function()
												return db.backdrop.settings.edgeSize
											end,
											set = function(info, v)
												db.backdrop.settings.edgeSize = v
												mod:UpdateBackdrop()
											end
										},
									}
								}
							}
						}
					}
				}
			}
		},
		presets = {
			type = "group",
			name = L["Preset"],
			args = {
				saveas = {
					name = L["Save current settings as preset..."],
					order = 1,
					type = "input",
					width = "full",
					get = function() return "" end,
					set = function(info, v)
						mod:SavePresetAs(v)
					end
				},
				preset = {
					type = "select",
					name = L["Select preset to load"],
					desc = L["Select a preset to load settings from. This will erase any of your current borders."],
					order = 2,
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
				delete = {
					name = L["Delete"],
					type = "select",
					confirm = true,
					order = 3,
					disabled = function()
						for k, v in pairs(userPresets) do
							return false
						end
						return true
					end,
					confirmText = L["Really delete this preset? This can't be undone."],
					values = userPresets,
					get = function(info, v)
						return nil
					end,
					set = function(info, v)
						mod.db.global.userPresets[v] = nil
					end
				},
			}
		}
	}
}

local function getLeaf(info)
	return info.options.args[info[1]].args[info[2]].args[info[3]]
end

local function getTextureAndDB(info)
	local key = getLeaf(info).arg
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
			return getLeaf(info).name
		end,
		set = function(info, name)
			getLeaf(info).name = name
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
			local index = getLeaf(info).arg
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
			if select(2, GetAddOnInfo("TexBrowser")) then
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
			return not select(2, GetAddOnInfo("TexBrowser"))
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
		order = 116,
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
		name = L["Rotation Speed (seconds)"],
		desc = L["The time it takes (in seconds) to complete one rotation. A setting of 0 turns off rotation."],
		min = -300,
		max = 300,
		step = 1,
		bigStep = 1,
		order = 114,
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
			if v == 0 then
				local getAnim = tex:GetAnimationGroups()
				if getAnim then
					getAnim:Stop()
				end
				rotateTextures[tex] = nil
			else
				rotateTextures[tex] = v
				mod:StartRotations()
			end
		end
	},
	staticRotation = {
		type = "range",
		name = L["Static Rotation"],
		desc = L["A static amount to rotate the texture by."],
		min = 0,
		max = 360,
		order = 115,
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
	--[[playerRotation = {
		type = "multiselect",
		name = L["Match player rotation"],
		values = {
			normal = L["Normal rotation"],
			reverse = L["Reverse rotation"],
			none = L["Do not match player rotation"],
		},
		order = 113,
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
	},]]
	color = {
		type = "color",
		name = L["Texture tint"],
		order = 109,
		width = "full",
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
			tex:SetPoint("CENTER", Minimap, "CENTER", tex.settings.hNudge or 0, tex.settings.vNudge or 0)
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
			tex:SetPoint("CENTER", Minimap, "CENTER", tex.settings.hNudge or 0, tex.settings.vNudge or 0)
		end
	},
	layer = {
		type = "select",
		name = L["Layer"],
		values = layers,
		order = 110,
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
		order = 111,
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
		width = "full",
		order = 112,
		set = function(info, v)
			local tex = getTextureAndDB(info)
			tex.settings.disableRotation = v
			RotateTexture(tex, tex.settings.rotation or 0, true)
			local getAnim = tex:GetAnimationGroups()
			if v then
				if getAnim then
					getAnim:Stop()
				end
				rotateTextures[tex] = nil
			else
				if getAnim then
					getAnim:Play()
				end
				rotateTextures[tex] = tex.settings.rotSpeed
			end
		end
	}
}

local defaults = {
	global = {
		userPresets = {},
	},
	profile = {
		hideBlizzard = true,
		borders = {},
		applyPreset = "Blue Rune Circles",
		backdrop = {
			scale = 1,
			show = false,
			textureColor = {},
			borderColor = {},
			settings = {
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				insets = {left = 4, top = 4, right = 4, bottom = 4},
				edgeSize = 16,
				tile = false
			}
		}
	}
}

function mod:OnInitialize()
	Shape = parent:GetModule("Shapes")

	self.db = parent.db:RegisterNamespace(modName, defaults)
	db = self.db.profile
	parent:RegisterModuleOptions(modName, options, modName)
	local args = parent:GetModule("General").options.args
	args.presets = deepCopyHash(options.args.presets.args.preset)
	if args.presets then
		args.presets.order = 110
		args.presets.width = nil
		args.presets.values = presets
	end

	customBackdrop = CreateFrame("Frame", "SexyMapCustomBackdrop", Minimap)
	customBackdrop:SetFrameStrata("BACKGROUND")
	customBackdrop:SetFrameLevel(customBackdrop:GetFrameLevel() - 1)
	customBackdrop:SetPoint("CENTER")
	customBackdrop:SetWidth(Minimap:GetWidth())
	customBackdrop:SetHeight(Minimap:GetHeight())
end

function mod:OnEnable()
	db = self.db.profile

	self:RebuildPresets()

	if db.applyPreset then
		self:ApplyPreset(db.applyPreset)
		db.applyPreset = false
	else
		self:ApplySettings()
	end

end

function mod:OnDisable()
	self:ClearWidgets()
end

function mod:RebuildPresets()
	for k, v in pairs(self.db.global.userPresets) do
		userPresets[k] = k
		presets[k] = k
	end
	for k, v in pairs(parent.borderPresets) do
		presets[k] = k
	end
end

function mod:Clear()
	db.shape = "Textures\\MinimapMask"
	db.borders = {}	-- leaky
	db.backdrop = deepCopyHash(defaults.profile.backdrop)	-- leaky
	return self:ApplySettings()
end

function mod:ApplyPreset(preset)
	local preset = self.db.global.userPresets[preset] or parent.borderPresets[preset]

	db.borders = deepCopyHash(preset.borders)
	db.backdrop = preset.backdrop and deepCopyHash(preset.backdrop) or deepCopyHash(defaults.profile.backdrop)
	db.shape = preset.shape

	return self:ApplySettings()
end

function mod:NewBorder(name)
	local t = {name = name}
	tinsert(db.borders, t)
	self:CreateBorderFromParams(t)
end

function mod:SavePresetAs(name)
	self.db.global.userPresets[name] = {
		borders = deepCopyHash(db.borders),
		backdrop = deepCopyHash(db.backdrop),
		shape = Shape:GetShape()
	}
	self:RebuildPresets()
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

	options.args.currentGroup.args.borders.args["tex" .. inc] = {
		type = "group",
		name = t.name or ("Border #" .. inc),
		arg = "tex" .. inc,
		args = borderOptions
	}
	return tex
end

function mod:ClearWidgets()
	for k, v in pairs(options.args.currentGroup.args.borders.args) do
		if k ~= "default" then
			-- Leaky, but we don't care too much
			options.args.currentGroup.args.borders.args[k] = nil
		end
	end
	for k, v in pairs(textures) do
		tinsert(texturePool, v)
		v:Hide()
		textures[k] = nil
	end
	for k, v in pairs(rotateTextures) do
		local getAnim = k:GetAnimationGroups()
		if getAnim then
			getAnim:Stop()
		end
		rotateTextures[k] = nil
	end
end

function mod:StartRotations()
	if next(rotateTextures) then
		for k, v in pairs(rotateTextures) do
			if type(v) == "number" then
				local getAnim = k:GetAnimationGroups()
				if getAnim then
					getAnim:Stop()
					local anim = getAnim:GetAnimations()
					if v > 0 then
						anim:SetDegrees(-360)
						anim:SetDuration(v)
						getAnim:Play()
					elseif v < 0 then
						anim:SetDegrees(360)
						anim:SetDuration(-v)
						getAnim:Play()
					end
				else
					local animgroup = k:CreateAnimationGroup()
					local anim = animgroup:CreateAnimation("Rotation")
					anim:SetOrder(1)
					animgroup:SetLooping("REPEAT")
					if v > 0 then
						anim:SetDegrees(-360)
						anim:SetDuration(v)
						animgroup:Play()
					elseif v < 0 then
						anim:SetDegrees(360)
						anim:SetDuration(-v)
						animgroup:Play()
					end
				end
			end
		end
	end
end

function mod:ApplySettings()
	self:ClearWidgets()

	if db.shape then
		Shape:ApplyShape(db.shape)
	end

	for _, v in ipairs(db.borders) do
		self:CreateBorderFromParams(v)
	end

	self:StartRotations()

	self:UpdateBorder()
	self:UpdateBackdrop()
end

function mod:UpdateBorder()
	if db.hideBlizzard then
		MinimapBorder:Hide()
	else
		MinimapBorder:Show()
	end
end

function mod:UpdateBackdrop()
	if db.backdrop.show then
		customBackdrop:Show()
		customBackdrop:SetFrameStrata("BACKGROUND")
		customBackdrop:SetScale(db.backdrop.scale or 1)
		customBackdrop:SetAlpha(db.backdrop.alpha or 1)
		customBackdrop:SetBackdrop(db.backdrop.settings)
		local t = db.backdrop.textureColor
		customBackdrop:SetBackdropColor(t.r or 0, t.g or 0, t.b or 0, t.a or 1)
		t = db.backdrop.borderColor
		customBackdrop:SetBackdropBorderColor(t.r or 1, t.g or 1, t.b or 1, t.a or 1)
	else
		customBackdrop:Hide()
	end
end

