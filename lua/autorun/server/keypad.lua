util.AddNetworkString( "KeypadConfig" )

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
