
local _, addon = ...
local parent = addon.SexyMap
local modName = "Fader"
local mod = addon.SexyMap:NewModule(modName)
local L = addon.L
local db

local options = {
	type = "group",
	name = modName,
	childGroups = "tab",
	disabled = function() return not db.enabled end,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enable fader"],
			desc = L["Enable fader functionality"],
			get = function()
				return db.enabled
			end,
			set = function(info, v)
				db.enabled = v
				if v then
					mod:Enable()
				else
					Minimap:SetAlpha(1)
					mod:Disable()
				end
			end,
			disabled = false,
			order = 1,
			width = "full",
		},
		normalOpacity = {
			type = "range",
			name = L["Normal Opacity"],
			min = 0,
			max = 1,
			step = 0.01,
			isPercent = true,
			get = function()
				return db.normalOpacity
			end,
			set = function(info, v)
				db.normalOpacity = v
				Minimap:SetAlpha(v)
			end,
			order = 2
		},
		hoverOpacity = {
			type = "range",
			name = L["Hover Opacity"],
			min = 0,
			max = 1,
			step = 0.01,
			isPercent = true,
			get = function()
				return db.hoverOpacity
			end,
			set = function(info, v)
				db.hoverOpacity = v
			end,
			order = 3
		},
	}
}

function mod:OnInitialize()
	local defaults = {
		profile = {
			enabled = false,
			hoverOpacity = 0.25,
			normalOpacity = 1
		}
	}
	self.db = parent.db:RegisterNamespace(modName, defaults)
	parent:RegisterModuleOptions(modName, options, modName)
	db = self.db.profile
	self:SetEnabledState(db.enabled)
end

local hooked
function mod:OnEnable()
	db = self.db.profile
	Minimap:SetAlpha(db.normalOpacity)

	if not hooked then
		hooked = true

		local animGroup = Minimap:CreateAnimationGroup()
		local anim = animGroup:CreateAnimation("Alpha")
		animGroup:SetScript("OnFinished", function()
			Minimap:SetAlpha(GetMouseFocus():GetName() == "Minimap" and db.hoverOpacity or db.normalOpacity)
		end)
		anim:SetOrder(1)
		anim:SetDuration(0.5)

		Minimap:HookScript("OnEnter", function()
			if db.enabled then
				animGroup:Stop()
				Minimap:SetAlpha(db.normalOpacity)
				anim:SetChange(db.hoverOpacity-db.normalOpacity)
				animGroup:Play()
			end
		end)
		Minimap:HookScript("OnLeave", function()
			if db.enabled then
				animGroup:Stop()
				Minimap:SetAlpha(db.hoverOpacity)
				anim:SetChange(db.normalOpacity-db.hoverOpacity)
				animGroup:Play()
			end
		end)
	end
end

