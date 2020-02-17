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
local partyMemberFrameShown = {}
local partyMemberFrameNotPresentIconShown = {}


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
    frame.IEF_originalAlpha = frame:GetAlpha()
    UIFrameFadeOut(frame, fadeOutTime, frame:GetAlpha(), targetAlpha)
  else
    frame.IEF_wasShown = false
  end
end

local function ConditionalFadeIn(frame)
  if not frame then return end

  if frame.IEF_wasShown then
    UIFrameFadeIn(frame, fadeInTime, frame:GetAlpha(), frame.IEF_originalAlpha)
  end
end






-- Set the scripts such that hovering over the half-faded tracking bars brings them to full opacity.
local function SetStatusBarFading(barManager)
  for _, frame in pairs(barManager.bars) do
    if not frame.IEF_hooked then
      frame.IEF_hooked = true

      local originalEnter = frame:GetScript("OnEnter")
      local originalLeave = frame:GetScript("OnLeave")

      frame:SetScript("OnEnter", function()
        originalEnter(frame)
        barManager.IEF_tempAlpha = barManager:GetAlpha()
        barManager:SetAlpha(1)
      end)

      frame:SetScript("OnLeave", function()
        originalLeave(frame)
        if barManager.IEF_tempAlpha ~= nil then
          barManager:SetAlpha(barManager.IEF_tempAlpha)
        end
      end)
    end
  end
end



if Bartender4 then
  hooksecurefunc(Bartender4:GetModule("StatusTrackingBar"), "OnEnable", function(self)
    SetStatusBarFading(BT4StatusBarTrackingManager)
  end)
else
  hooksecurefunc(StatusTrackingBarManager, "AddBarFromTemplate", SetStatusBarFading)
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
  -- Otherwise we cannot take the correct values of partyMemberFrameShown or partyMemberFrameNotPresentIconShown.
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
    if BT4StatusBarTrackingManager then
      BT4StatusBarTrackingManager:SetIgnoreParentAlpha(true)
      BT4StatusBarTrackingManager.IEF_tempAlpha = IEF_Config.trackingBarAlpha
      ConditionalFadeOutTo(BT4StatusBarTrackingManager, BT4StatusBarTrackingManager.IEF_tempAlpha)
    else
      StatusTrackingBarManager:SetIgnoreParentAlpha(true)
      StatusTrackingBarManager.IEF_tempAlpha = IEF_Config.trackingBarAlpha
      ConditionalFadeOutTo(StatusTrackingBarManager, StatusTrackingBarManager.IEF_tempAlpha)
    end
  end


  -- Got to manually fade out (and aftewards hide) the PartyMemberFrame..NotPresentIcon.
  for i = 1, 4, 1 do
    if _G["PartyMemberFrame" .. i] and _G["PartyMemberFrame" .. i]:IsShown() then
      partyMemberFrameShown[i] = true
      local partyMemberFrameNotPresent = _G["PartyMemberFrame" .. i .. "NotPresentIcon"]
      if partyMemberFrameNotPresent and partyMemberFrameNotPresent:IsShown() then
        partyMemberFrameNotPresentIconShown[i] = true
        UIFrameFadeOut(partyMemberFrameNotPresent, fadeOutTime, partyMemberFrameNotPresent:GetAlpha(), 0)
      else
        partyMemberFrameNotPresentIconShown[i] = false
      end
    else
      partyMemberFrameShown[i] = false
      partyMemberFrameNotPresentIconShown[i] = false
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


    for i = 1, 4, 1 do
      if partyMemberFrameShown[i] then
        _G["PartyMemberFrame" .. i]:Hide()
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

      if IEF_Config.hideTrackingBar then
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

      if IEF_Config.hideTrackingBar then
        ConditionalHide(StatusTrackingBarManager)
      end

    end

  end, fadeOutTime)

end)   -- End of gossipShowFrame.



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


  for i = 1, 4, 1 do
    if partyMemberFrameShown[i] then
      _G["PartyMemberFrame" .. i]:Show()
    end

    if partyMemberFrameNotPresentIconShown[i] then
      UIFrameFadeIn(_G["PartyMemberFrame" .. i .. "NotPresentIcon"], fadeInTime, _G["PartyMemberFrame" .. i .. "NotPresentIcon"]:GetAlpha(), 1)
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
    ConditionalFadeIn(BT4StatusBarTrackingManager)
    -- Store IEF_tempAlpha for OnEnter/OnLeave.
    BT4StatusBarTrackingManager.IEF_tempAlpha = 1

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
    ConditionalFadeIn(StatusTrackingBarManager)
    -- Store IEF_tempAlpha for OnEnter/OnLeave.
    StatusTrackingBarManager.IEF_tempAlpha = 1

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

      if BT4StatusBarTrackingManager then
        BT4StatusBarTrackingManager:SetIgnoreParentAlpha(false)
      else
        StatusTrackingBarManager:SetIgnoreParentAlpha(false)
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
  if gossipShown > 0 and UIParent:GetAlpha() == 1 and gossipShown < GetTime() then
    GossipCloseFunction(false)
  end
end)


function L:OnInitialize()
  self:InitializeSavedVariables()
  self:InitializeOptions()
end

