return function(bodyTagHandlers, env)
    bodyTagHandlers.br = {
        start = function(xml)
            print()
        end
    }
end