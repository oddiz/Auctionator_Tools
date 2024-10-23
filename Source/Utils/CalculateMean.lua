---@diagnostic disable: lowercase-global
function AhTools_CalculateMean(auctionDatas)
	local quantity = 500

	-- Return 0 if no auction data
	if not auctionDatas or #auctionDatas == 0 then
		return 0
	end

	local cumulativeCost = 0
	local cumulativeQuantity = 0

	for _, auction in ipairs(auctionDatas) do
		-- Calculate how much we need from this auction
		local remainingNeeded = quantity - cumulativeQuantity
		if remainingNeeded <= 0 then
			break
		end

		-- Only take what we need from this auction
		local quantityToTake = math.min(auction.quantity, remainingNeeded)

		cumulativeQuantity = cumulativeQuantity + quantityToTake
		cumulativeCost = cumulativeCost + (quantityToTake * auction.unitPrice)
	end

	-- Return 0 if we couldn't get any items
	if cumulativeQuantity == 0 then
		return 0
	end

	return math.floor(cumulativeCost / cumulativeQuantity)
end

cla = function(msg)
	if DevTool then
		DevTool:AddData(msg)
	end
end
