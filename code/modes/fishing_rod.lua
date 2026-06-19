local skullModes = require("code.skull_modes")
local customItemHelper = require("code.custom_item_helper")
local utils = require("code.utils")
local mode = skullModes.newMode()

local model = models.rod.Skull_fishing_rod
mode:setModel(model)

local mainTexture = textures["texture"]
model.rod.normal.normal2d:addChild(customItemHelper.makeIcon(mainTexture, vec(0, 16), vec(16, 16)))
model.rod.used.used2d:addChild(customItemHelper.makeIcon(mainTexture, vec(0, 32), vec(16, 16)))
model.game:setPrimaryRenderType("EMISSIVE_SOLID")

local fishingGameScale = 0.12

local bobberModel = models.rod.fishing_bobber
bobberModel:moveTo(worldModel)
bobberModel:setVisible(false)

local bobberVisibleFrame = -10
local bobberPos = vec(0, 0, 0)
local bobberOldPos = vec(0, 0, 0)
local bobberVel = vec(0, 0, 0)
local bobberInWater = false

local fishCatchTick = 0
local fishingTimer = 0

local fishingGame = false
local gameCursorSize = 0.25
local gameCursorY = 0
local gameCursorYOld = 0
local gameCursorVel = 0
local gameFishY = 0
local gameFishYOld = 0
local gameProgress = 0
local gameProgressOld = 0
local gameProgressVel = 0
local gameEndDelay = 0

local hasFirstPersonMod = client.isModLoaded("firstperson")

bobberModel.preRender = function()
   if avatarFrame > bobberVisibleFrame then
      bobberModel:setVisible(false)
   end
end

local function startFishingGame()
   fishingGame = true
   gameCursorY = 0.5
   gameCursorYOld = 0.5
   gameCursorVel = 0
   gameFishY = 0.6
   gameFishYOld = 0.6
   gameProgress = 0.5
   gameProgressOld = 0.5
   gameProgressVel = 0
   gameEndDelay = 0
end

function mode.render(delta, block, item, entity, ctx)
   model.game:setVisible(false)
   local mat, modelType = customItemHelper.getMatrix(entity, ctx, 2)

   model.rod:setMatrix(mat)
   local rodUsed = bobberVisibleFrame > avatarFrame
   local modelToUse = rodUsed and "used" or "normal"
   model.rod.normal:setVisible(not rodUsed)
   model.rod.used:setVisible(rodUsed)
      :setRot(0, 0, 0)
   model.rod[modelToUse][modelToUse..'3d']:setVisible(modelType == 3)
   model.rod[modelToUse][modelToUse..'2d']:setVisible(modelType == 2)

   local viewer = client.getViewer()
   if not entity or entity:getUUID() ~= viewer:getUUID() then
      return
   end

   if viewer:isSwingingArm() then
      local isLeftHanded = viewer:isLeftHanded()
      if isLeftHanded ~= utils.contextToLeftHanded[ctx] then
         local x = viewer:getSwingTime() + delta
         x = math.clamp(x * 0.2, 0, 1)
         x = 1 - (1 - x) ^ 2
         x = 1 - (1 - x * 2) ^ 2
         model.rod.used:setRot(x * 40 * (isLeftHanded and 1 or -1), 0, x * 70)
      end
   end
   if viewerClicked then
      if bobberVisibleFrame > avatarFrame then
         if not fishingGame then
            if fishCatchTick > avatarTick then
               startFishingGame()
            elseif avatarTick > fishCatchTick + 20 then
               bobberVisibleFrame = -10
               sounds:playSound("minecraft:entity.fishing_bobber.retrieve", viewer:getPos(), 0.5, 1)
            end
         end
      else
         bobberVisibleFrame = avatarFrame + 10
         bobberPos = viewer:getPos():add(0, viewer:getEyeHeight())
         bobberOldPos = bobberPos
         bobberVel = viewer:getLookDir() * 0.7 + vec(0, 0.2, 0)
         bobberPos = bobberPos + bobberVel
         fishingTimer = 0
         fishingGame = false
         sounds:playSound("minecraft:entity.fishing_bobber.throw", viewer:getPos(), 0.2, 0.5)
      end
      bobberModel:setVisible(true)
   end
   if bobberVisibleFrame > avatarFrame then
      bobberVisibleFrame = avatarFrame + 10
      if fishingGame then
         local cursorY = math.lerp(gameCursorYOld, gameCursorY, delta)
         model.game.cursor:setPos(0, cursorY * (1 - gameCursorSize) * 62, 0)
         local s = gameCursorSize * 62 - 2
         model.game.cursor.middle:setScale(1, s, 1)
         model.game.cursor.top:setPos(0, s - 1, 0)
         model.game.fish:setPos(0, math.lerp(gameFishYOld, gameFishY, delta) * 56, 0)
         local progress = math.lerp(gameProgressOld, gameProgress, delta)
         model.game.progress:setScale(1, progress, 1)
            :setColor(vectors.hsvToRGB(progress * 0.3, 0.75, 1))

         local mat, isFirstPerson = customItemHelper.getCustomGuiMatrix(ctx)
         if isFirstPerson then
            mat = mat * matrices.scale4(fishingGameScale, fishingGameScale, 1)
         end
         model.game:setVisible(true)
            :setMatrix(mat)
      end
   end
   bobberModel:setPos(math.lerp(bobberOldPos, bobberPos, delta) * 16)
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
   --[[-- debug
   fishingGame = true
   gameProgress = 0.5
   bobberVisibleFrame = avatarFrame + 100
   bobberPos = client.getCameraPos() - vec(0, 4, 0)
   bobberModel:setVisible(true)
   --]]
   if bobberVisibleFrame < avatarFrame then
      return
   end
   bobberOldPos = bobberPos
   gameCursorYOld = gameCursorY
   gameFishYOld = gameFishY
   gameProgressOld = gameProgress
   local viewer = client.getViewer()
   if (viewer:getPos() - bobberPos):length() > 24 then
      bobberVisibleFrame = -10
      return
   end
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
   -- win or lose
   if gameEndDelay >= 1 then
      gameEndDelay = gameEndDelay + 1
      if gameEndDelay >= 20 then
         bobberVisibleFrame = -10
         bobberVisibleFrame = -10
         host:setActionbar("game finished")
      end
      return
   end
   -- fish
   -- vip
   gameFishY = math.cos(avatarTick * 0.05 + math.sin(avatarTick * 0.07)) * 0.5 + 0.5
   -- cursor
   local isClicking = viewer:isSneaking() or viewer:isSwingingArm() and viewer:getSwingTime() <= 4
   gameCursorVel = gameCursorVel * 0.95 + (isClicking and 1 or -1) * 0.01
   gameCursorY = gameCursorY + gameCursorVel
   for _ = 1, 2 do
      gameCursorY = 1 - gameCursorY
      gameCursorVel = -gameCursorVel
      if gameCursorY < 0 then
         gameCursorVel = isClicking and 0 or math.abs(gameCursorVel) * 0.8
         gameCursorY = 0
      end
   end
   -- cursor check
   local cursorMin = gameCursorY * (1 - gameCursorSize)
   local cursorMax = cursorMin + gameCursorSize
   if cursorMin < gameFishY + 0.04 and cursorMax > gameFishY - 0.04 then
      gameProgressVel = math.lerp(gameProgressVel, 1, 0.6)
   else
      gameProgressVel = math.lerp(gameProgressVel, -0.8, 0.3)
   end
   -- progress
   gameProgress = gameProgress + gameProgressVel * 0.01
   gameProgress = math.clamp(gameProgress, 0, 1)
   if gameProgress == 1 or gameProgress == 0 then
      gameEndDelay = 1
   end
end

return mode