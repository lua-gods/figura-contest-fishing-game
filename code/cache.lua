local mod = {}

local tempData = {}

local emptyFunc = function() end

---@generic value
---@param name string
---@param func fun(name: string): value, function?
---@param initValue any
---@return value
function mod.get(name, func, initValue)
   if tempData[name] then
      tempData[name][1] = avatarTick
      return tempData[name][2]
   end
   local v, callback = func(initValue)
   if v then
      tempData[name] = {
         avatarTick,
         v,
         callback or emptyFunc
      }
   end
   return v
end

---@param name string
---@param v any
---@param callback function?
function mod.save(name, v, callback)
   tempData[name] = {
      avatarTick,
      v,
      callback or emptyFunc
   }
end

local lastIndex
function events.world_tick()
   local value
   lastIndex, value = next(tempData, tempData[lastIndex] and lastIndex or nil)
   if value and value[1] < avatarTick - 100 then
      value[3]()
      tempData[lastIndex] = nil
   end
end

return mod