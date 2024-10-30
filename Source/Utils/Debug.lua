function AuctionatorTools.Debug.IsOn()
	return true
end

function AuctionatorTools.Debug.Message(message, ...)
	if AuctionatorTools.Debug.IsOn() then
		print(GOLD_FONT_COLOR:WrapTextInColorCode(message), ...)
	end
end
