local browser = {}
browser.file = ({...})[1]

-- Load our libs
browser.logger = require('logger').open(shell.dir()..'/log.txt')
browser.logger.setTimeOffset(-5)
-- browser.logger.enableDebug()
browser.browserScript = require('browser-script')(browser.logger)
browser.networking = require('networking')(browser.logger)
browser.bodyTagHandlers = {}
require("tags")(browser)

-- Load other's libs (possibly tweaked)
browser.primeui = require('primeui')(browser.logger)
browser.xmlLib = require('xmlLib')
browser.bigfont = require('bigfont')

-- Load base libs
browser.strings = require('cc.strings')

-- Setup debug logging monitor if on CraftOS-PC
if (string.find(_G._HOST,"CraftOS%-PC") ~= nil and os.getComputerID() ~= -1) then
  periphemu.create('left', 'monitor')
  browser.logger.setMonitor(peripheral.wrap('left'))
end

-- Startup logs
browser.logger.info("Browser started")
if (browser.file == nil) then
  browser.logger.error("no address specified")
  local oldColor = term.getTextColor()
  term.setTextColor(colors.red)
  print("Expected an address, example:")
  print(" browser files://pages/browser.ccml")
  term.setTextColor(oldColor)
  return
end
browser.logger.info("Viewing ".. browser.file)
browser.logger.info("Loading browser script v".. browser.browserScript.VERSION)

-- Setup stacks for various tags and other browser level variables
browser.windowStack = {}
browser.alignmentStack = {}
browser.textColorStack = {}
browser.backgroundColorStack = {}
browser.scripts = {}

local function findChildren(xml,tagName)
  local ret = {}
  for k,v in pairs(xml) do
    if (v.tag == tagName) then
      ret[#ret+1] = v
    end
  end
  return ret
end

-- Load data from the path and pull out necessary tags
local function loadXML()
  browser.xml = browser.xmlLib.parseText(browser.networking.getFile(browser.file))
  browser.ccmlTag = findChildren(browser.xml,'ccml')[1]
  browser.bodyTag = findChildren(browser.ccmlTag.children,'body')[1]
  browser.headTag = findChildren(browser.ccmlTag.children,'head')[1]
end
loadXML()

function browser.printTable(tbl,indent)
  if (indent == nil) then indent = '' end
  for k,v in pairs(tbl) do
    term.setTextColor(colors.lightBlue)
    term.write(indent..k..':')
    term.setTextColor(colors.white)
    if (type(v) == 'table') then
      print()
      browser.printTable(v,indent..'  ')
    else
      print(tostring(v))
    end
  end
end

function browser.setAlignment(width)
  local alignment = browser.alignmentStack[#browser.alignmentStack]
  local termW,termH = term.getSize()
  if (alignment == 'center') then
    local cX,cY = term.getCursorPos()
    term.setCursorPos((termW-width)/2,cY)
  elseif (alignment == 'right') then
    local cX,cY = term.getCursorPos()
    term.setCursorPos(termW-width+1,cY)
  end
end

function browser.writeWrapped(text,rootLevel)
  local termW,termH = term.getSize()
  local curX,curY = term.getCursorPos()
  if (termW-curX >= #text) then
    if (not rootLevel and text:sub(1,1) == ' ') then
      text = text:sub(2)
    end
    browser.setAlignment(#text)
    term.write(text)
  else
    local lines = browser.strings.wrap(text,termW-curX)
    if (not rootLevel and lines[1]:sub(1,1) == ' ') then
      lines[1] = lines[1]:sub(2)
    end
    browser.setAlignment(#lines[1])
    term.write(lines[1])
    local newText = string.sub(text,#lines[1]+1)
    if (#newText > 0) then
      print()
    end
    browser.writeWrapped(newText)
  end
end

--[[ Graphics ]]--
local outmostTerm = term

local termW,termH = term.getSize()
-- Setup window for title stuff
local titleWindow = window.create(term.current(),1,1,termW,1)
titleWindow.setBackgroundColor(colors.white)
titleWindow.setTextColor(colors.black)
titleWindow.clear()

-- Setup window for address bar
local addressWindow = window.create(term.current(),1,2,termW,1)
addressWindow.setBackgroundColor(colors.lightGray)
addressWindow.setTextColor(colors.black)
addressWindow.clear()

-- Window for page content, using PrimeUI
local renderWindow = browser.primeui.scrollBox(term.current(),1,3,termW,termH-2,termH-2,true,true,colors.white,colors.gray)
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
browser.windowStack[#browser.windowStack+1] = renderWindow
term.redirect(renderWindow)

local function renderAddress()
  addressWindow.setCursorPos(1,1)
  addressWindow.write(browser.strings.ensure_width(browser.file,termW))
end

-- Render page icon, title, and close button
local function renderTitle()
  titleWindow.clear()
  titleWindow.setCursorPos(termW,1)
  titleWindow.setBackgroundColor(colors.red)
  titleWindow.setTextColor(colors.white)
  titleWindow.write("X")

  titleWindow.setCursorPos(2,1)
  titleWindow.setTextColor(colors.black)
  titleWindow.setBackgroundColor(colors.white)

  local title
  if (browser.headTag ~= nil) then
    local iconTag = findChildren(browser.headTag.children,'icon')[1]
    if (iconTag ~= nil) then
      titleWindow.blit(browser.strings.ensure_width(tostring(iconTag.value),2),browser.strings.ensure_width(iconTag.attributes.text,2),browser.strings.ensure_width(iconTag.attributes.background,2))
      titleWindow.setTextColor(colors.black)
      titleWindow.setBackgroundColor(colors.white)
    end

    local titleTag = findChildren(browser.headTag.children,'title')[1]
    if (titleTag ~= nil) then
      title = titleTag.value
    end
  else
    title = "Untitled Page"
  end
  titleWindow.setCursorPos(5,1)
  titleWindow.write(browser.strings.ensure_width(title,termW-5))
end

local function renderBody(bodyTag)
  for k,v in pairs(bodyTag.children) do
    if (browser.bodyTagHandlers[v.tag] ~= nil) then
      local handler = browser.bodyTagHandlers[v.tag]
      browser.logger.debug("entering "..v.tag)
      if (v.attributes ~= nil and #v.attributes > 0) then
        browser.logger.debug("has attributes:")
        for k,v in pairs(v.attributes) do
          browser.logger.debug("  "..v)
        end
      end
      if (handler.start ~= nil) then
        handler.start(v)
      end

      renderBody(v)

      browser.logger.debug("exiting "..v.tag)
      if (handler.final ~= nil) then
        handler.final(v)
      end
    else
      browser.logger.error("unknown tag: "..v.tag)
    end
  end
end

renderAddress()
renderTitle()
term.setTextColor(colors.white)
term.setBackgroundColor(colors.black)
term.clear()
term.setCursorPos(1,1)
renderBody(browser.bodyTag)

local function rerender()
  term.setTextColor(colors.white)
  term.setBackgroundColor(colors.black)
  term.clear()
  term.setCursorPos(1,1)
  renderBody(browser.bodyTag)
end

parallel.waitForAll(
  function()
    rerender()
    while true do
      local e = {os.pullEventRaw()}
      if (e[1] == 'mouse_click') then
        if (e[2] == 1 and e[3] == termW and e[4] == 1) then
          os.queueEvent('terminate')
        end
      elseif (e[1] == 'browser_refresh') then -- TODO: find better way to handle this
        loadXML()
        renderAddress()
        rerender()
        renderTitle()
      elseif (e[1] == 'browser_rerender') then -- TODO: find better way to handle this
        rerender()
        renderTitle()
      elseif (e[1] == 'terminate') then
        term.scroll(termH)
        term.clear()
        term.setCursorPos(1,1)
        return
      end
    end
  end,
  browser.primeui.run,
  table.unpack(browser.scripts)
)
browser.logger.close()
