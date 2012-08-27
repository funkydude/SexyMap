
local _, sm = ...
sm.Fader = {}

local parent = sm.Core
local mod = sm.Fader
local L = sm.L
local db

local options = {
	type = "group",
	name = L["Fader"],
	childGroups = "tab",
	disabled = function() return not db.enabled end,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enable Minimap Fader"],
			get = function()
				return db.enabled
			end,
			set = function(info, v)
				db.enabled = v
				if v then
					Minimap:SetAlpha(db.normalOpacity)
				else
					Minimap:SetAlpha(1)
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

function mod:OnEnable()
	local defaults = {
		profile = {
			enabled = false,
			hoverOpacity = 0.25,
			normalOpacity = 1
		}
	}
	self.db = parent.db:RegisterNamespace("Fader", defaults)
	parent:RegisterModuleOptions("Fader", options, L["Fader"])
	db = self.db.profile

	if db.enabled then
		Minimap:SetAlpha(db.normalOpacity)
	end
end

do
	local animGroup = Minimap:CreateAnimationGroup()
	local anim = animGroup:CreateAnimation("Alpha")
	animGroup:SetScript("OnFinished", function()
		-- Minimap or Minimap icons including nil checks to compensate for other addons
		local focus = GetMouseFocus()
		if focus and ((focus:GetName() == "Minimap") or (focus:GetParent() and focus:GetParent():GetName() and focus:GetParent():GetName():find("Mini[Mm]ap"))) then
			Minimap:SetAlpha(db.hoverOpacity)
		else
			Minimap:SetAlpha(db.normalOpacity)
		end
	end)
	anim:SetOrder(1)
	anim:SetDuration(0.5)

	local fadeStop -- Use a variable to prevent fadeout/in when moving the mouse around minimap/icons

	local OnEnter = function()
		if db.enabled then
			if fadeStop then return end

			animGroup:Stop()
			Minimap:SetAlpha(db.normalOpacity)
			anim:SetChange(db.hoverOpacity-db.normalOpacity)
			animGroup:Play()
		end
	end
	local OnLeave = function()
		if db.enabled then
			local focus = GetMouseFocus() -- Minimap or Minimap icons including nil checks to compensate for other addons
			if focus and ((focus:GetName() == "Minimap") or (focus:GetParent() and focus:GetParent():GetName() and focus:GetParent():GetName():find("Mini[Mm]ap"))) then
				fadeStop = true
				return
			end
			fadeStop = nil

			animGroup:Stop()
			Minimap:SetAlpha(db.hoverOpacity)
			anim:SetChange(db.normalOpacity-db.hoverOpacity)
			animGroup:Play()
		end
	end

	function mod:SexyMap_NewFrame(_, f)
		f:HookScript("OnEnter", OnEnter)
		f:HookScript("OnLeave", OnLeave)
	end
end

parent.RegisterCallback(mod, "SexyMap_NewFrame")

