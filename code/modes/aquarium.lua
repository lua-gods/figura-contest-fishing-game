local skullModes = require("code.skull_modes")
local utils = require("code.utils")
local cache = require("code.cache")
local fishLib  = require("code.fish")

local mode = skullModes.newMode()


local mainModel = models.aquarium.Skull
mode:setModel(mainModel)
mainModel:setPrimaryRenderType("TRANSLUCENT_CULL")
mainModel.sand.castle.walls:setPrimaryRenderType("TRANSLUCENT")

local glassFace = mainModel.glass_face:remove()
local glassEdge = mainModel.glass_edge:remove()
glassFace:setPrimaryRenderType("TRANSLUCENT_CULL")
glassEdge:setPrimaryRenderType("TRANSLUCENT_CULL")

local fishModel = mainModel:newPart("fish")
local lastFishModel = models:newPart(""):remove()
fishModel:setScale(0.4)
   :setRot(0, 22, 0)
   :setPos(2, 10, -3)

local lastFishModelFrame = -1

local glassModels = {}

local glassEdgesRots = {
   vec(0, 0, 0),
   vec(0, 0, 90),
   vec(0, 0, 180),
   vec(0, 0, -90),
}
local glassEdgesSides = {4, 1, 6, 2}

local glassSidesRots = {
   vec(-90, 0, 0),
   vec(90, 0, 0),
   vec(0, 0, 0),
   vec(0, 90, 0),
   vec(0, 180, 0),
   vec(0, -90, 0),
}

local glassSidesMap = {
   {3, 5, 2, 4, 1, 6},
   {5, 3, 1, 4, 2, 6},
   {1, 2, 3, 4, 5, 6},
   {1, 2, 6, 3, 4, 5},
   {1, 2, 5, 6, 3, 4},
   {1, 2, 4, 5, 6, 3},
}

local bit32Btest = bit32.btest
local worldGetBlock = world.getBlockState

for i = 0, 63 do
   local model = mainModel:newPart("")
   model:setVisible(false)
      :setPos(0, 8, 0)
   local sides = {
      bit32Btest(i, 1), bit32Btest(i, 2), bit32Btest(i, 4),
      bit32Btest(i, 8), bit32Btest(i, 16), bit32Btest(i, 32),
   }
   if i == 0 then
      model:newText("")
         :setText("a")
         :setScale(0, 0, 0)
   end
   for side = 1, 6 do
      local myModel = model:newPart("")
      myModel:setRot(glassSidesRots[side])
      if sides[ glassSidesMap[side][ 3 ] ] then
         myModel:addChild(glassFace)
         for k = 1, 4 do
            if sides[ glassSidesMap[side][ glassEdgesSides[k] ] ] then
               local m = glassEdge:copy("")
               m:setRot(glassEdgesRots[k])
               myModel:addChild(m)
            end
         end
      end
   end
   glassModels[i] = model
end

local lastGlassModel = glassModels[1]

local floorOffset = vec(0, 0, 0)
local wallOffset = vec(0, -4, -4)

local facingToRot = {
   north = 0,
   east = 4,
   south = 8,
   west = 12,
}

local headBlockIds = {
   ["minecraft:player_head"] = true,
   ["minecraft:player_wall_head"] = true,
}

---@param block BlockState
---@return boolean
local function isHead(block)
   return headBlockIds[block.id] or false
end

---@param pos Vector3
---@return ModelPart?
local function cacheInit(pos)
   if lastFishModelFrame == avatarFrame then
      return
   end
   lastFishModelFrame = avatarFrame
   local seed = utils.seededRand(pos.x + pos.y * 100 + pos.z * 10000)
   local name = fishLib.makeFishName(seed)
   local model = fishLib.getFishModel(name)[3]:copy("")
   return model
end

function mode.render(delta, block, item, entity, ctx)
   if not block then return end
   local properties = block.properties or {}
   local rot = (tonumber(properties.rotation) or facingToRot[properties.facing]) * 22.5
   mainModel:visible(true)
      :rot(0, rot, 0)
      :pos(properties.facing and wallOffset or floorOffset)

   local pos = block:getPos()
   local up = not isHead(worldGetBlock(pos + vec(0, 1, 0)))
   local down = not isHead(worldGetBlock(pos + vec(0, -1, 0)))
   local north = not isHead(worldGetBlock(pos + vec(0, 0, -1)))
   local south = not isHead(worldGetBlock(pos + vec(0, 0, 1)))
   local west = not isHead(worldGetBlock(pos + vec(-1, 0, 0)))
   local east = not isHead(worldGetBlock(pos + vec(1, 0, 0)))
   local n = (up and 1 or 0) +
      (down and 2 or 0) +
      (north and 4 or 0) +
      (east and 8 or 0) +
      (south and 16 or 0) +
      (west and 32 or 0)

   local rand = utils.seededRand(pos.x + pos.z * 10000)
   lastGlassModel:setVisible(false)
   lastGlassModel = glassModels[n]
   lastGlassModel:setVisible(true)
   mainModel.sand:setVisible(down)
   mainModel.sand.seagrass:setVisible(rand > 0.5)
   mainModel.sand.castle:setVisible((rand * 2) % 1 > 0.9)
   local id = "aquarium;"..tostring(pos)
   lastFishModel:remove()
   if (rand * 4) % 1 > 0.5 then
      local model = cache.get(id, cacheInit, pos)
      if model then
         fishModel:addChild(model)
         lastFishModel = model
         local time = avatarTick + delta + rand * 100
         local y = math.cos(time * 0.07 + math.sin(time * 0.02))
         model:setPos(0, y, 0)
      end
   end
end

function mode.tick()
   local anim = math.floor((avatarTick * 0.15) % 8) * 8
   mainModel.sand.seagrass:setUVPixels(anim, 0)
end

return mode