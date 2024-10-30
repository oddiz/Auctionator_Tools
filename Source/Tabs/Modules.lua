local AceGUI = LibStub:GetLibrary("AceGUI-3.0")
local AceEvent = LibStub:GetLibrary("AceEvent-3.0")
local _, addonNS = ...


function addonNS.CreateATTAb(container, name, widgets)
	local tabContent = {
		text = name,
		value = string.lower(name),
		Widgets = widgets,
		frame = nil
	}


	local frame = AceGUI:Create("SimpleGroup")
	frame:SetLayout("List")
	frame:SetFullWidth(true)
	frame:SetFullHeight(true)

	container:AddChild(frame)

	tabContent.frame = frame

	function tabContent:Init()
		if #self.Widgets > 0 then
			for _, widget in ipairs(self.Widgets) do
				widget:DrawWidget(frame)
			end
		end
	end

	return tabContent
end

function addonNS.CreateATWidget(title)
	local container = AceGUI:Create("InlineGroup")
	container:SetTitle(title)
	container:SetLayout("Flow")
	container:SetFullWidth(true)
	AceEvent:Embed(container)

	return container
end
