local skullModes = require("code.skull_modes")
local customItemHelper = require("code.custom_item_helper")
local utils = require("code.utils")
local itemsManager = require("code.items_manager")
local fishLib = require("code.fish")
local keybindHelper = require("code.keybind_helper")

local mode = skullModes.newMode()

local model = models.rod.Skull_fishing_rod
mode:setModel(model)

local mainTexture = textures["texture"]
model.rod.normal.normal2d:addChild(customItemHelper.makeIcon(mainTexture, vec(0, 16), vec(16, 16)))
model.rod.used.used2d:addChild(customItemHelper.makeIcon(mainTexture, vec(16, 16), vec(16, 16)))

local fishingGameScale = 0.12

local bobberModel = models.rod.fishing_bobber
bobberModel:moveTo(worldModel)
bobberModel:setVisible(false)
bobberModel.bobber_uv:setPrimaryRenderType("CUTOUT_CULL")

local stringModel = bobberModel.bobber_string

local gameModel = model.game_main
gameModel:setPrimaryRenderType("EMISSIVE_SOLID")

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
local gameFishRandom = 0
local gameFishYVel = 0
local gameFishYTarget = 0

local fishingGameAnimNew = 0
local fishingGameAnimOld = 0

local tutorialText = 1
local tutorialTexts = {
   function()
      return toJson{"Press ", {color = "aqua", text = keybindHelper.getVanillaKey("key.attack")}, " to cast\nfishing rod"}
   end,
   function()
      if not (fishingGame and bobberVisibleFrame >= avatarFrame) then
         return ""
      end
      return toJson{"Hold ", {color = "aqua", text = keybindHelper.getVanillaKey("key.sneak")}, " to move\nrectangle up"}
   end,
   function()
      if viewerGotBook then
         tutorialText = 4
         return ""
      end
      if bobberVisibleFrame >= avatarFrame then
         return ""
      end
      return toJson{"Rename player head to ", {color = "aqua", text = "book"}, " to get book\nyou can view all fished items there!"}
   end,
   function() return "" end, -- tutorial finished
}

local tutorialModel = model:newPart("")
local tutorialTextTask = tutorialModel:newText("")
tutorialTextTask:setOutline(true)
   :setScale(0.125)
   :pos(0, -12, 0)
   :alignment("CENTER")
   :setLight(15, 15)

local catchInfoTime = -90
local catchInfoMainModel = model:newPart("")
local catchInfoModel = catchInfoMainModel:newPart("")

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
   gameFishYVel = 0
   gameFishYTarget = 0.8
   if math.random() > 0.95 and #itemsManager.fishedItems >= 3 then
      gameFishRandom = -1
   else
      gameFishRandom = math.random() ^ 2
   end
end

---@param item string
---@param new boolean
local function updateCatchInfoModel(item, new)
   catchInfoTime = avatarTick + 2

   catchInfoModel:remove()
   catchInfoModel = catchInfoMainModel:newPart("")

   local icon = itemsManager.getItemModel(item)
   local text1 = new and "Caught new " or "Caught "
   local text2 = item.."!"
   local scale = 0.2
   local y = 0.9

   local text1Width = utils.getTextWidth(text1) * scale
   local text2Width = utils.getTextWidth(text2) * scale


   catchInfoModel:newText("a")
      :setText(text1)
      :setLight(15, 15)
      :setOutline(true)
      :setScale(scale)
      :setPos(0, y, 0)

      catchInfoModel:newPart("")
      :addChild(icon)
      :setPos(-text1Width - 2, -0.6 + y, 0)
      :scale(0.75)
      :setScale(scale)

      catchInfoModel:newText("b")
      :setText(text2)
      :setPos(-text1Width - 4.5, y, 0)
      :setLight(15, 15)
      :setOutline(true)
      :setScale(scale)

   local fullWidth = text1Width + text2Width + 4.2
   catchInfoModel:setScale(0.2)
      :setPos(fullWidth * 0.5, 12, 0)
end

local function giveFish()
   if gameFishRandom == -1 then
      local item = itemsManager.addRandomExtraItem()
      if item then
         updateCatchInfoModel(item, true)
         return
      end
      gameFishRandom = 0
   end
   local seed = gameFishRandom ^ 2
   seed = seed + math.random(0, 1)

   local waterDepth = 1
   for _ = 1, 4 do
      if not utils.isWater(world.getBlockState(bobberPos - vec(0, waterDepth, 0))) then
         break
      end
      waterDepth = waterDepth + 1
   end

   seed = seed + (world.getSkyLightLevel(bobberPos) >= 1 and 2 or 0)
   seed = seed + (world.getBiome(bobberPos).id:find("warm") and 4 or 0)
   seed = seed + (waterDepth == 5 and 8 or 0)

   seed = utils.seededRand(seed)
   local fishName = fishLib.makeFishName(seed)
   local new = itemsManager.addItem(fishName)
   updateCatchInfoModel(fishName, new)
end

function mode.render(delta, block, item, entity, ctx)
   gameModel:setVisible(false)
   tutorialModel:setVisible(false)
   catchInfoMainModel:setVisible(false)
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
   if not utils.isHoldingItemContext[ctx] then
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
               sounds:playSound("minecraft:entity.fishing_bobber.retrieve", viewer:getPos(), 1, 0.8 + math.random() * 0.4)
            end
         end
      else
         if tutorialText == 1 then tutorialText = 2 end
         bobberVisibleFrame = avatarFrame + 10
         bobberPos = viewer:getPos():add(0, viewer:getEyeHeight())
         bobberOldPos = bobberPos
         bobberVel = viewer:getLookDir() * 0.7 + vec(0, 0.2, 0)
         bobberPos = bobberPos + bobberVel
         fishingTimer = 0
         fishingGame = false
         sounds:playSound("minecraft:entity.fishing_bobber.throw", viewer:getPos(), 0.5, 0.33 + math.random() * 0.2)
      end
      bobberModel:setVisible(true)
   end
   local fishingGameAnim = math.lerp(fishingGameAnimOld, fishingGameAnimNew, delta)
   if fishingGameAnim > 0.01 then
      local cursorY = math.lerp(gameCursorYOld, gameCursorY, delta)
      gameModel.game.cursor:setPos(0, cursorY * (1 - gameCursorSize) * 62, 0)
      local s = gameCursorSize * 62 - 2
      gameModel.game.cursor.middle:setScale(1, s, 1)
      gameModel.game.cursor.top:setPos(0, s - 1, 0)
      gameModel.game.fish:setPos(0, math.lerp(gameFishYOld, gameFishY, delta) * 56, 0)
      local progress = math.lerp(gameProgressOld, gameProgress, delta)
      gameModel.game.progress:setScale(1, progress, 1)
         :setColor(vectors.hsvToRGB(progress * 0.3, 0.75, 1))

      local mat, isFirstPerson = customItemHelper.getCustomGuiMatrix(ctx)
      if isFirstPerson then
         mat = mat * matrices.scale4(fishingGameScale, fishingGameScale, 1)
      end
      gameModel.game:setScale(1 - (1 - fishingGameAnim) ^ 3, 1, 1)
      gameModel:setVisible(true)
         :setMatrix(mat)
   end
   do
      local mat, firstPerson = customItemHelper.getCustomGuiMatrix(ctx)
      if firstPerson then
         mat:translate(0, 0, 32)
      else
         mat:translate(0, 0, -8)
      end
      tutorialModel:setVisible(true)
      tutorialModel:setMatrix(mat)
      tutorialTextTask:setText(tutorialTexts[tutorialText]())
   end
   local catchInfoAnim = (avatarTick + delta - catchInfoTime) / 60
   if catchInfoAnim < 1 then
      catchInfoAnim = math.max(catchInfoAnim, 0)
      local s = (1 - math.abs(1 - 2 * catchInfoAnim)) * 5
      s = math.clamp(s, 0, 1)
      s = 1 - (1 - s) ^ 3
      local mat, firstPerson = customItemHelper.getCustomGuiMatrix(ctx)
      if firstPerson then
         mat:translate(0, 0, 32)
      else
         mat:translate(0, 0, -8)
      end
      catchInfoMainModel:setVisible(true)
         :setMatrix(mat)
      catchInfoModel:scale(1, s, 1)
   end
   if bobberVisibleFrame <= avatarFrame then
      return
   end
   bobberVisibleFrame = avatarFrame + 10
   local bobberPos2 = math.lerp(bobberOldPos, bobberPos, delta) * 16
   bobberModel:setPos(bobberPos2)
   bobberModel.bobber_uv:setUVPixels(0, 0)
   if worldRenderedUsingItemFrame > avatarFrame then
      local pos = bobberPos2 / 16 + vec(0, 0.25, 0)
      local endPos = pos - vec(0, 0.5, 0)
      local block, hitPos = raycast:block(pos, endPos, "COLLIDER", "WATER")
      hitPos = hitPos or endPos
      local dist = (pos - hitPos):length() * 16
      dist = math.clamp(8 - dist, 0, 8)
      local isWater = block and utils.isWater(block)
      bobberModel.bobber_uv:setUVPixels(isWater and 8 or 0, dist)
   end
   local isLeft = utils.contextToLeftHanded[ctx]
   local pos
   if utils.isFirstPersonContext[ctx] then
      local mat = utils.skullCenterToWorldMat(delta)
      local mat2 = mat:inverted()

      local offset = vec(-1.5, 14.5, 5)
      if isLeft then
         offset.x = -offset.x
      end
      pos = mat2:apply(-utils.firstPersonCenterItemOffsets[ctx] + offset)
   elseif utils.isThirdPersonContext[ctx] then
      pos = viewer:getPos(delta) * 16
      local offset = vec(-5, 14, 15)
      if isLeft then
         offset.x = -offset.x
      end
      offset = vectors.rotateAroundAxis(-viewer:getBodyYaw(delta), offset, vec(0, 1, 0))
      pos = pos + offset
   end
   if pos then
      pos = pos - bobberPos2

      local yaw = 90 - math.deg(math.atan2(pos.z, pos.x))
      local pitch = math.deg(math.atan2(pos.xz:length(), pos.y))

      stringModel:setVisible(true)
         :setRot(pitch, yaw, 0)
         :setScale(1, pos:length(), 1)
   else
      stringModel:setVisible(false)
   end
end

---@return boolean
local function isCursorToucingFish()
   local cursorMin = gameCursorY * (1 - gameCursorSize)
   local cursorMax = cursorMin + gameCursorSize
   return cursorMin < gameFishY + 0.04 and cursorMax > gameFishY - 0.04
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
   local bobberVisible = bobberVisibleFrame >= avatarFrame
   fishingGameAnimOld = fishingGameAnimNew
   fishingGameAnimNew = fishingGameAnimNew + (bobberVisible and fishingGame and 1 or -1) * 0.1
   fishingGameAnimNew = math.clamp(fishingGameAnimNew, 0, 1)
   gameCursorYOld = gameCursorY
   gameFishYOld = gameFishY
   gameProgressOld = gameProgress
   if not bobberVisible then
      return
   end
   --[[-- debug
   if not fishingGame then
      startFishingGame()
      gameProgress = 2
   end
   --]]
   bobberOldPos = bobberPos
   local viewer = client.getViewer()
   if (viewer:getPos() - bobberPos):length() > (fishingGame and 32 or 24) then
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
      fishingTimer = math.floor(fishingTimer * 0.5)
   end
   if fishingTimer > 5 and fishingTimer % 10 == 0 and math.random() > 0.8 then
      sounds:playSound("minecraft:entity.generic.splash", bobberPos, 0.1, 0.4)
   end
   if not fishingGame then
      if bobberInWater and fishingTimer > 120 and math.random() > (0.99 - (fishingTimer - 120) * 0.005) then
         bobberVel = bobberVel - vec(0, 0.15, 0)
         fishCatchTick = avatarTick + 20
         fishingTimer = 60
         sounds:playSound("minecraft:entity.fishing_bobber.splash", bobberPos, 0.5, math.random() * 0.8 + 0.6)
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
      if gameEndDelay >= 10 then
         bobberVisibleFrame = -10
         bobberVisibleFrame = -10
         sounds:playSound("minecraft:entity.fishing_bobber.retrieve", viewer:getPos(), 1, 0.8 + math.random() * 0.4)
         if gameProgress > 0.5 then
            giveFish()
            sounds:playSound("minecraft:entity.arrow.hit_player", viewer:getPos(), 1, 1)
            if tutorialText == 2 then
               tutorialText = 3
            end
         else
            sounds:playSound("minecraft:entity.fish.swim", viewer:getPos(), 0.8 + math.random() * 0.2, 0.6 + math.random() * 0.8)
         end
      end
      return
   end
   --
   if avatarTick % 10 == 0 then
      sounds:playSound("minecraft:entity.fishing_bobber.retrieve", bobberPos, 0.1, 0.1 + math.random() * 0.2)
   end
   -- fish
   if math.random() > (isCursorToucingFish() and 0.62 or 0.9) then
      local offset = (math.random() - 0.5) * 2
      offset = math.sign(offset) * offset ^ 2
      if math.random() > 0.9 then
         offset = offset * 0.5
      else
         offset = offset * 0.1
      end
      gameFishYTarget = gameFishYTarget + offset
   end
   gameFishYTarget = gameFishYTarget + (math.random() - 0.5) * 0.025
   gameFishYTarget = gameFishYTarget % 2
   if gameFishYTarget > 1 then
      gameFishYTarget = 2 - gameFishYTarget
   end
   gameFishYVel = math.lerp(gameFishYVel, gameFishYTarget - gameFishY, 0.1)
   gameFishY = gameFishY + gameFishYVel * 0.5
   gameFishY = math.clamp(gameFishY, 0, 1)
   -- cursor
   local isClicking = viewer:isSneaking() or viewer:isSwingingArm() and viewer:getSwingTime() <= 4
   gameCursorVel = gameCursorVel * 0.88 + (isClicking and 1 or -1) * 0.01
   gameCursorY = gameCursorY + gameCursorVel
   for _ = 1, 2 do
      gameCursorY = 1 - gameCursorY
      gameCursorVel = -gameCursorVel
      if gameCursorY < 0 then
         gameCursorVel = isClicking and 0 or math.abs(gameCursorVel)
         gameCursorY = 0
      end
   end
   -- cursor check
   if isCursorToucingFish() then
      gameProgressVel = math.lerp(gameProgressVel, 1, 0.6)
   else
      gameProgressVel = math.lerp(gameProgressVel, -0.8, 0.3)
   end
   -- progress
   gameProgress = gameProgress + gameProgressVel * 0.006
   gameProgress = math.clamp(gameProgress, 0, 1)
   if gameProgress == 1 or gameProgress == 0 then
      gameEndDelay = 1
   end
end

return mode