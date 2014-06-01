-----------------------------------------------------------------------------------------------
-- Client Lua Script for CraftingResume
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"

local CraftingResume = {}

local knSaveVersion = 0

function CraftingResume:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function CraftingResume:Init()
    Apollo.RegisterAddon(self)
end

function CraftingResume:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end

	local locWindowlocation = self.wndMain and self.wndMain:GetLocation() or self.locSavedWindowLoc

	local tSave =
	{
		tWindowLocation = locWindowlocation and locWindowlocation:ToTable() or nil,
		nSaveVersion = knSaveVersion,
	}

	return tSave
end

function CraftingResume:OnRestore(eType, tSavedData)
	if tSavedData and tSavedData.nSaveVersion then
		if tSavedData.tWindowLocation then
			self.locSavedWindowLoc = WindowLocation.new(tSavedData.tWindowLocation)
		end
	end
end

function CraftingResume:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("CraftingResume.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function CraftingResume:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	Apollo.RegisterEventHandler("GenericEvent_CraftFromPL", 		"OnGenericEvent_CraftFromPL", self)
	Apollo.RegisterEventHandler("TradeskillEngravingStationOpen", 	"OnInvokeEngravingWindow", self) -- Opening from in game station
	Apollo.RegisterEventHandler("InvokeCraftingWindow", 			"OnInvokeCraftingWindow", self) -- Opening from in game station
	self.bCraftingStation = true
end

function CraftingResume:OnInvokeEngravingWindow()
	-- If there is a current craft, right clicking the station opens to the craft instead of the schematic list
	if GameLib.GetPlayerUnit():IsCasting() then
		return
	end

	self.bCraftingStation = false

	local tCurrentCraft = CraftingLib.GetCurrentCraft()
	if tCurrentCraft and tCurrentCraft.nSchematicId ~= 0 then
		Event_FireGenericEvent("GenericEvent_CraftFromPL", tCurrentCraft.nSchematicId)
	else
		Event_FireGenericEvent("GenericEvent_CraftingResume_CloseCraftingWindows")
		Event_FireGenericEvent("GenericEvent_CraftingResume_OpenEngraving")
	end
end

function CraftingResume:OnInvokeCraftingWindow()
	-- If there is a current craft, right clicking the station opens to the craft instead of the schematic list
	if GameLib.GetPlayerUnit():IsCasting() then
		return
	end

	self.bCraftingStation = true

	local tCurrentCraft = CraftingLib.GetCurrentCraft()
	if tCurrentCraft and tCurrentCraft.nSchematicId ~= 0 then -- TODO: Also filter by crafting station capabilities
		Event_FireGenericEvent("GenericEvent_CraftFromPL", tCurrentCraft.nSchematicId)
	else
		Event_FireGenericEvent("AlwaysShowTradeskills")
	end
end

function CraftingResume:OnGenericEvent_CraftFromPL(idQueuedSchematic)
	if GameLib.GetPlayerUnit():IsCasting() then
		return
	end

	if self.wndMain and self.wndMain:IsValid() then
		self.locSavedWindowLoc = self.wndMain:GetLocation()
		self.wndMain:Destroy()
	end

	local tCurrentCraft = CraftingLib.GetCurrentCraft()
	if tCurrentCraft and tCurrentCraft.nSchematicId ~= 0 then
		local tSchematicInfo = CraftingLib.GetSchematicInfo(tCurrentCraft.nSchematicId)
		self.wndMain = Apollo.LoadForm(self.xmlDoc , "CraftingResumeForm", nil, self)
		self.wndMain:FindChild("CoordPrevAbandonBtn"):SetData(idQueuedSchematic)
		self.wndMain:FindChild("CoordPrevFinishOldBtn"):SetData(tCurrentCraft.nSchematicId)
		self.wndMain:FindChild("CoordPrevFinishOldBtn"):Enable(self.bCraftingStation)
		self.wndMain:FindChild("CoordPrevWindowPopupOldName"):SetText(tSchematicInfo.strName)
		self.wndMain:FindChild("CoordPrevWindowPopupOldIcon"):SetSprite(tSchematicInfo.itemOutput:GetIcon())
		Tooltip.GetItemTooltipForm(self, self.wndMain:FindChild("CoordPrevWindowPopupOldIcon"), tSchematicInfo.itemOutput, {bPrimary = true, bSelling = false})

		-- Build materials list
		self.wndMain:FindChild("CoordPrevWindowMaterials"):DestroyChildren()
		for idx, tMaterial in pairs(tSchematicInfo.tMaterials) do
			local wndNoMaterials = Apollo.LoadForm(self.xmlDoc, "CoordPrevMaterialItem", self.wndMain:FindChild("CoordPrevWindowMaterials"), self)
			wndNoMaterials:FindChild("CoordPrevMaterialIcon"):SetText(tMaterial.nAmount)
			wndNoMaterials:FindChild("CoordPrevMaterialIcon"):SetSprite(tMaterial.itemMaterial:GetIcon())
			Tooltip.GetItemTooltipForm(self, wndNoMaterials, tMaterial.itemMaterial, {bPrimary = true, bSelling = false})
		end
		self.wndMain:FindChild("CoordPrevWindowMaterials"):ArrangeChildrenHorz(0)
		self.wndMain:Invoke()

		if self.locSavedWindowLoc then
			self.wndMain:MoveToLocation(self.locSavedWindowLoc)
		end
	else
		self:HelperStartCraft(idQueuedSchematic)
	end
end

function CraftingResume:OnCoordPrevFinishOldBtn(wndHandler, wndControl) -- CoordPrevFinishOldBtn, data is idQueuedSchematic
	self:HelperStartCraft(wndHandler:GetData())
	self.locSavedWindowLoc = self.wndMain:GetLocation()
	self.wndMain:Destroy()
end

function CraftingResume:OnCoordPrevAbandonBtn(wndHandler, wndControl) -- CoordPrevAbandonBtn
	if self.bCraftingStation then
		Event_FireGenericEvent("AlwaysShowTradeskills")
	else
		Event_FireGenericEvent("GenericEvent_CraftingResume_OpenEngraving")
	end

	Event_FireGenericEvent("GenericEvent_LootChannelMessage", Apollo.GetString("CraftingResume_Abandon"))
	Event_FireGenericEvent("GenericEvent_BotchCraft")
	CraftingLib.BotchCraft()
	self.locSavedWindowLoc = self.wndMain:GetLocation()
	self.wndMain:Destroy()
end

function CraftingResume:HelperStartCraft(idSchematic)
	if not idSchematic then
		return
	end

	local tSchematicInfo = CraftingLib.GetSchematicInfo(idSchematic)
	if not tSchematicInfo then
		return
	end

	local tTradeskillInfo = CraftingLib.GetTradeskillInfo(tSchematicInfo.eTradeskillId)
	if tTradeskillInfo.bIsCoordinateCrafting then
		Event_FireGenericEvent("GenericEvent_StartCraftingGrid", idSchematic)
	elseif tTradeskillInfo.bIsCircuitBoardCrafting then
		Event_FireGenericEvent("GenericEvent_StartCircuitCraft", idSchematic)
	end
	Event_FireGenericEvent("GenericEvent_CraftingResume_CloseEngraving")
end

function CraftingResume:OnWindowClosed()
	self.locSavedWindowLoc = self.wndMain:GetLocation()
	self.wndMain:Destroy()
	self.bCraftingStation = true
end

local CraftingResumeInst = CraftingResume:new()
CraftingResumeInst:Init()
