-- Fake all required API calls for non-pfUI users.
-- This is skipped if a pfUI API is found, like if pfUI is running or
-- pfQuest already provides that API.
if not (pfUI and pfUI.api) then
  -- set the default table and fill with non-pfUI config values
  -- using blizzard game font and backdrops.
  pfUI = {
    ["api"] = {},
    ["cache"] = {},
    ["backdrop"] = {
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 16,
      insets = { left = 3, right = 3, top = 3, bottom = 3 }
    },
    ["backdrop_small"] = {
      bgFile = "Interface\\BUTTONS\\WHITE8X8", tile = false, tileSize = 0,
      edgeFile = "Interface\\BUTTONS\\WHITE8X8", edgeSize = 1,
      insets = {left = 0, right = 0, top = 0, bottom = 0},
    },
    ["font_default"] = STANDARD_TEXT_FONT,
   }

  pfUI_config = {
    ["appearance"] = {
      ["border"] = {
        ["default"] = "3",
      }
    },
    ["global"] = {
      ["font_size"] = 12
    },
    -- fix for old questie releases
    ["disabled"] = {
      ["minimap"] = "1"
    }
  }

  -- [ round ]
  -- Rounds a float number into specified places after comma.
  -- 'input'      [float]         the number that should be rounded.
  -- 'places'     [int]           amount of places after the comma.
  -- returns:     [float]         rounded number.
  function pfUI.api.round(input, places)
    if not places then places = 0 end
    if type(input) == "number" and type(places) == "number" then
      local pow = 1
      for i = 1, places do pow = pow * 10 end
      return floor(input * pow + 0.5) / pow
    end
  end

  -- [ Create Backdrop ]
  -- Creates a pfUI compatible frame as backdrop element
  -- 'f'          [frame]         the frame which should get a backdrop.
  -- 'inset'      [int]           backdrop inset, defaults to border size.
  -- 'legacy'     [bool]          use legacy backdrop instead of creating frames.
  -- 'transp'     [number]        set default transparency
  local er, eg, eb, ea = .4,.4,.4,1
  local br, bg, bb, ba = 0,0,0,1
  function pfUI.api.CreateBackdrop(f, inset, legacy, transp)
    -- exit if now frame was given
    if not f then return end

    -- use default inset if nothing is given
    local border = inset
    if not border then
      border = tonumber(pfUI_config.appearance.border.default)
    end

    if transp then ba = transp end

    -- use legacy backdrop handling
    if legacy then
      f:SetBackdrop(pfUI.backdrop)
      f:SetBackdropColor(br, bg, bb, ba)
      f:SetBackdropBorderColor(er, eg, eb , ea)
      return
    end

    -- increase clickable area if available
    if f.SetHitRectInsets then
      f:SetHitRectInsets(-border,-border,-border,-border)
    end

    -- use new backdrop behaviour
    if not f.backdrop then
      f:SetBackdrop(nil)

      local border = tonumber(border) - 1
      local backdrop = pfUI.backdrop
      if border < 1 then backdrop = pfUI.backdrop_small end
      local b = CreateFrame("Frame", nil, f)
      b:SetPoint("TOPLEFT", f, "TOPLEFT", -border, border)
      b:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", border, -border)

      local level = f:GetFrameLevel()
      if level < 1 then
        --f:SetFrameLevel(level + 1)
        b:SetFrameLevel(level)
      else
        b:SetFrameLevel(level - 1)
      end

      f.backdrop = b
      b:SetBackdrop(backdrop)
    end

    local b = f.backdrop
    b:SetBackdropColor(br, bg, bb, ba)
    b:SetBackdropBorderColor(er, eg, eb , ea)
  end
end

-- Mock pfUI other pfUI functions if required
pfUI.api.SaveMovable = pfUI.api.SaveMovable or function(frame) frame:SetUserPlaced(1) end
pfUI.api.UpdateMovable = pfUI.api.UpdateMovable or function(frame) end
pfUI.RegisterModule = pfUI.RegisterModule or function(a,b,func) func() end
