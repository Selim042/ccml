return function(bodyTagHandlers, env)
    bodyTagHandlers.link = {
        start = function(xml)
            env.setAlignment(#xml.value)
            local curX,curY = term.getCursorPos()
            local tColor = term.getTextColor()
            local bgColor = term.getBackgroundColor()
            env.primeui.button(term.current(),curX,curY,xml.value,
                    function()
                        local protocol = env.strings.split(env.file,':')[1]

                        local slashSplit = env.strings.split(env.file,'/')
                        slashSplit[#slashSplit] = nil
                        local pathMinusFile = table.concat(slashSplit,'/')
                        local destFilePath = pathMinusFile..'/'..xml.attributes.dest

                        env.file = destFilePath
                        os.queueEvent('browser_refresh')
                    end
            )
            term.setTextColor(tColor)
            term.setBackgroundColor(bgColor)
        end
    }
end