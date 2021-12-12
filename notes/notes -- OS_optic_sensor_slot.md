# CODING NOTES -- OS_optic_sensor_slot

## Shared Interface

Output only. 

```lua
-- HANDLER
optic_sensor = sim.getObjectHandle( "OS_optic_sensor_slot" )

-- DATA FROM THE SENSOR
{
	{ state = triggered[1], last_detection = detected[1] },
	{ state = triggered[2], last_detection = detected[2] },
	{ state = triggered[3], last_detection = detected[3] }
}

-- retrieve the data from the sensor
data = sim.unpackTable( sim.readCustomDataBlock( optic_sensor, "OS_optic_sensor_slot_shared" ) )
```