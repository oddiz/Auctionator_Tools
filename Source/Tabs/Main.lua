local AceGUI = LibStub:GetLibrary("AceGUI-3.0")
local AT = AuctionatorTools

local tabs = {
	{ text = "Shopping", value = "shopping", content = ATShoppingTab },
	{ text = "Selling",  value = "selling",  content = ATSellingTab },
	{ text = "Options",  value = "options",  content = ATOptionsTab }
}

local function SelectGroup(container, event, group)
	container:ReleaseChildren()
	for _, tab in ipairs(tabs) do
		if tab.value == group then
			tab.content:Init(container)

			break
		end
	end
end
function AT.Tabs:Init(parent)
	--- Create Tabs ---
	local tabGroup = AceGUI:Create("TabGroup")
	tabGroup:SetLayout("Flow")
	tabGroup:SetTabs(tabs)

	tabGroup:SetCallback("OnGroupSelected", SelectGroup)

	parent:AddChild(tabGroup)

	tabGroup:SelectTab("shopping")
end
