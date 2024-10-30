local AceGUI = LibStub:GetLibrary("AceGUI-3.0")
local _, addonNS = ...
ATSellingTab = {}

ATSellingTab.Widgets = {

	addonNS.ImprovedSkip,

}

function ATSellingTab:Init(container)
	local frame = AceGUI:Create("SimpleGroup")
	frame:SetLayout("List")
	frame:SetFullWidth(true)
	frame:SetFullHeight(true)

	for _, widget in ipairs(self.Widgets) do
		widget:DrawWidget(frame)
	end

	container:AddChild(frame)
end
