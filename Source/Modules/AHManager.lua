---@enum AhStatus
local AH_STATUS = {
	READY = 1,
	BUSY = 2
}

---@class AHBuyerMessage
---@field success number
---@field event string
---@field data any

---@class AHManager: AceModule,AceBucket-3.0,AceEvent-3.0
---@field AhStatus AhStatus
AhManager = {}
function AhManager:OnEnable()
	AhManager.AhStatus = AH_STATUS.READY
	AhManager.queue = {}
	-- Set up events
	self:RegisterEvent("AUCTION_HOUSE_THROTTLED_SYSTEM_READY", "OnAhReady")
	self:RegisterBucketEvent("COMMODITY_SEARCH_RESULTS_UPDATED", 0.5, "OnCommodityUpdated")
	self:RegisterMessage("search_commodity", "SearchCommodity")
end

function AhManager:OnAhReady()
	self.AhStatus = AH_STATUS.READY
	if #self.queue > 0 then
		self:ProcessNext()
	end
end

function AhManager:AhNotReady(event, ...)
	local args = { ... }
	if self.AhStatus == AH_STATUS.BUSY then
		return true
	else
		return false
	end
end

function AhManager:ProcessNext()
	if self:AhNotReady() then return end
	if #self.queue > 0 then
		local nextItem = table.remove(self.queue, 1)
		if self:IsItemCommodity(nextItem) then
			self:SendQuery(nextItem)
		else
			print("item search is not implemented yet")
		end
	else
		---
	end
end

function AhManager:AddToQueue(itemID)
	table.insert(self.queue, itemID)
	cla("queue")
	cla(self.queue)
	self:ProcessNext()
end

function AhManager:OnCommodityUpdated(items)
	for itemID, _ in pairs(items) do
		self:SendCommodityResult(itemID)
	end
end

function AhManager:SearchCommodity(event, itemID)
	cla("AhManager: message received")
	cla(itemID)
	if not AhManager:IsItemCommodity(itemID) then
		print("Item to search is not commodity")
		return
	end

	self:AddToQueue(itemID)
end

function AhManager:SendQuery(itemID)
	self.AhStatus = AH_STATUS.BUSY
	local itemKey = C_AuctionHouse.MakeItemKey(itemID)
	local sorts = {
		{ sortOrder = Enum.AuctionHouseSortOrder.Price, reverseSort = false }
	}
	C_AuctionHouse.SendSearchQuery(itemKey, sorts, false)
end

---@alias AuctionDatas table<number, CommoditySearchResultInfo>

---@alias ComSearchMsgData table<number, AuctionDatas>


function AhManager:SendCommodityResult(itemID)
	---@type table<number, CommoditySearchResultInfo>
	local auctionDatas = {}
	for i = 1, C_AuctionHouse.GetNumCommoditySearchResults(itemID) do
		---@type CommoditySearchResultInfo|nil
		local result = C_AuctionHouse.GetCommoditySearchResultInfo(itemID, i)
		if result and result.itemID then
			table.insert(auctionDatas, i, result)
		end
	end

	self:SendResult("commodity_search_result", { itemID, auctionDatas })
end

function AhManager:SendResult(event, data)
	---@type AHBuyerMessage
	local message = {
		success = 1,
		event = event,
		data = data
	}
	self:SendMessage("ahmanager_result", message)
end

function AhManager:IsItemCommodity(itemID)
	self.commodityCache = self.commodityCache or {}
	if self.commodityCache[itemID] then return self.commodityCache[itemID] == "true" end

	if not itemID then return false end
	local itemKey = C_AuctionHouse.MakeItemKey(itemID)

	local itemInfo = C_AuctionHouse.GetItemKeyInfo(itemKey)
	if not itemInfo then
		return false
	elseif not itemInfo.isCommodity then
		self.commodityCache[itemID] = "false"
		return false
	elseif itemInfo.isCommodity then
		self.commodityCache[itemID] = "true"
		return true
	end
	print("IsItemCommodity unexpected code block reached")
	return nil
end
