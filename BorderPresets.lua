SexyMap.borderPresets = {				
	["Blue Runes"] = {
		borders = {
			{
				["a"] = 1,
				["r"] = 0.3098039215686275,
				["name"] = "Rune 1",
				["b"] = 1,
				["scale"] = 1.4,
				["rotSpeed"] = -16,
				["g"] = 0.4784313725490196,
				["texture"] = "SPELLS\\AURARUNE256.BLP",
			}, -- [1]
			{
				["a"] = 0.3799999952316284,
				["r"] = 0.196078431372549,
				["rotSpeed"] = 4,
				["b"] = 1,
				["scale"] = 2.1,
				["name"] = "Rune 2",
				["g"] = 0.2901960784313725,
				["texture"] = "SPELLS\\AuraRune_A.blp",
			}, -- [2]
			{
				["a"] = 0.3,
				["name"] = "Fade",
				["b"] = 1,
				["scale"] = 1.6,
				["r"] = 0,
				["g"] = 0.2235294117647059,
				["texture"] = "SPELLS\\T_VFX_HERO_CIRCLE.BLP",
			}, -- [3]
		},
		shape = "Textures\\MinimapMask"
	},
	["Purple Rune Square"] = {
		borders = {
			{
				["a"] = 0.5,
				["hNudge"] = 0,
				["rotSpeed"] = 0,
				["b"] = 1,
				["scale"] = 1.6,
				["g"] = 0.2666666666666667,
				["vNudge"] = 0,
				["rotation"] = 0,
				["name"] = "Rune",
				["r"] = 0.6705882352941176,
				["texture"] = "SPELLS\\AuraRune256b.blp",
			}, -- [1]
			{
				["a"] = 0.1899999976158142,
				["name"] = "Inner Circle",
				["b"] = 1,
				["scale"] = 3,
				["r"] = 0.4705882352941176,
				["g"] = 0,
				["texture"] = "Interface\\GLUES\\MODELS\\UI_Tauren\\gradientCircle.blp",
			}, -- [2]
		},
		shape = "Interface\\AddOns\\SexyMap\\shapes\\diamond"
	},
	["Burning Sun"] = {
		borders = {
			{
				["a"] = 1,
				["r"] = 1,
				["name"] = "Main",
				["b"] = 0.04313725490196078,
				["scale"] = 1.57,
				["rotSpeed"] = 21,
				["g"] = 0.2901960784313725,
				["texture"] = "PARTICLES\\GENERICGLOW5.BLP",
			}, -- [1]
			{
				["a"] = 1,
				["r"] = 1,
				["name"] = "Second",
				["b"] = 0.3529411764705882,
				["scale"] = 1.68,
				["rotSpeed"] = -11,
				["g"] = 0.8705882352941177,
				["texture"] = "PARTICLES\\GENERICGLOW5.BLP",
			}, -- [2]
			{
				["a"] = 1,
				["name"] = "Tint",
				["b"] = 0.3254901960784314,
				["scale"] = 1.35,
				["r"] = 1,
				["g"] = 0.6705882352941176,
				["texture"] = "SPELLS\\T_VFX_HERO_CIRCLE.BLP",
			}, -- [3]		
		},
		shape = "Textures\\MinimapMask"
	},
	["Midnight Moon"] = {
		borders = {
			{
				["a"] = 0.6400000154972076,
				["rotSpeed"] = 0,
				["b"] = 1,
				["scale"] = 1.47,
				["g"] = 0.1137254901960784,
				["rotation"] = 0,
				["name"] = "Shadow",
				["drawLayer"] = "BORDER",
				["blendMode"] = "BLEND",
				["r"] = 0,
				["texture"] = "SPELLS\\T_VFX_Moon_Black.blp",
			}, -- [1]
			{
				["a"] = 1,
				["hNudge"] = 1,
				["rotSpeed"] = 0,
				["b"] = 0.8156862745098039,
				["scale"] = 2.3,
				["g"] = 0.7058823529411764,
				["vNudge"] = 3,
				["drawLayer"] = "OVERLAY",
				["name"] = "Glow",
				["rotation"] = 198,
				["r"] = 0.6509803921568628,
				["blendMode"] = "ADD",
				["texture"] = "SPELLS\\MoonCrescentGlow2.blp",
			}, -- [2]	
		},
		shape = "Textures\\MinimapMask"
	}	
}