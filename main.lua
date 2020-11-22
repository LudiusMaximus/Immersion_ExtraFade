local folderName = ...
local L = LibStub("AceAddon-3.0"):NewAddon(folderName, "AceTimer-3.0")


-- Must fit the hardcoded values of Immersion.
local fadeOutTime = 0.2
local fadeInTime = 0.5


-- Lua API
local _G = _G
local string_find = string.find

local UIFrameFadeOut   = _G.UIFrameFadeOut
local UIFrameFadeIn    = _G.UIFrameFadeIn
local InCombatLockdown = _G.InCombatLockdown


-- Flags
local gossipShown = 0

local cinematicRunning = false
local framerateWasShown = false


local function ConditionalHide(frame)
  if not frame or (frame:IsProtected() and InCombatLockdown()) then return end

  if frame:IsShown() then
    frame.IEF_wasShown = true
    frame:Hide()
  else
    frame.IEF_wasShown = false
  end
end

local function ConditionalShow(frame)
  if not frame then return end

  if frame.IEF_wasShown and not frame:IsShown() then
    if frame:IsProtected() and InCombatLockdown() then
      -- Try again!
      LibStub("AceTimer-3.0"):ScheduleTimer(function() ConditionalShow(frame) end , 0.1)
    else
      frame:Show()
    end
  end
end



local function ConditionalFadeOutTo(frame, targetAlpha)
  if not frame then return end

  if frame:IsShown() then
    frame.IEF_wasShown = true

    -- If we are starting to fade-out while a fade-in was still in progress,
    -- we use the fade-in's target alpha as the original alpha.
    if frame.IEF_fadeInTargetAlpha ~= nil then
      frame.IEF_alphaBeforeFadeOut = frame.IEF_fadeInTargetAlpha
      -- print("Fade-in still in progress. Using", frame.IEF_fadeInTargetAlpha, "instead of", frame:GetAlpha())
    else
      frame.IEF_alphaBeforeFadeOut = frame:GetAlpha()
    end

    UIFrameFadeOut(frame, fadeOutTime, frame:GetAlpha(), targetAlpha)

  else
    frame.IEF_wasShown = false
  end
end

local function ConditionalFadeIn(frame)
  if not frame then return end

  if frame.IEF_wasShown then

    -- Mark that fade-in is in progress.
    frame.IEF_fadeInTargetAlpha = frame.IEF_alphaBeforeFadeOut

    -- The same as UIFrameFadeIn(), but with a callback function.
    local fadeInfo = {};
    fadeInfo.mode = "IN";
    fadeInfo.timeToFade = fadeInTime
    fadeInfo.startAlpha = frame:GetAlpha()
    fadeInfo.endAlpha = frame.IEF_alphaBeforeFadeOut
    fadeInfo.finishedFunc = function(finishedArg1)
        -- print(finishedArg1:GetName(), "finished")
        finishedArg1.IEF_fadeInTargetAlpha = nil
      end
    fadeInfo.finishedArg1 = frame
    UIFrameFade(frame, fadeInfo)

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


if IsAddOnLoaded("GW2_UI") then

  -- GW2_UI seems to offer no way of hooking any of its functions.
  -- So we have to do it like this.
  local enterWorldFrame = CreateFrame("Frame")
  enterWorldFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  enterWorldFrame:SetScript("OnEvent", function()
    if GwExperienceFrame then

      local originalEnter = GwExperienceFrame:GetScript("OnEnter")
      local originalLeave = GwExperienceFrame:GetScript("OnLeave")

      GwExperienceFrame:SetScript("OnEnter", function(...)
        GwExperienceFrame.IEF_tempAlpha = GwExperienceFrame:GetAlpha()
        GwExperienceFrame:SetAlpha(1)
        originalEnter(...)
      end)

      GwExperienceFrame:SetScript("OnLeave", function(...)
        originalLeave(...)
        if GwExperienceFrame.IEF_tempAlpha ~= nil then
          GwExperienceFrame:SetAlpha(GwExperienceFrame.IEF_tempAlpha)
        end
      end)

    end
  end)

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

  if string_find(ownerName, "^ContainerFrame") or ownerName == "ChatFrameChannelButton" or ownerName == "ChatFrameMenuButton" then
    self:Hide()
  -- else
    -- print(ownerName)
  end
end

GameTooltip:HookScript('OnTooltipSetDefaultAnchor', GameTooltipHider)
GameTooltip:HookScript('OnTooltipSetItem', GameTooltipHider)
GameTooltip:HookScript('OnShow', GameTooltipHider)






local function GossipShowFunction()

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

    if GwChatContainer1 then
      GwChatContainer1:SetIgnoreParentAlpha(true)
    end

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

    if GwExperienceFrame then
      GwExperienceFrame:SetIgnoreParentAlpha(true)
      GwExperienceFrame.IEF_tempAlpha = IEF_Config.trackingBarAlpha
      ConditionalFadeOutTo(GwExperienceFrame, GwExperienceFrame.IEF_tempAlpha)
    end

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
    ConditionalHide(QuickJoinToastButton)
    ConditionalHide(PlayerFrame)
    ConditionalHide(PetFrame)
    ConditionalHide(TargetFrame)
    ConditionalHide(BuffFrame)
    ConditionalHide(DebuffFrame)


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


    if IsAddOnLoaded("GW2_UI") then

      -- TODO: Could hide other GW2_UI frames too,
      -- which should not give tooltips while faded...

      if IEF_Config.hideTrackingBar then
        ConditionalHide(GwExperienceFrame)
      end

    end

  end, fadeOutTime)

end

local gossipShowFrame = CreateFrame("Frame")
gossipShowFrame:RegisterEvent("GOSSIP_SHOW")
gossipShowFrame:RegisterEvent("QUEST_COMPLETE")
gossipShowFrame:RegisterEvent("QUEST_DETAIL")
gossipShowFrame:RegisterEvent("QUEST_GREETING")
gossipShowFrame:RegisterEvent("QUEST_PROGRESS")
gossipShowFrame:SetScript("OnEvent", GossipShowFunction)


-- If enteringCombat we only show the hidden frames (which cannot be shown
-- during combat lockdown). But we skip the SetIgnoreParentAlpha(false).
-- This can be done when Immersion exits the NPC interaction.
local function GossipCloseFunction(enteringCombat)

  -- Only do something once per closing.
  if gossipShown == 0 then
    return
  end

  if not enteringCombat then
    gossipShown = 0
  end

  -- print("GossipCloseFunction", enteringCombat)

  -- Show FramerateLabel again.
  if not enteringCombat then
    ConditionalFadeIn(FramerateLabel)
    ConditionalFadeIn(FramerateText)
  end


  -- Fade in the only half faded status bar.
  ConditionalShow(MainMenuExpBar)
  ConditionalFadeIn(MainMenuExpBar)
  ConditionalShow(ReputationWatchBar)
  ConditionalFadeIn(ReputationWatchBar)

  -- Store IEF_tempAlpha for OnEnter/OnLeave.
  if MainMenuExpBar then
    MainMenuExpBar.IEF_tempAlpha = 1
  end

  if ReputationWatchBar then
    ReputationWatchBar.IEF_tempAlpha = 1
  end

  ConditionalShow(QuickJoinToastButton)
  ConditionalShow(PlayerFrame)
  ConditionalShow(PetFrame)
  ConditionalShow(TargetFrame)
  ConditionalShow(BuffFrame)
  ConditionalShow(DebuffFrame)


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


  if IsAddOnLoaded("GW2_UI") then

    -- TODO: Whould have to show other GW2_UI frames again,
    -- which were hidden in GossipShowFunction()...

    if GwExperienceFrame then
      ConditionalShow(GwExperienceFrame)
      ConditionalFadeIn(GwExperienceFrame)
      GwExperienceFrame.IEF_tempAlpha = 1
    end

  end


  -- Cancel timers that may still be in progress.
  if L.frameHideTimer then LibStub("AceTimer-3.0"):CancelTimer(L.frameHideTimer) end
  if L.frameShowTimer then LibStub("AceTimer-3.0"):CancelTimer(L.frameShowTimer) end

  if not enteringCombat then
    -- Reset the IgnoreParentAlpha after the UI fade-in is finished.
    L.frameShowTimer = LibStub("AceTimer-3.0"):ScheduleTimer(function()

      ChatFrame1:SetIgnoreParentAlpha(false)
      ChatFrame1Tab:SetIgnoreParentAlpha(false)
      ChatFrame1EditBox:SetIgnoreParentAlpha(false)

      if GwChatContainer1 then
        GwChatContainer1:SetIgnoreParentAlpha(false)
      end

      ReputationWatchBar:SetIgnoreParentAlpha(false)
      MainMenuExpBar:SetIgnoreParentAlpha(false)

      if GwExperienceFrame then
        GwExperienceFrame:SetIgnoreParentAlpha(false)
      end

    end, fadeInTime)
  end

end


local gossipCloseFrame = CreateFrame("Frame")
gossipCloseFrame:RegisterEvent("GOSSIP_CLOSED")
gossipCloseFrame:RegisterEvent("QUEST_FINISHED")
gossipCloseFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
gossipCloseFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entering combat.
gossipCloseFrame:SetScript("OnEvent", function(self, event, ...)
  -- print("gossipCloseFrame", event)
  if event == "PLAYER_REGEN_DISABLED" then
    GossipCloseFunction(true)
  else
    GossipCloseFunction(false)
  end
end)


-- If we somehow missed to show the frames again, we do it here!
local emergencyFrame = CreateFrame("Frame")
emergencyFrame:SetScript("onUpdate", function(...)
  if not cinematicRunning and gossipShown > 0 and UIParent:GetAlpha() == 1 and gossipShown < GetTime() then
    GossipCloseFunction(false)
  end
end)




local toggleFramerateFrame = CreateFrame("Frame")
toggleFramerateFrame:RegisterEvent("CINEMATIC_START")
toggleFramerateFrame:RegisterEvent("CINEMATIC_STOP")
toggleFramerateFrame:SetScript("OnEvent", function(self, event)
  if event == "CINEMATIC_START" then
    cinematicRunning = true
    if IEF_Config.hideFrameRateCinematic and FramerateLabel:IsVisible() then
      framerateWasShown = true
      ToggleFramerate()
    end
  else
    cinematicRunning = false
    if not FramerateLabel:IsVisible() and framerateWasShown then
      framerateWasShown = false
      ToggleFramerate()
    end
  end
end)



function L:OnInitialize()
  self:InitializeSavedVariables()
  self:InitializeOptions()
end

