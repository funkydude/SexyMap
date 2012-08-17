
local _, addon = ...
local parent = addon.SexyMap
local mod = addon.SexyMap:NewModule("General")
local L = addon.L

local db
local options = {
	type = "group",
	name = "General",
	args = {
		lock = {
			order = 1,
			name = L["Lock minimap"],
			type = "toggle",
			get = function()
				return db.lock
			end,
			set = function(info, v)
				db.lock = v
				Minimap:SetMovable(not db.lock)
			end,
		},
		clamp = {
			order = 2,
			type = "toggle",
			name = L["Clamp to screen"],
			get = function()
				return db.clamp
			end,
			set = function(info, v)
				db.clamp = v
				Minimap:SetClampedToScreen(v)
			end,
		},
		rightClickToConfig = {
			order = 3,
			type = "toggle",
			name = L["Right click map to configure"],
			width = "full",
			get = function()
				return db.rightClickToConfig
			end,
			set = function(info, v)
				db.rightClickToConfig = v
			end,
		},
		scale = {
			order = 4,
			type = "range",
			name = L["Scale"],
			min = 0.2,
			max = 3.0,
			step = 0.01,
			bigStep = 0.01,
			width = "double",
			get = function(info)
				return db.scale or 1
			end,
			set = function(info, v)
				db.scale = v
				mod:Update()
			end,
		},
		zoomSpacer = {
			order = 5,
			type = "header",
			name = "",
		},
		zoom = {
			order = 6,
			type = "range",
			name = L["Autozoom out after..."],
			desc = L["Number of seconds to autozoom out after. Set to 0 to turn off Autozoom."],
			min = 0,
			width = "full",
			max = 60,
			step = 1,
			bigStep = 1,
			get = function()
				return mod.db.profile.autoZoom
			end,
			set = function(info, v)
				mod.db.profile.autoZoom = v
			end,
		},
		spacer = {
			order = 7,
			type = "header",
			name = "",
		},
	}
}

mod.options = options

function mod:OnInitialize()
	local defaults = {
		profile = {
			lock = true,
			clamp = true,
			rightClickToConfig = true,
			autoZoom = 5,
		}
	}
	self.db = parent.db:RegisterNamespace("General", defaults)
	db = self.db.profile
	parent:RegisterModuleOptions("General", options, "General")

	local Minimap = Minimap

	--[[ Auto Zoom Out ]]--
	local animGroup = Minimap:CreateAnimationGroup()
	local anim = animGroup:CreateAnimation()
	animGroup:SetScript("OnFinished", function()
		for i = 1, 5 do
			MinimapZoomOut:Click()
		end
	end)
	anim:SetOrder(1)
	anim:SetDuration(1)

	--[[ MouseWheel Zoom ]]--
	Minimap:EnableMouseWheel(true)
	Minimap:SetScript("OnMouseWheel", function(frame, d)
		if d > 0 then
			MinimapZoomIn:Click()
		elseif d < 0 then
			MinimapZoomOut:Click()
		end
		if mod.db.profile.autoZoom > 0 then
			animGroup:Stop()
			anim:SetDuration(mod.db.profile.autoZoom)
			animGroup:Play()
		end
	end)
	if self.db.profile.autoZoom > 0 then
		animGroup:Play()
	end

	MinimapCluster:EnableMouse(false)

	MinimapBorderTop:Hide()
	Minimap:RegisterForDrag("LeftButton")
	Minimap:SetClampedToScreen(db.clamp)
	Minimap:SetScale(db.scale or 1)
	Minimap:SetMovable(not db.lock)

	Minimap:SetScript("OnDragStart", function(self) if self:IsMovable() then self:StartMoving() end end)
	Minimap:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local p, _, rp, x, y = Minimap:GetPoint()
		db.point, db.relpoint, db.x, db.y = p, rp, x, y
	end)

	if db.point then
		Minimap:SetPoint(db.point, nil, db.relpoint, db.x, db.y)
	end
end

function mod:OnEnable()
	db = self.db.profile
end

