# Example -- Sensors and Spawning

## Tools of the trade

... 

## Basic usage

Check this before:

- the object you want to spawn *must be detectable*: a common error is to don't set the model detectable

Here is the code, except for the spawning part (see *sensors_and_spawning_basic.ttt*):

```lua
-- child script with 'spawner'
function sysCall_init()
    -- ...
    
    -- setup sensor
    sensor_handle = sim.getObjectChild( sim.getObjectHandle( sim.handle_self ), 0 )
    
    -- ...
end

function sysCall_sensing( )
    state = sim.readProximitySensor( sensor_handle )
    if state > 0 then
        print( "Detected an object inside the space!" )
    else
        print( "No objects inside..." )
    end
end
```

## Lock the spawner

The strategy:

- the sensor updates a boolean which indicates when at least one object is inside the space of the proximity sensor
- when an object is detected, the spawner "looses its turn"

Here is the code:

```lua
-- child script with 'spawner'
function sysCall_init()
    -- his should be done into the scene script
    math.randomseed( os.time( ) )
    
    -- setup timer
    delta_time      = 1
    remaining_time  = delta_time
    prev_time       = sim.getSimulationTime( )
    
    -- setup sensor
    sensor_handle = sim.getObjectChild( sim.getObjectHandle( sim.handle_self ), 0 )
    sensor_signal = false
    
    -- setup spawning
    spawn_dummy      = sim.getObjectHandle( "spawner" )
    spawn_point      = sim.getObjectPosition( spawn_dummy, -1 )
    spawn_idx        = 0
    last_spawn       = -1
    last_spawn_count = 0
end

-- spawning with dynamic step
function sysCall_actuation( )
    if remaining_time <= 0 then
        -- spawning
        if not sensor_signal then
            spawn_execute( get_random_idx( 1, 3, 3 ) )
        end
		
		-- then reset the timer
        remaining_time = delta_time
        
    else
        -- keep going
        local simulation_step = sim.getSimulationTime( ) - prev_time
        remaining_time = remaining_time - simulation_step
        prev_time =sim.getSimulationTime( )
        
    end
end

function sysCall_sensing( )
    state = sim.readProximitySensor( sensor_handle )
    sensor_signal = ( state > 0 )
end
```

## Lock instead of loosing the turn

A little improvement of the previous strategy:

- the sensor updates a boolean which indicates when at least one object is inside the space of the proximity sensor
- when an object is detected, the spawner is locked
- at the first time the space is free, the spawner is unlocked and the object is spawned

Here is the code; sensing and spawning are the same. 

```lua
function sysCall_actuation( )
    if spawn_lock then
        if not sensor_signal then
            -- the space is free and the spawner is locked
            spawn_execute( get_random_idx( 1, 3, 3 ) )
            spawn_lock = false
            print( "Spawner UNLOCKED" )
        end
    else
        if remaining_time <= 0 then
            -- spawning
            if not sensor_signal then
                spawn_execute( get_random_idx( 1, 3, 3 ) )
            else
                spawn_lock = true
                print( "Spawner LOCKED" )
            end
            
            -- then reset the timer
            remaining_time = delta_time
            
        else
            -- keep going
            local simulation_step = sim.getSimulationTime( ) - prev_time
            remaining_time = remaining_time - simulation_step
            prev_time =sim.getSimulationTime( )
            
        end
    end
end
```