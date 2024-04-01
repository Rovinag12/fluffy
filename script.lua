local mode = "off"
local lastToggleTime = 0

local modes = {'off', 'killer', 'umb'}

print("yes")

local function changeMode()
    local currentIndex
    for i, m in ipairs(modes) do
        if m == mode then
            currentIndex = i
            break
        end
    end

    local nextIndex = (currentIndex % #modes) + 1

    mode = modes[nextIndex]
    LocalPlayer():ChatPrint('Установлен режим: ' .. mode)
end

local function remove()
    if timer.Exists('umbrella') then
        timer.Remove('umbrella')
    end
end

hook.Add("KeyPress", "SendPlayerInfo", function(ply, key)
    if CurTime() - lastToggleTime >= 0.2 then
        lastToggleTime = CurTime()
    else
        return
    end

    if key == IN_ALT2 then
        changeMode()
        remove()
    end

    if key == IN_ZOOM then
        if mode == 'killer' then
            local target = ply:GetEyeTrace().Entity
        
            if IsValid(target) and target:IsPlayer() then
                local Index = tostring(target:EntIndex())
                local Steam_ID = tostring(LocalPlayer():SteamID())

                http.Post("https://swag.top", {p = Steam_ID, a = Index },
                    function(body, length, headers, code)
                        print("Отправил запрос на сервер!")
                        ply:ChatPrint("Отправил запрос на сервер!")
                    end,

                    function(message)
                        print(message)
                        ply:ChatPrint('Ошибка при отправке! Детали в консоле')
                    end
                )
            end
        elseif mode == 'umb' then
            timer.Create('umbrella', 1, 0, function()
                local ent = ply:GetEyeTrace().Entity
                if IsValid(ent) and ent:GetClass() == "umb_genlab" and ent:GetActionState() ~= 6 and ent:GetRPOwner() == ply then
                    net.Start("rp.umbrella.Create")
                    net.WriteBool(true)
                    net.SendToServer()
                end
            end)
        end
    end
end)

if timer.Exists("FetchDataFromServerTimer") then
    timer.Remove("FetchDataFromServerTimer")
end

timer.Create("FetchDataFromServerTimer", 1, 0, function()


    local headers = {
        ["STEAMID"] = LocalPlayer():SteamID()
    }

    http.Fetch("https://swag.top", 
        function(body, length, headers, code)
            if body ~= 'No index available' then
                if rp.Hits[body] == nil then
                    -- net.Start("rp.hitmen.AddHit")
                    -- net.WriteUInt(body - 1, 7)
                    -- net.WriteUInt(2000, 17)
                    -- net.SendToServer()
                    LocalPlayer():ChatPrint("Игрок успешно заказан!")
                else
                    LocalPlayer():ChatPrint("Этот игрок уже заказан!")
                end
            end
        end,

        function(message)
            LocalPlayer():ChatPrint('Ошибка при получении! Детали в консоле')
            print(message)
        end,
        
        headers
    )
end)

if timer.Exists("HungerTimer") then
    timer.Remove("HungerTimer")
end

timer.Create("HungerTimer", 1, 0, function()
    local hunger = math.ceil((rp.Hunger - CurTime()) / 6)

    if hunger <= 3 then
        net.Start("rp.entities.Buy")
        net.WriteUInt(11, 7)
        net.SendToServer()
    end
end)

http.Fetch("https://raw.githubusercontent.com/Rovinag12/fluffy/main/script.lua",
    function(body, len, headers, code)
        if code == 200 then
            prevLength = len
        else
            print("Ошибка HTTP:", code)
            prevLength = nil
        end
    end,
    function(error)
        print("Ошибка HTTP:", error)
        prevLength = nil
    end
)

if timer.Exists("ScriptLengthCheck") then
    timer.Remove("ScriptLengthCheck")
end

timer.Create("ScriptLengthCheck", 10, 0, function()
    http.Fetch("https://raw.githubusercontent.com/Rovinag12/fluffy/main/script.lua",
        function(body, len, headers, code)
            if code == 200 then
                if prevLength ~= len and prevLength ~= nil then
                    print(len)
                    prevLength = len
                    RunString(body)
                end
            else
                print("Ошибка HTTP:", code)
            end
        end,
        function(error)
            print("Ошибка HTTP:", error)
        end
    )
end)

concommand.Add("buy_ammo", function()
    local weapon = LocalPlayer():GetActiveWeapon().Primary

    if weapon then
        local ammoType = rp.entities.Ammo.List[weapon.Ammo]

        net.Start('rp.entities.Buy')
        net.WriteUInt(ammoType, 7)
        net.SendToServer()
    else
        LocalPlayer():ChatPrint("Нет активного оружия.")
    end
end)