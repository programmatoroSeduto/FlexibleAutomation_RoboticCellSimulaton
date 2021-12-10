--[[
    TEST_slot_sensor
        A simple echo from the slot sensor.
    
    DATA FROM SENSOR
    {
        { free=true, dist=-1, handle=nil }, -- slot 1
        { free=true, dist=-1, handle=nil }, -- slot 2
        { free=true, dist=-1, handle=nil }  -- slot 3
    }
--]]

--- read from sensors
function read_sensor( )
    data = sim.unpackTable( 
        sim.readCustomDataBlock( slot_sensor, "OS_slot_sensor_shared" ) )
end
--

---
function sysCall_init()
    enabled = true
    pause_sim = true -- pause the simulation every time at least one slot is occupied
    
    if enabled then
        -- sensor handle
        slot_sensor = sim.getObjectHandle( "OS_slot_sensors" )
        
        frame_count = 0
        frame_wait = -1
        frame_n_wait = 10
    end
end
--

---
function sysCall_sensing()
    if enabled then
        if frame_wait < 0 then
            -- read from the sensor
            read_sensor( )
            
            -- print the content of the sensors
            frame_count = frame_count + 1
            print( "[sysCall_sensing@TEST_slot_sensor, f:" .. frame_count .. "] data:" )
            print( data )
            
            if (not data[1].free) or (not data[2].free) or (not data[3].free) then
                print( "[sysCall_sensing@TEST_slot_sensor, f:" .. frame_count .. "] sim paused" )
                sim.pauseSimulation( )
                frame_wait = frame_n_wait
            end
        else
            frame_wait = frame_wait - 1
        end
    end
end
-- 