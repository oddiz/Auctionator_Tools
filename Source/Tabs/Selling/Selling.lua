local AceGUI = LibStub:GetLibrary("AceGUI-3.0")
local _, addonNS = ...
ATSellingTab = {}

ATSellingTab.Widgets = {

	addonNS.ImprovedSkip,
	addonNS.ImprovedQuantity

}

function ATSellingTab:Init(container)
	local frame = AceGUI:Create("SimpleGroup")
	frame:SetLayout("List")
	frame:SetFullWidth(true)
	frame:SetFullHeight(true)

	for _, widget in ipairs(self.Widgets) do
		if widget.DrawWidget then
			widget:DrawWidget(frame)
		end
	end

	container:AddChild(frame)
end
