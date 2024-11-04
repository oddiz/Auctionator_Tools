local _, addonNS = ...
local AceGUI = LibStub:GetLibrary("AceGUI-3.0")
local DebugWidget = {}


function DebugWidget:DrawWidget(container)
	local Debug = addonNS.Debug
	local DebugOn = Debug.IsOn()

	local DebugToggle = AceGUI:Create("CheckBox")
	DebugToggle:SetLabel("Debug")
	DebugToggle:SetValue(DebugOn)
	DebugToggle:SetFullWidth(true)
	DebugToggle:SetCallback("OnValueChanged", function(cb)
		Debug.SetOn(cb:GetValue())
	end)
	container:AddChild(DebugToggle)
end

addonNS.DebugWidget = DebugWidget
