return function(bodyTagHandlers, env)
    bodyTagHandlers.big = {
        start = function(xml)
            if (xml.value ~= nil) then
                env.setAlignment(#xml.value*2.5)
                env.bigfont.bigWrite(xml.value)
            end
        end
    }
end