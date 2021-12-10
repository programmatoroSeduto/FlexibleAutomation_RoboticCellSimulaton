--[[
    OS_slot_sensor
        low level management of the sensors in front of the output conveyors.
    
    ASSUMPTIONS:
    - an object can't occupy two consecutive sensors: there's enough space between sensors
    
    SHARED DATA:
    OS_slot_sensor_shared: (array)
    - free: (bool) if the sensor area is free or not
    - dist: (float) -1 if not valid; >=0 the distance between the center of the sensor
        and the pick point
    - handle: handle of the pick point of the object inside the slot
--]]
--




--
--- FUNCTIONS
--

--- Update the state of the shared data
function update_shared_data( )
    sim.writeCustomDataBlock( self, 
        "OS_slot_sensor_shared", sim.packTable( shared_data ) )
    
    -- DEGUG
    --[[
    print( "[update_shared_data@OS_slot_sensor] read data:" )
    local data = sim.readCustomDataBlock( self, "OS_slot_sensor_shared" )
    data = sim.unpackTable( data )
    print( data )
    --]]
end
--




--
--- INIT 
--

--- Setup the three sensors
function sensor_setup( slot_names )
    slot_sensor = { }
    for i = 1,#slot_names,1 do
        local record = { handle = nil, center = {} }
        
        -- handler
        local h = sim.getObjectHandle( slot_names[i] )
        
        -- center
        local center_h = sim.getObjectChild( h, 0 )
        local center_pos = sim.getObjectPosition( center_h, -1 )
        
        -- insert te row into the table
        record.handle = h
        record.center = center_pos
        table.insert( slot_sensor, record )
    end
end
--

--- Setup: shared data
function shared_setup( )
    shared_data = {
        { free=true, dist=-1, handle=nil }, -- slot 1
        { free=true, dist=-1, handle=nil }, -- slot 2
        { free=true, dist=-1, handle=nil }  -- slot 3
    }
end

--- inti function for the task 'OS_slot_sensor'
function sysCall_init()
    self = sim.getObjectHandle( sim.handle_self )
    
    -- setup the sensors
    sensor_setup( {
        "slot_1_oiltray",
        "slot_2_fuelpump",
        "slot_3_camshaft"
        } )
    -- print( slot_sensor )
    
    -- init shared data
    shared_setup( )
    update_shared_data( )
end
--




--
--- SENSING
--

--- look for the pick point inside a vendor
function look_for_pick_point_of( handle )
    local pick_point_handle = nil
    local idx = 0
    while true do
        local ch = sim.getObjectChild( handle, idx )
        if ch < 0 then 
            break
        end
        
        local ch_n = sim.getObjectName( ch )
        if string.find( ch_n, "pick_point" ) ~= nil then
            pick_point_handle = ch
            break
        end
        
        idx = idx + 1
    end
    
    return pick_point_handle
end
--

--- Compute the planar distance between two handlers
function distance_between( handleA, handleB )
    -- positions
    pos_A = sim.getObjectPosition( handleA, -1 )
    pos_B = sim.getObjectPosition( handleB, -1 )
    
    -- distance
    return math.sqrt( 
        (pos_A[1] - pos_B[1])*(pos_A[1] - pos_B[1]) + 
        (pos_A[2] - pos_B[2])*(pos_A[2] - pos_B[2]) 
        )
end
--

--- sensing process
function sysCall_sensing()
    local status = -1
    local distance = -1
    local obj = -1
    
    for i=1,#slot_sensor,1 do
        -- check if the sensor is free or not
        -- print( "[sysCall_sensing@OS_slot_sensor] sensor handle " ..  )
        status, distance, _, obj = sim.readProximitySensor( slot_sensor[i].handle )
        
        if status > 0 then
            -- print( "[sysCall_sensing@OS_slot_sensor] slot " .. i .. " DETECTED an object" )
            -- there's something inside the sensor space
            shared_data[i].free = false
            
            -- compute the distance between the center and the pick point
            local pick_point = look_for_pick_point_of( obj )
            if pick_point == nil then
                -- print( "[sysCall_sensing@OS_slot_sensor] ERROR: unable to find the pick point in slot " .. i .. "." )
                -- print( "[sysCall_sensing@OS_slot_sensor] see object named '" .. sim.getObjectName( obj ) .. "'" )
                shared_data[i].free = true
                shared_data[i].dist = -1
                shared_data[i].handle = nil
            else
                -- "recognize" the pick point
                shared_data[i].handle = pick_point
                
                -- compute the planar distance between the two points
                shared_data[i].dist = distance_between( slot_sensor[i].handle, obj )
            end
        else
            -- nothing inside the sensor
            shared_data[i].free = true
            shared_data[i].dist = -1
            shared_data[i].handle = nil
        end
    end
    
    -- last step: update shared data
    update_shared_data( )
end
--
