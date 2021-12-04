# Example - Working on Conveyors

## Example 1 -- Carousel

Implementation of a simple carousel using the Generic Conveyor System provided in CoppeliaSim. 

Basic setup of a carousel:

1. importing the *generci conveyor system* into the scene
2. set *main properties --> path is closed*
3. place a cuboid on the conveyor. By default, the conveyor turns counter-clockwise wrt the world frame. 
4. Playing with the settings of the conveyor

## Playing with conveyor settings from Init function

Here are the default settings for the *generic conveyor system* you can find in the `sysCall_init()` function:

```lua
config.useRollers=false
config.rollerSize={0.05,0.2} -- diameter, length
config.padSize={0.05,0.2,0.005}
config.interPadSpace=0.002
config.useBorder=true
config.borderSize={0.05,0.005,0.05}
config.padCol={0.2,0.2,0.2}
config.col={0.5,0.5,0.5}
config.respondablePads=true
config.respondableBase=false
config.respondableBaseElementLength=0.05
config.initPos=0
config.initVel=0.16
```

### Rollers

```lua
-- Set 'true' to use rollers
config.useRollers = true

-- only if you use rollers, set diameter and length for each roller
config.rollerSize = {0.05, 0.2}

-- set each roller as collidable (default: true)
config.respondablePads = true
```

### Pads

By default, for each pad, **x** axis is oriented towards the motion, **y** axis is oriented orthogonally on the counter-clockwise direction, and **z** has upwards orientation. 

```lua
-- Set 'false' to use pads
config.useRollers = false

-- measures: x, y, z
config.padSize = {0.25, 0.2, 0.005}

-- space between pads
config.interPadSpace = 0.002

-- color (RGB) of each pad
config.padCol = {0.2,0.2,0.2}

-- set each pad as collidable (default: true)
config.respondablePads = true
```

### Borders

The border is the couple of guidelines close to the pads/rollers. It is made up of many chunks

```lua
-- by default, the conveyor has borders borders
config.useBorder = true

-- sizes: length, thickness, and height
config.borderSize={0.05, 0.005, 0.05}

-- color (RGB) of the border, but also of the whole structure
--    except for the pads/rollers
config.col = {0.2,0.5,0.5}
```

### Motion

```lua
-- initial position of the conveyor
config.initPos = 0

-- initial velocity of the conveyor
config.initVel = 0.16
```

## Where is 'conveyorSystem_customization'?

The default child script of the *general conveyor system* starts with this line:

```lua
conveyorSystem = require('conveyorSystem_customization')

-- ... --
```

Well, where is it? You can find the file into the folder 

> *<your CoppeliaSim installation folder>/CoppeliaSim/lua*

Inside this folder there are also other interesting scripts. By the way, this folder also contains the fundamental script **sim.lua** as well, among all other very interesting things. 

# Useful Links

- [What is a customization script?](https://www.coppeliarobotics.com/helpFiles/en/customizationScripts.htm)
- Meaning of the word **sim.Handle_self**, see [here, section LUA parameters](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simGetObjectHandle.htm)