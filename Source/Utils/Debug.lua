local _, addonNS = ...
addonNS.Debug = {}
function addonNS.Debug.IsOn()
	local debugOn = AuctionatorTools.db.global.Config.Debug
	return debugOn
end

function addonNS.Debug.SetOn(value)
	local debugOn = AuctionatorTools.db.global.Config.Debug
	debugOn = value
	AuctionatorTools.db.global.Config.Debug = debugOn
end

function addonNS.Debug.Message(message, ...)
	if addonNS.Debug.IsOn() then
		print(GOLD_FONT_COLOR:WrapTextInColorCode(message), ...)

		-- if any of the arguments are tables, pretty print them
		for i, arg in ipairs({ ... }) do
			if type(arg) == "table" then
				if DevTools_Dump then -- DevTools_Dump is a global function from DevTools_Dump.lua
					print(DevTools_Dump(arg))
				else
					print(arg)
				end
			end
		end
	end
end
