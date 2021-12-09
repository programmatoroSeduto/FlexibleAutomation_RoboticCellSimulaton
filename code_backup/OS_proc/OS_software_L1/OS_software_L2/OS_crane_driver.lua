--[[
    OS_crane_driver
        low level control for the crane as state machine
    
    SHARED DATA:
    --> READ ONLY
    OS_crane_driver_shared:
        - target {x, y, z} : the previously provided target (default: vector zero)
        - threshold : (positive float) the previously setted threshold
        - busy (bool) : this flag indicates when the manipulator is working or not
        - current_pose {x, y, z} : the current position of the end effector
    --> WRITE ONLY
    OS_crane_driver_shared_active (0, 1) : this flag is exposed to the upper-level program and 
        specifies when the controller has an objective or not.
        if the flag is activated, the system checks for aobjective position;
        if the position is not valid, the operation is aborted
    OS_crane_driver_shared_target {x, y, z} : 
        the objective position for the end effector
    OS_crane_driver_shared_threshold (positive float) : 
        the threshold to consider the EE arrived into a certain position
    
    HOW TO USE IT:
    in order to start the motion, write on the shared vars (in this precise order):
        OS_crane_driver_shared_target = { x, y, z }
        OS_crane_driver_shared_active = 1
    If you want to set the threshold, set this:
        OS_crane_driver_shared_threshold = float
    when the motion starts, you could
        - wait until OS_crane_driver_shared.busy is false (end of the path)
        - or write '0' on OS_crane_driver_shared_active (forced stop)
--]]
--



--
--- OTHER FUNCTIONS
--

--- compute the eucledian distance between two positions
function distance_between( A, B )
    return math.sqrt(
        (A[1] - B[1])*(A[1] - B[1]) + 
        (A[2] - B[2])*(A[2] - B[2]) + 
        (A[3] - B[3])*(A[3] - B[3])
    )
end
--




--
--- STATE MACHINE
--

--- obtain an empty machine
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

--- prepare the settings for moving the robot
function crane_set_movement( pack )
    -- update shared data before starting
    shared_data.busy = true
    shared_data.current_pose = sim.getObjectPosition( pack.pointer, -1 )
    
    -- compute the new path
    local new_pose = { shared_data.target[1], shared_data.target[2], shared_data.target[3], 0.0, 0.0, 0.0, 1.0 }
    pack.path = path_init( pack.pointer, new_pose )
    
    -- set the path
    pack.path.velocity = pack.vel
    pack.path.toll = shared_data.threshold
end
--

--- stop the motion
function crane_stop_movement( pack )
    -- update the shared data
    shared_data.active = false
    shared_data.busy = false
    
    -- remove the path
    sim.removeModel( pack.path.handle )
    pack.path = nil
    
    -- clear the flags
    shared_clear_active_flag( )
end
--

--- implementation of state IDLE
function state_idle( self, pack )
    if shared_data.active then
        -- check the position first
        if #shared_data.target < 3 or #shared_data.target > 3 then
            -- the target is not valid (IMPROVE THIS CHECK!)
            shared_data.target = {0.0, 0.0, 0.0}
            shared_data.active = false
            print( "[state_idle@OS_crane_driver] ERROR: not a valid target!" )
            
            shared_clear_active_flag( )
            
            return "idle"
        end
        
        -- compute a new path
        crane_set_movement( pack )
        
        -- start the movement
        return "move"
        
    else
        -- keep going
        return "idle"
        
    end
end
--

--- go to point
function state_move( self, pack )
    -- check if the operation was blocked
    if not shared_data.active then
        -- stop the motion
        crane_stop_movement( pack )
        
        -- return in idle state
        return "idle"
    end
    
    -- execute the movement
    local res = path_move( pack.path, pack.vel )
    
    -- evaluate the distance from the desided position
    shared_data.current_pose = sim.getObjectPosition( pack.pointer, -1 )
    -- print( distance_between( shared_data.current_pose, shared_data.target ) )
    if res then
        -- final position reached!
        crane_stop_movement( pack )
        
        -- return in idle state
        return "idle"
    else
        -- keep moving
        return "move"
    end
end
--




--
--- TRAJECTORIES
--

--- create the path from A to B
--    or update a previously set path by giving it from path_obj
--    the handle_A is the starting 'pointer'
--        and handle_B is the initial 'target'
-- RETURNS the new path object
--[[
    OBJECT path :
        pointer                     -- the point to move along the path
        target                      -- handle of the destination dummy
        pose_start                  -- the starting pose (#=7)
        pose_end                    -- the objective pose (#=7)
        pose_serialized             -- the serialization of the poses (#=14)
        
        path_infos.chunks           -- number of segments
        path_infos.up_vector        -- the up-vector, used to build the path
        
        handle                      -- handle of the path from pose_start to pose_end
        handle_name                 -- name of the object in the scene
        
        path_infos.chunk_length     -- length of each chunk
        path_infos.length           -- total length
        
        path_infos.direction        -- unary vector (#=3) direction of the path
        
        path_infos.positions        -- [1:3] starting pose, [#-2:#] destination
        path_infos.orientations     -- [1:3] starting pose, [#-2:#] destination
        
        path_infos.target_reached   -- as the name suggests...
        path_infos.time_prev        -- previous call of sis.getSimulationTime( )
        path_infos.time_step        -- time elapsed between calls of path_move( )
        path_infos.velocity         -- velocity of the point
        path_infos.distance         -- distance between the current point and the destination
        toll                        -- threshold
        
--]]
function path_init( handle_A, pose_target_B, path_obj )
    local path_infos = {}
    -- get another reference if given
    if path_obj ~= nil then
        -- delete the previous path
        sim.removeModel( path_obj.handle )
        path_infos = path_obj 
    end
    
    -- useful for concatenating different poses
    local function concat_array( from, into )
        for i=1,#from,1 do
             table.insert( into, from[i] )
        end
    end
    
    -- get the poses of the objects
    path_infos.pointer = handle_A
    -- path_infos.target  = handle_B
    path_infos.pose_start = sim.getObjectPose( path_infos.pointer, -1 )
    -- path_infos.pose_end   = sim.getObjectPose( path_infos.target, -1 )
    path_infos.pose_end = pose_target_B
    -- serialize before creating the path
    local ctrl_points_serialized = {}
    concat_array( path_infos.pose_start, ctrl_points_serialized )
    concat_array( path_infos.pose_end, ctrl_points_serialized )
    path_infos.pose_serialized = ctrl_points_serialized
    
    -- other infos
    path_infos.chunks    = 5
    path_infos.up_vector = {0, 0, 1}
    
    -- generate the path
    path_infos.handle = sim.createPath(
        ctrl_points_serialized,
        8,        --> show individual path points
        path_infos.chunks,
        1.0,      --> smoothness
        0,        --> orientaton mode (default is 0)
        path_infos.up_vector
        )
    path_infos.handle_name = sim.getObjectName( path_infos.handle )
    
    -- print( path_infos )
    -- sim.pauseSimulation( )
    
    -- length
    _, path_infos.length = sim.getPathLengths( path_infos.pose_serialized, 7 )
    path_infos.chunk_length = path_infos.length / path_infos.chunks
    
    -- direciton of the path (supposed as straight line) as unary vector
    path_infos.direction = {
        (path_infos.pose_end[1] - path_infos.pose_start[1])/path_infos.length,
        (path_infos.pose_end[2] - path_infos.pose_start[2])/path_infos.length,
        (path_infos.pose_end[3] - path_infos.pose_start[3])/path_infos.length,
    }
    
    -- poses
    local pathData = sim.unpackDoubleTable(
        sim.readCustomDataBlock( path_infos.handle,'PATH' )
    )
    local m = Matrix( #pathData//7, 7, pathData )
    path_infos.positions    = m : slice(1,1,m:rows(),3) : data()
    path_infos.orientations = m : slice(1,4,m:rows(),7) : data()
    
    -- other data
    path_infos.target_reached = false
    path_infos.time_prev      = sim.getSimulationTime( )
    path_infos.time_step      = 0
    path_infos.velocity       = 0.1
    path_infos.distance       = 0.0
    path_infos.toll           = 0.01
    
	if path_obj ~= nil then
		path_obj = path_infos
	end 
    return path_infos
end
--

--- ARGUMENTS:
--    path_struct            : the path data structure
--    (optional) vel         : the velocity
--    (optional) time_extern : time is given from outside the function
--  RETURNS true if the target was reached, false otherwise
--[[ EXAMPLES:
	local res = path_move( path_global, 0.1, sim.getSimulationTime( ) )
	local res = path_move( path_global, 0.1 )
	local res = path_move( path_global )
	local res = path_move( path_global, nil, sim.getSimulationTime( ) )
--]]
function path_move( path_struct, vel, time_extern )
    if path_struct.target_reached then
        return true
    else
        if vel ~= nil then
            path_struct.velocity = vel
        end
        
        local time_now = 0
        if time ~= nil then
           time_now = time_extern 
        else
            time_now = sim.getSimulationTime( )
        end
        path_struct.time_step = time_now - path_struct.time_prev
        path_struct.time_prev = time_now
        
        -- compute the distance
        --[[
        local res, ds = sim.checkDistance( path_struct.pointer, path_struct.target )
        if ( res > 0 ) and ( ds[7] < path_struct.toll ) then
            path_struct.target_reached = true
            return true
        end
        --]]
        local ds = distance_between( 
            sim.getObjectPosition( path_struct.pointer, -1 ),
            { path_struct.pose_end[1], path_struct.pose_end[2], path_struct.pose_end[3] }
            )
        if ds <= path_struct.toll then
            path_struct.target_reached = true
            return true
        end
        
        if not path_struct.target_reached then
            -- compute the traveled distance during the step
            path_struct.distance = path_struct.distance + path_struct.velocity * path_struct.time_step
            
            -- interpolate with the path
            local dest_pose = sim.getPathInterpolatedConfig(
                path_struct.pose_serialized,
                sim.getPathLengths( path_struct.pose_serialized, 7 ),
                path_struct.distance,
                nil,
                {0,0,0,2,2,2,2}
            )
            sim.setObjectPose( path_struct.pointer, -1, dest_pose )
        end
        
        return false
    end
end
--




--
--- SHARED INFOS
--

--- Setup the shared informations
function shared_setup( )
    -- structure to read only
    shared_data = {
        active = true,
        busy = false,
        target = {0.0, 0.0, 0.0},
        current_pose = {0.0, 0.0, 0.0},
        threshold = 0.001
    }
    sim.writeCustomDataBlock( self, 
        "OS_crane_driver_shared", sim.packTable( shared_data ) )
    
    -- infos to write only
    active = 0
    sim.writeCustomDataBlock( self, 
        "OS_crane_driver_shared_active", sim.packUInt8Table( { active } ) )
    target_pos = {0.0, 0.0, 0.0}
    sim.writeCustomDataBlock( self,
        "OS_crane_driver_shared_target", sim.packFloatTable( target_pos ) )
    user_threshold = 0.001
    sim.writeCustomDataBlock( self,
        "OS_crane_driver_shared_threshold", sim.packFloatTable( { user_threshold } ) )
end
--

--- Publish the state
function shared_out( )
    -- 'shared_data' is already updated by other parts of the script
    sim.writeCustomDataBlock( self, 
        "OS_crane_driver_shared", sim.packTable( shared_data ) )
end
--

--- Read the objective infos
function shared_in( )
    local buffer = nil
    
    -- 'target_pos'
    buffer = sim.readCustomDataBlock( self, "OS_crane_driver_shared_target" )
    target_pos = sim.unpackFloatTable( buffer ) --> check validity!
    
    -- 'active' flag
    buffer = sim.readCustomDataBlock( self, "OS_crane_driver_shared_active" )
    active = sim.unpackUInt8Table( buffer )[1] --> check validity!
    
    -- 'user_threshold'
    buffer = sim.readCustomDataBlock( self, "OS_crane_driver_shared_threshold" )
    user_threshold = sim.unpackFloatTable( buffer )[1] --> check validity!
    
    -- update shared data
    shared_data.active = ( active > 0 )
    shared_data.target = target_pos
    shared_data.threshold = user_threshold
    
    -- DEBUG 
    -- print( "[shared_in@OS_crane_driver] shared data: " )
    -- print( shared_data )
end
--

--- Clean the 'active' flag
function shared_clear_active_flag( )
    sim.writeCustomDataBlock( self, 
        "OS_crane_driver_shared_active", sim.packUInt8Table( { 0 } ) )
end




--
--- SETUP AND INIT
--

--- Find the elements of the manipulator
function crane_setup( )
    -- handlers
    crane_target = sim.getObjectHandle( "crane_target" )
end
--

--- Setup the state machine
function smach_setup( )
    -- empty state machine
    sm = smach_init( )
    
    -- shared path
    local pack = {
        pointer = crane_target,
        path = nil,
        vel = 0.1
    }
    -- print( pack )
    sm.set_shared( sm, pack )
    
    -- states
    sm.add_state( sm, "idle", state_idle, true  )
    sm.add_state( sm, "move", state_move, false )
end
--

--- Init
function sysCall_init()
    self = sim.getObjectHandle( sim.handle_self )
    
    -- init crane infos
    crane_setup( )
    
    -- state machine
    smach_setup( )
    
    -- set the shared infos
    shared_setup( )
end
--




--
--- ACTUATION
--
function sysCall_actuation()
    -- read the shared vars
    shared_in( )
    
    -- update the state machine
    sm.exec( sm )
    
    -- export the new state
    shared_out( )
end
--