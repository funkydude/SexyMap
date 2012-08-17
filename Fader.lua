
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

do
	local animGroup = Minimap:CreateAnimationGroup()
	local anim = animGroup:CreateAnimation("Alpha")
	animGroup:SetScript("OnFinished", function()
		local focus = GetMouseFocus() and GetMouseFocus():GetParent()
		-- Minimap or Minimap icons
		if focus and focus:GetName():find("Mini[Mm]ap") then
			Minimap:SetAlpha(db.hoverOpacity)
		else
			Minimap:SetAlpha(db.normalOpacity)
		end
	end)
	anim:SetOrder(1)
	anim:SetDuration(0.5)

	local OnEnter, OnLeave
	-- Function for hooking the Minimap/Icon's OnEnter/OnLeave
	local hooked = {}
	local hookIcons = function(...)
		for i=1, select("#", ...) do
			local f = select(i, ...)
			if not hooked[f:GetName()] then
				hooked[f:GetName()] = true
				f:HookScript("OnEnter", OnEnter)
				f:HookScript("OnLeave", OnLeave)
			end
		end
	end

	local fadeStop -- Use a variable to prevent fadeout/in when moving the mouse around minimap/icons

	OnEnter = function(f)
		if fadeStop then return end
		if db.enabled then
			animGroup:Stop()
			anim:SetChange(db.hoverOpacity-db.normalOpacity)
			animGroup:Play()
		end
		hookIcons(Minimap:GetChildren()) -- Instead of using a timer to periodically hook new icons
	end
	OnLeave = function(f)
		local focus = GetMouseFocus() and GetMouseFocus():GetParent()
		if focus and focus:GetName():find("Mini[Mm]ap") then
			fadeStop = true
			return
		end
		fadeStop = nil
		if db.enabled then
			animGroup:Stop()
			anim:SetChange(db.normalOpacity-db.hoverOpacity)
			animGroup:Play()
		end
	end

	function mod:OnEnable()
		db = self.db.profile
		Minimap:SetAlpha(db.normalOpacity)

		hookIcons(MinimapCluster:GetChildren()) -- Minimap & Icons
		hookIcons(Minimap:GetChildren()) -- Minimap Icons
		hookIcons(MinimapBackdrop:GetChildren()) -- More Icons
	end
end

