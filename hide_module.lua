local _, Addon = ...


-- Call Addon.HideUI() to hide UI keeping configured frames.
-- Call Addon.ShowUI(true) when entering combat while UI is hidden.
--   This will show the actually hidden frames, that cannot be shown during combat,
--   but the fade out state will remain. You only see tooltips of faded-out frames.
-- Call Addon.ShowUI(false) to show UI.

-- Expecting configuration in config argument:

-- config.hideFrameRate
-- config.hideAlertFrame
-- config.hideChatFrame
-- config.hideTrackingBar
-- config.trackingBarAlpha



-- Lua API
local _G = _G
local string_find = string.find

local UIFrameFadeOut   = _G.UIFrameFadeOut
local UIFrameFadeIn    = _G.UIFrameFadeIn
local InCombatLockdown = _G.InCombatLockdown


-- Flag. Also needed by emergency handling.
Addon.uiHiddenTime = 0





-- The alert frames are hard to come by...
-- https://www.wowinterface.com/forums/showthread.php?p=337803
-- For testing:
-- /run UIParent:SetAlpha(0.5)
-- /run NewMountAlertSystem:ShowAlert("123"); NewMountAlertSystem:ShowAlert("123")

local collectedAlertFrames = {}
local alertFramesIgnoreParentAlpha = false

local function SetAlertFramesIgnoreParentAlpha(enable)
  alertFramesIgnoreParentAlpha = enable
  for _, v in pairs(collectedAlertFrames) do
    v:SetIgnoreParentAlpha(enable)
  end
end

local function CollectAlertFrame(_, frame)
  if not frame.ludius_collected then
    tinsert(collectedAlertFrames, frame)
    frame.ludius_collected = true
    frame:SetIgnoreParentAlpha(alertFramesIgnoreParentAlpha)
  end
end

for _, subSystem in pairs(AlertFrame.alertFrameSubSystems) do
  local pool = type(subSystem) == 'table' and subSystem.alertFramePool
  if type(pool) == 'table' and type(pool.resetterFunc) == 'function' then
    hooksecurefunc(pool, "resetterFunc", CollectAlertFrame)
  end
end





local function ConditionalHide(frame)
  if not frame or (frame:IsProtected() and InCombatLockdown()) then return end

  if frame:IsShown() then
    frame.ludius_wasShown = true
    frame:Hide()
  else
    frame.ludius_wasShown = false
  end
end

local function ConditionalShow(frame)
  if not frame then return end

  if frame.ludius_wasShown and not frame:IsShown() then
    if frame:IsProtected() and InCombatLockdown() then
      -- Try again!
      LibStub("AceTimer-3.0"):ScheduleTimer(function() ConditionalShow(frame) end , 0.1)
    else
      frame.ludius_wasShown = false
      frame:Show()
    end
  end
end



local function ConditionalFadeOutTo(frame, targetAlpha, fadeOutTime)
  if not frame then return end

  if frame:IsShown() then
    frame.ludius_wasOpaque = true

    -- If we are starting to fade-out while a fade-in was still in progress,
    -- we use the fade-in's target alpha as the original alpha.
    if frame.ludius_fadeInTargetAlpha ~= nil then
      frame.ludius_alphaBeforeFadeOut = frame.ludius_fadeInTargetAlpha
      -- print("Fade-in still in progress. Using", frame.ludius_fadeInTargetAlpha, "instead of", frame:GetAlpha())
    else
      frame.ludius_alphaBeforeFadeOut = frame:GetAlpha()
    end

    UIFrameFadeOut(frame, fadeOutTime, frame:GetAlpha(), targetAlpha)

  else
    frame.ludius_wasOpaque = false
  end
end

local function ConditionalFadeIn(frame, fadeInTime)
  if not frame then return end

  if frame.ludius_wasOpaque then

    -- Mark that fade-in is in progress.
    frame.ludius_fadeInTargetAlpha = frame.ludius_alphaBeforeFadeOut

    -- The same as UIFrameFadeIn(), but with a callback function.
    local fadeInfo = {};
    fadeInfo.mode = "IN";
    fadeInfo.timeToFade = fadeInTime
    fadeInfo.startAlpha = frame:GetAlpha()
    fadeInfo.endAlpha = frame.ludius_alphaBeforeFadeOut
    fadeInfo.finishedFunc = function(finishedArg1)
        -- print(finishedArg1:GetName(), "finished")
        finishedArg1.ludius_wasOpaque = false
        finishedArg1.ludius_fadeInTargetAlpha = nil
      end
    fadeInfo.finishedArg1 = frame
    UIFrameFade(frame, fadeInfo)

  end
end



-- Set the scripts such that hovering over the half-faded tracking bars brings them to full opacity.

-- When entering the standard UI barManager, it gets triggered repeatedly. We only want to store the
-- alpha value of the first call, which is why we have to remember the time.
local enterTime = GetTime()

local function SetStatusBarFading(barManager)
  for _, frame in pairs(barManager.bars) do

    local originalEnter = frame:GetScript("OnEnter")
    local originalLeave = frame:GetScript("OnLeave")

    frame:SetScript("OnEnter", function(...)
      if enterTime < GetTime() then
        barManager.ludius_tempAlpha = barManager:GetAlpha()
        barManager:SetAlpha(1)
        enterTime = GetTime()
      end
      originalEnter(...)
    end)

    frame:SetScript("OnLeave", function(...)
      originalLeave(...)
      if barManager.ludius_tempAlpha ~= nil then
        barManager:SetAlpha(barManager.ludius_tempAlpha)
      end
    end)
  end
end


if Bartender4 then
  hooksecurefunc(Bartender4:GetModule("StatusTrackingBar"), "OnEnable", function()
    SetStatusBarFading(BT4StatusBarTrackingManager)
  end)

else
  hooksecurefunc(StatusTrackingBarManager, "AddBarFromTemplate", SetStatusBarFading)
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
        GwExperienceFrame.ludius_tempAlpha = GwExperienceFrame:GetAlpha()
        GwExperienceFrame:SetAlpha(1)
        originalEnter(...)
      end)

      GwExperienceFrame:SetScript("OnLeave", function(...)
        originalLeave(...)
        if GwExperienceFrame.ludius_tempAlpha ~= nil then
          GwExperienceFrame:SetAlpha(GwExperienceFrame.ludius_tempAlpha)
        end
      end)

    end
  end)

end



-- To hide the tooltip of bag items.
-- (While we are actually hiding other frames to suppress their tooltips,
-- this is not practical for the bag, as openning my cause a slight lag.)
local function GameTooltipHider(self)

  if Addon.uiHiddenTime == 0 or not self then return end

  local ownerName = nil
  if self:GetOwner() then
    ownerName = self:GetOwner():GetName()
  end
  if ownerName == nil then return end

  if string_find(ownerName, "^ContainerFrame") or ownerName == "ChatFrameChannelButton" then
    self:Hide()
  -- else
    -- print(ownerName)
  end
end

GameTooltip:HookScript("OnTooltipSetDefaultAnchor", GameTooltipHider)
GameTooltip:HookScript("OnTooltipSetItem", GameTooltipHider)
GameTooltip:HookScript("OnShow", GameTooltipHider)




Addon.HideUI = function(config, fadeOutTime)

  -- print("HideUI")

  -- Make sure that this is not run when the UI is already hidden.
  if Addon.uiHiddenTime ~= 0 then return end

  Addon.uiHiddenTime = GetTime()


  if config.hideFrameRate then
    ConditionalFadeOutTo(FramerateLabel, 0, fadeOutTime)
    ConditionalFadeOutTo(FramerateText, 0, fadeOutTime)
  end

  if not config.hideAlertFrame then
    CovenantRenownToast:SetIgnoreParentAlpha(true)
    SetAlertFramesIgnoreParentAlpha(true)
  end

  if not config.hideChatFrame then
    ChatFrame1:SetIgnoreParentAlpha(true)
    ChatFrame1Tab:SetIgnoreParentAlpha(true)
    ChatFrame1EditBox:SetIgnoreParentAlpha(true)

    if GwChatContainer1 then
      GwChatContainer1:SetIgnoreParentAlpha(true)
    end
  end

  -- Store ludius_tempAlpha for OnEnter/OnLeave.
  if not config.hideTrackingBar then
    if BT4StatusBarTrackingManager then
      BT4StatusBarTrackingManager:SetIgnoreParentAlpha(true)
      BT4StatusBarTrackingManager.ludius_tempAlpha = config.trackingBarAlpha
      ConditionalFadeOutTo(BT4StatusBarTrackingManager, BT4StatusBarTrackingManager.ludius_tempAlpha, fadeOutTime)
    else
      StatusTrackingBarManager:SetIgnoreParentAlpha(true)
      StatusTrackingBarManager.ludius_tempAlpha = config.trackingBarAlpha
      ConditionalFadeOutTo(StatusTrackingBarManager, StatusTrackingBarManager.ludius_tempAlpha, fadeOutTime)
    end

    if GwExperienceFrame then
      GwExperienceFrame:SetIgnoreParentAlpha(true)
      GwExperienceFrame.ludius_tempAlpha = config.trackingBarAlpha
      ConditionalFadeOutTo(GwExperienceFrame, GwExperienceFrame.ludius_tempAlpha, fadeOutTime)
    end

  end


  -- Got to manually fade out the PartyMemberFrame..NotPresentIcon
  -- and afterwards hide PartyMemberFrame..
  for i = 1, 4, 1 do
    ConditionalFadeOutTo(_G["PartyMemberFrame" .. i .. "NotPresentIcon"], 0, fadeOutTime)
  end


  -- Got to manually fade out these CompactRaidFrame.. child frames
  -- and afterwards hide CompactRaidFrame..
  for i = 1, 40, 1 do
    if _G["CompactRaidFrame" .. i] then
      ConditionalFadeOutTo(_G["CompactRaidFrame" .. i .. "Background"], 0, fadeOutTime)
      ConditionalFadeOutTo(_G["CompactRaidFrame" .. i .. "HorizTopBorder"], 0, fadeOutTime)
      ConditionalFadeOutTo(_G["CompactRaidFrame" .. i .. "HorizBottomBorder"], 0, fadeOutTime)
      ConditionalFadeOutTo(_G["CompactRaidFrame" .. i .. "VertLeftBorder"], 0, fadeOutTime)
      ConditionalFadeOutTo(_G["CompactRaidFrame" .. i .. "VertRightBorder"], 0, fadeOutTime)
    end
  end




  -- Cancel timers that may still be in progress.
  if Addon.frameHideTimer then LibStub("AceTimer-3.0"):CancelTimer(Addon.frameHideTimer) end
  if Addon.frameShowTimer then LibStub("AceTimer-3.0"):CancelTimer(Addon.frameShowTimer) end

  -- Hide frames of which we want no mouseover tooltips while faded.
  Addon.frameHideTimer = LibStub("AceTimer-3.0"):ScheduleTimer(function()

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


    for i = 1, 4, 1 do
      ConditionalHide(_G["PartyMemberFrame" .. i])
    end

    for i = 1, 40, 1 do
      if _G["CompactRaidFrame" .. i] then
        ConditionalHide(_G["CompactRaidFrame" .. i])
      end
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

      if config.hideTrackingBar then
        ConditionalHide(BT4StatusBarTrackingManager)
      end

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

      if config.hideTrackingBar then
        ConditionalHide(StatusTrackingBarManager)
      end

    end


    if IsAddOnLoaded("GW2_UI") then

      -- TODO: Could hide other GW2_UI frames too,
      -- which should not give tooltips while faded...

      if config.hideTrackingBar then
        ConditionalHide(GwExperienceFrame)
      end

    end

  end, fadeOutTime)

end




-- If enteringCombat we only show the hidden frames (which cannot be shown
-- during combat lockdown). But we skip the SetIgnoreParentAlpha(false).
-- This can be done when Immersion exits the NPC interaction.
Addon.ShowUI = function(config, fadeInTime, enteringCombat)

  -- print("ShowUI", enteringCombat)

  -- Only do something once per closing.
  if Addon.uiHiddenTime == 0 then return end

  if not enteringCombat then
    Addon.uiHiddenTime = 0
  end

  -- print("ShowUI", enteringCombat)

  -- Show FramerateLabel again.
  if not enteringCombat then
    ConditionalFadeIn(FramerateLabel, fadeInTime)
    ConditionalFadeIn(FramerateText, fadeInTime)
  end



  for i = 1, 4, 1 do
    -- If we are not checking this, it may happen that the empty PartyMemberFrame
    -- is shown again after NPC interaction, even if the party has been disbanded.
    if UnitInParty("player") then
      ConditionalShow(_G["PartyMemberFrame" .. i])
    end
    ConditionalFadeIn(_G["PartyMemberFrame" .. i .. "NotPresentIcon"], fadeInTime)
  end


  for i = 1, 40, 1 do
    if _G["CompactRaidFrame" .. i] then
      if UnitInRaid("player") then
        ConditionalShow(_G["CompactRaidFrame" .. i])
      end
      ConditionalFadeIn(_G["CompactRaidFrame" .. i .. "Background"], fadeInTime)
      ConditionalFadeIn(_G["CompactRaidFrame" .. i .. "HorizTopBorder"], fadeInTime)
      ConditionalFadeIn(_G["CompactRaidFrame" .. i .. "HorizBottomBorder"], fadeInTime)
      ConditionalFadeIn(_G["CompactRaidFrame" .. i .. "VertLeftBorder"], fadeInTime)
      ConditionalFadeIn(_G["CompactRaidFrame" .. i .. "VertRightBorder"], fadeInTime)
    end
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

    -- Fade in the only half faded status bar.
    ConditionalShow(BT4StatusBarTrackingManager)
    if not enteringCombat then
      ConditionalFadeIn(BT4StatusBarTrackingManager, fadeInTime)
    end
    -- Store ludius_tempAlpha for OnEnter/OnLeave.
    if BT4StatusBarTrackingManager then
      BT4StatusBarTrackingManager.ludius_tempAlpha = 1
    end

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


    -- Fade in the only half faded status bar.
    ConditionalShow(StatusTrackingBarManager)
    if not enteringCombat then
      ConditionalFadeIn(StatusTrackingBarManager, fadeInTime)
    end
    -- Store ludius_tempAlpha for OnEnter/OnLeave.
    if StatusTrackingBarManager then
      StatusTrackingBarManager.ludius_tempAlpha = 1
    end

  end


  if IsAddOnLoaded("GW2_UI") then

    -- TODO: Whould have to show other GW2_UI frames again,
    -- which were hidden in HideUI()...

    if GwExperienceFrame then
      ConditionalShow(GwExperienceFrame)
      ConditionalFadeIn(GwExperienceFrame, fadeInTime)
      GwExperienceFrame.ludius_tempAlpha = 1
    end

  end


  -- Cancel timers that may still be in progress.
  if Addon.frameHideTimer then LibStub("AceTimer-3.0"):CancelTimer(Addon.frameHideTimer) end
  if Addon.frameShowTimer then LibStub("AceTimer-3.0"):CancelTimer(Addon.frameShowTimer) end

  if not enteringCombat then
    -- Reset the IgnoreParentAlpha after the UI fade-in is finished.
    Addon.frameShowTimer = LibStub("AceTimer-3.0"):ScheduleTimer(function()

      SetAlertFramesIgnoreParentAlpha(false)
      CovenantRenownToast:SetIgnoreParentAlpha(false)

      ChatFrame1:SetIgnoreParentAlpha(false)
      ChatFrame1Tab:SetIgnoreParentAlpha(false)
      ChatFrame1EditBox:SetIgnoreParentAlpha(false)

      if GwChatContainer1 then
        GwChatContainer1:SetIgnoreParentAlpha(false)
      end


      if BT4StatusBarTrackingManager then
        BT4StatusBarTrackingManager:SetIgnoreParentAlpha(false)
      else
        StatusTrackingBarManager:SetIgnoreParentAlpha(false)
      end

      if GwExperienceFrame then
        GwExperienceFrame:SetIgnoreParentAlpha(false)
      end

    end, fadeInTime)
  end

end





