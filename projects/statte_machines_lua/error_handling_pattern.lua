--[[
	HOW TO USE IT:
	- the state "ERROR" is used for handling fatal errors
		the simulation is stopped and the machine stays forever in "ERROR" state
	- the state "WARNING" is applyed for unexpected, but not-fatal, situations
		the simulation can be paused or not
	- the state "SETUP" should contain some setup utilities for the machine
	States "ERROR" and "WARNING" are meant to be executed along with the state which
		has issued the error in the same frame.
		Just for giving you a more precise idea, see this algorithm:
	function sysCall_actuation()
		if enabled then
			sm.exec( sm )
			if sm.state_name == "ERROR" or sm.state_name == "WARNING" then
				sm.exec( sm ) -- error handling state
			end
		end
	end
	
	LOG CONVENTIONS
	always use sm_print( ) to print something to the console: it will make your 
	log more readable. 
	Here are some other conventions you should take into account when you write
	a message to the console:
	- TRANSITION LOG
		[funct@script, frame, state] --> next_state
	- WAIT-RESOLVE LOG
	first frame:
		[funct@script, frame, state] waiting something...
	when the action is completed:
		[funct@script, frame, state] waiting something...OK
	for instance: start one action at frame 100, which is complete at frame 102
	
--]]



--
--- HANDLED STATE MACHINE PATTERN
--

--- frame update
function sm_frame_update( pack, state, funct )
    local funct = fnct or ""
	local state = state or ""
	
	-- frame count
	pack.frame_count = pack.frame_count + 1
	
	-- function name (nil if not needed)
	pack.funct_name = funct
	
	-- state name (nil is allowed)
	pack.state_name = state
end
--

--- print a custom message
--    IT CANNOT PRINT nil VALUES!
function sm_print( pack, msg, data )
    local data = data or nil
	local msg = msg or ""
    local prefix = "["
	
	-- function name
	if not(pack.funct == "") then
		prefix = prefix .. pack.funct_name .. "@"
	end
	
	-- scrpt name
	prefix = prefix .. pack.script_name
	
	-- frame count
	prefix = prefix .. ", f:" .. pack.frame_count
	
	-- state string
	if not(pack.state == "") then
		prefix = prefix .. ", " .. pack.state
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
	local pack = sm_get_pack( ) --> TODO: set the name of the script
	sm.set_shared( sm, pack )
    
	-- states
    sm.add_state( sm, "SETUP", state_setup, true )
    -- sm.add_state( sm, "",  funct,   false )
    sm.add_state( sm, "ERROR", state_handle_err, false )
    sm.add_state( sm, "WARNING", state_handle_warn, false )
	
	return sm
end
--




--
--- STATE PATTERNS
--

--- typical implementation
function state_proto( smach, pack )
	frame_update( )
	
	--- ... implementation of the state
end
--

--- double-state pattern
function state_double( smach, pack )
	frame_update( )
	
	if not pack.flag then
		-- first iteration
		pack.flag = true
		
		-- ... init of the double state
		
		return "state_double"
		
	else
		-- n-th iteration > first
		if condition then -- set the condition you want
			pack.flag = false
			
			-- ... end iteration of the double state
			
			return "next_state"
			
		else
			-- keep going
			return "state_double"
		end
		
	end
end
--

--- typical "ERROR" implementation
function state_handle_err( smach, pack )
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

--- typical "WARNING" implementation
--    resume the execution from another state
--    pack.err_report is set by another state as well as pack.err_warn_pause
function state_handle_warn( self, pack )
    -- error report
	if pack.err_report then
		cprint( "state_handle_err", "WARNING on state '" .. pack.err_state .. "'" )
		cprint( "state_handle_err", "last service message: ", pack.err_last_msg )
	end
    
    -- pause the simulation
	if pack.err_warn_pause == true then
		sim.pauseSimulation( )
	end
    
    -- restore the error handling procedure
    local to_state = pack.err_state
    err_state = ""
    err_last_msg = {}
    
    cprint( "state_handle_warn", "resuming --> " .. to_state )
    return to_state
end
--

