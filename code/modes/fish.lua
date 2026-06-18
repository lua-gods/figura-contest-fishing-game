local skullModes = require("code.skull_modes")
local fishLib = require("code.fish")
local customItemHelper = require("code.custom_item_helper")

local mode = skullModes.newMode()

local mainModel = models:newPart("", "Skull")
mode:setModel(mainModel)

local lastFishModel = mainModel:newPart("")

function mode.render(delta, block, item, entity, ctx)
   if not item then return end
   local itemName = item:getName():lower():gsub("^%s+", ""):gsub("%s+$", "")

   lastFishModel:remove()
   local fishModels = fishLib.getFishModel(itemName)

   local mat, modelType = customItemHelper.getMatrix(entity, ctx, 1)
   local model = fishModels[modelType]

   mainModel:addChild(model)
   lastFishModel = model

   mainModel:setMatrix(mat)
end

return mode