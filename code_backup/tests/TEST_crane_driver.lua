--[[
    TEST_crane_driver
        a simple echo of the state of the crane
--]]

function sysCall_init()
    enabled = true
    
    flag = false
    end_echo = false
    driver = sim.getObjectHandle( "OS_crane_driver" )
    
    frame_count = 0
    
    -- the second idle position
    local pos_h = sim.getObjectHandle( "OS_poses_idle_2" )
    position = sim.getObjectPosition( pos_h, -1 )
    print( "[sysCall_init@TEST_crane_driver] pose to reach: " )
    print( position )
end

function sysCall_actuation()
    if enabled then
    if not flag then
        -- send the motion request
        print( "[sysCall_actuation@TEST_crane_driver] FIRST FRAME" )
        print( "[sysCall_actuation@TEST_crane_driver] sending the coordinates... " )
        local ret = sim.writeCustomDataBlock( driver, 
            "OS_crane_driver_shared_target", sim.packFloatTable( position ) )
        print( "[sysCall_actuation@TEST_crane_driver] returned " .. tostring(ret) )
        print( "[sysCall_actuation@TEST_crane_driver] sending 'active' signal... " )
        ret = sim.writeCustomDataBlock( driver,
            "OS_crane_driver_shared_active", sim.packUInt8Table( { 1 } ) )
        print( "[sysCall_actuation@TEST_crane_driver] returned " .. tostring(ret) )
        
        print( "[sysCall_actuation@TEST_crane_driver] ready to go!" )
        flag = true
        
    else
        if not end_echo then
            -- echo the response from the driver
            frame_count = frame_count + 1
            print( "[sysCall_actuation@TEST_crane_driver] ECHO PHASE (frame " 
                .. frame_count .. ")" )
            
            local data = sim.unpackTable(
                sim.readCustomDataBlock( driver, "OS_crane_driver_shared" )
                )
            local active = sim.unpackUInt8Table(
                sim.readCustomDataBlock( driver, "OS_crane_driver_shared_active" )
                )
            
            print( "[sysCall_actuation@TEST_crane_driver] 'active' flag: " .. active[1]  )
            print( "[sysCall_actuation@TEST_crane_driver] response from the driver:" )
            print( data )
            
            if data.current_pose[1] == position[1] then
            if data.current_pose[2] == position[2] then
            if data.current_pose[3] == position[3] then
                end_echo = true
                print( "[sysCall_actuation@TEST_crane_driver] objective reached."  )
            end
            end
            end
        end
    end
    end
end