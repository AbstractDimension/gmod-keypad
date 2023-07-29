hook.Add( "PlayerBindPress", "Keypad", function( ply, bind, pressed )
    if not pressed then return end

    local tr = util.TraceLine( {
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:GetAimVector() * 65,
        filter = ply
    } )

    local ent = tr.Entity
    if not IsValid( ent ) or not ent.IsKeypad then return end

    if string.find( bind, "+use", nil, true ) then
        local element = ent:GetHoveredElement()
        if not element or not element.click then return end
        element.click( ent )
    end
end )

local physical_keypad_commands = {
    [KEY_ENTER] = function( self )
        self:SendCommand( self.Command_Accept )
    end,
    [KEY_PAD_ENTER] = function( self )
        self:SendCommand( self.Command_Accept )
    end,
    [KEY_PAD_MINUS] = function( self )
        self:SendCommand( self.Command_Abort )
    end,
    [KEY_PAD_PLUS] = function( self )
        self:SendCommand( self.Command_Abort )
    end
}

for i = KEY_PAD_1, KEY_PAD_9 do
    physical_keypad_commands[i] = function( self )
        self:SendCommand( self.Command_Enter, i - KEY_PAD_1 + 1 )
    end
end

local last_press = 0
local enter_strict = CreateConVar( "keypad_willox_enter_strict", "0", FCVAR_ARCHIVE, "Only allow the numpad's enter key to be used to accept keypads' input" )

hook.Add( "CreateMove", "Keypad", function()
    if RealTime() - 0.1 < last_press then return end

    for key, handler in pairs( physical_keypad_commands ) do
        if input.WasKeyPressed( key ) then
            if enter_strict:GetBool() and key == KEY_ENTER then continue end
            local ply = LocalPlayer()

            local tr = util.TraceLine( {
                start = ply:EyePos(),
                endpos = ply:EyePos() + ply:GetAimVector() * 65,
                filter = ply
            } )

            local ent = tr.Entity
            if not IsValid( ent ) or not ent.IsKeypad then return end
            last_press = RealTime()
            handler( ent )

            return
        end
    end
end )

concommand.Add( "keypad_config", function( lply )
    local ent = lply:GetEyeTrace().Entity
    if not IsValid( ent ) or not ent.IsKeypad then return end
    if lply ~= ent:GetKeypadOwner() then return end

    ent.AllowedPlayers = ent.AllowedPlayers or {}

    local frame = vgui.Create( "DFrame" )
    frame:SetSize( 300, 400 )
    frame:Center()
    frame:SetTitle( "Keypad Config" )
    frame:MakePopup()
    frame.AllowedPlayersCache = table.Copy( ent.AllowedPlayers )

    -- List of all players and if they're allowed or not
    local scroll = vgui.Create( "DScrollPanel", frame )
    scroll:Dock( FILL )

    local listLayout = vgui.Create( "DListLayout", scroll )
    listLayout:Dock( FILL )

    local function addPlayer( ply, allowed )
        local panel = vgui.Create( "DPanel", listLayout )
        panel:SetTall( 20 )
        panel:Dock( TOP )
        panel:DockMargin( 0, 0, 0, 4 )
        function panel:Paint( w, h )
            draw.RoundedBox( 0, 0, 0, w, h, Color( 100, 100, 100 ) )
        end
        panel.playerName = string.lower( ply:Nick() )

        local checkbox = vgui.Create( "DCheckBox", panel )
        checkbox:Dock( LEFT )
        checkbox:SetWide( 20 )
        checkbox:SetTall( 20 )
        checkbox:SetValue( allowed )
        function checkbox:Paint( w, h )
            -- outlines for the checkbox
            draw.RoundedBox( 10, 0, 0, w, h, Color( 0, 0, 0 ) )
            if self:GetChecked() then
                draw.RoundedBox( 10, 2, 2, w - 4, h - 4, Color( 0, 255, 0 ) )
            else
                draw.RoundedBox( 10, 2, 2, w - 4, h - 4, Color( 255, 0, 0 ) )
            end
        end

        function checkbox:OnChange( val )
            local id = ply:SteamID()
            if ply:IsBot() then
                id = ply:EntIndex()
            end
            frame.AllowedPlayersCache[id] = val
        end

        local label = vgui.Create( "DLabel", panel )
        label:Dock( FILL )
        label:DockMargin( 5, 0, 0, 0 )
        label:SetText( ply:Nick() )
        label:SetTextColor( Color( 255, 255, 255 ) )
    end

    for _, ply in ipairs( player.GetAll() ) do
        if ply ~= lply then
            if ply:IsBot() then
                addPlayer( ply, ent.AllowedPlayers[ply:EntIndex()] )
            else
                addPlayer( ply, ent.AllowedPlayers[ply:SteamID()] )
            end
        end
    end

    local buttonAll = vgui.Create( "DButton", frame )
    buttonAll:Dock( BOTTOM )
    buttonAll:SetText( "Apply to all keypads" )
    function buttonAll:DoClick()
        ent.AllowedPlayers = frame.AllowedPlayersCache

        net.Start( "KeypadConfigAll" )
        net.WriteTable( ent.AllowedPlayers )
        net.SendToServer()

        for _, keypad in ipairs( ents.FindByClass( "keypad*" ) ) do
            if IsValid( keypad ) and keypad.IsKeypad and lply == keypad:GetKeypadOwner() then
                keypad.AllowedPlayers = frame.AllowedPlayersCache
            end
        end

        frame:Close()
    end

    local button = vgui.Create( "DButton", frame )
    button:Dock( BOTTOM )
    button:SetText( "Apply" )
    function button:DoClick()
        ent.AllowedPlayers = frame.AllowedPlayersCache

        net.Start( "KeypadConfig" )
        net.WriteEntity( ent )
        net.WriteTable( ent.AllowedPlayers )
        net.SendToServer()

        frame:Close()
    end

    -- Searchbar
    local search = vgui.Create( "DTextEntry", frame )
    search:Dock( TOP )
    search:DockMargin( 0, 0, 0, 4 )
    search:SetPlaceholderText( "Search..." )

    function search:OnChange()
        local val = self:GetValue()
        for _, panel in ipairs( listLayout:GetChildren() ) do
            local name = panel.playerName

            if string.find( name, string.lower( val ), nil, true ) then
                panel:SetVisible( true )
            else
                panel:SetVisible( false )
            end
        end
        listLayout:InvalidateLayout()
    end
end )
