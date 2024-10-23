local AceGUI = LibStub:GetLibrary("AceGUI-3.0")
local AceEvent = LibStub:GetLibrary("AceEvent-3.0")








function CreateATModule(title)
	local container = AceGUI:Create("InlineGroup")
	container:SetTitle(title)
	container:SetLayout("Flow")
	container:SetFullWidth(true)
	AceEvent:Embed(container)

	return container
end
