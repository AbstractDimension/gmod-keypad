local render_SetMaterial = render.SetMaterial
local render_DrawBox = render.DrawBox
local cam_Start3D2D = cam.Start3D2D
local color_white = color_white
local cam_End3D2D = cam.End3D2D
local LocalPlayer = LocalPlayer

surface.CreateFont( "KeypadAbort", {
    font = "Roboto",
    size = 45,
    weight = 900
} )

surface.CreateFont( "KeypadOK", {
    font = "Roboto",
    size = 60,
    weight = 900
} )

surface.CreateFont( "KeypadNumber", {
    font = "Roboto",
    size = 70,
    weight = 600
} )

surface.CreateFont( "KeypadEntry", {
    font = "Roboto",
    size = 120,
    weight = 900
} )

surface.CreateFont( "KeypadStatus", {
    font = "Roboto",
    size = 60,
    weight = 900
} )

local COLOR_GREEN = Color( 0, 255, 0 )
local COLOR_RED = Color( 255, 0, 0 )
local COG_COLOR = Color( 150, 150, 150 )

local cogMat = Material( "icon16/cog.png", "smooth mips" )
local mat = CreateMaterial( "willox_keypad_material", "VertexLitGeneric", {
    ["$basetexture"] = "white",
    ["$color"] = "{ 36 36 36 }",
} )

local function DrawLines( lines, x, y )
    local text = table.concat( lines, "\n" )
    local _, total_h = surface.GetTextSize( text )
    local y_off = 0

    for _, v in ipairs( lines ) do
        local w, h = surface.GetTextSize( v )
        surface.SetTextPos( x - w / 2, y - total_h / 2 + y_off )
        surface.DrawText( v )
        y_off = y_off + h
    end
end

local elements = {
    {
        x = 0.075,
        y = 0.04,
        w = 0.85,
        h = 0.25,
        color = Color( 50, 75, 50, 255 ),
        render = function( self, x, y )
            local status = self:GetKeypadStatus()

            if status == self.Status_None then
                surface.SetFont( "KeypadEntry" )
                local text = self:GetText()
                local textw, texth = surface.GetTextSize( text )
                surface.SetTextColor( color_white )
                surface.SetTextPos( x - textw / 2, y - texth / 2 )
                surface.DrawText( text )
            elseif status == self.Status_Denied then
                surface.SetFont( "KeypadStatus" )
                surface.SetTextColor( COLOR_RED )

                if self:GetText() == "1337" then
                    DrawLines( { "ACC355", "D3N13D" }, x, y )
                else
                    DrawLines( { "ACCESS", "DENIED" }, x, y )
                end
            elseif status == self.Status_Granted then
                surface.SetFont( "KeypadStatus" )
                surface.SetTextColor( COLOR_GREEN )

                if self:GetText() == "1337" then
                    DrawLines( { "ACC355", "GRAN73D" }, x, y )
                else
                    DrawLines( { "ACCESS", "GRANTED" }, x, y )
                end
            end
        end,
    }, -- Screen
    {
        x = 0.075,
        y = 0.04 + 0.25 + 0.03,
        w = 0.25,
        h = 0.125,
        color = Color( 120, 25, 25 ),
        hovercolor = Color( 180, 25, 25 ),
        text = "DEL",
        font = "KeypadAbort",
        click = function( self )
            self:SendCommand( self.Command_Abort )
        end
    }, -- ABORT
    {
        x = 0.075 + 0.3,
        y = 0.04 + 0.25 + 0.03,
        w = 0.25,
        h = 0.125,
        color = Color( 25, 27, 120 ),
        hovercolor = Color( 25, 123, 180 ),
        text = "ID",
        font = "KeypadOK",
        click = function( self )
            self:SendCommand( self.Command_ID )
        end
    }, -- ID
    {
        x = 0.075 + 0.3 * 2,
        y = 0.04 + 0.25 + 0.03,
        w = 0.25,
        h = 0.125,
        color = Color( 25, 120, 25 ),
        hovercolor = Color( 25, 180, 25 ),
        text = "OK",
        font = "KeypadOK",
        click = function( self )
            self:SendCommand( self.Command_Accept )
        end
    }, -- OK
    {
        x = 0.828,
        y = 0.04,
        w = 0.0962,
        h = 0.05,
        -- grey
        color = Color( 60, 60, 60 ),
        hovercolor = Color( 80, 80, 80 ),
        text = "",
        font = "KeypadOK",
        click = function( self )
            net.Start( "KeypadOpenConfig" )
            net.WriteEntity( self )
            net.SendToServer()
        end,
        render = function( _, x, y )
            render.PushFilterMag( TEXFILTER.POINT )
            render.PushFilterMin( TEXFILTER.POINT )

            surface.SetDrawColor( COG_COLOR )
            surface.SetMaterial( cogMat )
            surface.DrawTexturedRect( x - 11, y - 11, 22, 22 )

            render.PopFilterMag()
            render.PopFilterMin()
        end,
        condition = function( self )
            return self:GetKeypadOwner() == LocalPlayer()
        end
    } -- Config
}

-- Create numbers
do
    for i = 1, 9 do
        local column = ( i - 1 ) % 3
        local row = math.floor( ( i - 1 ) / 3 )

        local element = {
            x = 0.075 + 0.3 * column,
            y = 0.175 + 0.25 + 0.05 + 0.5 / 3 * row,
            w = 0.25,
            h = 0.13,
            color = Color( 120, 120, 120 ),
            hovercolor = Color( 180, 180, 180 ),
            text = tostring( i ),
            click = function( self )
                self:SendCommand( self.Command_Enter, i )
            end
        }

        table.insert( elements, element )
    end
end

function ENT:Paint( w, h )
    local hovered = self:GetHoveredElement()

    for _, element in ipairs( elements ) do
        if element.condition and not element.condition( self ) then
            continue
        end

        surface.SetDrawColor( element.color )
        local element_x = w * element.x
        local element_y = h * element.y
        local element_w = w * element.w
        local element_h = h * element.h

        if element == hovered and element.hovercolor then
            surface.SetDrawColor( element.hovercolor )
        end

        surface.DrawRect( element_x, element_y, element_w, element_h )
        local cx = element_x + element_w / 2
        local cy = element_y + element_h / 2

        if element.text then
            surface.SetFont( element.font or "KeypadNumber" )
            local textw, texth = surface.GetTextSize( element.text )
            surface.SetTextColor( color_black )
            surface.SetTextPos( cx - textw / 2, cy - texth / 2 )
            surface.DrawText( element.text )
        end

        if element.render then
            element.render( self, cx, cy )
        end
    end
end

function ENT:GetHoveredElement()
    local w, h = self.Width2D, self.Height2D
    local x, y = self:CalculateCursorPos()

    -- reverse ipairs
    for i = #elements, 1, -1 do
        local element = elements[i]
        local element_x = w * element.x
        local element_y = h * element.y
        local element_w = w * element.w
        local element_h = h * element.h
        if element_x < x and element_x + element_w > x and element_y < y and element_y + element_h > y then return element end
    end
end

function ENT:Draw()
    local entTable = self:GetTable()
    local selfPos = self:GetPos()

    render_SetMaterial( mat )
    render_DrawBox( selfPos, self:GetAngles(), entTable.Mins, entTable.Maxs, color_white, true )

    if selfPos:DistToSqr( LocalPlayer():GetPos() ) > 262144 then return end

    local pos, ang = self:CalculateRenderPos(), self:CalculateRenderAng()
    local w, h = entTable.Width2D, entTable.Height2D
    local x, y = self:CalculateCursorPos()

    cam_Start3D2D( pos, ang, entTable.Scale )
    self:Paint( w, h, x, y )
    cam_End3D2D()
end
