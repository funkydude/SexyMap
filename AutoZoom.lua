
local _, addon = ...
local parent = addon.SexyMap
local modName = "AutoZoom"
local mod = addon.SexyMap:NewModule(modName, "AceTimer-3.0")
local L = addon.L

local options = {
	type = "group",
	name = modName,
	args = {
		show = {
			type = "range",
			name = L["Autozoom out after..."],
			desc = L["Number of seconds to autozoom out after. Set to 0 to turn off Autozoom."],
			min = 0,
			width = "double",
			max = 60,
			step = 1,
			bigStep = 1,
			get = function()
				return mod.db.profile.autoZoom
			end,
			set = function(info, v)
				mod.db.profile.autoZoom = v
			end
		}
	}
}

local defaults = {
	profile = { autoZoom = 5 }
}
function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
	parent:RegisterModuleOptions(modName, options, modName)
end

-- This module should be merged into the core as it really doesn't qualify to be a separate module
local timerHandle = nil
function mod:OnEnable()
	Minimap:EnableMouseWheel(true)
	Minimap:SetScript("OnMouseWheel", function(frame, d)
		if d > 0 then
			MinimapZoomIn:Click()
		elseif d < 0 then
			MinimapZoomOut:Click()
		end
		if mod.db.profile.autoZoom > 0 then
			if timerHandle then
				mod:CancelTimer(timerHandle, true)
			end
			timerHandle = mod:ScheduleTimer("ZoomOut", mod.db.profile.autoZoom)
		end
	end)
	if mod.db.profile.autoZoom > 0 then
		self:ZoomOut()
	end
end

function mod:ZoomOut()
	timerHandle = nil
	for i = 1, 5 do
		MinimapZoomOut:Click()
	end
end

