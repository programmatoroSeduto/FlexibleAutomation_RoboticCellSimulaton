# LUA snippets -- Timing Patterns for non-threaded scripts in LUA

## Tools of the trade

Timing:

- [Get simulation time step](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simGetSimulationTimeStep.htm)
- [get simulation time](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simGetSimulationTime.htm)

## Fixed step

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

## Dynamic Step

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