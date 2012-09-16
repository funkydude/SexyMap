
local _, sm = ...
sm.fader = {}

local mod = sm.fader
local L = sm.L

local options = {
	type = "group",
	name = L["Fader"],
	childGroups = "tab",
	disabled = function() return not mod.db.enabled end,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enable Minimap Fader"],
			get = function()
				return mod.db.enabled
			end,
			set = function(info, v)
				mod.db.enabled = v
				if v then
					Minimap:SetAlpha(mod.db.normalOpacity)
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
				return mod.db.normalOpacity
			end,
			set = function(info, v)
				mod.db.normalOpacity = v
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
				return mod.db.hoverOpacity
			end,
			set = function(info, v)
				mod.db.hoverOpacity = v
			end,
			order = 3
		},
	}
}

function mod:OnInitialize(profile)
	if type(profile.fader) ~= "table" then
		profile.fader = {
			enabled = false,
			hoverOpacity = 0.25,
			normalOpacity = 1
		}
	end
	self.db = profile.fader
end

function mod:OnEnable()
	sm.core:RegisterModuleOptions("Fader", options, L["Fader"])

	if mod.db.enabled then
		Minimap:SetAlpha(mod.db.normalOpacity)
	end
end

do
	local animGroup = Minimap:CreateAnimationGroup()
	local anim = animGroup:CreateAnimation("Alpha")
	animGroup:SetScript("OnFinished", function()
		-- Minimap or Minimap icons including nil checks to compensate for other addons
		local focus = GetMouseFocus()
		if focus and ((focus:GetName() == "Minimap" or focus:GetName() == "AtlasButton" or focus:GetName() == "HealBot_MMButton") or (focus:GetParent() and focus:GetParent():GetName() and focus:GetParent():GetName():find("Mini[Mm]ap"))) then
			Minimap:SetAlpha(mod.db.hoverOpacity)
		else
			Minimap:SetAlpha(mod.db.normalOpacity)
		end
	end)
	anim:SetOrder(1)
	anim:SetDuration(0.3)

	local fadeStop -- Use a variable to prevent fadeout/in when moving the mouse around minimap/icons

	local OnEnter = function()
		if mod.db.enabled then
			if fadeStop then return end

			local delayed = anim:IsDelaying()
			animGroup:Stop()
			if not delayed then
				Minimap:SetAlpha(mod.db.normalOpacity)
				anim:SetStartDelay(0)
				anim:SetChange(mod.db.hoverOpacity-mod.db.normalOpacity)
				animGroup:Play()
			end
		end
	end
	local OnLeave = function()
		if mod.db.enabled then
			local focus = GetMouseFocus() -- Minimap or Minimap icons including nil checks to compensate for other addons
			if focus and ((focus:GetName() == "Minimap" or focus:GetName() == "AtlasButton" or focus:GetName() == "HealBot_MMButton") or (focus:GetParent() and focus:GetParent():GetName() and focus:GetParent():GetName():find("Mini[Mm]ap"))) then
				fadeStop = true
				return
			end
			fadeStop = nil

			animGroup:Stop()
			Minimap:SetAlpha(mod.db.hoverOpacity)
			anim:SetStartDelay(0.5)
			anim:SetChange(mod.db.normalOpacity-mod.db.hoverOpacity)
			animGroup:Play()
		end
	end

	function mod:NewFrame(f)
		f:HookScript("OnEnter", OnEnter)
		f:HookScript("OnLeave", OnLeave)
	end
end

