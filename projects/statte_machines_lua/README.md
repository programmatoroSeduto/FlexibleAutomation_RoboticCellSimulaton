# LUA snippets -- A pattern for State Machines in CoppeliaSim

## Resources 

About Lua Syntax:

- [Anonymous Functions in LUA](https://riptutorial.com/lua/example/4080/anonymous-functions); btw see [RIP tutorial](https://riptutorial.com/)
- Unfortunately keywords like `this` and `self` doesn't exist in LUA, so you should use a workaroud as described in [the documentation about OOP in LUA](https://www.lua.org/pil/16.html)
- about [default parameters](https://riptutorial.com/lua/example/4081/default-parameters) in LUA functions

## First version -- a small framework for state machines in LUA

Note that the variables starting with double underscore are to be considered as *private* pretty much like in Python naming conventions. 

### State Machine Init

The following function `smach_init( )` returns an empty state machine. 

```lua
function smach_init( )
    local sm = { }

    -- transition function
    sm.__transition_function = { }
    --[[
    Access Syntax:
        1. numeric - DIRECT ACCESS
            transition_function[ state_idx ]     --> state_record
        2. by string - INDIRECT ACCESS
            transition_function[ "state_label" ] --> state_idx
            then you can use the state_idx to access the record
    State record structure:
        state_label (must be unique)
        state_idx (automatically set)
        state_action (the function associated with the state)
    Action Prototype:
        arguments: 
            1. a single package with everythin needed to run the state
            2. the state machine itself
        returns: the label of the next state, or nothing
            when nothing is returned, the machine doesn't update its state
    --]]

    -- how many states are in the state machine
    sm.__state_count = 0
    -- actual state (-1 if there's not a initial state)
    sm.state = -1
    sm.state_name = nil
    
    -- initial state (-1 if not set)
    sm.init_state = -1
    
    -- shared data for the states
    sm.shared = { }
    
    -- MEMBER: add a new state to the machine
    -- ARGS: self, label, function, is_init?
    -- RETURNS: success (true) or not (false) and the state (-1 if result is false)
    --    if the machine is empty, set the new state as initial 
    function sm.add_state( 
        self,          -- the state machine
        state_label,   -- the label of the state
        state_action,  -- the callback associated to the state
        is_init        -- default is 'false'
        )
        -- default args
        is_init = is_init or false
        
        -- verify the label
        if self.__exists_label( self, state_label ) then
            print( "[State Machine:add_state] ERROR: label '" .. state_label .. "' already defined." )
            return false
        end
        
        -- get the record
        local state_idx    = self.__state_count
        self.__state_count = self.__state_count + 1
        local state_record = self.__create_state_record( 
            state_label, state_idx, state_action )
        
        -- define the record into the table
        --- DIRECT ACCESS
        self.__transition_function[ state_idx ] = state_record
        --- INDIRECT ACCESS
        self.__transition_function[ state_label ] = state_idx
        
        -- set the initial state if needed
        if self.init_state < 0 or is_init then
            self.init_state = state_idx 
            self.state = state_idx
            self.state_name = state_label
        end
    end
    
    -- MEMBER: run the actual state
    --    set also shared infos is infos!=nil
    function sm.exec( self, infos )
        -- check if the machine has at least one state
        if self.init_state < 0 then
            print( "[State Machine:exec] ERROR: State machine not yet initialized!" )
            return false, nil, nil
        end
        
        -- get the state record
        local state_record = self.__transition_function[ self.state ]
        
        -- execute the actual state
        --    and gather the next state (as string)
        local state_next_str = nil
        if infos == nil then
            state_next_str = state_record[ "state_action" ]( self, self.shared )
        else
            self.shared = infos
            state_next_str = state_record[ "state_action" ]( self, self.shared )
        end
        
        -- compute the next state if possible
        local state_next_idx = self.__transition_function[ state_next_str ]
        
        -- update the state of the machine
        if state_next_idx ~= nil then
            self.state = state_next_idx
            self.state_name = state_record["state_name"]
        end
        
        return true, self.state, self.state_name  --> success
    end
    
    -- MEMBER: set/reset shared infos
    function sm.set_shared( self, pack )
        self.shared = pack
    end
    
    -- PRIVATE: verify if a label exists inside the transition_function
    function sm.__exists_label( self, label )
        for i = 1, #self.__transition_function, 1 do
            if self.__transition_function[i]["state_label"] == label then
                return true --> found a previously defined label in the table
            end
        end
        
        return false --> name is unique
    end
    
    -- PRIVATE: create a record
    function sm.__create_state_record( label, idx, action_funct )
        local record = { 
            ["state_label"]  = label, 
            ["state_idx"]    = idx,
            ["state_action"] = action_funct
        }
        
        return record
    end
    
    -- return the state machine
    return sm
end
```

### Adding states

For adding states to the machine, you can use simply the method `.add_state( self, label, function )`. By default, the first added state is considered also as *initial state*; in any case, you can indicate explicitly the state adding a `true` as last parameter. 

Here is a very common example:

```lua
-- create an empty state machine
smach = smach_init( )

-- define the states
--    just for example: two states
smach.add_state( smach, 
	"state_0", 
	function( self, pack )
		print( "from 0 to 1" )
		return  "state_1"
	end,
	true
)
smach.add_state( smach, 
	"state_1",
	function( self, pack )
		print( "from 1 to 0" )
		return "state_0"
	end,
	false
)
```

### Shared data

Using global variales could be a poor solution in many situations. So, this implementation allows the states to have a *shared storage* that you can initialize using `.set_shared( self, pack )` or reassign using `.exec( self, pack )`. Every time you call one of these functions, the "pack" is copied inside the state machine class, so each state can share memory instead of working with a copy.

```lua
-- set the package
local pack = { 
	["state_0_name"] = "oibo-boi",
	["state_1_name"] = "ciaccia"
}
smach.set_shared( smach, pack )
```

### Execute the machine

Each time the function `.exec( self )` is called, the machine calls the function associated with the current state and performs a transition. 

The version `.exec( self, pack )` of the method allows the program to "reset" the shared memory. Take into account that *only the copy inside the state machine is updated by the states*: the package provided is copied before executing the action, so the "pack" doesn't change. 

```lua
function sysCall_actuation()
    if check_time( ) then
        smach.exec( smach )
    end
end
```

## A complete example -- FSM with two states

See the example *state_code*. In this example, the state changes every 2 seconds. The machine is made up of only two states, *state_0* and *state_1*.

```lua
-- clock pattern + check and run
function check_time( )
    local clock_now = sim.getSimulationTime( )
    
    -- check if timing is enabled
    if time_setup == nil then
        -- setup clock
        delta_time = 2
        clock_next = clock_now + delta_time
        
        time_setup = true
    end
    
    -- check time
    if clock_now >= clock_next then
        clock_next = sim.getSimulationTime( ) + delta_time
        return true
    else
        return false
    end
end


-- Create an empty state machine
function smach_init( )
    local sm = {}

    -- transition function
    sm.__transition_function = { }
    --[[
    Access Syntax:
        1. numeric - DIRECT ACCESS
            transition_function[ state_idx ]     --> state_record
        2. by string - INDIRECT ACCESS
            transition_function[ "state_label" ] --> state_idx
            then you can use the state_idx to access the record
    State record structure:
        state_label (must be unique)
        state_idx (automatically set)
        state_action (the function associated with the state)
    Action Prototype:
        arguments: 
            1. a single package with everythin needed to run the state
            2. the state machine itself
        returns: the label of the next state
    --]]

    -- how many states are in the state machine
    sm.__state_count = 0
    -- actual state (-1 if there's not a initial state)
    sm.state = -1
    
    -- initial state (-1 if not set)
    sm.init_state = -1
    
    -- shared data for the states
    sm.shared = { }
    
    -- MEMBER: add a new state to the machine
    -- ARGS: self, label, function, is_init?
    -- RETURNS: success (true) or not (false)
    --    if the machine is empty, set the new state as initial 
    function sm.add_state( 
        self,          -- the state machine
        state_label,   -- the label of the state
        state_action,  -- the callback associated to the state
        is_init        -- default is 'false'
        )
        -- default args
        is_init = is_init or false
        
        -- verify the label
        if self.__exists_label( self, state_label ) then
            print( "[State Machine:add_state] ERROR: label '" .. state_label .. "' already defined." )
            return false
        end
        
        -- get the record
        local state_idx    = self.__state_count
        self.__state_count = self.__state_count + 1
        local state_record = self.__create_state_record( 
            state_label, state_idx, state_action )
        
        -- define the record into the table
        --- DIRECT ACCESS
        self.__transition_function[ state_idx ] = state_record
        --- INDIRECT ACCESS
        self.__transition_function[ state_label ] = state_idx
        
        -- set the initial state if needed
        if self.init_state < 0 or is_init then
            self.init_state = state_idx 
            self.state = state_idx
        end
    end
    
    -- MEMBER: run the actual state
    --    set also shared infos is infos!=nil
    function sm.exec( self, infos )
        -- check if the machine has at least one state
        if self.init_state < 0 then
            print( "[State Machine:exec] ERROR: State machine not yet initialized!" )
            return false
        end
        
        -- get the state record
        local state_record = self.__transition_function[ self.state ]
        
        -- execute the actual state
        --    and gather the next state (as string)
        local state_next_str = nil
        if infos == nil then
            state_next_str = state_record[ "state_action" ]( self, self.shared )
        else
            self.shared = infos
            state_next_str = state_record[ "state_action" ]( self, self.shared )
        end
        
        -- compute the next state if possible
        local state_next_idx = self.__transition_function[ state_next_str ]
        if state_next_idx == nil then
            print( "[State Machine:exec] ERROR: state action of '" .. 
                state_record["state_label"] .. "' returned an unexistent state!")
            return false
        end
        
        -- update the state of the machine
        self.state = state_next_idx
        
        return true --> success
    end
    
    -- MEMBER: set/reset shared infos
    function sm.set_shared( self, pack )
        self.shared = pack
    end
    
    -- PRIVATE: verify if a label exists inside the transition_function
    function sm.__exists_label( self, label )
        for i = 1, #self.__transition_function, 1 do
            if self.__transition_function[i]["state_label"] == label then
                return true --> found a previously defined label in the table
            end
        end
        
        return false --> name is unique
    end
    
    -- PRIVATE: create a record
    function sm.__create_state_record( label, idx, action_funct )
        local record = { 
            ["state_label"]  = label, 
            ["state_idx"]    = idx,
            ["state_action"] = action_funct
        }
        
        return record
    end
    
    -- return the state machine
    return sm
end


function sysCall_init()
    -- create an empty state machine
    smach = smach_init( )
    
    -- define the states
    --    just for example: two states
    smach.add_state( smach, 
        "state_0", 
        function( self, pack )
            print( "from " .. pack["state_0_name"] .. " to " .. pack["state_1_name"] )
            return  "state_1"
        end,
        true
    )
    smach.add_state( smach, 
        "state_1",
        function( self, pack )
            print( "from " .. pack["state_1_name"] .. " to " .. pack["state_0_name"] )
            return "state_0"
        end,
        false
    )
    
    -- set the package
    pack = { 
        ["state_0_name"] = "oibo-boi",
        ["state_1_name"] = "ciaccia"
    }
    smach.set_shared( smach, pack )
end


function sysCall_actuation()
    if check_time( ) then
        smach.exec( smach )
    end
end
```

## A more advanced example -- FSM and Trajectories

See the example *smach_trajectories*, which combines the trajectory framework with the state machine. Here is the main part of the code, which uses the scripts presented before:

```lua
function setup_smach( )
    local machine = smach_init( )
    
    -- shared infos
    local shared_info = {
        handlers = point_set,
        sequence_idx = 1,
        path_h = nil,
        ptr = pointer,
        end_job = false,
        velocity = 1,
    }
    machine.set_shared( machine, shared_info )
    
    -- state: INIT
    machine.add_state( machine,
        "INIT",
        function( self, pack )
            print( "state: INIT" )
            
            return "update_path"
        end, 
        true
    )
    
    -- state: update target
    machine.add_state( machine,
        "update_path",
        function( self, pack )
            print(  "state: UPDATE_PATH" )
            
            -- end of the cycle
            if pack.sequence_idx > #pack.handlers then
                return "END"
            end
            
            -- change path
            pack.path_h = path_switch( 
                pack.handlers[pack.sequence_idx], 
                pack.path_h,
                pack.ptr
            )
            pack.sequence_idx = pack.sequence_idx + 1
            
            print(  "state: GO_TO_POINT" )
            return "go_to_point"
        end
    )
    
    -- state: go to point
    machine.add_state( machine,
        "go_to_point",
        function( self, pack )
            if path_move( pack.path_h, pack.velocity ) then
                return "update_path"
            else
                return "go_to_point"
            end
        end
    )
    
    -- state: END
    machine.add_state( machine,
        "END",
        function( self, pack )
            print( "state: END" )
            pack.sequence_idx = 1
            return "INIT"
        end
    )
    
    return machine
end


function sysCall_init( )
    -- elements from the scene: pointer...
    pointer = sim.getObjectHandle( "point_to_move" )
    -- ...and destinations
    point_set = {}
    for i=1,4,1 do
        point_set[i] = sim.getObjectHandle( "pose_" .. i )
    end
    
    sm = setup_smach( )
    print( sm )
end


function sysCall_actuation( )
    sm.exec( sm )
end
```

# Some console examples

```lua
--[[ 
ABOUT MAPS SYNTAX:
map = { ["uno"]=1, ["due"]=2 }
map["uno"] --> 1
map[1]     --> nil

STRANGE TABLE:
strange_table = {x=10, y=45; "one", "two", "three"}

FUNCTIONS AND TABLES:
> action_table = {}
> action_table
{}
> local myfunct = function() print( "funct" ) end
> myfunct()
funct
> action_table[1] = myfunct
> action_table[1]
"<FUNCTION 000001A893621AD0>"
> action_table[1]()
funct

OBJECT ORIENTED FASHON:
> my_object = {}
> function my_object.my_function( ) print( "body of my_object.my_function( )" ) end
> my_object.my_function
"<FUNCTION 000001A893624440>"
> my_object.my_function()
body of my_object.my_function( )

FUNCTION WITH DEFAULT ARGS:
-- not working methods:
> function with_init_param( x=42 ) print( x ) end
[string "function with_init_param( x=42 ) print( x ) e..."]:1: ')' expected near '='
> function with_init_param( x:42 ) print( x ) end
[string "function with_init_param( x:42 ) print( x ) e..."]:1: ')' expected near ':'
> function with_init_param( x ) print( x ) end
-- working:
> function with_init_param( x ) 
    x = x or 42 
    print( x )
  end
> with_init_param()
42
> with_init_param( -1 )
-1

DEFINITION CHECKING INSIDE A TABLE
> tab = { 5, 2 }
> typeof( 5 )
[string "typeof( 5 )"]:1: attempt to call a nil value (global 'typeof')
> type( 5 )
"number"
> type( nil )
"nil"
> type( tab[3] )
"nil"

RETURN MULTIVALUE
-- not the correct syntax
> function multi_return( a, b ) 
        return { a, b } 
    end 
    c, d = multi_return( 1, 2 )
> c
{1, 2}
> b
nil
> d
nil
-- the correct one
> function multi_return( a, b ) 
        return a, b 
    end 
    c, d = multi_return( 1, 2 )
> c
1
> d
2
--]]
```