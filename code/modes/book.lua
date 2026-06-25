local skullModes = require("code.skull_modes")
local utils = require("code.utils")
local customItemHelper = require("code.custom_item_helper")
local fishLib = require("code.fish")
local keybindHelper = require("code.keybind_helper")
local itemsManager = require("code.items_manager")

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
   :setOutline(true)
   :setLight(15, 15)

local targetPage = 0
local newCurrentPage = targetPage
local oldCurrentPage = targetPage
local loadedPages = {}
local wasBookClosed = true
local bookOpenFrame = -10

local pageSound = math.round(targetPage)

local itemsCount = -1

local lastPageFrame = -1
local emptyModel = models:newPart(""):remove()

---@param n number
---@return ModelPart
local function getPage(n)
   if loadedPages[n] then
      return loadedPages[n]
   end
   if lastPageFrame == avatarFrame then
      return emptyModel
   end
   lastPageFrame = avatarFrame
   local pageModel = modeModel.book.pagesOpen.pages:newPart("")

   pageModel:setPos(2, 4, 3)
   local model = pageModel:newPart("")
   model:setScale(0.125)

   local isRightPage = n % 2 == 0
   model:setPos(isRightPage and 0 or 7, 0, -0.01)

   local fishName = itemsManager.getItem(n) or "???"

   model:newText("")
      :setText(toJson{color = "black", text = fishName})
      :setPos(-28, -40, 0)
      :setWrap(true)
      :setWidth(64)
      :setScale(0.75)
      :alignment("CENTER")

   local fishModel = itemsManager.getItemModel(n)
   model:newPart("")
      :setPos(-28, -20)
      :setScale(2, 2, 1)
      :addChild(fishModel)

   loadedPages[n] = pageModel
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
   elseif ctx == "HEAD" then
      pos, rot = vec(1, 6.72, 0), vec(0, 30, 0)
   end

   modeModel:setPos(pos)
      :setRot(rot)

   local viewer = client.getViewer()
   if not entity or viewer:getUUID() ~= entity:getUUID() then
      return
   end
   viewerGotBook = true
   if not utils.isHoldingItemContext[ctx] then
      return
   end
   local leftHanded = viewer:isLeftHanded()
   local bookClosed = leftHanded == isLeft
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
   if bookClosed then
      return
   end
   bookOpenFrame = avatarFrame + 2
   local mat, firstPerson = customItemHelper.getCustomGuiMatrix(ctx)
   mat = mat * (firstPerson and bookGuiMatFirst or bookGuiMatThird)
   modeModel:setMatrix(mat)

   local currentPage = math.lerp(oldCurrentPage, newCurrentPage, delta)
   if viewerClicked then
      targetPage = targetPage + (viewer:isSneaking() and -1 or 1)
      targetPage = math.max(targetPage, 0)
   end

   local newPageSound = math.round(currentPage)
   if newPageSound ~= pageSound then
      pageSound = newPageSound
      sounds:playSound("minecraft:item.book.page_turn", viewer:getPos())
   end

   modeModel.book:setRot(0, 0, -90)
      :setPos(-1, 6, 0)
   modeModel.book.left:setRot(0, 0, -80)
   modeModel.book.right:setRot(0, 0, 80)
   modeModel.book.pagesClosed:setVisible(false)
   modeModel.book.pagesOpen:setVisible(true)

   local pageTurn = currentPage % 1
   local x = pageTurn
   x = 3 * x ^ 2 - 2 * x ^ 3
   local pageAngle = (x - 0.5) * -80 * 2
   modeModel.book.pagesOpen.pageTurn:setRot(0, 0, pageAngle)

   if itemsCount ~= #itemsManager.fishedItems then
      itemsCount = #itemsManager.fishedItems
      for _, v in pairs(loadedPages) do
         v:remove()
      end
      loadedPages = {}
   end

   local pagesN = math.floor(currentPage) * 2 + 1
   getPage(pagesN)    :setRot(0, 10, 0):setVisible(pageTurn < 0.8)
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
   newCurrentPage = math.lerp(newCurrentPage, targetPage, 0.2)
end

table.insert(globalSkullRender, function()
   local isClosed = avatarFrame > bookOpenFrame
   if wasBookClosed ~= isClosed then
      wasBookClosed = isClosed
      if avatarFrame < bookOpenFrame + 10 then
         sounds:playSound("minecraft:item.book.page_turn", client.getViewer():getPos())
      end
   end
end)

return mode