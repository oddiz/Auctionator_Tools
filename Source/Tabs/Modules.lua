local AceGUI = LibStub:GetLibrary("AceGUI-3.0")
local AceEvent = LibStub:GetLibrary("AceEvent-3.0")

---@class AtModule
AtModule = {}




function AtModule:GetWidget()
	return self.container
end

function AtModule:AddChild(widget)
	self.container:AddChild(widget)
end

function AtModule:New(title)
	local o = {}
	setmetatable(o, self)
	o.__index = self

	local container = AceGUI:Create("InlineGroup")
	container:SetTitle(title)
	container:SetLayout("Flow")
	container:SetFullWidth(true)
	AceEvent:Embed(container)

	o.container = container
	return o
end
