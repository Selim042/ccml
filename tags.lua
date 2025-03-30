local tagList = {
    "align",
    "text",
    "t",
    "blit",
    "big",
    "br",
    "color",
    "colour",
    "img",
    "script",
    "hr",
    "link",
    --"window"
}

return function(browser)
    for _, tag in pairs(tagList) do
        require("tags." .. tag)(browser.bodyTagHandlers, browser)
    end
end