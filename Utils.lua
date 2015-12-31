(function()
  
  if tenv == nil then
    tenv = {}
  end
  
  local function starts(String,Start)
     return string.sub(String,1,string.len(Start))==Start
  end
  
  local function ends(String,End)
     return End=='' or string.sub(String,-string.len(End))==End
  end
  
  local function split(str, delim, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gmatch(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
  end
  
  tenv.parse = function(default)
    -- Control defaults.
    if default == nil then
      default = "true"
    end
    
    -- Parse the line.
    local actor = tenv.line.actor
    local words = split(actor, " ")
    
    local datatable = {}
    for i = 1,#words do
      -- Parse the word.
      local word = split(words[i], ":", 2)
      local value = default
      
      -- Split on ":"
      if #word > 1 then
        word, value = word[1], word[2]
      else
        word = word[1]
      end
      
      -- Parse the value for
      --   . True / False
      --   . Numbers
      --   . Colors/Alpha or both
      if value == "true" then
        value = true
      elseif value == "false" then
        value = false
      elseif _G.tonumber(value) ~= nil then
        value = _G.tonumber(value)
      elseif starts(value, "&H") and ends(value, "&") then
        local length = _G.unicode.len(value)
        local r,g,b,a = _G.util.extract_color(value)
        
        if length == 3+2 then
          value = a
        elseif length == 3+6 then
          value = {r,g,b}
        elseif length == 3+8 then
          value = {r,g,b,a}
        end
      end
      
      -- Set the value.
      datatable[word] = value
      
    end
    
    -- Return the table.
    return datatable
  end
end)()
