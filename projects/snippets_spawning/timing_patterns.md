# LUA snippets -- Timing Patterns for non-threaded scripts in LUA

## Tools of the trade

Timing:

- [Get simulation time step](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simGetSimulationTimeStep.htm)
- [get simulation time](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simGetSimulationTime.htm)

## Timer Pattern -- Fixed step

```lua
-- child script with 'spawner'
function sysCall_init()
    -- setup timer
    remaining_time  = 0   -- remanining time to the next spawn
    delta_time      = 2   -- one spawn every 2 seconds
    
    -- get the simulation step, which is constant during the simulation
    simulation_step = sim.getSimulationTimeStep( )
end

-- spawning with fixed step
function sysCall_actuation( )
    if remaining_time <= 0 then
        -- spawning
        print( "Spawning!" )
		
		-- then reset the timer
        remaining_time = delta_time
        
    else
        -- keep going
        remaining_time = remaining_time - simulation_step
        print( "Keep going..." )
        
    end
end
```

## Timer Pattern -- Dynamic Step

```lua
-- child script with 'spawner'
function sysCall_init()
    -- setup timer
    remaining_time  = 0   -- remanining time to the next spawn
    delta_time      = 2   -- one spawn every 2 seconds
    prev_time       = sim.getSimulationTime( )
end

-- spawning with dynamic step
function sysCall_actuation( )
    if remaining_time <= 0 then
        -- spawning
        print( "Spawning!" )
		
		-- then reset the timer
        remaining_time = delta_time
        
    else
        -- compute the step
        local simulation_step = sim.getSimulationTime( ) - prev_time
        remaining_time = remaining_time - simulation_step
        prev_time =sim.getSimulationTime( )
        
        -- keep going
        print( "Keep going..." )
        
    end
end
```

## Check-and-run pattern

Another feasible strategy is to gather all the timing functionalities in a single function. Here is a variation of the dynamic timer pattern:

```lua
-- update the timer and check 
-- it return TRUE if it's time for the event, FALSE otherwise
function check_time( )
    -- check if timing is enabled
    if prev_time == nil then
        -- setup timer
        delta_time      = 2
        remaining_time  = delta_time
        prev_time       = sim.getSimulationTime( )
    end
    
    -- update timer
    local simulation_step = sim.getSimulationTime( ) - prev_time
    remaining_time = remaining_time - simulation_step
    prev_time =sim.getSimulationTime( )
    
    -- check time
    if remaining_time <= 0 then
        remaining_time = delta_time
        return true
    else
        return false
    end
end
```

The advantage of this approach is to enclose the time management in only one function, improving the semantic of the code. Another pros lies in the fact that now, in the spawning algorithm, the actuation function has only one instruction:

```lua
-- spawning with dynamic step
function sysCall_actuation( )
    if check_time( ) then
        spawn_execute( )
    end
end
```

## Clock Pattern

The strategy: instead of decreasing a "timer" variable, we have now a variable which is increased at every frame. 

```lua
-- clock pattern + check and run
function check_time( )
    local clock_now = sim.getSimulationTime( )
    
    -- check if timing is enabled
    if time_setup == nil then
        -- setup clock
        delta_time = 2
        clock_next = clock_now + delta_time
        
        time_setup = true
    end
    
    -- check time
    if clock_now >= clock_next then
        clock_next = sim.getSimulationTime( ) + delta_time
        return true
    else
        return false
    end
end
```

This approach could have a cons to take into account: in some cases, *overflow* could happen. Except for this, the approach is lighter than the timer pattern in terms of computation: in fact the update step disappears here, the function just does setup and checking. 