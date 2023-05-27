include( "sh_init.lua" )
include( "cl_maths.lua" )
include( "cl_panel.lua" )

local render_SetMaterial = render.SetMaterial
local render_DrawBox = render.DrawBox
local cam_Start3D2D = cam.Start3D2D
local color_white = color_white
local cam_End3D2D = cam.End3D2D
local LocalPlayer = LocalPlayer

local mat = CreateMaterial( "willox_keypad_material", "VertexLitGeneric", {
    ["$basetexture"] = "white",
    ["$color"] = "{ 36 36 36 }",
} )

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

function ENT:SendCommand( command, data )
    net.Start( "Keypad_Wire" )
    net.WriteEntity( self )
    net.WriteUInt( command, 4 )

    if data then
        net.WriteUInt( data, 8 )
    end

    net.SendToServer()
end
