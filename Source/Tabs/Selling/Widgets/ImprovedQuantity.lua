local _, addonNS = ...
local AceGUI = LibStub:GetLibrary("AceGUI-3.0")
local AceDB = LibStub:GetLibrary("AceDB-3.0")
local ImprovedQuantity = {}

local Debug = AuctionatorTools.Debug.Message
local function restockQtyLabel()
	local undercutSkipActive = AuctionatorTools.db.profile.Selling.ImprovedQuantity.skipIfLeadSeller or false
	if undercutSkipActive then
		return GRAY_FONT_COLOR:WrapTextInColorCode("Restock posted auction (Disabled: Skipping non-undercutted auctions)")
	else
		return "Restock posted auction"
	end
end
function ImprovedQuantity:DrawWidget(container)
	self.widgetSettings = AuctionatorTools.db.profile.Selling.ImprovedQuantity
	local moduleContainer = addonNS.CreateATWidget("Improved Quantity")

	local cbRestock = AceGUI:Create("CheckBox")
	cbRestock:SetLabel(restockQtyLabel())
	cbRestock:SetValue(self.widgetSettings.restockQty or false)



	moduleContainer:AddChild(cbRestock)

	container:AddChild(moduleContainer)

	cbRestock:SetCallback("OnValueChanged", function(cb)
		ImprovedQuantity.widgetSettings.restockQty = cb:GetValue()
		Debug("New value for restockQty ", ImprovedQuantity.GetSetting("restockQty"))
		cbRestock:SetLabel(restockQtyLabel())
	end)
end

function ImprovedQuantity.SaveQuantity(itemID, amount)
	local qtyDB = AuctionatorTools.db.global.quantity

	if (itemID and amount and qtyDB) then
		qtyDB[itemID] = amount

		return true
	else
		return false
	end
end

function ImprovedQuantity.GetQuantity(itemID)
	local qtyDB = AuctionatorTools.db.global.quantity
	if qtyDB and itemID then
		return qtyDB[itemID]
	end
end

function ImprovedQuantity.InjectToAuctionator(originalMixin)
	function AuctionatorSaleItemMixin:CreateSaveQtyButton()
		-- Create save button
		local maxButton = self.MaxButton

		if not maxButton then
			Debug("Max button not found")
		else
			self.SaveButton = AceGUI:Create("Button")
			self.SaveButton:SetWidth(100)
			self.SaveButton:SetParent(maxButton)
			self.SaveButton:SetPoint("TOP", maxButton, "BOTTOM", 0, 5)
			self.SaveButton:SetText("Save Quantity")

			self.SaveButton:OnClick(function()
				local currentQuantity = self.Quantity:GetNumber()
				local currentItemID = self.itemInfo.itemID

				if currentQuantity and currentItemID then
					local result = ImprovedQuantity.SaveQuantity(currentItemID, currentQuantity)

					local orgText = self.SaveButton:GetText()
					self.SaveButton:SetText(string.format("%s %s", orgText, (result and "Saved") or "Failed"))
				end
			end)
		end
	end

	----------------------------------------------------------
	local SetQuantity_org = originalMixin.SetQuantity
	function AuctionatorSaleItemMixin:SetQuantity()
		local itemID = self.itemInfo.itemID
		local customQuantity = itemID and ImprovedQuantity.GetQuantity(itemID)

		if customQuantity then
			local result = self:GetCommodityResult(itemID)
			Debug("checking if undercutted for" .. itemID)
			if result and result.containsOwnerItem and result.owners[1] == "player" then
				Debug("Auction not undercutted")
				self.Quantity:SetNumber(customQuantity - result.quantity)
			else
				self.Quantity:SetNumber(customQuantity)
			end
		else
			SetQuantity_org(self)
		end
	end
end
