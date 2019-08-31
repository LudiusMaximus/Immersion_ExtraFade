local folderName = ...
local L = LibStub("AceAddon-3.0"):NewAddon(folderName, "AceTimer-3.0")


-- Must fit the values of Immersion.
local fadeOutTime = 0.2
local fadeInTime = 0.5


local StatusBarMod = Bartender4:GetModule("StatusTrackingBar")
StatusBarMod:Enable()

for _, frame in pairs(StatusBarMod.bar.manager.bars) do

  local originalEnter = frame:GetScript("OnEnter")
  local originalLeave = frame:GetScript("OnLeave")

  frame:SetScript("OnEnter", function()
    originalEnter(frame)
    StatusBarMod.bar.manager.tempAlpha = StatusBarMod.bar.manager:GetAlpha()
    StatusBarMod.bar.manager:SetAlpha(1)
  end )

  frame:SetScript("OnLeave", function()
    originalLeave(frame)
    if (StatusBarMod.bar.manager.tempAlpha ~= nil) then
      StatusBarMod.bar.manager:SetAlpha(StatusBarMod.bar.manager.tempAlpha)
    end
  end )

end


local bagnonInventoryOpen = false


local gossipShowFrame = CreateFrame("Frame")
gossipShowFrame:RegisterEvent("GOSSIP_SHOW")
gossipShowFrame:RegisterEvent("QUEST_DETAIL")
gossipShowFrame:RegisterEvent("QUEST_COMPLETE")
gossipShowFrame:RegisterEvent("QUEST_GREETING")
gossipShowFrame:SetScript("OnEvent", function(self, event, ...)

  ChatFrame1:SetIgnoreParentAlpha(true)
  ChatFrame1Tab:SetIgnoreParentAlpha(true)
  ChatFrame1EditBox:SetIgnoreParentAlpha(true)


  StatusBarMod.bar.manager:SetIgnoreParentAlpha(true)

  -- Store tempAlpha for OnEnter/OnLeave.
  StatusBarMod.bar.manager.tempAlpha = 0.25
  UIFrameFadeOut(StatusBarMod.bar.manager, fadeOutTime, StatusBarMod.bar.manager:GetAlpha(), StatusBarMod.bar.manager.tempAlpha)


  if L.frameHideTimer then LibStub("AceTimer-3.0"):CancelTimer(L.frameHideTimer) end
  if L.frameShowTimer then LibStub("AceTimer-3.0"):CancelTimer(L.frameShowTimer) end

  -- Hide frames of which we want no mouseover tooltips while faded.
  L.frameHideTimer = LibStub("AceTimer-3.0"):ScheduleTimer(function()

    if QuickJoinToastButton then QuickJoinToastButton:Hide() end
    if PlayerFrame then PlayerFrame:Hide() end
    if PetFrame then PetFrame:Hide() end
    if TargetFrame then TargetFrame:Hide() end
    if BuffFrame then BuffFrame:Hide() end
    if DebuffFrame then DebuffFrame:Hide() end


    if BT4Bar1 then BT4Bar1:Hide() end
    if BT4Bar2 then BT4Bar2:Hide() end
    if BT4Bar3 then BT4Bar3:Hide() end
    if BT4Bar4 then BT4Bar4:Hide() end
    if BT4Bar5 then BT4Bar5:Hide() end
    if BT4Bar6 then BT4Bar6:Hide() end
    if BT4Bar7 then BT4Bar7:Hide() end
    if BT4Bar8 then BT4Bar8:Hide() end
    if BT4Bar9 then BT4Bar9:Hide() end
    if BT4Bar10 then BT4Bar10:Hide() end
    if BT4BarBagBar then BT4BarBagBar:Hide() end
    if BT4BarMicroMenu then BT4BarMicroMenu:Hide() end

    if BT4BarStanceBar then BT4BarStanceBar:Hide() end
    if BT4BarPetBar then BT4BarPetBar:Hide() end


    -- Bagnon inventory vanishes automatically with the UI fade.
    -- We hide it explicitly anyway and remember if we should
    -- open it again after the NPC interaction.
    if BagnonFrameinventory and BagnonFrameinventory:IsShown() then
      bagnonInventoryOpen = true
      BagnonFrameinventory:Hide()
    else
      bagnonInventoryOpen = false
    end

  end, fadeOutTime)

end)


local gossipClosedFrame = CreateFrame("Frame")
gossipClosedFrame:RegisterEvent("GOSSIP_CLOSED")
gossipClosedFrame:RegisterEvent("QUEST_FINISHED")
gossipClosedFrame:SetScript("OnEvent", function(self, event, ...)

  -- Cancel hide timer if frames have not been hidden yet.
  if L.frameHideTimer then LibStub("AceTimer-3.0"):CancelTimer(L.frameHideTimer) end
  if L.frameShowTimer then LibStub("AceTimer-3.0"):CancelTimer(L.frameShowTimer) end

  L.frameShowTimer = LibStub("AceTimer-3.0"):ScheduleTimer(function()
    ChatFrame1:SetIgnoreParentAlpha(false)
    ChatFrame1Tab:SetIgnoreParentAlpha(false)
    ChatFrame1EditBox:SetIgnoreParentAlpha(false)

    StatusBarMod.bar.manager:SetIgnoreParentAlpha(false)
  end, fadeInTime)


  -- If the Bagnon inventory was open before, we open it again.
  -- Have to do this with this timer, otherwise it won't work...
  if BagnonFrameinventory and bagnonInventoryOpen then
    LibStub("AceTimer-3.0"):ScheduleTimer(function()
      BagnonFrameinventory:Show()
    end, 0)
  end


  if QuickJoinToastButton then QuickJoinToastButton:Show() end
  if PlayerFrame then PlayerFrame:Show() end
  if PetFrame then PetFrame:Show() end
  if TargetFrame then TargetFrame:Show() end
  if BuffFrame then BuffFrame:Show() end
  if DebuffFrame then DebuffFrame:Show() end


  if BT4Bar1 and BT4Bar1:GetAttribute("state-vis") ~= "hide" then BT4Bar1:Show() end
  if BT4Bar2 and BT4Bar2:GetAttribute("state-vis") ~= "hide" then BT4Bar2:Show() end
  if BT4Bar3 and BT4Bar3:GetAttribute("state-vis") ~= "hide" then BT4Bar3:Show() end
  if BT4Bar4 and BT4Bar4:GetAttribute("state-vis") ~= "hide" then BT4Bar4:Show() end
  if BT4Bar5 and BT4Bar5:GetAttribute("state-vis") ~= "hide" then BT4Bar5:Show() end
  if BT4Bar6 and BT4Bar6:GetAttribute("state-vis") ~= "hide" then BT4Bar6:Show() end
  if BT4Bar7 and BT4Bar7:GetAttribute("state-vis") ~= "hide" then BT4Bar7:Show() end
  if BT4Bar8 and BT4Bar8:GetAttribute("state-vis") ~= "hide" then BT4Bar8:Show() end
  if BT4Bar9 and BT4Bar9:GetAttribute("state-vis") ~= "hide" then BT4Bar9:Show() end
  if BT4Bar10 and BT4Bar10:GetAttribute("state-vis") ~= "hide" then BT4Bar10:Show() end
  if BT4BarBagBar and BT4BarBagBar:GetAttribute("state-vis") ~= "hide" then BT4BarBagBar:Show() end
  if BT4BarMicroMenu and BT4BarMicroMenu:GetAttribute("state-vis") ~= "hide" then BT4BarMicroMenu:Show() end

  if BT4BarStanceBar and BT4BarStanceBar:GetAttribute("state-vis") ~= "hide" then BT4BarStanceBar:Show() end
  if BT4BarPetBar and BT4BarPetBar:GetAttribute("state-vis") ~= "hide" then BT4BarPetBar:Show() end

  -- Fade in the only half faded status bar.
  -- Store tempAlpha for OnEnter/OnLeave.
  StatusBarMod.bar.manager.tempAlpha = 1
  UIFrameFadeIn(StatusBarMod.bar.manager, fadeInTime, StatusBarMod.bar.manager:GetAlpha(), StatusBarMod.bar.manager.tempAlpha)

end)
