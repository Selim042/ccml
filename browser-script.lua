local api = {}
api.VERSION = "1.0.0"

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
    os.queueEvent('browser-rerender')
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
  -- global.print = print
  global.pairs = pairs
  global.ipairs = ipairs
  global.tostring = tostring
  -- todo: how to isolate these??
  global.string = string
  return global
end

api.execute = function(script,dom)
  local env = getEnv(dom)
  local loadedScript = load(script)
  assert(loadedScript)
  setfenv(loadedScript,env)
  loadedScript()
end

return api
