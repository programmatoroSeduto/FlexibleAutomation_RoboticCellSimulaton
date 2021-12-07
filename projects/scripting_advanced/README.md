# LUA snippets -- Scripting Advanced

## Call a script from another script

See these links: 

- [sim.getScriptAssociatedWithObject](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simGetScriptAssociatedWithObject.htm)
- [sim.callScriptFunction](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simCallScriptFunction.htm)
- for further infos, see also the [regular API](https://www.coppeliarobotics.com/helpFiles/en/apiFunctions.htm) section *Scripts*
- [Messaging/interfaces/connectivity](https://www.coppeliarobotics.com/helpFiles/en/meansOfCommunication.htm)
- [sim.packTable](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simPackTable.htm)
- [sim.unpackTable](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simUnpackTable.htm)
- Other *packing* functions [here (API)](https://www.coppeliarobotics.com/helpFiles/en/apiFunctions.htm#packing)
- Here is [how to temporany disable error notifications](https://forum.coppeliarobotics.com/viewtopic.php?t=6975)

Just a simple example. Let's suppose that you want to call the function `my_function( )` which is contained in a *child script* (in CoppeliaSim, `sim.scripttype_childscript`) belonging to an object named `my_object` (which is also the default name of the script) with no arguments. 

So, you can do this, that is completely equivalent to call the function *in the scope the code is in*:

```lua
returnval = sim.callScriptFunction( 
	"my_function@my_object",   --> <the function to call>@<the script the function is placed>
	sim.scripttype_childscript --> kind of script to find
	)
```

note that any returned value is saved *in the scope that coninains this calling*. 

## Shared Settings Pattern

Sometimes you need to share informations between nodes, for instance to avoid hard-coding and enclose all the settings in one plac instead of in many places. This can be done using 

- a function which returns an object, and
- the call `sim.callScriptFunction( )` with the option `sim.scripttype_mainscript`

Of course you can put this function everywhere inside the simulation. Here is an example of pattern: in the main script, 

```lua
-- MAIN SCRIPT
require('defaultMainScript')

function shared_infos( )
	local shared = {}
	
	-- put inside 'shared' everything you want
	--> shared.option = value
	
	return shared
end
```

You can retrieve the infos using this. *Note that*, with main scripts, the name of the script is not required because for every scene there's only one main script. 

```lua
shared = sim.callScriptFunction( "shared_infos", sim.scripttype_mainscript )
```

The advantage of this patters is that the settings of a scene are collected in only one place, and the scene doesn't require external script files. However there are also several cons:

- you can only read and copy infos. Of course you can rebuild the structure re-calling the function, but the object will remain a copy and not something really shared. 
- settings cannot be shared by different scenes: if you have two or more scenes with the same settings, you should copy and paste, which is clearly a very poor solution. The best is to create an external script

## Script Communication using Custom Data Blocks

A *custom data block* is a shared table among the scripts. These fields are associated to an object into the scene, and represents the "public interface" of the object. 

```lua
--- WRITE
-- define / rewrite a shared variable
sim.writeCustomDataBlock( obj_handle, "var_name", "var_value" )
-- ES:
sim.writeCustomDataBlock( pack.suction_root, "enabled", "false" )

--- READ
sim.readCustomDataBlock( obj_handle, "var_name" )
```