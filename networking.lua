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

return api