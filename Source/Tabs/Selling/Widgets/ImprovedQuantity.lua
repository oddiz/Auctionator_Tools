local _, addonNS = ...
local AceGUI = LibStub:GetLibrary("AceGUI-3.0")
local ImprovedQuantity = {}

local Debug = addonNS.Debug.Message

function ImprovedQuantity:DrawWidget(container)
	local moduleContainer = addonNS.CreateATWidget("Improved Quantity")

	moduleContainer:SetLayout("Flow")
	--------------------------------------------
	local cbUseCustomQty = AceGUI:Create("CheckBox")
	cbUseCustomQty:SetValue(AuctionatorTools.db.profile.Selling.ImprovedQuantity.useCustomQty or false)
	cbUseCustomQty:SetRelativeWidth(1)
	cbUseCustomQty:SetLabel("Use Custom Qty")
	moduleContainer:AddChild(cbUseCustomQty)

	cbUseCustomQty:SetCallback("OnValueChanged", function(cb)
		AuctionatorTools.db.profile.Selling.ImprovedQuantity.useCustomQty = cb:GetValue()
		Debug("New value for useCustomQty ", cb:GetValue())
	end)


	container:AddChild(moduleContainer)
end

function ImprovedQuantity.GetSetting(settingName)
	return AuctionatorTools.db.profile.Selling.ImprovedQuantity
			[settingName]
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

function ImprovedQuantity.GetSavedQuantity(itemID)
	local qtyDB = AuctionatorTools.db.global.quantity
	if qtyDB and itemID then
		return qtyDB[itemID]
	end
end

function ImprovedQuantity.InjectToAuctionator(originalMixin)
	local OnShow_org = originalMixin.OnShow

	function AuctionatorSaleItemMixin:OnShow()
		OnShow_org(self)

		self:CreateSaveQtyButton()
	end

	-------------------------------------------------
	function AuctionatorSaleItemMixin:CreateSaveQtyButton()
		Debug("Creating save quantity button")
		-- Create save button
		local maxButton = self.MaxButton

		if not maxButton then
			Debug("Max button not found")
		else
			if self.SaveButton then
				Debug("Save button already exists")
				return
			end
			self.SaveButton = CreateFrame("Button", "SaveQtyButton", self, "UIPanelButtonTemplate")
			self.SaveButton:SetSize(130, 25)
			self.SaveButton:SetPoint("BOTTOMLEFT", maxButton, "TOP", 0, 5)
			self.SaveButton:SetText("Save Quantity")
			self.SaveButton:RegisterForClicks("AnyUp", "AnyDown")
			self.SaveButton:SetScript("OnClick", function(_, button, down)
				local currentQuantity = self.Quantity:GetNumber()
				local currentItemID = self.itemInfo.itemID

				if currentQuantity and currentItemID then
					local result = ImprovedQuantity.SaveQuantity(currentItemID, currentQuantity)
					if down then
						self.SaveButton:SetText((result and "Saved") or ("Failed"))
					else
						self.SaveButton:SetText("Saved Qty - " .. currentQuantity)
					end
				end
			end)
		end
	end

	----------------------------------------------------------

	-- Set quantity logic
	local SetQuantity_org = originalMixin.SetQuantity
	function AuctionatorSaleItemMixin:SetQuantity()
		if not self.itemInfo then return end
		local itemID = self.itemInfo.itemID
		local customQuantity = self.itemInfo and SkipLogic:GetSavedQuantity(self.itemInfo)

		if customQuantity then
			self.SaveButton:SetText("Saved Qty - " .. customQuantity)
			local result = self:GetCommodityResult(itemID)
			Debug("checking if undercutted for" .. itemID)
			if result and result.containsOwnerItem and result.owners[1] == "player" and AuctionatorTools.db.profile.Selling.ImprovedSkip.restockEnabled then
				Debug("Auction not undercutted")
				self.Quantity:SetNumber(customQuantity - result.quantity)
			else
				self.Quantity:SetNumber(customQuantity)
			end
		else
			self.SaveButton:SetText("Save Quantity")
			SetQuantity_org(self)
		end
	end
end

addonNS.ImprovedQuantity = ImprovedQuantity
