local validAlignment = {
    'center',
    'right'
}

--- Aligns contained elements either to center or right of containing element.
--- 
--- Required attributes:<br>
---     - value=string
return function(bodyTagHandlers, env)
    bodyTagHandlers.align = {
        start = function(xml)
            if (xml.attributes.value ~= nil) then
                env.logger.error("Missing value attribute in align tag")
            end
            env.alignmentStack[#env.alignmentStack + 1] = xml.attributes.value
        end,
        final = function(xml)
            env.alignmentStack[#env.alignmentStack] = nil
        end
    }
end