if not host:isHost() then
   return
end

local entityName = avatar:getEntityName()

---@param name string
---@return ItemStack
local function newPlayerHead(name)
   local nameJson = toJson({text = name})
   local nbt = toJson{
      SkullOwner = entityName,
      display = {Name = nameJson}
   }
   return world.newItem("minecraft:player_head"..nbt)
end

local items = {
   "Fishing Rod",
   "Book",
}

local getItemHelpText = {
   "Get your player head\n",
   "(some servers might\nhave ",
   {text = "/head", color = "aqua"},
   " command)",
}

local actionNeedsRename = {
   false,
   true,
}

local page = action_wheel:newPage()
action_wheel:setPage(page)

local actions = {}

---@return boolean
local function hasGivePermission()
   if not player:isLoaded() then
      return false
   end
   if player:getGamemode() == "CREATIVE" then
      return true
   end
   return false
end

---@param item ItemStack
local function giveItem(item)
   if not hasGivePermission() then
      printJson(toJson{
         color = "red",
         text = "Unable to give items!"
      })
      return
   end

   local selectedSlot = player:getNbt().SelectedItemSlot or 0
   selectedSlot = selectedSlot % 9

   for i = 0, 8 do
      local slot = "hotbar."..i
      local slotItem = host:getSlot(slot)
      if slotItem == item then
         printJson(toJson{
            color = "red",
            text = "Item already in hotbar!"
         })
         return
      end
   end

   for i = 0, 8 do
      local k = (selectedSlot + i) % 9
      local slot = "hotbar."..k
      local slotItem = host:getSlot(slot)
      if not slotItem or slotItem.id == "minecraft:air" then
         host:setSlot(slot, item)
         return
      end
   end

   printJson(toJson{
      color = "red",
      text = "No empty slots in hotbar found!"
   })
end

for i, v in ipairs(items) do
   local action = page:newAction()
   actions[i] = action
   local item = newPlayerHead(v)
   action:setItem(item)
      :onLeftClick(function()
         giveItem(item)
   end)
end

local hadPermissions
function events.tick()
   if not action_wheel:isEnabled() then
      return
   end
   local hasPermissions = hasGivePermission()
   if hadPermissions == hasPermissions then
      return
   end
   hadPermissions = hasPermissions
   for i, action in ipairs(actions) do
      local text = {
         "",
         {text = items[i], bold = true},
         "\n\n",
         "Click to give item"
      }
      if not hasPermissions then
         text = {
            text,
            "\n",
            {color = "red", text = "Requires creative mode!"},
         }
      end
      text = {
         text,
         "\n",
         {text = "-----< or >-----", color = "gray"},
         "\n",
         getItemHelpText,
         actionNeedsRename[i] and {
            "\nand rename it to ",
            {text = items[i], color = "aqua"}
         } or ""
      }
      action:setTitle(toJson(text))
         :setHoverColor(hasPermissions and vec(1, 1, 1) or vec(0.5, 0.5, 0.5))
   end
end