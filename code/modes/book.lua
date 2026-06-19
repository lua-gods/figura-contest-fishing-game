local skullModes = require("code.skull_modes")
local utils = require("code.utils")
local custom_item_helper = require("code.custom_item_helper")
local mode = skullModes.newMode()

local model = models.book.Skull
mode:setModel(model)
model:setPrimaryRenderType("CUTOUT_CULL")

local bookGuiMatFirst = matrices.mat4()
bookGuiMatFirst:rotate(-90, 0, 0)
   :translate(0, 0, 20)

local bookGuiMatThird = bookGuiMatFirst:copy()
bookGuiMatThird:scale(2)
   :translate(0, 0, -40)

local newCurrentPage = 0
local oldCurrentPage = 0
local targetPage = 0
local loadedPages = {}

function mode.render(delta, block, item, entity, ctx)
   model.book:setRot(0, 0, 0)
   model.book.left:setRot(0, 0, 0)
   model.book.right:setRot(0, 0, 0)
   model.book.pagesClosed:setVisible(true)
   model.book.pages:setVisible(false)
   if block then
      model:setPos(0, 0, 0)
         :setRot(0, 0, 0)
      return
   end
   local pos = vec(0, 0, 0)
   local rot = vec(0, 0, 0)
   local isLeft = utils.contextToLeftHanded[ctx]
   if utils.isFirstPersonContext[ctx] then
      pos = vec(isLeft and -2 or 2, 10, 0)
      rot = vec(-60, isLeft and 15 or -15, 0)
   elseif utils.isThirdPersonContext[ctx] then
      if isLeft then
         pos, rot = vec(-2, 6, 0), vec(-20, 45, 0)
      else
         pos, rot = vec(2, 6, 0), vec(-20, -45, 0)
      end
   end

   model:setPos(pos)
      :setRot(rot)

   if type(entity) ~= "PlayerAPI" then
      return
   end
   local leftHanded = entity:isLeftHanded()
   if leftHanded == isLeft then
      return
   end
   local mat, firstPerson = custom_item_helper.getCustomGuiMatrix(ctx)
   mat = mat * (firstPerson and bookGuiMatFirst or bookGuiMatThird)
   model:setMatrix(mat)

   -- currentPage = client.getCameraRot().x * 0.1
   -- host:setActionbar(currentPage)
   local currentPage = math.lerp(oldCurrentPage, newCurrentPage, delta)
   if viewerClicked then
      targetPage = targetPage + 1
   end

   model.book:setRot(0, 0, -90)
   model.book.left:setRot(0, 0, -80)
   model.book.right:setRot(0, 0, 80)
   model.book.pagesClosed:setVisible(false)
   model.book.pages:setVisible(true)

   local x = currentPage % 1
   x = x < 0.5 and 4 * x ^ 3 or 1 - (-2 * x + 2) ^ 3 / 2
   model.book.pages.pageTurn:setRot(0, 0, (x - 0.5) * -80 * 2)
end

function mode.tick(init)
   oldCurrentPage = newCurrentPage
   newCurrentPage = math.lerp(newCurrentPage, targetPage, 0.2)
end

return mode