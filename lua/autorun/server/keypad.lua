util.AddNetworkString( "KeypadOpenConfig" )
util.AddNetworkString( "KeypadConfig" )
util.AddNetworkString( "KeypadConfigAll" )
util.AddNetworkString( "Keypad_Command" )

CreateConVar( "keypad_min_granted_hold_lenght", 5, { FCVAR_ARCHIVE }, "Minimum time a keypad will stay open when its opened.", 0 )
CreateConVar( "keypad_max_granted_initial_lenght", 3, { FCVAR_ARCHIVE }, "Maximum time a keypad will wait to open after its granted.", 0 )

net.Receive( "KeypadOpenConfig", function( _, ply )
    local keypad = net.ReadEntity()
    if not IsValid( keypad ) or not keypad.IsKeypad then return end

    if ply ~= keypad:GetKeypadOwner() then return end

    net.Start( "KeypadOpenConfig" )
        net.WriteEntity( keypad )
        net.WriteTable( keypad.AllowedPlayers )
        net.WriteBool( keypad.AllowSquadMembers)
    net.Send( ply )
end )

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
        local owner = ent:GetKeypadOwner()

        if owner == ply then
            ent:Process( true )
            return
        end

        local steamid = ply:SteamID()
        if ent.AllowedPlayers[steamid] then
            ent:Process( true )
            return
        end

        local squadID = owner:GetSquadID()
        if ent.AllowSquadMembers and squadID != -1 then
            local members = SquadMenu:GetSquad(squadID).membersById
            for memberID, _ in pairs(members) do
                if memberID == ply:SteamID() then
                    ent:Process( true )
                    return
                end
            end
        end

        ent:Process( false )
    end
end )

local function validateConfigTable( tbl )
    local config = {}
    local plyCount = game.MaxPlayers()
    local count = 0

    for steamid, bool in pairs( tbl ) do
        count = count + 1
        if count > plyCount then break end

        local idPly = player.GetBySteamID( steamid ) or player.GetByID( tonumber( steamid ) )
        if IsValid( idPly ) then
            config[steamid] = bool
        end
    end

    return config
end

net.Receive( "KeypadConfig", function( _, ply )
    local keypad = net.ReadEntity()
    local config = net.ReadTable()
    local allowSquadMembers = net.ReadBool()

    if not IsValid( keypad ) or not keypad.IsKeypad then return end
    if ply ~= keypad:GetKeypadOwner() then return end

    local allowedPlayers = validateConfigTable( config )
    keypad.AllowedPlayers = allowedPlayers
    keypad.AllowSquadMembers = allowSquadMembers
end )

net.Receive( "KeypadConfigAll", function( _, ply )
    ply.KeypadConfigAllCooldown = ply.KeypadConfigAllCooldown or 0
    if ply.KeypadConfigAllCooldown > CurTime() then return end
    ply.KeypadConfigAllCooldown = CurTime() + 0.25

    local config = net.ReadTable()
    local allowedPlayers = validateConfigTable( config )
    local allowSquadMembers = net.ReadBool()

    for _, keypad in ipairs( ents.FindByClass( "keypad*" ) ) do
        if IsValid( keypad ) and keypad.IsKeypad and ply == keypad:GetKeypadOwner() then
            keypad.AllowedPlayers = allowedPlayers
            keypad.AllowSquadMembers = allowSquadMembers
        end
    end
end )
