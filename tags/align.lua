return function(bodyTagHandlers, env)
    bodyTagHandlers.align = {
        start = function(xml)
            env.alignmentStack[#env.alignmentStack + 1] = xml.attributes.value
        end,
        final = function(xml)
            env.alignmentStack[#env.alignmentStack] = nil
        end
    }
end