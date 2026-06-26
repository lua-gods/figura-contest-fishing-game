local fishingRodMode = require("code.modes.fishing_rod")
local bookMode = require("code.modes.book")
local fishMode = require("code.modes.fish")
local aquariumMode = require("code.modes.aquarium")

local fishLib = require("code.fish")

local canGlobalSkullRender = false
function events.world_render()
   canGlobalSkullRender = true
end

events.SKULL_RENDER:register(function(delta, block, item, entity, ctx)
   if canGlobalSkullRender then
      canGlobalSkullRender = false
      for _, v in ipairs(globalSkullRender) do
         v(delta)
      end
   end
   if block or not item then
      return aquariumMode:setMode(delta, block, item, entity, ctx)
   end
   local itemName = item:getName()
   local itemNameLower = itemName:lower()
   if fishLib.isFish(itemNameLower) then
      return fishMode:setMode(delta, block, item, entity, ctx)
   end
   if itemNameLower:find("book") then
      return bookMode:setMode(delta, block, item, entity, ctx)
   end
   return fishingRodMode:setMode(delta, block, item, entity, ctx)
end)