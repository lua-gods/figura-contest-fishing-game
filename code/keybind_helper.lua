local mod = {}

local nameFallback = {
   ["key.mouse.left"] = "LMB",
   ["key.mouse.right"] = "RMB",
}

---@param str Minecraft.keybind|string
---@return string
function mod.getVanillaKey(str)
   local key = keybinds:getVanillaKey(str)
   local char = key:match("^key%.keyboard%.(%w)$")
   if char then
      return "["..char:upper().."]"
   end
   if nameFallback[key] then
      return "["..nameFallback[key].."]"
   end
   return key
end

return mod