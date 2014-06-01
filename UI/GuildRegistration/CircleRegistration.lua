-----------------------------------------------------------------------------------------------
-- Client Lua Script for CircleRegistration
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"

local CircleRegistration = {}

local kcrDefaultText = CColor.new(47/255, 148/255, 172/255, 1.0)
local kcrHighlightedText = CColor.new(49/255, 252/255, 246/255, 1.0)
local eProfanityFilter = GameLib.CodeEnumUserTextFilterClass.Strict

local kstrDefaultOption =
{
	Apollo.GetString("CRB_Circle_Master"),
	Apollo.GetString("CRB_Circle_Council"),
	Apollo.GetString("Circle_SoloMember")
}

function CircleRegistration:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function CircleRegistration:Init()
    Apollo.RegisterAddon(self)
end

function CircleRegistration:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("CircleRegistration.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function CircleRegistration:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end
	Apollo.RegisterEventHandler("EventGeneric_OpenCircleRegistrationPanel", "OnEventGeneric_OpenCircleRegistrationPanel", self)
end

function CircleRegistration:Initialize(wndParent)
	Apollo.RegisterEventHandler("GuildResultInterceptResponse", "OnGuildResultInterceptResponse", self)
	Apollo.RegisterTimerHandler("ErrorMessageTimer", 		"OnErrorMessageTimer", self)
	Apollo.RegisterTimerHandler("SuccessfulMessageTimer", 	"OnSuccessfulMessageTimer", self)

	if self.wndMain then
		self.wndMain:Destroy()
	end

	self.wndMain 				= Apollo.LoadForm(self.xmlDoc, "CircleRegistrationForm", wndParent, self)
	self.wndCircleRegAlert 		= self.wndMain:FindChild("AlertMessage")
	self.wndCircleRegName 		= self.wndMain:FindChild("CircleRegistrationWnd"):FindChild("GuildNameString")
	self.wndRegisterCircleBtn 	= self.wndMain:FindChild("CircleRegistrationWnd"):FindChild("RegisterBtn")
	self.xmlDoc = nil

	-- TODO Refactor below, we can just look up the info when the create button is hit
	self.tCreate =
	{
		strName 		= "",
		eGuildType 		= GuildLib.GuildType_Circle,
		strMaster 		= kstrDefaultMaster,
		strCouncil 		= kstrDefaultCouncil,
		strMember 		= kstrDefaultMember
	}

	self.arCircleRegOptions = {} -- the various guild settings
	for idx = 1, 3 do
		self.arCircleRegOptions[idx] =
		{
			wndOption = self.wndMain:FindChild("CircleRegistrationWnd"):FindChild("OptionString_" .. idx),
			--wndButton = self.wndMain:FindChild("CircleRegistrationWnd"):FindChild("LabelRevertBtn_" .. idx)
		}
		self.arCircleRegOptions[idx].wndOption:SetData(idx)
		--self.arCircleRegOptions[idx].wndButton:SetData(idx)
	end
end

function CircleRegistration:OnEventGeneric_OpenCircleRegistrationPanel(wndParent)
	if not self.wndMain or not self.wndMain:IsValid() then
		self:Initialize(wndParent)
	end
	
	if not self.wndMain:IsShown() then
		self.wndMain:Invoke()
	end
	
	self:OnFullRedrawOfRegistration()
end

function CircleRegistration:OnClose()
	Apollo.StopTimer("LeftCircleMessageTimer")
	Apollo.StopTimer("SuccessfulMessageTimer")
	Apollo.StopTimer("ErrorMessageTimer")

	self.wndCircleRegAlert:Show(false)

	self.wndMain:FindChild("CircleRegistrationWnd"):Show(false)
end

-----------------------------------------------------------------------------------------------
-- Circle registration functions
-----------------------------------------------------------------------------------------------

function CircleRegistration:OnFullRedrawOfRegistration()
	-- First reset registration options
	for idx = 1, 3 do
		self.arCircleRegOptions[idx].wndOption:SetText(kstrDefaultOption[idx])
	end

	self.wndCircleRegAlert:Show(false)
	self.wndCircleRegAlert:FindChild("MessageAlertText"):SetText("")
	self.wndCircleRegAlert:FindChild("MessageBodyText"):SetText("")
	self.wndCircleRegName:SetText("")

	self:HelperClearCircleRegFocus()
	self:UpdateCircleRegOptions()

	self.wndMain:FindChild("CircleRegistrationWnd"):Show(true)
end

function CircleRegistration:OnCircleRegNameChanging(wndHandler, wndControl)
	local strInput = self.wndCircleRegName:GetText() or ""
	self.tCreate.strName = strInput
	self:UpdateCircleRegOptions()

	self.wndMain:FindChild("InvalidInputWarning"):Show(strInput ~= "" and not GameLib.IsTextValid(strInput, GameLib.CodeEnumUserText.GuildName, eProfanityFilter))
end

function CircleRegistration:OnCircleRegOptionChanging(wndHandler, wndControl)
	local nRank = wndControl:GetData()
	if nRank == 1 then
		self.tCreate.strMaster = wndControl:GetText()
	elseif nRank == 2 then
		self.tCreate.strCouncil = wndControl:GetText()
	else
		self.tCreate.strMember = wndControl:GetText()
	end

	self:UpdateCircleRegOptions()
end

function CircleRegistration:UpdateCircleRegOptions()
	--see which fields need undo buttons
	for idx = 1, 3 do
		if self.arCircleRegOptions[idx].wndOption:GetText() ~= kstrDefaultOption[idx] then
			--self.arCircleRegOptions[idx].wndButton:Enable(true)
			self.arCircleRegOptions[idx].wndOption:SetTextColor(kcrHighlightedText)
		else
			--self.arCircleRegOptions[idx].wndButton:Enable(false)
			self.arCircleRegOptions[idx].wndOption:SetTextColor(kcrDefaultText)
		end
	end

	local strMasterName = self.arCircleRegOptions[1].wndOption:GetText()
	local strCouncilName = self.arCircleRegOptions[2].wndOption:GetText()
	local strMemberName = self.arCircleRegOptions[3].wndOption:GetText()
	
	--see if the Guild can be submitted
	local bHasName = self:HelperCheckForEmptyString(self.wndCircleRegName:GetText())
	local bNameValid = GameLib.IsTextValid( self.wndCircleRegName:GetText(), GameLib.CodeEnumUserText.GuildName, eProfanityFilter)
	local bHasMaster = self:HelperCheckForEmptyString(strMasterName) and GameLib.IsTextValid(strMasterName, GameLib.CodeEnumUserText.GuildRankName, eProfanityFilter)
	local bHasCouncil = self:HelperCheckForEmptyString(strCouncilName) and GameLib.IsTextValid(strCouncilName, GameLib.CodeEnumUserText.GuildRankName, eProfanityFilter)
	local bHasMember = self:HelperCheckForEmptyString(strMemberName) and GameLib.IsTextValid(strMemberName, GameLib.CodeEnumUserText.GuildRankName, eProfanityFilter)
	self.wndRegisterCircleBtn:Enable(bHasName and bNameValid and bHasMaster and bHasCouncil and bHasMember)
end

function CircleRegistration:HelperCheckForEmptyString(strText) -- make sure there's a valid string
	local strFirstChar = string.find(strText, "%S")
	return strFirstChar ~= nil and string.len(strFirstChar) > 0
end

function CircleRegistration:HelperClearCircleRegFocus(wndHandler, wndControl)
	for idx = 1, 3 do
		self.arCircleRegOptions[idx].wndOption:ClearFocus()
	end
	self.wndCircleRegName:ClearFocus()
end

-----------------------------------------------------------------------------------------------
function CircleRegistration:UseDefaultTitleBtn(wndHandler, wndControl) -- reset an option to its default
	local nRank = wndControl:GetData()
	self.arCircleRegOptions[nRank].wndOption:SetText(kstrDefaultOption[nRank])
	self:HelperClearCircleRegFocus()
	self:UpdateCircleRegOptions()
end

function CircleRegistration:OnCircleRegBtn(wndHandler, wndControl)
	local tGuildInfo = self.tCreate -- TODO Refactor
	local arGuldResultsExpected = { GuildLib.GuildResult_Success,  GuildLib.GuildResult_AtMaxGuildCount, GuildLib.GuildResult_InvalidGuildName, 
									 GuildLib.GuildResult_GuildNameUnavailable, GuildLib.GuildResult_NotEnoughRenown, GuildLib.GuildResult_NotEnoughCredits,
									 GuildLib.GuildResult_InsufficientInfluence, GuildLib.GuildResult_NotHighEnoughLevel, GuildLib.GuildResult_YouJoined,
									 GuildLib.GuildResult_YouCreated, GuildLib.GuildResult_MaxArenaTeamCount, GuildLib.GuildResult_MaxWarPartyCount,
									 GuildLib.GuildResult_AtMaxCircleCount, GuildLib.GuildResult_VendorOutOfRange }

	Event_FireGenericEvent("GuildResultInterceptRequest", tGuildInfo.eGuildType, self.wndMain, arGuldResultsExpected )
	GuildLib.Create(tGuildInfo.strName, tGuildInfo.eGuildType, tGuildInfo.strMaster, tGuildInfo.strCouncil, tGuildInfo.strMember)

	self:HelperClearCircleRegFocus()
	self.wndRegisterCircleBtn:Enable(false)
	self.wndMain:FindChild("CircleRegistrationWnd"):Show(false)
	self:OnClose()
	--need to reset info, because next time a circle is created, if the any field isn't updated, it will remain the same it was last circle
	self.tCreate =
	{
		strName 		= "",
		eGuildType 		= GuildLib.GuildType_Circle,
		strMaster 		= kstrDefaultMaster,
		strCouncil 		= kstrDefaultCouncil,
		strMember 		= kstrDefaultMember
	}
end

function CircleRegistration:OnGuildResultInterceptResponse( guildCurr, eGuildType, eResult, wndRegistration, strAlertMessage )
	if eGuildType ~= GuildLib.GuildType_Circle or wndRegistration ~= self.wndMain then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, strAlertMessage, "")
		return
	end

	if not self.wndCircleRegAlert or not self.wndCircleRegAlert:IsValid() then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, strAlertMessage, "")
		return
	end

	self.wndCircleRegAlert:FindChild("MessageBodyText"):SetText(strAlertMessage)
	self.wndCircleRegAlert:Show(true)
	if eResult == GuildLib.GuildResult_Success or eResult == GuildLib.GuildResult_YouCreated or eResult == GuildLib.GuildResult_YouJoined then
		self.wndCircleRegAlert:FindChild("MessageAlertText"):SetTextColor(ApolloColor.new("UI_WindowTextTextPureGreen"))
		self.wndCircleRegAlert:FindChild("MessageAlertText"):SetText(Apollo.GetString("GuildResult_Success"))
		Apollo.CreateTimer("SuccessfulMessageTimer", 3.00, false)
	else
		self.wndCircleRegAlert:FindChild("MessageAlertText"):SetTextColor(ApolloColor.new("ConTough"))
		self.wndCircleRegAlert:FindChild("MessageAlertText"):SetText(Apollo.GetString("Error"))
		Apollo.CreateTimer("ErrorMessageTimer", 3.00, false)
	end
end

function CircleRegistration:OnSuccessfulMessageTimer()
	self:OnClose()
end

function CircleRegistration:OnErrorMessageTimer()
	self:OnClose()
end

-----------------------------------------------------------------------------------------------
-- CircleRegistration Instance
-----------------------------------------------------------------------------------------------
local CircleRegistrationInst = CircleRegistration:new()
CircleRegistrationInst:Init()
