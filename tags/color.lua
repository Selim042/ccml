return function(bodyTagHandlers, env)
    bodyTagHandlers.color = {
        start = function(xml)
            if (xml.attributes.text ~= nil) then
                env.textColorStack[#env.textColorStack + 1] = term.getTextColor()
                local color = xml.attributes.text
                term.setTextColor(colors[color])
            end
            if (xml.attributes.background ~= nil) then
                env.backgroundColorStack[#env.backgroundColorStack + 1] = term.getBackgroundColor()
                local color = xml.attributes.background
                term.setBackgroundColor(colors[color])
            end
        end,
        final = function(xml)
            -- printTable(textColorStack)
            -- printTable(backgroundColorStack)
            if (xml.attributes.text ~= nil) then
                term.setTextColor(env.textColorStack[#env.textColorStack])
                env.textColorStack[#env.textColorStack] = nil
            end
            if (xml.attributes.background ~= nil) then
                term.setBackgroundColor(env.backgroundColorStack[#env.backgroundColorStack])
                env.backgroundColorStack[#env.backgroundColorStack] = nil
            end
        end,
    }
    bodyTagHandlers.colour = bodyTagHandlers.color
end