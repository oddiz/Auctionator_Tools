local _, addonNS = ...
local AceGUI = LibStub:GetLibrary("AceGUI-3.0")
local AceDB = LibStub:GetLibrary("AceDB-3.0")
local ImprovedSkip = {}

local Debug = AuctionatorTools.Debug.Message

local function skipIfLeadSellerLabel(skipEnabled)
	if skipEnabled then
		return "Skip if you are the lead seller"
	else
		return "Refresh until undercut"
	end
end

function ImprovedSkip:DrawWidget(container)
	self.widgetSettings = AuctionatorTools.db.profile.Selling.ImprovedSkip

	local moduleContainer = addonNS.CreateATWidget("Improved Skip")

	local cbSkipEnabled = AceGUI:Create("CheckBox")
	cbSkipEnabled:SetLabel("Auto skip to next item")
	cbSkipEnabled:SetValue(self.widgetSettings.skipEnabled or false)

	local cbSkipToFirst = AceGUI:Create("CheckBox")
	cbSkipToFirst:SetLabel("Loop to first item")
	cbSkipToFirst:SetValue(self.widgetSettings.skipToFirst or false)

	local cbSkipIfLeadSeller = AceGUI:Create("CheckBox")
	local siflsLabel = skipIfLeadSellerLabel(self.widgetSettings.skipEnabled or false)
	cbSkipIfLeadSeller:SetLabel(siflsLabel)
	cbSkipIfLeadSeller:SetValue(self.widgetSettings.skipIfLeadSeller or false)

	moduleContainer:AddChild(cbSkipEnabled)
	moduleContainer:AddChild(cbSkipToFirst)
	moduleContainer:AddChild(cbSkipIfLeadSeller)

	container:AddChild(moduleContainer)

	cbSkipEnabled:SetCallback("OnValueChanged", function(cb)
		ImprovedSkip.widgetSettings.skipEnabled = cb:GetValue()
		Debug("New value for skipEnabled ", ImprovedSkip.GetSetting("skipEnabled"))
		cbSkipIfLeadSeller:SetLabel(skipIfLeadSellerLabel(ImprovedSkip.GetSetting("skipEnabled")))
	end)
	cbSkipToFirst:SetCallback("OnValueChanged", function(cb)
		ImprovedSkip.widgetSettings.skipToFirst = cb:GetValue()
		Debug("New value for skipToFirst ", ImprovedSkip.GetSetting("skipToFirst"))
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

function ImprovedSkip.InjectToAuctionator(originalMixin)
	if not AuctionatorSaleItemMixin then
		Debug("Couldn't find AuctionatorSaleItemMixin")
		return
	end
	Debug("Setting auto select next to false")
	Auctionator.Config.Set(Auctionator.Config.Options.SELLING_AUTO_SELECT_NEXT, false)


	Debug("Injecting Improved Skip Functions")
	function AuctionatorSaleItemMixin:GetFirstItem()
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

	function AuctionatorSaleItemMixin:GetLastItem()
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
	function AuctionatorSaleItemMixin:SkipItem(itemID)
		Debug("AuctionatorSaleItemMixin SkipItem(itemID)", itemID)
		local SALE_ITEM_EVENTS = {
			Auctionator.AH.Events.CommoditySearchResultsReady,
			Auctionator.AH.Events.ItemSearchResultsReady,
		}
		local itemInfo = self.itemInfo or self.lastItemInfo

		if itemID and itemInfo.itemID ~= itemID then return end
		local isSkipEnabled = addonNS.ImprovedSkip.GetSetting("skipEnabled")

		if not isSkipEnabled then
			Debug("Skip disabled selecting last item")
			-- Skip is disabled
			Auctionator.EventBus:Fire(
				self, Auctionator.Selling.Events.BagItemRequest, itemInfo.key
			)
			return
		else
			-- Skip is enabled
			if itemInfo.nextItem then
				Debug("Skipping to next item")
				Auctionator.EventBus:Fire(
					self, Auctionator.Selling.Events.BagItemRequest, itemInfo.nextItem
				)
				return
			end
			local lastItem = self:GetLastItem()

			local atLastItem = lastItem and (lastItem.sortKey == itemInfo.sortKey)
			if atLastItem and addonNS.ImprovedSkip.GetSetting("skipToFirst") then
				-- if atLastItem
				Debug("Skipping to first item")
				local firstItem = self:GetFirstItem()
				Auctionator.EventBus:Fire(
					self, Auctionator.Selling.Events.BagItemRequest, firstItem
				)

				return
			end
		end
	end

	-- Skip if undercut
	local ProcessCommodityResults_old = originalMixin.ProcessCommodityResults
	function AuctionatorSaleItemMixin:ProcessCommodityResults(itemID, ...)
		Debug("Processing commodity results", itemID)
		ProcessCommodityResults_old(self, itemID, ...)
		if addonNS.ImprovedSkip.GetSetting("skipIfLeadSeller") then
			local result = self:GetCommodityResult(itemID)
			Debug("checking if undercutted for" .. itemID)
			if result and result.containsOwnerItem and result.owners[1] == "player" then
				Debug("Auction not undercutted")
				self:SkipItem(itemID)
			else
				Debug("Auction is undercutted")
			end
		end
	end

	local PostItem_old = originalMixin.PostItem

	function AuctionatorSaleItemMixin:PostItem(confirmed)
		Debug("AuctionatorSaleItemMixin PostItem(confirmed)", confirmed)
		PostItem_old(self, confirmed)
		local postedItemID = self.lastItemInfo.itemID
		self:SkipItem(postedItemID)
	end
end

addonNS.ImprovedSkip = ImprovedSkip
