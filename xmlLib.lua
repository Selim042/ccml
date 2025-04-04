-- modified from Basalt
-- https://github.com/Pyroxenium/Basalt/blob/c71557feb72e83377bb75d83fc6ecbe34418b9ae/Basalt/libraries/xmlParser.lua#L4
-- Used under MIT license
-- Removes quotes around string arugments and adds number literal arguments

local XMLNode = {
    new = function(tag)
        return {
            tag = tag,
            value = nil,
            attributes = {},
            children = {},

            addChild = function(self, child)
                table.insert(self.children, child)
            end,

            addAttribute = function(self, tag, value)
                self.attributes[tag] = value
            end
        }
    end
}

local parseAttributes = function(node, s)
    -- Parse "" style string attributes
    local _, _ = string.gsub(s, "(%w+)=([\"'])(.-)%2", function(attribute, _, value)
        node:addAttribute(attribute, value) -- remove quotes from value
    end)
    -- Parse {} style computed attributes
    local _, _ = string.gsub(s, "(%w+)={(.-)}", function(attribute, expression)
        node:addAttribute(attribute, expression)
    end)
    -- added attributes type: number literals
    -- Parse numeric style string attributes
    local _, _ = string.gsub(s, "(%w+)=(%d%d-)", function(attribute, value)
        node:addAttribute(attribute, tonumber(value))
    end)
end

local XMLParser = {
    parseText = function(xmlText)
        -- Allow \ encoded special characters
        xmlText = xmlText:gsub("\\(%d%d%d?)", function(n) return string.char(tonumber(n)) end)

        local stack = {}
        local top = XMLNode.new()
        table.insert(stack, top)
        local ni, c, label, xarg, empty
        local i, j = 1, 1
        while true do
            ni, j, c, label, xarg, empty = string.find(xmlText, "<(%/?)([%w_:]+)(.-)(%/?)>", i)
            if not ni then break end
            local text = string.sub(xmlText, i, ni - 1);
            if not string.find(text, "^%s*$") then
                local lVal = (top.value or "") .. text
                stack[#stack].value = lVal
            end
            if empty == "/" then -- empty element tag
                local lNode = XMLNode.new(label)
                parseAttributes(lNode, xarg)
                top:addChild(lNode)
            elseif c == "" then -- start tag
                local lNode = XMLNode.new(label)
                parseAttributes(lNode, xarg)
                table.insert(stack, lNode)
                top = lNode
            else -- end tag
                local toclose = table.remove(stack) -- remove top

                top = stack[#stack]
                if #stack < 1 then
                    error("XMLParser: nothing to close with " .. label)
                end
                if toclose.tag ~= label then
                    error("XMLParser: trying to close " .. toclose.tag .. " with " .. label)
                end
                top:addChild(toclose)
            end
            i = j + 1
        end
        local text = string.sub(xmlText, i);
        if #stack > 1 then
            error("XMLParser: unclosed " .. stack[#stack].tag)
        end
        return top.children
    end
}

return XMLParser