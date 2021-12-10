--[[
    OS_crane_service
        mid-level control for the crane, structured as a RPR. 
    
    COMMANDS
        slot       --> 1, 2, 3
            set the current work slot
            every commands after this one will act on the selected slot
            default slot is 2. 
            -> SUCCESS : 
                true : slot changed.
                false : you cannot change the slot immediately after a successful 
                    "pick" command
        pick_ready --> -
            move the end effector over the vendor to pick in the working slot
            This algorithm is followed:
            1. given the working slot, check if the slot is occupied by a vendor
            2. if it is, search the pick point using a low level service
            3. the final position of the gripper is 0.2m over the pick point
            4. move the EE in the computed position
            5. the robot has state pick ready
            -> SUCCESS 
                false : the slot is empty, unable to find the pick point
                true : motion complete
                WARNING: don't test SUCCESS flag during the motion! Rely on BUSY instead
            -> BUSY
                true : the gripper is on move
                false : the gripper is quiet
        pick      --> -
            start the pick procedure. Here is how it works:
            1. the robot must be in pick ready state, otherwise SUCCESS=false
            2. enable the suction pad
            3. go down towards the pick point and pick the object
            4. after a while...
            5. go upwards with the object
            6. the robot is carrying a payload
            -> SUCCESS
                false : the robot is not in pick ready state 
                true : operation completed
            -> BUSY 
                true : the robot is on move
                false : the robot is quiet
        place_ready --> -
            move the end effector in the place position. The robot must be in state 
            "carrying a payload" before launching the command. 
            -> SUCCESS : 
                false : initial stata was not correct
                true : motion completed
            -> BUSY : movement
        place       --> -
            place the object on the conveyor. Here is how it works:
            1. go down
            2. release the payload de-actvating the suction pad
            3. go up
            -> SUCCESS
            -> BUSY
        idle
            the robot moves in the idle position of the working slot.
            -> SUCCESS 
            ->BUSY
--]]
--




--
--- STATE MACHINE
--

--- build a state machine
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
            return false
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
        if state_next_idx == nil or state_next_str == nil then
            print( "[State Machine:exec] ERROR: state action of '" .. 
                state_record["state_label"] .. "' returned an unexistent state!")
            return false
        end
        
        -- update the state of the machine
        self.state = state_next_idx
		self.state_name = state_next_str
        
        return true --> success
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
--- UPDATE AND EXTERNAL COMMANDS
--

-- setup: expose the services
function service_setup( )
    -- empty input msg 
    service_empty_input = { cmd="", value=-1 }
    -- empty output msg
    service_empty_output = { success=true, busy=false, err_code=0, err_str="" }
    
    -- input infos
    sim.writeCustomDataBlock( self,
        "OS_crane_service_shared_input", sim.packTable( service_empty_input ) )
    sim.writeCustomDataBlock( self,
        "OS_crane_service_shared_enable_slot_check", "true" )
    
    -- output infos
    sim.writeCustomDataBlock( self,
        "OS_crane_service_shared_output", sim.packTable( service_empty_output ) )
    
    service_input = service_empty_input
    service_enable_slot_check = true
    service_output = service_empty_output
end
--

--- get the command from another script, if any
function service_update_input( )
    -- read the input
    service_input = sim.unpackTable( sim.readCustomDataBlock( self, 
        "OS_crane_service_shared_input" ) )
    service_enable_slot_check = ( sim.readCustomDataBlock( self,
        "OS_crane_service_shared_enable_slot_check" ) == "true" )
    
    -- clear the cmd input!
    sim.writeCustomDataBlock( self,
        "OS_crane_service_shared_input", sim.packTable( service_empty_input ) )
end
--

--- publish the current state
function service_update_output( msg )
    sim.writeCustomDataBlock( self,
        "OS_crane_service_shared_output", sim.packTable( msg or service_output ) )
    
    if msg ~= nil then
        service_output = msg
    end
end
--

--- enable or disable the gripper
function cmd_gripper( flag )
    -- it is a swich by default
    local flag = flag or ( not gripper_status )
    
    if flag then
        -- enable the gripper
        sim.writeCustomDataBlock( gripper_handle, "suction_pad_enabled", "true" )
    else
        -- disable the gripper
        sim.writeCustomDataBlock( gripper_handle, "suction_pad_enabled", "false" )
    end
    
    gripper_status = flag
end
--

--- check the real status of the gripper
function cmd_check_gripper( )
    -- read the status
    gripper_status = ( sim.readCustomDataBlock( gripper_handle, "suction_pad_enabled" ) == "true" )
end
--

--- send a pose to reach to the low level controller
--    as array pos={x,y,z}
function cmd_send_position( pos )
    -- send the pose
    -- print( "[cmd_send_position@OS_crane_service] arg: " )
    -- print( pos )
    -- sim.pauseSimulation( )
    sim.writeCustomDataBlock( crane_driver, 
        "OS_crane_driver_shared_target", sim.packFloatTable( pos ) )
    -- send the signlal
    sim.writeCustomDataBlock( crane_driver,
        "OS_crane_driver_shared_active", sim.packUInt8Table( { 1 } ) )
end
--

--- get the position of the gripper
function cmd_get_ee_position( )
    local data = sim.unpackTable( sim.readCustomDataBlock( crane_driver, "OS_crane_driver_shared" ) )
    return data.current_pose
end
--

--- check the status of the driver
--   RETURNS 'idle', 'busy'
function cmd_check_driver_status( )
    local buf1 = sim.readCustomDataBlock( crane_driver, "OS_crane_driver_shared" )
    local msg = sim.unpackTable( buf1 )
    local buf2 = sim.readCustomDataBlock( crane_driver, "OS_crane_driver_shared_active" )
    local active = sim.unpackUInt8Table( buf2 )
    
    -- print( "[cmd_check_driver_status@OS_crane_service] msg from driver: " )
    -- print( msg )
    -- print( "[cmd_check_driver_status@OS_crane_service] active msg: " )
    -- print( active )
    
    active = active[1] > 0
    
    if msg.busy then
        return "busy", msg, active
    else
        return "idle", msg, active
    end
end
--

--- require infos from the sensor
function cmd_check_slot_sensor( )
    return sim.unpackTable( sim.readCustomDataBlock( sensor_slot_driver, "OS_slot_sensor_shared" ) )
end
--

--- find the pick point position depending on the settings
--    ARGS: true:pick point, false:place point
--    RETURNS: the point, or nil
function cmd_find_point( flag )
    local point = {}
    
    if flag then
        -- find a pick point
        if service_enable_slot_check then
            -- get measurements from the slot sensors
            local sens = cmd_check_slot_sensor( )
            
            -- the slot must be not free
            if sens[working_slot].free then
                return nil
            end
            
            -- find the position of the pick point
            local pick_point_h = sens[working_slot].handle
            point = sim.getObjectPosition( pick_point_h, -1 )
            
        else
            -- take one of the test points
            point = sim.getObjectPosition( pos_test[ working_slot ], -1 )
            
        end
    else
        -- place point
        -- IMPLEMENT THIS!
    end
    
    return point
end
--




-- 
--- ACTIONS AND COMMANDS
--

--- set the robot busy
function sm_set_busy( )
    service_output.busy = true
    service_output.success = false
end
--

--- remove the flag busy
function sm_set_idle_state( flag )
    local flag = flag or true
    
    service_output.busy = false
    service_output.success = flag
end
--

--- command 'pick_ready' as state machine
function sm_pick_ready( )
    local smach = smach_init( )
    local has_init = false
    
    local pack = {
        up_space = 0.1 
    }
    smach.set_shared( smach, pack )
    
    -- before starting
    smach.add_state( smach, "INIT",
        function( self, pack )
            -- the gripper must not have a payload
            if gripper_payload then
                sm_error_description = "[OS_crane_service] command PICK_READY state INIT -- ERROR: the gripper is busy now. Unable to perform the task. "
                return "ERR"
            end
            
            -- compute the pick point
            local pick_point = cmd_find_point( true )
            if pick_point == nil then
                -- error!
                return  "ERR"
            end
            pick_point[3] = pick_point[3] + pack.up_space
            
            -- send the request to the driver
            cmd_send_position( pick_point )
            
            return "GO_TO_POINT"
        end, 
        true
    )
    
    -- movement to the point
    smach.add_state( smach, "GO_TO_POINT",
        function( self, pack )
            -- simply wait until the manipulator is idle again
            if cmd_check_driver_status( ) == "busy" then
                return "GO_TO_POINT"
            else
                return "END"
            end
        end, 
        false
    )
    
    -- the machine ended successfully
    smach.add_state( smach, "END",
        function( self, pack )
            -- end of the job
            return "END"
        end, 
        false
    )
    
    -- some error occurred
    smach.add_state( smach, "ERR",
        function( self, pack )
            -- an error occurred
            return "ERR"
        end, 
        false
    )
    
    return smach, has_init
end
--

--- command 'pick' as state machine
function sm_pick( )
    local smach = smach_init( )
    local has_init = true
    
    pack = {
        pick_point = {},
        up_point = {},
        up_flag = true
    }
    smach.set_shared( smach, pack )
    
    -- init state
    smach.add_state( smach, "INIT",
        function( self, pack )
            -- the gripper must not have a payload
            if gripper_payload then
                sm_error_description = "[OS_crane_service] command PICK state INIT -- ERROR: the gripper is busy now. Unable to perform the task. "
                return "ERR"
            end
            
            -- get measurements from the slot sensors
            sens = cmd_check_slot_sensor( )
            
            -- the slot must be not free
            if sens[working_slot].free then
                sm_error_description = "[OS_crane_service] command PICK state INIT -- ERROR: nothing to grasp. "
                return "ERR"
            end
            
            -- store the poses in the shared data
            pack.pick_point = sim.getObjectPosition( sens[working_slot].handle, -1 )
            pack.up_point = cmd_get_ee_position( )
            
            -- send the first request to the driver
            cmd_send_position( pack.pick_point )
            
            -- enable the gripper
            cmd_gripper( true )
            
            pack.up_flag = true
            return "go_to_point"
        end,
        true
    )
    
    -- reach one given position (flag=true --> downwards path)
    smach.add_state( smach, "go_to_point",
        function( self, pack )
            if cmd_check_driver_status( ) == "idle" then
                -- end effector is idle
                if pack.up_flag then
                    -- idle in pick_point
                    up_flag = false
                    
                    -- send the request for the upwards path
                    cmd_send_position( pack.up_point )
                    
                    return "go_to_point"
                else
                    -- idle in up pos (end of the task)
                    gripper_has_payload = true
                    return "END"
                    
                end
            else
                -- end effector is busy
                return "go_to_point"
            end
        end, 
        false
    )
    
    -- the machine ended successfully
    smach.add_state( smach, "END",
        function( self, pack )
            -- end of the job
            return "END"
        end, 
        false
    )
    
    -- some error occurred
    smach.add_state( smach, "ERR",
        function( self, pack )
            -- an error occurred
            return "ERR"
        end, 
        false
    )
    
    return smach, has_init
end
--

--- command 'place_ready' as state machine
function sm_place_ready( )
    local smach = smach_init( )
    local has_init = true
    
    -- init state
    smach.add_state( smach, "INIT",
        function( self, pack )
            -- the gripper must have a payload
            if not gripper_payload then
                sm_error_description = "[OS_crane_service] command PLACE_READY state INIT -- ERROR: the gripper is carrying nothin. Cannot place. "
                return "ERR"
            end
            
            -- find the place position
            local place_pos = sim.getObjectPosition( pos_place[working_slot], -1 )
            place_pos[3] = place_pos[3] + 0.2
            
            -- send the request to the driver
            cmd_send_position( place_pos )
            
            return "go_to_point"
        end, 
        true
    )
    
    -- movement to the point
    smach.add_state( smach, "go_to_point",
        function( self, pack )
            -- simply wait until the manipulator is idle again
            if cmd_check_driver_status( ) == "busy" then
                return "go_to_point"
            else
                service_output.busy = false
                service_output.success = true
                return "END"
            end
        end, 
        false
    )
    
    -- the machine ended successfully
    smach.add_state( smach, "END",
        function( self, pack )
            -- end of the job
            return "END"
        end, 
        false
    )
    
    -- some error occurred
    smach.add_state( smach, "ERR",
        function( self, pack )
            -- an error occurred
            return "ERR"
        end, 
        false
    )
    
    return smach, has_init
end
--

--- command 'place' as state machine
function sm_place( )
    local smach = smach_init( )
    local has_init = true
    
    pack = {
        place_point = {},
        up_point = {},
        up_flag = true,
        clock_t = -1,
        delay = 0.5
    }
    smach.set_shared( smach, pack )
    
    -- init state
    smach.add_state( smach, "INIT",
        function( self, pack )
            -- the gripper must have a payload to release
            if not gripper_payload then
                sm_error_description = "[OS_crane_service] command PLACE state INIT -- ERROR: the gripper is carrying nothin. Cannot place. "
                return "ERR"
            end
            
            -- find both the positions
            pack.up_point = cmd_get_ee_position( )
            pack.place_point = sim.getObjectPosition( pos_place[working_slot] )
            
            -- send the first request to the driver
            cmd_send_position( pack.place_point )
            
            pack.up_flag = true
            return "go_to_point"
        end,
        true
    )
    
    -- reach one given position (flag=true --> downwards path)
    smach.add_state( smach, "go_to_point",
        function( self, pack )
            if cmd_check_driver_status( ) == "idle" then
                -- the robot is in idle state
                if pack.up_flag then
                    -- the gripper can be turned off
                    --    it requires a dedicated state
                    return "gripper_off"
                    
                else
                    -- the gripper is free and in up position
                    gripper_has_payload = false
                    
                    -- end of the task
                    return "END"
                    
                end
            else
                -- the robot is on move
                return "go_to_point"
            end
        end, 
        false
    )
    
    -- release the object
    smach.add_state( smach, "gripper_off",
        function( self, pack )
            if pack.clock_t < 0 then
                -- turn off the gripper
                cmd_gripper( false )
                
                -- set the timer
                pack.clock_t = sim.getSimulationTime( ) + pack.delay
                
                -- start to count
                return "gripper_off"
                
            elseif sim.getSimulationTime( ) >= pack.clock_t then
                -- time to move!
                cmd_send_position( pack.up_point )
                pack.up_flag = false
                
                return "move_to_point"
            end
        end, 
        false
    )
    
    -- some error occurred
    smach.add_state( smach, "ERR",
        function( self, pack )
            -- an error occurred
            return "ERR"
        end, 
        false
    )
    
    -- the machine ended successfully
    smach.add_state( smach, "END",
        function( self, pack )
            -- all done!
            return "END"
        end, 
        false
    )
    
    return smach, has_init
end
--

--- command 'idle' as state machine
function sm_idle( )
    local smach = smach_init( )
    local has_init = false
    
    -- init state
    smach.add_state( smach, "INIT",
        function( self, pack )
            print( "[OS_crane_service, idle:INIT]" )
            
            -- get the rest position
            local idle_point = sim.getObjectPosition( pos_idle[working_slot], -1 )
            
            -- send the command to the robot
            -- print( "[state_action@OS_crane_service] idle point selected:" )
            -- print( idle_point )
            cmd_send_position( idle_point )
            
            print( "[OS_crane_service, idle:go_to_point]" )
            return "go_to_point"
        end,
        true
    )
    
    -- reach one given position (flag=true --> downwards path)
    smach.add_state( smach, "go_to_point",
        function( self, pack )
            local status = ""
            local msg = {}
            local active_flag = false
            status, msg, active_flag = cmd_check_driver_status( )
            -- print( "[OS_crane_service, idle:go_to_point] " )
            -- print( "[OS_crane_service, idle:go_to_point] active=" .. tostring(active_flag) )
            -- print( "[OS_crane_service, idle:go_to_point] status='" .. status .. "'" )
            -- print( "[OS_crane_service, idle:go_to_point] msg: " )
            -- print( msg )
            -- simply wait until the manipulator is idle again
            if status == "busy" then
                -- print( "[state_action@OS_crane_service] driver busy, waiting..." )
                return "go_to_point"
            else
                return "END"
            end
        end, 
        false
    )
    
    -- some error occurred
    smach.add_state( smach, "ERR",
        function( self, pack )
            print( "[OS_crane_service, idle:ERR]" )
            -- an error occurred
            return "ERR"
        end, 
        false
    )
    
    -- the machine ended successfully
    smach.add_state( smach, "END",
        function( self, pack )
            print( "[OS_crane_service, idle:END]" )
            -- all done!
            return "END"
        end, 
        false
    )
    
    return smach, has_init
end
--

--- read an extern command (not empty!)
function select_cmd( )
    local c = string.lower(service_input.cmd)
    local val = service_input.value
    local has_init = false
    local sm = {}
    
    print( "[select_cmd@OS_crane_service] RECEIVED COMMAND --> " 
        .. " { cmd='" .. c .. "', value='" .. val .. "' }" )
    
    -- CONDITION: the machine is not working
    if cur_cm ~=nil then
        print( "[select_cmd@OS_crane_service]" 
            .. "ERROR: crane is busy; cannot change slot" )
        sm = cur_sm
    
    
    -- AVAILABLE COMMANDS
    elseif c == "slot" then
        if val > 0 and val < 4 and not gripper_has_payload then
            working_slot = val
            print( "[select_cmd@OS_crane_service]" 
                .. "SLOT: new slot is " .. working_slot )
        else
            print( "[select_cmd@OS_crane_service]" 
            .. "ERROR: slot " .. val .. "doesn't exist." )
        end
        sm = nil
        
    elseif c == "pick_ready" then
        -- set the machine for the command "pick ready"
        sm, has_init = sm_pick_ready( )
        
    elseif c == "pick" then
        -- pick command
        sm, has_init = sm_pick( )
        
    elseif c == "place_ready" then
        sm, has_init = sm_place_ready( )
        
    elseif c == "place" then
        sm, has_init = sm_place( )
    
    elseif c == "idle" then
        sm, has_init = sm_idle( )
    
    
    -- ERROR command not recognized
    else
        print( "[select_cmd@OS_crane_service]" 
            .. "ERROR: command not defined." )
        sm = cur_sm
    end
    
    return sm, has_init
end
--




--
--- INIT AND SETUP
--

--- setup of the task system
function task_sys_setup( )
    -- status of the gripper
    gripper_handle = sim.getObjectHandle( "suctionPad" )
    gripper_status = false
    gripper_has_payload = false
    
    -- low level controller
    crane_driver = sim.getObjectHandle( "OS_crane_driver" )
    
    -- task
    -- the slot currently handled
    working_slot = 2
    -- current state machine (if needed)
    cur_sm = nil
    -- error description
    sm_error_description = ""
    
    -- slot sensor handle
    sensor_slot_driver = sim.getObjectHandle( "OS_slot_sensors" )
    
    -- system positions
    pos_idle = {
        sim.getObjectHandle( "OS_poses_idle_1" ),
        sim.getObjectHandle( "OS_poses_idle_2" ),
        sim.getObjectHandle( "OS_poses_idle_3" )
    }
    pos_place = {
        sim.getObjectHandle( "OS_oiltray_place_point" ),
        sim.getObjectHandle( "OS_fuelpump_place_point" ),
        sim.getObjectHandle( "OS_camshaft_place_point" ),
    }
    
    -- use them when the slot checking is not enabled
    pos_test = {
        sim.getObjectHandle( "slot_1_center" ),
        sim.getObjectHandle( "slot_2_center" ),
        sim.getObjectHandle( "slot_3_center" )
    }
    
end
-- 

--- init
function sysCall_init()
    self = sim.getObjectHandle( sim.handle_self )
    
    -- expose the services
    service_setup( )
    
    -- setup the task system
    task_sys_setup( )
end
--




--
--- EXECUTION
--

--- 
function sysCall_actuation()
    -- update the input
    service_update_input( )
    
    -- check for new tasks
    if service_input.cmd ~= "" then
        -- setup the task
        local has_init = false
        cur_sm, has_init = select_cmd( )
        
        -- the input was "consumed"
        service_input = service_empty_input
        
        -- execute the setup if needed
        if has_init then
            -- ececute the first state
            if cur_sm.exec( cur_sm ) == "ERR" then
                -- setup failed
                -- clear the current task
                cur_sm = nil
                
                -- set the output message 
                sm_set_idle_state( false )
                -- service_output.err_code = sm_error_code
                service_output.err_str = sm_error_description
            end
        end
        
        -- set the output as busy
        sm_set_busy( )
    end
    
    -- execute the previous command
    if cur_sm ~= nil then
        -- print( "[sysCall_actuation@OS_crane_service] current state machine: " )
        -- print( cur_sm )
        -- print( cur_sm.state_name )
        
        -- execute the step of the machine
        cur_sm.exec( cur_sm )
        
        -- check the state of the machine
        --    consume the machine if the machine has ended its work
        -- print( "[sysCall_actuation@OS_crane_service] second state: " .. cur_sm.state_name )
        if cur_sm.state_name == "ERR" then
            sm_set_idle_state( false )
            service_output.err_str = sm_error_description
            cur_sm = nil
            
        elseif cur_sm.state_name == "END" then
            sm_set_idle_state( true )
            service_output.err_str = ""
            cur_sm = nil
            
        end
    end
    
    -- publish the new state
    service_update_output( )
end
--