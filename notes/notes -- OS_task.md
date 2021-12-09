# CODING NOTES -- OS_task

## It should communicate with

drivers:

- OS_slot_sensor

services:

- OS_conveyor_service
- OS_crane_service
- OS_slot_manager

## External libs

- state machine

## Local Infos

- self (always present)
- threshold for slot sensors
- driver handles
- service handles

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
10. go into idle position
11 restart the conveyor of the working slot



## setup

- stop the slot conveyors before starting
- enable the carousel before starting
- the robot is in idle state before starting (go in idle state)

## warnings

- nel caso si comunicasse con un service che fa da intermediario con un driver, potrebbe esserci un frame di ritardo nelle reazioni. Questo non dovrebbe rappresentare un problema ... in ogni caso, stai all'occhio. Diciamo però che se lavorassi "nell'intorno" del punto, allora riuscirei comunque a far funzionare il tutto. 
- 