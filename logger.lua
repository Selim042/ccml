local api = {}

api.open = function(filePath)
  local file = fs.open(filePath,'a')
  local debugEnabled = false
  local isClosed = false
  local timeOffset = 0

  local function writeLine(msg)
    file.writeLine(msg)
    file.flush()
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
    file.write('[')
    file.write(hours)
    file.write(':')
    local mins = math.floor(60*(time - math.floor(time)))
    if (mins < 10) then
      mins = '0'..mins
    end
    file.write(mins)
    file.write(']')
  end

  local ret = {}
  ret.info = function(msg)
    if (not isClosed) then
      writeTime()
      file.write(' [INFO] ')
      writeLine(msg)
    end
  end

  ret.error = function(msg)
    if (not isClosed) then
      writeTime()
      file.write(' [ERROR] ')
      writeLine(msg)
    end
  end

  ret.debug = function(msg)
    if (not closed and debugEnabled) then
      writeTime()
      file.write(' [DEBUG] ')
      writeLine(msg)
    end
  end

  ret.enableDebug = function()
    debugEnabled = true
  end

  ret.setTimeOffset = function(offset)
    timeOffset = offset
  end

  ret.close = function()
    file.close()
  end

  return ret
end

return api
