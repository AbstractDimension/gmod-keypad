AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_maths.lua" )
AddCSLuaFile( "cl_panel.lua" )
AddCSLuaFile( "sh_init.lua" )
include( "sh_init.lua" )

function ENT:SetValue( val )
    self.Value = val

    if self:GetSecure() then
        self:SetText( string.rep( "*", #val ) )
    else
        self:SetText( val )
    end
end

function ENT:GetValue()
    return self.Value
end

function ENT:Process( granted )
    self:GetData()
    local length, repeats, delay, initdelay, key

    if granted then
        self:SetKeypadStatus( self.Status_Granted )
        length = math.max( self.KeypadData.LengthGranted, GetConVar( "keypad_min_granted_hold_lenght" ):GetFloat() )
        initdelay = math.min( self.KeypadData.InitDelayGranted, GetConVar( "keypad_max_granted_initial_lenght" ):GetFloat() )
        repeats = math.min( self.KeypadData.RepeatsGranted, 50 )
        delay = self.KeypadData.DelayGranted
        key = tonumber( self.KeypadData.KeyGranted ) or 0
    else
        self:SetKeypadStatus( self.Status_Denied )
        length = self.KeypadData.LengthDenied
        repeats = math.min( self.KeypadData.RepeatsDenied, 50 )
        delay = self.KeypadData.DelayDenied
        initdelay = self.KeypadData.InitDelayDenied
        key = tonumber( self.KeypadData.KeyDenied ) or 0
    end

    local owner = self:GetKeypadOwner()

    -- 0.25 after last timer
    timer.Simple( math.max( initdelay + length * ( repeats + 1 ) + delay * repeats + 0.25, 2 ), function()
        if IsValid( self ) then
            self:Reset()
        end
    end )

    timer.Simple( initdelay, function()
        if not IsValid( self ) then return end
        for i = 0, repeats do
            timer.Simple( length * i + delay * i, function()
                if not IsValid( self ) or not IsValid( owner ) then return end
                numpad.Activate( owner, key, true )
            end )

            timer.Simple( length * ( i + 1 ) + delay * i, function()
                if not IsValid( self ) or not IsValid( owner ) then return end
                numpad.Deactivate( owner, key, true )
            end )
        end
    end )

    if granted then
        self:EmitSound( "buttons/button9.wav" )
    else
        self:EmitSound( "buttons/button11.wav" )
    end
end

function ENT:SetData( data )
    self.KeypadData = data
    self:SetPassword( data.Password or "1337" )
    self:Reset()
    duplicator.StoreEntityModifier( self, "keypad_password_passthrough", self.KeypadData )
end

function ENT:GetData()
    if not self.KeypadData then
        self:SetData( {
            Password = 1337,
            RepeatsGranted = 0,
            RepeatsDenied = 0,
            LengthGranted = 0,
            LengthDenied = 0,
            DelayGranted = 0,
            DelayDenied = 0,
            InitDelayGranted = 0,
            InitDelayDenied = 0,
            KeyGranted = 0,
            KeyDenied = 0,
            Secure = false
        } )
    end

    return self.KeypadData
end

function ENT:Reset()
    self:SetValue( "" )
    self:SetKeypadStatus( self.Status_None )
    self:SetSecure( self:GetData().Secure )
end

duplicator.RegisterEntityModifier( "keypad_password_passthrough", function( ply, entity, data )
    entity:SetKeypadOwner( ply )
    entity:SetData( data )
end )
