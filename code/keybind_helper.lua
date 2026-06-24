local mod = {}

---@type {[Minecraft.keybind|string]: string}
local nameFallback = {
   ["key.mouse.left"] = "Left Mouse Button",
   ["key.mouse.right"] = "Right Mouse Button",
   ["key.keyboard.left.shift"] = "SHIFT",
   ["key.keyboard.right.shift"] = "RSHIFT",
   ["key.keyboard.left.control"] = "CTRL",
   ["key.keyboard.right.control"] = "RCTRL",
   ["key.keyboard.left.alt"] = "ALT",
   ["key.keyboard.right.alt"] = "ALT",
   ["key.keyboard.backspace"] = "BACKSPACE",
   ["key.keyboard.backslash"] = "\\",
   ["key.keyboard.slash"] = "/",
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