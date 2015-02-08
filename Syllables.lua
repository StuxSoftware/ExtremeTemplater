(function()
  -- Our Value-Cache to increase the performance on loop templates.
  local _spos_lru = {}

  -- A decorator generator for the LRU-Cache.
  local function _spos_decorate_lru(func, name)
    return function()
      local l = tenv.line
      local s = tenv.syl
    
      -- Query the cache so we don't have to calculate the syllable position
      -- anytime we want to query the syllable position.
      if _spos_lru[l.style] ~= nil then
        if _spos_lru[l.style][l.i] ~= nil then
          if _spos_lru[l.style][l.i][s.i] ~= nil then
            if _spos_lru[l.style][l.i][s.i][name] ~= nil then
              return _spos_lru[l.style][l.i][s.i][name]
            end
          end
        end
      end
      
      -- Compute the value to put it into the cache.
      local result = func()
      
      -- Update value-cache.
      if _spos_lru[l.style] == nil then
        _spos_lru[l.style] = {}
      end
      if _spos_lru[l.style][l.i] == nil then
        _spos_lru[l.style][l.i] = {}
      end
      if _spos_lru[l.style][l.i][s.i] == nil then
        _spos_lru[l.style][l.i][s.i] = {}
      end
      _spos_lru[l.style][l.i][s.i][name] = result
      
      -- Return the result.
      return result
    end
  end

  --[[
  Please note that most values are cached so that we get a performance
  speedup on kanji karaoke templates.
  ]]
  tenv.getSylY = _spos_decorate_lru(function()
    -- Ensure that we are in a Syllable Template.
    if tenv["syl"] == nil then
      error("This function must be executed in a syllable template.")
    end
    
    -- Return the default position on non Kanji Alignments.
    local syl = tenv.syl
    if tenv.line.valign ~= "middle" then
      return line.middle
    end
    
    local height = 0
    local pos = 0
    local lheight = 0
    
    for si = 1,#tenv.line.kara do
      if not _G.is_syl_blank(tenv.line.kara[si]) then
        if tenv.line.kara[si].i <= syl.i then
          lheight = 0
        end
        
        for char in _G.unicode.chars(tenv.line.kara[si].text) do
          local w, h, d, e = _G.aegisub.text_extents(tenv.line.styleref, char)
          height = height + h
          if tenv.line.kara[si].i <= syl.i then
            pos = pos + h
            lheight = lheight + h
          end
        end
      end
    end
    return (meta.res_y-height)/2+pos-(lheight/2)
  end, "y")

  tenv.getSylX = _spos_decorate_lru(function()
    if tenv["syl"] == nil then
      error("This function must be executed in a syllable template.")
    end
    
    local syl = tenv.syl
    if tenv.line.valign ~= "middle" then
      return line.left + syl.center
    else
      if tenv.line.halign == "right" then
        return meta.res_x-line.eff_margin_r-line.height/2
      elseif tenv.line.halign == "left" then
        return line.eff_margin_l+line.height/2
      elseif tenv.line.halign == "center" then
        return(meta.res_x - tenv.line.height)/2
      end
    end
  end, "x")

  --[[
  Please note that most values are cached so that we get a performance
  speedup on kanji karaoke templates.
  ]]
  tenv.getSylText = _spos_decorate_lru(function()
    if tenv["syl"] == nil then
      error("This function must be executed in a syllable template.")
    end
    local syl = tenv.syl
    if tenv.line.valign ~= "middle" then
      return syl.text
    else
      local result = ""
      local first = true
      
      for char in _G.unicode.chars(tenv.syl.text) do
        if not first then
          result = result .. "\\N"
        end
        result = result .. char
        first = false
      end
      return result
    end
  end, "text")
  
  -- Shortcut that creates a point for the position of the
  -- syllable.
  tenv.getSylPos = function()
    return {tenv.getSylX(), tenv.getSylY()}
  end
end)()
