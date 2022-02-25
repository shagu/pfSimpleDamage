pfUI:RegisterModule("damagemeter", function ()
  local track_all_units = false
  local width = 200
  local height = 18

  local dmg_table = {}
  local view_dmg_all = {}
  local view_dmg_all_max = 0

  local CreateBackdrop = pfUI.api.CreateBackdrop
  local round = pfUI.api.round
  local UpdateMovable = pfUI.api.UpdateMovable

  local playerClasses = {}

  local validUnits = {}
  validUnits["player"] = true
  validUnits["pet"] = true

  for i=1,4 do validUnits["party" .. i] = true end
  for i=1,4 do validUnits["partypet" .. i] = true end
  for i=1,40 do validUnits["raid" .. i] = true end
  for i=1,40 do validUnits["raidpet" .. i] = true end

  -- TODO: api
  function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[table.getn(keys)+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
      table.sort(keys, function(a,b) return order(t, a, b) end)
    else
      table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
      i = i + 1
      if keys[i] then
        return keys[i], t[keys[i]]
      end
    end
  end

  local function prepare(template)
    template = gsub(template, "%(", "%%(") -- fix ( in string
    template = gsub(template, "%)", "%%)") -- fix ) in string
    template = gsub(template, "%d%$","")
    template = gsub(template, "%%s", "(.+)")
    return gsub(template, "%%d", "(%%d+)")
  end

  -- me source me target
  local pfSPELLLOGSCHOOLSELFSELF = prepare(SPELLLOGSCHOOLSELFSELF) -- Your %s hits you for %d %s damage.
  local pfSPELLLOGCRITSCHOOLSELFSELF = prepare(SPELLLOGCRITSCHOOLSELFSELF) -- Your %s crits you for %d %s damage.
  local pfSPELLLOGSELFSELF = prepare(SPELLLOGSELFSELF) --Your %s hits you for %d.
  local pfSPELLLOGCRITSELFSELF = prepare(SPELLLOGCRITSELFSELF) -- Your %s crits you for %d.
  local pfPERIODICAURADAMAGESELFSELF =  prepare(PERIODICAURADAMAGESELFSELF) -- "You suffer %d %s damage from your %s.";

  -- me source
  local pfSPELLLOGSCHOOLSELFOTHER = prepare(SPELLLOGSCHOOLSELFOTHER) -- Your %s hits %s for %d %s damage.
  local pfSPELLLOGCRITSCHOOLSELFOTHER = prepare(SPELLLOGCRITSCHOOLSELFOTHER) -- Your %s crits %s for %d %s damage.
  local pfSPELLLOGSELFOTHER = prepare(SPELLLOGSELFOTHER) -- Your %s hits %s for %d.
  local pfSPELLLOGCRITSELFOTHER = prepare(SPELLLOGCRITSELFOTHER) -- Your %s crits %s for %d.
  local pfPERIODICAURADAMAGESELFOTHER = prepare(PERIODICAURADAMAGESELFOTHER) -- "%s suffers %d %s damage from your %s."; -- Rabbit suffers 3 frost damage from your Ice Nova.
  local pfCOMBATHITSELFOTHER = prepare(COMBATHITSELFOTHER) -- You hit %s for %d.
  local pfCOMBATHITCRITSELFOTHER = prepare(COMBATHITCRITSELFOTHER) -- You crit %s for %d.
  local pfCOMBATHITSCHOOLSELFOTHER = prepare(COMBATHITSCHOOLSELFOTHER) -- You hit %s for %d %s damage.
  local pfCOMBATHITCRITSCHOOLSELFOTHER = prepare(COMBATHITCRITSCHOOLSELFOTHER) -- You crit %s for %d %s damage.

  -- me target
  local pfSPELLLOGSCHOOLOTHERSELF = prepare(SPELLLOGSCHOOLOTHERSELF) -- %s's %s hits you for %d %s damage.
  local pfSPELLLOGCRITSCHOOLOTHERSELF = prepare(SPELLLOGCRITSCHOOLOTHERSELF) -- %s's %s crits you for %d %s damage.
  local pfSPELLLOGOTHERSELF = prepare(SPELLLOGOTHERSELF) -- %s's %s hits you for %d.
  local pfSPELLLOGCRITOTHERSELF = prepare(SPELLLOGCRITOTHERSELF) -- %s's %s crits you for %d.
  local pfPERIODICAURADAMAGEOTHERSELF = prepare(PERIODICAURADAMAGEOTHERSELF) -- "You suffer %d %s damage from %s's %s."; -- You suffer 3 frost damage from Rabbit's Ice Nova.
  local pfCOMBATHITOTHERSELF = prepare(COMBATHITOTHERSELF) -- %s hits you for %d.
  local pfCOMBATHITCRITOTHERSELF = prepare(COMBATHITCRITOTHERSELF) -- %s crits you for %d.
  local pfCOMBATHITSCHOOLOTHERSELF = prepare(COMBATHITSCHOOLOTHERSELF) -- %s hits you for %d %s damage.
  local pfCOMBATHITCRITSCHOOLOTHERSELF = prepare(COMBATHITCRITSCHOOLOTHERSELF) -- %s crits you for %d %s damage.

  -- other
  local pfSPELLLOGSCHOOLOTHEROTHER = prepare(SPELLLOGSCHOOLOTHEROTHER) -- %s's %s hits %s for %d %s damage.
  local pfSPELLLOGCRITSCHOOLOTHEROTHER = prepare(SPELLLOGCRITSCHOOLOTHEROTHER) -- %s's %s crits %s for %d %s damage.
  local pfSPELLLOGOTHEROTHER = prepare(SPELLLOGOTHEROTHER) -- %s's %s hits %s for %d.
  local pfSPELLLOGCRITOTHEROTHER = prepare(SPELLLOGCRITOTHEROTHER) -- %s's %s crits %s for %d.
  local pfPERIODICAURADAMAGEOTHEROTHER = prepare(PERIODICAURADAMAGEOTHEROTHER) -- "%s suffers %d %s damage from %s's %s."; -- Bob suffers 5 frost damage from Jeff's Ice Nova.
  local pfCOMBATHITOTHEROTHER = prepare(COMBATHITOTHEROTHER) -- %s hits %s for %d.
  local pfCOMBATHITCRITOTHEROTHER = prepare(COMBATHITCRITOTHEROTHER) -- %s crits %s for %d.
  local pfCOMBATHITSCHOOLOTHEROTHER = prepare(COMBATHITSCHOOLOTHEROTHER) -- %s hits %s for %d %s damage.
  local pfCOMBATHITCRITSCHOOLOTHEROTHER = prepare(COMBATHITCRITSCHOOLOTHEROTHER) -- %s crits %s for %d %s damage.

  pfUI.damagemeter = CreateFrame("Frame", "pfDamageMeter", UIParent)
  pfUI.damagemeter:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  pfUI.damagemeter:SetWidth(width)
  pfUI.damagemeter:SetHeight(0)
  pfUI.damagemeter:SetMovable(true)

  CreateBackdrop(pfUI.damagemeter)
  UpdateMovable(pfUI.damagemeter)

  pfUI.damagemeter.bar = {}
  for i=0,50 do
    pfUI.damagemeter.bar[i] = CreateFrame("StatusBar", "pfDamageMeterBar" .. i, pfUI.damagemeter)
    pfUI.damagemeter.bar[i]:SetStatusBarTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    pfUI.damagemeter.bar[i]:SetWidth(width)
    pfUI.damagemeter.bar[i]:SetHeight(height)
    pfUI.damagemeter.bar[i]:Hide()
    pfUI.damagemeter.bar[i]:SetPoint("TOP", pfUI.damagemeter, "TOP", 0, -pfUI.damagemeter.bar[i]:GetHeight()*i)

    pfUI.damagemeter.bar[i].textLeft = pfUI.damagemeter.bar[i]:CreateFontString("Status", "OVERLAY", "GameFontNormal")
    pfUI.damagemeter.bar[i].textLeft:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    pfUI.damagemeter.bar[i].textLeft:SetJustifyH("LEFT")
    pfUI.damagemeter.bar[i].textLeft:SetFontObject(GameFontWhite)
    pfUI.damagemeter.bar[i].textLeft:SetParent(pfUI.damagemeter.bar[i])
    pfUI.damagemeter.bar[i].textLeft:ClearAllPoints()
    pfUI.damagemeter.bar[i].textLeft:SetPoint("TOPLEFT", pfUI.damagemeter.bar[i], "TOPLEFT", 5, 1)
    pfUI.damagemeter.bar[i].textLeft:SetPoint("BOTTOMRIGHT", pfUI.damagemeter.bar[i], "BOTTOMRIGHT", -5, 0)

    pfUI.damagemeter.bar[i].textRight = pfUI.damagemeter.bar[i]:CreateFontString("Status", "OVERLAY", "GameFontNormal")
    pfUI.damagemeter.bar[i].textRight:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    pfUI.damagemeter.bar[i].textRight:SetJustifyH("RIGHT")
    pfUI.damagemeter.bar[i].textRight:SetFontObject(GameFontWhite)
    pfUI.damagemeter.bar[i].textRight:SetParent(pfUI.damagemeter.bar[i])
    pfUI.damagemeter.bar[i].textRight:ClearAllPoints()
    pfUI.damagemeter.bar[i].textRight:SetPoint("TOPLEFT", pfUI.damagemeter.bar[i], "TOPLEFT", 5, 1)
    pfUI.damagemeter.bar[i].textRight:SetPoint("BOTTOMRIGHT", pfUI.damagemeter.bar[i], "BOTTOMRIGHT", -5, 0)
    pfUI.damagemeter.bar[i]:EnableMouse(true)

    pfUI.damagemeter.bar[i]:SetScript("OnMouseDown",function()
      if arg1 == "LeftButton" then
        this:GetParent():StartMoving()
      elseif arg1 == "RightButton" then
        pfUI.damagemeter:ResetBars(this.textLeft:GetText())
      elseif arg1 == "MiddleButton" then
        pfUI.damagemeter:ResetBars()
      end
    end)

    pfUI.damagemeter.bar[i]:SetScript("OnMouseUp",function()
      if arg1 == "LeftButton" then
        this:GetParent():StopMovingOrSizing()
        SaveMovable(this:GetParent())
      end
    end)

    pfUI.damagemeter.bar[i]:SetScript("OnEnter", function()
      GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
      GameTooltip:AddDoubleLine("|cff33ffccDamage", "|cffffffff" .. dmg_table[this.unit]["_sum"] .. " - 100%")
      for attack, damage in spairs(dmg_table[this.unit], function(t,a,b) return t[b] < t[a] end) do
        if attack ~= "_sum" then
          GameTooltip:AddDoubleLine("|cffffffff" .. attack, "|cffcccccc" .. damage .. " - |cffffffff" .. round(damage / dmg_table[this.unit]["_sum"] * 100,1) .. "%")
        end
      end
      GameTooltip:Show()
    end)

    pfUI.damagemeter.bar[i]:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
  end

  function pfUI.damagemeter:ScanName(name)
    for unit, _ in pairs(validUnits) do
      if UnitExists(unit) and UnitName(unit) == name then
        if UnitIsPlayer(unit) then
          local _, class = UnitClass(unit)
          playerClasses[name] = class
          return true
        else
          playerClasses[name] = unit
          return true
        end
      end
    end

    if track_all_units then
      playerClasses[name] = "other"
      return true
    else
      return false
    end
  end

  function pfUI.damagemeter:ResetBars(name)
    if name then
      if dmg_table[name] and view_dmg_all[name] then
        dmg_table[name] = nil
        view_dmg_all[name] = nil
        view_dmg_all_max = 0
        pfUI.damagemeter:RefreshBars()
      else
        message("No entries found for: " .. name)
      end
    else
      dmg_table = {}
      view_dmg_all = {}
      view_dmg_all_max = 0
      pfUI.damagemeter:RefreshBars()
    end
  end

  function pfUI.damagemeter:RefreshBars()
    local count = 0
    local sum_dmg = 0
    for _, damage in pairs(view_dmg_all) do
      count = count + 1
      sum_dmg = sum_dmg + damage

      if damage > view_dmg_all_max then
        view_dmg_all_max = damage
      end
    end

    local i=0
    for name, damage in spairs(view_dmg_all, function(t,a,b) return t[b] < t[a] end) do
      pfUI.damagemeter.bar[i]:SetMinMaxValues(0, view_dmg_all_max)
      pfUI.damagemeter.bar[i]:SetValue(damage)
      pfUI.damagemeter.bar[i]:Show()
      pfUI.damagemeter.bar[i].unit = name

      local color = { r= .6, g = .6, b = .6 }
      if playerClasses[name] ~= "other" then
        color = { r= .6, g = 1, b = .6 }
      end
      if RAID_CLASS_COLORS[playerClasses[name]] then
        color = RAID_CLASS_COLORS[playerClasses[name]]
      elseif playerClasses[name] then
        -- parse pet owners
        if strsub(playerClasses[name],0,3) == "pet" then
          name = UnitName("player") .. " - " .. name
        elseif strsub(playerClasses[name],0,8) == "partypet" then
          name = UnitName("party" .. strsub(playerClasses[name],9)) .. " - " .. name
        elseif strsub(playerClasses[name],0,7) == "raidpet" then
          name = UnitName("raid" .. strsub(playerClasses[name],8)) .. " - " .. name
        end
      end

      pfUI.damagemeter.bar[i]:SetStatusBarColor(color.r, color.g, color.b)

      pfUI.damagemeter.bar[i].textLeft:SetText(name)
      pfUI.damagemeter.bar[i].textRight:SetText(damage .. " - " .. round(damage / sum_dmg * 100,1) .. "%")
      i = i + 1
    end

    local sizing = i * height
    if sizing > 0 then
      pfUI.damagemeter:SetHeight(sizing)
      pfUI.damagemeter:Show()
    else
      pfUI.damagemeter:SetHeight(height)
      pfUI.damagemeter:Hide()
    end

    -- hide remaining bars
    for j=i,50 do
      pfUI.damagemeter.bar[j]:Hide()
    end
  end

  function pfUI.damagemeter:AddData(source, attack, target, damage, school)
    -- message(source .. " (" .. attack .. ") -> " .. target .. ": " .. damage .. " (" .. school .. ")")

    -- write dmg_table table
    if not dmg_table[source] and pfUI.damagemeter:ScanName(source) then
      dmg_table[source] = {}
    end

    if dmg_table[source] then
      dmg_table[source][attack] = (dmg_table[source][attack] or 0) + tonumber(damage)
      dmg_table[source]["_sum"] = (dmg_table[source]["_sum"] or 0) + tonumber(damage)
    else
      return
    end

    if dmg_table[source] then
      view_dmg_all[source] = (view_dmg_all[source] or 0) + tonumber(damage)
    end

    pfUI.damagemeter:RefreshBars()
  end

  pfUI.damagemeter:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
  pfUI.damagemeter:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
  pfUI.damagemeter:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
  pfUI.damagemeter:RegisterEvent("CHAT_MSG_SPELL_PARTY_DAMAGE")
  pfUI.damagemeter:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE")
  pfUI.damagemeter:RegisterEvent("CHAT_MSG_COMBAT_PARTY_HITS")
  pfUI.damagemeter:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE")
  pfUI.damagemeter:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE")
  pfUI.damagemeter:RegisterEvent("CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS")
  pfUI.damagemeter:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE")
  pfUI.damagemeter:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE")
  pfUI.damagemeter:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS")
  pfUI.damagemeter:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE")
  pfUI.damagemeter:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_HITS")
  pfUI.damagemeter:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE")
  pfUI.damagemeter:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE")
  pfUI.damagemeter:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE")
  pfUI.damagemeter:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS")
  pfUI.damagemeter:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS")
  pfUI.damagemeter:RegisterEvent("CHAT_MSG_SPELL_PET_DAMAGE")
  pfUI.damagemeter:RegisterEvent("CHAT_MSG_COMBAT_PET_HITS")

  pfUI.damagemeter:SetScript("OnEvent", function()
    local source = UnitName("player")
    local target = UnitName("player")
    local school = "physical"
    local attack = "Auto Hit"

    if arg1 then
      -- me source me target
       -- Your %s hits you for %d %s damage.
      for attack, damage, school in string.gfind(arg1, pfSPELLLOGSCHOOLSELFSELF) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

       -- Your %s crits you for %d %s damage.
      for attack, damage, school in string.gfind(arg1, pfSPELLLOGCRITSCHOOLSELFSELF) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

       -- Your %s hits you for %d.
      for attack, damage in string.gfind(arg1, pfSPELLLOGSELFSELF) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

       -- Your %s crits you for %d.
      for attack, damage in string.gfind(arg1, pfSPELLLOGCRITSELFSELF) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

      -- "You suffer %d %s damage from your %s.";
      for damage, school, attack in string.gfind(arg1, pfPERIODICAURADAMAGESELFSELF) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

      -- me source
       -- Your %s hits %s for %d %s damage.
      for attack, target, damage, school in string.gfind(arg1, pfSPELLLOGSCHOOLSELFOTHER) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

       -- Your %s crits %s for %d %s damage.
      for attack, target, damage, school in string.gfind(arg1, pfSPELLLOGCRITSCHOOLSELFOTHER) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

       -- Your %s hits %s for %d.
      for attack, target, damage in string.gfind(arg1, pfSPELLLOGSELFOTHER) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

       -- Your %s crits %s for %d.
      for attack, target, damage in string.gfind(arg1, pfSPELLLOGCRITSELFOTHER) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

      -- %s suffers %d %s damage from your %s."; -- Rabbit suffers 3 frost damage from your Ice Nova.
      for target, damage, school, attack in string.gfind(arg1, pfPERIODICAURADAMAGESELFOTHER) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

      -- You hit %s for %d.
      for target, damage in string.gfind(arg1, pfCOMBATHITSELFOTHER) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

      -- You crit %s for %d.
      for target, damage in string.gfind(arg1, pfCOMBATHITCRITSELFOTHER) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

      -- You hit %s for %d %s damage.
      for target, damage, school in string.gfind(arg1, pfCOMBATHITSCHOOLSELFOTHER) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

      -- You crit %s for %d %s damage.
      for target, damage, school in string.gfind(arg1, pfCOMBATHITCRITSCHOOLSELFOTHER) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

      -- me target
       -- %s's %s hits you for %d %s damage.
      for source, attack, damage, school in string.gfind(arg1, pfSPELLLOGSCHOOLOTHERSELF) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

       -- %s's %s crits you for %d %s damage.
      for source, attack, damage, school in string.gfind(arg1, pfSPELLLOGCRITSCHOOLOTHERSELF) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

       -- %s's %s hits you for %d.
      for source, attack, damage in string.gfind(arg1, pfSPELLLOGOTHERSELF) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

       -- %s's %s crits you for %d.
      for source, attack, damage in string.gfind(arg1, pfSPELLLOGCRITOTHERSELF) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

      -- "You suffer %d %s damage from %s's %s."; -- You suffer 3 frost damage from Rabbit's Ice Nova.
      for damage, school, source, attack in string.gfind(arg1, pfPERIODICAURADAMAGEOTHERSELF) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

      -- %s hits you for %d.
      for source, damage in string.gfind(arg1, pfCOMBATHITOTHERSELF) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

      -- %s crits you for %d.
      for source, damage in string.gfind(arg1, pfCOMBATHITCRITOTHERSELF) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

      -- %s hits you for %d %s damage.
      for source, damage, school in string.gfind(arg1, pfCOMBATHITSCHOOLOTHERSELF) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

      -- %s crits you for %d %s damage.
      for source, damage, school in string.gfind(arg1, pfCOMBATHITCRITSCHOOLOTHERSELF) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

      -- other
       -- %s's %s hits %s for %d %s damage.
      for source, attack, target, damage, school in string.gfind(arg1, pfSPELLLOGSCHOOLOTHEROTHER) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

       -- %s's %s crits %s for %d %s damage.
      for source, attack, target, damage, school in string.gfind(arg1, pfSPELLLOGCRITSCHOOLOTHEROTHER) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

       -- %s's %s hits %s for %d.
      for source, attack, target, damage in string.gfind(arg1, pfSPELLLOGOTHEROTHER) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

       -- %s's %s crits %s for %d.
      for source, attack, target, damage, school in string.gfind(arg1, pfSPELLLOGCRITOTHEROTHER) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

      -- "%s suffers %d %s damage from %s's %s."; -- Bob suffers 5 frost damage from Jeff's Ice Nova.
      for target, damage, school, source, attack in string.gfind(arg1, pfPERIODICAURADAMAGEOTHEROTHER) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

      -- %s hits %s for %d.
      for source, target, damage in string.gfind(arg1, pfCOMBATHITOTHEROTHER) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

      -- %s crits %s for %d.
      for source, target, damage in string.gfind(arg1, pfCOMBATHITCRITOTHEROTHER) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

      -- %s hits %s for %d %s damage.
      for source, target, damage, school in string.gfind(arg1, pfCOMBATHITSCHOOLOTHEROTHER) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end

      -- %s crits %s for %d %s damage.
      for source, target, damage, school in string.gfind(arg1, pfCOMBATHITCRITSCHOOLOTHEROTHER) do
        pfUI.damagemeter:AddData(source, attack, target, damage, school)
        return
      end
    end
  end)
end)
