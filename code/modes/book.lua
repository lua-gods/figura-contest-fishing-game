local skullModes = require("code.skull_modes")
local utils = require("code.utils")
local customItemHelper = require("code.custom_item_helper")
local fishLib = require("code.fish")
local keybindHelper = require("code.keybind_helper")

local mode = skullModes.newMode()

local modeModel = models.book.Skull
mode:setModel(modeModel)
modeModel:setPrimaryRenderType("CUTOUT_CULL")

local bookGuiMatFirst = matrices.mat4()
bookGuiMatFirst:rotate(-90, 0, 0)
   :translate(0, 0, 20)

local bookGuiMatThird = bookGuiMatFirst:copy()
bookGuiMatThird:scale(2)
   :translate(0, 0, -40)

modeModel.book.pagesOpen.pages:setMatrix(matrices.mat4():rotateZ(90):rotateY(90))

local infoTextTask = modeModel.book:newText("info")
infoTextTask:setAlignment("CENTER")
   :setScale(0.1)

local newCurrentPage = 0
local oldCurrentPage = 0
local targetPage = 0
local loadedPages = {}

---@param n number
---@return ModelPart
local function getPage(n)
   if loadedPages[n] then return loadedPages[n] end
   local pageModel = modeModel.book.pagesOpen.pages:newPart("")
   loadedPages[n] = pageModel

   pageModel:setPos(2, 4, 3)
   local model = pageModel:newPart("")
   model:setScale(0.125)

   local isRightPage = n % 2 == 0
   model:setPos(isRightPage and 0 or 7, 0, -0.01)

   local fishName = fishLib.makeFishName()

   model:newText("")
      :setText(toJson{color = "black", text = fishName})
      :setPos(-20, -2, 0)
      :setWrap(true)
      :setWidth(46)
      :setScale(0.75)

   local fishModel = fishLib.generateFishModel(fishName)[2]:copy("")
   fishModel:setPos(-10, -10, 0)
   model:addChild(fishModel)

   return pageModel
end

function mode.render(delta, block, item, entity, ctx)
   modeModel.book:setRot(0, 0, 0)
      :setPos(-1, 0, 0)
   modeModel.book.left:setRot(0, 0, 0)
   modeModel.book.right:setRot(0, 0, 0)
   modeModel.book.pagesClosed:setVisible(true)
   modeModel.book.pagesOpen:setVisible(false)
   infoTextTask:setVisible(false)
   if block then
      modeModel:setPos(1, 0, 0)
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

   modeModel:setPos(pos)
      :setRot(rot)

   if type(entity) ~= "PlayerAPI" then
      return
   end
   local viewer = client.getViewer()
   local leftHanded = entity:isLeftHanded()
   local bookClosed = leftHanded == isLeft
   if viewer:getUUID() == entity:getUUID() then
      infoTextTask:setVisible(true)
      infoTextTask:setText(toJson{
         "Press ",
         {text = keybindHelper.getVanillaKey("key.swapOffhand"), color = "aqua"},
         " to ",
         bookClosed and "open" or "close"
      })
      if bookClosed then
         infoTextTask:rot(90, 0, 0):pos(0, 1, 7)
      else
         infoTextTask:rot(90, 0, 90):pos(0, 0.7, -5)
      end
   end
   if bookClosed then
      return
   end
   local mat, firstPerson = customItemHelper.getCustomGuiMatrix(ctx)
   mat = mat * (firstPerson and bookGuiMatFirst or bookGuiMatThird)
   modeModel:setMatrix(mat)

   local currentPage = math.lerp(oldCurrentPage, newCurrentPage, delta)
   if viewerClicked then
      targetPage = targetPage + (viewer:isSneaking() and -1 or 1)
   end

   modeModel.book:setRot(0, 0, -90)
      :setPos(-1, 0, 0)
   modeModel.book.left:setRot(0, 0, -80)
   modeModel.book.right:setRot(0, 0, 80)
   modeModel.book.pagesClosed:setVisible(false)
   modeModel.book.pagesOpen:setVisible(true)

   local pageTurn = currentPage % 1
   local x = pageTurn
   x = x < 0.5 and 4 * x ^ 3 or 1 - (-2 * x + 2) ^ 3 / 2
   local pageAngle = (x - 0.5) * -80 * 2
   modeModel.book.pagesOpen.pageTurn:setRot(0, 0, pageAngle)

   local pagesN = math.floor(currentPage) * 2 + 1
   getPage(pagesN):setRot(0, 10, 0):setVisible(pageTurn < 0.8)
   getPage(pagesN + 1):setRot(0, -90 + pageAngle, 0):setVisible(pageTurn < 0.8)
   getPage(pagesN + 2):setRot(0, 90 + pageAngle, 0):setVisible(pageTurn > 0.2)
   getPage(pagesN + 3):setRot(0, -10, 0):setVisible(pageTurn > 0.2)
   for i, v in pairs(loadedPages) do
      if i < pagesN or i > pagesN + 3 then
         v:remove()
         loadedPages[i] = nil
      end
   end
end

function mode.tick(init)
   oldCurrentPage = newCurrentPage
   newCurrentPage = math.lerp(newCurrentPage, targetPage, 0.15)
end

return mode