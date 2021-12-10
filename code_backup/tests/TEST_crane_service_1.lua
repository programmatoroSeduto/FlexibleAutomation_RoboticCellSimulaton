--[[
    TEST_crane_driver_1
        test on the simple command "idle" in steps:
        1. set cyclically a working slot
        2. move the crane in the idle position of the selected slot
        the module 'OS_crane_service' is tested here, using a simple state machine. 
--]]

--- print a custom message
function cprint( funct, msg, data )
    local data = data or nil
    local prefix = "[" .. funct .. "@TEST_crane_service_1](f:" .. frame_count .. ")"
    
    print( prefix .. msg )
    if data ~=nil then
        print( data )
    end
end
--

--- frame update
function frame_update( )
    frame_count = frame_count + 1
end
--

--- init state machine
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

--- prepare the test
-- cprint( "state_setup_test", "" )
function state_setup_test( self, pack )
    -- select the slot
    next_idx( )
    cprint( "state_setup_test", "selected idx: " .. pose_idx )
    
    cprint( "state_setup_test", "--> " .. "send_slot" )
    return "send_slot"
end
--

--- send the command "slot"
-- cprint( "state_send_slot", "" )
function state_send_slot( self, pack )
    cprint( "state_send_slot", "sending 'slot' command..." )
    local msg = { cmd="slot", value=pose_idx }
    sim.writeCustomDataBlock( crane_service, "OS_crane_service_shared_input", sim.packTable( msg ) )
    cprint( "state_send_slot", "waiting next frame..." )
    
    cprint( "state_send_slot", "--> " .. "send_idle" )
    return "send_idle"
end
--

--- send the command "idle"
-- cprint( "state_send_idle", "" )
function state_send_idle( self, pack )
    cprint( "state_send_idle", "waiting next frame... OK" )
    local msg = sim.unpackTable( sim.readCustomDataBlock( crane_service, "OS_crane_service_shared_output" ) )
    cprint( "state_send_idle", "state of the service after the command slot: ", msg )
    
    cprint( "state_send_idle", "sending 'idle' command... " )
    msg = { cmd="idle", value=-1 }
    sim.writeCustomDataBlock( crane_service, "OS_crane_service_shared_input", sim.packTable( msg ) )
    cprint( "state_send_idle", "waiting next frame..." )
    
    cprint( "state_send_idle", "--> " .. "move_to" )
    return "move_to"
end
--

--- wait until the robot has reached the end position
-- cprint( "state_move_to", "" )
function state_move_to( self, pack )
    local msg = sim.unpackTable( sim.readCustomDataBlock( crane_service, "OS_crane_service_shared_output" ) )
    
    if not frame_flag then
        frame_prev = frame_count
        frame_flag = true
        
        -- first frame: check if the reaction to the command is correct
        cprint( "state_move_to", "waiting next frame... OK" )
        cprint( "state_move_to", "state of the service the frame after the command 'idle': ", msg )
        if not msg.busy then
            cprint( "state_move_to", "service is not busy (UNEXPECTED)" )
            
            -- unexpected status
            err_state = "move_to"
            err_last_msg = msg
            
            cprint( "state_move_to", "--> " .. "UNEXPECTED" )
            return "UNEXPECTED"
            
        else
            -- all right
            cprint( "state_move_to", "service is busy (OK) success=" .. tostring(msg.success) )
            cprint( "state_move_to", "movement phase..." )
            
            cprint( "state_move_to", "--> " .. "move_to" )
            return "move_to"
        end
        
    else
        -- check the status
        if msg.busy then
            -- check if the machine is moving (max 1000 frames)
            if ( frame_count - frame_prev ) % 1000 == 0 then
                -- something strange is happening
                cprint( "state_move_to", "the service is requiring too much time! (is it correct?) " )
                
                -- unexpected status
                err_state = "move_to"
                err_last_msg = msg
                
                cprint( "state_move_to", "--> " .. "WARNING" )
                return "WARNING"
            else
                -- keep going
                return "move_to"
            end
            
        else
            frame_flag = false
            
            -- idle success
            cprint( "state_move_to", "movement phase...OK" )
            cprint( "state_move_to", "state of the service at the end of the task: ", msg )
            
            cprint( "state_move_to", "--> " .. "setup_test" )
            return "setup_test"
        end
        
    end
end
--

--- handle a unexpected situation
-- cprint( "state_handle_err", "" )
function state_handle_err( self, pack )
    -- error report
    cprint( "state_handle_err", "ERROR on state '" .. err_state .. "'" )
    cprint( "state_handle_err", "last service message: ", err_last_msg )
    
    -- stop the simulation
    sim.stopSimulation( )
end
--

--- handle a warning
-- cprint( "state_handle_warn", "" )
function state_handle_warn( self, pack )
    -- error report
    cprint( "state_handle_err", "WARNING on state '" .. err_state .. "'" )
    cprint( "state_handle_err", "last service message: ", err_last_msg )
    
    -- pause the simulation
    sim.pauseSimulation( )
    
    -- restore the error handling procedure
    local to_state = err_state
    err_state = ""
    err_last_msg = {}
    
    cprint( "state_handle_warn", "resuming --> " .. to_state )
    return to_state
end
--

--- setup the state machine
function state_machine_setup( )
    sm = smach_init( )
    
    sm.add_state( sm, "setup_test", state_setup_test,  true  )
    sm.add_state( sm, "send_slot",  state_send_slot,   false )
    sm.add_state( sm, "send_idle",  state_send_idle,   false )
    sm.add_state( sm, "move_to",    state_move_to,     false )
    sm.add_state( sm, "UNEXPECTED", state_handle_err,  false )
    sm.add_state( sm, "WARNING",    state_handle_warn, false )
end
--

--- change idx
function next_idx( )
    -- next idx
    pose_idx = pose_idx + 1
    if pose_idx > 3 then
        pose_idx = 1
    end
end
--

--- setup the test
function sysCall_init()
    enabled = true
    
    -- handle to the service
    crane_service = sim.getObjectHandle( "OS_crane_service" )
    
    -- state machine 
    state_machine_setup( )
    pose_idx = 1
    
    -- frame count and others
    frame_count = 0
    frame_prev = -1
    frame_flag = false
    
    -- error handling
    err_state = ""
    err_last_msg = {}
end
--

---
function sysCall_actuation()
    if enabled then
        frame_update( )
        sm.exec( sm )
        if sm.state_name == "UNEXPECTED" or sm.state_name == "WARNING" then
            sm.exec( sm ) -- error handling state
        end
    end
end
--

--[[

--]]