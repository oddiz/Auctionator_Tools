---@diagnostic disable: lowercase-global
function AhTools_CalculateMean(auctionDatas)
	local quantity = 500

	local cumulativeCost = 0
	local cumulativeQuantity = 0
	local quantityIndex = 1

	for _, auction in ipairs(auctionDatas) do
		local newQuantity = cumulativeQuantity + auction.quantity
		local newCost = cumulativeCost + (auction.quantity * auction.unitPrice)

		cumulativeQuantity = newQuantity
		cumulativeCost = newCost

		if cumulativeQuantity >= quantity then
			break
		end
	end

	return math.floor(cumulativeCost / cumulativeQuantity)
end

cla = function(msg)
	if DevTool then
		DevTool:AddData(msg)
	end
end
