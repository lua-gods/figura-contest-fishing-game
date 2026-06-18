local mod = {}

local emptyModelPart = models:newPart("")
emptyModelPart:setVisible(false):remove()
---@overload fun(init: boolean)
local tickPlaceholder = function() end
---@overload fun(delta: number, block: BlockState, item: ItemStack, entity: Entity, ctx: Event.SkullRender.context)
local renderPlaceholder = function() end

local lastModel = emptyModelPart

---@class auria.fish.skullMode
local skullMode = {}
skullMode.__index = skullMode

---@return auria.fish.skullMode
function mod.newMode()
   ---@class auria.fish.skullMode
   local obj = {
      model = emptyModelPart,
      tick = tickPlaceholder,
      render = renderPlaceholder,
      lastTick = -20,
   }
   setmetatable(obj, skullMode)
   return obj
end

---@param model ModelPart
function skullMode:setModel(model)
   self.model = model
   model:setVisible(false)
end

---@param delta number
---@param block BlockState
---@param item ItemStack
---@param entity Entity
---@param ctx Event.SkullRender.context
function skullMode:setMode(delta, block, item, entity, ctx)
   lastModel:setVisible(false)
   lastModel = self.model
   lastModel:setVisible(true)
   if avatarTick ~= self.lastTick then
      self.tick(avatarTick > self.lastTick + 10)
      self.lastTick = avatarTick
   end
   self.render(delta, block, item, entity, ctx)
end

return mod