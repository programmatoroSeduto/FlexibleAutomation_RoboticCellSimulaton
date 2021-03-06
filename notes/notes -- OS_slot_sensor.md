# CODING NOTES -- OS_slot_sensor

## Shared Interface

**INPUT**. It has not a input. 

**OUTPUT**. See the structure here: The structure is updates every time the `sysCall_sensing()` is called. The sensor simply outputs the actua state of each slot. 

```lua
-- HANDLER
slot_sensor = sim.getObjectHandle( "OS_slot_sensors" )

-- DATA STRUCTURE : READ-ONLY DATA
-- structure of the shared output message
-- free : if the sensor area is free or not
-- dist : the planar distance between center and pick point
-- vdist: the planar distance vector wrt the world frame
--    'y' (no.2) lies on the direction of the carousel
-- handle : handle of the pick point
-- from_handle : the handle of the center of the sensor
shared_data = {
	{ free=true, dist=-1, vdist={}, handle=nil, from_handle=slot_sensor[1].handle }, -- slot 1
	{ free=true, dist=-1, vdist={}, handle=nil, from_handle=slot_sensor[2].handle }, -- slot 2
	{ free=true, dist=-1, vdist={}, handle=nil, from_handle=slot_sensor[3].handle }  -- slot 3
}
-- dist : -1 if the sensor is free; distance between the pick point and the center of the sensor
-- handle : coppeliasim handle of the pick point

-- (READ ONLY)
-- read the data from the sensor
sensor_data = sim.unpackTable( sim.readCustomDataBlock( slot_sensor, "OS_slot_sensor_shared" ) )
```

## Inside the code

```lua
-- shared interface
shared_data -- the global message
shared_setup( ) -- see inti function
update_shared_data( ) -- read the state from global shared_data

-- sensors and slots
slot_sensor = {{handle, center}, ...#3} -- handlers of the slot proximity sensors and centers (ordered)
sensor_setup( slot_names ) -- build the structure slot_sensor

-- others
look_for_pick_point_of( handle ) -- look for the pick point of a vendor, whatever it is
distance_between( handleA, handleB ) -- planar distacce (only {x,y}) between two handlers
```




















```lua

```