local utils = require("code.utils")
local mod = {}

local itemMatrices = {
   GUI = nil,
   GROUND = matrices.mat4():translate(0, 8, 0),
   HEAD = matrices.mat4():scale(0.45):translate(0, 10.5, 3.681),
}
itemMatrices.ITEM_ENTITY = itemMatrices.GROUND
local heldItemMatrices = {
   { -- normal
      FIRST_PERSON_LEFT_HAND  = matrices.mat4():rotateZ(25):rotateY(90):translate(3, 14.2, 0):scale(0.75),
      FIRST_PERSON_RIGHT_HAND = matrices.mat4():rotateZ(25):rotateY(90):translate(-2.9, 14.65, -1):scale(0.75),
      THIRD_PERSON_LEFT_HAND  = matrices.mat4():translate(0, 5.1, -7):rotateX(45):rotateY(45):scale(1.1),
      THIRD_PERSON_RIGHT_HAND = matrices.mat4():translate(0, 5.1, -7):rotateX(45):rotateY(-45):scale(1.1),
   },
   { -- tool
      FIRST_PERSON_LEFT_HAND  = matrices.mat4():rotateZ(-25):rotateY(90):translate(1, 12.5, 0):scale(0.73),
      FIRST_PERSON_RIGHT_HAND = matrices.mat4():rotateZ(-25):rotateY(90):translate(-1, 12.5, 0):scale(0.73),
      THIRD_PERSON_LEFT_HAND  = matrices.mat4():translate(0, 7.6, 0):rotateZ(-10):rotateY(135):scale(1.7),
      THIRD_PERSON_RIGHT_HAND = matrices.mat4():translate(0, 7.7, 0):rotateZ(-10):rotateY(45):scale(1.7),
   }
}

local entityMatrices = {
   ["minecraft:item_frame"] = matrices.mat4():translate(0, 4, 0)
}
mod.itemMatrices = itemMatrices
mod.heldItemMatrices = heldItemMatrices

local guiMatrix = matrices.mat4()
guiMatrix:rotate(38, -45, 0)
   :translate(0, 4, 0)

local hudThirdPersonMainMat = matrices.mat4()
   hudThirdPersonMainMat = hudThirdPersonMainMat * matrices.rotation4(-45, 0, 0)
   hudThirdPersonMainMat:scale(0.25)

local hudThirdPersonMat = {
   THIRD_PERSON_LEFT_HAND  = hudThirdPersonMainMat:copy():translate(vec(-10, 10, -18)),
   THIRD_PERSON_RIGHT_HAND = hudThirdPersonMainMat:copy():translate(vec(10, 10, -18)),
}

---@param texture Texture
---@param uv Vector2
---@param size Vector2
function mod.makeIcon(texture, uv, size)
   local model = models:newPart(""):remove()
   model:newSprite("")
      :setTexture(texture, texture:getDimensions():unpack())
      :setUVPixels(uv)
      :setRegion(size)
      :setSize(16, 16)
      :setRenderType("CUTOUT_EMISSIVE_SOLID")
      :setPos(8, 8)

   return model
end

---@param entity Entity
---@param ctx Event.SkullRender.context
---@param itemType number
---@return Matrix4, number
function mod.getMatrix(entity, ctx, itemType)
   if itemMatrices[ctx] then
      return itemMatrices[ctx], 3
   end
   local mat = heldItemMatrices[itemType][ctx]
   if mat then
      return mat, 3
   end
   if entity then
      local entityType = entity:getType()
      if entityMatrices[entityType] then
         return entityMatrices[entityType], 3
      end
   end
   return guiMatrix, 2
end

---@param ctx Event.SkullRender.context
---@return Matrix4, boolean
function mod.getCustomGuiMatrix(ctx)
   if utils.firstPersonCenterItemOffsets[ctx] then
      return matrices.translate4(utils.firstPersonCenterItemOffsets[ctx]), true
   end
   local mat = mod.heldItemMatrices[1][ctx] or matrices.mat4()
   mat = mat * (hudThirdPersonMat[ctx] or matrices.mat4())
   return mat, false
end

return mod