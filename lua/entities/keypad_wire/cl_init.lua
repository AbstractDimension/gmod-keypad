include( "sh_init.lua" )
include( "entities/keypad/cl_maths.lua" )
include( "entities/keypad/cl_panel.lua" )

function ENT:SendCommand( command, data )
    net.Start( "Keypad_Wire" )
    net.WriteEntity( self )
    net.WriteUInt( command, 4 )

    if data then
        net.WriteUInt( data, 8 )
    end

    net.SendToServer()
end
