local _, addonNS = ...
local AceGUI = LibStub:GetLibrary("AceGUI-3.0")
local ImprovedSkip = {}

local Debug = addonNS.Debug.Message

local function skipIfLeadSellerLabel(skipEnabled)
	if skipEnabled then
		return "Skip if you are the lead seller"
	else
		return "Refresh until undercut"
	end
end

function ImprovedSkip:DrawWidget(container)
	local SkipLogicModule = AuctionatorTools:GetModule("SkipLogic")

	local moduleContainer = addonNS.CreateATWidget("Improved Skip")
	--------------------------------------------
	local cbMasterSwitch = AceGUI:Create("CheckBox")
	cbMasterSwitch:SetLabel("Master switch")
	cbMasterSwitch:SetValue(SkipLogicModule:GetSetting("masterSwitch") or false)
	cbMasterSwitch:SetFullWidth(true)
	--------------------------------------------

	local preference = SkipLogicModule:GetSetting("preference")
	local cbProcessUndercut = AceGUI:Create("CheckBox")
	cbProcessUndercut:SetLabel("Act on undercut items")
	cbProcessUndercut:SetValue(SkipLogicModule:GetSetting("processUndercut") or false)
	cbProcessUndercut:SetLabel(string.format("%s on undercut items",
		GREEN_FONT_COLOR:WrapTextInColorCode(preference)))
	cbProcessUndercut:SetFullWidth(true)
	--------------------------------------------

	local restockGroup = AceGUI:Create("SimpleGroup")
	restockGroup:SetLayout("Flow")
	restockGroup:SetFullWidth(true)
	local cbRestockEnabled = AceGUI:Create("CheckBox")
	cbRestockEnabled:SetValue(SkipLogicModule:GetSetting("restockEnabled") or false)
	cbRestockEnabled:SetRelativeWidth(0.3)
	cbRestockEnabled:SetLabel("Restock")

	cbRestockEnabled:SetCallback("OnValueChanged", function(cb)
		ImprovedSkip.widgetSettings.restockEnabled = cb:GetValue()
		Debug("New value for restockEnabled ", SkipLogicModule:GetSetting("restockEnabled"))
	end)

	local sliderRestock = AceGUI:Create("Slider")
	sliderRestock:SetRelativeWidth(0.7)
	sliderRestock:SetSliderValues(0, 1, 0.01)
	sliderRestock:SetIsPercent(true)
	sliderRestock:SetValue(SkipLogicModule:GetSetting("restockThreshold"))
	sliderRestock:SetDisabled(not SkipLogicModule:GetSetting("restockEnabled"))

	restockGroup:AddChild(cbRestockEnabled)
	restockGroup:AddChild(sliderRestock)
	--------------------------------------------

	local groupSelectAction = AceGUI:Create("InlineGroup")
	groupSelectAction:SetFullWidth(true)
	groupSelectAction:SetLayout("Flow")
	groupSelectAction:SetTitle("Select action")

	local function getActionPref()
		return SkipLogicModule:GetSetting("preference")
	end



	local radioSkip = AceGUI:Create("CheckBox")
	radioSkip:SetType("radio")
	radioSkip:SetLabel("Skip")
	radioSkip:SetValue(getActionPref() == "SKIP")
	radioSkip:SetRelativeWidth(0.5)

	local radioRefresh = AceGUI:Create("CheckBox")
	radioRefresh:SetType("radio")
	radioRefresh:SetLabel("Refresh")
	radioRefresh:SetValue(getActionPref() == "REFRESH")
	radioRefresh:SetRelativeWidth(0.5)

	local function handleSelect(type)
		if type == "SKIP" then
			SkipLogicModule:SetSetting("preference", "SKIP")
			radioSkip:SetValue(true)
			radioRefresh:SetValue(false)
		elseif type == "REFRESH" then
			SkipLogicModule:SetSetting("preference", "REFRESH")
			radioSkip:SetValue(false)
			radioRefresh:SetValue(true)
		end
		Debug("New value for preference ", SkipLogicModule:GetSetting("preference"))
		cbProcessUndercut:SetLabel(string.format("%s on undercut items", GREEN_FONT_COLOR:WrapTextInColorCode(type)))
	end

	radioSkip:SetCallback("OnValueChanged", function() handleSelect("SKIP") end)
	radioRefresh:SetCallback("OnValueChanged", function() handleSelect("REFRESH") end)
	groupSelectAction:AddChild(radioSkip)
	groupSelectAction:AddChild(radioRefresh)

	--------------------------------------------
	moduleContainer:AddChild(cbMasterSwitch)
	moduleContainer:AddChild(cbProcessUndercut)
	moduleContainer:AddChild(restockGroup)
	moduleContainer:AddChild(groupSelectAction)

	container:AddChild(moduleContainer)

	cbMasterSwitch:SetCallback("OnValueChanged", function(cb)
		SkipLogicModule:SetSetting("masterSwitch", cb:GetValue())
		Debug("New value for masterSwitch ", SkipLogicModule:GetSetting("masterSwitch"))
	end)
	cbProcessUndercut:SetCallback("OnValueChanged", function(cb)
		SkipLogicModule:SetSetting("processNonUndercut", cb:GetValue())
		Debug("New value for processNonUndercut ", SkipLogicModule:GetSetting("processUndercut"))
	end)
	cbRestockEnabled:SetCallback("OnValueChanged",
		function(cb)
			SkipLogicModule:SetSetting("restockEnabled", cb:GetValue())
			Debug("New value for restockEnabled ", SkipLogicModule:GetSetting("restockEnabled"))

			sliderRestock:SetDisabled(not SkipLogicModule:GetSetting("restockEnabled"))
		end)
	sliderRestock:SetCallback("OnMouseUp", function(_, _, value)
		SkipLogicModule:SetSetting("restockThreshold", value)
		Debug("New value for restockThreshold ", SkipLogicModule:GetSetting("restockThreshold"))
	end)
end

addonNS.ImprovedSkip = ImprovedSkip
