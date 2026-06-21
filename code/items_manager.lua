local fishLib = require("code.fish")
local customItemHelper = require("code.custom_item_helper")

local mod = {}

local extraItems = {
   ["sea grass"] = "minecraft:seagrass",
   ["stick"] = "minecraft:stick",
   ["bowl"] = "minecraft:bowl",
   ["string"] = "minecraft:string",
}

local fallbackIcon = models.fish.fallback_icon
fallbackIcon:remove()

local fishedItems = {}
local fishedItemsMap = {}
mod.fishedItems = fishedItems

local extraModels = {}
local availableExtraItems = {}
for name, item in pairs(extraItems) do
   table.insert(availableExtraItems, name)
   local model = models:newPart(""):remove()
   extraModels[name] = model
   model:newItem("")
      :setItem(item)
      :setScale(1, 1, 0.001)
end

---@param str string
function mod.addItem(str)
   if not fishedItemsMap[str] then
      fishedItemsMap[str] = true
      table.insert(fishedItems, str)
   end
end

---@return boolean
function mod.addRandomExtraItem()
   if #availableExtraItems == 0 then
      return false
   end
   local i = math.random(#availableExtraItems)
   local n = availableExtraItems[i]
   table.remove(availableExtraItems, i)
   mod.addItem(n)
   return true
end

---@param n number
---@return string?
function mod.getItem(n)
   return fishedItems[n]
end

---@param n number
---@return ModelPart
function mod.getItemModel(n)
   local str = fishedItems[n]
   if not str then
      return fallbackIcon
   end
   if extraModels[str] then
      return extraModels[str]
   end
   return fishLib.getFishModel(str)[4]
end

return mod