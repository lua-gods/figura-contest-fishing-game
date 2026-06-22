local utils = require("code.utils")
local worldModelPart = models:newPart("world", "World")
local skullModel = models:newPart("world_skull", "Skull")
local skullModel2 = skullModel:newPart("")

worldModelPart:addChild(worldModel)
skullModel:setVisible(false)
skullModel2:addChild(worldModel)

local worldLastFrame = 2
local skullBlockLastFrame = 0
local offHandLastFrame = 0
local renderUsingSkull = false
local canRenderUsingSkull = false
local skullBlockPos

worldModelPart.preRender = function(delta, context, part)
   worldLastFrame = avatarFrame + 2
   renderUsingSkull = false
end

function events.world_render()
   if avatarFrame > worldLastFrame then
      renderUsingSkull = true
      skullBlockPos = nil
      renderAsSkullItem = avatarFrame > skullBlockLastFrame
      canRenderUsingSkull = true
   end
end

local facingToOffset = {
   [1] = vec(-8, 0, -8),
   north = vec(-8, -4, -12),
   east = vec(-4, -4, -8),
   south = vec(-8, -4, -4),
   west = vec(-12, -4, -8),
}

local facingToRot = {
   north = 0,
   east = 4,
   south = 8,
   west = 12,
}

local _ = models:newPart("", "WORLD") -- f3 bounding box
events.SKULL_RENDER:register(function(delta, block, item, entity, ctx)
   skullModel:visible(false)
   if renderUsingSkull then
      if block then
         skullBlockLastFrame = avatarFrame + 2
         local blockPos = block:getPos()
         if not skullBlockPos then
            skullBlockPos = blockPos
         end
         local properties = block.properties
         if skullBlockPos == blockPos and properties then
            local rot = (tonumber(properties.rotation) or facingToRot[properties.facing]) * 22.5
            skullModel:visible(true)
               :rot(0, rot, 0)
               :pos()
            skullModel2:pos(-blockPos * 16 + facingToOffset[properties.facing or 1])
         end
      elseif renderAsSkullItem and utils.firstPersonCenterItemOffsets[ctx] then
         local isOffHand = client.getViewer():isLeftHanded() ~= utils.contextToLeftHanded[ctx]
         if isOffHand then
            offHandLastFrame = avatarFrame + 2
         end
         if canRenderUsingSkull and isOffHand == (avatarFrame <= offHandLastFrame) then
            canRenderUsingSkull = false
            skullModel:setPos(utils.firstPersonCenterItemOffsets[ctx])
            :rot()
            skullModel:visible(true)
            skullModel2:setMatrix(utils.skullCenterToWorldMat(delta))
         end
      end
   end
end)