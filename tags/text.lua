return function(bodyTagHandlers, env)
    bodyTagHandlers.text = {
        start = function(xml)
            if (xml.value ~= nil) then
                env.writeWrapped(xml.value,true)
            end
        end
    }
end