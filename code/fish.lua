local utils = require("code.utils")
local cache = require("code.cache")

local fishSprite = models.fish.fish_layer
local fishSpriteFlip = models.fish.fish_layer_flipped
local fishSpriteOutline = models.fish.fish_layer_outline
fishSprite:remove()
fishSpriteFlip:remove()
fishSpriteOutline:remove()

local mod = {}

local uvFlipMat = matrices.mat3()
uvFlipMat:scale(-1, 1, 1)
   :translate(1, 0)

local syllablesData = {
   {text = "ba", hasVowel = true },
   {text = "le", hasVowel = true },
   {text = "vi", hasVowel = true },
   {text = "ng", hasVowel = false},
   {text = "sh", hasVowel = false},
   {text = "pa", hasVowel = true },
}
local syllablesLookup = {}
for i, v in ipairs(syllablesData) do
   syllablesLookup[v.text] = v
end

local letterColors = {
   b = 0.52,
   v = 0.8,
   l = 0.25,
   sh = 0.1
}

local namePrefixes = {
   {value = "", weight = 35},
   {value = "golden ", weight = 1},
}

local default0Mt = {
   __index = function() return 0 end
}

local extraFish = {
   [3] = {
      {value = "", weight = 200},
      {value = "labubu", weight = 1}
   }
}

---@param seed number?
---@return string
function mod.makeFishName(seed)
   seed = seed or math.random()
   local name = ""
   local usedSyllables = setmetatable({}, default0Mt)
   local maxSyllables = #syllablesData
   local hadVowel = false
   name = name..utils.weightedRandom(namePrefixes, utils.seededRand(seed + 1))
   local syllablesCount = utils.seededRandInt(seed + 2, utils.seededRandInt(seed + 3, 4) + 2) + 1
   if extraFish[syllablesCount] then
      local customName = utils.weightedRandom(extraFish[syllablesCount], utils.seededRand(seed + 5))
      if customName ~= "" then
         return name..customName.." fish"
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
   return name.." fish"
end

---@param seed number
---@param hue number
---@param hueStrength number
---@param name string
---@return Vector3[]
local function generateColors(seed, hue, hueStrength, name)
   local colors = {}
   local customHue = 0
   local hueSum = 0.0001
   for i, v in pairs(letterColors) do
      local _, c = name:gsub(i, i)
      customHue = customHue + v * c
      hueSum = hueSum + c
   end
   customHue = math.lerp(
      customHue / hueSum,
      utils.seededRand(seed),
      utils.seededRand(seed + 3)
   )
   hueStrength = 0
   hue = math.lerp(
      customHue,
      hue,
      hueStrength
   )
   local k = (utils.seededRand(seed + 1) - 0.5) * 0.2 * (1 - hueStrength)
   if utils.seededRand(seed + 2) > 0.7 then
      k = k + 0.333
   end
   k = 0
   for i = 1, 3 do
      colors[i] = vectors.hsvToRGB(
         hue + (i - 1) * k,
         utils.seededRand(seed + 6 + i * 20) ^ 2 * 0.7,
         utils.seededRand(seed + 7 + i * 20) * 0.7 + 0.3
      )
   end
   return colors
end

---@param rawFishName string
---@return ModelPart[]
function mod.generateFishModel(rawFishName)
   local fishName = rawFishName
   local hue = 0
   local hueStrength = 0

   if fishName:sub(1, 7) == "golden " then
      fishName = fishName:sub(8, -1)
      hue = 0.12
      hueStrength = 0.95
   end

   local model = models:newPart(""):remove()
   local modelFlip = models:newPart(""):remove()
   local modelOutline = models:newPart(""):remove()
   local seed = utils.hashString(fishName)

   local layerCount = utils.seededRandInt(seed + 1, 3)
   local fishStyle = utils.seededRandInt(seed + 3, 3) - 1

   local colors = generateColors(-seed, hue, hueStrength, fishName)

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
   end

   local mainOutline = fishSpriteOutline:copy("")
   modelOutline:addChild(mainOutline)
   mainOutline:setPos(0, 0, 0.005)
      :setUVPixels(0, fishStyle * 18)

   local hudModel = model:copy("")
   hudModel:setPrimaryRenderType("CUTOUT_EMISSIVE_SOLID")

   local model3d = models:newPart(""):remove()
   model3d:addChild(model)
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
   return cache.get(name, newFishModelTempData)
end

--[=[ -- debug
local fishName = mod.makeFishName()
-- fishName = "papa fish"
-- fishName = "papa fish"

models:newPart("", "Hud")
   :setLight(15, 15)
   :setScale(4, 4)
   :setPos(vec(-10, -10, 0) * 4)
   :addChild(mod.generateFishModel(fishName)[4])--:setPos(-16, -16))
   :newText("a")
   :setText(fishName)
   :setPos(7, -10)
   -- :setPos(-0.5, -16.5, 0)
   :setScale(1 / 2)
   :setOutline(true)
--]=]

return mod