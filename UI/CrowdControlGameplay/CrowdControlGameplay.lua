-----------------------------------------------------------------------------------------------
-- Client Lua Script for CrowdControlGameplay
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "Unit"
require "GameLib"

local CrowdControlGameplay = {}

function CrowdControlGameplay:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function CrowdControlGameplay:Init()
    Apollo.RegisterAddon(self)
end

function CrowdControlGameplay:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("CrowdControlGameplay.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function CrowdControlGameplay:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end
	Apollo.RegisterEventHandler("ActivateCCStateStun", "OnActivateCCStateStun", self) -- Starting the UI
	Apollo.RegisterEventHandler("UpdateCCStateStun", "OnUpdateCCStateStun", self) -- Hitting the interact key
	Apollo.RegisterEventHandler("RemoveCCStateStun", "OnRemoveCCStateStun", self) -- Close the UI
	Apollo.RegisterEventHandler("StunVGPressed", "OnStunVGPressed", self)

	Apollo.RegisterTimerHandler("CalculateTimeRemaining", "OnCalculateTimeRemaining", self)

	self.wndProgress = nil
end

-----------------------------------------------------------------------------------------------
-- Rapid Tap
-----------------------------------------------------------------------------------------------

function CrowdControlGameplay:OnActivateCCStateStun(eChosenDirection)
	self.wndProgress = Apollo.LoadForm(self.xmlDoc, "ButtonHit_Progress", nil, self)
	self.wndProgress:Show(true) -- to get the animation
	self.wndProgress:FindChild("TimeRemainingContainer"):Show(false)

	local bLeft 	= eChosenDirection == Unit.CodeEnumCCStateStunVictimGameplay.Left
	local bUp 		= eChosenDirection == Unit.CodeEnumCCStateStunVictimGameplay.Forward
	local bRight 	= eChosenDirection == Unit.CodeEnumCCStateStunVictimGameplay.Right
	local bDown 	= eChosenDirection == Unit.CodeEnumCCStateStunVictimGameplay.Backward

	self.wndProgress:FindChild("ProgressButtonArtLeft"):SetText(bLeft and GameLib.GetKeyBinding("StrafeLeft") or "")
	self.wndProgress:FindChild("ProgressButtonArtUp"):SetText(bUp and GameLib.GetKeyBinding("MoveForward") or "")
	self.wndProgress:FindChild("ProgressButtonArtRight"):SetText(bRight and GameLib.GetKeyBinding("StrafeRight") or "")
	self.wndProgress:FindChild("ProgressButtonArtDown"):SetText(bDown and GameLib.GetKeyBinding("MoveBackward") or "")

	self.wndProgress:FindChild("ProgressButtonArtLeft"):Enable(bLeft)
	self.wndProgress:FindChild("ProgressButtonArtUp"):Enable(bUp)
	self.wndProgress:FindChild("ProgressButtonArtRight"):Enable(bRight)
	self.wndProgress:FindChild("ProgressButtonArtDown"):Enable(bDown)

	if not bLeft and not bUp and not bRight and not bDown then
		-- Error case:
		self:OnRemoveCCStateStun()
		return
	end

	self:OnCalculateTimeRemaining()
end

function CrowdControlGameplay:OnRemoveCCStateStun()
	if self.wndProgress and self.wndProgress:IsValid() then
		self.wndProgress:Destroy()
		self.wndProgress = nil
	end
end

function CrowdControlGameplay:OnUpdateCCStateStun(fProgress) -- Updates Progress Bar
	if not self.wndProgress or not self.wndProgress:IsValid() then
		return
	end

	if self.wndProgress:FindChild("ProgressBar") then
		self.wndProgress:FindChild("ProgressBar"):SetMax(100)
		self.wndProgress:FindChild("ProgressBar"):SetFloor(0)
		self.wndProgress:FindChild("ProgressBar"):SetProgress(fProgress * 100)
	end

	self:OnCalculateTimeRemaining()
end

function CrowdControlGameplay:OnCalculateTimeRemaining()
	local nTimeRemaining = GameLib.GetCCStateStunTimeRemaining()
	if not nTimeRemaining or nTimeRemaining == 0 then
		if self.wndProgress and self.wndProgress:IsValid() then
			Apollo.CreateTimer("CalculateTimeRemaining", 0.1, false) -- Try again, in case it hasn't initialized yet
		end
		return
	end

	if self.wndProgress and self.wndProgress:IsShown() and self.wndProgress:FindChild("TimeRemainingContainer") then
		self.wndProgress:FindChild("TimeRemainingContainer"):Show(true)
		local nMaxTime = self.wndProgress:FindChild("TimeRemainingBar"):GetData()
		if not nMaxTime or nTimeRemaining > nMaxTime then
			nMaxTime = nTimeRemaining
			self.wndProgress:FindChild("TimeRemainingBar"):SetMax(100)
			self.wndProgress:FindChild("TimeRemainingBar"):SetData(nMaxTime)
			self.wndProgress:FindChild("TimeRemainingBar"):SetProgress(100)
		end
		self.wndProgress:FindChild("TimeRemainingBar"):SetProgress(math.min(math.max(nTimeRemaining / nMaxTime * 100, 0), 100), 50) -- 2nd Arg is the rate
	end

	if nTimeRemaining > 0 then
		Apollo.CreateTimer("CalculateTimeRemaining", 0.1, false)
	end
end

function CrowdControlGameplay:OnStunVGPressed(bPushed)
	if self.wndProgress and self.wndProgress:IsValid() then
		self.wndProgress:FindChild("ProgressButtonArtLeft"):SetCheck(bPushed)
		self.wndProgress:FindChild("ProgressButtonArtUp"):SetCheck(bPushed)
		self.wndProgress:FindChild("ProgressButtonArtDown"):SetCheck(bPushed)
		self.wndProgress:FindChild("ProgressButtonArtRight"):SetCheck(bPushed)
	end
end

local CrowdControlGameplayInst = CrowdControlGameplay:new()
CrowdControlGameplayInst:Init()
