local _, addonNS = ...
local AceGUI = LibStub:GetLibrary("AceGUI-3.0")
local ImprovedQuantity = {}

local Debug = AuctionatorTools.Debug.Message
local function restockQtyLabel()
	local undercutSkipActive = AuctionatorTools.db.profile.Selling.ImprovedSkip.skipIfLeadSeller or false
	if undercutSkipActive then
		return {
			label = RED_FONT_COLOR:WrapTextInColorCode("Restock posted auction"),
			desc = GRAY_FONT_COLOR:WrapTextInColorCode("Disabled: Skipping non-undercutted auctions)")
		}
	else
		return {
			label = "Restock posted auction",
			desc = ""
		}
	end
end
function ImprovedQuantity:DrawWidget(container)
	self.widgetSettings = AuctionatorTools.db.profile.Selling.ImprovedQuantity
	local moduleContainer = addonNS.CreateATWidget("Improved Quantity")

	local cbRestock = AceGUI:Create("CheckBox")
	cbRestock:SetValue(self.widgetSettings.restockQty or false)
	cbRestock:SetFullHeight(true)

	moduleContainer:AddChild(cbRestock)

	container:AddChild(moduleContainer)

	cbRestock:SetCallback("OnValueChanged", function(cb)
		ImprovedQuantity.widgetSettings.restockQty = cb:GetValue()
		Debug("New value for restockQty ", ImprovedQuantity.GetSetting("restockQty"))
		self.updateCbRestockLabel()
	end)
	self.updateCbRestockLabel = function()
		cbRestock:SetLabel(restockQtyLabel().label)
		cbRestock:SetDescription(restockQtyLabel().desc)
	end
	self.updateCbRestockLabel()
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

function ImprovedQuantity.GetQuantity(itemID)
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
						self.SaveButton:SetText("Save Quantity - " .. currentQuantity)
					end
				end
			end)
		end
	end

	----------------------------------------------------------

	-- Set quantity logic
	local SetQuantity_org = originalMixin.SetQuantity
	function AuctionatorSaleItemMixin:SetQuantity()
		local itemID = self.itemInfo.itemID
		local customQuantity = itemID and ImprovedQuantity.GetQuantity(itemID)

		if customQuantity then
			self.SaveButton:SetText("Save Quantity - " .. customQuantity)
			local result = self:GetCommodityResult(itemID)
			Debug("checking if undercutted for" .. itemID)
			if result and result.containsOwnerItem and result.owners[1] == "player" and ImprovedQuantity.widgetSettings.restockQty then
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
