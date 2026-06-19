local skullModes = require("code.skull_modes")
local mode = skullModes.newMode()

local model = models.book.Skull
mode:setModel(model)
model:setPrimaryRenderType("CUTOUT_CULL")

function mode.render(delta, block, item, entity, ctx)
   
end

return mode