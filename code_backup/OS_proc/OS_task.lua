--[[
    OS_task
        this module manages the entire robotic cell. It is the software at the upmost level.
    
    See the coding notes for further informations. 
--]]




--
--- STATE MACHINE LIB FUNCTION
--

--- implementation of the state machine
function smach_init( )
    local sm = { }

    -- transition function
    sm.__transition_function = { }
    --[[
    Access Syntax:
        1. numeric - DIRECT ACCESS
            transition_function[ state_idx ]     --> state_record
        2. by string - INDIRECT ACCESS
            transition_function[ "state_label" ] --> state_idx
            then you can use the state_idx to access the record
    State record structure:
        state_label (must be unique)
        state_idx (automatically set)
        state_action (the function associated with the state)
    Action Prototype:
        arguments: 
            1. a single package with everythin needed to run the state
            2. the state machine itself
        returns: the label of the next state, or nothing
            when nothing is returned, the machine doesn't update its state
    --]]

    -- how many states are in the state machine
    sm.__state_count = 0
    -- actual state (-1 if there's not a initial state)
    sm.state = -1
    sm.state_name = nil
    
    -- initial state (-1 if not set)
    sm.init_state = -1
    
    -- shared data for the states
    sm.shared = { }
    
    -- MEMBER: add a new state to the machine
    -- ARGS: self, label, function, is_init?
    -- RETURNS: success (true) or not (false) and the state (-1 if result is false)
    --    if the machine is empty, set the new state as initial 
    function sm.add_state( 
        self,          -- the state machine
        state_label,   -- the label of the state
        state_action,  -- the callback associated to the state
        is_init        -- default is 'false'
        )
        -- default args
        is_init = is_init or false
        
        -- verify the label
        if self.__exists_label( self, state_label ) then
            print( "[State Machine:add_state] ERROR: label '" .. state_label .. "' already defined." )
            return false
        end
        
        -- get the record
        local state_idx    = self.__state_count
        self.__state_count = self.__state_count + 1
        local state_record = self.__create_state_record( 
            state_label, state_idx, state_action )
        
        -- define the record into the table
        --- DIRECT ACCESS
        self.__transition_function[ state_idx ] = state_record
        --- INDIRECT ACCESS
        self.__transition_function[ state_label ] = state_idx
        
        -- set the initial state if needed
        if self.init_state < 0 or is_init then
            self.init_state = state_idx 
            self.state = state_idx
            self.state_name = state_label
        end
    end
    
    -- MEMBER: run the actual state
    --    set also shared infos is infos!=nil
    function sm.exec( self, infos )
        -- check if the machine has at least one state
        if self.init_state < 0 then
            print( "[State Machine:exec] ERROR: State machine not yet initialized!" )
            return false, nil, nil
        end
        
        -- get the state record
        local state_record = self.__transition_function[ self.state ]
        
        -- execute the actual state
        --    and gather the next state (as string)
        local state_next_str = nil
        if infos == nil then
            state_next_str = state_record[ "state_action" ]( self, self.shared )
        else
            self.shared = infos
            state_next_str = state_record[ "state_action" ]( self, self.shared )
        end
        
        -- compute the next state if possible
        local state_next_idx = self.__transition_function[ state_next_str ]
        
        -- update the state of the machine
        if state_next_idx ~= nil then
            self.state = state_next_idx
            self.state_name = state_record["state_name"]
        end
        
        return true, self.state, self.state_name  --> success
    end
    
    -- MEMBER: set/reset shared infos
    function sm.set_shared( self, pack )
        self.shared = pack
    end
    
    -- PRIVATE: verify if a label exists inside the transition_function
    function sm.__exists_label( self, label )
        for i = 1, #self.__transition_function, 1 do
            if self.__transition_function[i]["state_label"] == label then
                return true --> found a previously defined label in the table
            end
        end
        
        return false --> name is unique
    end
    
    -- PRIVATE: create a record
    function sm.__create_state_record( label, idx, action_funct )
        local record = { 
            ["state_label"]  = label, 
            ["state_idx"]    = idx,
            ["state_action"] = action_funct
        }
        
        return record
    end
    
    -- return the state machine
    return sm
end
--




--
--- SHARED COMMUNICATION
-- 

--- setup the communication
function sh_setup( )
    -- drivers
    driver_slot_sensor = sim.getObjectHandle( "OS_slot_sensors" )
    
    -- services
    service_conveyor = sim.getObjectHandle( "OS_conveyor_service" )
    service_crane = sim.getObjectHandle( "OS_crane_service" )
    service_slot_manager = sim.getObjectHandle( "OS_slot_manager" )
end
--

--- read a suggestion from the slot_manager service
--    RETURNS (1) bool, whether there's or not a suggestion 
--      (2) the suggestion (-1 if empty)
function sh_get_suggestion( )
    -- read from the service
    local data = sim.unpackTable( 
        sim.readCustomDataBlock( service_slot_manager, "OS_slot_manager_shared" ) )
    
    if data.slot > 0 then
        -- suggestion from the slot_manager!
        return true, data.slot
    else
        -- no suggestion from the slot_manager
        return false, -1
    end
end
--

--- check the distance of the pick point from the center of the sensor
--    RETURNS (1) true if the distance is under the threshold, false (2) the distance
function sh_check_distance( working_slot, threshold )
    -- get the distance from the sensor
    local sensor_data = sim.unpackTable( 
        sim.readCustomDataBlock( driver_slot_sensor, "OS_slot_sensor_shared" ) )
    
    -- don't go on if the sensor is empty
    if sensor_data[working_slot].free then
        return false, infinite_number
    end
    
    local dist = sensor_data[working_slot].dist
    if sensor_data[working_slot].dist <= threshold then
        return true, dist
    else
        return false, dist
    end
end
--

--- toggle the carousel
--    DEFAULT: turn off the carousel
function sh_toggle_carousel( flag )
    local flag = flag or false
    
    if flag then
        sim.writeCustomDataBlock( service_conveyor,
            "OS_conveyor_service_shared_input", 
            sim.packTable( { cmd = "carousel", value = 1 } )
            )
    else
        sim.writeCustomDataBlock( service_conveyor,
            "OS_conveyor_service_shared_input", 
            sim.packTable( { cmd = "carousel", value = 0 } )
            )
    end
end
--

--- toggle the conveyor of the working slot
function sh_toggle_conveyor( working_slot, flag )
    local flag = flag or false
    
    if flag then
        sim.writeCustomDataBlock( service_conveyor,
            "OS_conveyor_service_shared_input", 
            sim.packTable( { cmd = "conveyor_" .. working_slot, value = 1 } )
            )
    else
        sim.writeCustomDataBlock( service_conveyor,
            "OS_conveyor_service_shared_input", 
            sim.packTable( { cmd = "conveyor_" .. working_slot, value = 0 } )
            )
    end
end
--

--- check the state of the robot
--    RETURNS (1) if the robot is busy (2) success flag
function sh_check_robot( )
    -- read the state of the service
    local data = sim.unpackTable( 
        sim.readCustomDataBlock( service_crane, "OS_crane_service_shared_output" ) )
    print( "[sh_check_robot@OS_task] received data:" )
    print( data )
    
    return data.busy, data.success
end
--

--- send one among the pick commands
--    ARGS: 
--      false: run the command "pick_ready"
--      true: run the command "pick"
function sh_pick( flag )
    if flag then
        -- "pick_ready" command
        local msg = { cmd="pick", value=-1 }
        sim.writeCustomDataBlock( service_crane, 
            "OS_crane_service_shared_input", sim.packTable( msg ) )
        
    else
        -- "pick" command
        local msg = { cmd="pick_ready", value=-1 }
        sim.writeCustomDataBlock( service_crane, 
            "OS_crane_service_shared_input", sim.packTable( msg ) )
        
    end
end
--

--- send one among the place commands
--    ARGS: 
--      false: run the command "place_ready"
--      true: run the command "place"
function sh_place( flag )
    if flag then
        -- "place_ready" command
        local msg = { cmd="place", value=-1 }
        sim.writeCustomDataBlock( service_crane, 
            "OS_crane_service_shared_input", sim.packTable( msg ) )
        
    else
        -- "place" command
        local msg = { cmd="place_ready", value=-1 }
        sim.writeCustomDataBlock( service_crane, 
            "OS_crane_service_shared_input", sim.packTable( msg ) )
        
    end
end
--

--- select one working slot
function sh_set_working_slot( slot )
    local slot = slot or 2
    
    local msg = { cmd = "slot", value = slot }
    sim.writeCustomDataBlock( service_crane, 
        "OS_crane_service_shared_input", sim.packTable( msg ) )
end
--

--- send the command "idle"
function sh_command_idle( )
    local msg = { cmd = "idle", value = slot }
    sim.writeCustomDataBlock( service_crane, 
        "OS_crane_service_shared_input", sim.packTable( msg ) )
end
--




--
--- STATE MACHINE IMPLEMENTATION
--

--- set some frames to wait
function smach_set_wait_frames( pack, n_frames )
    local n_frames = n_frames or 1
    
    -- init the waiting
    pack.waiting_frame = true
    pack.frame_to_wait = n_frames
end
--

--- wait one frame
--    RETURNS true:end of the wait
function smach_wait_frame( pack )
    -- decrement the frame count
    pack.frame_to_wait = pack.frame_to_wait - 1
    
    -- check the frame count
    if pack.frame_to_wait <= 0 then
        -- end of the waiting
        pack.waiting_frame = false
        pack.frame_to_wait = -1
        
        return true
    
    else
        -- keep waiting
        return false
        
    end
end
--

--- restore the empty pack
function smach_reset_pack( pack )
    pack.working_slot = -1
    pack.prev_dist = infinite_number
    pack.waiting_frame = false
    pack.frame_to_wait = -1
    pack.flag = false
end
--

--- INIT state: wait for a suggestion
--    keep in this state until a suggestion is sent
function state_wait_suggestion( sm, pack ) --> "wait_suggestion"
    -- wait for a suggestion
    local res = false
    res, pack.working_slot = sh_get_suggestion( )
    if not res then
        -- keep in this state
        return "wait_suggestion"
    else
        print( "[state_wait_suggestion@OS_task] suggestion: " .. pack.working_slot )
        return "wait_dist"
    end
end
--

--- wait until the distance is under the threshold
function state_wait_dist( sm, pack ) --> "wait_dist"
    local dist = -1
    local res = false
    res, dist = sh_check_distance( pack.working_slot, pack.threshold )
    if res then
        -- set the working slot of the robot
        sh_set_working_slot( pack.working_slot )
        
        -- stop the carousel
        sh_toggle_carousel( false )
        
        pack.prev_dist = infinite_number
        print( "[state_wait_dist@OS_task] from 'wait_dist' to 'pick_ready'" )
        return "pick_ready"
        
    else
        if dist < pack.prev_dist then
            -- the distance is decreasing
            pack.prev_dist = dist
            
            -- keep waiting for the distance
            return "wait_dist"
        else
            -- the distance is increasing instead of decreasing
            -- refuse the suggestion
            print( "[state_wait_dist@OS_task] suggestion " .. pack.working_slot .. " rejected." )
            smach_reset_pack( pack )
            
            -- restore the init state
            return "wait_suggestion"
        end
        
    end
end
--

--- prepare to pick the object
--     "flag" is false when the state begins
function state_pick_ready( sm, pack ) --> "pick_ready"
    if not flag then
        -- not yet set
        flag = true
        
        -- send the command to the service
        sh_pick( false )
        
        return "pick_ready"
        
    else
        -- wait until the status becomes idle again
        local busy = false
        local success = false
        busy, success = sh_check_robot( )
        print( "[state_pick_ready@OS_task] " 
            .. "success=" .. tostring(success) 
            .. " busy=" .. tostring(busy) )
        
        if busy then
            -- keep waiting
            return "pick_ready"
        
        else
            if success then
                pack.flag = false
                
                -- run "pick" 
                print( "[state_pick_ready@OS_task] from 'pick_ready' to 'pick'" )
                return "pick"
                
            else
                -- some error occurred
                smach_reset_pack( pack )
                return "wait_suggestion"
                
            end
        end
    end
end
--

--- pick
function state_pick( sm, pack ) --> "pick"
    if not flag then
        -- not yet set
        flag = true
        
        -- send the command to the service
        sh_pick( true )
        
        return "pick"
        
    else
        -- wait until the status becomes idle again
        local busy = false
        local success = false
        busy, success = sh_check_robot( )
        
        if busy then
            -- keep waiting
            return "pick"
        
        else
            if success then
                pack.flag = false
                
                -- go to "place_ready" step
                return "place_ready"
                
            else
                -- some error occurred
                smach_reset_pack( pack )
                return "wait_suggestion"
                
            end
            
        end
    end
end
--

--- command "place_ready"
function state_place_ready( sm, pack ) --> "place_ready"
    if not flag then
        -- not yet set
        flag = true
        
        -- send the command to the service
        sh_place( false )
        -- restart the carousel
        sh_toggle_carousel( true )
        -- stop the working conveyor
        sh_toggle_conveyor( pack.working_slot, false )
        
        return "place_ready"
        
    else
        -- wait until the status becomes idle again
        local busy = false
        local success = false
        busy, success = sh_check_robot( )
        
        if busy then
            -- keep waiting
            return "place_ready"
        
        else
            if success then
                pack.flag = false
                
                -- go to "place" step
                return "place"
                
            else
                -- some error occurred
                smach_reset_pack( pack )
                return "wait_suggestion"
                
            end
            
        end
    end
end
--

--- command "place"
function state_place( sm, pack ) --> "place"
    if not flag then
        -- not yet set
        flag = true
        
        -- send the command to the service
        sh_place( true )
        
        return "place"
        
    else
        -- wait until the status becomes idle again
        local busy = false
        local success = false
        busy, success = sh_check_robot( )
        
        if busy then
            -- keep waiting
            return "place"
        
        else
            if success then
                pack.flag = false
                
                -- restart the output conveyor
                sh_toggle_conveyor( pack.working_slot, true )
                -- clear the shared pack
                smach_reset_pack( pack )
                
                -- task done
                return "wait_suggestion"
                
            else
                -- some error occurred
                smach_reset_pack( pack )
                return "wait_suggestion"
                
            end
            
        end
    end
end
--




--
--- INIT AND SETUP
--

--- setup the state machine
function task_setup( )
    local task = smach_init( )
    
    -- infinite number
    infinite_number = 10e30
    
    -- set the shared memory of the machine
--  local pack = {
    pack = {
        threshold = 0.05,
        prev_dist = infinite_number,  -- if the distance is increasing, there's somehing wrong
        working_slot = -1,
        
        waiting_frame = false, -- use it to wait some frames
        frame_to_wait = -1,    -- how many frames to wait
        
        flag = false     -- another geenral-purpose flag
    }
    task.set_shared( task, pack )
    
    -- states
    task.add_state( task, "wait_suggestion", state_wait_suggestion, true  )
    task.add_state( task, "wait_dist", state_wait_dist, false )
    task.add_state( task, "pick_ready", state_pick_ready, false )
    task.add_state( task, "pick", state_pick, false )
    task.add_state( task, "place_ready", state_place_ready, false )
    task.add_state( task, "place", state_place, false )
    
    return task
end
--

--- init function of OS_task
function sysCall_init()
    self = sim.getObjectHandle( sim.handle_self )
    
    -- setup the communication
    sh_setup( )
    
    -- setup the state machine
    task = task_setup( )
end
--




--
--- WORKING CYCLE
--

function sysCall_actuation()
    task.exec( task )
end
--

