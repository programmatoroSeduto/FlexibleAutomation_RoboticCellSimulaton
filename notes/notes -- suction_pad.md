# CODING NOTES -- suction pad

## Shared Interface

```lua
-- HANDLER
suction_pad = sim.getObjectHandle( "suctionPad" )

-- (WRITE ONLY) no codification
-- disable the suction pad or place an object
sim.writeCustomDataBlock( suction_pad, "suction_pad_enabled", "false" )
-- enable the suction pad
sim.writeCustomDataBlock( suction_pad, "suction_pad_payload", "true" )

-- (READ ONLY) no codification
-- check if the suction pad is carrying something
local status = sim.readCustomDataBlock( suction_pad, "suction_pad_payload" )
-- it can be "true", "false" (string)
```