-- surface.PlaySound("arc9_eft_shared/weapon_generic_spin"..math.random(1,10)..".ogg")
-- surface.PlaySound("arc9_eft_shared/weapon_generic_rifle_spin"..math.random(10)..".ogg")

if CLIENT then
    local isOpen = false
    local selected = nil
    local currentWeaponClass = nil

    local lastHoveredClass = nil

    local animateStates = {}
    local hoverScales = {}

    local blacklist = {}

    local function GetFilteredWeapons()
        local weps = {}
        local centerWep = nil
        local ply = LocalPlayer()
        if not IsValid(ply) then return weps end

        local class = string.Trim('weapon_hands_sh')
        if class ~= "" then
            local wep = ply:GetWeapon(class)
            if IsValid(wep) and not blacklist[class] then
                centerWep = wep
            end
        end

        for _, wep in ipairs(ply:GetWeapons()) do
            local cls = wep:GetClass()
            if not blacklist[cls] and (not centerWep or cls ~= centerWep:GetClass()) then
                table.insert(weps, wep)
            end
        end

        if centerWep then
            table.insert(weps, 1, centerWep)
        end

        return weps
    end

    local function SwitchToWeapon(class)
        if not class then return end
        local ply = LocalPlayer()
        if ply:HasWeapon(class) then
            local active = ply:GetActiveWeapon()
            if IsValid(active) then
                ply.LastInv = active
            end

            RunConsoleCommand("use", class)
        end
    end

    hook.Add("Think", "RadialMenuKeybind", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local keynum = { KEY_1, MOUSE_MIDDLE }
        local down = false
        for k, v in pairs( keynum ) do
            down = down or input.IsButtonDown( v )
        end

        local inSpawn = spawnmenu and spawnmenu.IsVisible and spawnmenu:IsVisible()
        local inConsole = gui.IsConsoleVisible()
        local inGameUI = gui.IsGameUIVisible()
        local inChat = chat and chat.IsTyping and chat.IsTyping()
        local hasFocus = vgui.GetKeyboardFocus() ~= nil

        if down and ply:Alive() and not ply:InVehicle() and not inSpawn and not inConsole and not inGameUI and not inChat and not hasFocus then
            if not isOpen then
                isOpen = true
                animateStates = {}
                surface.PlaySound("arc9_eft_shared/weapon_generic_rifle_spin"..math.random(10)..".ogg")
                gui.EnableScreenClicker(true)
                local active = ply:GetActiveWeapon()
                if IsValid(active) then
                    currentWeaponClass = active:GetClass()
                end
            end
        else
            if isOpen then
                isOpen = false
                gui.EnableScreenClicker(false)
                if selected and IsValid(ply) then
                    local cls = selected:GetClass()
                    if cls ~= currentWeaponClass then
                        surface.PlaySound("arc9_eft_shared/weapon_generic_spin"..math.random(1,10)..".ogg")
                        SwitchToWeapon(cls)
                    end
                end
                selected = nil
            end
        end
    end)

    hook.Add("HUDPaint", "DrawRadialMenu", function()
        if not isOpen then return end
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() or ply:InVehicle() then return end

        local items = GetFilteredWeapons()
        if #items == 0 then return end

        local sw, sh = ScrW(), ScrH()
        local cx, cy = sw * 0.5, sh * 0.5
        local mx, my = gui.MousePos()

        local boxsc = math.Clamp(2, 0.5, 6)
        local r = math.Clamp(120 + (#items * 8), 80, math.min(sw, sh) * 0.5 - 50)
        local step = (#items > 1) and 360 / (#items - 1) or 360
        local centerEnabled = 1

        surface.SetFont("RadialFont")

        local closestDist, hovered = math.huge, nil
        for i, wep in ipairs(items) do
            local id = wep:GetClass()
            local state = animateStates[id] or { posFrac = 0, alphaFrac = 0 }
            animateStates[id] = state

            state.posFrac = Lerp(FrameTime() * 10, state.posFrac, 1)
            state.alphaFrac = Lerp(FrameTime() * 5, state.alphaFrac, 1)

            local isCenter = centerEnabled and (i == 1)
            local ang = isCenter and 0 or math.rad((i - 2) * step - 90)
            local tx = isCenter and cx or (cx + math.cos(ang) * r * state.posFrac)
            local ty = isCenter and cy or (cy + math.sin(ang) * r * state.posFrac)

            local disp = wep:GetPrintName()
            local tw, th = surface.GetTextSize(disp)

            hoverScales[id] = Lerp(FrameTime() * 10, hoverScales[id] or 0, (wep == selected) and 1 or 0)
            local sc = 1 + hoverScales[id] * 0.3

            local function DrawFilledCircle(x, y, radius, segments, color)
                local vertices = {}
                table.insert(vertices, { x = x, y = y })
                for i = 0, segments do
                    local angle = math.rad((i / segments) * 360)
                    table.insert(vertices, {
                        x = x + math.cos(angle) * radius,
                        y = y + math.sin(angle) * radius
                    })
                end
                draw.NoTexture()
                surface.SetDrawColor(color)
                surface.DrawPoly(vertices)
            end

            if isCenter then
                local radOutline = math.max(tw, th) * 0.5 * sc * 2 + 3
                local fillColor

                if wep == selected then
                    fillColor = Color(hg.VGUI.MainColor.r, hg.VGUI.MainColor.g, hg.VGUI.MainColor.b, 240 * state.alphaFrac)
                else
                    fillColor = Color(0, 0, 0, 240 * state.alphaFrac)
                end

                draw.NoTexture()
                surface.SetDrawColor(fillColor)
                DrawFilledCircle(tx, ty, radOutline, 32, fillColor)

                draw.SimpleTextOutlined(disp, "RadialFont", tx, ty, Color(255, 255, 255, 225000 * state.alphaFrac), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, .6, color_black)
            else
                local padX = 4 * 6 * sc
                local padY = 2 * 6 * sc
                local w, h = tw * sc, th * sc
                local boxColor
                if wep == selected then
                    boxColor = Color(hg.VGUI.MainColor.r, hg.VGUI.MainColor.g, hg.VGUI.MainColor.b, 240 * state.alphaFrac)
                else
                    boxColor = Color(0, 0, 0, 240 * state.alphaFrac)
                end

                draw.RoundedBox(4, tx - w * 0.5 - padX, ty - h * 0.5 - padY, w + padX * 2, h + padY * 2, boxColor)
                draw.SimpleTextOutlined(disp, "RadialFont", tx, ty - 2, Color(255, 255, 255, 255 * state.alphaFrac), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, .6, color_black)
            end
        end

        -- Determine hovered after drawing (optional but safer)
        local closestDist2, hovered2 = math.huge, nil
        for i, wep in ipairs(items) do
            local isCenter = centerEnabled and (i == 1)
            local ang = isCenter and 0 or math.rad((i - 2) * step - 90)
            local tx = isCenter and cx or (cx + math.cos(ang) * r)
            local ty = isCenter and cy or (cy + math.sin(ang) * r)
            local d = math.Distance(mx, my, tx, ty)
            if d < 100 and d < closestDist2 then
                closestDist2, hovered2 = d, wep
            end
        end

        if hovered2 ~= selected then
            if hovered2 then
                surface.PlaySound("arc9_eft_shared/weapon_generic_rifle_spin"..math.random(10)..".ogg")
            end
            selected = hovered2
        end

        if not selected then
            lastHoveredClass = nil
        else
            lastHoveredClass = selected:GetClass()
        end
    end)

    hook.Add("PlayerBindPress", "RadialMenuLastinv", function(ply, bind, pressed)
        if not pressed or not IsValid(ply) then return end
        if string.find(bind, "lastinv") and IsValid(LocalPlayer().LastInv) then
            SwitchToWeapon(LocalPlayer().LastInv:GetClass())
            return true
        end
    end)
end