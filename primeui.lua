-- PrimeUI by JackMacWindows
-- Public domain/CC0

local expect = require "cc.expect".expect

-- Initialization code
local PrimeUI = {}
do
    local coros = {}
    local restoreCursor

    --- Adds a task to run in the main loop.
    ---@param func function The function to run, usually an `os.pullEvent` loop
    function PrimeUI.addTask(func)
        expect(1, func, "function")
        local t = {coro = coroutine.create(func)}
        coros[#coros+1] = t
        _, t.filter = coroutine.resume(t.coro)
    end

    --- Sends the provided arguments to the run loop, where they will be returned.
    ---@param ... any The parameters to send
    function PrimeUI.resolve(...)
        coroutine.yield(coros, ...)
    end

    --- Clears the screen and resets all components. Do not use any previously
    --- created components after calling this function.
    function PrimeUI.clear()
        -- Reset the screen.
        term.setCursorPos(1, 1)
        term.setCursorBlink(false)
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.clear()
        -- Reset the task list and cursor restore function.
        coros = {}
        restoreCursor = nil
    end

    --- Sets or clears the window that holds where the cursor should be.
    ---@param win window|nil The window to set as the active window
    function PrimeUI.setCursorWindow(win)
        expect(1, win, "table", "nil")
        restoreCursor = win and win.restoreCursor
    end

    --- Gets the absolute position of a coordinate relative to a window.
    ---@param win window The window to check
    ---@param x number The relative X position of the point
    ---@param y number The relative Y position of the point
    ---@return number x The absolute X position of the window
    ---@return number y The absolute Y position of the window
    function PrimeUI.getWindowPos(win, x, y)
        if win == term then return x, y end
        while win ~= term.native() and win ~= term.current() do
            if not win.getPosition then return x, y end
            local wx, wy = win.getPosition()
            x, y = x + wx - 1, y + wy - 1
            _, win = debug.getupvalue(select(2, debug.getupvalue(win.isColor, 1)), 1) -- gets the parent window through an upvalue
        end
        return x, y
    end

    --- Runs the main loop, returning information on an action.
    ---@return any ... The result of the coroutine that exited
    function PrimeUI.run()
        while true do
            -- Restore the cursor and wait for the next event.
            if restoreCursor then restoreCursor() end
            local ev = table.pack(os.pullEvent())
            -- Run all coroutines.
            for _, v in ipairs(coros) do
                if v.filter == nil or v.filter == ev[1] then
                    -- Resume the coroutine, passing the current event.
                    local res = table.pack(coroutine.resume(v.coro, table.unpack(ev, 1, ev.n)))
                    -- If the call failed, bail out. Coroutines should never exit.
                    if not res[1] then error(res[2], 2) end
                    -- If the coroutine resolved, return its values.
                    if res[2] == coros then return table.unpack(res, 3, res.n) end
                    -- Set the next event filter.
                    v.filter = res[2]
                end
            end
        end
    end
end

--- Draws a thin border around a screen region.
---@param win window The window to draw on
---@param x number The X coordinate of the inside of the box
---@param y number The Y coordinate of the inside of the box
---@param width number The width of the inner box
---@param height number The height of the inner box
---@param fgColor color|nil The color of the border (defaults to white)
---@param bgColor color|nil The color of the background (defaults to black)
function PrimeUI.borderBox(win, x, y, width, height, fgColor, bgColor)
    expect(1, win, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, width, "number")
    expect(5, height, "number")
    fgColor = expect(6, fgColor, "number", "nil") or colors.white
    bgColor = expect(7, bgColor, "number", "nil") or colors.black
    -- Draw the top-left corner & top border.
    win.setBackgroundColor(bgColor)
    win.setTextColor(fgColor)
    win.setCursorPos(x - 1, y - 1)
    win.write("\x9C" .. ("\x8C"):rep(width))
    -- Draw the top-right corner.
    win.setBackgroundColor(fgColor)
    win.setTextColor(bgColor)
    win.write("\x93")
    -- Draw the right border.
    for i = 1, height do
        win.setCursorPos(win.getCursorPos() - 1, y + i - 1)
        win.write("\x95")
    end
    -- Draw the left border.
    win.setBackgroundColor(bgColor)
    win.setTextColor(fgColor)
    for i = 1, height do
        win.setCursorPos(x - 1, y + i - 1)
        win.write("\x95")
    end
    -- Draw the bottom border and corners.
    win.setCursorPos(x - 1, y + height)
    win.write("\x8D" .. ("\x8C"):rep(width) .. "\x8E")
end

--- Creates a clickable button on screen with text.
---@param win window The window to draw on
---@param x number The X position of the button
---@param y number The Y position of the button
---@param text string The text to draw on the button
---@param action function|string A function to call when clicked, or a string to send with a `run` event
---@param fgColor color|nil The color of the button text (defaults to white)
---@param bgColor color|nil The color of the button (defaults to light gray)
---@param clickedColor color|nil The color of the button when clicked (defaults to gray)
---@param periphName string|nil The name of the monitor peripheral, or nil (set if you're using a monitor - events will be filtered to that monitor)
function PrimeUI.button(win, x, y, text, action, fgColor, bgColor, clickedColor, periphName)
    expect(1, win, "table")
    expect(1, win, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, text, "string")
    expect(5, action, "function", "string")
    fgColor = expect(6, fgColor, "number", "nil") or colors.white
    bgColor = expect(7, bgColor, "number", "nil") or colors.gray
    clickedColor = expect(8, clickedColor, "number", "nil") or colors.lightGray
    periphName = expect(9, periphName, "string", "nil")
    -- Draw the initial button.
    win.setCursorPos(x, y)
    win.setBackgroundColor(bgColor)
    win.setTextColor(fgColor)
    win.write(" " .. text .. " ")
    -- Get the screen position and add a click handler.
    PrimeUI.addTask(function()
        local screenX, screenY = PrimeUI.getWindowPos(win, x, y)
        local buttonDown = false
        while true do
            local event, button, clickX, clickY = os.pullEvent()
            if event == "mouse_click" and periphName == nil and button == 1 and clickX >= screenX and clickX < screenX + #text + 2 and clickY == screenY then
                -- Initiate a click action (but don't trigger until mouse up).
                buttonDown = true
                -- Redraw the button with the clicked background color.
                win.setCursorPos(x, y)
                win.setBackgroundColor(clickedColor)
                win.setTextColor(fgColor)
                win.write(" " .. text .. " ")
            elseif (event == "monitor_touch" and periphName == button and clickX >= screenX and clickX < screenX + #text + 2 and clickY == screenY)
                or (event == "mouse_up" and button == 1 and buttonDown) then
                -- Finish a click event.
                if clickX >= screenX and clickX < screenX + #text + 2 and clickY == screenY then
                    -- Trigger the action.
                    if type(action) == "string" then
                        PrimeUI.resolve("button", action)
                    else
                        action()
                    end
                end
                -- Redraw the original button state.
                win.setCursorPos(x, y)
                win.setBackgroundColor(bgColor)
                win.setTextColor(fgColor)
                win.write(" " .. text .. " ")
            end
        end
    end)
end

--- Draws a line of text, centering it inside a box horizontally.
---@param win window The window to draw on
---@param x number The X position of the left side of the box
---@param y number The Y position of the box
---@param width number The width of the box to draw in
---@param text string The text to draw
---@param fgColor color|nil The color of the text (defaults to white)
---@param bgColor color|nil The color of the background (defaults to black)
function PrimeUI.centerLabel(win, x, y, width, text, fgColor, bgColor)
    expect(1, win, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, width, "number")
    expect(5, text, "string")
    fgColor = expect(6, fgColor, "number", "nil") or colors.white
    bgColor = expect(7, bgColor, "number", "nil") or colors.black
    assert(#text <= width, "string is too long")
    win.setCursorPos(x + math.floor((width - #text) / 2), y)
    win.setTextColor(fgColor)
    win.setBackgroundColor(bgColor)
    win.write(text)
end

--- Creates a list of entries with toggleable check boxes.
---@param win window The window to draw on
---@param x number The X coordinate of the inside of the box
---@param y number The Y coordinate of the inside of the box
---@param width number The width of the inner box
---@param height number The height of the inner box
---@param selections table<string,string|boolean> A list of entries to show, where the value is whether the item is pre-selected (or `"R"` for required/forced selected)
---@param action function|string|nil A function or `run` event that's called when a selection is made
---@param fgColor color|nil The color of the text (defaults to white)
---@param bgColor color|nil The color of the background (defaults to black)
function PrimeUI.checkSelectionBox(win, x, y, width, height, selections, action, fgColor, bgColor)
    expect(1, win, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, width, "number")
    expect(5, height, "number")
    expect(6, selections, "table")
    expect(7, action, "function", "string", "nil")
    fgColor = expect(8, fgColor, "number", "nil") or colors.white
    bgColor = expect(9, bgColor, "number", "nil") or colors.black
    -- Calculate how many selections there are.
    local nsel = 0
    for _ in pairs(selections) do nsel = nsel + 1 end
    -- Create the outer display box.
    local outer = window.create(win, x, y, width, height)
    outer.setBackgroundColor(bgColor)
    outer.clear()
    -- Create the inner scroll box.
    local inner = window.create(outer, 1, 1, width - 1, nsel)
    inner.setBackgroundColor(bgColor)
    inner.setTextColor(fgColor)
    inner.clear()
    -- Draw each line in the window.
    local lines = {}
    local nl, selected = 1, 1
    for k, v in pairs(selections) do
        inner.setCursorPos(1, nl)
        inner.write((v and (v == "R" and "[-] " or "[\xD7] ") or "[ ] ") .. k)
        lines[nl] = {k, not not v}
        nl = nl + 1
    end
    -- Draw a scroll arrow if there is scrolling.
    if nsel > height then
        outer.setCursorPos(width, height)
        outer.setBackgroundColor(bgColor)
        outer.setTextColor(fgColor)
        outer.write("\31")
    end
    -- Set cursor blink status.
    inner.setCursorPos(2, selected)
    inner.setCursorBlink(true)
    PrimeUI.setCursorWindow(inner)
    -- Get screen coordinates & add run task.
    local screenX, screenY = PrimeUI.getWindowPos(win, x, y)
    PrimeUI.addTask(function()
        local scrollPos = 1
        while true do
            -- Wait for an event.
            local ev = table.pack(os.pullEvent())
            -- Look for a scroll event or a selection event.
            local dir
            if ev[1] == "key" then
                if ev[2] == keys.up then dir = -1
                elseif ev[2] == keys.down then dir = 1
                elseif ev[2] == keys.space and selections[lines[selected][1]] ~= "R" then
                    -- (Un)select the item.
                    lines[selected][2] = not lines[selected][2]
                    inner.setCursorPos(2, selected)
                    inner.write(lines[selected][2] and "\xD7" or " ")
                    -- Call the action if passed; otherwise, set the original table.
                    if type(action) == "string" then PrimeUI.resolve("checkSelectionBox", action, lines[selected][1], lines[selected][2])
                    elseif action then action(lines[selected][1], lines[selected][2])
                    else selections[lines[selected][1]] = lines[selected][2] end
                    -- Redraw all lines in case of changes.
                    for i, v in ipairs(lines) do
                        local vv = selections[v[1]] == "R" and "R" or v[2]
                        inner.setCursorPos(2, i)
                        inner.write((vv and (vv == "R" and "-" or "\xD7") or " "))
                    end
                    inner.setCursorPos(2, selected)
                end
            elseif ev[1] == "mouse_scroll" and ev[3] >= screenX and ev[3] < screenX + width and ev[4] >= screenY and ev[4] < screenY + height then
                dir = ev[2]
            end
            -- Scroll the screen if required.
            if dir and (selected + dir >= 1 and selected + dir <= nsel) then
                selected = selected + dir
                if selected - scrollPos < 0 or selected - scrollPos >= height then
                    scrollPos = scrollPos + dir
                    inner.reposition(1, 2 - scrollPos)
                end
                inner.setCursorPos(2, selected)
            end
            -- Redraw scroll arrows and reset cursor.
            outer.setCursorPos(width, 1)
            outer.write(scrollPos > 1 and "\30" or " ")
            outer.setCursorPos(width, height)
            outer.write(scrollPos < nsel - height + 1 and "\31" or " ")
            inner.restoreCursor()
        end
    end)
end

--- Creates a clickable region on screen without any content.
---@param win window The window to draw on
---@param x number The X position of the button
---@param y number The Y position of the button
---@param width number The width of the inner box
---@param height number The height of the inner box
---@param action function|string A function to call when clicked, or a string to send with a `run` event
---@param periphName string|nil The name of the monitor peripheral, or nil (set if you're using a monitor - events will be filtered to that monitor)
function PrimeUI.clickRegion(win, x, y, width, height, action, periphName)
    expect(1, win, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, width, "number")
    expect(5, height, "number")
    expect(6, action, "function", "string")
    expect(7, periphName, "string", "nil")
    PrimeUI.addTask(function()
        -- Get the screen position and add a click handler.
        local screenX, screenY = PrimeUI.getWindowPos(win, x, y)
        local buttonDown = false
        while true do
            local event, button, clickX, clickY = os.pullEvent()
            if (event == "monitor_touch" and periphName == button)
                or (event == "mouse_click" and button == 1 and periphName == nil) then
                -- Finish a click event.
                if clickX >= screenX and clickX < screenX + width
                    and clickY >= screenY and clickY < screenY + height then
                    -- Trigger the action.
                    if type(action) == "string" then
                        PrimeUI.resolve("clickRegion", action)
                    else
                        action()
                    end
                end
            end
        end
    end)
end

--- Draws a BIMG-formatted image to the screen. This does not support transparency,
--- and does not handle animation on its own (but the index parameter may be
--- used by apps to implement animation).
---@param win window The window to draw on
---@param x number The X position of the top left corner of the image
---@param y number The Y position of the top left corner of the image
---@param data string|table The path to the image to load, or the image data itself
---@param index number|nil The index of the frame to draw (defaults to 1)
---@param setPalette boolean|nil Whether to set the palette if the image contains one (defaults to true)
function PrimeUI.drawImage(win, x, y, data, index, setPalette)
    expect(1, win, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, data, "string", "table")
    index = expect(5, index, "number", "nil") or 1
    expect(6, setPalette, "boolean", "nil")
    if setPalette == nil then setPalette = true end
    -- Load the image file if a string was passed. (This consists of reading the file and unserializing.)
    if type(data) == "string" then
        local file = assert(fs.open(data, "rb"))
        local filedata = file.readAll()
        file.close()
        data = assert(textutils.unserialize(filedata), "File is not a valid BIMG file")
    end
    -- Blit each line to the screen.
    for line = 1, #data[index] do
        win.setCursorPos(x, y + line - 1)
        win.blit(table.unpack(data[index][line]))
    end
    -- Set the palette if one exists and is desired.
    local palette = data[index].palette or data.palette
    if setPalette and palette then
        for i = 0, #palette do
            win.setPaletteColor(2^i, table.unpack(palette[i]))
        end
    end
end

--- Draws a NFT-formatted image to the screen.
---@param win window The window to draw on
---@param x number The X position of the top left corner of the image
---@param y number The Y position of the top left corner of the image
---@param data string|table The path to the image to load, or the image data itself
function PrimeUI.drawNFT(win, x, y, data)
    expect(1, win, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, data, "string", "table")
    -- Load the image file if a string was passed using nft.load.
    if type(data) == "string" then
        data = assert(nft.load("data/example.nft"), "File is not a valid NFT file")
    end
    nft.draw(data, x, y , win)
end

--- Draws a block of text inside a window with word wrapping, optionally resizing the window to fit.
---@param win window The window to draw in
---@param text string The text to draw
---@param resizeToFit boolean|nil Whether to resize the window to fit the text (defaults to false). This is useful for scroll boxes.
---@param fgColor color|nil The color of the text (defaults to white)
---@param bgColor color|nil The color of the background (defaults to black)
---@return number lines The total number of lines drawn
function PrimeUI.drawText(win, text, resizeToFit, fgColor, bgColor)
    expect(1, win, "table")
    expect(2, text, "string")
    expect(3, resizeToFit, "boolean", "nil")
    fgColor = expect(4, fgColor, "number", "nil") or colors.white
    bgColor = expect(5, bgColor, "number", "nil") or colors.black
    -- Set colors.
    win.setBackgroundColor(bgColor)
    win.setTextColor(fgColor)
    -- Redirect to the window to use print on it.
    local old = term.redirect(win)
    -- Draw the text using print().
    local lines = print(text)
    -- Redirect back to the original terminal.
    term.redirect(old)
    -- Resize the window if desired.
    if resizeToFit then
        -- Get original parameters.
        local x, y = win.getPosition()
        local w = win.getSize()
        -- Resize the window.
        win.reposition(x, y, w, lines)
    end
    return lines
end

--- Creates a text input box.
---@param win window The window to draw on
---@param x number The X position of the left side of the box
---@param y number The Y position of the box
---@param width number The width/length of the box
---@param action function|string A function or `run` event to call when the enter key is pressed
---@param fgColor color|nil The color of the text (defaults to white)
---@param bgColor color|nil The color of the background (defaults to black)
---@param replacement string|nil A character to replace typed characters with
---@param history string[]|nil A list of previous entries to provide
---@param completion function|nil A function to call to provide completion
---@param default string|nil A string to return if the box is empty
function PrimeUI.inputBox(win, x, y, width, action, fgColor, bgColor, replacement, history, completion, default)
    expect(1, win, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, width, "number")
    expect(5, action, "function", "string")
    fgColor = expect(6, fgColor, "number", "nil") or colors.white
    bgColor = expect(7, bgColor, "number", "nil") or colors.black
    expect(8, replacement, "string", "nil")
    expect(9, history, "table", "nil")
    expect(10, completion, "function", "nil")
    expect(11, default, "string", "nil")
    -- Create a window to draw the input in.
    local box = window.create(win, x, y, width, 1)
    box.setTextColor(fgColor)
    box.setBackgroundColor(bgColor)
    box.clear()
    -- Call read() in a new coroutine.
    PrimeUI.addTask(function()
        -- We need a child coroutine to be able to redirect back to the window.
        local coro = coroutine.create(read)
        -- Run the function for the first time, redirecting to the window.
        local old = term.redirect(box)
        local ok, res = coroutine.resume(coro, replacement, history, completion, default)
        term.redirect(old)
        -- Run the coroutine until it finishes.
        while coroutine.status(coro) ~= "dead" do
            -- Get the next event.
            local ev = table.pack(os.pullEvent())
            -- Redirect and resume.
            old = term.redirect(box)
            ok, res = coroutine.resume(coro, table.unpack(ev, 1, ev.n))
            term.redirect(old)
            -- Pass any errors along.
            if not ok then error(res) end
        end
        -- Send the result to the receiver.
        if type(action) == "string" then PrimeUI.resolve("inputBox", action, res)
        else action(res) end
        -- Spin forever, because tasks cannot exit.
        while true do os.pullEvent() end
    end)
end

--- Runs a function or action repeatedly after a specified time period until canceled.
--- If a function is passed as an action, it may return a number to change the
--- period, or `false` to stop it.
---@param time number The amount of time to wait for each time, in seconds
---@param action function|string The function to call when the timer completes, or a `run` event to send
---@return function cancel A function to cancel the timer
function PrimeUI.interval(time, action)
    expect(1, time, "number")
    expect(2, action, "function", "string")
    -- Start the timer.
    local timer = os.startTimer(time)
    -- Add a task to wait for the timer.
    PrimeUI.addTask(function()
        while true do
            -- Wait for a timer event.
            local _, tm = os.pullEvent("timer")
            if tm == timer then
                -- Fire the timer action.
                local res
                if type(action) == "string" then PrimeUI.resolve("timeout", action)
                else res = action() end
                -- Check the return value and adjust time accordingly.
                if type(res) == "number" then time = res end
                -- Set a new timer if not canceled.
                if res ~= false then timer = os.startTimer(time) end
            end
        end
    end)
    -- Return a function to cancel the timer.
    return function() os.cancelTimer(timer) end
end

--- Adds an action to trigger when a key is pressed.
---@param key key The key to trigger on, from `keys.*`
---@param action function|string A function to call when clicked, or a string to use as a key for a `run` return event
function PrimeUI.keyAction(key, action)
    expect(1, key, "number")
    expect(2, action, "function", "string")
    PrimeUI.addTask(function()
        while true do
            local _, param1 = os.pullEvent("key") -- wait for key
            if param1 == key then
                if type(action) == "string" then PrimeUI.resolve("keyAction", action)
                else action() end
            end
        end
    end)
end

--- Adds an action to trigger when a key is pressed with modifier keys.
---@param key key The key to trigger on, from `keys.*`
---@param withCtrl boolean Whether Ctrl is required
---@param withAlt boolean Whether Alt is required
---@param withShift boolean Whether Shift is required
---@param action function|string A function to call when clicked, or a string to use as a key for a `run` return event
function PrimeUI.keyCombo(key, withCtrl, withAlt, withShift, action)
    expect(1, key, "number")
    expect(2, withCtrl, "boolean")
    expect(3, withAlt, "boolean")
    expect(4, withShift, "boolean")
    expect(5, action, "function", "string")
    PrimeUI.addTask(function()
        local heldCtrl, heldAlt, heldShift = false, false, false
        while true do
            local event, param1, param2 = os.pullEvent() -- wait for key
            if event == "key" then
                -- check if key is down, all modifiers are correct, and that it's not held
                if param1 == key and heldCtrl == withCtrl and heldAlt == withAlt and heldShift == withShift and not param2 then
                    if type(action) == "string" then PrimeUI.resolve("keyCombo", action)
                    else action() end
                -- activate modifier keys
                elseif param1 == keys.leftCtrl or param1 == keys.rightCtrl then heldCtrl = true
                elseif param1 == keys.leftAlt or param1 == keys.rightAlt then heldAlt = true
                elseif param1 == keys.leftShift or param1 == keys.rightShift then heldShift = true end
            elseif event == "key_up" then
                -- deactivate modifier keys
                if param1 == keys.leftCtrl or param1 == keys.rightCtrl then heldCtrl = false
                elseif param1 == keys.leftAlt or param1 == keys.rightAlt then heldAlt = false
                elseif param1 == keys.leftShift or param1 == keys.rightShift then heldShift = false end
            end
        end
    end)
end

--- Draws a line of text at a position.
---@param win window The window to draw on
---@param x number The X position of the left side of the text
---@param y number The Y position of the text
---@param text string The text to draw
---@param fgColor color|nil The color of the text (defaults to white)
---@param bgColor color|nil The color of the background (defaults to black)
function PrimeUI.label(win, x, y, text, fgColor, bgColor)
    expect(1, win, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, text, "string")
    fgColor = expect(5, fgColor, "number", "nil") or colors.white
    bgColor = expect(6, bgColor, "number", "nil") or colors.black
    win.setCursorPos(x, y)
    win.setTextColor(fgColor)
    win.setBackgroundColor(bgColor)
    win.write(text)
end

--- Creates a progress bar, which can be updated by calling the returned function.
---@param win window The window to draw on
---@param x number The X position of the left side of the bar
---@param y number The Y position of the bar
---@param width number The width of the bar
---@param fgColor color|nil The color of the activated part of the bar (defaults to white)
---@param bgColor color|nil The color of the inactive part of the bar (defaults to black)
---@param useShade boolean|nil Whether to use shaded areas for the inactive part (defaults to false)
---@return function redraw A function to call to update the progress of the bar, taking a number from 0.0 to 1.0
function PrimeUI.progressBar(win, x, y, width, fgColor, bgColor, useShade)
    expect(1, win, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, width, "number")
    fgColor = expect(5, fgColor, "number", "nil") or colors.white
    bgColor = expect(6, bgColor, "number", "nil") or colors.black
    expect(7, useShade, "boolean", "nil")
    local function redraw(progress)
        expect(1, progress, "number")
        if progress < 0 or progress > 1 then error("bad argument #1 (value out of range)", 2) end
        -- Draw the active part of the bar.
        win.setCursorPos(x, y)
        win.setBackgroundColor(bgColor)
        win.setBackgroundColor(fgColor)
        win.write((" "):rep(math.floor(progress * width)))
        -- Draw the inactive part of the bar, using shade if desired.
        win.setBackgroundColor(bgColor)
        win.setTextColor(fgColor)
        win.write((useShade and "\x7F" or " "):rep(width - math.floor(progress * width)))
    end
    redraw(0)
    return redraw
end

--- Creates a scrollable window, which allows drawing large content in a small area.
---@param win window The parent window of the scroll box
---@param x number The X position of the box
---@param y number The Y position of the box
---@param width number The width of the box
---@param height number The height of the outer box
---@param innerHeight number The height of the inner scroll area
---@param allowArrowKeys boolean|nil Whether to allow arrow keys to scroll the box (defaults to true)
---@param showScrollIndicators boolean|nil Whether to show arrow indicators on the right side when scrolling is available, which reduces the inner width by 1 (defaults to false)
---@param fgColor number|nil The color of scroll indicators (defaults to white)
---@param bgColor color|nil The color of the background (defaults to black)
---@return window inner The inner window to draw inside
---@return fun(pos:number) scroll A function to manually set the scroll position of the window
function PrimeUI.scrollBox(win, x, y, width, height, innerHeight, allowArrowKeys, showScrollIndicators, fgColor, bgColor)
    expect(1, win, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, width, "number")
    expect(5, height, "number")
    expect(6, innerHeight, "number")
    expect(7, allowArrowKeys, "boolean", "nil")
    expect(8, showScrollIndicators, "boolean", "nil")
    fgColor = expect(9, fgColor, "number", "nil") or colors.white
    bgColor = expect(10, bgColor, "number", "nil") or colors.black
    if allowArrowKeys == nil then allowArrowKeys = true end
    -- Create the outer container box.
    local outer = window.create(win == term and term.current() or win, x, y, width, height)
    outer.setBackgroundColor(bgColor)
    outer.clear()
    -- Create the inner scrolling box.
    local inner = window.create(outer, 1, 1, width - (showScrollIndicators and 1 or 0), innerHeight)
    inner.setBackgroundColor(bgColor)
    inner.clear()
    -- Draw scroll indicators if desired.
    if showScrollIndicators then
        outer.setBackgroundColor(bgColor)
        outer.setTextColor(fgColor)
        outer.setCursorPos(width, height)
        outer.write(innerHeight > height and "\31" or " ")
    end
    -- Get the absolute position of the window.
    x, y = PrimeUI.getWindowPos(win, x, y)
    -- Add the scroll handler.
    local scrollPos = 1
    PrimeUI.addTask(function()
        while true do
            -- Wait for next event.
            local ev = table.pack(os.pullEvent())
            -- Update inner height in case it changed.
            innerHeight = select(2, inner.getSize())
            -- Check for scroll events and set direction.
            local dir
            if ev[1] == "key" and allowArrowKeys then
                if ev[2] == keys.up then dir = -1
                elseif ev[2] == keys.down then dir = 1 end
            elseif ev[1] == "mouse_scroll" and ev[3] >= x and ev[3] < x + width and ev[4] >= y and ev[4] < y + height then
                dir = ev[2]
            end
            -- If there's a scroll event, move the window vertically.
            if dir and (scrollPos + dir >= 1 and scrollPos + dir <= innerHeight - height) then
                scrollPos = scrollPos + dir
                inner.reposition(1, 2 - scrollPos)
            end
            -- Redraw scroll indicators if desired.
            if showScrollIndicators then
                outer.setBackgroundColor(bgColor)
                outer.setTextColor(fgColor)
                outer.setCursorPos(width, 1)
                outer.write(scrollPos > 1 and "\30" or " ")
                outer.setCursorPos(width, height)
                outer.write(scrollPos < innerHeight - height and "\31" or " ")
            end
        end
    end)
    -- Make a function to allow external scrolling.
    local function scroll(pos)
        expect(1, pos, "number")
        pos = math.floor(pos)
        expect.range(pos, 1, innerHeight - height)
        -- Scroll the window.
        scrollPos = pos
        inner.reposition(1, 2 - scrollPos)
        -- Redraw scroll indicators if desired.
        if showScrollIndicators then
            outer.setBackgroundColor(bgColor)
            outer.setTextColor(fgColor)
            outer.setCursorPos(width, 1)
            outer.write(scrollPos > 1 and "\30" or " ")
            outer.setCursorPos(width, height)
            outer.write(scrollPos < innerHeight - height and "\31" or " ")
        end
    end
    return inner, scroll
end

--- Creates a list of entries that can each be selected.
---@param win window The window to draw on
---@param x number The X coordinate of the inside of the box
---@param y number The Y coordinate of the inside of the box
---@param width number The width of the inner box
---@param height number The height of the inner box
---@param entries string[] A list of entries to show, where the value is whether the item is pre-selected (or `"R"` for required/forced selected)
---@param action function|string A function or `run` event that's called when a selection is made
---@param selectChangeAction function|string|nil A function or `run` event that's called when the current selection is changed
---@param fgColor color|nil The color of the text (defaults to white)
---@param bgColor color|nil The color of the background (defaults to black)
function PrimeUI.selectionBox(win, x, y, width, height, entries, action, selectChangeAction, fgColor, bgColor)
    expect(1, win, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, width, "number")
    expect(5, height, "number")
    expect(6, entries, "table")
    expect(7, action, "function", "string")
    expect(8, selectChangeAction, "function", "string", "nil")
    fgColor = expect(9, fgColor, "number", "nil") or colors.white
    bgColor = expect(10, bgColor, "number", "nil") or colors.black
    -- Check that all entries are strings.
    if #entries == 0 then error("bad argument #6 (table must not be empty)", 2) end
    for i, v in ipairs(entries) do
        if type(v) ~= "string" then error("bad item " .. i .. " in entries table (expected string, got " .. type(v), 2) end
    end
    -- Create container window.
    local entrywin = window.create(win, x, y, width, height)
    local selection, scroll = 1, 1
    -- Create a function to redraw the entries on screen.
    local function drawEntries()
        -- Clear and set invisible for performance.
        entrywin.setVisible(false)
        entrywin.setBackgroundColor(bgColor)
        entrywin.clear()
        -- Draw each entry in the scrolled region.
        for i = scroll, scroll + height - 1 do
            -- Get the entry; stop if there's no more.
            local e = entries[i]
            if not e then break end
            -- Set the colors: invert if selected.
            entrywin.setCursorPos(2, i - scroll + 1)
            if i == selection then
                entrywin.setBackgroundColor(fgColor)
                entrywin.setTextColor(bgColor)
            else
                entrywin.setBackgroundColor(bgColor)
                entrywin.setTextColor(fgColor)
            end
            -- Draw the selection.
            entrywin.clearLine()
            entrywin.write(#e > width - 1 and e:sub(1, width - 4) .. "..." or e)
        end
        -- Draw scroll arrows.
        entrywin.setBackgroundColor(bgColor)
        entrywin.setTextColor(fgColor)
        entrywin.setCursorPos(width, 1)
        entrywin.write("\30")
        entrywin.setCursorPos(width, height)
        entrywin.write("\31")
        -- Send updates to the screen.
        entrywin.setVisible(true)
    end
    -- Draw first screen.
    drawEntries()
    -- Add a task for selection keys.
    PrimeUI.addTask(function()
        while true do
            local event, key, cx, cy = os.pullEvent()
            if event == "key" then
                if key == keys.down and selection < #entries then
                    -- Move selection down.
                    selection = selection + 1
                    if selection > scroll + height - 1 then scroll = scroll + 1 end
                    -- Send action if necessary.
                    if type(selectChangeAction) == "string" then PrimeUI.resolve("selectionBox", selectChangeAction, selection)
                    elseif selectChangeAction then selectChangeAction(selection) end
                    -- Redraw screen.
                    drawEntries()
                elseif key == keys.up and selection > 1 then
                    -- Move selection up.
                    selection = selection - 1
                    if selection < scroll then scroll = scroll - 1 end
                    -- Send action if necessary.
                    if type(selectChangeAction) == "string" then PrimeUI.resolve("selectionBox", selectChangeAction, selection)
                    elseif selectChangeAction then selectChangeAction(selection) end
                    -- Redraw screen.
                    drawEntries()
                elseif key == keys.enter then
                    -- Select the entry: send the action.
                    if type(action) == "string" then PrimeUI.resolve("selectionBox", action, entries[selection])
                    else action(entries[selection]) end
                end
            elseif event == "mouse_click" and key == 1 then
                -- Handle clicking the scroll arrows.
                local wx, wy = PrimeUI.getWindowPos(entrywin, 1, 1)
                if cx == wx + width - 1 then
                    if cy == wy and selection > 1 then
                        -- Move selection up.
                        selection = selection - 1
                        if selection < scroll then scroll = scroll - 1 end
                        -- Send action if necessary.
                        if type(selectChangeAction) == "string" then PrimeUI.resolve("selectionBox", selectChangeAction, selection)
                        elseif selectChangeAction then selectChangeAction(selection) end
                        -- Redraw screen.
                        drawEntries()
                    elseif cy == wy + height - 1 and selection < #entries then
                        -- Move selection down.
                        selection = selection + 1
                        if selection > scroll + height - 1 then scroll = scroll + 1 end
                        -- Send action if necessary.
                        if type(selectChangeAction) == "string" then PrimeUI.resolve("selectionBox", selectChangeAction, selection)
                        elseif selectChangeAction then selectChangeAction(selection) end
                        -- Redraw screen.
                        drawEntries()
                    end
                elseif cx >= wx and cx < wx + width - 1 and cy >= wy and cy < wy + height then
                    local sel = scroll + (cy - wy)
                    if sel == selection then
                        -- Select the entry: send the action.
                        if type(action) == "string" then PrimeUI.resolve("selectionBox", action, entries[selection])
                        else action(entries[selection]) end
                    else
                        selection = sel
                        -- Send action if necessary.
                        if type(selectChangeAction) == "string" then PrimeUI.resolve("selectionBox", selectChangeAction, selection)
                        elseif selectChangeAction then selectChangeAction(selection) end
                        -- Redraw screen.
                        drawEntries()
                    end
                end
            elseif event == "mouse_scroll" then
                -- Handle mouse scrolling.
                local wx, wy = PrimeUI.getWindowPos(entrywin, 1, 1)
                if cx >= wx and cx < wx + width and cy >= wy and cy < wy + height then
                    if key < 0 and selection > 1 then
                        -- Move selection up.
                        selection = selection - 1
                        if selection < scroll then scroll = scroll - 1 end
                        -- Send action if necessary.
                        if type(selectChangeAction) == "string" then PrimeUI.resolve("selectionBox", selectChangeAction, selection)
                        elseif selectChangeAction then selectChangeAction(selection) end
                        -- Redraw screen.
                        drawEntries()
                    elseif key > 0 and selection < #entries then
                        -- Move selection down.
                        selection = selection + 1
                        if selection > scroll + height - 1 then scroll = scroll + 1 end
                        -- Send action if necessary.
                        if type(selectChangeAction) == "string" then PrimeUI.resolve("selectionBox", selectChangeAction, selection)
                        elseif selectChangeAction then selectChangeAction(selection) end
                        -- Redraw screen.
                        drawEntries()
                    end
                end
            end
        end
    end)
end

--- Creates a text box that wraps text and can have its text modified later.
---@param win window The parent window of the text box
---@param x number The X position of the box
---@param y number The Y position of the box
---@param width number The width of the box
---@param height number The height of the box
---@param text string The initial text to draw
---@param fgColor color|nil The color of the text (defaults to white)
---@param bgColor color|nil The color of the background (defaults to black)
---@return function redraw A function to redraw the window with new contents
function PrimeUI.textBox(win, x, y, width, height, text, fgColor, bgColor)
    expect(1, win, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, width, "number")
    expect(5, height, "number")
    expect(6, text, "string")
    fgColor = expect(7, fgColor, "number", "nil") or colors.white
    bgColor = expect(8, bgColor, "number", "nil") or colors.black
    -- Create the box window.
    local box = window.create(win, x, y, width, height)
    -- Override box.getSize to make print not scroll.
    function box.getSize()
        return width, math.huge
    end
    -- Define a function to redraw with.
    local function redraw(_text)
        expect(1, _text, "string")
        -- Set window parameters.
        box.setBackgroundColor(bgColor)
        box.setTextColor(fgColor)
        box.clear()
        box.setCursorPos(1, 1)
        -- Redirect and draw with `print`.
        local old = term.redirect(box)
        print(_text)
        term.redirect(old)
    end
    redraw(text)
    return redraw
end

--- Runs a function or action after the specified time period, with optional canceling.
---@param time number The amount of time to wait for, in seconds
---@param action function|string The function to call when the timer completes, or a `run` event to send
---@return function cancel A function to cancel the timer
function PrimeUI.timeout(time, action)
    expect(1, time, "number")
    expect(2, action, "function", "string")
    -- Start the timer.
    local timer = os.startTimer(time)
    -- Add a task to wait for the timer.
    PrimeUI.addTask(function()
        while true do
            -- Wait for a timer event.
            local _, tm = os.pullEvent("timer")
            if tm == timer then
                -- Fire the timer action.
                if type(action) == "string" then PrimeUI.resolve("timeout", action)
                else action() end
            end
        end
    end)
    -- Return a function to cancel the timer.
    return function() os.cancelTimer(timer) end
end

--- Creates a clickable, toggleable button on screen with text.
---@param win window The window to draw on
---@param x number The X position of the button
---@param y number The Y position of the button
---@param textOn string The text to draw on the button when on
---@param textOff string The text to draw on the button when off (must be the same length as textOn)
---@param action function|string A function to call when clicked, or a string to send with a `run` event
---@param fgColor color|nil The color of the button text (defaults to white)
---@param bgColor color|nil The color of the button (defaults to light gray)
---@param clickedColor color|nil The color of the button when clicked (defaults to gray)
---@param periphName string|nil The name of the monitor peripheral, or nil (set if you're using a monitor - events will be filtered to that monitor)
function PrimeUI.toggleButton(win, x, y, textOn, textOff, action, fgColor, bgColor, clickedColor, periphName)
    expect(1, win, "table")
    expect(1, win, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, textOn, "string")
    expect(5, textOff, "string")
    if #textOn ~= #textOff then error("On and off text must be the same length", 2) end
    expect(6, action, "function", "string")
    fgColor = expect(7, fgColor, "number", "nil") or colors.white
    bgColor = expect(8, bgColor, "number", "nil") or colors.gray
    clickedColor = expect(9, clickedColor, "number", "nil") or colors.lightGray
    periphName = expect(10, periphName, "string", "nil")
    -- Draw the initial button.
    win.setCursorPos(x, y)
    win.setBackgroundColor(bgColor)
    win.setTextColor(fgColor)
    win.write(" " .. textOff .. " ")
    local state = false
    -- Get the screen position and add a click handler.
    PrimeUI.addTask(function()
        local screenX, screenY = PrimeUI.getWindowPos(win, x, y)
        local buttonDown = false
        while true do
            local event, button, clickX, clickY = os.pullEvent()
            if event == "mouse_click" and periphName == nil and button == 1 and clickX >= screenX and clickX < screenX + #textOn + 2 and clickY == screenY then
                -- Initiate a click action (but don't trigger until mouse up).
                buttonDown = true
                -- Redraw the button with the clicked background color.
                win.setCursorPos(x, y)
                win.setBackgroundColor(clickedColor)
                win.setTextColor(fgColor)
                win.write(" " .. (state and textOn or textOff) .. " ")
            elseif (event == "monitor_touch" and periphName == button and clickX >= screenX and clickX < screenX + #textOn + 2 and clickY == screenY)
                or (event == "mouse_up" and button == 1 and buttonDown) then
                -- Finish a click event.
                state = not state
                if clickX >= screenX and clickX < screenX + #textOn + 2 and clickY == screenY then
                    -- Trigger the action.
                    if type(action) == "string" then
                        PrimeUI.resolve("toggleButton", action, state)
                    else
                        action(state)
                    end
                end
                -- Redraw the original button state.
                win.setCursorPos(x, y)
                win.setBackgroundColor(bgColor)
                win.setTextColor(fgColor)
                win.write(" " .. (state and textOn or textOff) .. " ")
            end
        end
    end)
end

--- Draws a vertical line at a position with the specified height.
---@param win window The window to draw on
---@param x number The X position of the line
---@param y number The Y position of the top of the line
---@param height number The height of the line
---@param right boolean|nil Whether to align the line to the right instead of the left (defaults to false)
---@param fgColor color|nil The color of the line (defaults to white)
---@param bgColor color|nil The color of the background (defaults to black)
function PrimeUI.verticalLine(win, x, y, height, right, fgColor, bgColor)
    expect(1, win, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, height, "number")
    right = expect(5, right, "boolean", "nil") or false
    fgColor = expect(6, fgColor, "number", "nil") or colors.white
    bgColor = expect(7, bgColor, "number", "nil") or colors.black
    -- Use drawing characters to draw a thin line.
    win.setTextColor(right and bgColor or fgColor)
    win.setBackgroundColor(right and fgColor or bgColor)
    for j = 1, height do
        win.setCursorPos(x, y + j - 1)
        win.write("\x95")
    end
end

-- YOUR CODE HERE
return PrimeUI