local folderName, Addon = ...
local L = LibStub("AceAddon-3.0"):NewAddon(folderName, "AceTimer-3.0")


-- Must fit the hardcoded values of Immersion.
local fadeOutTime = 0.2
local fadeInTime = 0.5


function L:OnInitialize()
  self:InitializeSavedVariables()
  self:InitializeOptions()
end

local gossipShowFrame = CreateFrame("Frame")
gossipShowFrame:RegisterEvent("GOSSIP_SHOW")
gossipShowFrame:RegisterEvent("QUEST_COMPLETE")
gossipShowFrame:RegisterEvent("QUEST_DETAIL")
gossipShowFrame:RegisterEvent("QUEST_GREETING")
gossipShowFrame:RegisterEvent("QUEST_PROGRESS")
gossipShowFrame:SetScript("OnEvent", function(_, event)
  -- print("gossipShowFrame", event)
  Addon.HideUI(IEF_Config, fadeOutTime)
end)

local gossipCloseFrame = CreateFrame("Frame")
gossipCloseFrame:RegisterEvent("GOSSIP_CLOSED")
gossipCloseFrame:RegisterEvent("QUEST_FINISHED")
gossipCloseFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
gossipCloseFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entering combat.
gossipCloseFrame:SetScript("OnEvent", function(_, event)
  -- print("gossipCloseFrame", event)
  if event == "PLAYER_REGEN_DISABLED" then
    Addon.ShowUI(IEF_Config, fadeInTime, true)
  else
    Addon.ShowUI(IEF_Config, fadeInTime, false)
  end
end)




-- Local flags.
local cinematicRunning = false
local framerateWasShown = false

-- If we somehow missed to show the frames again, we do it here!
local emergencyFrame = CreateFrame("Frame")
emergencyFrame:SetScript("onUpdate", function()
  if UIParent:GetAlpha() == 1 and Addon.uiHiddenTime > 0 and Addon.uiHiddenTime < GetTime() and not cinematicRunning then
    -- print("Emergency show")
    Addon.ShowUI(IEF_Config, 0, false)
  end
end)

local toggleFramerateFrame = CreateFrame("Frame")
toggleFramerateFrame:RegisterEvent("CINEMATIC_START")
toggleFramerateFrame:RegisterEvent("CINEMATIC_STOP")
toggleFramerateFrame:SetScript("OnEvent", function(_, event)
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
