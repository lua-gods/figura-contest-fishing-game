local utils = require("code.utils")
local cache = require("code.cache")

local fishSprite = models.fish.fish_layer
local fishSpriteFlip = models.fish.fish_layer_flipped
local fishSpriteOutline = models.fish.fish_layer_outline
fishSprite:remove()
fishSpriteFlip:remove()
fishSpriteOutline:remove()

local fishSprite3d = models:newPart(""):remove()
do
   fishSprite3d:setPrimaryRenderType("TRANSLUCENT_CULL")
   local layerXModel = models.fish.fish_layer3d_x
   local layerYModel = models.fish.fish_layer3d_y
   layerXModel:remove()
   layerYModel:remove()
   for i = 0, 15 do
      local layerX = layerXModel:copy("")
      local layerY = layerYModel:copy("")
      layerX:setPos(i, 0, 0):setUVPixels(-i, 0)
      layerY:setPos(0, -i, 0):setUVPixels(0, i)
      fishSprite3d:addChild(layerX)
      fishSprite3d:addChild(layerY)
   end
end

local fishTextureSize = textures["fish"]:getDimensions()

local mod = {}

local uvFlipMat = matrices.mat3()
uvFlipMat:scale(-1, 1, 1)
   :translate(1, 0)

local syllablesData = {
   {text = "ba", hasVowel = true },
   {text = "bu", hasVowel = true },
   {text = "le", hasVowel = true },
   {text = "la", hasVowel = true },
   {text = "vi", hasVowel = true },
   {text = "ng", hasVowel = false},
   {text = "sh", hasVowel = false},
   {text = "pa", hasVowel = true },
   {text = "ki", hasVowel = true },
   {text = "xu", hasVowel = false },
}

local namePrefixes = {
   {value = "", weight = 35},
   {value = "golden ", weight = 1},
}

local default0Mt = {
   __index = function() return 0 end
}

local extraFish = {}

local fishStyles = {
   {name = "fish", style = {0, 1, 2, 4, 5}},
   {name = "octopus", style = {6}},
   {name = "pufferfish", style = {3}},
   {name = "crab", style = {7}},
   {name = "starfish", style = {8}},
}

local customFishStyles = {
   papa = {
      styles = {fish = 5},
      colors = {"#c8e4bf", "#a8c4af", "#efffd0"},
      goldenColors = {"#ffdaad", "#ffc2a1", "#ffefd0"},
      layers = 3,
   },
   baba = {
      styles = {
         fish = 2,
      },
      colors = {"#ffffff", "#D9396A", "#D9396A"},
      goldenColors = {"#ffffff", "#EDE285", "#EDE285"},
      layers = 3,
   },
   labubu = {
      styles = {
         fish = 0,
      },
      colors = {"#ffcba6", "#97e9ff", "#86cbed"},
      goldenColors = {"#ffcba6", "#ffd466", "#f2a74b"},
   }
}

local fishStylesLookup = {}
local fishSuffixesWeights = {}

for i, v in pairs(fishStyles) do
   fishSuffixesWeights[i] = {value = v.name, weight = #v.style}
   fishStylesLookup[v.name] = v.style
end

---@param seed number?
---@return string
function mod.makeFishName(seed)
   seed = seed or math.random()
   local name = ""
   local usedSyllables = setmetatable({}, default0Mt)
   local maxSyllables = #syllablesData
   local hadVowel = false

   name = name..utils.weightedRandom(namePrefixes, utils.seededRand(seed + 1))
   suffix = " "..utils.weightedRandom(fishSuffixesWeights, utils.seededRand(seed + 4))

   local syllablesCount = utils.seededRandInt(seed + 2, utils.seededRandInt(seed + 3, 2) + 2) + 1
   if extraFish[syllablesCount] then
      local customName = utils.weightedRandom(extraFish[syllablesCount], utils.seededRand(seed + 5))
      if customName ~= "" then
         return name..customName..suffix
      end
   end
   for i = 1, syllablesCount do
      local rand = utils.seededRandInt(seed + 10 + i, maxSyllables)
      for k = 1, maxSyllables do
         local n = (k + rand) % maxSyllables + 1
         local v = syllablesData[n]
         if usedSyllables[n] <= 1 and (hadVowel or v.hasVowel) then
            usedSyllables[n] = usedSyllables[n] + 1
            hadVowel = v.hasVowel
            name = name..v.text
            break
         end
      end
   end
   return name..suffix
end

---@type fun(colors: Vector3[], seed: number)[]
local fishStylesColors = {
   [3] = function(colors, seed)
      local rand = utils.seededRand(seed + 9)
      colors[2] = math.lerp(colors[1], vec(1, 1, 1), rand * 0.5) --[[@as Vector3]]
   end,
   [8] = function(colors, seed)
      local rand = utils.seededRand(seed + 9)
      colors[2] = math.lerp(colors[1], vec(1, 1, 1), rand * 0.6 + 0.2) --[[@as Vector3]]
      colors[3] = colors[2]
   end
}

---@param seed number
---@param hue number
---@param hueStrength number
---@param name string
---@param style number
---@return Vector3[]
local function generateColors(seed, hue, hueStrength, name, style)
   local colors = {}
   hue = math.lerp(
      utils.seededRand(seed),
      hue,
      hueStrength
   )
   local k = (utils.seededRand(seed + 1) - 0.5) * 0.1 * (1 - hueStrength)
   if utils.seededRand(seed + 2) > 0.8 and hueStrength < 0.5 then
      k = k + 0.5
      hueStrength = 1
   end
   if utils.seededRand(seed + 4) > 0.9 then
      hueStrength = 1
   end
   for i = 1, 3 do
      local sat = utils.seededRand(seed + 6 + i * 20) ^ 2 * 0.9
      local val = utils.seededRand(seed + 7 + i * 20)
      val = 1 - (1 - val) ^ 2
      val = val * 0.5 + 0.5
      sat = math.lerp(sat, 1, hueStrength * 0.8 * (1 - val ^ 2))
      val = math.lerp(val, 1, hueStrength * 0.9)
      colors[i] = vectors.hsvToRGB(
         hue + (i - 1) * k,
         sat,
         val
      )
   end
   if fishStylesColors[style] then
      fishStylesColors[style](colors, seed)
   end
   return colors
end

---@param rawFishName string
---@return ModelPart[]
function mod.generateFishModel(rawFishName)
   local fishName, suffix = rawFishName:match('^(.-)%s+(%w+)$')
   fishName = fishName or ""
   suffix = suffix or "fish"
   local hue = 0
   local hueStrength = 0
   local isGolden = false

   if fishName:sub(1, 7) == "golden " then
      fishName = fishName:sub(8, -1)
      hue = 0.11
      hueStrength = 0.98
      isGolden = true
   end

   local model = models:newPart(""):remove()
   local modelFlip = models:newPart(""):remove()
   local modelOutline = models:newPart(""):remove()
   local seed = utils.hashString(fishName)

   local myFishStyles = fishStylesLookup[suffix] or fishStylesLookup.fish
   local layerCount = utils.seededRandInt(seed + 1, 3)
   local fishStyle = myFishStyles[utils.seededRandInt(seed + 3, #myFishStyles)]

   if fishStyle == 3 then
      layerCount = 3
   end

   local colors = generateColors(-seed, hue, hueStrength, fishName, fishStyle)

   if customFishStyles[fishName] then
      local customStyle = customFishStyles[fishName]
      fishStyle = customStyle.styles and customStyle.styles[suffix] or fishStyle
      local newColors = isGolden and customStyle.goldenColors or customStyle.colors
      if newColors then
         colors[1] = newColors[1] and vectors.hexToRGB(newColors[1]) or colors[1]
         colors[2] = newColors[2] and vectors.hexToRGB(newColors[2]) or colors[2]
         colors[3] = newColors[3] and vectors.hexToRGB(newColors[3]) or colors[3]
      end
      layerCount = customStyle.layers or layerCount
   end

   local model3d = models:newPart(""):remove()

   for i = 0, layerCount do
      local layerY = i - 1
      local k = i
      if i == 0 then
         layerY = 2 + utils.seededRandInt(seed + 5, 2)
         k = 0.5
      elseif layerCount == 2 and i == 2 then
         layerY = utils.seededRandInt(seed + 2, 2)
      end
      local color = colors[i] or colors[1]
      local pos = vec(0, 0, -k * 0.01)
      local uv = vec(fishStyle, layerY) * 16
      local sprite = fishSprite:copy("")
      model:addChild(sprite)
      sprite:setPos(pos)
         :setUVPixels(uv)
         :color(color)
      local spriteFlip = fishSpriteFlip:copy("")
      modelFlip:addChild(spriteFlip)
      spriteFlip:setPos(-pos)
         :setUVPixels(uv)
         :color(color)
      if i == 0 then
         local outline = fishSprite:copy("")
         modelOutline:addChild(outline)
         outline:setPos(0, 0, 0.006)
            :setUVPixels(uv + vec(0, 32))
      end
      if i <= 1 then
         local model3dsides = fishSprite3d:copy("")
         model3dsides:setColor(color)
         -- setUVPixels applies setUV to children when its group
         -- so setUV is needed instead
         model3dsides:setUV(uv / fishTextureSize)
         model3d:addChild(model3dsides)
      end
   end

   local mainOutline = fishSpriteOutline:copy("")
   modelOutline:addChild(mainOutline)
   mainOutline:setPos(0, 0, 0.005)
      :setUVPixels(0, fishStyle * 18)

   local hudModel = model:copy("")
   hudModel:setPrimaryRenderType("CUTOUT_EMISSIVE_SOLID")

   model3d:addChild(model:copy(""):setPos(0, 0, 0.01))
   modelFlip:setPos(0, 0, -0.01)
   model3d:addChild(modelFlip)

   modelOutline:addChild(model)

   return {model, hudModel, model3d, modelOutline}
end

---@param name string
---@return ModelPart
local function newFishModelTempData(name)
   local model = mod.generateFishModel(name)
   return model
end

---@param name string
---@return ModelPart
function mod.getFishModel(name)
   return cache.get("fish;"..name, newFishModelTempData, name)
end

---@param name string
---@return boolean
function mod.isFish(name)
   if fishStylesLookup[name:match("%a%s+(%w+)%s*$")] then
      return true
   end
   return false
end

--[=[ -- debug
for x = 0, 5 do
   for y = 0, 3 do
      local fishName = mod.makeFishName()

      models:newPart("", "Hud")
         :setLight(15, 15)
         :setScale(3, 3)
         :setPos(vec(-10, -10, 0) * 3 - vec(x * 60, y * 80, 0))
         :addChild(mod.generateFishModel(fishName)[4])--:setPos(-16, -16))
         :newText("a")
         :setText(fishName)
         :setPos(8, -10)
         :setScale(0.25)
         :wrap(true)
         :width(64)
         :setOutline(true)
   end
end
--]=]

return mod