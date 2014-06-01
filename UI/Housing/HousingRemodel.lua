-----------------------------------------------------------------------------------------------
-- Client Lua Script for HousingRemodel
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "HousingLib"

-----------------------------------------------------------------------------------------------
-- HousingRemodel Module Definition
-----------------------------------------------------------------------------------------------
local HousingRemodel 		= {}
local RemodelPreviewControl = {}
local RemodelPreviewItem 	= {}

---------------------------------------------------------------------------------------------------
-- global
---------------------------------------------------------------------------------------------------
local gidZone 				= 0
local gtRemodelTrueValues = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local knExtRemodelTabs 		= 5
local knIntRemodelTabs 		= 5

local kcrDarkBlue 	= CColor.new(47/255,148/255,172/255,1.0)
--local kBrightBlue = CColor.new(49/255,252/255,246/255,1.0)
local kcrWhite 		= CColor.new(1.0,1.0,1.0,1.0)
local kcrDisabled 	= CColor.new(0.13,0.33,0.37,1.0)

local ktTypeStrings =
{
	["Roof"]			= "HousingRemodel_Roof", 
	["Wallpaper"] 		= "Housing_Wallpaper", 
	["Entry"] 			= "HousingRemodel_Entry", 
	["Door"] 			= "HousingRemodel_Door", 
	["Sky"]				= "HousingRemodel_Sky",
    ["IntWallpaper"] 	= "Housing_Wallpaper", 
	["Floor"] 			= "HousingRemodel_Floor", 
	["Ceiling"]			= "CRB_CEILING", 
	["Trim"] 			= "HousingRemodel_Trim", 
	["Lighting"] 		= "HousingRemodel_Lighting",
}
 ---------------------------------------------------------------------------------------------------
-- RemodelPreviewControl methods
---------------------------------------------------------------------------------------------------
function RemodelPreviewControl:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.eType 				= nil
	o.tRemodelPreviewItems 	= {}
	o.wndRemodelTotalCostML = nil
	o.wndRemodelTotalCostCash = nil
	o.wndAcceptBtn 			= nil
	o.wndCancelBtn 			= nil

	return o
end

function RemodelPreviewControl:OnLoad(strPreviewType, wndParentFrame, wndParent, tChildNamesList)
	self.strType = strPreviewType;

	local tBakedList = {}
	if self.strType == "exterior" then
		tBakedList = HousingLib.GetBakedDecorDetails()
	else
		-- "interior" items aren't on a baked list
		--  this loading process will set them up w/ default text/colors
	end

	-- loop through the names given, and create list entries with the name as the key
	for idx = 1, #tChildNamesList do
		self.tRemodelPreviewItems[idx] = RemodelPreviewItem:new()
		self.tRemodelPreviewItems[idx]:OnLoad(wndParentFrame, tBakedList[idx], tChildNamesList[idx])
	end

	self.wndRemodelTotalCostML 		= wndParent:FindChild("RemodelPreviewTotalCost")
	self.wndRemodelTotalCostCash 	= wndParent:FindChild("RemodelPreviewCashWindow")
	self.wndAcceptBtn 				= wndParent:FindChild("ReplaceBtn")
	self.wndCancelBtn 				= wndParent:FindChild("CancelBtn")

end

function RemodelPreviewControl:OnResidenceChange(idZone)
	if self.strType == "exterior" then
	    local tRemodelValues = {}
		local tBakedList	= {}
		tBakedList = HousingLib.GetBakedDecorDetails()
		for key, tData in pairs(tBakedList) do
		    if tData.eHookType ~= nil and tData.eHookType == HousingLib.CodeEnumDecorHookType.Roof then
		        tRemodelValues[HousingLib.RemodelOptionTypeExterior.Roof] = tData
		    elseif tData.eType ~= nil and tData.eType == HousingLib.RemodelOptionTypeExterior.Wallpaper then
		        tRemodelValues[HousingLib.RemodelOptionTypeExterior.Wallpaper] = tData
		    elseif tData.eHookType ~= nil and tData.eHookType == HousingLib.CodeEnumDecorHookType.Entryway then
                tRemodelValues[HousingLib.RemodelOptionTypeExterior.Entry] = tData 
            elseif tData.eHookType ~= nil and tData.eHookType == HousingLib.CodeEnumDecorHookType.Door then
                tRemodelValues[HousingLib.RemodelOptionTypeExterior.Door] = tData
            elseif tData.eType ~= nil and tData.eType == HousingLib.RemodelOptionTypeExterior.Sky then
		        tRemodelValues[HousingLib.RemodelOptionTypeExterior.Sky] = tData
		    end
		end

		for eType = HousingLib.RemodelOptionTypeExterior.Roof, HousingLib.RemodelOptionTypeExterior.Sky do
		    local tData = tRemodelValues[eType]
			self.tRemodelPreviewItems[eType]:OnResidenceChange(tData)
		end
	else
	    gtRemodelTrueValues = {}
		local tSectorDecorList = HousingLib.GetDecorDetailsBySector(idZone)
		for key, tData in pairs(tSectorDecorList) do
			--self.tRemodelPreviewItems[tData.eType]:OnResidenceChange(tData)
			gtRemodelTrueValues[tData.eType] = tData
		end
		
		for eType = HousingLib.RemodelOptionTypeInterior.Wallpaper, HousingLib.RemodelOptionTypeInterior.Lighting do
		    local tData = gtRemodelTrueValues[eType]
			self.tRemodelPreviewItems[eType]:OnResidenceChange(tData)
		end
	end
end

function RemodelPreviewControl:OnChoiceMade(nIndex, idItem, tList )
	self.tRemodelPreviewItems[nIndex]:OnChoiceMade(idItem, tList)

	self:SetTotalPrice()
end

function RemodelPreviewControl:OnAllChoicesCanceled(bPurchased)
	for idx, value in ipairs(self.tRemodelPreviewItems) do
		self.tRemodelPreviewItems[idx]:OnChoiceCanceled(idx)
	end

	if not bPurchased then
		self:ClearClientPreviewItems()
	end

	self:SetTotalPrice()
end

function RemodelPreviewControl:OnChoiceCanceled(nIndex)
	Sound.Play(Sound.PlayUIHousingItemCancelled)
	self.tRemodelPreviewItems[nIndex]:OnChoiceCanceled()
	self:ClearClientPreviewItems()

	self:SetTotalPrice()
end

function RemodelPreviewControl:OnPreviewCheck(nIndex)
	self:SetClientPreviewItems()
end

function RemodelPreviewControl:ThereArePreviewItems()
	for idx, value in ipairs(self.tRemodelPreviewItems) do
		if self.tRemodelPreviewItems[idx].idSelectedChoice ~= 0 then
			return true
		end
	end

	return false
end

function RemodelPreviewControl:SetClientPreviewItems()
	if self.strType == "exterior" then

		local idRoof		= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Roof]:GetPreviewValue()
		local idWallpaper	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Wallpaper]:GetPreviewValue()
		local idEntry		= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Entry]:GetPreviewValue()
		local idDoor 		= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Door]:GetPreviewValue()
		local idSky     	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Sky]:GetPreviewValue()

		if 	self:ThereArePreviewItems() then
			HousingLib.PreviewResidenceBakedDecor(idRoof, idWallpaper, idEntry, idDoor, idSky )
		end
	else -- "interior"
		local idCeiling 	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Ceiling]:GetPreviewValue()
		local idTrim 		= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Trim]:GetPreviewValue()
		local idWallpaper 	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Wallpaper]:GetPreviewValue()
		local idFloor 		= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Floor]:GetPreviewValue()
		local idLighting 	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Lighting]:GetPreviewValue()

		if 	self:ThereArePreviewItems() then
			HousingLib.PreviewResidenceSectorDecor(gidZone, idCeiling, idTrim, idWallpaper, idFloor, idLighting)
		end
	end
end

function RemodelPreviewControl:ClearClientPreviewItems()
	if self.strType == "exterior" then
		local idRoof		= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Roof]:GetPreviewValue()
		local idWallpaper	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Wallpaper]:GetPreviewValue()
		local idEntry		= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Entry]:GetPreviewValue()
		local idDoor 		= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Door]:GetPreviewValue()
		local idSky     	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Sky]:GetPreviewValue()
		
		HousingLib.PreviewResidenceBakedDecor(idRoof, idWallpaper, idEntry, idDoor, idSky)
	else
		local idCeiling 	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Ceiling]:GetPreviewValue()
		local idTrim 		= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Trim]:GetPreviewValue()
		local idWallpaper 	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Wallpaper]:GetPreviewValue()
		local idFloor 		= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Floor]:GetPreviewValue()
		local idLighting 	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Lighting]:GetPreviewValue()

		HousingLib.PreviewResidenceSectorDecor(gidZone, idCeiling, idTrim, idWallpaper, idFloor, idLighting)
	end
end

function RemodelPreviewControl:SetTotalPrice()

	local nTotalCostCash = 0
	local nTotalCostRenown = 0
	if self:ThereArePreviewItems() then
        for key, value in pairs(self.tRemodelPreviewItems) do
            if self.tRemodelPreviewItems[key].wndCost:GetCurrency():GetMoneyType() == Money.CodeEnumCurrencyType.Credits then
                nTotalCostCash = nTotalCostCash + self.tRemodelPreviewItems[key].wndCost:GetAmount()
            else
                nTotalCostRenown = nTotalCostRenown + self.tRemodelPreviewItems[key].wndCost:GetAmount()
            end
        end
	end

    local strDoc = self.wndRemodelTotalCostCash:GetAMLDocForPrice(nTotalCostCash, Money.CodeEnumCurrencyType.Credits, nTotalCostRenown, Money.CodeEnumCurrencyType.Renown, true)
    self.wndRemodelTotalCostML:SetAML (strDoc)

	-- adjust the accept & cancel buttons based on totalCost
	--local bEnable = nTotalCostCash > 0 and nTotalCostCash <= GameLib.GetPlayerCurrency():GetAmount()
	local bInvalidCash = nTotalCostCash > 0 and nTotalCostCash > GameLib.GetPlayerCurrency():GetAmount()
	local bInvalidRenown = nTotalCostRenown > 0 and nTotalCostRenown > GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Renown):GetAmount()
	local bDisable = (nTotalCostCash <= 0 and nTotalCostRenown <= 0) or bInvalidCash or bInvalidRenown
	self.wndAcceptBtn:Enable(not bDisable)
	self.wndCancelBtn:Enable(not bDisable)

end

function RemodelPreviewControl:PurchaseRemodelChanges()
	--print("purchaseRemodelChanges type: " .. self.type)
	if self.strType == "exterior" then
			HousingLib.ModifyResidenceDecor(self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Roof].idSelectedChoice,
											self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Wallpaper].idSelectedChoice,
											self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Entry].idSelectedChoice,
                                            self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Door].idSelectedChoice,
                                            self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Sky].idSelectedChoice)
	else
		HousingLib.PurchaseInteriorWallpaper(self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Wallpaper].idSelectedChoice,
											 self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Floor].idSelectedChoice,
											 self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Ceiling].idSelectedChoice,
											 self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Trim].idSelectedChoice,
                                             self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Lighting].idSelectedChoice)
	end

	Sound.Play(Sound.PlayUI16BuyVirtual)

    if self.strType == "interior" then
		self:OnResidenceChange(gidZone)
	end
	self:OnAllChoicesCanceled(true)
end

---------------------------------------------------------------------------------------------------
-- RemodelPreviewItem methods
---------------------------------------------------------------------------------------------------

function RemodelPreviewItem:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.wndCost 				= nil
	o.wndDescription 		= nil
	o.wndCancelBtn 			= nil
	o.wndPreviewCheckbox 	= nil

	o.tCurrentItem 			= {}
	o.strType               = nil
	o.idSelectedChoice 		= 0

	return o
end

function RemodelPreviewItem:OnLoad(wndParent, tRemodelOption, strName)
	local wndPreview = wndParent:FindChild(strName .. "Window")

	self.wndCost = wndPreview:FindChild("Cost")
	self.wndDescription = wndPreview:FindChild("Description")
	self.wndCancelBtn = wndPreview:FindChild("CanceBtn")
	self.wndPreviewCheckbox = wndPreview:FindChild(strName .. "PreviewBtn")

	self.idSelectedChoice = 0
	self.strType = strName
	self:OnResidenceChange(tRemodelOption)
end

-- set up the "grey'd" out default choices with the current residence values
function RemodelPreviewItem:OnResidenceChange(tCurrentItem)
	-- "interior" items aren't on a baked list
	--  this process will set them up w/ default text/colors
	-- name is actually type/slot ("Ceiling", "Trim", etc...)

	if tCurrentItem ~= nil then
		self.tCurrentItem = tCurrentItem
		self.wndDescription:SetText(self.tCurrentItem.strName)
	else
		self.tCurrentItem = {}
		-- line below should change once all these things exist!
		self.wndDescription:SetText(self.tCurrentItem.strName or Apollo.GetString("CRB_Default_") .. Apollo.GetString(ktTypeStrings[self.strType]))
	end

	self.wndDescription:SetTextColor(ApolloColor.new("UI_TextHoloBody"))
	self.wndPreviewCheckbox:Show(false)
	self.wndPreviewCheckbox:SetCheck(false)
	self.wndCancelBtn:Show(false)

end

function RemodelPreviewItem:OnChoiceMade(idItem, tList )
	local tItemData = HousingRemodel:GetItem(idItem, tList)
	if tItemData ~= nil then
        self.wndCost:SetMoneySystem(tItemData.eCurrencyType)
        self.wndCost:SetAmount(tItemData.nCost)
        self.wndDescription:SetText(tItemData.strName)
        self.wndDescription:SetTextColor(ApolloColor.new("UI_BtnTextGreenNormal"))
        self.wndPreviewCheckbox:Show(true)
        self.wndCancelBtn:Show(true)
        self.wndPreviewCheckbox:SetCheck(true)
        self.idSelectedChoice = tItemData.nId
	end
end

function RemodelPreviewItem:OnChoiceCanceled()
    self.wndCost:SetMoneySystem(Money.CodeEnumCurrencyType.Credits)
	self.wndCost:SetAmount(0)
	-- line below should change once all these things exist!
	self.wndDescription:SetText(self.tCurrentItem.strName or Apollo.GetString("CRB_Default_") .. Apollo.GetString(ktTypeStrings[self.strType]))
	self.wndDescription:SetTextColor(kcrDarkBlue)
	self.wndPreviewCheckbox:Show(false)
	self.wndPreviewCheckbox:SetCheck(false)
	self.wndCancelBtn:Show(false)
	self.idSelectedChoice = 0
end

function RemodelPreviewItem:GetPreviewValue()
	if self.wndPreviewCheckbox:IsChecked() then
		return self.idSelectedChoice
	end

	return 0
end

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function HousingRemodel:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

	-- initialize our variables
	o.wndRemodel = nil
	o.wndListView = nil
	o.wndOkButton = nil
	o.wndCashRemodel = nil

	o.bPlayerIsInside = false

	o.wndSortByList = nil
	o.tCategoryItems = {}

	o.tExtRemodelTabs = {}
	o.tIntRemodelTabs = {}

	o.luaExtRemodelPreviewControl = RemodelPreviewControl:new()
	o.luaIntRemodelPreviewControl = RemodelPreviewControl:new()

    return o
end

function HousingRemodel:Init()
    Apollo.RegisterAddon(self)
end


-----------------------------------------------------------------------------------------------
-- HousingRemodel OnLoad
-----------------------------------------------------------------------------------------------
function HousingRemodel:OnLoad()
	Apollo.RegisterEventHandler("HousingButtonRemodel", 			"OnHousingButtonRemodel", self)
	Apollo.RegisterEventHandler("HousingButtonLandscape", 			"OnHousingButtonLandscape", self)
	Apollo.RegisterEventHandler("HousingButtonCrate", 				"OnHousingButtonCrate", self)
	Apollo.RegisterEventHandler("HousingButtonVendor", 				"OnHousingButtonCrate", self)
	Apollo.RegisterEventHandler("HousingButtonList", 				"OnHousingButtonList", self)
	Apollo.RegisterEventHandler("HousingPanelControlOpen", 			"OnOpenPanelControl", self)
	Apollo.RegisterEventHandler("HousingPanelControlClose", 		"OnClosePanelControl", self)
	Apollo.RegisterEventHandler("HousingMyResidenceDecorChanged", 	"OnResidenceDecorChanged", self)
	Apollo.RegisterEventHandler("HousingResult", 					"OnHousingResult", self)
	Apollo.RegisterEventHandler("HousingNamePropertyOpen",          "OnHousingNameProperty", self)
	Apollo.RegisterEventHandler("PlayerCurrencyChanged", 			"OnPlayerCurrencyChanged", self)
	Apollo.RegisterEventHandler("HousingBuildStarted", 				"OnBuildStarted", self)

	Apollo.RegisterTimerHandler("HousingRemodelTimer", 				"OnRemodelTimer", self)
	Apollo.RegisterTimerHandler("HousingIntRemodelTimer", 			"OnIntRemodelTimer", self)

	Apollo.CreateTimer("HousingRemodelTimer", 0.200, false)
	Apollo.StopTimer("HousingRemodelTimer")

	Apollo.CreateTimer("HousingIntRemodelTimer", 0.200, false)
	Apollo.StopTimer("HousingIntRemodelTimer")

    -- load our forms
    self.xmlDoc                     = XmlDoc.CreateFromFile("HousingRemodel.xml")
    self.wndRemodel 				= Apollo.LoadForm(self.xmlDoc, "HousingRemodelWindow", nil, self)
	self.wndListView 				= self.wndRemodel:FindChild("StructureList")
	self.wndReplaceButton 			= self.wndRemodel:FindChild("ReplaceBtn")
	self.wndCancelButton			= self.wndRemodel:FindChild("CancelBtn")
	self.wndCashRemodel 			= self.wndRemodel:FindChild("CashWindow")
	self.wndExtRemodelHeaderFrame 	= self.wndRemodel:FindChild("ExtHeaderWindow")
	self.wndIntRemodelHeaderFrame 	= self.wndRemodel:FindChild("IntHeaderWindow")
	self.wndExtPreviewWindow 		= self.wndRemodel:FindChild("ExtPreviewWindow")
	self.wndIntPreviewWindow 		= self.wndRemodel:FindChild("IntPreviewWindow")
	self.wndIntRemodelRemoveBtn 	= self.wndRemodel:FindChild("RemoveIntOption")
	self.wndCurrentUpgradeLabel		= self.wndRemodel:FindChild("CurrentOptionDisplayString")
	self.wndSearchWindow 			= self.wndRemodel:FindChild("SearchBox")
	self.wndClearSearchBtn 			= self.wndRemodel:FindChild("ClearSearchBtn")
	--self.winNameTextBox = self.winRemodel:FindChild("PropertyNameBox")
	--self.winIntSearchWindow = self.winIntRemodelHeaderFrame:FindChild("IntSearchBox")
	--self.winExtSearchWindow = self.winExtRemodelHeaderFrame:FindChild("ExtSearchBox")
	--self.winExtClearSearchBtn = self.winExtRemodelHeaderFrame:FindChild("ExtClearSearchBtn")
	--self.winIntClearSearchBtn = self.winIntRemodelHeaderFrame:FindChild("IntClearSearchBtn")

	self.wndPropertySettingsPopup	= Apollo.LoadForm(self.xmlDoc, "PropertySettingsPanel", nil, self)
	self.wndPropertyRenamePopup 	= Apollo.LoadForm(self.xmlDoc, "PropertyRenamePanel", nil, self)

	self.wndListView:SetColumnText(1, Apollo.GetString("HousingRemodel_UpgradeColumn"))
	self.wndListView:SetColumnText(2, Apollo.GetString("HousingRemodel_Cost"))

	-- TODO: Re-enable when we have sorting
   -- self.winRemodel:FindChild("IntSortByBtn"):Enable(false)
    --self.winRemodel:FindChild("ExtSortByBtn"):Enable(false)

	for idx = 1, knExtRemodelTabs do
		self.tExtRemodelTabs[idx] = self.wndExtRemodelHeaderFrame:FindChild("ExtRemodelTab" .. tostring(idx))
	end
	self.wndExtRemodelHeaderFrame:SetRadioSel("ExtRemodelTab", 1)

	for idx = 1, knIntRemodelTabs do
		self.tIntRemodelTabs[idx] = self.wndIntRemodelHeaderFrame:FindChild("IntRemodelTab" .. tostring(idx))
	end
	self.wndIntRemodelHeaderFrame:SetRadioSel("IntRemodelTab", 1)

	--self.ExtRemodelPreviewControl:load("exterior", self.winRemodel, self.winRemodel, {"Roof", "Wallpaper", "Entry", "Door"} )
	--self.IntRemodelPreviewControl:load("interior", self.winRemodel, self.winRemodel, {"Ceiling", "Trim", "IntWallpaper", "Floor", "Lighting"} )
	self.luaExtRemodelPreviewControl:OnLoad("exterior", self.wndRemodel:FindChild("ExtPreviewWindow"), self.wndRemodel, {"Roof", "Wallpaper", "Entry", "Door", "Sky"})
	self.luaIntRemodelPreviewControl:OnLoad("interior", self.wndRemodel:FindChild("IntPreviewWindow"), self.wndRemodel, {"IntWallpaper", "Floor", "Ceiling", "Trim", "Lighting"})


	self.wndReplaceButton:Enable(false)
	self.wndReplaceButton:Show(true)
	self.wndCancelButton:Enable(false)
	self.wndClearSearchBtn:Show(false)
	--self.winIntClearSearchBtn:Show(false)
	--self.winExtClearSearchBtn:Show(false)

	self:ResetPopups()

	self.wndCashRemodel:SetAmount(GameLib.GetPlayerCurrency(), true)
	--self.winNameTextBox:SetText(HousingLib.GetPropertyName())

	HousingLib.RefreshUI()
end


-----------------------------------------------------------------------------------------------
-- HousingRemodel Functions
-----------------------------------------------------------------------------------------------

function HousingRemodel:ResetPopups()
	self.wndPropertyRenamePopup:Show(false)
	self.wndPropertySettingsPopup:Show(false)
end

function HousingRemodel:OnSortByUncheck()
	if self.bPlayerIsInside then
		self.wndRemodel:FindChild("IntSortByList"):Show(false)
	else
		self.wndRemodel:FindChild("ExtSortByList"):Show(false)
	end
end

function HousingRemodel:OnSortByCheck()
	if self.bPlayerplayerIsInside then
		self.wndRemodel:FindChild("IntSortByList"):Show(true)
	else
		self.wndRemodel:FindChild("ExtSortByList"):Show(true)
	end
end

--[[function HousingRemodel:OnSortByName(wndHandler, wndControl)
	if not wndHandler then return end
	self.nSortType = 1
	self:HelperOnSortByUpdateDropdown(wndHandler:GetText())
end

function HousingRemodel:OnSortByZone(wndHandler, wndControl)
	if not wndHandler then return end
	self.nSortType = 2
	self:HelperOnSortByUpdateDropdown(wndHandler:GetText())
end

function HousingRemodel:OnSortByUpdated(wndHandler, wndControl)
	if not wndHandler then return end
	self.nSortType = 3
	self:HelperOnSortByUpdateDropdown(wndHandler:GetText())
end--]]

function HousingRemodel:HelperOnSortByUpdateDropdown(strDropdownText)
    --if self.bPlayerIsInside then
      --  self.winRemodel:FindChild("IntSortByBtn"):SetCheck(false)
      --  self.winRemodel:FindChild("IntSortByList"):Show(false)
       -- self.winRemodel:FindChild("IntSortByBtnLabel"):SetText(strDropdownText)
	--else
	  --  self.winRemodel:FindChild("ExtSortByBtn"):SetCheck(false)
      --  self.winRemodel:FindChild("ExtSortByList"):Show(false)
       -- self.winRemodel:FindChild("ExtSortByBtnLabel"):SetText(strDropdownText)
	--end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnHousingButtonRemodel()
	if not self.wndRemodel:IsVisible() then
        self.wndRemodel:Show(true)
        self:ShowAppropriateRemodelTab()
        self.wndRemodel:ToFront()
		self.wndRemodel:FindChild("PropertyNameDisplay"):SetText(HousingLib.GetPropertyName())
		if self.bPlayerIsInside then
		    Event_ShowTutorial(GameLib.CodeEnumTutorial.Housing_Room)
		else
            Event_ShowTutorial(GameLib.CodeEnumTutorial.Housing_House)
        end    
	else
	    self:OnCloseHousingRemodelWindow()
	end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnHousingButtonCrate()
	if self.wndRemodel:IsVisible() then
		self:OnCloseHousingRemodelWindow()
	end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnHousingButtonList()
	if self.wndRemodel:IsVisible() then
		self:OnCloseHousingRemodelWindow()
	end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnHousingButtonLandscape()
	if self.wndRemodel:IsVisible() then
		self:OnCloseHousingRemodelWindow()
	end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnOpenPanelControl(idPropertyInfo, idZone, bPlayerIsInside)
	if self.bPlayerIsInside ~= bPlayerIsInside then
		self:OnCloseHousingRemodelWindow()
	end

    if gidZone ~= idZone then
		self.luaIntRemodelPreviewControl:OnAllChoicesCanceled(false)
	end

	gidZone = idZone
	self.idPropertyInfo = idPropertyInfo
	self.bPlayerIsInside = bPlayerIsInside == true --make sure we get true/false

	if bPlayerIsInside then
		self.luaIntRemodelPreviewControl:OnResidenceChange(gidZone)
	    self:ShowAppropriateRemodelTab()
	else
	    self.luaExtRemodelPreviewControl:OnResidenceChange(gidZone)
	    self:ShowAppropriateRemodelTab()
	end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnClosePanelControl()
	self:OnCloseHousingRemodelWindow() -- you've left your property!
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnReplaceBtn(wndControl, wndHandler)
    if self.bPlayerIsInside then
	    self.luaIntRemodelPreviewControl:PurchaseRemodelChanges()
	    -- call this to refresh our windows
	    self:ShowAppropriateIntRemodelTab()
	else
	    self.luaExtRemodelPreviewControl:PurchaseRemodelChanges()
	    
	    self.idUniqueItem = nil

	    -- give the server enough time to process the purchase request, then update the UI
		Apollo.StartTimer("HousingRemodelTimer")
	end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnCancelBtn(wndControl, wndHandler)
	Sound.Play(Sound.PlayUIHousingItemCancelled)
	if self.bPlayerIsInside then
	    self:ResetIntRemodelPreview(false)
	else
	    self:ResetExtRemodelPreview(false)
	end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnWindowClosed()
	-- called after the window is closed by:
	--	self.winMasterCustomizeFrame:Close() or
	--  hitting ESC or
	--  C++ calling Event_CloseHousingVendorWindow()

	-- popup windows reset
	self:ResetPopups()

	self:ResetExtRemodelPreview(true)
	self:ResetIntRemodelPreview(true)
	self.wndSearchWindow:SetText("")
	self.wndClearSearchBtn:Show(false)
	Sound.Play(Sound.PlayUIWindowClose)
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnCloseHousingRemodelWindow()
	-- close the window which will trigger OnWindowClosed
	self:ResetPopups()
	self.wndListView:SetCurrentRow(0)
	self.idUniqueItem = nil
	self.idIntPruneItem = nil
	self.wndRemodel:Close()
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:SwitchRemodelTab()
	self.wndSearchWindow:ClearFocus()

	for idx = 1, knExtRemodelTabs do
		self.tExtRemodelTabs[idx]:SetTextColor(kcrDarkBlue)
	end

	local nRemodelSel = self.wndExtRemodelHeaderFrame:GetRadioSel("ExtRemodelTab")
	if nRemodelSel >= 1 and nRemodelSel <= knExtRemodelTabs then
		self.tExtRemodelTabs[nRemodelSel]:SetTextColor(kcrWhite)
	end

	for idx = 1, knIntRemodelTabs do
		self.tIntRemodelTabs[idx]:SetTextColor(kcrDarkBlue)
	end

	nRemodelSel = self.wndIntRemodelHeaderFrame:GetRadioSel("IntRemodelTab")
	if nRemodelSel >= 1 and nRemodelSel <= knIntRemodelTabs then
		self.tIntRemodelTabs[nRemodelSel]:SetTextColor(kcrWhite)
	end

	self:ShowAppropriateRemodelTab()
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnRemodelTabBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end

	self:SwitchRemodelTab()
end

---------------------------------------------------------------------------------------------------
--Upper buttons:
function HousingRemodel:OnEntryOptionsBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end

	self.wndExtRemodelHeaderFrame:SetRadioSel("ExtRemodelTab", 3)
	self:SwitchRemodelTab()
end

function HousingRemodel:OnWallOptionsBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	self.wndExtRemodelHeaderFrame:SetRadioSel("ExtRemodelTab", 2)
	self:SwitchRemodelTab()
end

function HousingRemodel:OnRoofOptionsBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	self.wndExtRemodelHeaderFrame:SetRadioSel("ExtRemodelTab", 1)
	self:SwitchRemodelTab()
end

function HousingRemodel:OnDoorOptionsBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	self.wndExtRemodelHeaderFrame:SetRadioSel("ExtRemodelTab", 4)
	self:SwitchRemodelTab()
end

function HousingRemodel:OnSkyOptionsBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	self.wndExtRemodelHeaderFrame:SetRadioSel("ExtRemodelTab", 5)
	self:SwitchRemodelTab()
end

--Upper buttons (Interior):
function HousingRemodel:OnCeilingOptionsBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end

	self.wndIntRemodelHeaderFrame:SetRadioSel("IntRemodelTab", 1)
	self:SwitchRemodelTab()
end

function HousingRemodel:OnTrimOptionsBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	self.wndIntRemodelHeaderFrame:SetRadioSel("IntRemodelTab", 2)
	self:SwitchRemodelTab()
end

function HousingRemodel:OnIntWallpaperOptionsBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	self.wndIntRemodelHeaderFrame:SetRadioSel("IntRemodelTab", 3)
	self:SwitchRemodelTab()
end

function HousingRemodel:OnFloorOptionsBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	self.wndIntRemodelHeaderFrame:SetRadioSel("IntRemodelTab", 4)
	self:SwitchRemodelTab()
end

function HousingRemodel:OnLightingOptionsBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	self.wndIntRemodelHeaderFrame:SetRadioSel("IntRemodelTab", 5)
	self:SwitchRemodelTab()
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnHousingNameProperty()
	self.wndPropertyRenamePopup:FindChild("CostWindow"):SetMoneySystem(Money.CodeEnumCurrencyType.Renown)
	self.wndPropertyRenamePopup:FindChild("CostWindow"):SetAmount(0)
	self.wndPropertyRenamePopup:FindChild("MyCashWindow"):SetMoneySystem(Money.CodeEnumCurrencyType.Renown)
	self.wndPropertyRenamePopup:FindChild("MyCashWindow"):SetAmount(GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Renown))

	self.wndPropertyRenamePopup:FindChild("OldNameEntry"):SetText(HousingLib.GetPropertyName())
	self.wndPropertyRenamePopup:FindChild("NewNameEntry"):SetText("")
	self.wndPropertyRenamePopup:FindChild("ClearNameEntryBtn"):Show(false)

	self:CheckPropertyNameChange()

	self.wndRemodel:Show(false)
	self:ResetPopups()
	self.wndPropertyRenamePopup:Show(true)
	self.wndPropertyRenamePopup:ToFront()
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnPropertyNameBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	
	local nRenameCost = HousingLib.GetPropertyName() ~= "" and HousingLib.PropertyRenameCost or 0

	self.wndPropertyRenamePopup:FindChild("CostWindow"):SetMoneySystem(Money.CodeEnumCurrencyType.Renown)
	self.wndPropertyRenamePopup:FindChild("CostWindow"):SetAmount(nRenameCost)
	self.wndPropertyRenamePopup:FindChild("MyCashWindow"):SetMoneySystem(Money.CodeEnumCurrencyType.Renown)
	self.wndPropertyRenamePopup:FindChild("MyCashWindow"):SetAmount(GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Renown))

	self.wndPropertyRenamePopup:FindChild("OldNameEntry"):SetText(HousingLib.GetPropertyName())
	self.wndPropertyRenamePopup:FindChild("NewNameEntry"):SetText("")
	self.wndPropertyRenamePopup:FindChild("ClearNameEntryBtn"):Show(false)

	self:CheckPropertyNameChange()

	self.wndRemodel:Show(false)
	self:ResetPopups()
	self.wndPropertyRenamePopup:Show(true)
	self.wndPropertyRenamePopup:ToFront()
end

function HousingRemodel:CheckPropertyNameChange(wndHandler, wndControl)
	local strProposed = self.wndPropertyRenamePopup:FindChild("NewNameEntry"):GetText()
	local bCanAfford = GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Renown):GetAmount() >= HousingLib.PropertyRenameCost or HousingLib.GetPropertyName() == ""
	local bTextValid = GameLib.IsTextValid(strProposed, GameLib.CodeEnumUserText.HousingResidenceName, GameLib.CodeEnumUserTextFilterClass.Strict)
	
	
	self.wndPropertyRenamePopup:FindChild("RenameBtn"):Enable(bCanAfford and strProposed ~= "" and bTextValid)
	self.wndPropertyRenamePopup:FindChild("RenameValidAlert"):Show(strProposed ~= "" and not bTextValid)
	self.wndPropertyRenamePopup:FindChild("ClearNameEntryBtn"):Show(strProposed ~= "")
end

function HousingRemodel:OnClearNameEntryBtn(wndHandler, wndControl)
	self.wndPropertyRenamePopup:FindChild("NewNameEntry"):SetText("")
	self.wndPropertyRenamePopup:FindChild("NewNameEntry"):ClearFocus()
	self:CheckPropertyNameChange()
end

function HousingRemodel:OnRenameAccept(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end

	HousingLib.RenameProperty(self.wndPropertyRenamePopup:FindChild("NewNameEntry"):GetText())
	--HousingLib.RenameProperty(self.winNameTextBox:GetText())

	self.wndPropertyRenamePopup:Show(false)
	if HousingLib.GetPropertyName() ~= "" then
        self:OnHousingButtonRemodel()
	end
end

function HousingRemodel:OnRenameCancel(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
    
    self.wndPropertyRenamePopup:Show(false)
    
    if HousingLib.GetPropertyName() ~= "" then
        self:OnHousingButtonRemodel()
	end
end

function HousingRemodel:OnRemodelTimer()
	self.luaExtRemodelPreviewControl:OnResidenceChange(gidZone)
    -- call this to refresh our windows
    self:ShowAppropriateExtRemodelTab()
end

function HousingRemodel:OnIntRemodelTimer()
	--update the player's money
	self.wndListView:SetCurrentRow(0)
end

-----------------------------------------------------------------------------------------------
-- DecorateItemList Functions
-----------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function HousingRemodel:OnRemodelListItemChange(wndControl, wndHandler, nX, nY)
	self.wndSearchWindow:ClearFocus()

	if wndControl ~= wndHandler then
		return
	end

	-- find the item id of the thingie that's selected
    local nRow = wndControl:GetCurrentRow()
    local idItem = wndControl:GetCellData(nRow, 1 )
    self.idUniqueItem = idItem

	--Print("id is: " .. id)
	local wndCheckButton = nil
	local tItemList = nil

	if self.bPlayerIsInside then
		self.wndReplaceButton:Show(self.idUniqueItem ~= self.idIntPruneItem)
		self.wndIntRemodelRemoveBtn:Show(self.idUniqueItem == self.idIntPruneItem)

		if self.idUniqueItem == self.idIntPruneItem then
			local nSel = self.wndIntRemodelHeaderFrame:GetRadioSel("IntRemodelTab")
			if nSel == 1 then
				self.luaIntRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeInterior.Ceiling)
				wndCheckButton = self.wndRemodel:FindChild("CeilingPreviewBtn")
			elseif nSel == 2 then
				self.luaIntRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeInterior.Trim)
				wndCheckButton = self.wndRemodel:FindChild("TrimPreviewBtn")
			elseif nSel == 3 then
				self.luaIntRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeInterior.Wallpaper)
				wndCheckButton = self.wndRemodel:FindChild("IntWallpaperPreviewBtn")
			elseif nSel == 4 then
				self.luaIntRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeInterior.Floor)
				wndCheckButton = self.wndRemodel:FindChild("FloorPreviewBtn")
			else
                self.luaIntRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeInterior.Lighting)
				wndCheckButton = self.wndRemodel:FindChild("LightingPreviewBtn")
			end
		else
			local nSel = self.wndIntRemodelHeaderFrame:GetRadioSel("IntRemodelTab")
			if nSel == 1 then
				self.luaIntRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeInterior.Ceiling, idItem, self.tRemodelVendorWallpaperList)
				wndCheckButton = self.wndRemodel:FindChild("CeilingPreviewBtn")
				tItemList = self.tRemodelVendorWallpaperList
			elseif nSel == 2 then
				self.luaIntRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeInterior.Trim, idItem, self.tRemodelVendorWallpaperList)
				wndCheckButton = self.wndRemodel:FindChild("TrimPreviewBtn")
				tItemList = self.tRemodelVendorWallpaperList
			elseif nSel == 3 then
				self.luaIntRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeInterior.Wallpaper, idItem, self.tRemodelVendorWallpaperList)
				wndCheckButton = self.wndRemodel:FindChild("IntWallpaperPreviewBtn")
				tItemList = self.tRemodelVendorWallpaperList
			elseif nSel == 4 then
				self.luaIntRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeInterior.Floor, idItem, self.tRemodelVendorWallpaperList)
				wndCheckButton = self.wndRemodel:FindChild("FloorPreviewBtn")
				tItemList = self.tRemodelVendorWallpaperList
			else
        	    self.luaIntRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeInterior.Lighting, idItem, self.tRemodelVendorWallpaperList)
				wndCheckButton = self.wndRemodel:FindChild("LightingPreviewBtn")
				tItemList = self.tRemodelVendorWallpaperList
			end
		end
	else
		local nSel = self.wndExtRemodelHeaderFrame:GetRadioSel("ExtRemodelTab")
		if nSel == 1 then
			Sound.Play(Sound.PlayUIHousingHardwareAddition)
			self.luaExtRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeExterior.Roof, idItem, self.tRemodelRoofList)
			wndCheckButton = self.wndRemodel:FindChild("RoofPreviewBtn")
			tItemList = self.tRemodelRoofList
		elseif nSel == 2 then
			Sound.Play(Sound.PlayUIHousingDecor)
			self.luaExtRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeExterior.Wallpaper, idItem, self.tRemodelVendorWallpaperList)
			wndCheckButton = self.wndRemodel:FindChild("WallpaperPreviewBtn")
			tItemList = self.tRemodelVendorWallpaperList
		elseif nSel == 3 then
			Sound.Play(Sound.PlayUIHousingHardwareAddition)
			self.luaExtRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeExterior.Entry, idItem, self.tRemodelEntryList)
			wndCheckButton = self.wndRemodel:FindChild("EntryPreviewBtn")
			tItemList = self.tRemodelEntryList
		elseif nSel == 4 then
			Sound.Play(Sound.PlayUIHousingHardwareAddition)
			self.luaExtRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeExterior.Door, idItem, self.tRemodelDoorList)
			wndCheckButton = self.wndRemodel:FindChild("DoorPreviewBtn")
			tItemList =  self.tRemodelDoorList
		else
			Sound.Play(Sound.PlayUIHousingHardwareAddition)
			self.luaExtRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeExterior.Sky, idItem, self.tRemodelVendorWallpaperList)
			wndCheckButton = self.wndRemodel:FindChild("SkyPreviewBtn")
			tItemList = self.tRemodelVendorWallpaperList
		end
	end

	if tItemList then
		local tItemData = self:GetItem(idItem, tItemList)
		--if tItemData then
			self.wndCashRemodel:SetMoneySystem(tItemData.eCurrencyType)
			self.wndCashRemodel:SetAmount(GameLib.GetPlayerCurrency(tItemData.eCurrencyType))
		--end
	end

	-- "check" the preview button automatically for the user
	wndCheckButton:SetCheck(true)
	self:OnComponentPreviewOnCheck(wndCheckButton)

end
---------------------------------------------------------------------------------------------------
function HousingRemodel:ShowAppropriateRemodelTab()
	if self.bPlayerIsInside then
		self:ShowAppropriateIntRemodelTab()
		self.wndExtPreviewWindow:Show(false)
		self.wndIntPreviewWindow:Show(true)
		self.wndExtRemodelHeaderFrame:Show(false) -- ADD BUY/REPLACE BTNS HERE
		self.wndIntRemodelHeaderFrame:Show(true)
		self.wndReplaceButton:Show(true)
		self.wndIntRemodelRemoveBtn:Show(false)
		self.wndSortByList = self.wndRemodel:FindChild("IntSortByList")
	else
		self:ShowAppropriateExtRemodelTab()

		self.wndExtPreviewWindow:Show(true)
		self.wndIntPreviewWindow:Show(false)
		self.wndExtRemodelHeaderFrame:Show(true)
		self.wndIntRemodelHeaderFrame:Show(false)
		self.wndIntRemodelRemoveBtn:Show(false)
		self.wndSortByList = self.wndRemodel:FindChild("ExtSortByList")
		self.wndRemodel:FindChild("PropertyNameDisplay"):SetText(HousingLib.GetPropertyName())
	end

    self.wndCashRemodel:SetMoneySystem(Money.CodeEnumCurrencyType.Credits)
	self.wndCashRemodel:SetAmount(GameLib.GetPlayerCurrency(), true)
	--self.winNameTextBox:SetText(HousingLib.GetPropertyName())

  -- self:PopulateCategoryList()
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:SetRemodelCurrentDetails(strText)
	if strText ~= nil then
		local strLabel = string.format("<T Font=\"%s\" TextColor=\"%s\">%s</T>", "CRB_InterfaceMedium", "ff2f94ac", Apollo.GetString("HousingRemodel_CurrentUpgrade"))
		local strTextFormatted = string.format("<T Font=\"%s\" TextColor=\"%s\">%s</T>", "CRB_InterfaceMedium", "ff31fcf6", strText)
		local strFull = string.format("<T Align=\"Center\">%s</T>", String_GetWeaselString(strLabel, strTextFormatted))

		self.wndCurrentUpgradeLabel:SetText(strFull)
	else
		self.wndCurrentUpgradeLabel:SetText("")
	end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:ShowAppropriateIntRemodelTab()
	local idPruneItem = 0
	local nSel = self.wndIntRemodelHeaderFrame:GetRadioSel("IntRemodelTab")
	if nSel < 1 or nSel > knIntRemodelTabs then
		return
	end

	local eType
	if nSel == 1 then --ceiling
	    eType = HousingLib.RemodelOptionTypeInterior.Ceiling
		self.tRemodelVendorWallpaperList = HousingLib.GetRemodelWallpaperInteriorList(eType)
	elseif nSel == 2 then -- trim
	    eType = HousingLib.RemodelOptionTypeInterior.Trim
		self.tRemodelVendorWallpaperList = HousingLib.GetRemodelWallpaperInteriorList(eType)
	elseif nSel == 3 then -- walls
	    eType = HousingLib.RemodelOptionTypeInterior.Wallpaper
		self.tRemodelVendorWallpaperList = HousingLib.GetRemodelWallpaperInteriorList(eType)
	elseif nSel == 4 then -- floor
	    eType = HousingLib.RemodelOptionTypeInterior.Floor
		self.tRemodelVendorWallpaperList = HousingLib.GetRemodelWallpaperInteriorList(eType)
	elseif nSel == 5 then -- lighting
	    eType = HousingLib.RemodelOptionTypeInterior.Lighting
		self.tRemodelVendorWallpaperList = HousingLib.GetRemodelWallpaperInteriorList(eType)
	end

	if gtRemodelTrueValues[eType] ~= nil then
		idPruneItem = gtRemodelTrueValues[eType].nId
	else
	    self.idIntPruneItem = nil
	end

	self:ShowItems(self.wndListView, self.tRemodelVendorWallpaperList, idPruneItem)
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:ShowAppropriateExtRemodelTab()
	local idPruneItem = 0
	local nSel = self.wndExtRemodelHeaderFrame:GetRadioSel("ExtRemodelTab")
	if nSel < 1 or nSel > #self.tExtRemodelTabs then
		return
	end
	self.tExtRemodelTabs[nSel]:SetTextColor(kcrWhite)

	local strCurrentItemText
	if nSel == 1 then
		self.tRemodelRoofList = HousingLib.GetRemodelRoofList()
		idPruneItem = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Roof].tCurrentItem.nId
		strCurrentItemText = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Roof].tCurrentItem.strName
		self:ShowItems(self.wndListView, self.tRemodelRoofList, idPruneItem)
	elseif nSel == 2 then
		self.tRemodelVendorWallpaperList = HousingLib.GetRemodelWallpaperExteriorList()
		idPruneItem = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Wallpaper].tCurrentItem.nId
		strCurrentItemText = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Wallpaper].tCurrentItem.strName
		self:ShowItems(self.wndListView, self.tRemodelVendorWallpaperList, idPruneItem)
	elseif nSel == 3 then
		self.tRemodelEntryList = HousingLib.GetRemodelEntryList()
		idPruneItem = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Entry].tCurrentItem.nId
		strCurrentItemText = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Entry].tCurrentItem.strName
		self:ShowItems(self.wndListView, self.tRemodelEntryList, idPruneItem)
	elseif nSel == 4 then
		self.tRemodelDoorList = HousingLib.GetRemodelDoorList()
		idPruneItem = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Door].tCurrentItem.nId
		strCurrentItemText = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Door].tCurrentItem.strName
		self:ShowItems(self.wndListView, self.tRemodelDoorList, idPruneItem)
	else
		self.tRemodelVendorWallpaperList = HousingLib.GetRemodelSkyExteriorList()
		idPruneItem = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Sky].tCurrentItem.nId
		strCurrentItemText = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Sky].tCurrentItem.strName
		self:ShowItems(self.wndListView, self.tRemodelVendorWallpaperList, idPruneItem)
	end

	if strCurrentItemText ~= nil then
		self:SetRemodelCurrentDetails(strCurrentItemText)
	else
		self:SetRemodelCurrentDetails(nil)
	end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnSearchChanged(wndControl, wndHandler)
  --[[  if self.playerIsInside and self.winIntSearchWindow:GetText() ~= "" then
        self.winIntClearSearchBtn:Show(true)
    elseif not self.playerIsInside and self.winExtSearchWindow:GetText() ~= "" then
        self.winExtClearSearchBtn:Show(true)
    else
        self.winIntClearSearchBtn:Show(false)
        self.winExtClearSearchBtn:Show(false)
    end--]]

    if self.wndSearchWindow:GetText() ~= "" then
        self.wndClearSearchBtn:Show(true)
	else
        self.wndClearSearchBtn:Show(false)
    end

    if self.bPlayerIsInside then
        self:ShowAppropriateIntRemodelTab()
    else
        self:ShowAppropriateExtRemodelTab()
    end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnClearSearchText(wndControl, wndHandler)
 	self.wndSearchWindow:SetText("")
--	self.winIntSearchWindow:SetText("")
--    self.winExtSearchWindow:SetText("")
	self.wndClearSearchBtn:Show(false)
	--self.winIntClearSearchBtn:Show(false)
	--self.winExtClearSearchBtn:Show(false)
	self.wndSearchWindow:ClearFocus()
    self:OnSearchChanged(wndControl, wndHandler)
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:ShowItems(wndListControl, tItemList, idPrune)
	if wndListControl ~= nil then
		wndListControl:DeleteAll()
	end

	if tItemList ~= nil then
		-- determine where we start and end based on page size
		local crRed = CColor.new(1.0, 0, 0, 1.0)
		local crWhite = CColor.new(1.0, 1.0, 1.0, 1.0)
		local crGrey = CColor.new(0.2,0.2,0.2,1.0)

		-- check for, and handle search filters
        local strSearch = self.wndSearchWindow:GetText()
      --[[  if self.playerIsInside then
            searchString = string.lower(self.winIntSearchWindow:GetText())
        else
            searchString = string.lower(self.winExtSearchWindow:GetText())
        end--]]

        if strSearch ~= nil and strSearch ~= "" and not strSearch:match("%W") then
            local tFilteredList = {}
            local nFilteredItems = 0
            for idx = 1, #tItemList do
                local strItemName = string.lower(tItemList[idx].strName)
                strSearch = string.lower(strSearch)
				if string.find(strItemName, strSearch) ~= nil then
                    nFilteredItems = nFilteredItems + 1
                    tFilteredList[nFilteredItems] = tItemList[idx]
                end
            end
            if #tFilteredList > 0 then
                tItemList = tFilteredList
            else
                return
            end
        end

	    -- Here we have an example of a nameless function being declared within another function's parameter list!
		table.sort(tItemList, function(a,b)	return (a.strName < b.strName)	end)

		-- populate the buttons with the item data
		for idx = 1, #tItemList do

			local tItemData = tItemList[idx]
			--if listControl ~= self.winListLandscape or self:SelectionMatches(item["type"]) then

				-- AddRow implicitly works on column one.  Every column can have it's own hidden data associated with it!
				local bPruned = false
				local nRow
				if idPrune ~= tItemData.nId then
					nRow = wndListControl:AddRow("" .. tItemData.strName, "", tItemData.nId)
				else
					if self.bPlayerIsInside then
						nRow = wndListControl:AddRow("" .. String_GetWeaselString(Apollo.GetString("HousingRemodel_CurrentEffect"), tItemData.strName), "", tItemData.nId)
						bPruned = true
						self.idIntPruneItem	= tItemData.nId
					else
						nRow = wndListControl:AddRow("" .. String_GetWeaselString(Apollo.GetString("HousingRemodel_CurrentEffect"), tItemData.strName), "", tItemData.nId)
						bPruned = true
						wndListControl:EnableRow(nRow, false)
					end
				end

				local strDoc = Apollo.GetString("CRB_Free_pull")

				local eCurrencyType = tItemData["eCurrencyType"]
		        local monCash = GameLib.GetPlayerCurrency(eCurrencyType):GetAmount()

		        self.wndCashRemodel:SetMoneySystem(eCurrencyType)

				if tItemData.nCost > monCash then
					strDoc = self.wndCashRemodel:GetAMLDocForAmount(tItemData.nCost, true, crRed)
				elseif bPruned == true then
					strDoc = self.wndCashRemodel:GetAMLDocForAmount(0, true, crGrey)
				else
					strDoc = self.wndCashRemodel:GetAMLDocForAmount(tItemData.nCost, true, crWhite)
				end


				wndListControl:SetCellData(idx, 2, "", "", tItemData.nCost)
				wndListControl:SetCellDoc(idx, 2, strDoc)

			--end
		end

        self.wndCashRemodel:SetMoneySystem(Money.CodeEnumCurrencyType.Credits)
	    self.wndCashRemodel:SetAmount(GameLib.GetPlayerCurrency(), true)
		self:SelectItemByUniqueId(wndListControl, tItemList)

	end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:SelectItemByUniqueId(wndListControl, tItemList)
	local nCount = wndListControl:GetRowCount()
	for idx = 1, nCount do
		local idx = wndListControl:GetCellData(idx, 1)
		if idx == self.idUniqueItem then
			wndListControl:SetCurrentRow(idx)
			wndListControl:EnsureCellVisible(idx, 1)

			local nAmount = wndListControl:GetCellData(idx, 2)
			if nAmount then
			    local tItemData = self:GetItem(idx, tItemList)
			    self.wndCashRemodel:SetMoneySystem(tItemData.eCurrencyType)
				self.wndCashRemodel:SetAmount(nAmount)
			end
			return
		end
	end

	self.idUniqueItem = nil
	--self.landscapeProposedControl:clear()
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:GetItem(idItem, tItemList)
	if tItemList then
		for idx = 1, #tItemList do
			tItemData = tItemList[idx]
			if tItemData.nId == idItem then
				return tItemData
			end
		end
	end
	return nil
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnRemoveRoofUpgrade()
	self.luaExtRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeExterior.Roof)
	self.wndSearchWindow:ClearFocus()
	local nSel = self.wndExtRemodelHeaderFrame:GetRadioSel("ExtRemodelTab")
	if nSel == 1 then
	    self.wndListView:SetCurrentRow(0)
	end
end

function HousingRemodel:OnRemoveWallUpgrade()
	self.luaExtRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeExterior.Wallpaper)
	self.wndSearchWindow:ClearFocus()
	local nSel = self.wndExtRemodelHeaderFrame:GetRadioSel("ExtRemodelTab")
	if nSel == 2 then
	    self.wndListView:SetCurrentRow(0)
	end
end

function HousingRemodel:OnRemoveEntryUpgrade()
	self.luaExtRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeExterior.Entry)
	self.wndSearchWindow:ClearFocus()
	local nSel = self.wndExtRemodelHeaderFrame:GetRadioSel("ExtRemodelTab")
	if nSel == 3 then
	    self.wndListView:SetCurrentRow(0)
	end
end

function HousingRemodel:OnRemoveDoorUpgrade()
	self.luaExtRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeExterior.Door)
	self.wndSearchWindow:ClearFocus()
	local nSel = self.wndExtRemodelHeaderFrame:GetRadioSel("ExtRemodelTab")
	if nSel == 4 then
	    self.wndListView:SetCurrentRow(0)
	end
end

function HousingRemodel:OnRemoveSkyUpgrade()
	self.luaExtRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeExterior.Sky)
	self.wndSearchWindow:ClearFocus()
	local nSel =self.wndExtRemodelHeaderFrame:GetRadioSel("ExtRemodelTab")
	if nSel == 5 then
	    self.wndListView:SetCurrentRow(0)
	end
end

function HousingRemodel:ResetExtRemodelPreview(bOmitSound)
	self.wndSearchWindow:ClearFocus()
	self.wndListView:SetCurrentRow(0)
	if bOmitSound ~= true then
		Sound.Play(Sound.PlayUIHousingItemCancelled)
	end

	self.luaExtRemodelPreviewControl:OnAllChoicesCanceled(false)
end

function HousingRemodel:OnComponentPreviewOnCheck(wndControl, wndHandler, iButton, nX, nY)
	self.wndSearchWindow:ClearFocus()

	if self.bPlayerIsInside then
        -- interior stuff
        if wndControl == self.wndRemodel:FindChild("CeilingPreviewBtn") then
            self.luaIntRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeInterior.Ceiling)
        elseif wndControl == self.wndRemodel:FindChild("IntWallpaperPreviewBtn") then
            self.luaIntRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeInterior.Wallpaper)
        elseif wndControl == self.wndRemodel:FindChild("FloorPreviewBtn") then
            self.luaIntRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeInterior.Floor)
        elseif wndControl == self.wndRemodel:FindChild("TrimPreviewBtn") then
            self.luaIntRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeInterior.Trim)
        elseif wndControl == self.wndRemodel:FindChild("LightingPreviewBtn") then
            self.luaIntRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeInterior.Lighting)
        end
	else
        if wndControl == self.wndRemodel:FindChild("RoofPreviewBtn") then
            self.luaExtRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeExterior.Roof)
        elseif wndControl == self.wndRemodel:FindChild("WallpaperPreviewBtn") then
            self.luaExtRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeExterior.Wallpaper)
        elseif wndControl == self.wndRemodel:FindChild("EntryPreviewBtn") then
            self.luaExtRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeExterior.Entry)
        elseif wndControl == self.wndRemodel:FindChild("DoorPreviewBtn") then
            self.luaExtRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeExterior.Door)
        elseif wndControl == self.wndRemodel:FindChild("SkyPreviewBtn") then
            self.luaExtRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeExterior.Sky)
        end
	end

end

---------------------------------------------------------------------------------------------------

function HousingRemodel:OnRemoveCeilingUpgrade()
	self.luaIntRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeInterior.Ceiling)
	self.wndSearchWindow:ClearFocus()
	local nSel = self.wndIntRemodelHeaderFrame:GetRadioSel("IntRemodelTab")
	if nSel == 1 then
	    self.wndListView:SetCurrentRow(0)
	end
end

function HousingRemodel:OnRemoveTrimUpgrade()
	self.luaIntRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeInterior.Trim)
	self.wndSearchWindow:ClearFocus()
	local nSel = self.wndIntRemodelHeaderFrame:GetRadioSel("IntRemodelTab")
	if nSel == 2 then
	    self.wndListView:SetCurrentRow(0)
	end
end

function HousingRemodel:OnRemoveIntWallpaperUpgrade()
	self.luaIntRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeInterior.Wallpaper)
	self.wndSearchWindow:ClearFocus()
	local nSel = self.wndIntRemodelHeaderFrame:GetRadioSel("IntRemodelTab")
	if nSel == 3 then
	    self.wndListView:SetCurrentRow(0)
	end
end

function HousingRemodel:OnRemoveFloorUpgrade()
	self.luaIntRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeInterior.Floor)
	self.wndSearchWindow:ClearFocus()
	local nSel = self.wndIntRemodelHeaderFrame:GetRadioSel("IntRemodelTab")
	if nSel == 4 then
	    self.wndListView:SetCurrentRow(0)
	end
end

function HousingRemodel:OnRemoveLightingUpgrade()
	self.luaIntRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeInterior.Lighting)
	self.wndSearchWindow:ClearFocus()
	local nSel = self.wndIntRemodelHeaderFrame:GetRadioSel("IntRemodelTab")
	if nSel == 5 then
	    self.wndListView:SetCurrentRow(0)
	end
end

function HousingRemodel:OnRemoveIntOption()
    self.wndSearchWindow:ClearFocus()
    local nSel = self.wndIntRemodelHeaderFrame:GetRadioSel("IntRemodelTab")
    local eType = 0

    if nSel == 1 then --ceiling
        eType = HousingLib.RemodelOptionTypeInterior.Ceiling
    elseif nSel == 2 then -- trim
        eType = HousingLib.RemodelOptionTypeInterior.Trim
    elseif nSel == 3 then -- walls
        eType = HousingLib.RemodelOptionTypeInterior.Wallpaper
    elseif nSel == 4 then -- floor
        eType = HousingLib.RemodelOptionTypeInterior.Floor
    elseif nSel == 5 then -- lighting
        eType = HousingLib.RemodelOptionTypeInterior.Lighting
    end

    HousingLib.RemoveInteriorWallpaper(eType)
    self.luaIntRemodelPreviewControl:OnResidenceChange(gidZone)
end

function HousingRemodel:ResetIntRemodelPreview()
	self.wndListView:SetCurrentRow(0)
	self.luaIntRemodelPreviewControl:OnAllChoicesCanceled(false)
end

function HousingRemodel:PurchaseIntRemodelChanges()
	self.luaIntRemodelPreviewControl:PurchaseRemodelChanges()
end

function HousingRemodel:OnResidenceDecorChanged()
    if self.bPlayerIsInside then
        self.luaIntRemodelPreviewControl:OnResidenceChange(gidZone)
        self:ShowAppropriateRemodelTab()

        -- give the server enough time to process the purchase request, then update the UI
        Apollo.StartTimer("HousingIntRemodelTimer")
    else
        self.luaExtRemodelPreviewControl:OnResidenceChange(gidZone)
    end
end

function HousingRemodel:OnHousingResult(strName, eResult)
	if self.wndRemodel:IsVisible() then
	    if self.playerIsInside then
            self:ResetIntRemodelPreview(false)
        else
            self:ResetExtRemodelPreview(false)
        end
    end
end

function HousingRemodel:OnPlayerCurrencyChanged()
	if self.wndRemodel then
		local eCurrencyType = self.wndCashRemodel:GetCurrency():GetMoneyType()
		local nCurrencyAmount = GameLib.GetPlayerCurrency(eCurrencyType)
		self.wndCashRemodel:SetAmount(nCurrencyAmount, false)
	end
end

function HousingRemodel:OnBuildStarted(plotIndex)
    if plotIndex == 1 and self.wndRemodel:IsVisible() then
        self:OnCloseHousingRemodelWindow()
    end
end

---------------------------------------------------------------------------------------------------
-- PropertySettingsPanel Functions
---------------------------------------------------------------------------------------------------

function HousingRemodel:OnPropertySettingsBtn( wndHandler, wndControl, eMouseButton )
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end

	self.wndPropertySettingsPopup:FindChild("ResidenceName"):SetText(HousingLib.GetPropertyName())

	local split = HousingLib.GetNeighborHarvestSplit()+1
	self.wndPropertySettingsPopup:FindChild("HarvestSharingDropdownWindow"):SetRadioSel("NeighborHarvestBtn", split)

	local wndDropdown = self.wndPropertySettingsPopup:FindChild("HarvestSharingDropdownWindow")
    self.wndPropertySettingsPopup:FindChild("HarvestSharingDropdownLabel"):SetText(wndDropdown:FindChild("NeighborHarvestBtn"..split):GetText())

    local kPrivacyLevel = HousingLib.GetResidencePrivacyLevel()+1
    self.wndPropertySettingsPopup:FindChild("PermissionsDropdownWindow"):SetRadioSel("PermissionsSettingsBtn", kPrivacyLevel)

	local wndDropdown = self.wndPropertySettingsPopup:FindChild("PermissionsDropdownWindow")
    self.wndPropertySettingsPopup:FindChild("PermissionsDropdownLabel"):SetText(wndDropdown:FindChild("PermissionsSettingsBtn"..kPrivacyLevel):GetText())

	self.wndRemodel:Show(false)
	self.wndPropertySettingsPopup:Show(true)
	self.wndPropertySettingsPopup:ToFront()
end

function HousingRemodel:OnHarvestSettingsDropdownBtnCheck( wndHandler, wndControl, eMouseButton )
    self.wndPropertySettingsPopup:FindChild("HarvestSharingDropdownWindow"):Show(true)
end

function HousingRemodel:OnHarvestSettingsDropdownBtnUncheck( wndHandler, wndControl, eMouseButton )
    self.wndPropertySettingsPopup:FindChild("HarvestSharingDropdownWindow"):Show(false)
end

function HousingRemodel:OnHarvestSettingsBtnChecked( wndHandler, wndControl, eMouseButton )
	local split = self.wndPropertySettingsPopup:FindChild("HarvestSharingDropdownWindow"):GetRadioSel("NeighborHarvestBtn")
	HousingLib.SetNeighborHarvestSplit(split-1)

	local wndDropdown = self.wndPropertySettingsPopup:FindChild("HarvestSharingDropdownWindow")
    self.wndPropertySettingsPopup:FindChild("HarvestSharingDropdownLabel"):SetText(wndDropdown:FindChild("NeighborHarvestBtn"..split):GetText())

	self.wndPropertySettingsPopup:FindChild("HarvestSharingDropdownBtn"):SetCheck(false)
	self.wndPropertySettingsPopup:FindChild("HarvestSharingDropdownWindow"):Show(false)
	return true
end

function HousingRemodel:OnCategorySelectionClosed()
    self.wndPropertySettingsPopup:FindChild("HarvestSharingDropdownBtn"):SetCheck(false)
    self.wndPropertySettingsPopup:FindChild("PermissionsDropdownBtn"):SetCheck(false)
end

function HousingRemodel:OnPermissionsDropdownBtnCheck( wndHandler, wndControl, eMouseButton )
    self.wndPropertySettingsPopup:FindChild("PermissionsDropdownWindow"):Show(true)
end

function HousingRemodel:OnPermissionsDropdownBtnUncheck( wndHandler, wndControl, eMouseButton )
    self.wndPropertySettingsPopup:FindChild("PermissionsDropdownWindow"):Show(false)
end

function HousingRemodel:OnPermissionsBtnChecked( wndHandler, wndControl, eMouseButton )
	local kPrivacyLevel = self.wndPropertySettingsPopup:FindChild("PermissionsDropdownWindow"):GetRadioSel("PermissionsSettingsBtn")
	HousingLib.SetResidencePrivacyLevel(kPrivacyLevel-1)

	local wndDropdown = self.wndPropertySettingsPopup:FindChild("PermissionsDropdownWindow")
    self.wndPropertySettingsPopup:FindChild("PermissionsDropdownLabel"):SetText(wndDropdown:FindChild("PermissionsSettingsBtn"..kPrivacyLevel):GetText())

	self.wndPropertySettingsPopup:FindChild("PermissionsDropdownBtn"):SetCheck(false)
	self.wndPropertySettingsPopup:FindChild("PermissionsDropdownWindow"):Show(false)
	return true
end

function HousingRemodel:OnSettingsCancel( wndHandler, wndControl, eMouseButton )
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end

	self.wndPropertySettingsPopup:Show(false)
	self:OnHousingButtonRemodel()
end

-----------------------------------------------------------------------------------------------
-- HousingDecorate Category Dropdown functions
-----------------------------------------------------------------------------------------------
-- populate item list
--[[function HousingRemodel:PopulateCategoryList()
	-- make sure the item list is empty to start with
	self:DestroyCategoryList()

	sortl, sortt, sortr, sortb = self.winSortByList:GetAnchorOffsets()

    -- add 5 items
	for i = 1,5 do
       -- self:AddCategoryItem(i)
        itemHeight = self.tCategoryItems[i]:GetHeight()
	    self.winSortByList:SetAnchorOffsets(sortl, sortt, sortr, sortt+i*itemHeight)
	end

	-- now all the iteam are added, call ArrangeChildrenVert to list out the list items vertically
	self.winSortByList:ArrangeChildrenVert()
end--]]

-- clear the item list
--[[function HousingRemodel:DestroyCategoryList()
	-- destroy all the wnd inside the list
	for idx,wnd in ipairs(self.tCategoryItems) do
		wnd:Destroy()
	end

	-- clear the list item array
	self.tCategoryItems = {}
end--]]

-- add an item into the item list
--[[function HousingRemodel:AddCategoryItem(i)
	-- load the window item for the list item
	local wnd = Apollo.LoadForm("HousingRemodel.xml", "CategoryListItem", self.winSortByList, self)

	-- keep track of the window item created
	self.tCategoryItems[i] = wnd

	-- give it a piece of data to refer to
	local wndItemBtn = wnd:FindChild("CategoryBtn")
	if wndItemBtn then -- make sure the text wnd exist
		wndItemBtn:SetText("Type " .. i) -- set the item wnd's text to "item i"
	end
	wnd:SetData(i)
end

-- when a list item is selected
function HousingRemodel:OnCategoryListItemSelected(wndHandler, wndControl)
    -- make sure the wndControl is valid
    if wndHandler ~= wndControl then
        return
    end--]]

    -- change the old item's text color back to normal color
    --[[local wndItemText
    if self.wndSelectedListItem ~= nil then
        wndItemText = self.wndSelectedListItem:FindChild("Text")
        wndItemText:SetTextColor(kcrNormalText)
    end

	-- wndControl is the item selected - change its color to selected
	self.wndSelectedListItem = wndControl
	wndItemText = self.wndSelectedListItem:FindChild("Text")
    wndItemText:SetTextColor(kcrSelectedText)

	Print( "item " ..  self.wndSelectedListItem:GetData() .. " is selected.")
end--]]

-----------------------------------------------------------------------------------------------
-- HousingRemodel Instance
-----------------------------------------------------------------------------------------------
local HousingRemodelInst = HousingRemodel:new()
HousingRemodelInst:Init()
