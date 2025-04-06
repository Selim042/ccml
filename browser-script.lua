local logger

local api = {}
api.VERSION = "2025.02.0"

local function getFunctions()
  local function getElementById(elementId,dom)
    local ret = {}
    for k,v in pairs(dom.children) do
      if (v.attributes.id == elementId) then
        ret[#ret+1] = v
      end

      local toConcat = getElementById(elementId,v)
      if (#toConcat > 0) then
        ret = {
          table.unpack(toConcat),
          table.unpack(ret)
        }
      end
    end
    return ret
  end
  local function rerender()
    os.queueEvent('browser_rerender')
  end
  return {
    getElementById = getElementById,
    rerender = rerender
  }
end

local function getEnv(dom)
  local global = {}
  global._G = global
  global.dom = dom
  for k,v in pairs(getFunctions()) do
    global[k] = v
  end
  global.sleep = sleep
  global.pairs = pairs
  global.ipairs = ipairs
  global.tostring = tostring
  global.string = {}
  for k,v in pairs(string) do
    global.string[k] = v
  end
  global.logger = {
    info = logger.info,
    error = logger.error,
    debug = logger.debug
  }
  return global
end

local function errorHandler(msg)
  logger.error("Error from script: "..msg)
end

api.execute = function(script,dom)
  local env = getEnv(dom)
  xpcall(load(script,"script","t",env), errorHandler)
end

return function(log)
  logger = log
  return api
end
