std = "lua51"
max_line_length = false
codes = true
exclude_files = {
	"**/Libs",
}
ignore = {
	"111/SexyMap2DB",
	"111/SLASH_SexyMap1",
	"111/SLASH_SexyMap2",
	"111/SexyMap",
	"111/GetMinimapShape",
	"212/self",
	"11[23]",
	"211",
	"212",
	"213",
	"412/preset",
	"432/self",
}
files["HudMap.lua"].ignore = {
	".*",
}
not_globals = {
	"arg", -- arg is a standard global, so without this it won't error when we typo "args" in a module
}
globals = {

}
