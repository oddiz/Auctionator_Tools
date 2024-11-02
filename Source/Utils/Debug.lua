function AuctionatorTools.Debug.IsOn()
	return AuctionatorTools.Config.Debug
end

function AuctionatorTools.Debug.Message(message, ...)
	if AuctionatorTools.Debug.IsOn() then
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
