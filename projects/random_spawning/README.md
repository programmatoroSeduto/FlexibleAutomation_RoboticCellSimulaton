# LUA snippets -- random spawning

*see examples* Snippet Spawning.

## Aside -- Random Numbers in LUA

see [this](https://stackoverflow.com/questions/20154991/generating-uniform-random-numbers-in-lua) on StackOverflow.

```lua
-- set seed
math.randomseed( 5 ) -- 5 is random...

-- set time seed
math.randomseed(os.time())

-- get one random int from 'a' to 'b'
local r = math.random( 1, 10 )
```

## Random Selection

See the scene attached. Note that, in order to avoid strange behaviours, the names of the objects to copy end all with a letter, in this case *c*. In this way, CoppeliaSim doesn't recognize the number at the end of the tag as an index, so it doesn't alter it. 

Here is the code:

```lua
function get_object_name( idx )
    return ( "object_to_copy_" .. idx .. "c" )
end

function get_random_idx( )
    return math.random( 1, 3 )
end

-- Spawning method
function spawn_execute( idx )
	local to_copy      = sim.getObjectHandle( get_object_name( idx ) )
    local to_copy_pos  = sim.getObjectPosition( to_copy, -1 )
    
    sim.removeObjectFromSelection( sim.handle_all )
    
    -- (1) select the original copy of the object to spawn
    sim.addObjectToSelection( sim.handle_single, to_copy )
    
    -- (2) move it to the new position
    sim.setObjectPosition( to_copy, -1, spawn_point )
    
    -- (3) copy and paste, rename the copy, adn increment the spawn index
    sim.copyPasteObjects( sim.getObjectSelection( ), 2 )
    local copy = sim.getObjectHandle( get_object_name( idx ) .. 0 )
    sim.setObjectName( copy, "new_copy_" .. spawn_idx )
    spawn_idx = spawn_idx + 1
    
    -- (4) restore the position of the original copy
    sim.setObjectPosition( to_copy, -1, to_copy_pos )
    
    sim.removeObjectFromSelection( sim.handle_all )
end

-- child script with 'spawner'
function sysCall_init()
    -- his should be done into the scene script
    math.randomseed( os.time( ) )
    
    -- setup timer
    delta_time      = 2
    remaining_time  = delta_time
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
        spawn_execute( get_random_idx( ) )
		
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

## Constraint -- don't spawn twice

A straightforward modify: just re-ask the number until it is different from the previos one. 

```lua
-- random index with the constraint
function get_random_idx( min, max )
    local r = math.random( min, max )
    while r == last_spawn do
        r = math.random( min, max )
    end
    last_spawn = r
    
    return r
end

-- child script with 'spawner'
function sysCall_init()
    -- ...
    last_spawn      = -1
end

-- spawning with dynamic step
function sysCall_actuation( )
    if remaining_time <= 0 then
        -- ...
        spawn_execute( get_random_idx( 1, 3 ) )
        
    else
        -- ...
    end
end
```

## Constraint -- spawn maximun twice

This is the idea:

1. generate the number
2. if the number is not equal to the previous one, choose it
3. else, if the number of repetitions is less than the maximum, choose it
4. else, retry

The function for choosing the index with this rule:

```lua
function get_random_idx( min, max, max_consecutive_spawn )
    local r = -1
    local done = false
    
    while not done do
        r = math.random( min, max )
        
        if r == last_spawn then
            if last_spawn_count < max_consecutive_spawn then
                last_spawn_count = last_spawn_count + 1
                done = true
            end
        else
            last_spawn = r
            last_spawn_count = 1
            done = true
        end
    end
    
    return r
end
```

Note that this function let you to decide which is the maximum number of repetitions. 