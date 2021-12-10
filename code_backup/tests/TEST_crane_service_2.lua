--[[
    TEST_crane_service_2
        the test wants to try out the command 'pick_ready'
    
    HOW THIS TEST WORKS
    Before starting, turn off the checking on the slots. 
    1. select cyclically the slot (see first test) and send the "slot" command
    2. send the command "pick_ready" to the service
    3. then, wait
    4. return to the idle position, then change slot
    This test is the starting point for the next test on "pick_ready" and "pick"
--]]

--- empty state machine
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

--- send a command to the service
function send_command_to_service( cmd, value )
    local value = value or -1
    
    local msg = { cmd=cmd, value=value }
    sim.writeCustomDataBlock( crane_service, 
        "OS_crane_service_shared_input", sim.packTable( msg ) )
end
--

--- get the status of the service
function get_status_service( )
    return sim.unpackTable( 
        sim.readCustomDataBlock( crane_service, "OS_crane_service_shared_output" ) )
end
--

--- setup state
--    select cyclically the slot (see first test) and send the "slot" command
function state_setup( smach, pack )
	sm_frame_update( pack, smach )
	
    -- compute the next idx
	next_idx( )
    sm_print( pack, "sending the 'slot' command (slot:" .. pose_idx .. ")" )
    send_command_to_service( "slot", pose_idx )
    
    sm_print( pack, "--> " .. "send_pick_ready" )
    return "send_pick_ready"
end
--

--- send the command pick_ready
function state_send_pick_ready( smach, pack )
	sm_frame_update( pack, smach )
	
	sm_print( pack, "sending command 'pick_ready'" )
    send_command_to_service( "pick_ready" )
    sm_print( pack, "waiting the next frame..." )
    
    sm_print( pack, "--> " .. "check_pick_ready" )
    return "check_pick_ready"
end
--

--- check the init state of pick_ready
function state_check_pick_ready( smach, pack )
    sm_frame_update( pack, smach )
    sm_print( pack, "waiting the next frame...OK" )
    
    local msg = get_status_service( )
    sm_print( pack, "service response: ", msg )
    
    -- the busy flag must be true
    if msg.busy then
        -- allright
        sm_print( pack, "--> " .. "run_pick_ready" )
        return "run_pick_ready"
        
    else
        -- unexpected state!
        sm_print( pack, "UNEXPECTED: msg.busy=" .. tostring(msg.busy) .. " (expected: true)" )
        
        pack.err_state = "check_pick_ready"
        pack.err_last_data = msg
        err_report = true
        
        return "ERROR"
    end
end
--

--- wait until the service is not busy
function state_run_pick_ready( smach, pack )
    sm_frame_update( pack, smach )
    
    -- check the status
    local msg = get_status_service( )
    
    if msg.busy then
        -- keep waiting
        return "run_pick_ready"
        
    else
        -- end of the waiting - all done!
        sm_print( pack, "pick ready complete! last message: ", msg )
        
        sm_print( pack, "--> " .. "END" )
        return "END"
    end
end
--

--- typical "ERROR" implementation
function state_handle_err( smach, pack )
	sm_frame_update( pack, smach )
	
	-- error report (only once)
	if pack.err_report then
		pack.err_report = false
		cprint( "state_handle_err", "ERROR on state '" .. pack.err_state .. "'" )
		cprint( "state_handle_err", "last service message: ", pack.err_last_msg )
    end
    -- stop the simulation
    sim.stopSimulation( )
	
	-- error state forever (fatal error)
	return "ERROR"
end
--

--- END state
function state_end( smach, pack )
    sm_frame_update( pack, smach )
    
    return "SETUP"
end
--

--- frame update
function sm_frame_update( pack, smach, funct )
    local funct = fnct or ""
	
	-- frame count
	pack.frame_count = pack.frame_count + 1
	
	-- function name (nil if not needed)
	pack.funct_name = funct
	
	-- state name (nil is allowed)
	pack.state_name = smach.state_name
end
--

--- print a custom message
--    IT CANNOT PRINT nil VALUES!
function sm_print( pack, msg, data )
    local data = data or nil
	local msg = msg or ""
    local prefix = "["
	
	-- function name
	if not(pack.funct_name == "") then
		prefix = prefix .. pack.funct_name .. "@"
	end
	
	-- scrpt name
	prefix = prefix .. pack.script_name
	
	-- frame count
	prefix = prefix .. ", f:" .. pack.frame_count
	
	-- state string
	if not(pack.state == "") then
		prefix = prefix .. ", " .. pack.state_name
	end
	
	-- end of the header
	prefix = prefix .. "] "
	
    -- print the message
    print( prefix .. msg )
	
	-- print also the data if any
    if data ~=nil then
        print( data )
    end
end
--

--- get the pack with the basic infos
function sm_get_pack( scr_name )
	return {
		-- frame management
		frame_count = 0, 
		frame_prev = -1, 
		
		-- double-state
		flag = false,
		
		-- error handling
		err_state = "",
		err_last_data = {},
		err_warn_pause = false,
		err_report = false,
		
		-- print with sm_print( )
		funct_name = "",
		state_name = "",
		script_name = scr_name
	}
end
--

--- setup the state machine
function sm_machine_setup( )
    local sm = smach_init( )
	
	-- set the shared data
	local pack = sm_get_pack( "TEST_crane_service_2" )
	sm.set_shared( sm, pack )
    
	-- states
    sm.add_state( sm, "SETUP", state_setup, true )
    sm.add_state( sm, "send_pick_ready", state_send_pick_ready, false )
    sm.add_state( sm, "check_pick_ready", state_check_pick_ready, false )
    sm.add_state( sm, "run_pick_ready", state_run_pick_ready, false )
    sm.add_state( sm, "END",  state_end, false )
    sm.add_state( sm, "ERROR", state_handle_err, false )
	
	return sm
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

---
function sysCall_init()
    enabled = false
    
    -- handle to the service
    crane_service = sim.getObjectHandle( "OS_crane_service" )
    
    -- state machine 
    sm = sm_machine_setup( )
    
    -- operation control
    pose_idx = 1
    
    -- disable slot checking
    sim.writeCustomDataBlock( crane_service, 
        "OS_crane_service_shared_enable_slot_check", "false" ) --> disable
end
--

---
function sysCall_actuation()
    if enabled then
        sm.exec( sm )
        if sm.state_name == "ERROR" or sm.state_name == "WARNING" then
            sm.exec( sm ) -- error handling state
        end
    end
end
--