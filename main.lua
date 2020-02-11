local folderName = ...
local L = LibStub("AceAddon-3.0"):NewAddon(folderName, "AceTimer-3.0")


-- Must fit the hardcoded values of Immersion.
local fadeOutTime = 0.2
local fadeInTime = 0.5


-- Lua API
local _G = _G
local string_find = string.find

local UIFrameFadeOut = _G.UIFrameFadeOut
local UIFrameFadeIn  = _G.UIFrameFadeIn



-- Flags
local gossipShown = 0



local function ConditionalHide(frame)
  if not frame then return end

  if frame:IsShown() then
    frame.wasShown = true
    frame:Hide()
  else
    frame.wasShown = false
  end
end

local function ConditionalShow(frame)
  if not frame then return end

  if frame.wasShown then
    frame:Show()
  end
end



local function ConditionalFadeOutTo(frame, targetAlpha)
  if frame:IsShown() then
    frame.wasShown = true
    UIFrameFadeOut(frame, fadeOutTime, frame:GetAlpha(), targetAlpha)
  else
    frame.wasShown = false
  end
end

local function ConditionalFadeIn(frame)
  if frame.wasShown then
    UIFrameFadeIn(frame, fadeInTime, frame:GetAlpha(), 1)
  end
end



for _, frame in pairs({ReputationWatchBar, MainMenuExpBar}) do

  local originalEnter = frame:GetScript("OnEnter")
  local originalLeave = frame:GetScript("OnLeave")

  frame:SetScript("OnEnter", function()
    originalEnter(frame)
    ReputationWatchBar.IEF_tempAlpha = ReputationWatchBar:GetAlpha()
    ReputationWatchBar:SetAlpha(1)
    MainMenuExpBar.IEF_tempAlpha = MainMenuExpBar:GetAlpha()
    MainMenuExpBar:SetAlpha(1)
  end )

  frame:SetScript("OnLeave", function()
    originalLeave(frame)
    if (ReputationWatchBar.IEF_tempAlpha ~= nil) then
      ReputationWatchBar:SetAlpha(ReputationWatchBar.IEF_tempAlpha)
    end
    if (MainMenuExpBar.IEF_tempAlpha ~= nil) then
      MainMenuExpBar:SetAlpha(MainMenuExpBar.IEF_tempAlpha)
    end
  end )

end











-- To hide the tooltip of bag items.
-- (While we are actually hiding other frames to suppress their tooltips,
-- this is not practical for the bag, as openning my cause a slight lag.)
local function GameTooltipHider(self)

  if gossipShown == 0 or not self then return end

  local ownerName = nil
  if self:GetOwner() then
    ownerName = self:GetOwner():GetName()
  end
  if ownerName == nil then return end

  if string_find(ownerName, "^ContainerFrame") then
    self:Hide()
  -- else
    -- print(ownerName)
  end
end

GameTooltip:HookScript('OnTooltipSetDefaultAnchor', GameTooltipHider)
GameTooltip:HookScript('OnTooltipSetItem', GameTooltipHider)
GameTooltip:HookScript('OnShow', GameTooltipHider)





local gossipShowFrame = CreateFrame("Frame")
gossipShowFrame:RegisterEvent("GOSSIP_SHOW")
gossipShowFrame:RegisterEvent("QUEST_COMPLETE")
gossipShowFrame:RegisterEvent("QUEST_DETAIL")
gossipShowFrame:RegisterEvent("QUEST_GREETING")
gossipShowFrame:RegisterEvent("QUEST_PROGRESS")
gossipShowFrame:SetScript("OnEvent", function(self, event, ...)

  -- Make sure that this is not run when the gossip view is already shown.
  if gossipShown ~= 0 then
    return
  end
  gossipShown = GetTime()


  if IEF_Config.hideFrameRate then
    ConditionalFadeOutTo(FramerateLabel, 0)
    ConditionalFadeOutTo(FramerateText, 0)
  end

  if not IEF_Config.hideChatFrame then
    ChatFrame1:SetIgnoreParentAlpha(true)
    ChatFrame1Tab:SetIgnoreParentAlpha(true)
    ChatFrame1EditBox:SetIgnoreParentAlpha(true)
  end




  -- Store IEF_tempAlpha for OnEnter/OnLeave.
  if not IEF_Config.hideTrackingBar then

    -- Store tempAlpha for OnEnter/OnLeave.
    MainMenuExpBar:SetIgnoreParentAlpha(true)
    MainMenuExpBar.IEF_tempAlpha = IEF_Config.trackingBarAlpha
    ConditionalFadeOutTo(MainMenuExpBar, MainMenuExpBar.IEF_tempAlpha)
    
    ReputationWatchBar:SetIgnoreParentAlpha(true)
    ReputationWatchBar.IEF_tempAlpha = IEF_Config.trackingBarAlpha
    ConditionalFadeOutTo(ReputationWatchBar, ReputationWatchBar.IEF_tempAlpha)

  end





  -- Cancel timers that may still be in progress.
  if L.frameHideTimer then LibStub("AceTimer-3.0"):CancelTimer(L.frameHideTimer) end
  if L.frameShowTimer then LibStub("AceTimer-3.0"):CancelTimer(L.frameShowTimer) end

  -- Hide frames of which we want no mouseover tooltips while faded.
  L.frameHideTimer = LibStub("AceTimer-3.0"):ScheduleTimer(function()

    -- Minimap, MinimapCluster and ObjectiveTrackerFrame may be excluded from fading out by Immersion.
    -- But we do not need to take care of them here, as they are not causing any unwanted tooltips.

    -- These frames are always faded out by Immersion and cause unwanted tooltips.
    -- So we hide them!
    if QuickJoinToastButton then QuickJoinToastButton:Hide() end
    if PlayerFrame then PlayerFrame:Hide() end
    if PetFrame then PetFrame:Hide() end
    if TargetFrame then TargetFrame:Hide() end
    if BuffFrame then BuffFrame:Hide() end
    if DebuffFrame then DebuffFrame:Hide() end


    if IEF_Config.hideTrackingBar then
      ConditionalHide(MainMenuExpBar)
      ConditionalHide(ReputationWatchBar)
    end


    -- Hide the action bars.
    if Bartender4 then

      ConditionalHide(BT4Bar1)
      ConditionalHide(BT4Bar2)
      ConditionalHide(BT4Bar3)
      ConditionalHide(BT4Bar4)
      ConditionalHide(BT4Bar5)
      ConditionalHide(BT4Bar6)
      ConditionalHide(BT4Bar7)
      ConditionalHide(BT4Bar8)
      ConditionalHide(BT4Bar9)
      ConditionalHide(BT4Bar10)
      ConditionalHide(BT4BarBagBar)
      ConditionalHide(BT4BarMicroMenu)

      ConditionalHide(BT4BarStanceBar)
      ConditionalHide(BT4BarPetBar)

    else

      ConditionalHide(ExtraActionBarFrame)
      ConditionalHide(MainMenuBarArtFrame)
      ConditionalHide(MainMenuBarVehicleLeaveButton)
      ConditionalHide(MicroButtonAndBagsBar)
      ConditionalHide(MultiCastActionBarFrame)
      ConditionalHide(PetActionBarFrame)
      ConditionalHide(PossessBarFrame)
      ConditionalHide(StanceBarFrame)

      ConditionalHide(MultiBarRight)
      ConditionalHide(MultiBarLeft)

    end

  end, fadeOutTime)

end)   -- End of gossipShowFrame.




local function GossipCloseFunction()

  -- Only do something once per closing.
  if gossipShown == 0 then
    return
  end
  gossipShown = 0


  -- Show FramerateLabel again.
  ConditionalFadeIn(FramerateLabel)
  ConditionalFadeIn(FramerateText)


  -- Fade in the only half faded status bar.
  ConditionalShow(MainMenuExpBar)
  ConditionalFadeIn(MainMenuExpBar)
  ConditionalShow(ReputationWatchBar)
  ConditionalFadeIn(ReputationWatchBar)
  
  -- Store IEF_tempAlpha for OnEnter/OnLeave.
  MainMenuExpBar.IEF_tempAlpha = 1
  ReputationWatchBar.IEF_tempAlpha = 1


  if QuickJoinToastButton then QuickJoinToastButton:Show() end
  if PlayerFrame then PlayerFrame:Show() end
  if PetFrame then PetFrame:Show() end
  if TargetFrame then TargetFrame:Show() end
  if BuffFrame then BuffFrame:Show() end
  if DebuffFrame then DebuffFrame:Show() end


  if Bartender4 then

    ConditionalShow(BT4Bar1)
    ConditionalShow(BT4Bar2)
    ConditionalShow(BT4Bar3)
    ConditionalShow(BT4Bar4)
    ConditionalShow(BT4Bar5)
    ConditionalShow(BT4Bar6)
    ConditionalShow(BT4Bar7)
    ConditionalShow(BT4Bar8)
    ConditionalShow(BT4Bar9)
    ConditionalShow(BT4Bar10)
    ConditionalShow(BT4BarBagBar)
    ConditionalShow(BT4BarMicroMenu)

    ConditionalShow(BT4BarStanceBar)
    ConditionalShow(BT4BarPetBar)

  else

    ConditionalShow(ExtraActionBarFrame)
    ConditionalShow(MainMenuBarArtFrame)
    ConditionalShow(MainMenuBarVehicleLeaveButton)
    ConditionalShow(MicroButtonAndBagsBar)
    ConditionalShow(MultiCastActionBarFrame)
    ConditionalShow(PetActionBarFrame)
    ConditionalShow(PossessBarFrame)
    ConditionalShow(StanceBarFrame)

    ConditionalShow(MultiBarRight)
    ConditionalShow(MultiBarLeft)

  end



  -- Cancel timers that may still be in progress.
  if L.frameHideTimer then LibStub("AceTimer-3.0"):CancelTimer(L.frameHideTimer) end
  if L.frameShowTimer then LibStub("AceTimer-3.0"):CancelTimer(L.frameShowTimer) end

  -- Reset the IgnoreParentAlpha after the UI fade in is finished.
  L.frameShowTimer = LibStub("AceTimer-3.0"):ScheduleTimer(function()

    ChatFrame1:SetIgnoreParentAlpha(false)
    ChatFrame1Tab:SetIgnoreParentAlpha(false)
    ChatFrame1EditBox:SetIgnoreParentAlpha(false)

    ReputationWatchBar:SetIgnoreParentAlpha(false)
    MainMenuExpBar:SetIgnoreParentAlpha(false)
    
  end, fadeInTime)

end


local gossipCloseFrame = CreateFrame("Frame")
gossipCloseFrame:RegisterEvent("GOSSIP_CLOSED")
gossipCloseFrame:RegisterEvent("QUEST_FINISHED")
gossipCloseFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
gossipCloseFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entering combat.
gossipCloseFrame:SetScript("OnEvent", function(...)
  GossipCloseFunction()
end)


-- If we somehow missed to show the frames again, we do it here!
local emergencyFrame = CreateFrame("Frame")
emergencyFrame:SetScript("onUpdate", function(...)
  if gossipShown > 0 and UIParent:GetAlpha() == 1 and gossipShown < GetTime() then
    GossipCloseFunction()
  end
end)


function L:OnInitialize()

  self:InitializeSavedVariables()
  self:InitializeOptions()

end

