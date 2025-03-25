local api = {}

api.open = function(filePath)
  local file = fs.open(filePath,'a')
  local debugEnabled = false
  local isClosed = false
  local timeOffset = 0
  local monitor = nil
  local name = nil

  local function fileWrite(msg)
    file.write(msg)
    file.flush()
    if (monitor ~= nil) then
      monitor.write(msg)
    end
  end

  local function fileWriteLine(msg)
    file.writeLine(msg)
    file.flush()
    if (monitor ~= nil) then
      monitor.write(msg..'\n')
      monitor.scroll(1)
      local monW,monH = monitor.getSize()
      monitor.setCursorPos(1,monH)
    end
  end

  local function writeTime()
    local time = os.time('utc') + timeOffset
    if (time < 0) then
      time = time + 24
    end
    local hours = math.floor(time)
    if (hours < 10) then
      hours = '0'..hours
    end
    fileWrite('[')
    fileWrite(hours)
    fileWrite(':')
    local mins = math.floor(60*(time - math.floor(time)))
    if (mins < 10) then
      mins = '0'..mins
    end
    fileWrite(mins)
    fileWrite(']')
  end

  local function writeName()
    if (name ~= nil) then
      fileWrite('[')
      fileWrite(name)
      fileWrite(']')
    end
  end

  local ret = {}
  ret.info = function(msg)
    if (not isClosed) then
      writeTime()
      writeName()
      fileWrite('[INFO] ')
      fileWriteLine(msg)
    end
  end

  ret.error = function(msg)
    if (not isClosed) then
      writeTime()
      writeName()
      fileWrite('[ERROR] ')
      fileWriteLine(msg)
    end
  end

  ret.debug = function(msg)
    if (not isClosed and debugEnabled) then
      writeTime()
      writeName()
      fileWrite('[DEBUG] ')
      fileWriteLine(msg)
    end
  end

  ret.enableDebug = function()
    debugEnabled = true
  end

  ret.setTimeOffset = function(offset)
    timeOffset = offset
  end

  ret.setMonitor = function(mon)
    monitor = mon
    local monW,monH = monitor.getSize()
    monitor.setCursorPos(1,monH)
  end

  ret.setName = function(nm)
    name = nm
  end

  ret.close = function()
    file.close()
  end

  return ret
end

return api
