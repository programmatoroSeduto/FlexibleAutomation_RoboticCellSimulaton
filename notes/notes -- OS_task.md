# CODING NOTES -- OS_task

## It should communicate with

drivers:

- OS_slot_sensor (OK see notes)

services:

- OS_conveyor_service (OK see notes)
- OS_crane_service (OK see notes)
- OS_slot_manager (OK see notes)

## External libs

- state machine

## Local Infos

from `sh_setup()`:

- self (always present)
- driver handles
- service handles

data inside the machine: 

- the last suggestion (default: -1)
- threshold for slot sensors (default: 0.05)
- working slot (default or empty: -1; recomputed each time there's a new suggestion)


## The main idea (before developing the code)

1. wait for a suggestion from the module OS_slot_manager
2. as soon as a suggestion (the slot to check) is provided, store the suggestion  (last_suggestion) and 
3. select the working slot, and wait until the distance between center and the pick point is less than a certain threshold (use sensors)
4. stop the carousel
5. prepare to pick
6. pick the object
7. restart the carousel and stop the working conveyor
8. prepare to place
9. place the object
10. go into idle position ONLY IF there's no other suggetions, otherwise go to state 3. after stored the suggestion
11 restart the conveyor of the working slot, and return in state 1. 

## setup

- stop the slot conveyors before starting
- enable the carousel before starting
- the robot is in idle state before starting (go in idle state)

## warnings

- nel caso si comunicasse con un service che fa da intermediario con un driver, potrebbe esserci un frame di ritardo nelle reazioni. Questo non dovrebbe rappresentare un problema ... in ogni caso, stai all'occhio. Diciamo però che se lavorassi "nell'intorno" del punto, allora riuscirei comunque a far funzionare il tutto. 
- c'è un possibile bug nell'implementazione dello slot sensor: il sensore attualmente non riesce a distinguere tra gli oggetti il cui pick point è al di fuori del proximity sensor da quelli che effettivamente si possono prendere. E' un errore che va corretto nell'implementazione dello slot_manager. Questo non manda in crash l'intero sistema, ma potrebbe portare a rifiutare più oggetti del dovuto. In casi semplici o in condizioni di bassa frequenza di spawning, non dovrebbe esserci problema. Per risolvere il problema basta calcolare il distance vector e studiarne le coordinate projected wrt il frame word. 
- e se succedesse qualcosa mentre il robot ha il pezzo nel gripper? Come si risolve l'errore quando il robot ha il pezzo in mano? Una buona strategia?


## Inside the code

```lua
--- communication with other modules
sh_setup( ) -- get the handles
sh_get_suggestion( ) --> suggestion?, suggested_slot
sh_check_distance( working_slot, threshold ) --> bool
sh_toggle_carousel( flag ) -- turn on/off the carousel
sh_toggle_conveyor( working_slot, flag ) -- torn on/off the working conveyor
sh_check_robot( ) --> busy, success
sh_pick( flag ) --> false:"pick_ready", true:"pick"
sh_place( flag ) --> false"place_ready", true:"place"
sh_set_working_slot( slot ) -- command "slot"
sh_command_idle( ) -- command "idle"

-- frame management system
smach_set_wait_frames( pack, n_frames ) -- set how many frames to wait
smach_wait_frame( pack ) -- decrement the timer at each call and check it (true:frame count expired)

-- state machine
task_setup( )
smach_set_wait_frames( pack, n_frames )
smach_wait_frame( pack )
smach_reset_pack( pack )
state_wait_suggestion( sm, pack ) --> "wait_suggestion"
state_wait_dist( sm, pack ) --> "wait_dist"
state_pick_ready( sm, pack ) --> "pick_ready"
state_pick( sm, pack ) --> "pick"
state_place_ready( sm, pack ) --> "place_ready"
state_place( sm, pack ) --> "place"
```



print( "[state_wait_suggestion@OS_task] " )










```lua

```