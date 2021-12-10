# CODING NOTES -- OS_crane_service

> Update these notes!

Handle to the service:

```lua
crane_service = sim.getObjectHandle( "OS_crane_service" )
```

Vars:

- (WRITE ONLY) *OS_crane_service_shared_input* - packTable

the message is rewrittenn with the empy message when the service has read it.  

commands: *slot, pick_ready, pick, place_ready, place, idle* 

```lua
-- empty input
service_empty_input = { cmd="", value=-1 }
-- send the input
local msg = { cmd="cmd", value=value }
sim.writeCustomDataBlock( crane_service, "OS_crane_service_shared_input", sim.packTable( msg ) )
-- if you read this fiels, you'l find the empty message always

-- enable slot check for the pick and place (test only)
sim.writeCustomDataBlock( crane_service, 
	"OS_crane_service_shared_enable_slot_check", "true" ) --> enable
sim.writeCustomDataBlock( crane_service, 
	"OS_crane_service_shared_enable_slot_check", "false" ) --> disable
-- the var is not rewritten	
```

- (READ ONLY) *OS_crane_service_shared_output* - packTable

```lua
-- empty message
service_empty_output = { success=true, busy=false, erro_code=0, err_str="" }
-- read the output with
local msg = sim.unpackTable( sim.readCustomDataBlock( crane_service, "OS_crane_service_shared_output" ) )
```

Inside the code:

```lua
-- other handlers
self -- handle to the service "OS_crane_service"
pos_idle -- array (ordered by slot) of idle positions
pos_place -- array of place points (ordered by slot)

-- task error handling
sm_error_description -- the string description of the error

-- main channels
service_setup( ) -- setup the service infos
service_input -- the last input, "consumed" after task selection IN ANY CASE
service_output -- the last output
service_update_input( ) -- read the input shared var and update service_input
service_update_output( ) -- write the content of service_output to the shared space

-- msg models
service_empty_input = { cmd="", value=-1 }
service_empty_output = { success=true, busy=false, err_code=0, err_str="" }

-- gripper
gripper_handle -- the handle of the gripper
gripper_status - READ ONLY - USE cmd_gripper() INSTEAD! -- (true, false) the status of the gripper
gripper_payload -- if true, the gripper is carrying something
cmd_gripper( flag ) -- enable or disable the gripper
cmd_check_gripper( ) -- check the real status of the gripper

-- crane low level
crane_driver -- the handle of the crane driver
cmd_send_position( pos ) -- start the motion of the gripper towards a given pos {x,y,z}
cmd_get_ee_position( ) -- get the position of the gripper
cmd_check_driver_status( ) -- the driver can be "idle" or "busy" depending on the motion

-- sensors 
sensor_slot_driver -- low leve slot sensor
cmd_check_slot_sensor( ) -- it returns the package containing the state of the slot proximity sensors; used to obtain the pick point

-- task selection and execution
cur_sm -- the running state machine (default: nil)
working_slot -- the slot currently handled
select_cmd( ) -- choose one task (state machine) to execute and return it

-- available tasks 
-- (they return smach, has_init; if has_init, exeute the first state before starting)
sm_pick_ready( ) -- obtain the state machine of the action "pick_ready"
sm_pick( ) -- implementation of the command "pick" as state machine
sm_place_ready( ) -- implementation of the command "place_ready" as state machine
sm_place( ) -- implementation of "place"
sm_idle( ) -- go into rest position
```

commands. In general you cannot change the running task while it is running. You have to wait for the end of the current task. The *cmd* field is interpreted as case-insensitive.

- cmd=**slot** value=number(1,2,3) -- change the working slot. You cannot change it while the system is working 
- cmd=**pick_ready** -- move the gripper over the vendor to pick
- cmd=**pick** -- pick the vendor: move down --> enable the gripper and pick --> move up
- cmd=**place_ready** -- move the gripper CARRYING THE VENDOR over the place point
- cmd=**place** -- place the vendor: move down --> disable the gripper --> delay --> move up
- cmd=**idle** -- move the robot in idle position

The expected sequence each time: (cmd, value)

1. *slot, <your working slot>*
2. *pick_ready, -1*
3. *pick, -1*
4. *place_ready, -1* 
4. *place, -1* 
5. *idle, -1*

(TODO: implement the command "maintenance" -- move the gripper in the maintenance zone)

(TODO: implement the command "break" -- stop the task; the driver is interruptible right now, but not the service)







```lua

```