(function()
  -- Some Internal Functions
  
  -- foldr(function, default_value, table)
  -- e.g: foldr(operator.mul, 1, {1,2,3,4,5}) -> 120
  local function foldr(func, val, tbl)
     for i,v in _G.pairs(tbl) do
         val = func(val, v)
     end
     return val
  end
  
  -- slice(table, start, length)
  -- e.g. slice({1,2,3,4,5}, 2, 3) => {2,3,4}
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
  local function head(tbl)
     return tbl[1]
  end

  -- tail(table)
  -- e.g: tail({1,2,3}) -> {2,3}
  --
  -- XXX This is a BAD and ugly implementation.
  -- should return the address to next porinter, like in C (arr+1)
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
  local function reduce(func, tbl, init)
     if init ~= nil then
       return foldr(func, init, tbl)
     end
     return foldr(func, head(tbl), tail(tbl))
  end
  -- operator table.
  -- @see also python's operator module.
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
  local pack = function(...)
    return {...}
  end
  
  local truediv = function(a,b)
    return (a - (a%b))/b
  end
  
  -- bind1(func, binding_value_for_1st)
  -- bind2(func, binding_value_for_2nd)
  -- @brief
  --      Binding argument(s) and generate new function.
  -- @see also STL's functional, Boost's Lambda, Combine, Bind.
  -- @examples
  --      local mul5 = bind1(operator.mul, 5) -- mul5(10) is 5 * 10
  --      local sub2 = bind2(operator.sub, 2) -- sub2(5) is 5 -2
  local function bind1(func, val1)
     return function (val2)
         return func(val1, val2)
     end
  end
  local function bind2(func, val2) -- bind second argument.
     return function (val1)
         return func(val1, val2)
     end
  end
  
  -- enumFromTo(from, to)
  -- e.g: enumFromTo(1, 10) -> {1,2,3,4,5,6,7,8,9}
  -- TODO How to lazy evaluate in Lua? (thinking with coroutine)
  local enumFromTo = function (from,to)
     local newtbl = {}
     local step = bind2(operator[(from < to) and "add" or "sub"], 1)
     local val = from
     while val <= to do
         _G.table.insert(newtbl, _G.table.getn(newtbl)+1, val)
         val = step(val)
     end
     return newtbl
  end
  
  -- curry(f,g)
  -- e.g: printf = curry(io.write, string.format)
  --          -> function(...) return io.write(string.format(unpack(arg))) end
  local function curry(f,g)
     return function (...)
         return f(g(...))
     end
  end
  
  -- beziere(time, ...) -> {x,y}
  -- Calculates the Point on a beziere curve at the given position.
  tenv.bezier = function(t, ...)
    local p = pack(...)
    local fac = function(n)
      local result = 1
      for i = 2,n do
        result = result * i
      end
      return result
    end
    local bin = function(i, n)
      return (fac(n)/(fac(i)*fac(n-i)))
    end
    local bern = function(t, i, n)
      return b(i, n) * t^i * (1-t)^(n-i)
    end
    local point = {}
    local n = #p-1
    for i = 0,n do
      local bern = bin(i,n) * t^i * (1-t)^(n-i)
      for j = 1,#(p[i+1]) do
        local _pval = 0
        
        if point[j] ~= nil then
          _pval = point[j]
        end
        
        point[j] = _pval + p[i+1][j] * bern
      end
    end
    return point
  end
  
  -- edgeline(time, ...) -> {x,y}
  -- Calculates a point on a line with edges.
  tenv.edgeline = function(t, ...)
    local edges = pack(...)
    
    -- Shortcut if we are on <=0 
    if t>=1 then
      return edges[#edges]
    end
    if t<=0 then
      return edges[0]
    end
    
    -- Get the actual points and calculate the relative
    -- position of the variable.
    local c_edges = #edges
    local actual_t = t*(c_edges-1)
    local rel_t = actual_t%1
    local p_edge = math.floor(actual_t)+1
    p1 = edges[p_edge]
    p2 = edges[p_edge+1]
    
    local result_p = {}
    for i = 1,#p1 do
        result_p[i] = p1[i] + (p2[i]-p1[i])*rel_t
    end
    
    -- Interpolate the point.
    return result_p
  end
  
  -- pos(x,y=nil) -> "\\pos(#{x},#{y})"
  -- Prints a proper position tag.
  tenv.pos = function(x, y)
    if y == nil then
      x,y = _G.unpack(x)
    end
    return "\\pos(" .. _G.tostring(x) .. "," .. _G.tostring(y) .. ")"
  end
  
  -- color(r,g=nil,b=nil, a=nil) -> "&H(aa)bbggrr&"
  -- Prints a color from the calculated geometry.
  -- If a is given or r is a table with four entries, a ass_style_color will be returned.
  -- Otherwise a normal color.
  tenv.color = function(r, g, b, a)
    if g == nil then
      if #r == 3 then
        r,g,b = _G.unpack(r)
      else
        r,g,b,a = _G.unpack(r)
      end
    end
    
    if a == nil then
      return _G.util.ass_color(r,g,b)
    end
    return _G.util.ass_style_color(r,g,b,a)
  end
  
  -----------------------------------------------------------------------------
  -- Affine Transformations                                                  --
  -----------------------------------------------------------------------------
  
  local function affineTransform(p, matrix)
    local function transformLine(p, n, m)
      local result = 0
      for i = 1,#p+1 do
        -- Support translate column now.
        local pc = p[i]
        if pc == nil then
          pc = 1
        end
        
        -- If the translate column is not given,
        -- we will ignore the point.
        local mc = m[n][i]
        if mc == nil then
          mc = 0
        end
        
        result = result + pc*mc
      end
      return result
    end
    return {
      transformLine(p, 1, matrix),
      transformLine(p, 2, matrix)
    }
  end
  
  -- rotate(p, theta) -> p
  tenv.rotate = function(p, theta)
    return affineTransform(p, {
       {math.cos(theta), -math.sin(theta)},
       {math.sin(theta),  math.cos(theta)}
    })
  end
  
  -- shear(p, x=0, y=0) -> p
  tenv.shear = function(p, x, y)
    if x == nil then
      x = 0
    end
    if y == nil then
      y = 0
    end
    return affineTransform(p, {
      {1, x},
      {y, 1}
    })
  end
  
  -- scale(p, x=1, y=1) -> p
  tenv.scale = function(p, x, y)
    if x == nil then
      x = 1
    end
    if y == nil then
      y = 1
    end
    
    return affineTransform(p, {
      {x, 0},
      {0, y}
    })
  end
  
  -- translate(...) -> p
  -- Moves a point.
  tenv.translate = function(...)
    return foldr(function(p1,p2) return {p1[1]+p2[1], p1[2]+p2[2]} end, {0,0}, pack(...))
  end
end)()
