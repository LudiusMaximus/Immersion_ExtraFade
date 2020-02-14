local folderName = ...
local L = LibStub("AceAddon-3.0"):GetAddon(folderName)



local defaults = {
  
  hideFrameRate    = true,
  hideChatFrame    = false,
  hideTrackingBar  = false,
  trackingBarAlpha = 0.33,
  
}


local optionsTable = {
  type = 'group',
  args = {
    
    info = {
      order = 0,
      type = "description",
      name = "Make adjustemts here to chose how additional frames should or should not be hidden during NPC-interaction. \nThis only has an effect when you activate \"Hide Interface\" in Immersion's settings.\n\n",
    },
  
  
    hideFrameRate = {
      order = 10,
      type = 'toggle',
      name = "Hide Frame Rate",
      desc = "Check this to hide the frame rate during Immersion's \"Hide Interface\"!",
      width = "normal",
      get = function() return IEF_Config.hideFrameRate end,
      set = function(_, newValue) IEF_Config.hideFrameRate = newValue end,
    },
    
    nl1 = {order = 20, type = "description", name = " ",},
    
    hideChatFrame = {
      order = 30,
      type = 'toggle',
      name = "Hide Chat Frame",
      desc = "Uncheck this to keep the chat frame during Immersion's \"Hide Interface\"! This allows you to better track your rewards while handing in quests.",
      width = "normal",
      get = function() return IEF_Config.hideChatFrame end,
      set = function(_, newValue) IEF_Config.hideChatFrame = newValue end,
    },
    
    nl2 = {order = 40, type = "description", name = " ",},
    
    hideTrackingBar = {
      order = 50,
      type = 'toggle',
      name = "Hide Tracking Bars",
      desc = "Uncheck this to keep the tracking bars (XP, AP, Reputation) during Immersion's \"Hide Interface\"! This allows you to better track your rewards while handing in quests.",
      width = "normal",
      get = function() return IEF_Config.hideTrackingBar end,
      set = function(_, newValue) IEF_Config.hideTrackingBar = newValue end,
    },
    
    nl3 = {order = 60, type = "description", name = "",},
    
    trackingBarAlpha = {
      order = 70,
      type = 'range',
      name = "Tracking bar opacity during NPC intaraction",
      desc = "Only partially fade out the tracking bars. Hovering over them brings them to full opacity.",
      disabled = function() return IEF_Config.hideTrackingBar end,
      min = .01,
      max = 1,
      step = .01,
      width = "double",
      get = function() return IEF_Config.trackingBarAlpha end,
      set = function(_, newValue) IEF_Config.trackingBarAlpha = newValue end,
    },
    
    nl4 = {order = 80, type = "description", name = " ",},
    
    restoreDefaults = {
      order = 90,
      type = 'execute',
      name = "Restore defaults",
      desc = "Restore settings to the preference of the developer.",
      width = "normal",
      func = function()
              for k, v in pairs(defaults) do
                IEF_Config[k] = v
              end
            end,
    },
    
  },
}



function L:InitializeSavedVariables()

  if IEF_Config == nil then
    IEF_Config = {}
  end

  -- Remove keys from previous versions.
  for k, v in pairs(IEF_Config) do
    -- print (k, v)
    if defaults[k] == nil then
      -- print(k, "not in defaults")
      IEF_Config[k] = nil
    end
  end
  
  -- Set defaults for new key.
  for k, v in pairs(defaults) do
    -- print (k, v)
    if IEF_Config[k] == nil then
      -- print(k, "not there")
      IEF_Config[k] = v
    end
  end

end


function L:InitializeOptions()

  LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("Immersion ExtraFade", optionsTable)
  self.optionsMenu = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Immersion ExtraFade", "Immersion ExtraFade")

end
