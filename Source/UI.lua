local AceGUI = LibStub:GetLibrary("AceGUI-3.0")
local AT = AuctionatorTools

function AT:CreateMainFrame()
	if self.mainFrame then
		return
	end
	local f = {}

	f = AceGUI:Create("Frame")
	f:SetTitle("Auctionator Helper")
	f:SetStatusText("Useful utilities that will enchance goblin experience - made by oddiz")
	f:SetWidth(400)
	f:SetHeight(400)
	f:SetLayout("Fill")
	self.Tabs:Init(f)

	self.mainFrame = f
end

function AT:CreateToggleButtons()
	local auctionFrame = _G["AuctionHouseFrame"]
	if not auctionFrame then
		print("Auction House frame not found!")
		return
	end

	if self.toggleButton then return end

	local toggleButton = CreateFrame("Button", "ATToggleButton", auctionFrame, "UIPanelButtonTemplate")
	toggleButton:SetSize(100, 25)
	toggleButton:SetPoint("TOP", auctionFrame, "TOP", 0, 60)
	toggleButton:SetText("Tools")
	toggleButton:SetScript("OnClick", function() AT:ToggleMainFrame() end)
	self.toggleButton = toggleButton
end

function AT:ToggleMainFrame()
	if self.mainFrame then
		if self.mainFrame:IsShown() then self.mainFrame:Hide() else self.mainFrame:Show() end
	end
end
