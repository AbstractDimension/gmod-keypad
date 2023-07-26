util.AddNetworkString( "KeypadConfig" )
util.AddNetworkString( "KeypadConfigAll" )

CreateConVar( "keypad_min_granted_hold_lenght", 5, { FCVAR_ARCHIVE }, "Minimum time a keypad will stay open when its opened.", 0 )
CreateConVar( "keypad_max_granted_initial_lenght", 3, { FCVAR_ARCHIVE }, "Maximum time a keypad will wait to open after its granted.", 0 )

net.Receive( "KeypadConfig", function( _, ply )
    local keypad = net.ReadEntity()
    local config = net.ReadTable()

    if not IsValid( keypad ) or not keypad.IsKeypad then return end
    if ply ~= keypad:GetKeypadOwner() then return end

    keypad.AllowedPlayers = keypad.AllowedPlayers or {}

    local plyCount = game.MaxPlayers()
    local count = 0

    for steamid, bool in pairs( config ) do
        count = count + 1
        if count > plyCount then break end

        local idPly = player.GetBySteamID( steamid )
        if IsValid( idPly ) then
            keypad.AllowedPlayers[steamid] = bool
        end
    end
end )

net.Receive( "KeypadConfigAll", function( _, ply )
    ply.KeypadConfigAllCooldown = ply.KeypadConfigAllCooldown or 0
    if ply.KeypadConfigAllCooldown > CurTime() then return end
    ply.KeypadConfigAllCooldown = CurTime() + 0.5

    local config = net.ReadTable()
    local allowedPlayers = {}

    local plyCount = game.MaxPlayers()
    local count = 0

    for steamid, bool in pairs( config ) do
        count = count + 1
        if count > plyCount then break end

        local idPly = player.GetBySteamID( steamid )
        if IsValid( idPly ) then
            allowedPlayers[steamid] = bool
        end
    end

    for _, keypad in ipairs( ents.FindByClass( "keypad*" ) ) do
        if IsValid( keypad ) and keypad.IsKeypad and ply == keypad:GetKeypadOwner() then
            keypad.AllowedPlayers = allowedPlayers
        end
    end
end )
