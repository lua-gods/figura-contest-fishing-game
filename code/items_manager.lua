local fishLib = require("code.fish")
local customItemHelper = require("code.custom_item_helper")

local mod = {}

local extraItems = {
   ["sea grass"] = "minecraft:seagrass",
   ["stick"] = "minecraft:stick",
   ["bowl"] = "minecraft:bowl",
   ["string"] = "minecraft:string",
   ["fishing rod"] = "",
}

local fallbackIcon = models.fish.fallback_icon
fallbackIcon:remove()

local fishedItems = {"fishing rod"}
local fishedItemsMap = {}
mod.fishedItems = fishedItems

local extraModels = {}
local availableExtraItems = {}

extraModels["fishing rod"] = models.rod.fishing_rod_icon:remove()

for _, v in pairs(fishedItems) do
   fishedItemsMap[v] = true
end

for name, item in pairs(extraItems) do
   if not fishedItemsMap[name] then
      table.insert(availableExtraItems, name)
   end
   if not extraModels[name] then
      local model = models:newPart(""):remove()
      extraModels[name] = model
      model:newItem("")
         :setItem(item)
         :setScale(1, 1, 0.001)
   end
end

---@param str string
---@return boolean
function mod.addItem(str)
   if not fishedItemsMap[str] then
      fishedItemsMap[str] = true
      table.insert(fishedItems, str)
      return true
   end
   return false
end

---@return string?
function mod.addRandomExtraItem()
   if #availableExtraItems == 0 then
      return
   end
   local i = math.random(#availableExtraItems)
   local n = availableExtraItems[i]
   table.remove(availableExtraItems, i)
   mod.addItem(n)
   return n
end

---@param n number
---@return string?
function mod.getItem(n)
   return fishedItems[n]
end

---@param n number|string
---@return ModelPart
function mod.getItemModel(n)
   local str = type(n) == "string" and n or fishedItems[n]
   if not str then
      return fallbackIcon
   end
   if extraModels[str] then
      return extraModels[str]
   end
   return fishLib.getFishModel(str)[4]
end

return mod