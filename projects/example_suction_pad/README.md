# An example -- Suction Pad

## Aside -- about the Suction Pad

You can find the model in *components* -> *grippers* -> *suction pad* in CoppeliaSim. 

### Structure of the Suction Pad

Here are the components of this type of gripper:

- **s** : the proximity sensor, used to detect shapes that are *close to* the attach point
- **l** : this dummy is attached to the object to pick
- **l2** : this dummy keeps its father and is linked to the other one during pick-up
- **b** : the root of the model *suction pad*
- **suctionPadLink** : the force sensor of the suction pad

```lua
function sysCall_init() 
	-- get the structure of the gripper
    s   = sim.getObjectHandle('suctionPadSensor')
    l   = sim.getObjectHandle('suctionPadLoopClosureDummy1')
    l2  = sim.getObjectHandle('suctionPadLoopClosureDummy2')
    b   = sim.getObjectHandle('suctionPad')
    suctionPadLink = sim.getObjectHandle('suctionPadLink')
	
	-- settings of the suction pad (you can customize them)
    infiniteStrength=true
    maxPullForce=3
    maxShearForce=1
    maxPeelTorque=0.1
    enabled=true
	
	-- setup
    sim.setLinkDummy(l,-1)
    sim.setObjectParent(l,b,true)
    m=sim.getObjectMatrix(l2,-1)
    sim.setObjectMatrix(l,-1,m)
end
```

### The logic of the Suction pad

**Object pick-up**. *Shape* is the object to pick-up. 

```lua
-- the parent of 'suctionPadLoopClosureDummy1' is the root of the SuctionPad
sim.setObjectParent(l, b, true)

-- the position of the 'suctionPadLoopClosureDummy2' is the same of the previous one
m=sim.getObjectMatrix(l2,-1)
sim.setObjectMatrix(l,-1,m)

-- set 'suctionPadLoopClosureDummy1' child of the object we want to pick-up
sim.setObjectParent(l, shape, true) --> the last boolean says "keep it where is placed!"

-- link the dummies, to that the object follows the dummy
sim.setLinkDummy(l, l2)
```

**Release**. For releasing an object, it is enough to break the linkage and restore the father of the dummy. 

```lua
-- unlink the dummies
sim.setLinkDummy( l, -1 ) --> '-1' that is 'no father'

-- reset the previous parent for the dummy 1
sim.setObjectParent( l, b, true )

-- make the poses of the two dummies to coincide
m=sim.getObjectMatrix( l2, -1 )
sim.setObjectMatrix( l, -1, m )
```

**Forced release**. Note that, inside the code, the parent of the first dummy is checked compared to the state. In other words, if the suction pad is not in state *enabled* (i.e. it grasped something previously), the parent of the first dummy must be the root of the suction pad hierarchy. Otherwise, the state is *inconsistent*, so the code restores the state to *not enabled*. The code executed in this situation is always the same:

```lua
sim.setLinkDummy( l, -1 )
sim.setObjectParent( l, b, true )
m=sim.getObjectMatrix( l2, -1 )
sim.setObjectMatrix( l, -1, m )
```

So, to let the object to fall down, it is sufficient to *break the link*: the code will perform all the other steps. Find teh dummy of the gripper (let's say, `dummy`), then make it unlinked by calling `sim.setLinkDummy( dummy, -1 )`. 