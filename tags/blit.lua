return function(bodyTagHandlers, env)
    bodyTagHandlers.blit = {
        start = function(xml)
            env.setAlignment(#xml.value)
            term.blit(xml.value,xml.attributes.text,xml.attributes.background)
        end
    }
end