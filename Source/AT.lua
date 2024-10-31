local _, addonNS = ...

local Addon = LibStub("AceAddon-3.0"):NewAddon("AuctionatorTools", "AceEvent-3.0")
AuctionatorTools = Mixin(Addon, AuctionatorTools)
local function auctionatorActive()
	if Auctionator then return true else return false end
end

function AuctionatorTools:OnInitialize()
	if not Auctionator then
		print("Auctionator not found!!")
		return
	end
	self.db = LibStub("AceDB-3.0"):New("AuctionatorToolsDB", ATDB_Defaults)
	self:RegisterEvents()
	self:NewModule("AhManager", AhManager, "AceEvent-3.0", "AceBucket-3.0")
	self.originalSaleItem = Mixin(AuctionatorSaleItemMixin, {})
	addonNS.ImprovedSkip.InjectToAuctionator(self.originalSaleItem)
end

function AuctionatorTools:RegisterEvents()
	self:RegisterEvent("AUCTION_HOUSE_SHOW", "OnAuctionHouseShow")
end

function AuctionatorTools:OnAuctionHouseShow()
	self:CreateToggleButtons()
end
