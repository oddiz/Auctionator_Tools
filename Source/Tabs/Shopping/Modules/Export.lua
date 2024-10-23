local AceGUI = LibStub:GetLibrary("AceGUI-3.0")
local AceEvent = LibStub:GetLibrary("AceEvent-3.0")

--TODO: Add custom top X price for mean price
local searchPool = CreateObjectPool(
	function(pool)
		local f = CreateFrame("Frame")
		f = AceEvent:Embed(f)
		f.searchList = {}
		f.resultList = {}

		f.exportWindow = AceGUI:Create("Window")
		f.exportWindow:SetWidth(200)
		f.exportWindow:SetHeight(200)
		f.exportWindow:SetLayout("Fill")
		f.editBox = AceGUI:Create("MultiLineEditBox")
		f.exportWindow:AddChild(f.editBox)
		f.editBox:SetFullWidth(true)
		f.editBox:SetFullWidth(true)

		f.editBox:SetLabel("Copy export output")
		f.exportWindow:SetCallback("OnClose", function() f.abortSearch() end)

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

		f.addResults =
				function(results)
					for _, itemInfo in ipairs(results) do
						f.searchList[itemInfo.itemKey.itemID] = itemInfo
					end
				end

		f.abortSearch = function()
			pool:ReleaseAll()
		end
		f.search =
				function(callback)
					local searchAmount = AhTools_TableLength(f.searchList)
					f.SetExportText("Getting info: 0/" .. searchAmount)
					local processResults = function(msg)
						if msg.success == 1 then
							local msgData = msg.data
							local msgItemID = msgData[1]
							local msgAuctionData = msgData[2]
							local meanPrice = AhTools_CalculateMean(msgAuctionData)
							if f.searchList[msgItemID] then
								f.resultList[msgItemID] = f.searchList[msgItemID]
								f.resultList[msgItemID]["meanPrice"] = meanPrice
							end
						end
						local resultAmount = AhTools_TableLength(f.resultList)
						f.SetExportText(string.format("Getting info: %i/%i", resultAmount, searchAmount))
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


---@class ExportModule: AtModule
ExportModule = AtModule:New("Export Module")
function ExportModule:Init()
	local button = AceGUI:Create("Button")
	button:SetText("Export Results")
	button:SetHeight(25)
	button:SetCallback("OnClick", function(w)
		searchPool:ReleaseAll()
		self:ExportSearchResults()
	end)

	self.container:AddChild(button)

	return self.container
end

function ExportModule:ExportSearchResults()
	local results = self:GetAuctionatorResults()
	if (#results > 0) then
		local newSearch = searchPool:Acquire()

		newSearch.addResults(results)

		newSearch.search(
			function(results)
				local exportString = ExportModule:CreateExportString(results)

				newSearch.SetExportText(exportString)
			end)
	end
end

function ExportModule:GetAuctionatorResults()
	if not AuctionatorShoppingFrame then
		print("Shopping frame not found")
	end

	return AuctionatorShoppingFrame.ResultsListing.dataProvider.results
end

function ExportModule:CreateExportString(results)
	local text = ""

	-- Header
	text = '"Price","Name","ItemID"' .. "\n"

	for itemID, itemInfo in pairs(results) do
		local itemName = itemInfo.name or "Unknown Item" -- Get just the name
		local itemText = string.format('"%s","%s","%s"',
			tostring(itemInfo.meanPrice),
			itemName,
			tostring(itemID)
		)
		text = text .. itemText .. "\n"
		cla(itemInfo)
	end
	return text
end
