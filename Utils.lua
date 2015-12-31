(function()
  
  if tenv == nil then
    tenv = {}
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
    for part, pos in string.gfind(str, pat) do
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
    if default == nil then
      default = "true"
    end
    
    local actor = tenv.line.actor
    local words = split(actor, " ")
    
    local datatable = {}
    for i = 1,#words do
      local word = split(words[i], ":", 2)
      local value = default
      
      if #word > 1 then
        word, value = word[1], word[2]
      else
        word = word[1]
      end
      
      print(word)
      print(value)
      
      datatable[word] = value
      
    end
    
    return datatable
  end
end)()
