# Trajectories

## Links

About paths: 

- the list of all the functions for [Paths (regular API)](https://www.coppeliarobotics.com/helpFiles/en/apiFunctions.htm#paths)
- [sim.createPath](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simCreatePath.htm)
(https://www.coppeliarobotics.com/helpFiles/en/apiConstants.htm#customDrawingObjects)
- [sim.getPathInterpolatedConfig](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simGetPathInterpolatedConfig.htm)
- [sim.getPathLengths](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simGetPathLengths.htm)

About line and drawing in general:

- [sim.addDrawingObject](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simAddDrawingObject.htm); see also the types of drawings [here]
- [sim.addDrawingObjectItem](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simAddDrawingObjectItem.htm)

Concerning tables:

- [sim.UnpackDoubleTable](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simUnpackDoubleTable.htm)
- More infos about [packing/unpacking methods](https://www.coppeliarobotics.com/helpFiles/en/apiFunctions.htm#packing)
- [sim.readCustomDataBlock](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simReadCustomDataBlock.htm); see also [https://www.coppeliarobotics.com/helpFiles/en/apiFunctions.htm#packing](https://www.coppeliarobotics.com/helpFiles/en/apiFunctions.htm#packing)

Other useful methods:

- [sim.checkDistance](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simCheckDistance.htm)

## Straight-line path

Let's try somethins very simple. There's a dummy to move along a path (this is the most common usage of paths/trajectories). Here are the logic steps:

1. get the points to link (A: the actual pose, B:the final pose)
2. create the trajectory between the points
3. move the dummy along the trajectory
4. delete the path (and clean the scene)

Here is the entire code to build the path between two points:

```lua
-- cat two arrays
--    (LUA passes the tables by reference)
function concat_array( from, into )
    for i=1,#from,1 do
         table.insert( into, from[i] )
    end
end

-- create the path from A to B
--[[
    OBJECT path (no other infos):
        success         -- if the strcture is valid (=true) or not (=nil)
        pose_start      -- the starting pose (#=7)
        pose_end        -- the objective pose (#=7)
        pose_serialized -- the serialization of the poses (#=14)
        
        path_infos.chunks
        path_infos.up_vector
        
        handle          -- handle of the path from pose_start to pose_end
--]]
function path_create_between( handle_A, handle_B )
    local path_infos = {}
    
    -- get the poses of the objects
    path_infos.pose_start = sim.getObjectPose( handle_A, -1 )
    path_infos.pose_end   = sim.getObjectPose( handle_B, -1 )
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
    
    return path_infos
end


-- Obtain infos about the path
--    add them to the path data structure
--[[
    OBJECT path (other infos):
        path_infos.chunk_length     -- length of each chunk
        path_infos.length           -- total length
        path_infos.direction        -- unary vector (#=3) direction of the path
        path_infos.positions        -- [1:3] starting pose, [#-2:#] destination
        path_infos.orientations     -- [1:3] starting pose, [#-2:#] destination
--]]
function path_add_infos( path_infos )
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
end


-- child script of 'movement_along_path'
function sysCall_init( )
    point_to_move  = sim.getObjectHandle( "point_to_move" )
    point_end_path = sim.getObjectHandle( "final_dest" )
    
    -- build the path between A and B
    path = path_create_between( point_to_move, point_end_path )
    -- ...with auxiliary infos
    path_add_infos( path )
    print( path )
    
    -- others
    target_reached = false
    time_prev      = sim.getSimulationTime( )
    time_step      = 0.0  -- s
    mod_velocity   = 0.1 -- m/s
    distance       = 0.0  -- m
    path_removed   = false
end
```

To move the point along the path, here is one possibility. The path is removed when the point has reached the destination, using `sim.removeModel( )`. 

```lua
-- move the point towards the target
function sysCall_actuation( )
    if not target_reached then
        -- compute the traveled distance during the step
        distance = distance + mod_velocity * time_step
        
        -- interpolate with the path
        local dest_pose = sim.getPathInterpolatedConfig(
            path.pose_serialized,
            sim.getPathLengths( path.pose_serialized, 7 ),
            distance,
            nil,
            {0,0,0,2,2,2,2}
        )
        sim.setObjectPose( point_to_move, -1, dest_pose )
    elseif not path_removed then
        sim.removeModel( path.handle )
        path_removed = true
    end
end


-- check how far is the point from the target and compute the time step
function sysCall_sensing( )
    local time_now = sim.getSimulationTime( )
    time_step = time_now - time_prev
    time_prev = time_now
    
    -- compute the distance
    local res, ds, _ = sim.checkDistance( point_to_move, point_end_path )
    if ( res > 0 ) and ( ds[7] < 0.001 ) then
        target_reached = true
    end
end
```

### A refined version of the script -- Static Path Creation

*See the example* trajectory_example. Notice that here the objet path is enclosed in only one function, and the actuation is reduced to only one function. Sensing part is no longer needed. 

```lua
-- create the path from A to B
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
function path_init( handle_A, handle_B, path_obj )
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
    path_infos.target  = handle_B
    path_infos.pose_start = sim.getObjectPose( path_infos.pointer, -1 )
    path_infos.pose_end   = sim.getObjectPose( path_infos.target, -1 )
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
```

### A refined version of the script -- step along the path

```lua
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
        local res, ds = sim.checkDistance( path_struct.pointer, path_struct.target )
        if ( res > 0 ) and ( ds[7] < path_struct.toll ) then
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

```

## Path Switching

See the example *trajectory_points_sequence.ttt*. What about changing path during the simulation? Here is a script which allows to recompute the path using the script I wrote before:

```lua
-- switch from one path to another
--[[ EXAMPLES
    -- create from sscratch
    local path = path_switch( new_handle_dest, nil, from_pointer )
    
    -- create updating an existing structure
    local path = path_switch( new_handle_dest, path_struct )
    -- if the pointer changes:
    local path = path_switch( new_handle_dest, path_struct, from_pointer )
--]]
function path_switch( new_handle_dest, path_struct, from_pointer )
    if path_struct == nil then
        if from_pointer == nil then
            -- cannot create the struct!
            return nil
        end
        -- create crom scratch
        return path_init( from_pointer, new_handle_dest )
        
    else
        if from_pointer == nil then
            return path_init( path_struct.pointer, new_handle_dest )
        else
            return path_init( from_pointer, new_handle_dest, path_struct )
        end
        
    end
end
```