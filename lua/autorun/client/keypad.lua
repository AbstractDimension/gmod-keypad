local backColor = Color( 40, 40, 40 )
local frontColor = Color( 60, 60, 60 )
local buttonColor = Color( 50, 50, 50 )
local buttonHoverColor = Color( 80, 80, 80 )
local textColor = Color( 255, 255, 255 )
local green = Color( 0, 255, 0 )
local darkGreen = Color( 0, 200, 0 )
local red = Color( 255, 0, 0 )
local darkRed = Color( 200, 0, 0 )

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

net.Receive( "KeypadOpenConfig", function()
    local ent = net.ReadEntity()
    local playerConfigs = net.ReadTable()

    if not IsValid( ent ) or not ent.IsKeypad then return end

    local frame = vgui.Create( "DFrame" )
    frame:SetSize( 300, 400 )
    frame:Center()
    frame:SetTitle( "Keypad Config" )
    frame:MakePopup()
    function frame:Paint( w, h )
        draw.RoundedBox( 0, 0, 0, w, h, backColor )

        draw.RoundedBox( 0, 0, 0, w, 25, frontColor )
    end

    -- List of all players and if they're allowed or not
    local scroll = vgui.Create( "DScrollPanel", frame )
    scroll:Dock( FILL )
    function scroll:PaintOver( w, h )
        -- Separator
        draw.RoundedBox( 0, w - 16, 0, 2, h, backColor )
    end

    local bar = scroll:GetVBar()
    bar:SetHideButtons( true )
    function bar:Paint( w, h )
        draw.RoundedBox( 0, 0, 0, w, h, buttonColor )
    end

    local grip = bar.btnGrip
    function grip:Paint( w, h )
        draw.RoundedBox( 0, w - 20, 0, 5, h, Color( 255, 0, 0 ) )
        draw.RoundedBox( 0, 0, 0, w, h, frontColor )
    end

    local listLayout = vgui.Create( "DListLayout", scroll )
    listLayout:Dock( FILL )

    local function addPlayer( ply, allowed )
        local panel = vgui.Create( "DPanel", listLayout )
        panel:SetTall( 20 )
        panel:Dock( TOP )
        panel:DockMargin( 0, 0, 0, 4 )
        function panel:Paint( w, h )
            draw.RoundedBox( 0, 0, 0, w, h, buttonColor )
        end
        panel.playerName = string.lower( ply:Nick() )

        local checkbox = vgui.Create( "DCheckBox", panel )
        checkbox:Dock( LEFT )
        checkbox:SetWide( 20 )
        checkbox:SetTall( 20 )
        checkbox:SetValue( allowed )
        function checkbox:Paint( w, h )
            -- outlines for the checkbox
            draw.RoundedBox( 0, 0, 0, w, h, buttonColor )
            local isHovered = self:IsHovered()
            if self:GetChecked() then
                if isHovered then
                    draw.RoundedBox( 3, 2, 2, w - 4, h - 4, darkGreen )
                else
                    draw.RoundedBox( 3, 2, 2, w - 4, h - 4, green )
                end
            else
                if isHovered then
                    draw.RoundedBox( 3, 2, 2, w - 4, h - 4, darkRed )
                else
                    draw.RoundedBox( 3, 2, 2, w - 4, h - 4, red )
                end
            end
        end

        function checkbox:OnChange( val )
            local id = ply:SteamID()
            if ply:IsBot() then
                id = ply:EntIndex()
            end

            playerConfigs[id] = val
        end

        local label = vgui.Create( "DLabel", panel )
        label:Dock( FILL )
        label:DockMargin( 5, 0, 0, 0 )
        label:SetText( ply:Nick() )
        label:SetTextColor( textColor )
    end

    local buttonAll = vgui.Create( "DButton", frame )
    buttonAll:Dock( BOTTOM )
    buttonAll:SetText( "Apply to all keypads" )
    buttonAll:SetTextColor( textColor )
    function buttonAll:DoClick()
        net.Start( "KeypadConfigAll" )
        net.WriteTable( playerConfigs )
        net.SendToServer()

        frame:Close()
    end
    function buttonAll:Paint( w, h )
        draw.RoundedBox( 0, 0, 0, w, h, backColor )
        if self:IsHovered() then
            draw.RoundedBox( 0, 0, 2, w, h - 2, buttonHoverColor )
            return
        end
        draw.RoundedBox( 0, 0, 2, w, h - 2, frontColor )
    end

    local buttonApply = vgui.Create( "DButton", frame )
    buttonApply:Dock( BOTTOM )
    buttonApply:SetText( "Apply" )
    buttonApply:SetTextColor( textColor )
    function buttonApply:DoClick()
        net.Start( "KeypadConfig" )
        net.WriteEntity( ent )
        net.WriteTable( playerConfigs )
        net.SendToServer()

        frame:Close()
    end
    function buttonApply:Paint( w, h )
        draw.RoundedBox( 0, 0, 0, w, h, backColor )
        if self:IsHovered() then
            draw.RoundedBox( 0, 0, 2, w, h - 2, buttonHoverColor )
            return
        end
        draw.RoundedBox( 0, 0, 2, w, h - 2, frontColor )
    end

    -- Searchbar
    local search = vgui.Create( "DTextEntry", frame )
    search:Dock( TOP )
    search:DockMargin( 0, 0, 0, 4 )
    search:SetPlaceholderText( "Search..." )
    search:SetTextColor( textColor )
    search:SetPaintBackground( false )
    function search:OnChange()
        local val = string.lower( self:GetValue() )
        if val == "" then
            for _, panel in ipairs( listLayout:GetChildren() ) do
                panel:SetVisible( true )
            end
            listLayout:InvalidateLayout()
            return
        end

        for _, panel in ipairs( listLayout:GetChildren() ) do
            local name = panel.playerName

            if string.find( name, val, nil, true ) then
                panel:SetVisible( true )
            else
                panel:SetVisible( false )
            end
        end
        listLayout:InvalidateLayout()
    end
    function search:Paint( w, h )
        draw.RoundedBox( 0, 0, 0, w, h, frontColor )
        if self:GetValue() == "" then
            draw.SimpleText( self:GetPlaceholderText(), "DermaDefault", 3, 3, textColor )
        end
        self:DrawTextEntryText( textColor, textColor, textColor )
    end

    -- Add all players
    local sortedConfig = {}

    for _, ply in ipairs( player.GetAll() ) do
        if ply ~= LocalPlayer() then
            local id = ply:SteamID()
            if ply:IsBot() then
                id = ply:EntIndex()
            end
            if playerConfigs[id] then
                table.insert( sortedConfig, 1, { ply = ply, allowed = true } )
            else
                table.insert( sortedConfig, { ply = ply, allowed = false } )
            end
        end
    end

    for _, data in ipairs( sortedConfig ) do
        addPlayer( data.ply, data.allowed )
    end
end )
