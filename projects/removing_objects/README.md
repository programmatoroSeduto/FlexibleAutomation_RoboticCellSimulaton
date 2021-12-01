# Removing Objects

## tools of the trade

Removing objects:

- [remove object](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simRemoveObject.htm)
- [remove model](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simRemoveModel.htm)

Proximity sensors:

- The most important is [sim.readProximitySensor](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simReadProximitySensor.htm). I attach also the other methods just for knowledge. 
- [sim.handleProximitySensor](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simHandleProximitySensor.htm)
- [sim.checkProximitySensor](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simCheckProximitySensor.htm)
- [sim.resetProximitySensor](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simResetProximitySensor.htm)
- [sim.checkProximitySensorEx](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simCheckProximitySensorEx.htm)
- More advanced: [sim.checkProximitySensorEx2](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simCheckProximitySensorEx2.htm)

Similar methods exist even for *vision sensors*. See the page [regular API - Vision Sensors] (https://www.coppeliarobotics.com/helpFiles/en/apiFunctions.htm#visionSensor)

## Simple cancellation

See the example *remove_single.ttt*: here it is shown how to remove a spawned object using a simple proximity sensor. 

```lua
function sysCall_init()
    -- setup of the sensor
    sensor_handle = sim.getObjectHandle( "trash_sensor" )
    sensor_detected_obj_handle = nil
    sensor_signal = false
end

-- simple cancellation
function sysCall_actuation()
    if sensor_signal then
        sim.removeObject( sensor_detected_obj_handle )
    end
end

-- localization of the object to remove
function sysCall_sensing()
    -- read the data from the sensor
    state, dist, point, obj_h, surf = sim.readProximitySensor( sensor_handle )
    
    -- store the state of the sensor
    if state > 0 then
        -- detected an object!
        sensor_signal = true
        sensor_detected_obj_handle = obj_h
        
    else
        -- nothing in the sensor area
        sensor_signal = false
        sensor_detected_obj_handle = nil
        
    end
end

function sysCall_cleanup()
    -- empty
end
```

## Remove model

See example *remove_model.ttt*: now the object `object_to_copy_2c` has also a subtree, so it 
became a *mode* and not a single object. The code before *removes only the main object*, leaving the dummy into the scene. Since we want to delete *the entire object*, subtree included, we should use the function `sim.removeModel( )` instead of the simple `sim.removeObject( )`; except for this little update, the code is the same. 

```lua
-- child script of object "trash"
function sysCall_init()
    -- setup of the sensor
    sensor_handle = sim.getObjectHandle( "trash_sensor" )
    sensor_detected_obj_handle = nil
    sensor_signal = false
end

-- simple cancellation
function sysCall_actuation()
    if sensor_signal then
		--> UPDATE HERE
        sim.removeModel( sensor_detected_obj_handle )
    end
end

-- localization of the object to remove
function sysCall_sensing()
    -- read the data from the sensor
    state, dist, point, obj_h, surf = sim.readProximitySensor( sensor_handle )
    
    -- store the state of the sensor
    if state > 0 then
        -- detected an object!
        sensor_signal = true
        sensor_detected_obj_handle = obj_h
        
    else
        -- nothing in the sensor area
        sensor_signal = false
        sensor_detected_obj_handle = nil
        
    end
end

function sysCall_cleanup()
    -- empty
end
```

**just a hint**: remember to set the *main object* to delete as *model base*, otherwise CoppeliaSim will issue an error like the following.

> \[trash@childScript:error] 12: Object is not tagged as model base. (in function 'sim.removeModel')

Each element you want to remove with `sim.removeModel()` has to be marked as model base, although it has no objects under in the hierarchy. 