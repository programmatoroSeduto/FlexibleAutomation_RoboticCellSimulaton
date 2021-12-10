--[[
    OS_conveyor_service
        utilities for controlling the conveyors in the cell
    
    COMMANDS
        conveyor_1 --> 0, 1
        conveyor_2 --> 0, 1
        conveyor_3 --> 0, 1
            0 : stop the "output" conveyor, setting its velocity to zero
            1 : restart the conveyor, set velocity to 0.4 (default)
            -> SUCCESS : velocity overwritten.
        carousel --> 0, 1
            0 : stop the carousel
            1 : set the velocity of the carouse to 0.4 (default)
            -> SUCCESS : velocity of the carousel overwritten.
    
    SERVICE INTERFACE
    Send a command:
        sim.writeCustomDataBlock( sim.getObjectHandle( "OS_conveyor_service" ), "OS_conveyor_service_shared_input", sim.packTable( {cmd="", value=0} )
    retrieve the state:
        local buffer = sim.readCustomDataBlock(
            sim.getObjectHandle( "OS_conveyor_service" ),
            "OS_conveyor_service_shared_input" )
        status = sim.unpackTable( buffer )
            
--]]
--




-- 
--- UPDATE
-- 

--- setup: expose the service
function service_setup( )
    -- empty input model
    conveyor_empty_input_msg = { cmd="", value=-1 }
    -- empty output model
    conveyor_empty_output_msg = { success=true }
    
    -- input infos (read only)
    -- DEFAULT STATE: cmd="", value=-1
    sim.writeCustomDataBlock( self,
        "OS_conveyor_service_shared_input", 
        sim.packTable( conveyor_empty_input_msg )
        )
    
    -- output infos (write only)
    sim.writeCustomDataBlock( self,
        "OS_conveyor_service_shared_output",
        sim.packTable( conveyor_empty_output_msg )
        )
    
    service_input  = conveyor_empty_input_msg
    service_output = conveyor_empty_output_msg
end
--

--- get the command from the user, if any
function service_update_input( )
    -- read the input
    local buffer = sim.readCustomDataBlock( self, "OS_conveyor_service_shared_input" )
    service_input = sim.unpackTable( buffer )
    
    -- clear the previous input!
    sim.writeCustomDataBlock( self,
        "OS_conveyor_service_shared_input", sim.packTable( conveyor_empty_input_msg ) )
end
--

--- provide the output
--    ARGS: the message, as {success=, busy=}
--    default empty is used if msg=nil
function service_update_output( msg )
    local msg = msg or service_output
    sim.writeCustomDataBlock( self,
        "OS_conveyor_service_shared_output", sim.packTable( msg ) )
end
--




--
--- COMMANDS
--

--- switch the state of a conveyor or the carousel
function switch_state( is_carousel, idx, flag )
    -- select the handle
    local conveyorHandle
    if is_carousel then
        conveyorHandle = carousel.handle
    else
        conveyorHandle = conveyor[idx].handle
    end
    
    -- select the new velocity
    local new_vel
    if flag and is_carousel then
        new_vel = carousel_default_velocity
    elseif flag and not is_carousel then
        new_vel = conveyor_default_velocity
    else
        new_vel = 0.0
    end
    
    -- send the new value to the selected conveyor
    sim.writeCustomDataBlock( conveyorHandle,
        'CONVMOV', sim.packTable( { vel = new_vel } ) )
    
    -- update the state of the conveyor
    if is_carousel then
        carousel.active = flag
    else
        conveyor[idx].active = flag
    end
end

--- execute a received command
function execute_cmd( )
    local c = service_input.cmd
    local out = { success=true }
    
    if c == "conveyor_1" then
        switch_state( false, 1, (service_input.value > 0) )
    elseif c == "conveyor_2" then
        switch_state( false, 2, (service_input.value > 0) )
    elseif c == "conveyor_3" then
        switch_state( false, 3, (service_input.value > 0) )
    elseif c == "carousel" then
        switch_state( true, -1, (service_input.value > 0) )
    else
        -- command not recognized!
        out.success = false
    end
    
    -- set the new output state
    service_output = out
end
--




--
--- INIT
--

--- setup the global data
function conveyor_control_setup( )
    -- about the conveyors
    conveyor = {
        { handle=sim.getObjectHandle( "oiltray_conveyor" ), active=true },
        { handle=sim.getObjectHandle( "fuelpump_conveyor" ), active=true },
        { handle=sim.getObjectHandle( "camshaft_conveyor" ), active=true }
    }
    
    -- about the carousel 
    carousel = {
        handle=sim.getObjectHandle( "carousel" ), active=true
    }
    
    -- default values
    conveyor_default_velocity = 0.16
    carousel_default_velocity = 0.40
end
--

--- the init function of 'OS_conveyor_service'
function sysCall_init()
    self = sim.getObjectHandle( sim.handle_self )
    
    -- setup the communication system
    service_setup( )
    
    -- setup the control data
    conveyor_control_setup( )
end
--

function sysCall_actuation()
    -- get a command from another scrit, if any
    service_update_input( )
    
    -- don't run the function if the command is empty
    if service_input.cmd ~= "" then
        -- run the command
        execute_cmd( )
        
        -- the command is "consumed"
        service_input = conveyor_empty_input_msg
        
        -- publish the new state
        service_update_output( )
    end
end