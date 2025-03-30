local validAlignmentValues = {
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
            if (xml.attributes.value == nil) then
                env.logger.error("Missing value attribute in align tag")
            end
            local validAlign = false
            for k,v in ipairs(validAlignmentValues) do
                if (v == xml.attributes.value) then
                    validAlign = true
                end
            end
            if (not validAlign) then
                env.logger.error("Invalid alignment value: "..xml.attributes.value)
            end
            env.alignmentStack[#env.alignmentStack + 1] = xml.attributes.value
        end,
        final = function(xml)
            env.alignmentStack[#env.alignmentStack] = nil
        end
    }
end