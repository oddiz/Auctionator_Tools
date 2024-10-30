local _, addonNS = ...
local AceGUI = LibStub:GetLibrary("AceGUI-3.0")
local AceDB = LibStub:GetLibrary("AceDB-3.0")
local ImprovedSkip = {}

local Debug = AuctionatorTools.Debug.Message
function ImprovedSkip:DrawWidget(container)
	self.widgetSettings = AuctionatorTools.db.profile.Selling.ImprovedSkip

	local moduleContainer = addonNS.CreateATWidget("Improved Skip")

	local cbSkipEnabled = AceGUI:Create("CheckBox")
	cbSkipEnabled:SetLabel("Auto Skip")
	cbSkipEnabled:SetValue(self.widgetSettings.skipEnabled or false)

	local cbSkipToFirst = AceGUI:Create("CheckBox")
	cbSkipToFirst:SetLabel("Loop to first item")
	cbSkipToFirst:SetValue(self.widgetSettings.skipToFirst or false)

	local cbSkipIfLeadSeller = AceGUI:Create("CheckBox")
	cbSkipIfLeadSeller:SetLabel("Skip if you are the lead seller")
	cbSkipIfLeadSeller:SetValue(self.widgetSettings.skipIfLeadSeller or false)

	moduleContainer:AddChild(cbSkipEnabled)
	moduleContainer:AddChild(cbSkipToFirst)
	moduleContainer:AddChild(cbSkipIfLeadSeller)

	container:AddChild(moduleContainer)

	cbSkipToFirst:SetCallback("OnValueChanged", function(cb)
		ImprovedSkip.widgetSettings.skipToFirst = cb:GetValue()
		Debug("New value for skipToFirst ", ImprovedSkip.GetSetting("skipToFirst"))
	end)

	cbSkipEnabled:SetCallback("OnValueChanged", function(cb)
		ImprovedSkip.widgetSettings.skipEnabled = cb:GetValue()
		Debug("New value for skipEnabled ", ImprovedSkip.GetSetting("skipEnabled"))
	end)
	cbSkipIfLeadSeller:SetCallback("OnValueChanged",
		function(cb)
			self.widgetSettings.skipIfLeadSeller = cb:GetValue()
			Debug("New value for skipIfLeadSeller ", ImprovedSkip.GetSetting("skipIfLeadSeller"))
		end)
end

function ImprovedSkip.GetSetting(settingName)
	return AuctionatorTools.db.profile.Selling.ImprovedSkip
			[settingName]
end

function ImprovedSkip.InjectToAuctionator()
	if not AuctionatorSaleItemMixin then
		print("Couldn't find AuctionatorSaleItemMixin")
		return
	end
	Auctionator.Config.Set(Auctionator.Config.Options.SELLING_AUTO_SELECT_NEXT, false)
	local mixin = Mixin(AuctionatorSaleItemMixin)
	function AuctionatorSaleItemMixin:GetFirstItem()
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

	function AuctionatorSaleItemMixin:GetLastItem()
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

	function AuctionatorSaleItemMixin:UpdateSkipButtonState()
		if not self.SkipButton:IsShown() then
			self.SkipButton:Show()
		end
		if ImprovedSkip.GetSetting("skipEnabled") then
			local skipToFirst = addonNS.ImprovedSkip.GetSetting("skipToFirst")
			self.SkipButton:SetEnabled(self.SkipButton:IsShown() and (self.nextItem or skipToFirst))
			self.PrevButton:SetEnabled(self.SkipButton:IsShown() and self.prevItem)
		else
			self.SkipButton:SetEnabled(false)
		end
	end

	-- Skip logic
	function AuctionatorSaleItemMixin:SkipItem(...)
		local SALE_ITEM_EVENTS = {
			Auctionator.AH.Events.CommoditySearchResultsReady,
			Auctionator.AH.Events.ItemSearchResultsReady,
		}
		local itemID = ...
		local itemInfo = self.itemInfo or self.lastItemInfo
		if itemInfo.itemID ~= itemID then return end
		local isSkipEnabled = addonNS.ImprovedSkip.GetSetting("skipEnabled")

		if not isSkipEnabled then
			-- Skip is disabled
			Auctionator.EventBus:Fire(
				self, Auctionator.Selling.Events.BagItemRequest, self.lastKey
			)
			return
		else
			-- Skip is enabled
			if self.nextItem then
				Auctionator.EventBus:Fire(
					self, Auctionator.Selling.Events.BagItemRequest, self.nextItem
				)
				return
			end
			local lastItem = self:GetLastItem()

			local atLastItem = lastItem and lastItem.sortKey == self.itemInfo.sortKey
			if atLastItem and addonNS.ImprovedSkip.GetSetting("skipToFirst") then
				-- if atLastItem
				local firstItem = self:GetFirstItem()
				Auctionator.EventBus:Fire(
					self, Auctionator.Selling.Events.BagItemRequest, firstItem
				)

				return
			end
		end
	end

	-- Skip if undercut
	local ProcessCommodityResults_old = mixin.ProcessCommodityResults
	function AuctionatorSaleItemMixin:ProcessCommodityResults(itemID, ...)
		ProcessCommodityResults_old(self, itemID, ...)
		if addonNS.ImprovedSkip.GetSetting("skipIfLeadSeller") then
			local result = self:GetCommodityResult(itemID)
			Debug("checking if undercutted for" .. itemID)
			if result and result.containsOwnerItem and result.owners[1] == "player" then
				Debug("Auction not undercutted")
				self:SkipItem(itemID)
			else
				Debug("Auction is undercutted")
				DevTool:AddData(result)
			end
		end
	end

	-- Skip after posting
	local PostItem_old = mixin.PostItem

	function AuctionatorSaleItemMixin:PostItem(confirmed)
		PostItem_old(self, confirmed)
	end
end

addonNS.ImprovedSkip = ImprovedSkip
