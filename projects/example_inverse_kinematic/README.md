# Inverse Kinematics

## Tools of the trade

Inverse Kinematics methods:

- [IK plugin API reference](https://www.coppeliarobotics.com/helpFiles/en/simIK.htm)
- [simIK.setIkGroupCalculation](https://www.coppeliarobotics.com/helpFiles/en/simIK.htm#simIK.setIkGroupCalculation)

## Before starting ...

Words:

- **BASE** : the point where the kinematic chain starts
- **TIP** : the end effector
- **TARGET** : the point that the tip should reach using IK

IK: the chain, between BASE and TIP, should move in a way such that, at the end off the motion, the positions of TIP and TARGET coincide. In case the percect coincidence is not feasible, the algorithm searches for the minimum distance. 

- **GROUP** : a kinematic chain
- **ENVIRONMENT** : a set of groups

Checkings you should do before the implementation of the IK on code:

- all the joints in the kinematic chain must be with the flags *motor enabled* and *control loop enabled*; check the dynamic properties of the joints
- the TARGET must be linked to the TIP
- BASE, TIP and OBJECT aren't necessarily dummies: they can be every shape/mesh you want. 

## Simple Implementation

### Init of a simple kinematic group

Let's define and use one kinematic chain. Here is the procedure:

1. get the handles of BASE, TIP and TARGET
2. create a IK evironment using `simIK.createEnvironment( )`; you need this handler later
3. create a group using `simIK.createIkGroup( ik_environment )`; you need this handler later
4. set the calculation parameters using `simIK.setIkGroupCalculation(ik_environment, ik_group, simIK.method_pseudo_inverse, 0, 6)` (just some example values, see the documentation!)
5. finally, instantiate the kinematic chain using `simIK.addIkElementFromScene(ik_environment, ik_group , BASE, TIP, TARGET, simIK.constraint_pose)` (there are also other constraints, see the documentation)

A very common example of initialization:

```lua
function sysCall_init()
    BASE   = sim.getObjectHandle( "base" )
    TIP    = sim.getObjectHandle( "tip" )
    TARGET = sim.getObjectHandle( "target" )
    
    IK_ENV = simIK.createEnvironment( )
    IK_GROUP = simIK.createIkGroup( IK_ENV )
    simIK.setIkGroupCalculation( IK_ENV, IK_GROUP, simIK.method_pseudo_inverse, 0, 99 )
    local rs = simIK.addIkElementFromScene( IK_ENV, IK_GROUP, BASE, TIP, TARGET, simIK.constraint_pose )
end
```

### Actuation

Just call the function `simIK.applyIkEnvironmentToScene( ik_environment, ik_group )`; refer to the documentation for further infos. 

```lua
function ik_actuate()
    simIK.applyIkEnvironmentToScene( IK_ENV, IK_GROUP )
end
```

### Dampened implementation Vs. Undampened implementation

It could happen that the resolution algorithm `simIK.method_pseudo_inverse` is unable to find a solution. Anyway we ca solve the IK problem, as much as possible, changing algorithm: the strategy is to try first with "the best algorithm", and if it doesn't work, to use another one, maybe not beutiful, but effective. 

We can use a lighter algorithm `simIK.method_damped_least_squares`; this algorithm simply tries to find the solution which makes the distance between TIP and TARGET as less as possible, in terms of quartaric distance. 

You can find [here](https://www.coppeliarobotics.com/helpFiles/en/inverseKinematicsTutorial.htm) a more sophisticated implementation. Here is the skeleton from that:

```lua
function sysCall_init()
    BASE   = sim.getObjectHandle( "base" )
    TIP    = sim.getObjectHandle( "tip" )
    TARGET = sim.getObjectHandle( "target" )
    
    -- one environment for both the resolution methods
    IK_ENV = simIK.createEnvironment( )
    
    -- FIRST ALGORITHM  : IK with pseudo-inverse
    IK_GROUP_algo1 = simIK.createIkGroup( IK_ENV )
    simIK.setIkGroupCalculation( IK_ENV, IK_GROUP_algo1, simIK.method_pseudo_inverse, 0, 99 )
    simIK.addIkElementFromScene( IK_ENV, IK_GROUP_algo1, BASE, TIP, TARGET, simIK.constraint_pose )
    
    -- SECOND ALGORITHM : Least Square
    IK_GROUP_algo2 = simIK.createIkGroup( IK_ENV )
    simIK.setIkGroupCalculation( IK_ENV, IK_GROUP_algo2, simIK.method_damped_least_squares, 1, 99 )
    simIK.addIkElementFromScene( IK_ENV, IK_GROUP_algo2, BASE, TIP, TARGET, simIK.constraint_pose )
end
``` 

Actuation changes a bit: the function `simIK.applyIkEnvironmentToScene( env, gr, apply_on_success? )` returns `simIK.result_fail` in singularities. When one algorithm fails, try the next one. The `simIK.method_damped_least_squares` is the last resort. 

```lua
function sysCall_actuation()
    -- try with the first algorithm
    if simIK.applyIkEnvironmentToScene( IK_ENV, IK_GROUP_algo1, true ) == simIK.result_fail then
        --try with the second one (it shouldnt fail, bit please check)
        simIK.applyIkEnvironmentToScene( IK_ENV, IK_GROUP_algo2 )
    end
end
```

### Init Issue

See the example *example_issue*. An issue could happen in calling the function `simIK.addIkElementFromScene()`, similar to this one:

```
[suction_picker@childScript:error] 262: Object does not exist. (in function 'sim.getObjectType')
    stack traceback:
        [C]: in function 'sim.getObjectType'
        ...gram Files/CoppeliaRobotics/CoppeliaSimEdu/lua/simIK.lua:262: in function 'simIK.addIkElementFromScene'
        [string "suction_picker@childScript"]:9: in function 'sysCall_init'
[sandboxScript:info] Simulation suspended.
```

The instruction `local rs = simIK.addIkElementFromScene( IK_ENV, IK_GROUP, BASE, TIP, TARGET, simIK.constraint_pose )` causes this *unclear* issue: in fact, all the handlers in the example are valid, so there's no reason for this message. 

The error lies in the line `BASE = sim.getObjectHandle( "base" )`: for some reason, CoppeliaSim refuses this kinematic chain, making the instruction `simIK.addIkElementFromScene()` to fail. Changing that line with `BASE = sim.getObjectHandle( "suction_picker" )` (the dummy before the first piece of the kinematic chain) everything works as expected. 