avatarTick = 0
avatarFrame = 0

worldModel = models:newPart(""):remove()

---@type fun(delta: number)[]
globalSkullRender = {}

viewerClicked = false

events.WORLD_TICK:register(function()
   avatarTick = avatarTick + 1
end)

events.WORLD_RENDER:register(function(delta)
   avatarFrame = avatarFrame + 1
end)

local lastViewerClickTick = 0
table.insert(globalSkullRender, function(dt)
   viewerClicked = false
   local viewer = client.getViewer()
   local swingTime = viewer:getSwingTime()
   if avatarTick > lastViewerClickTick and viewer:isSwingingArm() and swingTime <= 2 then
      lastViewerClickTick = avatarTick + 3
      viewerClicked = true
   end
end)