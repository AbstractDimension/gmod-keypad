util.AddNetworkString( "KeypadConfig" )
util.AddNetworkString( "KeypadConfigAll" )

CreateConVar( "keypad_min_granted_hold_lenght", 5, { FCVAR_ARCHIVE }, "Minimum time a keypad will stay open when its opened.", 0 )
CreateConVar( "keypad_max_granted_initial_lenght", 3, { FCVAR_ARCHIVE }, "Maximum time a keypad will wait to open after its granted.", 0 )

util.AddNetworkString( "Keypad_Command" )

net.Receive( "Keypad_Command", function( _, ply )
    local ent = net.ReadEntity()
    if not IsValid( ent ) then return end

    local class = ent:GetClass()
    if class ~= "keypad" and class ~= "keypad_wire" then return end

    if ent:GetKeypadStatus() ~= ent.Status_None then return end
    if ply:EyePos():Distance( ent:GetPos() ) >= 120 then return end

    if ent.Next_Command_Time and ent.Next_Command_Time > CurTime() then return end
    ent.Next_Command_Time = CurTime() + 0.05

    local command = net.ReadUInt( 4 )

    if command == ent.Command_Enter then
        local val = tonumber( ent:GetValue() .. net.ReadUInt( 8 ) )

        if val and val > 0 and val <= 9999 then
            ent:SetValue( tostring( val ) )
            ent:EmitSound( "buttons/button15.wav" )
        end
        return
    end

    if command == ent.Command_Abort then
        ent:SetValue( "" )
        return
    end

    if command == ent.Command_Accept then
        if ent:GetValue() == ent:GetPassword() then
            ent:Process( true )
        else
            ent:Process( false )
        end

        return
    end

    if command == ent.Command_ID then
        if ent:GetKeypadOwner() == ply then
            ent:Process( true )
            return
        end

        local steamid = ply:SteamID()
        if ent.AllowedPlayers[steamid] then
            ent:Process( true )
            return
        end

        ent:Process( false )
    end
end )

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
