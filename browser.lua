local file = ({...})[1]
local path = shell.dir()

local primeui = require('primeui')
local xmlLib = require('xmlLib')
local bigfont = require('bigfont')
local stringWrap = require('cc.strings').wrap
local browserScript = require('browser-script')
local logger = require('logger').open(path..'/log.txt')
logger.setTimeOffset(-5)
-- logger.enableDebug()

if (string.find(_G._HOST,"CraftOS%-PC") ~= nil) then
  -- debug.debug()
  logger.setMonitor(peripheral.wrap('left'))
end

logger.info("Browser started")
logger.info("Viewing "..path..'/'..file)
logger.info("Loading browser script v"..browserScript.VERSION)

local fileHandle = fs.open(shell.dir()..'/'..file,'r')
local xml = xmlLib.parseText(fileHandle.readAll())
fileHandle.close()

local function findChildren(xml,tagName)
  local ret = {}
  for k,v in pairs(xml) do
    if (v.tag == tagName) then
      ret[#ret+1] = v
    end
  end
  return ret
end

local function printTable(tbl,indent)
  if (indent == nil) then indent = '' end
  for k,v in pairs(tbl) do
    term.setTextColor(colors.lightBlue)
    term.write(indent..k..':')
    term.setTextColor(colors.white)
    if (type(v) == 'table') then
      print()
      printTable(v,indent..'  ')
    else
      print(tostring(v))
    end
  end
end

local windowStack = {}
local ccmlTag = findChildren(xml,'ccml')[1]
local bodyTag = findChildren(ccmlTag.children,'body')[1]

local alignmentStack = {}
local function setAlignment(width)
  local alignment = alignmentStack[#alignmentStack]
  local termW,termH = term.getSize()
  if (alignment == 'center') then
    local cX,cY = term.getCursorPos()
    term.setCursorPos((termW-width)/2,cY)
  elseif (alignment == 'right') then
    local cX,cY = term.getCursorPos()
    term.setCursorPos(termW-width+1,cY)
  end
end

local bodyTagHandlers = {}

bodyTagHandlers.align = {
  start = function(xml)
    alignmentStack[#alignmentStack + 1] = xml.attributes.value
  end,
  final = function(xml)
    alignmentStack[#alignmentStack] = nil
  end
}

local function writeWrapped(text,rootLevel)
  local termW,termH = term.getSize()
  local curX,curY = term.getCursorPos()
  if (termW-curX >= #text) then
    if (not rootLevel and text:sub(1,1) == ' ') then
      text = text:sub(2)
    end
    setAlignment(#text)
    term.write(text)
  else
    local lines = stringWrap(text,termW-curX)
    if (not rootLevel and lines[1]:sub(1,1) == ' ') then
      lines[1] = lines[1]:sub(2)
    end
    setAlignment(#lines[1])
    term.write(lines[1])
    local newText = string.sub(text,#lines[1]+1)
    if (#newText > 0) then
      print()
    end
    writeWrapped(newText)
  end
end

bodyTagHandlers.text = {
  start = function(xml)
    if (xml.value ~= nil) then
      writeWrapped(xml.value,true)
    end
  end
}
bodyTagHandlers.t = bodyTagHandlers.text

bodyTagHandlers.blit = {
  start = function(xml)
    setAlignment(#xml.value)
    term.blit(xml.value,xml.attributes.text,xml.attributes.background)
  end
}

bodyTagHandlers.big = {
  start = function(xml)
    if (xml.value ~= nil) then
      setAlignment(#xml.value*2.5)
      bigfont.bigWrite(xml.value)
    end
  end
}

bodyTagHandlers.br = {
  start = function(xml)
    print()
  end
}

local textColorStack = {}
local backgroundColorStack = {}
bodyTagHandlers.color = {
  start = function(xml)
    if (xml.attributes.text ~= nil) then
      textColorStack[#textColorStack + 1] = term.getTextColor()
      local color = xml.attributes.text
      term.setTextColor(colors[color])
    end
    if (xml.attributes.background ~= nil) then
      backgroundColorStack[#backgroundColorStack + 1] = term.getBackgroundColor()
      local color = xml.attributes.background
      term.setBackgroundColor(colors[color])
    end
  end,
  final = function(xml)
    -- printTable(textColorStack)
    -- printTable(backgroundColorStack)
    if (xml.attributes.text ~= nil) then
      term.setTextColor(textColorStack[#textColorStack])
      textColorStack[#textColorStack] = nil
    end
    if (xml.attributes.background ~= nil) then
      term.setBackgroundColor(backgroundColorStack[#backgroundColorStack])
      backgroundColorStack[#backgroundColorStack] = nil
    end
  end,
}
bodyTagHandlers.colour = bodyTagHandlers.color

bodyTagHandlers.img = {
  start = function(xml)
    local imgFilePath = shell.dir()..'/'..xml.attributes.src
    -- print(imgFilePath)
    if (string.sub(imgFilePath,-4,-1) == '.nfp') then
      local tColor = term.getTextColor()
      local bColor = term.getBackgroundColor()

      local img = paintutils.loadImage(imgFilePath)
      -- term.scroll(#img)
      local cX,cY = term.getCursorPos()
      paintutils.drawImage(img,cX,cY)

      term.setTextColor(tColor)
      term.setBackgroundColor(bColor)
      term.setCursorPos(cX,cY)
    else
      logger.error("unknown image type: "..imgFilePath)
    end
  end
}

local scripts = {}
bodyTagHandlers.script = {
  start = function(xml)
    logger.debug("adding script to array")
    scripts[#scripts+1] = function()
      logger.debug("running a script")
      browserScript.execute(xml.value,ccmlTag)
    end
  end
}

bodyTagHandlers.hr = {
  start = function(xml)
    local termW,termH = term.getSize()
    local char = '-'
    if (xml.attributes.pattern ~= nil) then
      char = xml.attributes.pattern
    end
    term.write((char):rep(termW))
    print()
  end
}

-- bodyTagHandlers.window = {
--   start = function(xml)
--     local newWindow = window.create(term,xml.attributes.x,xml.attributes.y,xml.attributes.width,xml.attributes.height)
--     windowStack[#windowStack+1] = newWindow
--     term.redirect(windowStack[#windowStack])
--   end,
--   final = function(xml)
--     windowStack[#windowStack] = nil
--     term.redirect(windowStack[#windowStack])
--   end
-- }

local termW,termH = term.getSize()
local addressWindow = window.create(term.current(),1,1,termW,1)
addressWindow.setBackgroundColor(colors.white)
addressWindow.setTextColor(colors.black)
addressWindow.clear()
-- addressWindow.setVisible(true)

renderWindow = primeui.scrollBox(term.current(),1,2,termW,termH-1,termH-1,true,true)
local oldSetCursPos = renderWindow.setCursorPos
renderWindow.setCursorPos = function(x,y)
  local posX,posY = renderWindow.getPosition()
  local winW,winH = renderWindow.getSize()
  if (y > winH) then
    renderWindow.reposition(posX,posY,winW,y)
  end
  return oldSetCursPos(x,y)
end
local oldScroll = renderWindow.scroll
renderWindow.scroll = function(num)
  if (num > 0) then
    local posX,posY = renderWindow.getPosition()
    local winW,winH = renderWindow.getSize()
    renderWindow.reposition(posX,posY,winW,winH+num)
  end
  return oldScroll(num)
end
-- renderWindow = window.create(term.current(),1,2,termW,termH-1)
windowStack[#windowStack+1] = renderWindow
term.redirect(renderWindow)

local function renderAddress()
  addressWindow.setCursorPos(1,1)
  addressWindow.write("file:/"..path..'/'..file)
end

local function renderBody(bodyTag)
  for k,v in pairs(bodyTag.children) do
    if (bodyTagHandlers[v.tag] ~= nil) then
      local handler = bodyTagHandlers[v.tag]
      logger.debug("entering "..v.tag)
      if (v.attributes ~= nil and #v.attributes > 0) then
        logger.debug("has attributes:")
        for k,v in pairs(v.attributes) do
          logger.debug("  "..v)
        end
      end
      if (handler.start ~= nil) then
        handler.start(v)
      end

      renderBody(v)

      logger.debug("exiting "..v.tag)
      if (handler.final ~= nil) then
        handler.final(v)
      end
    else
      logger.error("unknown tag: "..v.tag)
    end
  end
end

renderAddress()
term.setTextColor(colors.white)
term.setBackgroundColor(colors.black)
term.clear()
term.setCursorPos(1,1)
renderBody(bodyTag)

local function rerender()
  term.setTextColor(colors.white)
  term.setBackgroundColor(colors.black)
  term.clear()
  term.setCursorPos(1,1)
  renderBody(bodyTag)
end

parallel.waitForAll(
  function()
    rerender()
    while true do
      local e = {os.pullEvent()}
      if (e[1] == 'mouse_click') then

      elseif (e[1] == 'browser_rerender') then -- TODO: find better way to handle this
        rerender()
      end
    end
  end,
  primeui.run,
  table.unpack(scripts)
)
logger.close()
