local skullModes = require("code.skull_modes")
local mode = skullModes.newMode()

local model = models.model.Skull
mode:setModel(model)

function mode.render(delta, block, item, entity, ctx)
   
end

return mode