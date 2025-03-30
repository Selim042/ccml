return function(bodyTagHandlers, env)
  bodyTagHandlers.hr = {
    start = function(xml)
      local termW,termH = term.getSize()
      local char = '-'
      if (xml.attributes.pattern ~= nil) then
        char = xml.attributes.pattern
      end
      term.write(string.rep(char,termW))
      print()
    end
  }
end