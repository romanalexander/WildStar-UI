-----------------------------------------------------------------------------------------------
-- Client Lua Script for Options
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Apollo"
require "Window"

local OptionsAddon = {}

local karStatusTextString =
{
	"Options_AddonInvalid",
	"Options_AddonOff",
	"Options_AddonError",
	"Options_AddonLoaded",
	"Options_AddonSuspended",
	"Options_AddonRunningWithErrors",
	"",
}

local karStatusText =
{
	"CRB_ModuleStatus_Invalid",
	"CRB_ModuleStatus_NotLoaded",
	"CRB_ModuleStatus_ParsingError",
	"CRB_ModuleStatus_Loaded",
	"CRB_ModuleStatus_Suspended",
	"CRB_ModuleStatus_RunningWithErrors",
	"CRB_ModuleStatus_RunningOk",
}

local karStatusColors =
{
	ApolloColor.new("AddonError"),
	ApolloColor.new("AddonNotLoaded"),
	ApolloColor.new("AddonError"),
	ApolloColor.new("AddonLoaded"),
	ApolloColor.new("AddonError"),
	ApolloColor.new("AddonWarning"),
	ApolloColor.new("AddonOk"),
}

local EnumAddonColumns =
{
	Status 			= 1,
	Name 			= 2,
	Folder 			= 3,
	Author			= 4,
	Memory 			= 5,
	Calls 			= 6,
	TotalTime 		= 7,
	MaxTime 		= 8,
	MsPerFrame      = 9,
	LastModified 	= 10,
	APIVersion 		= 11,
	Replaces 		= 12,
	LoadSetting 	= 13,
}

local ktVideoSettingLevels =
{
	["UltraHigh"] =
	{
		["lod.viewDistance"] = 920,
		["lod.farFogDistance"] = 2048,
		["camera.distanceMax"] = 32,
		["lod.textureLodMin"] = 0,
		["lod.textureFilter"] = 2,
		["lod.landLod"] = 1,
		["lod.clutterDistance"] = 128,
		["lod.clutterDensity"] = 2,
		["draw.shadows"] = true,
		["lod.shadowMapSize"] = 4096,
		["lod.renderTargetScale"] = 1,
		["fxaa.preset"] = 5,
		["fxaa.enable"] = true,
		["world.propScreenHeightPercentMin"] = 5,
	},
	["High"] =
	{
		["lod.viewDistance"] = 768,
		["lod.farFogDistance"] = 2048,
		["camera.distanceMax"] = 32,
		["lod.textureLodMin"] = 0,
		["lod.textureFilter"] = 2,
		["lod.landLod"] = 1,
		["lod.clutterDistance"] = 96,
		["lod.clutterDensity"] = 2,
		["draw.shadows"] = true,
		["lod.shadowMapSize"] = 2048,
		["lod.renderTargetScale"] = 1,
		["fxaa.preset"] = 4,
		["fxaa.enable"] = true,
		["world.propScreenHeightPercentMin"] = 5,
	},
	["Medium"] =
	{
		["lod.viewDistance"] = 640,
		["lod.farFogDistance"] = 2048,
		["camera.distanceMax"] = 32,
		["lod.textureLodMin"] = 1,
		["lod.textureFilter"] = 2,
		["lod.landLod"] = 1,
		["lod.clutterDistance"] = 64,
		["lod.clutterDensity"] = 1,
		["draw.shadows"] = true,
		["lod.shadowMapSize"] = 2048,
		["lod.renderTargetScale"] = 1,
		["fxaa.preset"] = 3,
		["fxaa.enable"] = true,
		["world.propScreenHeightPercentMin"] = 8,
	},
	["Low"] =
	{
		["lod.viewDistance"] = 512,
		["lod.farFogDistance"] = 1536,
		["camera.distanceMax"] = 32,
		["lod.textureLodMin"] = 2,
		["lod.textureFilter"] = 1,
		["lod.landLod"] = 0,
		["lod.clutterDistance"] = 48,
		["lod.clutterDensity"] = 0,
		["draw.shadows"] = true,
		["lod.shadowMapSize"] = 1024,
		["lod.renderTargetScale"] = 0.75,
		["fxaa.preset"] = 1,
		["fxaa.enable"] = true,
		["world.propScreenHeightPercentMin"] = 12,
	},
	["UltraLow"] =
	{
		["lod.viewDistance"] = 256,
		["lod.farFogDistance"] = 1024,
		["camera.distanceMax"] = 32,
		["lod.textureLodMin"] = 2,
		["lod.textureFilter"] = 0,
		["lod.landLod"] = 0,
		["lod.clutterDistance"] = 32,
		["lod.clutterDensity"] = 0,
		["draw.shadows"] = false,
		["lod.shadowMapSize"] = 1024,
		["lod.renderTargetScale"] = 0.5,
		["fxaa.preset"] = 0,
		["fxaa.enable"] = false,
		["world.propScreenHeightPercentMin"] = 12,
	}
}

function OptionsAddon:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function OptionsAddon:Init()
	Apollo.RegisterAddon(self)
end

function OptionsAddon:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("OptionsForms.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function OptionsAddon:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end
	Apollo.RegisterTimerHandler("ResChangedTimer", 		"OnResChangedTimer", self)
	Apollo.RegisterTimerHandler("ResExChangedTimer", 	"OnResExChangedTimer", self)
	Apollo.RegisterTimerHandler("AddonsUpdateTimer", 	"OnAddonsUpdateTimer", self)

	Apollo.RegisterEventHandler("SystemKeyDown", 		"OnSystemKeyDown", self)
	Apollo.RegisterEventHandler("TriggerDemoOptions", 	"OnInvokeOptionsScreen", self) --gamescom
	Apollo.RegisterEventHandler("EnteredCombat", 		"OnEnteredCombat", self)
	Apollo.RegisterEventHandler("RefreshOptionsDialog", "OnRefreshOptionsDialog", self)
	Apollo.RegisterEventHandler("InvokeEscapeMenu", 	"OnEscapeMenu", self)

	Apollo.CreateTimer("ResChangedTimer", 1.000, false)
	Apollo.StopTimer("ResChangedTimer")

	Apollo.CreateTimer("ResExChangedTimer", 1.000, false)
	Apollo.StopTimer("ResExChangedTimer")

	self.wndDemo = Apollo.LoadForm(self.xmlDoc, "DemoOptions", nil, self)
	self.wndDemo:Show(IsDemo())

	self.wndDemoGoodbye = Apollo.LoadForm(self.xmlDoc, "DemoSummary", nil, self)
	self.wndDemoGoodbye:Show(false)


	self.wndAddCoins = Apollo.LoadForm(self.xmlDoc, "DemoAddCoin", nil, self)
	self.wndAddCoins:Show(false)

	self.tAddons = {}
	self.nSortedBy = 0

	self.OptionsDlg = Apollo.LoadForm(self.xmlDoc, "OptionsMenu", nil, self)
	self.OptionsDlg:Show(not IsDemo())
	self.OptionsDlg:SetFocus()

	self.wndVideo = Apollo.LoadForm(self.xmlDoc, "VideoOptionsDialog", nil, self)
	Apollo.LoadForm(self.xmlDoc, "VideoOptionsControls", self.wndVideo:FindChild("ScrollPanel"), self)
	self.wndVideo:FindChild("ResolutionParent"):FindChild("Resolution"):Enable(true)
	self.wndVideo:FindChild("DropToggleExclusive"):AttachWindow(self.wndVideo:FindChild("ResolutionParent"))
	self.wndVideoConfirm = self.wndVideo:FindChild("TimedChangeBlocker")
	self.wndVideoConfirm:Show(false)

	----

	self.wndSounds = Apollo.LoadForm(self.xmlDoc, "SoundOptionsDialog", nil, self)
	self.wndAddons = Apollo.LoadForm(self.xmlDoc, "AddonsDialog", nil, self)

	self.wndTargeting = Apollo.LoadForm(self.xmlDoc, "TargettingDialog", nil, self)
	Apollo.LoadForm(self.xmlDoc, "TargettingOptionsControls", self.wndTargeting:FindChild("TargettingDialogControls"), self)

	self.bAddonsTimerCreated = false
	self.OptionsDlg:SetRadioSel("OptionsGroup", 0)
	self:OnOptionsCheck()

	self.nDemoAutoTimeout = 0 -- TODO: more demo

	self.mapCB2CVs =  -- these are auto-mapped options than don't need custom handlers
	{
		{wnd = self.wndVideo:FindChild("VerticalSync"), 		consoleVar = "video.verticalSync"},
		{wnd = self.wndVideo:FindChild("EnableCameraShake"), 	consoleVar = "camera.shake"},
		{wnd = self.wndVideo:FindChild("EnableFixedCamera"), 	consoleVar = "camera.reorient"},

		-- Combat
		{wnd = self.wndTargeting:FindChild("UseButtonDownBtn"), 				consoleVar = "spell.useButtonDownForAbilities"},
		{wnd = self.wndTargeting:FindChild("HoldToContinueCastingBtn"), 		consoleVar = "spell.holdToContinueCasting"},
		{wnd = self.wndTargeting:FindChild("AutoSelfCastBtn"), 					consoleVar = "spell.autoSelectCharacter"},
		{wnd = self.wndTargeting:FindChild("MoveToBtn"), 						consoleVar = "Player.moveToTargetOnSelfAOE"},
		{wnd = self.wndTargeting:FindChild("AutoPushTarget"), 					consoleVar = "spell.disableAutoTargeting"},
		{wnd = self.wndTargeting:FindChild("DashDirectionalBtn"), 				consoleVar = "player.directionalDashBackward"},
		{wnd = self.wndTargeting:FindChild("SelfDisplayBtn"), 					consoleVar = "spell.selfTelegraphDisplay"},
		{wnd = self.wndTargeting:FindChild("EnemyDisplayBtn"), 					consoleVar = "spell.enemyTelegraphDisplay"},
		{wnd = self.wndTargeting:FindChild("EnemyNPCDisplayBtn"), 				consoleVar = "spell.enemyNPCTelegraphDisplay"},
		{wnd = self.wndTargeting:FindChild("EnemyNPCBeneficialDisplayBtn"), 	consoleVar = "spell.enemyNPCBeneficialTelegraphDisplay"},
		{wnd = self.wndTargeting:FindChild("EnemyNPCDetrimentalDisplayBtn"),	consoleVar = "spell.enemyNPCDetrimentalTelegraphDisplay"},
		{wnd = self.wndTargeting:FindChild("EnemyPlayerDisplayBtn"), 			consoleVar = "spell.enemyPlayerTelegraphDisplay"},
		{wnd = self.wndTargeting:FindChild("EnemyPlayerBeneficialDisplayBtn"), 	consoleVar = "spell.enemyPlayerBeneficialTelegraphDisplay"},
		{wnd = self.wndTargeting:FindChild("EnemyPlayerDetrimentalDisplayBtn"), consoleVar = "spell.enemyPlayerDetrimentalTelegraphDisplay"},
		{wnd = self.wndTargeting:FindChild("AllyDisplayBtn"), 					consoleVar = "spell.allyTelegraphDisplay"},
		{wnd = self.wndTargeting:FindChild("PartyAllyDisplayBtn"), 				consoleVar = "spell.partyMemberAllyTelegraphDisplay"},
		{wnd = self.wndTargeting:FindChild("AllyNPCDisplayBtn"), 				consoleVar = "spell.allyNPCTelegraphDisplay"},
		{wnd = self.wndTargeting:FindChild("AllyNPCBeneficialDisplayBtn"), 		consoleVar = "spell.allyNPCBeneficialTelegraphDisplay"},
		{wnd = self.wndTargeting:FindChild("AllyNPCDetrimentalDisplayBtn"), 	consoleVar = "spell.allyNPCDetrimentalTelegraphDisplay"},
		{wnd = self.wndTargeting:FindChild("AllyPlayerDisplayBtn"), 			consoleVar = "spell.allyPlayerTelegraphDisplay"},
		{wnd = self.wndTargeting:FindChild("AllyPlayerBeneficialDisplayBtn"), 	consoleVar = "spell.allyPlayerBeneficialTelegraphDisplay"},
		{wnd = self.wndTargeting:FindChild("AllyPlayerDetrimentalDisplayBtn"), 	consoleVar = "spell.allyPlayerDetrimentalTelegraphDisplay"},
	}

	self.mapSB2CVs =  -- these are auto-mapped sliders that don't need custom handlers
	{
		-- video options
		{wnd = self.wndVideo:FindChild("ViewDistanceSlider"), 		consoleVar = "lod.viewDistance",		buddy = self.wndVideo:FindChild("ViewDistanceEditBox")},
		{wnd = self.wndVideo:FindChild("VDFogSlider"), 				consoleVar = "lod.farFogDistance",		buddy = self.wndVideo:FindChild("VDFogEditBox")},
		{wnd = self.wndVideo:FindChild("ClutterDistanceSlider"), 	consoleVar = "lod.clutterDistance",		buddy = self.wndVideo:FindChild("ClutterDistanceEditBox")},
		{wnd = self.wndVideo:FindChild("CameraDistanceSlider"),		consoleVar = "camera.distanceMax",		buddy = self.wndVideo:FindChild("CameraDistanceEditBox")},
		{wnd = self.wndVideo:FindChild("GammaScaleSlider"),			consoleVar = "ppp.gamma",				buddy = self.wndVideo:FindChild("GammaScaleEditBox"), 			 format = "%.02f"},

		-- audio options
		{wnd = self.wndSounds:FindChild("MasterVolumeSliderBar"), 	consoleVar = "sound.volumeMaster",		buddy = self.wndSounds:FindChild("MasterVolumeEditBox"), 		 format = "%.02f"},
		{wnd = self.wndSounds:FindChild("MusicVolumeSliderBar"), 	consoleVar = "sound.volumeMusic",		buddy = self.wndSounds:FindChild("MusicVolumeEditBox"), 		 format = "%.02f"},
		{wnd = self.wndSounds:FindChild("UIVolumeSliderBar"), 		consoleVar = "sound.volumeUI",			buddy = self.wndSounds:FindChild("UIVolumeEditBox"), 			 format = "%.02f"},
		{wnd = self.wndSounds:FindChild("SoundFXVolumeSliderBar"), 	consoleVar = "sound.volumeSfx",			buddy = self.wndSounds:FindChild("SoundFXVolumeEditBox"), 		 format = "%.02f"},
		{wnd = self.wndSounds:FindChild("AmbientVolumeSliderBar"), 	consoleVar = "sound.volumeAmbient",		buddy = self.wndSounds:FindChild("AmbientVolumeEditBox"), 		 format = "%.02f"},
		{wnd = self.wndSounds:FindChild("VoiceVolumeSliderBar"), 	consoleVar = "sound.volumeVoice",		buddy = self.wndSounds:FindChild("VoiceVolumeEditBox"), 		 format = "%.02f"},

		-- combat options
		{wnd = self.wndTargeting:FindChild("SelfOpacitySliderBar"), 				consoleVar = "spell.selfTelegraphOpacity",						buddy = self.wndTargeting:FindChild("SelfOpacityEditBox")},
		{wnd = self.wndTargeting:FindChild("EnemyDetrimentalOpacitySliderBar"), 	consoleVar = "spell.enemyDetrimentalTelegraphOpacity",			buddy = self.wndTargeting:FindChild("EnemyDetrimentalOpacityEditBox")},
		{wnd = self.wndTargeting:FindChild("AllyBeneficialOpacitySliderBar"), 		consoleVar = "spell.allyBeneficialTelegraphOpacity",				buddy = self.wndTargeting:FindChild("AllyBeneficialOpacityEditBox")},
		{wnd = self.wndTargeting:FindChild("OtherActionOpacitySliderBar"), 			consoleVar = "spell.enemyBeneficalAllyDetrimentalTelegraphOpacity",	buddy = self.wndTargeting:FindChild("OtherActionOpacityEditBox")},
		{wnd = self.wndTargeting:FindChild("OutlineOpacitySliderBar"), 				consoleVar = {"spell.selfTelegraphOutline", "spell.enemyDetrimentalTelegraphOutline", "spell.allyBeneficialTelegraphOutline", "spell.enemyBeneficalAllyDetrimentalTelegraphOutline"},			buddy = self.wndTargeting:FindChild("OutlineOpacityEditBox")},

	}

	self.mapDDParents =
	{
		{wnd = self.wndVideo:FindChild("DropToggleRenderTarget"),	consoleVar = "lod.renderTargetScale",				radio = "RenderTargetScale"},
		{wnd = self.wndVideo:FindChild("DropToggleResolution"),		consoleVar = "video.fullscreen", 					radio = "ResolutionMode"},
		{wnd = self.wndVideo:FindChild("DropToggleTexLOD"),			consoleVar = "lod.textureLodMin",					radio = "TextureResolution"},
		{wnd = self.wndVideo:FindChild("DropToggleTexFilter"),		consoleVar = "lod.textureFilter", 					radio = "TextureFiltering"},
		{wnd = self.wndVideo:FindChild("DropToggleFXAA"),			consoleVar = "fxaa.preset", 						radio = "FXAA"},
		{wnd = self.wndVideo:FindChild("DropToggleClutterDensity"),	consoleVar = "lod.clutterDensity", 					radio = "ClutterDensity"},
		{wnd = self.wndVideo:FindChild("DropToggleSceneDetail"),	consoleVar = "world.propScreenHeightPercentMin", 	radio = "SceneDetail"},
		{wnd = self.wndVideo:FindChild("DropToggleLandLOD"),		consoleVar = "lod.landlod", 						radio = "LandLOD"},
		{wnd = self.wndVideo:FindChild("DropToggleShadow"),			consoleVar = "draw.shadows", 						radio = "ShadowSetting"},
	}

	for idx, wndDD in pairs(self.mapDDParents) do
		wndDD.wnd:AttachWindow(wndDD.wnd:FindChild("ChoiceContainer"))
		wndDD.wnd:FindChild("ChoiceContainer"):Show(false)
	end

	self.wndSounds:FindChild("CinematicSubtitles"):SetCheck(Apollo.GetConsoleVariable("draw.subtitles"))
	self.wndSounds:FindChild("CombatMusicFlair"):SetCheck(Apollo.GetConsoleVariable("sound.intenseBattleMusic"))

	self.wndVideo:FindChild("DropTogglePresetSettings"):AttachWindow(self.wndVideo:FindChild("DropTogglePresetSettings"):FindChild("ChoiceContainer"))
	self.wndVideo:FindChild("DropTogglePresetSettings"):FindChild("ChoiceContainer"):Show(false)

	for strPreset, tPreset in pairs(ktVideoSettingLevels) do
		self.wndVideo:FindChild("DropTogglePresetSettings"):FindChild(strPreset):SetData(self.wndVideo:FindChild("DropTogglePresetSettings"))
	end
	self.wndVideo:FindChild("DropTogglePresetSettings"):FindChild("Custom"):SetData(self.wndVideo:FindChild("DropTogglePresetSettings"))

	self.tPrevExcRes = nil
	self.tPrevResSettings = nil

	-- TODO REMOVE
	local bPlayerSetting = Apollo.GetConsoleVariable("player.showDoubleTapToDash")
	Apollo.SetConsoleVariable("player.doubleTapToDash", bPlayerSetting) -- these should match

	self:InitOptionsControls()

	self.bReachedTheEnd = false
	self.pathMissionCount = 1
	self.pathMissionCompleted = 1

	if not self.bAddonsTimerCreated and not IsDemo() then
		Apollo.CreateTimer("AddonsUpdateTimer", 1.0, true)
		self.bAddonsTimerCreated = true
	end
end

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

function OptionsAddon:OnRefreshOptionsDialog()
	if self.OptionsDlg:IsShown() then
		self:OnOptionsCheck()
	end
end

function OptionsAddon:OnOptionsCheck()
	self:InitOptionsControls()

	local nOptions = self.OptionsDlg:FindChild("InnerFrame"):GetRadioSel("OptionsGroup")
	self.wndVideo:Show(nOptions == 1)
	self.wndSounds:Show(nOptions == 2)
	self.wndAddons:Show(nOptions == 3 and IsInGame())
	self.wndTargeting:Show(nOptions == 4)

	if nOptions ~= 1 and self.nOptionsTimer ~= 0 then -- unsaved graphic change
		self:OnChangeCancelBtn()
	end

	if nOptions == 1 then
		self.wndVideo:SetAnchorOffsets(self.wndVideo:GetAnchorOffsets())
		self:EnableVideoControls()
	elseif nOptions == 2 then
		self.wndSounds:SetAnchorOffsets(self.wndSounds:GetAnchorOffsets())
		self.wndSounds:FindChild("CombatMusicFlair"):SetCheck(Apollo.GetConsoleVariable("sound.intenseBattleMusic"))
		self.wndSounds:FindChild("CinematicSubtitles"):SetCheck(Apollo.GetConsoleVariable("draw.subtitles"))
	elseif nOptions == 3 then
		self.wndAddons:SetAnchorOffsets(self.wndAddons:GetAnchorOffsets())
		self:OnAddonsCheck(true)
	elseif nOptions == 4 then
		self:InitTargetingControls()
		self:OnMappedOptionsCheckboxHider()
		self.wndTargeting:SetAnchorOffsets(self.wndTargeting:GetAnchorOffsets())
	end
end

function OptionsAddon:InitTargetingControls()
	self.wndTargeting:FindChild("DashDoubleTapBtn"):SetCheck(Apollo.GetConsoleVariable("player.showDoubleTapToDash"))
	self.wndTargeting:FindChild("UseAbilityQueueBtn"):SetCheck(Apollo.GetConsoleVariable("player.abilityQueueMax") > 0)
	self.wndTargeting:FindChild("AbilityQueueLengthSliderBar"):SetValue(Apollo.GetConsoleVariable("player.abilityQueueMax") or 0)
	self.wndTargeting:FindChild("AbilityQueueLengthBlocker"):Show(Apollo.GetConsoleVariable("player.abilityQueueMax") == 0)
	self.wndTargeting:FindChild("AbilityQueueLengthEditBox"):SetText(Apollo.GetConsoleVariable("player.abilityQueueMax"))
	self.wndTargeting:FindChild("AlwaysFaceBtn"):SetCheck(not Apollo.GetConsoleVariable("Player.ignoreAlwaysFaceTarget"))
	self.wndTargeting:FindChild("FacingLockBtn"):SetCheck(not Apollo.GetConsoleVariable("Player.disableFacingLock"))
	self.wndTargeting:FindChild("ColorBlindNoneBtn"):SetCheck(Apollo.GetConsoleVariable("world.telegraphColorblindDisplay") == 0)
	self.wndTargeting:FindChild("ColorBlindDeuteranopialBtn"):SetCheck(Apollo.GetConsoleVariable("world.telegraphColorblindDisplay") == 1)
	self.wndTargeting:FindChild("ColorBlindProtanopiaBtn"):SetCheck(Apollo.GetConsoleVariable("world.telegraphColorblindDisplay") == 2)
	self.wndTargeting:FindChild("ColorBlindTratanopiaBtn"):SetCheck(Apollo.GetConsoleVariable("world.telegraphColorblindDisplay") == 3)
end

---------------------------------------------------------------------------------------------------
-- AddonsDialog Functions
---------------------------------------------------------------------------------------------------

function SortConfigButtons(wnd1, wnd2)
	local str1 = ""
	local str2 = ""

	if wnd1 ~= nil and wnd1:FindChild("ConfigureAddonBtn") ~= nil then
		str1 = wnd1:FindChild("ConfigureAddonBtn"):GetText()
	end
	if wnd2 ~= nil and wnd2:FindChild("ConfigureAddonBtn") ~= nil then
		str2 = wnd2:FindChild("ConfigureAddonBtn"):GetText()
	end
	return str1 < str2
end

function OptionsAddon:FillConfigureList()
	self:GetAddonsList()
	local wndList = self.OptionsDlg:FindChild("ConfigureList")

	if self.tConfigureButtons == nil then
		self.tConfigureButtons = {}
	end

	-- copy all existing addons into kill list
	local tKill = {}
	for k, v in pairs(self.tConfigureButtons) do
		tKill[k] = v
	end

	for i, tAddon in ipairs(self.tAddons) do
		if tAddon.bHasConfigure then
			if self.tConfigureButtons[tAddon.strFolder] == nil then
				local wndConf = Apollo.LoadForm(self.xmlDoc, "ConfigureAddonItem", wndList, self)
				wndConf:FindChild("ConfigureAddonBtn"):SetText(tAddon.strConfigureButtonText)
				wndConf:FindChild("ConfigureAddonBtn"):SetData(tAddon.strFolder)
				self.tConfigureButtons[tAddon.strFolder] = wndConf
			else
				self.tConfigureButtons[tAddon.strFolder]:FindChild("ConfigureAddonBtn"):SetText(tAddon.strConfigureButtonText)
			end
			-- remove the addon from the kill list
			tKill[tAddon.strFolder] = nil
		end
	end

	-- if any items remain in kill list, destroy them because we the addon has disappeared
	for k, wnd in pairs(tKill) do
		wnd:Destroy()
		self.tConfigureButtons[k] = nil
	end

	wndList:ArrangeChildrenVert(0, SortConfigButtons)
end

function OptionsAddon:UpdateAddonInfo(tAddon)
	tAddon.strStatus = Apollo.GetString(karStatusText[tAddon.eStatus])

	if tAddon.bCarbine then
		tAddon.strAuthor = Apollo.GetString("Options_AuthorCarbine")
	else
		tAddon.strAuthor = Apollo.GetString("Options_AuthorUnknown") -- this is temporary until the real info is passed from the client
	end
end

function OptionsAddon:GetAddonsList()
	self.tAddons = GetAddons()

	for idx, tAddon in ipairs(self.tAddons) do
		self:UpdateAddonInfo(tAddon)
	end
end

function OptionsAddon:UpdateAddonGridRow(wndGrid, nRow, tAddon)
	wndGrid:SetCellLuaData(nRow, EnumAddonColumns.Name, tAddon.strFolder)
	wndGrid:SetCellText(nRow, EnumAddonColumns.Name, tAddon.strName)
	wndGrid:SetCellText(nRow, EnumAddonColumns.Folder, tAddon.strFolder)
	wndGrid:SetCellText(nRow, EnumAddonColumns.Author, tAddon.strAuthor)
	wndGrid:SetCellText(nRow, EnumAddonColumns.APIVersion, tostring(tAddon.nAPIVersion))

	local strReplace = ""
	for idx, strAddon in ipairs(tAddon.arReplacedAddons) do
		if string.len(strReplace) > 0 then
			strReplace = String_GetWeaselString(Apollo.GetString("Archive_TextList"), strReplace, strAddon)
		else
			strReplace = strAddon
		end
	end
	wndGrid:SetCellText(nRow, EnumAddonColumns.Replaces, strReplace)

	local fTotalTime 	= tAddon.fTotalTime or 0.0
	local nTotalCalls 	= tAddon.nTotalCalls or 0
	local strTotalCalls = string.format("%5d", nTotalCalls)
	local fLongest 		= tAddon.fLongestCall or 0.0
	local strKb 		= string.format("%10.2fKb", tAddon.nMemoryUsage / 1024)
	local strTotalTime 	= string.format("%10.3fs", fTotalTime)
	local strLongest 	= string.format("%10.3fs", fLongest)
	local strMsPerFrame = string.format("%10.3fms", tAddon.fCallTimePerFrame * 1000.0)
	local strStatus 	= Apollo.GetString(karStatusTextString[tAddon.eStatus])

	wndGrid:SetCellText(nRow, EnumAddonColumns.Memory, strKb)
	wndGrid:SetCellText(nRow, EnumAddonColumns.Calls, strTotalCalls)
	wndGrid:SetCellText(nRow, EnumAddonColumns.TotalTime, strTotalTime)
	wndGrid:SetCellText(nRow, EnumAddonColumns.MaxTime, strLongest)
	wndGrid:SetCellText(nRow, EnumAddonColumns.MsPerFrame, strMsPerFrame)
	wndGrid:SetCellText(nRow, EnumAddonColumns.Status, strStatus)
	wndGrid:SetCellImage(nRow, EnumAddonColumns.Status, "CRB_MinimapSprites:sprMMIndicator")
	wndGrid:SetCellImageColor(nRow, EnumAddonColumns.Status, karStatusColors[tAddon.eStatus])

	local strLoad = Apollo.GetString("CRB_No")
	if WillAddonLoad(tAddon.strFolder) then
		strLoad = Apollo.GetString("CRB_Yes")
	end
	wndGrid:SetCellText(nRow, EnumAddonColumns.LoadSetting, strLoad)
	wndGrid:SetCellText(nRow, EnumAddonColumns.LastModified, tAddon.strLastModified)
	wndGrid:SetCellSortText(nRow, EnumAddonColumns.LastModified, tAddon.strLastModifiedSort)
end

function OptionsAddon:OnAddonsCheck(bReload)
	if bReload or self.tAddons == nil then
		self:GetAddonsList()
		self.wndAddons:FindChild("LoadSettings"):Enable(false)
		self.wndAddons:FindChild("ShowError"):Enable(false)
		self.wndAddons:FindChild("Configure"):Enable(false)
	end

	if self.wndErrorDetail ~= nil then
		self.wndErrorDetail:Destroy()
		self.wndErrorDetail = nil
	end
	if self.wndLoadConditions ~= nil then
		self.wndLoadConditions:Destroy()
		self.wndLoadConditions = nil
	end

	local wndGrid = self.wndAddons:FindChild("AddonGrid")
	local nPos = wndGrid:GetVScrollPos()
	local nSortCol = wndGrid:GetSortColumn() or 1
	local bAscending = wndGrid:IsSortAscending()

	wndGrid:DeleteAll()
	for idx, tAddon in ipairs(self.tAddons) do
		local nRow = wndGrid:AddRow(tAddon.strName)
		wndGrid:SetCellLuaData(nRow, EnumAddonColumns.Name, tAddon.strFolder)
		self:UpdateAddonGridRow(wndGrid, nRow, tAddon)
	end
	wndGrid:SetSortColumn(nSortCol, bAscending)
	wndGrid:SetVScrollPos(nPos)
end

function OptionsAddon:OnAddonsUpdateTimer()
	if not IsScreenVisible() then
		return
	end

	self:FillConfigureList()
	self.OptionsDlg:FindChild("Camp"):Enable(IsInGame())
	self.OptionsDlg:FindChild("Stuck"):Enable(IsInGame())

	if IsInCombat() then
		self.OptionsDlg:FindChild("OptionsLabel"):SetTextColor(CColor.new(1, 0, 0, 1))
	else
		self.OptionsDlg:FindChild("OptionsLabel"):SetTextColor(CColor.new(1, 1, 1, 1))
	end

	-- TODO: this logic got borked at some point (addition of the timer?) and the highlight is always shown. Need to investigate.
	if self.wndAddons:IsVisible() then
		local wndGrid = self.wndAddons:FindChild("AddonGrid")
		local arRowsToRemove = {}
		local bHighlightReloadButton = false
		for iRow = 1, wndGrid:GetRowCount() do
			local tNewInfo = GetAddonInfo(wndGrid:GetCellData(iRow, 2))
			if tNewInfo == nil then
				arRowsToRemove[#arRowsToRemove + 1] = iRow
			else
				self:UpdateAddonGridRow(wndGrid, iRow, tNewInfo)

				if (WillAddonLoad(tNewInfo.strFolder) and tNewInfo.eStatus <= OptionsScreen.CodeEnumAddonStatus.ParsingError)
					or (not WillAddonLoad(tNewInfo.strFolder) and tNewInfo.eStatus >= OptionsScreen.CodeEnumAddonStatus.Loaded) then
					bHighlightReloadButton = true
				end
			end
		end
		if bHighlightReloadButton then
			--self.wndAddons:FindChild("ReloadUI"):ChangeArt("CRB_UIKitSprites:btn_square_LARGE_Green")
			self.wndAddons:FindChild("ClickReloadPrompt"):Show(true)
		else
			--self.wndAddons:FindChild("ReloadUI"):ChangeArt("CRB_UIKitSprites:btn_square_LARGE_Red")
			self.wndAddons:FindChild("ClickReloadPrompt"):Show(false)
		end

		for iRow = 1, #arRowsToRemove do
			--wndGrid:DeleteRow(arRowsToRemove[iRow])
			-- TODO TEMP disabled for now
		end
	end
end


function OptionsAddon:OnShowErrors(wndHandler, wndControl)

	if self.strSelectedAddon == nil then
		return
	end

	local tAddon = GetAddonInfo(self.strSelectedAddon)
	if tAddon == nil then
		return
	end

	if self.wndErrorDetail ~= nil then
		self.wndErrorDetail:Destroy()
		self.wndErrorDetail = nil
	end

	local wnd = Apollo.LoadForm("OptionsForms.xml", "AddonError", "OptionsDialogs", self)

	local strError = ""
	for i, str in ipairs(tAddon.arErrors) do
		strError = strError .. str .. "\r\n\r\n"
	end

	wnd:FindChild("ErrorText"):SetText(strError)
	wnd:FindChild("Button1"):SetActionData(OptionsScreen.CodeEnumConfirmButtonType.CopyToClipboard, strError)
	wnd:ToFront()
	self.wndErrorDetail = wnd
end

function OptionsAddon:OnCloseErrorWindow(wndHandler, wndControl)
	wndHandler:GetParent():Destroy()
end

function OptionsAddon:InvokeAddonLoadOnStartDlg(tAddon)
	-- TEMPORARY SOLUTION FOR FX-68822
	if tAddon.strFolder == "EscapeMenu" then
		return
	end

	if self.wndLoadConditions ~= nil then
		self.wndLoadConditions:Destroy()
		self.wndLoadConditions = nil
	end

	local wnd = Apollo.LoadForm("OptionsForms.xml", "AddonLoadOptions", "OptionsDialogs", self)

	self.wndLoadConditions = wnd
	wnd:SetData(tAddon.strFolder)
	self:UpdateAddonLoadSetting(wnd)

	local mapLoadSettingToRadio = {
		[OptionsScreen.CodeEnumLoadType.Default] = 3,
		[OptionsScreen.CodeEnumLoadType.Yes] = 1,
		[OptionsScreen.CodeEnumLoadType.No] = 2,
	}

	local tInfo = GetAccountRealmCharacter()
	wnd:FindChild("Character"):SetText(tInfo.strCharacter)
	wnd:FindChild("Realm"):SetText(tInfo.strRealm)
	wnd:FindChild("Account"):SetText(tInfo.strAccount)

	wnd:FindChild("OptionsFrame"):SetRadioSel("MachineLoad", mapLoadSettingToRadio[tAddon.arLoadConditions[OptionsScreen.CodeEnumLoadLevel.Machine]])
	wnd:FindChild("AdvancedAddonOptions"):SetRadioSel("AccountLoad", mapLoadSettingToRadio[tAddon.arLoadConditions[OptionsScreen.CodeEnumLoadLevel.Account]])
	wnd:FindChild("AdvancedAddonOptions"):SetRadioSel("RealmLoad", mapLoadSettingToRadio[tAddon.arLoadConditions[OptionsScreen.CodeEnumLoadLevel.Realm]])
	wnd:FindChild("AdvancedAddonOptions"):SetRadioSel("CharacterLoad", mapLoadSettingToRadio[tAddon.arLoadConditions[OptionsScreen.CodeEnumLoadLevel.Character]])
	wnd:FindChild("OptionsFrame"):FindChild("IgnoreVersionMismatch"):SetCheck(tAddon.bIgnoreVersion)

	--SetAddonLoadOnStart(tAddon.strFolder, wndHandler:IsChecked())
end

function OptionsAddon:OnSetToDefault()
	self:HelperUncheckAllInnerFrame()
	ResetToDefaultAddons()
end

function OptionsAddon:HelperUncheckAllInnerFrame()
	self.OptionsDlg:FindChild("VideoBtn"):SetCheck(false)
	self.OptionsDlg:FindChild("SoundBtn"):SetCheck(false)
	self.OptionsDlg:FindChild("ExitGame"):SetCheck(false)
	self.OptionsDlg:FindChild("AddonsBtn"):SetCheck(false)
	self.OptionsDlg:FindChild("TargetingBtn"):SetCheck(false)

	self.wndVideo:Show(false)
	self.wndSounds:Show(false)
	self.wndAddons:Show(false)
	self.wndTargeting:Show(false)
end

local g_mapRadioToLoadSetting = {
	OptionsScreen.CodeEnumLoadType.Yes,
	OptionsScreen.CodeEnumLoadType.No,
	OptionsScreen.CodeEnumLoadType.Default,
}

function OptionsAddon:UpdateAddonLoadSetting(wnd)
	local tAddon = GetAddonInfo(wnd:GetData())
	local str = tAddon.strName
	if WillAddonLoad(tAddon.strFolder) then
		str = String_GetWeaselString(Apollo.GetString("Options_WillLoad"), str)
	else
		str = String_GetWeaselString(Apollo.GetString("Options_WillNotLoad"), str)
	end
	wnd:FindChild("AddonTitle"):SetText(str)

	local nAPIVersion = Apollo.GetAPIVersion()
	local str = String_GetWeaselString(Apollo.GetString("Options_APICheck"), nAPIVersion, tAddon.nAPIVersion)
	wnd:FindChild("VersionMatchInformation"):SetText(str)
	if nAPIVersion == tAddon.nAPIVersion then
		wnd:FindChild("VersionMatchInformation"):SetTextColor(CColor.new(1, 1, 1, 1))
	else
		wnd:FindChild("VersionMatchInformation"):SetTextColor(CColor.new(1, 0, 0, 1))
	end
end

function OptionsAddon:OnIgnoreVersionMismatchCheck(wndHandler, wndControl, eMouseButton)
end

function OptionsAddon:OnChangeMachineLoad(wndHandler, wndControl, eMouseButton)
	local wndAddon = wndHandler:GetParent():GetParent()
	local tAddon = GetAddonInfo(wndAddon:GetData())

	local nRadio = wndHandler:GetParent():GetRadioSel("MachineLoad")
	SetAddonLoadCondition(tAddon.strFolder, OptionsScreen.CodeEnumLoadLevel.Machine, g_mapRadioToLoadSetting[nRadio])
	self:UpdateAddonLoadSetting(wndAddon)
end

function OptionsAddon:OnChangeAccountLoad(wndHandler, wndControl, eMouseButton)
	local wndAddon = wndHandler:GetParent():GetParent()
	local tAddon = GetAddonInfo(wndAddon:GetData())

	local nRadio = wndHandler:GetParent():GetRadioSel("AccountLoad")
	SetAddonLoadCondition(tAddon.strFolder, OptionsScreen.CodeEnumLoadLevel.Account, g_mapRadioToLoadSetting[nRadio])
	self:UpdateAddonLoadSetting(wndAddon)
end

function OptionsAddon:OnChangeRealmLoad(wndHandler, wndControl, eMouseButton)
	local wndAddon = wndHandler:GetParent():GetParent()
	local tAddon = GetAddonInfo(wndAddon:GetData())

	local nRadio = wndHandler:GetParent():GetRadioSel("RealmLoad")
	SetAddonLoadCondition(tAddon.strFolder, OptionsScreen.CodeEnumLoadLevel.Realm, g_mapRadioToLoadSetting[nRadio])
	self:UpdateAddonLoadSetting(wndAddon)
end

function OptionsAddon:OnChangeCharacterLoad(wndHandler, wndControl, eMouseButton)
	local wndAddon = wndHandler:GetParent():GetParent()
	local tAddon = GetAddonInfo(wndAddon:GetData())

	local nRadio = wndHandler:GetParent():GetRadioSel("CharacterLoad")
	SetAddonLoadCondition(tAddon.strFolder, OptionsScreen.CodeEnumLoadLevel.Character, g_mapRadioToLoadSetting[nRadio])
	self:UpdateAddonLoadSetting(wndAddon)
end

function OptionsAddon:OnEnableAddonCheck(wndHandler, wndControl, eMouseButton)
	local wndAddon = wndHandler:GetParent():GetParent()
	local tAddon = GetAddonInfo(wndAddon:GetData())
	self:UpdateAddonLoadSetting(wndAddon)
end

function OptionsAddon:OnAddonShowAdvancedToggle(wndHandler, wndControl)
	if wndHandler:IsChecked() then
		wndHandler:GetParent():FindChild("AdvancedAddonOptions"):Show(true)
		wndControl:SetText(Apollo.GetString("Options_HideAdvancedOptions"))
	else
		wndHandler:GetParent():FindChild("AdvancedAddonOptions"):Show(false)
		wndControl:SetText(Apollo.GetString("Options_ShowAdvancedOptions"))
	end
end

function OptionsAddon:OnCloseAddonWindow(wndHandler, wndControl, eMouseButton)
	wndHandler:GetParent():Destroy()
end

function OptionsAddon:OnIgnoreVersionMismatchCheck(wndHandler, wndControl, eMouseButton)
	local bChecked = wndHandler:IsChecked()
	local wndAddon = wndHandler:GetParent():GetParent()
	local tAddon = GetAddonInfo(wndAddon:GetData())
	SetAddonIgnoreVersion(tAddon.strFolder, bChecked)
	self:UpdateAddonLoadSetting(wndAddon)
end

function OptionsAddon:OnChangeLoadSettings(wndHandler, wndControl, eMouseButton)
	if self.strSelectedAddon == nil then
		return
	end

	-- TEMPORARY SOLUTION FOR FX-68822
	if self.strSelectedAddon == "EscapeMenu" then
		return
	end

	local tAddon = GetAddonInfo(self.strSelectedAddon)
	self:InvokeAddonLoadOnStartDlg(tAddon)
end

function OptionsAddon:OnAddonSelChanged(wndHandler, wndControl, nRow, nCol)

	self.strSelectedAddon = wndControl:GetCellData(nRow, 2)
	-- TEMPORARY SOLUTION FOR FX-68822
	self.wndAddons:FindChild("LoadSettings"):Enable(self.strSelectedAddon ~= nil and self.strSelectedAddon ~= "EscapeMenu")

	local bShowErrorsButton = false
	local bShowConfigureButton = false
	if self.strSelectedAddon ~= nil then
		local tAddon = GetAddonInfo(self.strSelectedAddon)
		if tAddon ~= nil and #tAddon.arErrors > 0 then
			bShowErrorsButton = true
		end
		if tAddon ~= nil and tAddon.bHasConfigure and tAddon.eStatus >= OptionsScreen.CodeEnumAddonStatus.RunningWithError then
			bShowConfigureButton = true
		end
	end

	self.wndAddons:FindChild("ShowError"):Enable(bShowErrorsButton)
	self.wndAddons:FindChild("Configure"):Enable(bShowConfigureButton)
end

function OptionsAddon:OnAddonDoubleClick(wndHandler, wndControl, nRow, nCol)
	if nRow <= 0 then
		return
	end

	self.strSelectedAddon = wndControl:GetCellData(nRow, 2)
	local tAddon = GetAddonInfo(self.strSelectedAddon)
	if tAddon ~= nil then
		self:InvokeAddonLoadOnStartDlg(tAddon)
	end
end

function OptionsAddon:OnConfigure(wndHandler, wndControl, eMouseButton)
	CallConfigure(self.strSelectedAddon)
end

function OptionsAddon:OnConfigureAddon(wndHandler, wndControl, eMouseButton)
	CallConfigure(wndControl:GetData())
end

---------------------------------------------------------------------------------------------------
-- End Addons Management functions
---------------------------------------------------------------------------------------------------

function OptionsAddon:OnSystemKeyDown(iKey)
	if iKey == 27 then
		if not IsDemo() or GetDemoTimeRemaining() > 0 then
			self:OnOptionsClose()
		end
	end
	if iKey == 13 then
		--self:OnShowPassword()
	end
end

function OptionsAddon:OnOptionsClose()
	if self.nOptionsTimer ~= 0 then -- unsaved graphic change
		self:OnChangeCancelBtn()
	end

	self.wndTargeting:Show(false) -- TODO Hack for F&F: We hide the window to force a button click to bring it back up (as there's some state initialization there)
	self.OptionsDlg:FindChild("InnerFrame"):FindChild("TargetingBtn"):SetCheck(false)
	CloseOptions()
end

function OptionsAddon:OnExitGame()
	ExitGame()
end

function OptionsAddon:OnRequestCamp( wndHandler, wndControl, eMouseButton )
	RequestCamp()
end

function OptionsAddon:InitOptionsControls()
	self.wndVideoConfirm:Show(false)

	self:RefreshPresetVideoSelection()

	for idx, mapping in pairs(self.mapCB2CVs or {}) do
		if mapping.wnd then
			mapping.wnd:SetCheck(Apollo.GetConsoleVariable(mapping.consoleVar))
			mapping.wnd:SetData(mapping)
		end
	end

	for idx, mapping in pairs(self.mapSB2CVs or {}) do
		if mapping.wnd ~= nil then
			if type(mapping.consoleVar) == "table" then
				mapping.wnd:SetValue(Apollo.GetConsoleVariable(mapping.consoleVar[1]))
			else
				mapping.wnd:SetValue(Apollo.GetConsoleVariable(mapping.consoleVar))
			end

			mapping.wnd:SetData(mapping)
			if mapping.buddy ~= nil then
				local strFormat = "%s"
				if mapping.format ~= nil then
					strFormat = mapping.format
				end

				if type(mapping.consoleVar) == "table" then
					mapping.buddy:SetText(string.format(strFormat, Apollo.GetConsoleVariable(mapping.consoleVar[1])))
				else
					mapping.buddy:SetText(string.format(strFormat, Apollo.GetConsoleVariable(mapping.consoleVar)))
				end
			end
		end
	end

	for idx, parent in pairs(self.mapDDParents or {}) do
		if parent.wnd ~= nil and parent.consoleVar ~= nil and parent.radio ~= nil then
			local arBtns = parent.wnd:FindChild("ChoiceContainer"):GetChildren()
			for idxBtn = 1, #arBtns do
				arBtns[idxBtn]:SetCheck(false)
			end

			if parent.consoleVar == "video.fullscreen" then
				if Apollo.GetConsoleVariable("video.fullscreen") == true then
					if Apollo.GetConsoleVariable("video.exclusive") == true then
						self.wndVideo:SetRadioSel(parent.radio, 3)
						arBtns[3]:SetCheck(true)
						parent.wnd:SetText(arBtns[3]:GetText())
					else
						self.wndVideo:SetRadioSel(parent.radio, 2)
						arBtns[2]:SetCheck(true)
						parent.wnd:SetText(arBtns[2]:GetText())
					end
				else
					self.wndVideo:SetRadioSel(parent.radio, 1)
					arBtns[1]:SetCheck(true)
					parent.wnd:SetText(arBtns[1]:GetText())
				end
			elseif parent.consoleVar == "lod.renderTargetScale" then
				if Apollo.GetConsoleVariable("lod.renderTargetScale") == 1 then
					self.wndVideo:SetRadioSel(parent.radio, 1)
					arBtns[1]:SetCheck(true)
				elseif Apollo.GetConsoleVariable("lod.renderTargetScale") == 0.75 then
					self.wndVideo:SetRadioSel(parent.radio, 2)
					arBtns[2]:SetCheck(true)
				else
					self.wndVideo:SetRadioSel(parent.radio, 3)
					arBtns[3]:SetCheck(true)
				end
			elseif parent.consoleVar == "fxaa.preset" then
				if Apollo.GetConsoleVariable("fxaa.preset") == 5 then
					self.wndVideo:SetRadioSel(parent.radio, 1)
					arBtns[1]:SetCheck(true)
				elseif Apollo.GetConsoleVariable("fxaa.preset") == 4 then
					self.wndVideo:SetRadioSel(parent.radio, 2)
					arBtns[2]:SetCheck(true)
				elseif Apollo.GetConsoleVariable("fxaa.preset") == 3 then
					self.wndVideo:SetRadioSel(parent.radio, 3)
					arBtns[3]:SetCheck(true)
				elseif Apollo.GetConsoleVariable("fxaa.preset") == 2 then -- Note: There's no Ultra Low/Ultra High setting for 2
					self.wndVideo:SetRadioSel(parent.radio, 4)
					arBtns[4]:SetCheck(true)
				elseif Apollo.GetConsoleVariable("fxaa.preset") == 1 then
					self.wndVideo:SetRadioSel(parent.radio, 5)
					arBtns[5]:SetCheck(true)
				else
					self.wndVideo:SetRadioSel(parent.radio, 6)
					arBtns[6]:SetCheck(true)
				end
			elseif parent.consoleVar == "world.propScreenHeightPercentMin" then
				if Apollo.GetConsoleVariable("world.propScreenHeightPercentMin") == 5 then
					self.wndVideo:SetRadioSel(parent.radio, 1)
					arBtns[1]:SetCheck(true)
				elseif Apollo.GetConsoleVariable("world.propScreenHeightPercentMin") == 8 then
					self.wndVideo:SetRadioSel(parent.radio, 2)
					arBtns[2]:SetCheck(true)
				else
					self.wndVideo:SetRadioSel(parent.radio, 3)
					arBtns[3]:SetCheck(true)
				end
			elseif parent.consoleVar == "lod.landlod" then
				if Apollo.GetConsoleVariable("lod.landlod") == 1 then
					self.wndVideo:SetRadioSel(parent.radio, 1)
					arBtns[1]:SetCheck(true)
				else
					self.wndVideo:SetRadioSel(parent.radio, 2)
					arBtns[2]:SetCheck(true)
				end
			elseif parent.consoleVar == "draw.shadows" then
				if Apollo.GetConsoleVariable("draw.shadows") == true then
					if Apollo.GetConsoleVariable("lod.shadowMapSize") == 4096 then
						self.wndVideo:SetRadioSel(parent.radio, 1)
						arBtns[1]:SetCheck(true)
					elseif Apollo.GetConsoleVariable("lod.shadowMapSize") == 2048 then
						self.wndVideo:SetRadioSel(parent.radio, 2)
						arBtns[2]:SetCheck(true)
					else
						self.wndVideo:SetRadioSel(parent.radio, 3)
						arBtns[3]:SetCheck(true)
					end
				else
					self.wndVideo:SetRadioSel(parent.radio, 4)
					arBtns[4]:SetCheck(true)
				end
			else
				self.wndVideo:SetRadioSel(parent.radio, Apollo.GetConsoleVariable(parent.consoleVar) + 1)
				if arBtns[Apollo.GetConsoleVariable(parent.consoleVar) + 1] ~= nil then
					arBtns[Apollo.GetConsoleVariable(parent.consoleVar) + 1]:SetCheck(true)
				end
			end

			local strLabel = Apollo.GetString("Options_Unspecified")
			for idxBtn = 1, #arBtns do
				if arBtns[idxBtn]:IsChecked() then
					strLabel = arBtns[idxBtn]:GetText()
				end
			end

			parent.wnd:SetText(strLabel)
		end
	end

	self:FillConfigureList()

	local bIsInGame = IsInGame()
	self.OptionsDlg:FindChild("AddonsBtn"):Enable(bIsInGame)
	self.OptionsDlg:FindChild("AddonsBtn"):FindChild("RightArrowArt"):Show(bIsInGame)
	self.OptionsDlg:FindChild("Camp"):Enable(bIsInGame)
	if not bIsInGame then
		self.OptionsDlg:FindChild("AddonsBtn"):SetCheck(false)
		self.wndAddons:Show(false)
	end
end

function OptionsAddon:OnInvokeOptionsScreen(nOption)
	self.wndAddCoins:Show(false)
	self.wndDemoGoodbye:Show(false, true)
	self.wndDemo:Show(false, true)
	if nOption == 1 then
		self.wndDemoGoodbye:Show(true)
		return
	elseif nOption == 2 then
		CloseOptions()
		Camp()
		return
	end

	self:InitOptionsControls()
	if IsDemo() then
		self.wndDemo:Show(true)
	end
end

function OptionsAddon:OnReturnToDemo(iOption)
	self.wndDemo:Show(false)
	self.wndDemoGoodbye:Show(false)
	CloseOptions()
end

function OptionsAddon:OnInvokeRestart(wndHandler, wndControl, eMouseButton)
	CloseOptions()
	Camp()
end

function OptionsAddon:OnToggleCoinBtn()
	self.wndAddCoins:Show(true)
	self.wndAddCoins:FindChild("InsertCoinPassword"):SetText("")
	self.wndAddCoins:FindChild("InsertCoinPassword"):SetFocus()
	self.wndAddCoins:FindChild("InsertCoin"):Enable(false)
	self.wndAddCoins:ToFront()
	--self.wndDemo:Show(false)
end

function OptionsAddon:OnHideAddCoin()
	self.wndAddCoins:Show(false)
end

function OptionsAddon:OnPasswordChanged(wndHandler, wndControl, strNew)
	self.wndAddCoins:FindChild("InsertCoin"):Enable(strNew == "g4ffer")
end

function OptionsAddon:OnInsertCoin()
	if self.wndAddCoins:FindChild("InsertCoinPassword"):GetText() == "g4ffer" then
		AddDemoTime(300)
	end
end

------------------------------------------------------------------------------------------
-- End Demo
------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------

function OptionsAddon:OnReloadUI()
	self:HelperUncheckAllInnerFrame()
	ReloadUI()
end

------------------------------------------------------------------------------------------

function OptionsAddon:FillDisplayList()
	local exclusiveDisplayMode = Apollo.GetConsoleVariable("video.exclusiveDisplayMode")
	local arModes = EnumerateDisplayModes()
	local nSel = 0
	local nPos = self.wndVideo:FindChild("ResolutionParent"):FindChild("Resolution"):GetVScrollPos()
	self.wndVideo:FindChild("ResolutionParent"):FindChild("Resolution"):DeleteAll()
	for i, tMode in ipairs(arModes) do
		if tMode.vec.x == exclusiveDisplayMode.x and tMode.vec.y == exclusiveDisplayMode.y and tMode.vec.z == exclusiveDisplayMode.z then
			nSel = i
		end
		local str = tMode.strDisplay
		self.wndVideo:FindChild("ResolutionParent"):FindChild("Resolution"):AddRow(str, "", tMode)
	end
	self.bValidResolution = (nSel > 0)
	self.wndVideo:FindChild("ResolutionParent"):FindChild("Resolution"):SetCurrentRow(nSel)
	self.wndVideo:FindChild("ResolutionParent"):FindChild("Resolution"):SetVScrollPos(nPos)
	
	if not Apollo.GetConsoleVariable("video.exclusive") then
		self.wndVideo:FindChild("DropToggleExclusive"):Enable(false)
		self.wndVideo:FindChild("DropToggleExclusive"):SetText("")
	else
		self.wndVideo:FindChild("DropToggleExclusive"):Enable(true)
		local tDisplayMode = Apollo.GetConsoleVariable("video.exclusiveDisplayMode")
		self.wndVideo:FindChild("DropToggleExclusive"):SetText(tDisplayMode.x .."x".. tDisplayMode.y .."@".. tDisplayMode.z)
	end
end

function OptionsAddon:OnMappedOptionsCheckbox(wndHandler, wndControl)
	Apollo.SetConsoleVariable(wndControl:GetData().consoleVar, wndControl:IsChecked())
	self:EnableVideoControls()
	self:OnMappedOptionsCheckboxHider()
end

function OptionsAddon:OnMappedOptionsCheckboxHider(wndHandler, wndControl)
	self.wndTargeting:FindChild("EnemyNPCBeneficialDisplayBtn"):Enable(self.wndTargeting:FindChild("EnemyDisplayBtn"):IsChecked())
	self.wndTargeting:FindChild("EnemyNPCDetrimentalDisplayBtn"):Enable(self.wndTargeting:FindChild("EnemyDisplayBtn"):IsChecked())
	self.wndTargeting:FindChild("EnemyPlayerBeneficialDisplayBtn"):Enable(self.wndTargeting:FindChild("EnemyDisplayBtn"):IsChecked())
	self.wndTargeting:FindChild("EnemyPlayerDetrimentalDisplayBtn"):Enable(self.wndTargeting:FindChild("EnemyDisplayBtn"):IsChecked())

	self.wndTargeting:FindChild("PartyAllyDisplayBtn"):Enable(self.wndTargeting:FindChild("AllyDisplayBtn"):IsChecked())
	self.wndTargeting:FindChild("AllyNPCBeneficialDisplayBtn"):Enable(self.wndTargeting:FindChild("AllyDisplayBtn"):IsChecked())
	self.wndTargeting:FindChild("AllyNPCDetrimentalDisplayBtn"):Enable(self.wndTargeting:FindChild("AllyDisplayBtn"):IsChecked())
	self.wndTargeting:FindChild("AllyPlayerBeneficialDisplayBtn"):Enable(self.wndTargeting:FindChild("AllyDisplayBtn"):IsChecked())
	self.wndTargeting:FindChild("AllyPlayerDetrimentalDisplayBtn"):Enable(self.wndTargeting:FindChild("AllyDisplayBtn"):IsChecked())
end


function OptionsAddon:OnOptionsSliderChanged(wndHandler, wndControl, fValue, fOldValue)
	local mapping = wndControl:GetData()
	if type(mapping.consoleVar) == "table" then
		for idx, strConsoleVar in pairs(mapping.consoleVar) do
			Apollo.SetConsoleVariable(strConsoleVar, fValue)
		end
	else
		Apollo.SetConsoleVariable(mapping.consoleVar, fValue)
	end
	if mapping.buddy ~= nil then
		local strFormat = "%s"
		if mapping.format ~= nil then
			strFormat = mapping.format
		end

		if type(mapping.consoleVar) == "table" then
			mapping.buddy:SetText(string.format(strFormat, Apollo.GetConsoleVariable(mapping.consoleVar[1])))
		else
			mapping.buddy:SetText(string.format(strFormat, Apollo.GetConsoleVariable(mapping.consoleVar)))
		end
	end

	self:RefreshPresetVideoSelection()
end

function OptionsAddon:OnTextureFilteringRadio(wndHandler, wndControl)
	local ndx = wndControl:GetParent():GetRadioSel("TextureFiltering")
	if ndx == 1 then
		Apollo.SetConsoleVariable("lod.textureFilter", 0)
	elseif ndx == 2 then
		Apollo.SetConsoleVariable("lod.textureFilter", 1)
	elseif ndx == 3 then
		Apollo.SetConsoleVariable("lod.textureFilter", 2)
	end
	wndControl:GetParent():GetParent():SetText(wndControl:GetText())
	wndControl:GetParent():Close()
end

function OptionsAddon:OnClutterDensityRadio(wndHandler, wndControl)
	Apollo.SetConsoleVariable("lod.clutterDensity", wndControl:GetParent():GetRadioSel("ClutterDensity") - 1)
	wndControl:GetParent():GetParent():SetText(wndControl:GetText())
	wndControl:GetParent():Close()
end

function OptionsAddon:OnTextureResolutionRadio(wndHandler, wndControl)
	Apollo.SetConsoleVariable("lod.textureLodBias", wndControl:GetParent():GetRadioSel("TextureResolution") - 1)
	Apollo.SetConsoleVariable("lod.textureLodMin", wndControl:GetParent():GetRadioSel("TextureResolution") - 1)
	wndControl:GetParent():GetParent():SetText(wndControl:GetText())
	wndControl:GetParent():Close()
end

function OptionsAddon:OnFXAARadio(wndHandler, wndControl)
	local ndx = wndControl:GetParent():GetRadioSel("FXAA")
	if ndx == 1 then
		Apollo.SetConsoleVariable("fxaa.preset", 5)
	elseif ndx == 2 then
		Apollo.SetConsoleVariable("fxaa.preset", 4)
	elseif ndx == 3 then
		Apollo.SetConsoleVariable("fxaa.preset", 3)
	elseif ndx == 4 then
		Apollo.SetConsoleVariable("fxaa.preset", 2)
	elseif ndx == 5 then
		Apollo.SetConsoleVariable("fxaa.preset", 1)
	elseif ndx == 6 then
		Apollo.SetConsoleVariable("fxaa.preset", 0)
	end
	Apollo.SetConsoleVariable("fxaa.enable", ndx ~= 6)

	wndControl:GetParent():GetParent():SetText(wndControl:GetText())
	wndControl:GetParent():Close()
end

function OptionsAddon:OnSceneDetailRadio(wndHandler, wndControl)
	local ndx = wndControl:GetParent():GetRadioSel("SceneDetail")
	if ndx == 1 then
		Apollo.SetConsoleVariable("world.propScreenHeightPercentMin", 5)
	elseif ndx == 2 then
		Apollo.SetConsoleVariable("world.propScreenHeightPercentMin", 8)
	elseif ndx == 3 then
		Apollo.SetConsoleVariable("world.propScreenHeightPercentMin", 12)
	end

	wndControl:GetParent():GetParent():SetText(wndControl:GetText())
	wndControl:GetParent():Close()
end

function OptionsAddon:OnRenderTargetRadio(wndHandler, wndControl)
	local ndx = wndControl:GetParent():GetRadioSel("RenderTargetScale")
	if ndx == 1 then
		Apollo.SetConsoleVariable("lod.renderTargetScale", 1)
	elseif ndx == 2 then
		Apollo.SetConsoleVariable("lod.renderTargetScale", 0.75)
	elseif ndx == 3 then
		Apollo.SetConsoleVariable("lod.renderTargetScale", 0.5)
	end

	wndControl:GetParent():GetParent():SetText(wndControl:GetText())
	wndControl:GetParent():Close()
end

function OptionsAddon:OnLandLODRadio(wndHandler, wndControl)
	local ndx = wndControl:GetParent():GetRadioSel("LandLOD")
	if ndx == 1 then
		Apollo.SetConsoleVariable("lod.landlod", 1)
	elseif ndx == 2 then
		Apollo.SetConsoleVariable("lod.landlod", 0)
	end

	wndControl:GetParent():GetParent():SetText(wndControl:GetText())
	wndControl:GetParent():Close()
end

function OptionsAddon:OnShadowsRadio(wndHandler, wndControl)
	local ndx = wndControl:GetParent():GetRadioSel("ShadowSetting")
	if ndx == 1 then
		Apollo.SetConsoleVariable("draw.shadows", true)
		Apollo.SetConsoleVariable("lod.shadowMapSize", 4096)
	elseif ndx == 2 then
		Apollo.SetConsoleVariable("draw.shadows", true)
		Apollo.SetConsoleVariable("lod.shadowMapSize", 2048)
	elseif ndx == 3 then
		Apollo.SetConsoleVariable("draw.shadows", true)
		Apollo.SetConsoleVariable("lod.shadowMapSize", 1024)
	else -- off
		Apollo.SetConsoleVariable("draw.shadows", false)
	end

	wndControl:GetParent():GetParent():SetText(wndControl:GetText())
	wndControl:GetParent():Close()
end

function OptionsAddon:OnResolutionSelChanged(wndHandler, wndControl, nRow)
	local tMode = wndControl:GetCellData(nRow, 1)
	if tMode == nil then
		return
	end
	self.wndVideo:FindChild("ResolutionParent"):Show(false)
	self.wndVideo:FindChild("DropToggleExclusive"):SetText(tMode.strDisplay)
	self.tPrevExcRes = Apollo.GetConsoleVariable("video.exclusiveDisplayMode")
	Apollo.SetConsoleVariable("video.exclusiveDisplayMode", tMode.vec)

	if Apollo.GetConsoleVariable("video.fullscreen") == true and Apollo.GetConsoleVariable("video.exclusive") == true then
		Apollo.StartTimer("ResExChangedTimer")
		self.wndVideoConfirm:Show(true)
		self.wndVideoConfirm:SetData(2)
		self.wndVideoConfirm:FindChild("TextTimer"):SetText("15")
		self.nOptionsTimer = 0
	end
end

function OptionsAddon:OnResExChangedTimer()
	if self.nOptionsTimer < 15 then
		self.nOptionsTimer = self.nOptionsTimer + 1
		self.wndVideoConfirm:Show(true)
		self.wndVideoConfirm:FindChild("TextTimer"):SetText(15 - self.nOptionsTimer)
		Apollo.StartTimer("ResExChangedTimer", 1.000, false)
	else
		self.nOptionsTimer = 0
		self.wndVideoConfirm:Show(false)

		if self.tPrevExcRes ~= nil then
			self.wndVideo:FindChild("DropToggleExclusive"):SetText(self.tPrevExcRes.x .."x".. self.tPrevExcRes.y .."@".. self.tPrevExcRes.z)
			Apollo.SetConsoleVariable("video.exclusiveDisplayMode", self.tPrevExcRes)
			self.tPrevExcRes = nil
		end
	end
end

function OptionsAddon:OnWindowModeToggle(wndHandler, wndControl)
	if wndHandler ~= wndControl then -- in case the window closing trips this
		return
	end
	wndControl:FindChild("ChoiceContainer"):Show(wndControl:IsChecked())
	self:RefreshPresetVideoSelection()
end

function OptionsAddon:OnWindowModeToggleRes(wndHandler, wndControl)
	self.wndVideo:FindChild("ResolutionParent"):Show(wndControl:IsChecked())
	self:FillDisplayList()
end

--Resolution Settings (custom handlers)
function OptionsAddon:OnResWindowed(wndHandler, wndControl)
	self.tPrevResSettings = {Apollo.GetConsoleVariable("video.fullscreen"), Apollo.GetConsoleVariable("video.exclusive")}
	Apollo.SetConsoleVariable("video.fullscreen", false)
	Apollo.SetConsoleVariable("video.exclusive", false)
	self:EnableVideoControls()
	wndControl:GetParent():GetParent():SetText(wndControl:GetText())
	wndControl:GetParent():Close()
end

function OptionsAddon:OnResFullscreen(wndHandler, wndControl)
	self.tPrevResSettings = {Apollo.GetConsoleVariable("video.fullscreen"), Apollo.GetConsoleVariable("video.exclusive")}
	Apollo.SetConsoleVariable("video.fullscreen", true)
	Apollo.SetConsoleVariable("video.exclusive", false)
	self:EnableVideoControls()
	wndControl:GetParent():GetParent():SetText(wndControl:GetText())
	wndControl:GetParent():Close()
end

function OptionsAddon:OnResFullscreenEx(wndHandler, wndControl)
	self.tPrevResSettings = {Apollo.GetConsoleVariable("video.fullscreen"), Apollo.GetConsoleVariable("video.exclusive")}
	Apollo.SetConsoleVariable("video.fullscreen", true)
	Apollo.SetConsoleVariable("video.exclusive", true)
	self:EnableVideoControls()
	wndControl:GetParent():GetParent():SetText(wndControl:GetText())
	wndControl:GetParent():Close()

	self.wndVideoConfirm:Show(true)
	self.wndVideoConfirm:SetData(1)
	self.wndVideoConfirm:FindChild("TextTimer"):SetText("15")
	Apollo.StartTimer("ResChangedTimer")
	self.nOptionsTimer = 0
end

function OptionsAddon:OnResChangedTimer()
	if self.nOptionsTimer < 15 then
		self.nOptionsTimer = self.nOptionsTimer + 1
		self.wndVideoConfirm:Show(true)
		self.wndVideoConfirm:FindChild("TextTimer"):SetText(15 - self.nOptionsTimer)
		Apollo.StartTimer("ResChangedTimer")
	else
		self.nOptionsTimer = 0
		self.wndVideoConfirm:Show(false)

		if self.tPrevResSettings ~= nil then
			Apollo.SetConsoleVariable("video.fullscreen", self.tPrevResSettings[1])
			Apollo.SetConsoleVariable("video.exclusive", self.tPrevResSettings[2])
			self.tPrevResSettings = nil
			self:InitOptionsControls()
			self:EnableVideoControls()
		end
	end
end

function OptionsAddon:EnableVideoControls()
	self:RefreshPresetVideoSelection()
	self:FillDisplayList()
end

function OptionsAddon:RefreshPresetVideoSelection()
	local strMatchingPreset = "Custom"
	if not self.bCustomVideoSettings then
		for strPreset, tPreset in pairs(ktVideoSettingLevels) do
			local bAllMatching = true
			for strConsoleVar, default in pairs(tPreset) do
				if Apollo.GetConsoleVariable(strConsoleVar) ~= default then
					bAllMatching = false
					break
				end
			end

			if bAllMatching then
				strMatchingPreset = strPreset
			end
			self.wndVideo:FindChild("DropTogglePresetSettings"):FindChild(strPreset):SetCheck(false)
		end
	end

	self.wndVideo:FindChild("DropTogglePresetSettings"):FindChild(strMatchingPreset):SetCheck(true)
	self.wndVideo:FindChild("DropTogglePresetSettings"):SetText(self.wndVideo:FindChild("DropTogglePresetSettings"):FindChild(strMatchingPreset):GetText())
end

function OptionsAddon:OnChangeConfirmBtn(wndHandler, wndControl)
	Apollo.StopTimer("ResExChangedTimer")
	Apollo.StopTimer("ResChangedTimer")
	self.wndVideoConfirm:Show(false)
	self.tPrevExcRes = nil
	self.tPrevResSettings = nil
end

function OptionsAddon:OnChangeCancelBtn(wndHandler, wndControl)
	Apollo.StopTimer("ResExChangedTimer")
	Apollo.StopTimer("ResChangedTimer")
	self.nOptionsTimer = 0
	self.wndVideoConfirm:Show(false)

	if self.wndVideoConfirm:GetData() == 1 then --res
		if self.tPrevResSettings ~= nil then
			Apollo.SetConsoleVariable("video.fullscreen", self.tPrevResSettings[1])
			Apollo.SetConsoleVariable("video.exclusive", self.tPrevResSettings[2])
			self.tPrevResSettings = nil
			self:InitOptionsControls()
			self:EnableVideoControls()
		end
	else -- res exc
		if self.tPrevExcRes ~= nil then
			self.wndVideo:FindChild("DropToggleExclusive"):SetText(self.tPrevExcRes.x .."x".. self.tPrevExcRes.y .."@".. self.tPrevExcRes.z)
			Apollo.SetConsoleVariable("video.exclusiveDisplayMode", self.tPrevExcRes)
			self.tPrevExcRes = nil
		end
	end
end

-- Free form Targetting
function OptionsAddon:OnAlwaysFaceCheck(wndHandler, wndControl, eMouseButton)
	Apollo.SetConsoleVariable("Player.ignoreAlwaysFaceTarget", false)
	self.wndTargeting:FindChild("FacingLockBtn"):Enable(true)
	self.wndTargeting:FindChild("FacingLockBtn"):SetTextColor(CColor.new(1, 128/255, 0, 1))
end

function OptionsAddon:OnAlwaysFaceUncheck(wndHandler, wndControl, eMouseButton)
	Apollo.SetConsoleVariable("Player.ignoreAlwaysFaceTarget", true)
	self.wndTargeting:FindChild("FacingLockBtn"):Enable(false)
	self.wndTargeting:FindChild("FacingLockBtn"):SetTextColor(CColor.new(85/255, 43/255, 0, 1))
end

function OptionsAddon:OnFacingLockCheck(wndHandler, wndControl, eMouseButton)
	Apollo.SetConsoleVariable("Player.disableFacingLock", false)
end

function OptionsAddon:OnFacingLockUncheck(wndHandler, wndControl, eMouseButton)
	Apollo.SetConsoleVariable("Player.disableFacingLock", true)
end

-- Movement
function OptionsAddon:OnDashDoubleTapBtn(wndHandler, wndControl, eMouseButton)
	Apollo.SetConsoleVariable("player.doubleTapToDash", wndControl:IsChecked())
	Apollo.SetConsoleVariable("player.showDoubleTapToDash", wndControl:IsChecked())
end

-- Abilities
function OptionsAddon:OnAbilityQueueBtn(wndHandler, wndControl, eMouseButton)
	if wndControl:IsChecked() then
		Apollo.SetConsoleVariable("player.abilityQueueMax", 500)
	else
		Apollo.SetConsoleVariable("player.abilityQueueMax", 0)
	end

	self:OnOptionsCheck()
end

function OptionsAddon:OnAbilityQueueLengthChanged(wndHandler, wndControl, fValue, fOldValue)
	Apollo.SetConsoleVariable("player.abilityQueueMax", fValue)
	self.wndTargeting:FindChild("AbilityQueueLengthEditBox"):SetText(string.format("%.0f", fValue))
end

-- Telegraphs
function OptionsAddon:OnColorBlindNoneBtn(wndHandler, wndControl, eMouseButton)
	Apollo.SetConsoleVariable("world.telegraphColorblindDisplay", 0)
end

function OptionsAddon:OnColorBlindDeuteranopialBtn(wndHandler, wndControl, eMouseButton)
	Apollo.SetConsoleVariable("world.telegraphColorblindDisplay", 1)
end

function OptionsAddon:OnColorBlindProtanopiaBtn(wndHandler, wndControl, eMouseButton)
	Apollo.SetConsoleVariable("world.telegraphColorblindDisplay", 2)
end

function OptionsAddon:OnColorBlindTratanopiaBtn(wndHandler, wndControl, eMouseButton)
	Apollo.SetConsoleVariable("world.telegraphColorblindDisplay", 3)
end

function OptionsAddon:OnEnteredCombat()
	self:OnOptionsClose()
end

function OptionsAddon:OnRestoreDefaults()
	for iTable, tTable in pairs({ self.mapCB2CVs, self.mapSB2CVs, self.mapDDParents }) do
		for idx, tVar in pairs(tTable) do
			if tVar.wnd:IsVisible() then
				Apollo.ResetConsoleVariable(tVar.consoleVar)
			end
		end
	end
	self:OnOptionsCheck()
	
	self.wndVideo:FindChild("RefreshAnimation"):SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthSmallTemp")

end

function OptionsAddon:OnCheckCombatMusicFlair( wndHandler, wndControl, eMouseButton )
	Apollo.SetConsoleVariable("sound.intenseBattleMusic", true)
end

function OptionsAddon:OnUncheckCombatMusicFlair( wndHandler, wndControl, eMouseButton )
	Apollo.SetConsoleVariable("sound.intenseBattleMusic", false)
end

function OptionsAddon:OnCheckCinematicSubtitles( wndHandler, wndControl, eMouseButton )
	Apollo.SetConsoleVariable("draw.subtitles", true)
end

function OptionsAddon:OnUncheckCinematicSubtitles( wndHandler, wndControl, eMouseButton )
	Apollo.SetConsoleVariable("draw.subtitles", false)
end

function OptionsAddon:OnVideoPresetSetting(wndHandler, wndControl, eMouseButton)
	if wndControl:GetName() ~= "Custom" then
		for strConsoleVar, default in pairs(ktVideoSettingLevels[wndControl:GetName()]) do
			Apollo.SetConsoleVariable(strConsoleVar, default)
		end
	end

	self.bCustomVideoSettings = wndControl:GetName() == "Custom"

	self:EnableVideoControls()
	self:InitOptionsControls()
	local wndParent = wndControl:GetData()
	wndParent:SetText(wndControl:GetText())
	wndParent:FindChild("ChoiceContainer"):Close()
end

function OptionsAddon:OnStuck(wndHandler, wndControl, eMouseButton)
	ShowStuckUI()
	CloseOptions()
end

---------------------------------------------------------------------------------------------------
-- Options instance
---------------------------------------------------------------------------------------------------
local OptionsInst = OptionsAddon:new()
OptionsAddon:Init()
