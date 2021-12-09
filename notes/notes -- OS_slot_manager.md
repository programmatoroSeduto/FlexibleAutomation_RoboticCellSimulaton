# CODING NOTES -- OS_slot_manager

## Some things to take into account

**Suggestion sending**. The suggestion should be picked immediately, because the module publishes a new suggestion depending on the situation *at the current frame*, so the suggestion can change quickly. 

**reliability**. Sometime the sensor doesn't work well, which is a realistic situation: in the real environment, sensors are not perfect, and the color detection could be not reliable sometimes. The suggestion is published only if the module *is sure to have a coherent situation*. 

## Shared Interface

```
-- HANDLER
slot_manager = sim.getObjectHandle( "OS_slot_manager" )

-- DATA STRUCTURE : suggestion
msg = {
	slot= , --> the suggested slot
	pick_point_handle= --> the pick point of the object (deprecated)
}
-- empty message : (-1, -1)

-- (READ ONLY)
-- read the next suggestion
data = sim.unpackTable(sim.readCustomDataBlock( slot_manager, "OS_slot_manager_shared" ) )
```