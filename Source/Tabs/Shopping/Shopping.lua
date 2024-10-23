local AceGUI = LibStub:GetLibrary("AceGUI-3.0")
ATShoppingTab = {}

ATShoppingTab.Modules = {

	ExportModule,

}

function ATShoppingTab:Init(container)
	self.frame = AceGUI:Create("SimpleGroup")
	self.frame:SetLayout("List")
	self.frame:SetFullWidth(true)
	self.frame:SetFullHeight(true)

	container:AddChild(self.frame)
	for _, module in ipairs(self.Modules) do
		local moduleFrame = module:Init()
		self.frame:AddChild(moduleFrame)
	end

	return self
end
