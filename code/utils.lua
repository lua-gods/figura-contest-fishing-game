local mod = {}

local mathAbs = math.abs
local mathSin = math.sin
local mathFloor = math.floor

---@generic value
---@param tbl {value: value, weight: number}[]
---@param rand number?
---@return value
function mod.weightedRandom(tbl, rand)
   rand = rand or math.random()
   local totalWeight = 0
   for _, v in ipairs(tbl) do
      totalWeight = totalWeight + v.weight
   end
   rand = rand * totalWeight
   local n = 0
   for _, v in ipairs(tbl) do
      n = n + v.weight
      if n >= rand then
         return v.value
      end
   end
   return tbl[1].value
end

---@param seed number
---@return number
function mod.seededRand(seed)
   return (mathSin(seed * 48.1489) * 8512.4115) % 1
end

---@param seed number
---@param max integer
---@return number
function mod.seededRandInt(seed, max)
   return mathFloor(((mathSin(seed * 48.1489) * 8512.4115) % 1) * max) + 1
end

---@param str string
---@return number
function mod.hashString(str)
   local n = 0
   local buffer = data:createBuffer()
   buffer:writeByteArray(str)
   buffer:setPosition(0)
   for _ = 0, buffer:available(), 4 do
      local v = mathAbs(buffer:readInt()) / 849418.13489
      n = (mathSin(v + n) * 48249.924) % 1
   end
   buffer:close()
   return n % 1
end

mod.contextToLeftHanded = {
   FIRST_PERSON_LEFT_HAND = true,
   FIRST_PERSON_RIGHT_HAND = false,
   THIRD_PERSON_LEFT_HAND  = true,
   THIRD_PERSON_RIGHT_HAND = false,
}

mod.isFirstPersonContext = {
   FIRST_PERSON_LEFT_HAND  = true,
   FIRST_PERSON_RIGHT_HAND = true,
}

mod.isThirdPersonContext = {
   THIRD_PERSON_LEFT_HAND  = true,
   THIRD_PERSON_RIGHT_HAND = true,
}

mod.isHoldingItemContext = {
   FIRST_PERSON_LEFT_HAND  = true,
   FIRST_PERSON_RIGHT_HAND = true,
   THIRD_PERSON_LEFT_HAND  = true,
   THIRD_PERSON_RIGHT_HAND = true,
}

mod.firstPersonCenterItemOffsets = {
   ["FIRST_PERSON_LEFT_HAND"] = vec(-8.96, 16.33, -12.5),
   ["FIRST_PERSON_RIGHT_HAND"] = vec(8.96, 16.33, -12.5),
}

---@param block BlockState
---@return boolean
function mod.isWater(block)
   return block.id == "minecraft:water" or block:getFluidTags()[1] == "minecraft:water"
end

---@param delta number?
function mod.skullCenterToWorldMat(delta)
   local camRot = client.getViewer():getRot(delta or 1)
   local camPos = client.getCameraPos()

   local fov = math.tan(math.rad(client.getFOV() / 2)) * 2
   local mat = matrices.mat4()
   mat:translate(-camPos * 16)
   mat:rotateY(camRot.y)
   :rotateX(-camRot.x)

   local scale = 1 / fov * 0.933
   mat:scale(scale, scale, 0.7)
   return mat
end

return mod