local fishingRodMode = require("code.modes.fishing_rod")
local bookMode = require("code.modes.book")
local fishMode = require("code.modes.fish")

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
      return bookMode:setMode(delta, block, item, entity, ctx)
   end
   local itemName = item:getName()
   local itemNameLower = itemName:lower()
   if itemNameLower:find("%a%sfish") then
      return fishMode:setMode(delta, block, item, entity, ctx)
   end
   return fishingRodMode:setMode(delta, block, item, entity, ctx)
end)