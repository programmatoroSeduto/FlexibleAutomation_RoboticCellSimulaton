--[[
    OS_slot_manager
        This module optimizes the functioning of the robot by "suggesting" each time
        the best slot to resolve in the next move. 
    
    METHOD
        This aproach can be referred to as "right slot first": each time, the slot
        which contains the correct type of object is preferred. 
        The implementation uses two main data structures:
        - a queue Q of the objects entering in the working area
        - a 5 elements array A which contains the occupancy of the slots
    
    DATA:
    OS_slot_manager_shared
    - slot (-1 when empty) the selected slot
    - to_send.pick_point_handle (-1 with no suggestions) the handle to the pick point of
        the selected vendor 
--]]
--




-- 
--- SENSORS
-- 

--- Setup data about the sensors
function sensor_setup( )
    -- packages from the sensors
    optic_data = {
        { state=false, last_detection = "none" },
        { state=false, last_detection = "none" },
        { state=false, last_detection = "none" }
    }
    slot_sensor_data = {
        { free=true, dist=-1, handle=nil },
        { free=true, dist=-1, handle=nil },
        { free=true, dist=-1, handle=nil }
    }
    
    -- the last detection from the slot sensors
    slot_last_detection = { true, true, true }
    
    -- last value for the flag of the optic sensor
    optic_last_flag = false
end
--

--- read new data from the sensors
function sensor_update( )
    local buffer = nil
    
    -- data from the optic sensor
    buffer = sim.readCustomDataBlock( optic_driver, "OS_optic_sensor_slot_shared" )
    optic_data = sim.unpackTable( buffer )
    
    -- data from the slot sensors
    buffer = sim.readCustomDataBlock( slot_driver, "OS_slot_sensor_shared" )
    slot_sensor_data = sim.unpackTable( buffer )
    
    -- print( optic_data )
end
--

-- check if the last detection is equal to the actual one
--   GLOBALS: it uses the sensor package
--   RETURNS: 'true' if 'slot_last_detection' and 'slot_sensor_data[].free' are not the same
function sensor_check( )
    if (slot_last_detection[1]~=slot_sensor_data[1].free) 
        or (slot_last_detection[2]~=slot_sensor_data[2].free) 
        or (slot_last_detection[3]~=slot_sensor_data[3].free) then
        -- enable only if at least one optic sensor is active
        if optic_data[1].state or optic_data[2].state or optic_data[3].state then
            return true
        else
            return false
        end
    else
        return false
    end
end
--

--- make the measurements equal
function sensor_equal( )
    slot_last_detection[1] = slot_sensor_data[1].free
    slot_last_detection[2] = slot_sensor_data[2].free
    slot_last_detection[3] = slot_sensor_data[3].free
end
--

--- Get the allocated slots and the corresponding types
function sensor_get_allocation( )
    local type_vector = { "", "", "" }
    
    -- print( optic_data )
    for i=1,3,1 do
        -- print( optic_data[i].state )
        if optic_data[i].state then
            -- read the type from the optic sensor of the slot
            type_vector[i] = optic_data[i].last_detection
        end
    end
    
    -- print( type_vector )
    -- sim.pauseSimulation( )
    return type_vector
end
--




-- 
--- SUGGESTIONS
--

--- find the slot to resolve first
function suggest_slot( type_vector )
    -- search for the best slot from the first one to the last one
    for i=1,#vendors_list,1 do
        if type_vector[i] == vendors_list[i] then
            return i
        end
    end
    
    return -1 --> there is no acceptable solution
end
--

--- Publish the suggested slot
--    ARGS: 'idx' (-1 or >0)
function suggest_publish( idx )
    local idx = idx or -1
    
    -- create the message to write
    local to_send = { }
    if idx < 0 then
        to_send.slot = -1
        to_send.pick_point_handle = -1
    else
        to_send.slot = idx
        to_send.pick_point_handle = slot_sensor_data[ idx ].handle
    end
    
    sim.writeCustomDataBlock( self, 
        "OS_slot_manager_shared", sim.packTable( to_send ) )
end
--




--
--- INIT AND SETUP
--

--- Find the handlers to the drivers
function load_drivers( )
    -- proximity detection driver
    slot_driver = sim.getObjectHandle( "OS_slot_sensors" )
    
    -- color detection driver
    optic_driver = sim.getObjectHandle( "OS_optic_sensor_slot" )
end

--- Load the vendor types
function load_vendors_infos( )
    vendors_list = {
        "oiltray",  --> slot #1
        "fuelpump", --> slot #2
        "camshaft"  --> slot #3
    }
end
--

--- Init function of 'OS_slot_manager'
function sysCall_init( )
    self = sim.getObjectHandle( sim.handle_self )
    
    -- drivers 
    load_drivers( )
    -- vendors
    load_vendors_infos( )
    
    -- sensors
    sensor_setup( )
    
    -- init shared data
    suggest_publish( )
end
--

---
function sysCall_sensing( )
    -- update the state of the sensors
    sensor_update( )
    -- print( optic_data )
    
    -- check if the measurement is changed
    if sensor_check( ) then
        -- suggest a slot, if possible
        local best_slot = suggest_slot( sensor_get_allocation( ) )
        -- print( "best slot: " .. best_slot )
        
        -- publish the best slot and its data if possible
        -- otherwise, blish a empty message
        suggest_publish( best_slot )
        
        -- make the measurements equal
        sensor_equal( )
    end
end
--
