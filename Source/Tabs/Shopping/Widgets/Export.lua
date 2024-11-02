local AceGUI = LibStub:GetLibrary("AceGUI-3.0")
local AceEvent = LibStub:GetLibrary("AceEvent-3.0")

local _, addonNS = ...

local ExportWidget = {}
--TODO: Add custom top X price for mean price
ExportWidget.searchPool = CreateObjectPool(
	function(pool)
		local f = CreateFrame("Frame")
		f = AceEvent:Embed(f)
		f.searchList = {}
		f.resultList = {}
		f.exportWindow = AceGUI:Create("Window")
		f.exportWindow:SetWidth(600)
		f.exportWindow:SetHeight(600)
		f.exportWindow:SetLayout("Fill")

		f.editBox = AceGUI:Create("MultiLineEditBox")
		f.exportWindow:AddChild(f.editBox)
		f.editBox:SetFullWidth(true)
		f.editBox:SetFullWidth(true)

		f.editBox:SetLabel("Copy export output")
		f.exportWindow:SetCallback("OnClose", function() pool:ReleaseAll() end)

		f.exportWindow:Hide()
		f.SetExportText = function(string)
			if not f.exportWindow:IsShown() then
				f.exportWindow:Show()
			end
			f.editBox:SetText(string)
		end
		f.isSearchDone = function()
			local size = AhTools_TableLength
			return size(f.searchList) == size(f.resultList)
		end

		f.addSearchItems =
				function(results)
					for _, itemInfo in ipairs(results) do
						f.searchList[itemInfo.itemKey.itemID] = itemInfo
					end
				end


		f.search =
				function(callback)
					local searchAmount = AhTools_TableLength(f.searchList)
					f.SetExportText("Getting info: 0/" ..
						searchAmount .. "\n" .. "Using Mean quantity: " .. AuctionatorTools.db.profile.Shopping.meanQty)
					local processResults = function(msg)
						if msg.success == 1 then
							local msgData = msg.data
							local msgItemID = msgData[1]
							local msgAuctionData = msgData[2]
							local meanPrice = AhTools_CalculateMean(msgAuctionData, AuctionatorTools.db.profile.Shopping.meanQty)
							if f.searchList[msgItemID] and meanPrice then
								f.resultList[msgItemID] = f.searchList[msgItemID]
								f.resultList[msgItemID]["meanPrice"] = meanPrice
							end
						end
						local resultAmount = AhTools_TableLength(f.resultList)
						f.SetExportText(string.format("Getting info: %i/%i \n Using Mean quantity: %s", resultAmount, searchAmount,
							AuctionatorTools.db.profile.Shopping.meanQty))
						if f.isSearchDone() then
							callback(f.resultList)
						end
					end
					f:RegisterMessage("ahmanager_result",
						function(event, msg)
							processResults(msg)
						end
					)
					for itemID, _ in pairs(f.searchList) do
						f:SendMessage("search_commodity", itemID)
					end
				end
		return f
	end,
	function(_, frame)
		frame.searchList = {}
		frame.resultList = {}
		frame:UnregisterAllMessages()
	end
)



function ExportWidget:DrawWidget(container)
	local moduleContainer = addonNS.CreateATWidget("Proper Export")
	local groupMeanQtyOptions = AceGUI:Create("SimpleGroup")
	groupMeanQtyOptions:SetFullWidth(true)
	groupMeanQtyOptions:SetLayout("Flow")

	local labelMeanQty = AceGUI:Create("InteractiveLabel")
	labelMeanQty:SetText("Item Qty for Mean Price:")
	labelMeanQty:SetWidth(150)


	local eBoxMeanQty = AceGUI:Create("EditBox")
	eBoxMeanQty:SetWidth(100)
	eBoxMeanQty:SetText(AuctionatorTools.db.profile.Shopping.meanQty)
	eBoxMeanQty:SetCallback("OnTextChanged", function(w, event, value)
		--  only allow numbers, dont allow inputs other than numbers
		local prevNumber = tonumber(AuctionatorTools.db.profile.Shopping.meanQty)
		local newValue = tonumber(value)
		if newValue and newValue > 0 then
			AuctionatorTools.db.profile.Shopping.meanQty = newValue
		else
			eBoxMeanQty:SetText(prevNumber)
		end
	end)
	eBoxMeanQty:SetCallback("OnEnterPressed", function(w, event, value)
		local value = tonumber(value)
		if value then
			AuctionatorTools.db.profile.Shopping.meanQty = value
		end
	end)

	groupMeanQtyOptions:AddChild(labelMeanQty)
	groupMeanQtyOptions:AddChild(eBoxMeanQty)

	local button = AceGUI:Create("Button")
	button:SetText("Export Results")
	button:SetHeight(25)
	button:SetCallback("OnClick", function(w)
		self.searchPool:ReleaseAll()
		self:ExportSearchResults()
	end)

	moduleContainer:AddChild(groupMeanQtyOptions)
	moduleContainer:AddChild(button)
	container:AddChild(moduleContainer)
end

function ExportWidget:ExportSearchResults()
	local results = self:GetAuctionatorResults()
	if (#results > 0) then
		local newSearch = self.searchPool:Acquire()

		newSearch.addSearchItems(results)

		newSearch.search(
			function(results)
				local exportString = ExportWidget:CreateExportString(results)

				newSearch.SetExportText(exportString)
				newSearch.editBox:SetFocus()
				newSearch.editBox:HighlightText(0, string.len(exportString) - 1)
			end)
	end
end

function ExportWidget:GetAuctionatorResults()
	if not AuctionatorShoppingFrame then
		print("Shopping frame not found")
	end


	return AuctionatorShoppingFrame.ResultsListing.dataProvider.results
end

function ExportWidget:CreateExportString(results)
	-- Create a table for sorting
	local sortableResults = {}

	-- Convert the key-value pairs to a sortable array
	for itemID, itemInfo in pairs(results) do
		table.insert(sortableResults, {
			id = itemID,
			info = itemInfo,
			name = itemInfo.name or "Unknown Item"
		})
	end

	-- Sort the table alphabetically by name
	table.sort(sortableResults, function(a, b)
		return a.name:lower() < b.name:lower()
	end)

	local text = ""

	-- Header
	text = '"Price","Name","ItemID"' .. "\n"

	for _, item in ipairs(sortableResults) do
		local itemText = string.format('"%s","%s","%s"',
			tostring(item.info.meanPrice),
			item.name,
			tostring(item.id)
		)
		text = text .. itemText .. "\n"
	end

	return text
end

addonNS.ExportWidget = ExportWidget
