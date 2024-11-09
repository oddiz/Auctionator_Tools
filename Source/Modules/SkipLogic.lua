--------- Skip logic ---------
-- Variables:
--   Master switch
--   Restock enabled and Restock amount
--   Preference: Skip | Refresh
-- Conditions:
--   Auction is undercut
--   Auction is not undercut
--     Restock enabled -?-> Restock threshold is reached
-- Actions:
--   Skip or Refresh
--   Do nothing
-------------------------------

---@alias SkipSetting "masterSwitch"|"processNonUndercut"|"restockEnabled"|"restockThreshold"|"preference"


local default_settings = setmetatable({
	masterSwitch = false,
	processNonUndercut = false,
	restockEnabled = false,
	restockThreshold = 0.5,
	preference = "SKIP", -- "SKIP" or "REFRESH"
}, { __newindex = function() error("Default settings are read-only") end })
SkipLogic = {}
local _, addonNS = ...
local Debug = addonNS.Debug.Message
function SkipLogic:OnEnable()
	-- Initialize default values
	if self.initialized then return end
	self.initialized = true
	SkipLogic.InjectMethods()
end

---@param setting SkipSetting
function SkipLogic:GetSetting(setting)
	local value = AuctionatorTools.db.profile.Selling.SkipLogic[setting]
	return value ~= nil and value or default_settings[setting]
end

---@param setting SkipSetting
function SkipLogic:SetSetting(setting, value)
	AuctionatorTools.db.profile.Selling.SkipLogic[setting] = value
end

function SkipLogic:ProcessItemLogic(itemInfo)
	Debug("ProcessItemLogic with itemID", itemInfo.itemID)

	if not self:GetSetting("masterSwitch") then
		return
	end

	-- Get current item data
	local currentItem = itemInfo or self.itemInfo or self.lastItemInfo
	if not currentItem then return end

	-- Check if we should process this item
	if not self:ShouldProcessItem(currentItem) then
		return
	end

	-- Process based on undercut status
	local undercutStatus = self:GetUndercutStatus(currentItem)
	if undercutStatus.isUndercut then
		Debug("Auction is undercutted or no player auction exists")
		self:HandleUndercutItem(currentItem)
	elseif undercutStatus.isUndercut == false then
		Debug("Auction not undercutted")
		if self:GetSetting("processNonUndercut") then
			local result = undercutStatus.result
			self:HandleNonUndercutItem(currentItem, result)
		end
	end
end

function SkipLogic:ShouldProcessItem(itemInfo)
	-- Add any preliminary checks here
	return itemInfo and itemInfo.key
end

function SkipLogic:GetUndercutStatus(itemInfo)
	local itemID = itemInfo.itemID
	local result = AuctionatorSaleItemMixin:GetCommodityResult(itemID)
	Debug("Getting undercut status for" .. itemID)
	if result and result.containsOwnerItem and result.owners[1] == "player" then
		return {
			isUndercut = false,
			result = result,
		}
	elseif not result.containsOwnerItem then
		return {
			isUndercut = true,
			result = result,
		}
	end

	Debug(RED_FONT_COLOR:WrapTextInColorCode("Couldn't determine undercut status"))
end

function SkipLogic:DoAction(itemInfo)
	if self:GetSetting("masterSwitch") == false then return end
	if self:GetSetting("preference") == "SKIP" then
		self:SkipItem(itemInfo)
	elseif self:GetSetting("preference") == "REFRESH" then
		self:RefreshItem(itemInfo)
	end
end

function SkipLogic:HandleUndercutItem(itemInfo)
	-- do nothing
end

function SkipLogic:HandleNonUndercutItem(itemInfo, result)
	if self:GetSetting("restockEnabled") then
		self:HandleRestockLogic(itemInfo, result.quantity)
	else
		self:DoAction(itemInfo)
	end
end

function SkipLogic:GetSavedQuantity(itemInfo)
	local qtyDB = AuctionatorTools.db.global.quantity
	if qtyDB and itemInfo.itemID and qtyDB[itemInfo.itemID] then
		return qtyDB[itemInfo.itemID]
	else
		local defaultQuantity = Auctionator.Config.Get(Auctionator.Config.Options.DEFAULT_QUANTITIES)[itemInfo.classId]
		if defaultQuantity ~= nil and defaultQuantity > 0 then
			return defaultQuantity
		else
			-- No default quantity setting, use the maximum possible
			return AuctionatorSaleItemMixin:GetPostLimit()
		end
	end
end

function SkipLogic:HandleRestockLogic(itemInfo, postedQty)
	Debug("handling restock logic")
	local savedQty = self:GetSavedQuantity(itemInfo)
	local ratio = postedQty / savedQty
	Debug("ratio: " .. ratio)
	if ratio > self:GetSetting("restockThreshold") then
		Debug("Over threshold, running action")
		self:DoAction(itemInfo)
	else
		Debug("Under threshold setting missing amount")
		self.Quantity:SetNumber(savedQty - postedQty)
	end
end

-----------------------------------------------------
-------------- INJECT/HOOK METHODS ------------------
-----------------------------------------------------

function SkipLogic.InjectMethods()
	-- Set Auto Select Next to true for Auctionator by default
	Auctionator.Config.Set(Auctionator.Config.Options.SELLING_AUTO_SELECT_NEXT, true)

	local injectObject = CreateFromMixins(AuctionatorSaleItemMixin, SkipLogic)

	AuctionatorSaleItemMixin = injectObject


	local originalProcessCommodityResults = AuctionatorSaleItemMixin.ProcessCommodityResults
	-- Hook into existing ProcessCommodityResults
	function AuctionatorSaleItemMixin:ProcessCommodityResults(itemID, ...)
		originalProcessCommodityResults(self, itemID, ...)

		local itemInfo = self.itemInfo or self.lastItemInfo
		-- After processing commodity results, run our skip logic
		self:ProcessItemLogic(itemInfo)
	end

	local originalPostItem = AuctionatorSaleItemMixin.PostItem
	function AuctionatorSaleItemMixin:PostItem(confirmed)
		Debug("AuctionatorSaleItemMixin PostItem()")
		-- Unregister from the BagItemRequest event
		Auctionator.EventBus:Unregister(self, {
			Auctionator.Selling.Events.BagItemRequest
		})
		originalPostItem(self, confirmed)

		-- Register for the BagItemRequest event
		Auctionator.EventBus:Register(self, {
			Auctionator.Selling.Events.BagItemRequest
		})

		-- Original post item deletes self.itemInfo and stores it in lastItemInfo
		self:DoAction(self.lastItemInfo)
	end

	function AuctionatorSaleItemMixin:UpdateSkipButtonState()
		self.SkipButton:SetEnabled(self.SkipButton:IsShown())
		self.PrevButton:SetEnabled(self.SkipButton:IsShown() and self.prevItem)
	end

	function AuctionatorSaleItemMixin:GetFirstItemKey()
		Debug("AuctionatorSaleItemMixin GetFirstItem()")
		local firstItem = nil
		local frame = AuctionatorSellingFrame
		local bagListing = frame.BagListing
		local bagListingView = bagListing.View
		local bagListingViewGroups = bagListingView.groups
		if bagListingViewGroups ~= nil then
			for group in ipairs(bagListingViewGroups) do
				if #bagListingViewGroups[group].buttons > 0 then
					firstItem = bagListingViewGroups[group].buttons[1].key
					break
				end
			end
		end


		return firstItem
	end

	function AuctionatorSaleItemMixin:GetLastItemKey()
		Debug("AuctionatorSaleItemMixin GetLastItem()")
		local lastItem = nil
		local frame = AuctionatorSellingFrame
		local bagListing = frame.BagListing
		local bagListingView = bagListing.View
		local bagListingViewGroups = bagListingView.groups

		if bagListingViewGroups ~= nil then
			-- Iterate through groups in reverse to find the last non-empty group
			for i = #bagListingViewGroups, 1, -1 do
				local buttons = bagListingViewGroups[i].buttons
				if #buttons > 0 then
					-- Get the last button from the group
					lastItem = buttons[#buttons].key
					break
				end
			end
		end
		return lastItem
	end

	-- Replace original SkipItem method
	function AuctionatorSaleItemMixin:SkipItem(itemInfo)
		if itemInfo == nil then
			-- If itemInfo is nil, skip button is clicked mannually
			itemInfo = self.itemInfo or self.lastItemInfo
		end
		-- Validate that we're skipping the correct item
		if (itemInfo and self.itemInfo) and (itemInfo.itemID ~= self.itemInfo.itemID) then
			return
		end
		Debug("Skipping item ", itemInfo)

		-- Check if we are at the end of the list
		if self:GetLastItemKey().sortKey == itemInfo.key.sortKey then
			Debug("Reached end of list")
			-- Optionally, you could wrap around to the first item here
			local firstItem = self:GetFirstItemKey()
			Auctionator.EventBus:Fire(
				self, Auctionator.Selling.Events.BagItemRequest, firstItem
			)
			return
		else
			Debug("Not at end of list, next item is: ", itemInfo.nextItem)
			-- Fire the event to select the next item
			Auctionator.EventBus:Fire(
				self,
				Auctionator.Selling.Events.BagItemRequest,
				itemInfo.nextItem
			)
		end
	end

	function AuctionatorSaleItemMixin:RefreshItem(itemInfo)
		Debug("AuctionatorSaleItemMixin RefreshItem()")
		if itemInfo == nil then
			-- If itemInfo is nil, refresh button is clicked mannually	
			itemInfo = self.itemInfo or self.lastItemInfo
		end
		-- Re-fire the event for the same item to refresh it
		Auctionator.EventBus:Fire(
			self,
			Auctionator.Selling.Events.BagItemRequest,
			itemInfo.key
		)
	end
end
