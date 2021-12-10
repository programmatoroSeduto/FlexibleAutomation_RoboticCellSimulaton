--[[
    TEST_crane_driver_2
        a simple state machine. Move the crane among the three idle positions. 
--]]




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

--- select one final position
function state_select_position( self, pack )
    local next
    local next_p 
    next, next_p = next_pose( )
    cprint( "state_select_position", "next=" .. tostring(next) )
    cprint( "state_select_position", "next_p=", next_p )
    cprint( "state_select_position", "pose idx(" .. next .. ") pose: ", next_p )
    
    cprint( "state_select_position", "sending the command to the crane..." )
    sim.writeCustomDataBlock( driver, 
        "OS_crane_driver_shared_target", sim.packFloatTable( next_p ) )
    sim.writeCustomDataBlock( driver,
        "OS_crane_driver_shared_active", sim.packUInt8Table( { 1 } ) )
    
    frame_count = 0
    
    cprint( "state_select_position", "to state --> move_to" )
    return "move_to"
end
--

--- move to the position
-- cprint( "state_move_to", "" )
function state_move_to( self, pack )
    -- check the status of the driver
    local data = sim.unpackTable(
        sim.readCustomDataBlock( driver, "OS_crane_driver_shared" )
        )
    local active = sim.unpackUInt8Table(
        sim.readCustomDataBlock( driver, "OS_crane_driver_shared_active" )
        )[1]
    
    -- print once
    if frame_count == 0 then
        cprint( "state_move_to", "(before starting the task) active=" .. active )
        cprint( "state_move_to", "first package returned from the driver is: ", data )
    end
    frame_count = frame_count + 1
    
    if data.busy then
        -- keep going
        return "move_to"
        
    else
        -- end pos reached
        cprint( "state_select_position", "to state --> select_position (in " 
            .. frame_count .. " frames)" )
        cprint( "state_move_to", "(end of the task) active=" .. active )
        cprint( "state_move_to", "last package returned from the driver is: ", data )
        
        return "select_position"
        
    end
end
--

--- setup the state machine
function test_sm_setup( )
    sm = smach_init( )
    
    sm.add_state( sm, "select_position", state_select_position, true  )
    sm.add_state( sm, "move_to",         state_move_to,         false )
end
--

--- change idx
function next_pose( )
    -- next idx
    pose_idx = pose_idx + 1
    if pose_idx > 3 then
        pose_idx = 1
    end
    
    -- return index and pose at that index
    return pose_idx, poses[pose_idx]
end
--

--- print a custom message
function cprint( funct, msg, data )
    local data = data or nil
    local prefix = "[" .. funct .. "@TEST_crane_driver_2] "
    print( prefix .. msg )
    if data ~=nil then
        print( data )
    end
end
--

---
function sysCall_init()
    enabled = false
    
    -- the driver
    driver = sim.getObjectHandle( "OS_crane_driver" )
    
    -- points
    poses = {
        sim.getObjectPosition( sim.getObjectHandle( "OS_poses_idle_" .. 1 ), -1 ),
        sim.getObjectPosition( sim.getObjectHandle( "OS_poses_idle_" .. 2 ), -1 ),
        sim.getObjectPosition( sim.getObjectHandle( "OS_poses_idle_" .. 3 ), -1 )
    }
    pose_idx = 2
    
    -- frame counter
    frame_count = 0
    
    -- state machine
    test_sm_setup( )
end
--

---
function sysCall_actuation()
    if enabled then
        sm.exec( sm )
    end
end
--

--[[ LAST OUTPUT
[sandboxScript:info] Simulation started.
[sysCall_init@TEST_crane_driver] pose to reach: 
{0.69999748468399, -0.074077606201172, 0.70239019393921}
[state_select_position@TEST_crane_driver_2] next=3
[state_select_position@TEST_crane_driver_2] next_p=
{0.69999748468399, 0.92592310905457, 0.70239019393921}
[state_select_position@TEST_crane_driver_2] pose idx(3) pose: 
{0.69999748468399, 0.92592310905457, 0.70239019393921}
[state_select_position@TEST_crane_driver_2] sending the command to the crane...
[state_select_position@TEST_crane_driver_2] to state --> move_to
[state_move_to@TEST_crane_driver_2] (before starting the task) active=1
[state_move_to@TEST_crane_driver_2] first package returned from the driver is: 
{
        active=true,
        busy=true,
        current_pose={0.44999778270721, -0.049077481031418, 0.67738997936249},
        target={0.69999748468399, 0.92592310905457, 0.70239019393921},
        threshold=0.0010000000474975,
    }
[state_select_position@TEST_crane_driver_2] to state --> select_position (in 204 frames)
[state_move_to@TEST_crane_driver_2] (end of the task) active=0
[state_move_to@TEST_crane_driver_2] last package returned from the driver is: 
{
        active=false,
        busy=false,
        current_pose={0.69999748468399, 0.92592298984528, 0.70239019393921},
        target={0.69999748468399, 0.92592310905457, 0.70239019393921},
        threshold=0.0010000000474975,
    }
[state_select_position@TEST_crane_driver_2] next=1
[state_select_position@TEST_crane_driver_2] next_p=
{0.69999748468399, -1.0240786075592, 0.70239019393921}
[state_select_position@TEST_crane_driver_2] pose idx(1) pose: 
{0.69999748468399, -1.0240786075592, 0.70239019393921}
[state_select_position@TEST_crane_driver_2] sending the command to the crane...
[state_select_position@TEST_crane_driver_2] to state --> move_to
[state_move_to@TEST_crane_driver_2] (before starting the task) active=1
[state_move_to@TEST_crane_driver_2] first package returned from the driver is: 
{
        active=true,
        busy=true,
        current_pose={0.69999748468399, 0.92592298984528, 0.70239019393921},
        target={0.69999748468399, -1.0240786075592, 0.70239019393921},
        threshold=0.0010000000474975,
    }
[state_select_position@TEST_crane_driver_2] to state --> select_position (in 392 frames)
[state_move_to@TEST_crane_driver_2] (end of the task) active=0
[state_move_to@TEST_crane_driver_2] last package returned from the driver is: 
{
        active=false,
        busy=false,
        current_pose={0.69999754428864, -1.0240769386292, 0.70239019393921},
        target={0.69999748468399, -1.0240786075592, 0.70239019393921},
        threshold=0.0010000000474975,
    }
[state_select_position@TEST_crane_driver_2] next=2
[state_select_position@TEST_crane_driver_2] next_p=
{0.69999748468399, -0.074077606201172, 0.70239019393921}
[state_select_position@TEST_crane_driver_2] pose idx(2) pose: 
{0.69999748468399, -0.074077606201172, 0.70239019393921}
[state_select_position@TEST_crane_driver_2] sending the command to the crane...
[state_select_position@TEST_crane_driver_2] to state --> move_to
[state_move_to@TEST_crane_driver_2] (before starting the task) active=1
[state_move_to@TEST_crane_driver_2] first package returned from the driver is: 
{
        active=true,
        busy=true,
        current_pose={0.69999754428864, -1.0240769386292, 0.70239019393921},
        target={0.69999748468399, -0.074077606201172, 0.70239019393921},
        threshold=0.0010000000474975,
    }
[state_select_position@TEST_crane_driver_2] to state --> select_position (in 192 frames)
[state_move_to@TEST_crane_driver_2] (end of the task) active=0
[state_move_to@TEST_crane_driver_2] last package returned from the driver is: 
{
        active=false,
        busy=false,
        current_pose={0.69999754428864, -0.074077606201172, 0.70239019393921},
        target={0.69999748468399, -0.074077606201172, 0.70239019393921},
        threshold=0.0010000000474975,
    }
[state_select_position@TEST_crane_driver_2] next=3
[state_select_position@TEST_crane_driver_2] next_p=
{0.69999748468399, 0.92592310905457, 0.70239019393921}
[state_select_position@TEST_crane_driver_2] pose idx(3) pose: 
{0.69999748468399, 0.92592310905457, 0.70239019393921}
[state_select_position@TEST_crane_driver_2] sending the command to the crane...
[state_select_position@TEST_crane_driver_2] to state --> move_to
[state_move_to@TEST_crane_driver_2] (before starting the task) active=1
[state_move_to@TEST_crane_driver_2] first package returned from the driver is: 
{
        active=true,
        busy=true,
        current_pose={0.69999754428864, -0.074077606201172, 0.70239019393921},
        target={0.69999748468399, 0.92592310905457, 0.70239019393921},
        threshold=0.0010000000474975,
    }
[state_select_position@TEST_crane_driver_2] to state --> select_position (in 202 frames)
[state_move_to@TEST_crane_driver_2] (end of the task) active=0
[state_move_to@TEST_crane_driver_2] last package returned from the driver is: 
{
        active=false,
        busy=false,
        current_pose={0.69999748468399, 0.92592239379883, 0.70239019393921},
        target={0.69999748468399, 0.92592310905457, 0.70239019393921},
        threshold=0.0010000000474975,
    }
[state_select_position@TEST_crane_driver_2] next=1
[state_select_position@TEST_crane_driver_2] next_p=
{0.69999748468399, -1.0240786075592, 0.70239019393921}
[state_select_position@TEST_crane_driver_2] pose idx(1) pose: 
{0.69999748468399, -1.0240786075592, 0.70239019393921}
[state_select_position@TEST_crane_driver_2] sending the command to the crane...
[state_select_position@TEST_crane_driver_2] to state --> move_to
[state_move_to@TEST_crane_driver_2] (before starting the task) active=1
[state_move_to@TEST_crane_driver_2] first package returned from the driver is: 
{
        active=true,
        busy=true,
        current_pose={0.69999748468399, 0.92592239379883, 0.70239019393921},
        target={0.69999748468399, -1.0240786075592, 0.70239019393921},
        threshold=0.0010000000474975,
    }
[sandboxScript:info] simulation stopping...
[sandboxScript:info] Simulation stopped.
--]]