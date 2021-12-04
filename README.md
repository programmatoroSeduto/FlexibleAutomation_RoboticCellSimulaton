# Robotic Cell Simulation -- Tests

The list of all the example in this repository, *ordered*. 

## CAD examples

- [Example_manipulator](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/tree/test/projects/example_manipulator) : a simple PRR lnkage modeled using only the basic shapes in CoppeliaSim. See the [documentation](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/blob/test/projects/example_manipulator/CoppeliaSim__Es1_completo.pdf) about the example (in italian right now).
- [Example_simple_revolute_joint](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/tree/test/projects/example_simple_revolute_joint) : a simple assembly with one revolute jont. See the [documentation (ITA)](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/blob/test/projects/example_simple_revolute_joint/CoppeliaSim__riguardo_lesercizio_1__revolute_joints.pdf). The scene *revolute_v1_assembly.ttt* contains the simple structure made up by non-grouped basic shapes. The final result is in the scene file *revolute_v1_complete.ttt*.
- [example_simple_prismatic_joint](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/tree/test/projects/examples_simple_prismatic_joint) : a simple piston with one revolute joint. See the [description (ITA)](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/blob/test/projects/examples_simple_prismatic_joint/CoppeliaSim__riguardo_lesercizio_1__prismatic_joints.pdf). This folder contains three files: *prismatic_v1.ttt* is a simple piston without meshes; *prismatic_v2_assembly.ttt* is only the structure with basic shapes and without the joint; *prismatic_v2_final.ttt* contains the complete piston. 

## IK examples

- [example_inverse_kinematics](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/tree/test/projects/example_inverse_kinematic) : (see the [manipulator](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/tree/test/projects/example_manipulator) example) this folder contains snippets and an implementation example of Inverse Kinematics in CoppeliaSim. Refer to the [documentation (ENG)](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/blob/test/projects/example_inverse_kinematic/README.md) and [documentation (ITA)](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/blob/test/projects/example_inverse_kinematic/CoppeliaSim__Inverse_Kinematics__FUNZIONANTE.pdf) for further details. 

## Spawning and timing

- [snippets_spawning](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/tree/test/projects/snippets_spawning) : some tests on the simple spawning using the *copy&paste* approach. See the [readme](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/blob/test/projects/snippets_spawning/README.md) for further details. 
- [snippets about timing](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/blob/test/projects/snippets_spawning/timing_patterns.md) : useful scripts and patterns to manage simulation time in non-threaded scripts. See also [snippets_spawning](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/tree/test/projects/snippets_spawning).
- [random spawning](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/tree/test/projects/random_spawning)
- [sensors and spawning](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/tree/test/projects/sensors_and_spawning)
- [removing objects and models](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/tree/test/projects/removing_objects)

## Vision Sensors

- [Examples on Perspective Vision Sensor](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/tree/test/projects/vision_sensors)

## Paths and trajectories

- [Trajectories Framework](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/tree/test/projects/trajectories)

## Finite State Machines
- [LUA/FSM framework](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/tree/test/projects/statte_machines_lua)

## Grippers and Movement Controller

- [About the Suction Pad](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/tree/test/projects/example_suction_pad)


## Other examples

- [working on conveyors](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/tree/test/projects/working_on_conveyors)
- [toggle visibilitiy](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/tree/test/projects/toggle_visibility)
- [advanced on LUA/CoppeliaSim scripting](https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton/tree/test/projects/scripting_advanced)
