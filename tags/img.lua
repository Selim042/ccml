return function(bodyTagHandlers, env)
    bodyTagHandlers.img = {
        start = function(xml)
            local protocol = env.strings.split(env.file,':')[1]

            local slashSplit = env.strings.split(env.file,'/')
            slashSplit[#slashSplit] = nil
            local pathMinusFile = table.concat(slashSplit,'/')
            -- local imgFilePath = protocol..'://'..xml.attributes.src
            local imgFilePath = pathMinusFile..'/'..xml.attributes.src
            -- print(imgFilePath)
            if (string.sub(imgFilePath,-4,-1) == '.nfp') then
                local tColor = term.getTextColor()
                local bColor = term.getBackgroundColor()

                local img = paintutils.parseImage(env.networking.getFile(imgFilePath))
                -- term.scroll(#img)
                local cX,cY = term.getCursorPos()
                if (cY <= 2) then
                    term.scroll(#img)
                end
                paintutils.drawImage(img,cX,cY)

                term.setTextColor(tColor)
                term.setBackgroundColor(bColor)
                term.setCursorPos(cX,cY)
            else
                env.logger.error("unknown image type: "..imgFilePath)
            end
        end
    }
end