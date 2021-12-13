# Robotic Cell Simulation with CoppeliaSim

*Francesco Ganci, 4143910*, Robotics Engineering, *UniGe, A.A. 2021/2022*

Assignment for the simulation part in *Flexible Automation* course.

## Introduction

Purpose of this project is to implement a prototype of a robotic industrial cell able to sort three types of automotive vendors into the right conveyor. Th prototye is made entirely in CoppeliaSim. Inside the cell there is a robot cabaple to grasp softly the objects and move them from a load zone into the right conveyor. 

You can find two branches in this repository:

- the **main** branch contains the project and other things like the meshes used for the probject, or other files related to the development process of the project. The folder *submission* contains the same submission you can find [on the OneDrive of the course](https://unigeit.sharepoint.com/sites/FLEXIBLEAUTOMATION2021/Documenti%20condivisi/Forms/AllItems.aspx?id=%2Fsites%2FFLEXIBLEAUTOMATION2021%2FDocumenti%20condivisi%2FSimulationAssignmentRepo%2F4143910%5FGanci&viewid=4acfc479%2D342f%2D4256%2D8e95%2Dd935d9290dc9).
- the **test** branch is an archive of useful scripts I implemented before starting the project. You can find many of them, customized or not, inside the code of my project. 

### How to run this project

First of all, create a new forlder and clone this repository. Here is the shell command:

```bash
git clone https://github.com/programmatoroSeduto/FlexibleAutomation_RoboticCellSimulaton.git -b main .
```

You can find the final version of the project inside the folder *submission*. Open the scene file: you should see the robotic cell, as well as the floating view referred to the monitoring system. In order to launch the simulation, simply click on play. I suggest you to close che sidebars on the left of the window, so you can have a wider visual on the cell.

### Camera reference position

You can notice that the *DefaultCamera* is child of the dummy object *DefaultCameraReference*: this is, in my opinion, the best visual to appreciate how the robotic cell works; to set the visual, go inside the customization script alongside with *DefaultCameraReference*, and run the script. 

### Monitor System

In order to let the human operator to check how the robotic cell is working, a monitoring system is implemented with an array of cameras distributed in the main points of the robotic cell. The screen is managed by a module called *OS_monitor*, located in *control_system/operating_system/OS_proc* in the "task level". The screen shows the working phases of the crane robot inside the cell: it is not only a nice way to understand how the crane works, but also a tool for the maintenance of the devices. 

Currently the cameras have low resolution, in order to make the simulation lighter. Anyway, it is possible to enlarge the resolution of the cameras from *control_system/sensors/monitor_cam/input_cam*; unfortunately, CoppeliaSim doesn't allow the programmer to manage the resolution of a vision sensor from script, so you have to update *manually* the resolution for each camera inside the array. Make sure to have the same resolution for each camera, otherwise the module *OS_monitor* will complain a resolution error. 

The sensor used as screen is located at *control_system/sensors/monitor_cam/output_cam*; its name is *screen_cam_128_128*.