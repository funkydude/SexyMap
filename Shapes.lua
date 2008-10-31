local parent = SexyMap
local modName = "Shapes"
local mod = SexyMap:NewModule(modName)
local L = LibStub("AceLocale-3.0"):GetLocale("SexyMap")
local db
local CallbackHandler = LibStub:GetLibrary("CallbackHandler-1.0")
mod.callbacks = CallbackHandler:New(mod)

local keys = {}
local function interpolate(points, angle)
	for i = 1, #keys do tremove(keys) end
	for k, v in pairs(points) do
		tinsert(keys, k)
	end
	table.sort(keys)
	local pre, post = 0, 360
	for _, key in ipairs(keys) do
		if key < angle then
			pre = key
		else
			post = key
			break
		end
	end
	local pct = (angle - pre) / (post - pre)
	local x1, y1 = unpack(points[pre])
	local x2, y2 = unpack(points[post])
	local x, y = x1 + ((x2 - x1) * pct), y1 + ((y2 - y1) * pct)
	return x, y
end

--[[
------------------------------------------------------------------------
  Circle. Easy!
------------------------------------------------------------------------
]]--
local function circle(angle, radius)
	local bx = cos(angle) * radius
	local by = sin(angle) * radius
	return bx, by
end

--[[
------------------------------------------------------------------------
  Square
------------------------------------------------------------------------
]]--
local squarePoints = {	
	  [0] = { 1,  0},
	 [45] = { 1,  1},
	[135] = {-1,  1},
	[225] = {-1, -1},
	[315] = { 1, -1},
	[360] = { 1,  0},	
}
local function square(angle, radius)
	local x,y = interpolate(squarePoints, angle)
	return x * radius, y * radius
end

--[[
------------------------------------------------------------------------
  Diamond
------------------------------------------------------------------------
]]--
local diamondPoints = {
	[0]   = { 1,  0},
	[90]  = { 0,  1},
	[180] = {-1,  0},
	[270] = { 0, -1},
	[360] = { 1,  0}
}
local function diamond(angle, radius)
	local x,y = interpolate(diamondPoints, angle)
	return x * radius, y * radius
end

--[[
------------------------------------------------------------------------
  Master Shapes table
------------------------------------------------------------------------
]]--
local shapes = {
	["Textures\\MinimapMask"] = {
		name = L["Circle"],
		geometry = circle
	},
	["ENVIRONMENTS\\STARS\\Deathsky_Mask"] = {
		name = L["Faded Circle (Small)"],
		geometry = circle
	},
	["Interface\\AddOns\\SexyMap\\shapes\\largecircle"] = {
		name = L["Faded Circle (Large)"],
		geometry = circle
	},
	["Interface\\AddOns\\SexyMap\\shapes\\squareFuzzy"] = {
		name = L["Faded Square"],
		geometry = square
	},
	["Interface\\AddOns\\SexyMap\\shapes\\diamond"] = {
		name = L["Diamond"],
		geometry = diamond
	},
	["Interface\\BUTTONS\\WHITE8X8"] = {
		name = L["Square"],
		geometry = square
	}
}

local defaults = {
	profile = {}
}

local shapeList = {}
for k, v in pairs(shapes) do
	shapeList[k] = v.name
end

local shapeOptions = {
	type = "select",
	name = L["Minimap shape"],
	values = shapeList,
	get = function()
		return db.shape or "Textures\\MinimapMask"
	end,
	set = function(info, v)
		mod:ApplyShape(v)
	end
}

function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
	db = self.db.profile
end

function mod:OnEnable()
	db = self.db.profile
	db.shape = db.shape or parent:GetModule("General").db.profile.shape or "Textures\\MinimapMask"
	self:ApplyShape()
end

function mod:GetPosition(angle, radius)
	if angle < 0 then angle = 360 + angle end
	angle = angle % 360
	local func = shapes[db.shape] and shapes[db.shape].geometry or circle
	return func(angle, radius)
end

function mod:GetShapeOptions()
	return shapeOptions
end

function mod:GetShape()
	return db.shape
end

function mod:ApplyShape(shape)
	if shape or db.shape then
		db.shape = shape or db.shape or "Textures\\MinimapMask"
		Minimap:SetMaskTexture(db.shape)
	end
	self.callbacks:Fire("SexyMap_ShapeChanged")
end
