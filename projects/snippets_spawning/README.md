# LUA snippets -- Spawning

## Tools of the trade

Handlers and object names:

- [get object handle](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simGetObjectHandle.htm)
- [set object name](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simSetObjectName.htm)

Copy and paste function:

- [copy and paste](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simCopyPasteObjects.htm)

Functions for dealing with position and pose:

- [set object pose](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simSetObjectPose.htm)
- [get object pose](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simGetObjectPose.htm)
- [set object position](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simSetObjectPosition.htm)
- [get object position](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simGetObjectPosition.htm)

Selecting objects:

- [removeObjectFromSelection](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simRemoveObjectFromSelection.htm)
- [getObjectSelection](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simGetObjectSelection.htm)
- [addObjectToSelection](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simAddObjectToSelection.htm)

Timing:

- [Get simulation time step](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simGetSimulationTimeStep.htm)
- [get simulation time](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simGetSimulationTime.htm)

## First version -- just for understanding

first version: *object_to_copy* is a simple cube, the object we want t copy; *spawner* the point where to spawn the copy.

```lua
-- init function of the child script 'spawner'
function sysCall_init()
    -- sim.removeObjectFromSelection( sim.handle_all )
    to_copy = sim.getObjectHandle( "object_to_copy" )
    spawn_dummy = sim.getObjectHandle( sim.handle_self )
    spawn_point = sim.getObjectPosition( spawn_dummy, -1 )
    print( "spawn point: " ); print( spawn_point )
    
    sim.removeObjectFromSelection( sim.handle_all )
    sim.addObjectToSelection( sim.handle_single, to_copy )
    sim.copyPasteObjects( sim.getObjectSelection( ), 2 )
    sim.setObjectPosition( to_copy, -1, spawn_point )
    
    copy2 = sim.getObjectHandle( "object_to_copy0" )
    sim.setObjectName( copy2, "copy" )
end
```

**result**: the original cube *object_to_copy* is moved in the spawning position. The copy now is placed at the previous position of the original, and its name is changed by script from *object_to_copy0* (adding a zero after the name of the original one) to *copy*. 

Not exactly the result we'd desire, but it is something to start from. 

## Second version -- the correct behaviour

Let's rearrange the algorithm:

1. select the original copy of the object to spawn
2. move it to the new position
3. copy and paste, rename the copy
4. restore the position of the original copy

The structure of the project is the same: *object_to_copy* the simple object to copy; *spawner* the dummy where to place the object. 

```lua
-- init function inside the child script 'spawner'
function sysCall_init()
	-- (0) infos
    local to_copy      = sim.getObjectHandle( "object_to_copy" )
    local spawn_dummy  = sim.getObjectHandle( "spawner" )
    local to_copy_pos  = sim.getObjectPosition( to_copy, -1 )
    local spawn_point  = sim.getObjectPosition( spawn_dummy, -1 )
    
    sim.removeObjectFromSelection( sim.handle_all )
    
    -- (1) select the original copy of the object to spawn
    sim.addObjectToSelection( sim.handle_single, to_copy )
    
    -- (2) move it to the new position
    sim.setObjectPosition( to_copy, -1, spawn_point )
    
    -- (3) copy and paste, rename the copy
    sim.copyPasteObjects( sim.getObjectSelection( ), 2 )
    local copy = sim.getObjectHandle( "object_to_copy" .. 0 )
    sim.setObjectName( copy, "new_copy" )
    
    -- (4) restore the position of the original copy
    sim.setObjectPosition( to_copy, -1, to_copy_pos )
    
    sim.removeObjectFromSelection( sim.handle_all )
end
```

**result**: the copy, with tag *new_copy*, is located at the position of the *spawner* dummy, and the original object stays in the same position. The expected behaviour. 

**Note well**: the copy and paste here doesn't copy the entire model, but only one element. See the options of copy and paste for more details. 

## Third version -- timed spawning

This is a timed version for the spawning (see the attached document about *timing*). It uses the dynamic timer pattern. A counter of the spawned objects is incremented at each new object spawned; each copy has tag `"new_copy_" .. spawn_idx`.

```lua
-- Spawning method
function spawn_execute( )
    local to_copy      = sim.getObjectHandle( "object_to_copy" )
    local to_copy_pos  = sim.getObjectPosition( to_copy, -1 )
    
    sim.removeObjectFromSelection( sim.handle_all )
    
    -- (1) select the original copy of the object to spawn
    sim.addObjectToSelection( sim.handle_single, to_copy )
    
    -- (2) move it to the new position
    sim.setObjectPosition( to_copy, -1, spawn_point )
    
    -- (3) copy and paste, rename the copy, adn increment the spawn index
    sim.copyPasteObjects( sim.getObjectSelection( ), 2 )
    local copy = sim.getObjectHandle( "object_to_copy" .. 0 )
    sim.setObjectName( copy, "new_copy_" .. spawn_idx )
    spawn_idx = spawn_idx + 1
    
    -- (4) restore the position of the original copy
    sim.setObjectPosition( to_copy, -1, to_copy_pos )
    
    sim.removeObjectFromSelection( sim.handle_all )
end

-- child script with 'spawner'
function sysCall_init()
    -- setup timer
    remaining_time  = 0   -- remanining time to the next spawn
    delta_time      = 2   -- one spawn every 2 seconds
    prev_time       = sim.getSimulationTime( )
    
    -- setup spawning
    spawn_dummy     = sim.getObjectHandle( "spawner" )
    spawn_point     = sim.getObjectPosition( spawn_dummy, -1 )
    spawn_idx       = 0
end

-- spawning with dynamic step
function sysCall_actuation( )
    if remaining_time <= 0 then
        -- spawning
        spawn_execute( )
		
		-- then reset the timer
        remaining_time = delta_time
        
    else
        -- keep going
        local simulation_step = sim.getSimulationTime( ) - prev_time
        remaining_time = remaining_time - simulation_step
        prev_time =sim.getSimulationTime( )
        
    end
end
```

See the example attached here. 

**Note well**: the position of the spawner is extracten only one time at the init phase. If the spawn dumm would move, the object to copy keeps falling at the same initial position each time a new object is spawned. 