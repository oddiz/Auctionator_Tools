local AceGUI = LibStub:GetLibrary("AceGUI-3.0")

ATSellingTab = {}

ATSellingTab.Modules = {



}

function ATSellingTab:Init(container)
	self.frame = AceGUI:Create("SimpleGroup")
	self.frame:SetLayout("Flow")
	self.frame:SetFullWidth(true)
	self.frame:SetFullHeight(true)
	container:AddChild(self.frame)
end
