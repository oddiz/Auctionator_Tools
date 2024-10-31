std = "lua51"
max_line_length = false
codes = true

exclude_files = {
	"**/Libs",
}
not_globals = {
	"arg", -- arg is a standard global, so without this it won't error when we typo "args" in a module
}
globals = {
	-- wow std api
	"abs",
	"bit",
	"ceil",
	"cos",
	"debugstack",
	"exp",
	"floor",
	"format",
	"gmatch",
	"gsub",
	"hooksecurefunc",
	"ldexp",
	"max",
	"min",
	"mod",
	"rad",
	"random",
	"scrub",
	"sin",
	"sort",
	"sqrt",
	"strbyte",
	"strchar",
	"strcmputf8i",
	"strconcat",
	"strfind",
	"string.join",
	"strjoin",
	"strlen",
	"strlenutf8",
	"strlower",
	"strmatch",
	"strrep",
	"strrev",
	"strsplit",
	"strsub",
	"strtrim",
	"strupper",
	"table.wipe",
	"tan",
	"time",
	"tinsert",
	"tremove",

	-- framexml
	"tContains",

	-- Vanilla
	"GetTalentTabInfo",
}