return function(bodyTagHandlers, env)
    bodyTagHandlers.script = {
        start = function(xml)
            env.logger.debug("adding script to array")
            env.scripts[#env.scripts+1] = function()
                env.logger.debug("running a script")
                env.browserScript.execute(xml.value,env.ccmlTag)
            end
        end
    }
end