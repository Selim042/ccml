local strings = require('cc.strings')

local api = {}

local function arrCont(arr,val)
    for k,v in pairs(arr) do
        if (v == val) then
            return true
        end
    end
    return false
end

local stacks = {
    {
        getProtocols = function()
            return {"file"}
        end,
        getFile = function(path)
            local protocol = strings.split(path,':')
            local file = fs.open(protocol[2],'r')
            local cont = file.readAll()
            file.close()
            return cont
        end
    }
}

api.registerStack = function(stack)
    stacks[#stacks+1] = stack
end

api.getProtocols = function()
    local ret = {}
    for k,v in pairs(stacks) do
        local prots = v.getProtocols()
        if (#ret == 0) then
            ret = {table.unpack(prots)}
        else
            ret = {table.unpack(ret),table.unpack(prots)}
        end
    end
    return ret
end

api.getFile = function(path)
    local protocol = strings.split(path,':')
    for k,v in pairs(stacks) do
        if (arrCont(v.getProtocols(),protocol[1])) then
            return v.getFile(path)
        end
    end
end

-- Parse URI like describe in https://en.wikipedia.org/wiki/URI (don't support ipv6)
api.UriParser = function(url)
    local res = {}
    local tokens = strings.split(url,':', true, 1)
    if #tokens == 1 then
        error("invalid url") -- "http"
    end
    res.scheme = tokens[1]
    if tokens[2]:sub(0, 2) == "//" then
        tokens = tokens[2]:sub(3)
        tokens = strings.split(tokens,'/', true, 1)
        if #tokens == 1 then
            tokens[2] = "/"
        else
            tokens[2] = "/" .. tokens[2]
        end
        local authority = tokens[1]
        res.authority = {}
        authority = strings.split(authority,'@', true, 1)
        if #authority == 2 then
            res.authority.userinfo = authority[1]
            authority[1] = authority[2]
        end
        authority = strings.split(authority[1],':', true, 1)
        res.authority.host = authority[1]
        if authority[1] == "" then
            error("invalid url") -- "http://"
        end
        if #authority == 2 then
            res.authority.port = authority[2]
        end
    end
    local path = strings.split(tokens[2],'#', true, 1)
    if #path == 2 then
        res.fragment = path[2]
    end
    path = strings.split(path[1],'?', true, 1)
    if #path == 2 then
        res.arguments = path[2]
    end
    res.path = path[1]
    return res
end

return api