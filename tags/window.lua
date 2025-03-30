return function(bodyTagHandlers, env)
   bodyTagHandlers.window = {
      start = function(xml)
         local newWindow = window.create(term,xml.attributes.x,xml.attributes.y,xml.attributes.width,xml.attributes.height)
         env.windowStack[#env.windowStack+1] = newWindow
         term.redirect(windowStack[#windowStack])
      end,
      final = function(xml)
         env.windowStack[#env.windowStack] = nil
         term.redirect(env.windowStack[#env.windowStack])
      end
   }
end