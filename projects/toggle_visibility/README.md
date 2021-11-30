# LUA snippets -- Shapes Visibility

## Tools of the trade

Forum Links:

- [API function to change object visibility](https://forum.coppeliarobotics.com/viewtopic.php?t=4105)

Parameters and constraints:

- [sim.setObjectInt32Parameter](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simSetObjectInt32Parameter.htm)
- VERY IMPORTANT: [Object Parameters IDs](https://www.coppeliarobotics.com/helpFiles/en/objectParameterIDs.htm)
- [sim.setObjectSpecialProperty](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simSetObjectSpecialProperty.htm)
- [Scene object special properties](https://www.coppeliarobotics.com/helpFiles/en/apiConstants.htm#sceneObjectSpecialProperties)

## A simple example

Let's consider a single cuboid, with a chld script attached to. The coboid toggles its visibility every 2 seconds. 

```lua
function toggle_visiblity( )
    if visible == nil then
        visible = true
    end
    
    if visible then
        -- toggle invisible
        -- print( "Invisible!" )
        visible = false
        sim.setObjectInt32Param( this_handle, 10, 0 )
    else
        -- toggle visible
        -- print( "Visible!" )
        visible = true
        sim.setObjectInt32Param( this_handle, 10, 1 )
    end
end

function sysCall_init()
    this_handle = sim.getObjectHandle( sim.handle_self )
    sim.setObjectInt32Param( this_handle, 10, 1 )
    
    -- timer
    delta_time      = 1
    remaining_time  = delta_time
    
    -- get the simulation step, which is constant during the simulation
    simulation_step = sim.getSimulationTimeStep( )
end

function sysCall_actuation()
    if remaining_time <= 0 then
		toggle_visiblity( )
        remaining_time = delta_time
        
    else
        -- keep going
        remaining_time = remaining_time - simulation_step
        
    end
end

function sysCall_cleanup( )
    sim.setObjectInt32Param( this_handle, 10, 1 )
end

```
