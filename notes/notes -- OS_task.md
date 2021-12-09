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

- self (always present)
- threshold for slot sensors
- service handles
- driver handles

## The main idea (before developing the code)

1. wait for a suggestion from the module OS_slot_manager
2. as soon as a suggestion (the slot to check) is provided, store the suggestion and 
3. select the working slot, and wait until the distance between center and the pick point is less than a certain threshold (use sensors)
4. stop the carousel
5. prepare to pick
6. pick the object
7. restart the carousel and stop the working conveyor
8. prepare to place
9. place the object
10. go into idle position ONLY IF there's no other suggetions, otherwise go to state 3 after stored the suggestion
11 restart the conveyor of the working slot



## setup

- stop the slot conveyors before starting
- enable the carousel before starting
- the robot is in idle state before starting (go in idle state)

## warnings

- nel caso si comunicasse con un service che fa da intermediario con un driver, potrebbe esserci un frame di ritardo nelle reazioni. Questo non dovrebbe rappresentare un problema ... in ogni caso, stai all'occhio. Diciamo però che se lavorassi "nell'intorno" del punto, allora riuscirei comunque a far funzionare il tutto. 
- 














```lua

```