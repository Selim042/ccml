local toInclude = {
  "bigfont.lua",
  "browser-script.lua",
  "browser.lua",
  "logger.lua",
  "networking.lua",
  "primeui.lua",
  "tags.lua",
  "xmlLib.lua",

  "tags/"
}
local outputFile = "browser.bundle.lua"
local version = "2025.4.0"

local function packFolder(path,dat)
  if (path:find("/") ~= #path) then
    print("Building "..path)
    local f = fs.open(path,'r')
    if (f == nil) then
      error('file not found: '..path)
    end
    dat[path] = f.readAll()
    f.close()
  else
    local l = fs.list(path)
    for k,v in ipairs(l) do
      packFolder(path..'/'..v,dat)
    end
  end
end

local files = {}
for k,v in ipairs(toInclude) do
    packFolder(v,files)
end
local output = fs.open(outputFile,'w')
output.write("local version='"..version.."';")
output.write("local files=")
output.write(textutils.serialize(files))
output.write(
  'print("Installing CCML Browser v"..version);'..
  'local p="/"..shell.dir().."/";'..
  'for k,v in pairs(files) do;'..
    'print("Extracting:"..p..k);'..
    'local f=fs.open(p..k,"w");'..
    'f.write(v);'..
    'f.close();'..
  'end;'..
  'print("Done!")'
)
output.close()
print("Build complete")
