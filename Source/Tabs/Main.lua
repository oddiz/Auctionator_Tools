local AceGUI = LibStub:GetLibrary("AceGUI-3.0")
local AT = AuctionatorTools

local tabs = {
	{ text = "Shopping", value = "shopping", content = ATShoppingTab },
	{ text = "Selling",  value = "selling",  content = ATSellingTab },
	{ text = "Options",  value = "options",  content = ATOptionsTab }
}
function AT.Tabs:Init(parent)
	--- Create Tabs ---
	local tabGroup = AceGUI:Create("TabGroup")
	tabGroup:SetLayout("Flow")
	tabGroup:SetTabs(tabs)

	tabGroup:SetCallback("OnGroupSelected", function(container, _, group)
		AT.Tabs:SelectGroup(container, group)
	end)

	parent:AddChild(tabGroup)

	tabGroup:SelectTab("shopping")
end

function AT.Tabs:SelectGroup(container, group)
	container:ReleaseChildren()
	for _, tab in ipairs(tabs) do
		if tab.value == group then
			tab.content:Init(container)
			container:DoLayout()

			break
		end
	end
end
