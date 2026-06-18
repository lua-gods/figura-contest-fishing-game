require("code.globals")

for _, file in pairs(listFiles("", true)) do
   if file ~= "code.init" then
      require(file)
   end
end