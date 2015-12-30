(function()
  -- Some Internal Functions
  
  -- foldr(function, default_value, table)
  -- e.g: foldr(operator.mul, 1, {1,2,3,4,5}) -> 120
  -- Out Functional Library <http://lua-users.org/wiki/FunctionalLibrary>
  local function foldr(func, val, tbl)
     for i,v in _G.pairs(tbl) do
         val = func(val, v)
     end
     return val
  end
  
  -- slice(table, start, length)
  -- e.g. slice({1,2,3,4,5}, 2, 3) => {2,3,4}
  -- Out of underscore.lua
  local function slice(array, start_index, length)
    if length == 0 then
      return {}
    end
    local sliced_array = {}
    
    start_index = math.max(start_index, 1)
    local end_index = math.min(start_index+length-1, #array)
    for i=start_index, end_index do
      sliced_array[#sliced_array+1] = array[i]
    end
    return sliced_array
  end
  
  -- head(table)
  -- e.g: head({1,2,3}) -> 1
  -- Out Functional Library <http://lua-users.org/wiki/FunctionalLibrary>
  local function head(tbl)
     return tbl[1]
  end

  -- tail(table)
  -- e.g: tail({1,2,3}) -> {2,3}
  --
  -- XXX This is a BAD and ugly implementation.
  -- should return the address to next porinter, like in C (arr+1)
  --
  -- Out Functional Library <http://lua-users.org/wiki/FunctionalLibrary>
  local function tail(tbl)
     if _G.table.getn(tbl) < 1 then
         return nil
     else
         local newtbl = {}
         local tblsize = _G.table.getn(tbl)
         local i = 2
         while (i <= tblsize) do
             _G.table.insert(newtbl, i-1, tbl[i])
             i = i + 1
         end
        return newtbl
     end
  end
  
  -- reduce(function, table)
  -- e.g: reduce(operator.add, {1,2,3,4}) -> 10
  -- Out Functional Library <http://lua-users.org/wiki/FunctionalLibrary>
  local function reduce(func, tbl, init)
     if init ~= nil then
       return foldr(func, init, tbl)
     end
     return foldr(func, head(tbl), tail(tbl))
  end
  
  -- operator table.
  -- @see also python's operator module.
  -- Out Functional Library <http://lua-users.org/wiki/FunctionalLibrary>
  local operator = {
     mod = math.mod;
     pow = math.pow;
     add = function(n,m) return n + m end;
     sub = function(n,m) return n - m end;
     mul = function(n,m) return n * m end;
     div = function(n,m) return n / m end;
     gt  = function(n,m) return n > m end;
     lt  = function(n,m) return n < m end;
     eq  = function(n,m) return n == m end;
     le  = function(n,m) return n <= m end;
     ge  = function(n,m) return n >= m end;
     ne  = function(n,m) return n ~= m end;
  }
  
  -- Packs the stack into a table.
  -- Selfwritten
  local pack = function(...)
    return {...}
  end
  
  -- Pythons True-Div
  -- Selfwritten
  local truediv = function(a,b)
    return (a - (a%b))/b
  end
  
  -- timing_defaults(pos, max_pos) -> pos, max_pos
  local timing_defaults = function(pos, max_pos)
    if pos == nil then
      pos = math.max(0, tenv.j)
    end
    if max_pos == nil then
      max_pos = math.max(1, tenv.maxj)
    end
    return pos, max_pos
  end
  
  ------------------------------------------------------------------------
  -- Multi-Loop Base-Functions                                          --
  ------------------------------------------------------------------------
  tenv.multiloop = {}
  
  -- multiloop.set(...) -> ""
  -- Multiloop declaration. Updates maxj to set it to the
  -- multi-loop count.
  tenv.multiloop.set = function(...)
    tenv.maxloop(reduce(operator.mul, pack(...)))
    return ""
  end
  
  -- multiloop.get_all(...) -> {...}
  -- Returns all current multiloop counts.
  tenv.multiloop.get_all = function(...)
    local values = pack(...)
    result = {}
    for i = 1,#values do
      local __values = slice(values, 1, i-1)
      _G.table.insert(result, truediv(tenv.j, foldr(operator.mul, 1, __values)) % values[i])
    end
    return result
  end
  
  -- multiloop.get(i, ...) -> number
  -- Shorthand of multiloop.get_all(...)[i]
  tenv.multiloop.get = function(i, ...)
    return tenv.multiloop.get_all(...)[i]
  end
  
  -- multiloop.get_loopctl(i, ...) -> pos, max_pos
  -- A useful function to receive the time-data required for
  -- transform, from and distribute.
  tenv.multiloop.get_loopctl = function(i, ...)
    return tenv.multiloop.get_all(...)[i], pack(...)[i]
  end
  
  ------------------------------------------------------------------------
  -- Frame 4 Frame Base                                                 --
  ------------------------------------------------------------------------
  
  -- These functions defined in this scope are the basic functions needed
  -- for Frame4Frame.
  
  -- transform(accel=1, pos=tenv.j, max_pos=tenv.maxj) -> float
  -- Some functions require a time-argument. You calculate the argument
  -- using this function.
  tenv.transform = function(accel, pos, max_pos)
    if accel == nil then
      accel = 1
    end
    pos, max_pos = timing_defaults(pos, max_pos)
    return (pos / max_pos) ^ accel
  end
  
  -- from(offset, [pos, max_pos]) -> pos, max_pos
  tenv.from = function(offset, pos, max_pos)
    pos, max_pos = timing_defaults(pos, max_pos)
    local max_pos = max_pos-offset
    return math.max(0,pos-offset), max_pos
  end
  
  -- to(max, [pos, max_pos]) -> pos, max_pos
  tenv.to = function(offset, pos, max_pos)
    pos, max_pos = timing_defaults(pos, max_pos)
    local max_pos = max_pos-offset
    if offset>=pos then
      return 1, max_pos
    end
    return pos, max_pos
  end
  
  -- slice(from, to, [pos, max_pos]) -> pos, max_pos
  tenv.fromto = function(from, to, pos, max_pos)
    return tenv.from(from, tenv.to(to, pos, max_pos))
  end

  -- distribute([j, [maxj]]) -> ""
  -- Will distribute all times.
  tenv.distribute = function(j, maxj)
    if j == nil then
      j = tenv.j
    end
    if maxj == nil then
      maxj = tenv.maxj
    end
    
    local start, stop = tenv.line.start_time, tenv.line.end_time
    local duration = tenv.line.duration
    local newstart = math.floor(start + (j - 1) / maxj * duration)
    local newend = math.floor(start + j / maxj * duration)
    tenv.retime("set", newstart, newend)
    return ""
  end
  
  -- frames([length]) -> number
  -- Returns the amount of frames the given (possibly retimed) line will be shown.
  tenv.frames = function(length)
    if length == nil then
      length = (1000/(_G.aegisub.frame_from_ms(1000) or 20))
    end
    local start, stop = tenv.line.start_time, tenv.line.end_time
    return math.max(math.floor((stop-start) / length), 1)
  end
end)()
