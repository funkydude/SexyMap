
local _, addon = ...
local parent = addon.SexyMap
local modName = "Buttons"
local mod = addon.SexyMap:NewModule(modName)
local L = addon.L
local Shape
local db

local animFrames = {}
local blizzButtons = {
	GameTimeFrame = L["Calendar"],
	MiniMapTracking = L["Tracking Button"],
	MinimapZoneTextButton = "zone text",
	MinimapZoomIn = "zoom in",
	MinimapZoomOut = "zoom out",
	MiniMapWorldMapButton = L["Map Button"],
	TimeManagerClockButton = L["Clock"],
}
local dynamicButtons = {
	GuildInstanceDifficulty = "guild dungeon difficulty (when available)",
	MiniMapChallengeMode = "challenge mode (when available)",
	MiniMapInstanceDifficulty = "Dungeon difficulty (when available)",
	MiniMapMailFrame = "new mail indicator (when available)",
	MiniMapRecordingButton = "video record (when available, Mac OSX only)",
	MiniMapVoiceChatFrame = "voice chat (when available)",
	QueueStatusMinimapButton = "queue status (when available)",
	MiniMapLFGFrame = "LFG (when available)", -- XXX mop temp
	MiniMapBattlefieldFrame = "PVP (when available)", -- XXX mop temp
}

--[[
local buttons
local allChildren = {}
local ignoreButtons = {MinimapPing = true}

local function concatChildren(t, ...)
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if not ignoreButtons[v] then
			tinsert(t, v)
		end
	end
end

local lastChildCount = 0
local lastChild = nil
local function getChildren()
	local total = Minimap:GetNumChildren() + MinimapBackdrop:GetNumChildren() + MinimapCluster:GetNumChildren()
	if total == lastChildCount then return allChildren end
	lastChildCount = total
	wipe(allChildren)
	concatChildren(allChildren, Minimap:GetChildren())
	concatChildren(allChildren, MinimapBackdrop:GetChildren())
	concatChildren(allChildren, MinimapCluster:GetChildren())
	return allChildren
end

local captureNewChildren
do
	local childCount, lastChild, stockIndex
	-- Buttons to ignore if they show up in iteration. Usually due to manually parenting them to the minimap.
	local ignoreButtons = {
		MiniMapTracking = true,
		MiniMapWorldMapButton = true,
		TimeManagerClockButton = true,
		MinimapZoomIn = true,
		MinimapZoomOut = true,
		MiniMapVoiceChatFrame = true,
	}
	function captureNewChildren()
		local children = getChildren()
		if #children == childCount and lastChild == children[#children] then return 0 end
		childCount = #children
		lastChild = children[#children]

		local count = 0
		for i = (stockIndex or 1), #children do
			local child = children[i]
			local w, h = child.GetWidth and child:GetWidth() or 0, child.GetHeight and child:GetHeight() or 0
			local sizeOk = w > 25 and w < 100 and h > 25 and h < 100
			if sizeOk and stockIndex and not buttons[child:GetName()] and child.SetAlpha and not ignoreButtons[child:GetName()] and not child.sexyMapIgnore then
				buttons[child:GetName() or ("Button #" .. i)] = {child, custom = true}
				count = count + 1
			end
			if child == MiniMapVoiceChatFrame then
				stockIndex = i
			end
		end
		return count
	end
end
]]
local options = {
	type = "group",
	name = modName,
	childGroups = "tab",
	args = {
		custom = {
			type = "group",
			name = L["Addon Buttons"],
			disabled = function()
				return not db.controlVisibility
			end,
			args = {},
			order = 3,
		},
		dynamic = {
			type = "group",
			name = "Dynamic Buttons",
			disabled = function()
				return not db.controlVisibility
			end,
			args = {},
			order = 2,
		},
		stock = {
			type = "group",
			disabled = function()
				return not db.controlVisibility
			end,
			name = L["Standard Buttons"],
			args = {},
			order = 1,
		},
		lockDragging = {
			type = "toggle",
			name = L["Lock Button Dragging"],
			width = "full",
			order = 101,
			disabled = function()
				return true
				--return not db.allowDragging
			end,
			get = function()
				return db.lockDragging
			end,
			set = function(info, v)
				db.lockDragging = v
			end
		},
		enableDragging = {
			type = "toggle",
			name = L["Let SexyMap handle button dragging"],
			desc = L["Allow SexyMap to assume drag ownership for buttons attached to the minimap. Turn this off if you have another mod that you want to use to position your minimap buttons."],
			width = "full",
			order = 102,
			--
			disabled = function()
				return true
			end,
			--
			get = function()
				return db.allowDragging
			end,
			set = function(info, v)
				db.allowDragging = v
				if v then
					mod:MakeMovables()
				else
					mod:ReleaseMovables()
				end
			end
		},
		controlVisibility = {
			type = "toggle",
			name = L["Let SexyMap control button visibility"],
			desc = L["Turn this off if you want another mod to handle which buttons are visible on the minimap."],
			width = "full",
			order = 103,
			get = function()
				return db.controlVisibility
			end,
			set = function(info, v)
				db.controlVisibility = v
				for _,f in pairs(animFrames) do
					if not v then
						mod:ChangeFrameVisibility(f, "always")
					else
						mod:ChangeFrameVisibility(f, db.visibilitySettings[f:GetName()] or "hover")
					end
				end
			end
		},
		dragRadius = {
			type = "range",
			name = L["Drag Radius"],
			min = -30,
			max = 100,
			step = 1,
			bigStep = 1,
			order = 104,
			disabled = function()
				return true
				--return not db.allowDragging
			end,
			get = function()
				return db.radius
			end,
			set = function(info, v)
				db.radius = v
				parent:DisableFade(1.5)
				mod:UpdateDraggables()
			end
		}
	}
}

do
	local hideValues = {
		["always"] = L["Always"],
		["never"] = L["Never"],
		["hover"] = L["On hover"],
	}
	local dynamicValues = {
		["always"] = L["Always"],
		["hover"] = L["On hover"],
	}

	local function hideGet(info, v)
		return (db.visibilitySettings[info[#info]] or "hover") == v
	end

	local function hideSet(info, v)
		local name = info[#info]
		db.visibilitySettings[name] = v ~= "hover" and v or nil
		mod:ChangeFrameVisibility(_G[name], v)
	end

	function mod:AddButtonOptions(name, blizzIcon, dynamic)
		local p
		if blizzIcon then
			p = options.args.stock.args -- Blizz icon = stock section
		elseif dynamic then
			p = options.args.dynamic.args -- Blizz dynamic (off by default) icon = dynamic section
		else
			p = options.args.custom.args -- Addon icon = custom section
		end
		p[name] =  {
			type = "multiselect",
			name = ("Show %s:"):format(blizzButtons[name] or dynamicButtons[name] or name:gsub("LibDBIcon10_", "")),
			values = dynamic and dynamicValues or hideValues,
			get = hideGet,
			set = hideSet,
		}
	end
end

function mod:OnInitialize()
	local defaults = {
		profile = {
			radius = 2,
			dragPositions = {},
			visibilitySettings = {
				MinimapZoomIn = "never",
				MinimapZoomOut = "never",
				MiniMapWorldMapButton = "never",
				MinimapZoneTextButton = "always",
				TimeManagerClockButton = "always",
				MiniMapMailFrame = "always",
			},
			allowDragging = true,
			controlVisibility = true
		}
	}
	self.db = parent.db:RegisterNamespace(modName, defaults)
	db = self.db.profile
	parent:RegisterModuleOptions(modName, options, modName)

	parent.RegisterCallback(self, "SexyMap_NewFrame")
end

function mod:OnEnable()
	Shape = parent:GetModule("Shapes")
	--Shape.RegisterCallback(self, "SexyMap_ShapeChanged")

	db = self.db.profile
	local gotLast = false

	--self:Update()

	MiniMapInstanceDifficulty:EnableMouse(true)

	--self:MakeTrackingMovable()
	--self:MakeMovables()

	MiniMapInstanceDifficulty:SetFrameLevel(Minimap:GetFrameLevel() + 10)
end

do
	local fadeIgnore = {
		Minimap = true,
		MinimapBackdrop = true,
		SexyMapPingFrame = true,
		SexyMapCustomBackdrop = true,
		SexyMapCoordFrame = true,
		MiniMapTrackingButton = true, -- Child of MiniMapTracking which is faded
	}

	local OnFinished = function(anim)
		-- Minimap or Minimap icons including nil checks to compensate for other addons
		local f, focus = anim:GetParent(), GetMouseFocus()
		if focus and focus:GetParent() and focus:GetParent():GetName() and focus:GetParent():GetName():find("Mini[Mm]ap") then
			f:SetAlpha(1)
		else
			f:SetAlpha(0)
		end
	end


	local fadeStop -- Use a variable to prevent fadeout/in when moving the mouse around minimap/icons

	local OnEnter = function()
		if not db.controlVisibility or fadeStop then return end

		for _,v in pairs(animFrames) do
			local n = v:GetName()
			if not db.visibilitySettings[n] then
				v.smAnimGroup:Stop()
				v:SetAlpha(0)
				v.smAlphaAnim:SetChange(1)
				v.smAnimGroup:Play()
			end
		end
	end
	local OnLeave = function()
		if not db.controlVisibility then return end
		local focus = GetMouseFocus() -- Minimap or Minimap icons including nil checks to compensate for other addons
		if focus and focus:GetParent() and focus:GetParent():GetName() and focus:GetParent():GetName():find("Mini[Mm]ap") then
			fadeStop = true
			return
		end
		fadeStop = nil

		for _,v in pairs(animFrames) do
			local n = v:GetName()
			if not db.visibilitySettings[n] then
				v.smAnimGroup:Stop()
				v:SetAlpha(1)
				v.smAlphaAnim:SetChange(-1)
				v.smAnimGroup:Play()
			end
		end
	end

	function mod:SexyMap_NewFrame(_, f)
		local n, w = f:GetName(), f:GetWidth()
		-- Don't add animations for ignored frames, dynamically try to skip frames that may not be minimap buttons by checking size
		if not fadeIgnore[n] and w > 20 then
			f.smAnimGroup = f:CreateAnimationGroup()
			f.smAlphaAnim = f.smAnimGroup:CreateAnimation("Alpha")
			f.smAlphaAnim:SetOrder(1)
			f.smAlphaAnim:SetDuration(0.5)
			f.smAnimGroup:SetScript("OnFinished", OnFinished)
			tinsert(animFrames, f)

			if db.controlVisibility then
				self:ChangeFrameVisibility(f, db.visibilitySettings[n] or "hover")
			end
			self:AddButtonOptions(n, blizzButtons[n], dynamicButtons[n])
		end
		f:HookScript("OnEnter", OnEnter)
		f:HookScript("OnLeave", OnLeave)
	end

	function mod:ChangeFrameVisibility(frame, vis)
		if vis == "always" then
			if not dynamicButtons[frame:GetName()] then frame:Show() end
			frame:SetAlpha(1)
		elseif vis == "never" then
			frame:Hide()
		else
			if not dynamicButtons[frame:GetName()] then frame:Show() end
			frame:SetAlpha(0)
		end
	end
end


--[[
function mod:SexyMap_ShapeChanged()
	parent:DisableFade(1)
	self:UpdateDraggables()
end

function mod:CaptureButtons()
	local count = captureNewChildren()
	if count > 0 then
		for k, v in pairs(buttons) do
			mod:addButtonOptions(k, v)
		end
		self:Update()
	end
end

function mod:Update()
	if not db.controlVisibility then return end
	for k, v in pairs(buttons) do
		local hide = db[k] and db[k].hide or "hover"
		if hide ~= "hover" then
			for _, f in ipairs(v) do
				parent:UnregisterHoverButton(f)
			end
		end
		if hide == "hover" then
			for _, f in ipairs(v) do
				if v.custom and f:IsVisible() or not v.custom then
					parent:RegisterHoverButton(f, v.show)
					if v.override then
						parent:RegisterHoverOverride(f, v.override, unpack(v.overrideEvents))
					end
				end
			end
		elseif hide == "never" then
			for _, f in ipairs(v) do
				f = type(f) == "string" and _G[f] or f
				if f.Hide then
					f:Hide()
				end
			end
		else
			for _, f in ipairs(v) do
				f = type(f) == "string" and _G[f] or f
				if (v.custom and f:IsVisible() or not v.custom) and type(f) == "table" then
					if type(v.show) == "function" and v.show(f) or type(v.show) ~= "function" then
						if f.SetAlpha and f.Hide then
							f:SetAlpha(1)
							f:Show()
						end
					end
				end
			end
		end
	end
end

do
	local moving
	local movables = {}
	local dragFrame = CreateFrame("Frame", nil, UIParent)

	local GetCursorPosition = _G.GetCursorPosition

	local function getCurrentAngle(f, bx, by)
		local mx, my = Minimap:GetCenter()
		if not mx or not my or not bx or not by then return 0 end
		local h, w = (by - my), (bx - mx)
		if w == 0 then w = 0.001 end
		local angle = atan(h / w)
		if w < 0 then
			angle = angle + 180
		end
		return angle
	end

	local function setPosition(frame, angle)
		if not angle then
			local x, y = GetCursorPosition()
			x, y = x / Minimap:GetEffectiveScale(), y / Minimap:GetEffectiveScale()
			angle = getCurrentAngle(frame, x, y)
			db.dragPositions[frame:GetName()] = angle
		end

		local radius = (Minimap:GetWidth() / 2) + db.radius
		local bx, by = Shape:GetPosition(angle, radius)

		-- local bx = cos(angle) * radius
		-- local by = sin(angle) * radius

		frame:ClearAllPoints()
		frame:SetPoint("CENTER", Minimap, "CENTER", bx, by)
	end

	local function updatePosition()
		setPosition(moving)
	end

	local function start(frame)
		if db.lockDragging then return end

		dragFrame:SetScript("OnUpdate", updatePosition)
		parent:DisableFade()
		moving = frame
	end

	local function finish(frame)
		moving = nil
		parent:EnableFade()
		dragFrame:SetScript("OnUpdate", nil)
	end

	function mod:MakeMovable(frame)
		if not frame then return end
		if frame.sexyMapMovable then return end
		if movables[frame] then return end
		movables[frame] = true

		frame:RegisterForDrag("LeftButton")
		self:RawHookScript(frame, "OnDragStart", start)
		self:RawHookScript(frame, "OnDragStop", finish)
		frame.sexyMapMovable = true
	end

	function mod:MakeTrackingMovable()
		if MiniMapTracking.sexyMapMovable then return end
		if movables[MiniMapTracking] then return end
		movables[MiniMapTracking] = true
		MiniMapTrackingButton:RegisterForDrag("LeftButton")
		MiniMapTrackingButton:HookScript("OnDragStart", function()
			if db.lockDragging then return end

			parent:DisableFade()
			moving = MiniMapTracking
			dragFrame:SetScript("OnUpdate", updatePosition)
		end)
		MiniMapTrackingButton:HookScript("OnDragStop", finish)
		MiniMapTracking.sexyMapMovable = true
	end

	function mod:UpdateDraggables()
		if not db.allowDragging then return end

		for f, v in pairs(movables) do
			local x, y = f:GetCenter()
			local angle = db.dragPositions[f:GetName()] or getCurrentAngle(f, x, y)
			if angle then
				setPosition(f, angle)
			end
		end
	end

	local lastChildCount = 0
	function mod:MakeMovables()
		mod:CaptureButtons()

		if not db.allowDragging then return end

		local children = getChildren()
		local childCount = #children
		if childCount == lastChildCount then return end
		lastChildCount = childCount
		for i = 1, childCount do
			local child = children[i]
			local w, h = child.GetWidth and child:GetWidth() or 0, child.GetHeight and child:GetHeight() or 0
			local sizeOk = w > 25 and w < 100 and h > 25 and h < 100
			if sizeOk and child:GetName() then
				mod:MakeMovable(child)
			end
		end
		mod:UpdateDraggables()
	end

	function mod:ReleaseMovables()
		for frame, on in pairs(movables) do
			self:UnhookAll(frame)
			frame.sexyMapMovable = nil
			movables[frame] = nil
		end
	end
end
]]
--[[

====================================================
====================================================
====================================================
====================================================

]]
--[[
do
	local updateTimer, fadeTimer, fadeAnim
	-- Terrible, clean this up
	if not updateTimer then
		updateTimer = CreateFrame("Frame"):CreateAnimationGroup()
		local anim = updateTimer:CreateAnimation()
		updateTimer:SetScript("OnLoop", self.CheckExited)
		anim:SetOrder(1)
		anim:SetDuration(0.1)
		updateTimer:SetLooping("REPEAT")
	end
	if not fadeTimer then
		fadeTimer = CreateFrame("Frame"):CreateAnimationGroup()
		fadeAnim = fadeTimer:CreateAnimation()
		fadeTimer:SetScript("OnFinished", self.EnableFade)
		fadeAnim:SetOrder(1)
		fadeAnim:SetDuration(1)
		fadeTimer:SetLooping("NONE")
	end

	local faderFrame = CreateFrame("Frame")
	local fading = {}
	local fadeTarget = 0
	local fadeTime
	local totalTime = 0
	local hoverOverrides, hoverExempt = {}, {}

	local function fade(self, t)
		totalTime = totalTime + t
		local pct = min(1, totalTime / fadeTime)
		local total = 0
		for k, v in pairs(fading) do
			local alpha = v + ((fadeTarget - v) * pct)
			total = total + 1
			if not k.SetAlpha then
				print("|cFF33FF99SexyMap|r: No SetAlpha for", k:GetName())
			end

			k:SetAlpha(alpha)
			-- k:Show()
			if alpha == fadeTarget then
				fading[k] = nil
				total = total - 1
				-- if fadeTarget == 0 then
					-- k:Hide()
				-- end
			end
		end

		if total == 0 then
			faderFrame:SetScript("OnUpdate", nil)
		end
	end

	local function startFade(t)
		fadeTime = t or 0.2
		totalTime = 0
		faderFrame:SetScript("OnUpdate", fade)
	end

	local hoverButtons = {}
	function mod:RegisterHoverButton(frame, showFunc)
		local frameName = frame
		if type(frame) == "string" then
			frame = _G[frame]
		elseif frame then
			frameName = frame:GetName()
		end
		if not frame then
			-- print("|cFF33FF99SexyMap|r: Unable to register", frameName, ", does not exit")
			return
		end
		if hoverButtons[frame] then return end
		if not hoverExempt[frame] then
			frame:SetAlpha(0)
		end
		-- frame:Hide()
		hoverButtons[frame] = showFunc or true
	end

	function mod:UnregisterHoverButton(frame)
		if type(frame) == "string" then
			frame = _G[frame]
		end
		if not frame then return end
		if hoverButtons[frame] == true or type(hoverButtons[frame]) == "function" and hoverButtons[frame](frame) then
			frame:SetAlpha(1)
			-- frame:Show()
		end
		hoverButtons[frame] = nil
	end

	local function UpdateHoverOverrides(self, e)
		for k, v in pairs(hoverOverrides) do
			local ret = v(k, e)
			if ret then
				hoverExempt[k] = true
				k:SetAlpha(1)
				fading[k] = nil
			else
				hoverExempt[k] = false
				mod:OnExit()
			end
		end
	end

	function mod:RegisterHoverOverride(frame, func, ...)
		local frameName = frame
		if type(frame) == "string" then
			frame = _G[frame]
		elseif frame then
			frameName = frame:GetName()
		end

		hoverOverrides[frame] = func
		for i = 1, select("#", ...) do
			local event = select(i, ...)
			if not faderFrame:IsEventRegistered(event) then
				faderFrame:RegisterEvent(event)
			end
		end
		faderFrame:SetScript("OnEvent", UpdateHoverOverrides)
	end

	function mod:OnEnter()
		updateTimer:Play()
		fadeTarget = 1
		for k, v in pairs(hoverButtons) do
			if not hoverExempt[k] and (v == true or type(v) == "function" and v(k)) then
				fading[k] = k:GetAlpha()
			end
		end
		startFade()
	end

	function mod:OnExit()
		updateTimer:Stop()

		fadeTarget = 0
		for k, v in pairs(hoverButtons) do
			if not hoverExempt[k] then
				fading[k] = k:GetAlpha()
			end
		end
		startFade()
	end

	function mod:CheckExited()
		if mod.fadeDisabled then return end
		local f = GetMouseFocus()
		if f then
			local p = f:GetParent()
			while(p and p ~= UIParent) do
				if p == MinimapCluster then return true end
				p = p:GetParent()
			end
			mod:OnExit()
		end
	end

	function mod:EnableFade()
		mod.fadeDisabled = false
	end

	function mod:DisableFade(forHowLong)
		self.fadeDisabled = true
		self:OnEnter()
		if forHowLong and forHowLong > 0 then
			fadeTimer:Stop()
			fadeAnim:SetDuration(forHowLong)
			fadeTimer:Play()
		end
	end
end
]]