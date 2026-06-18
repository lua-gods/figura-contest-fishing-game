local skullModes = require("code.skull_modes")
local customItemHelper = require("code.custom_item_helper")
local utils = require("code.utils")
local mode = skullModes.newMode()

local model = models.model.Skull_fishing_rod
mode:setModel(model)

model.game:setScale(0.2, 0.2, 1)
model.rod:newItem(""):setItem("minecraft:fishing_rod")
model.game.bg:setPrimaryRenderType("CUTOUT_EMISSIVE_SOLID")
model.game.cursor:setPrimaryRenderType("CUTOUT_EMISSIVE_SOLID")

local bobberModel = models.model.fishing_bobber
bobberModel:moveTo(worldModel)
bobberModel:setVisible(false)

local bobberVisibleFrame = -10
local bobberPos = vec(0, 0, 0)
local bobberOldPos = vec(0, 0, 0)
local bobberVel = vec(0, 0, 0)
local bobberInWater = false

local fishCatchTick = 0

local fishingGame = false
local fishingTimer = 0

bobberModel.preRender = function()
   if avatarFrame > bobberVisibleFrame then
      bobberModel:setVisible(false)
   end
end

function mode.render(delta, block, item, entity, ctx)
   model.game:setVisible(false)
   local mat, modelType = customItemHelper.getMatrix(entity, ctx, 2)

   model.rod:setMatrix(mat)
   local viewer = client.getViewer()
   if not entity or entity:getUUID() ~= viewer:getUUID() then
      return
   end

   if utils.isFirstPersonContext[ctx] then
      if viewerClicked then
         local isOffHand = viewer:isLeftHanded() ~= utils.contextToLeftHanded[ctx]
         if bobberVisibleFrame > avatarFrame then
            if fishCatchTick > avatarTick then
               fishingGame = true
            else
               bobberVisibleFrame = -10
            end
         else
            bobberVisibleFrame = avatarFrame + 10
            bobberPos = viewer:getPos():add(0, viewer:getEyeHeight())
            bobberOldPos = bobberPos
            bobberVel = viewer:getLookDir() * 0.7 + vec(0, 0.2, 0)
            bobberPos = bobberPos + bobberVel
            fishingTimer = 0
            fishingGame = false
         end
         bobberModel:setVisible(true)
      end
      if bobberVisibleFrame > avatarFrame then
         bobberVisibleFrame = avatarFrame + 10
         if fishingGame or true then
            model.game:setVisible(true)
               :setPos(utils.firstPersonCenterItemOffsets[ctx])
         end
      end
      bobberModel:setPos(math.lerp(bobberOldPos, bobberPos, delta) * 16)
   end
end

function mode.tick(init)
   if init then
      bobberVisibleFrame = -10
      bobberModel:setVisible(false)
      bobberOldPos = vec(0, 0, 0)
      bobberPos = vec(0, 0, 0)
      bobberVel = vec(0, 0, 0)
      bobberInWater = false
      fishingGame = false
   end
   if bobberVisibleFrame < avatarFrame then
      return
   end
   local viewer = client.getViewer()
   if (viewer:getPos() - bobberPos):length() > 24 then
      bobberVisibleFrame = -10
      return
   end
   bobberOldPos = bobberPos
   bobberVel = (bobberVel - vec(0, 0.045, 0)) * 0.92
   for axis = 1, 3 do
      local endPos = bobberPos:copy()
      endPos[axis] = endPos[axis] + bobberVel[axis]
      local _, hitPos = raycast:block(bobberPos, (endPos - bobberPos):clampLength(0, 10) + bobberPos)
      local offset = (hitPos or bobberPos) - bobberPos
      local dist = offset:length()
      if dist > 0.0001 then
         bobberPos = bobberPos + offset / dist * math.max(dist - 0.001, 0)
      end
   end
   if math.abs((bobberPos - bobberOldPos):length() - bobberVel:length()) > 0.01 then
      bobberVel = bobberVel * 0.2
   end
   local block = world.getBlockState(bobberPos)
   if #block:getFluidTags() >= 1 then
      local blockUp = world.getBlockState(bobberPos + vec(0, 1, 0))
      local waterLevel = #blockUp:getFluidTags() >= 1 and 1 or 1 - bobberPos.y % 1
      bobberVel = bobberVel * 0.6
      bobberVel.y = bobberVel.y + 0.08 * (waterLevel + (math.cos(avatarTick * 0.2) + 1) * 0.05 + 0.3 + math.random() * 0.05)
   end

   bobberInWater = utils.isWater(world.getBlockState(bobberPos - vec(0, 0.25, 0)))
   if bobberInWater then
      fishingTimer = fishingTimer + 1
   else
      fishingTimer = fishingTimer * 0.5
   end
   if not fishingGame then
      if bobberInWater and fishingTimer > 120 and math.random() > 0.99 then
         bobberVel = bobberVel - vec(0, 0.15, 0)
         fishCatchTick = avatarTick + 20
         fishingTimer = 60
         for _ = 1, 16 do
            particles:newParticle("minecraft:bubble", bobberPos + (vec(math.random(), 0.5, math.random()) - 0.5) * 1.2)
            particles:newParticle("minecraft:splash", bobberPos + (vec(math.random(), 0.5, math.random()) - 0.5) * 1.2)
         end
      end
      return
   end
end

return mode