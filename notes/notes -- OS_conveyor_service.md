# CODING NOTES -- OS_conveyor_service

## Things to remember

**Frame Management**. For a module at level zero, every command given to the conveyor through this interface is effective *at the next frame* due to the hierarchical implementation of the module system. 
In particular, remember to check the `.success` flag *at the frame after* the command is sent. 

## Shared Interface

```lua
-- HANDLE
conveyor_service = sim.getObjectHandle( "OS_conveyor_service" )

-- DATA STRUCTURES : input
conveyor_empty_input_msg = { cmd="", value=-1 } -- the empty input
conveyor_empty_output_msg = { success=true } -- the output, referred to the last given command
-- COMMANDS:
--    "conveyor_1, <0, 1>" : activate/deactivate the conveyor in slot 1
--    "conveyor_2, <0, 1>" : ... in slot 2
--    "conveyor_3, <0, 1>" : ... in slot 3
--    "carousel, <0, 1>" : activate/deactivate the slot carousel
-- commands indexes are ordered by slot from right to left. 

-- (WRITE ONLY)
-- send a command to the conveyor manager
local command = "your_cmd"
local val = your_value
sim.writeCustomDataBlock( conveyor_service,
	"OS_conveyor_service_shared_input", 
	sim.packTable( { cmd=command, value=val } )
	)
-- after the message is received, the input is cleaned.

-- (READ ONLY) 
-- success flag referred to the previous command
data = sim.unpackTable( sim.readCustomDataBlock( conveyor_service, "OS_conveyor_service_shared_input" ) )
```