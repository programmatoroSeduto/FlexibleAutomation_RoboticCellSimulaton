# How to use Vision Sensors in CoppeliaSim

Some small examples of *usage* and *detection* of vision sensors with CoppeliaSim. 

## Tools of the trade

Documentation:

- An overview about [Vision Sensors](https://www.coppeliarobotics.com/helpFiles/en/visionSensors.htm)
- Just an introduction on [how to use wision sensors (video)](https://www.youtube.com/watch?v=bh3wY5BHzsg)
- A note about [pages and views](https://www.coppeliarobotics.com/helpFiles/en/pagesAndViews.htm), in particular *floating views*
- vision sensor [properties](https://www.coppeliarobotics.com/helpFiles/en/visionSensorPropertiesDialog.htm) in CoppeliaSim
- a more deep example about vision sensors [here (video)](https://www.youtube.com/watch?v=k9MGG4T3OWA)

API pages:

- List of functions, see [Vision Sensors regular API](https://www.coppeliarobotics.com/helpFiles/en/apiFunctions.htm#visionSensor)
- [simVision API](https://www.coppeliarobotics.com/helpFiles/en/simVision.htm?view=category)
- [IM plugin API reference](https://www.coppeliarobotics.com/helpFiles/en/simIM.htm?view=alphabetical)

From forums:

- [Display Image from Vision Sensor](https://forum.coppeliarobotics.com/viewtopic.php?t=7383)
- [Possibility to display an image in a floating view?](https://forum.coppeliarobotics.com/viewtopic.php?t=5565)
- [object detection by Vision Sensor](https://forum.coppeliarobotics.com/viewtopic.php?t=320)

Tools:

- [sim.setVisionSensorCharImage](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simSetVisionSensorCharImage.htm)
- [sim.getVisionSensorCharImage](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simGetVisionSensorCharImage.htm)
- [sim.getVisionSensorImage](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simGetVisionSensorImage.htm)
- [sim.setVisionSensorImage](https://www.coppeliarobotics.com/helpFiles/en/regularApi/simSetVisionSensorImage.htm)

See also:

- About [tables in LUA (reference)](https://www.tutorialspoint.com/lua/lua_tables.htm)
- [StackOverflow - LUA and equality being using tables](https://stackoverflow.com/questions/20325332/how-to-check-if-two-tablesobjects-have-the-same-value-in-lua)

## Before starting - an overview on Vision Sensors in CoppeliaSim

There are mainly two types of vision sensors available:

- **orthographic** sensor
- **perspective** sensor

The scene *vision_setup_no_code.ttt* contains an example of usage of a vision sensor. 

### VERY IMPORTANT -- Renderable Objects

An object we want to detect with any vision sensor has to be set as *renderable* before starting the simulation. Otherwise, the vision sensor cannot detect it. 

### View the image from the sensor

1. Right click in a empty part of the scene -> *add* -> *floating view*; a new empty window pops out
2. select the vision sensor to observe
3. right click in the empty window -> *view* -> *Associate View with selected vision sensor*

Alternatively you can simply add the sensor from the empty window clicking on *view* -> *view selection*. Each vision sensor opens a new view among the others. 

**It is worthy of note that** the screens you add to the simulation are automatically saved into the scene, so, as you close and re-open the scene, the saved setup is restored, views included. 

### Vision Sensors and LUA

With no further conditions, CoppeliaSim automatically manages the transmission of the image from the vision sensor to its window. But what if we're interested in filter the image and, in any case, to elaborate it? 

Infos can be *redirected* to LUA scripts (by handles) using the flags **Explicit handling** and **External Input**. Please refer to the documentation for more infos. 

**Let's say more**. If you associate a window with a vision sensor, *the sensor represents the window in the hierarchy*, so for instance you can take the image from one camera and transfer it in anothe one *referring by code to the sensor linked to the window*. 

## A first example -- image transfer

See the example *vision_image_transfer*: the image is collected from the *unhandled* camera, and transmitted *to the second window* using the sensor *handled* as reference to the window. **Result**: you can see the *unhandled* output also in the *handled* window. 

```lua
-- child script of 'vision_sensor_group'
function sysCall_init()
    cam_from = sim.getObjectHandle( "vision_unhandled" )
    cam_to   = sim.getObjectHandle( "vision_handled" )
end

function sysCall_actuation()
    -- transfer the image from the fist cam to the second one
    if image ~= nil then
        sim.setVisionSensorCharImage( cam_to, image )
		-- also this works fine (but don't mix the approaches)
		-- sim.setVisionSensorImage( cam_to, image )
    end
end

function sysCall_sensing()
    -- take the image from the 'from' camera
    image = nil
    image = sim.getVisionSensorCharImage( cam_from )
	-- also this works fine (but don't mix the approaches)
	-- image = sim.getVisionSensorImage( cam_from )
end

function sysCall_cleanup()
    sim.resetVisionSensor( cam_to )
end
```

Some observations:

- the vision sensors must have the same resolution
- you cannot *set* the image if the vision sensor **Explicit handling** and **External Input**; you can only read from the sensor

## Camera Timed Switch

In the example *vision_timed.ttt* there are 2 vision sensors as input and one output, which is called *screen*. The input is changed every 2 seconds. 

```lua
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

-- child script of 'vision_sensor_group'
function sysCall_init()
    screen = sim.getObjectHandle( "vision_screen" )
    cam_0 = sim.getObjectHandle( "vision_camera_" .. 0 )
    cam_1 = sim.getObjectHandle( "vision_camera_" .. 1 )
    
    cam_idx = 0 --> 1: use cam from - 0: use cam to
    print( "switch camera --> " .. cam_idx )
end

function sysCall_actuation()
    -- transfer the image from the fist cam to the second one
    if image ~= nil then
        sim.setVisionSensorCharImage( screen, image )
    end
    
    if check_time( ) then
        cam_idx = (cam_idx + 1) % 2
        print( "switch camera --> " .. cam_idx )
    end
end

function sysCall_sensing()
    -- take the image from the 'from' camera
    image = nil
    
    if cam_idx > 0 then
        image = sim.getVisionSensorCharImage( cam_1 )
    else
        image = sim.getVisionSensorCharImage( cam_0 )
    end
end

function sysCall_cleanup()
    sim.resetVisionSensor( screen )
end
```

## Color Detection

See example *color_detection.ttt*: it shows how to use a ortographic sensor for identifying a base color. Before starting, remember to check these points:

- the object you want to detect must be *renderable*
- the object should have a *specular* color set, as well as an ambient-diffuse color

```lua
-- get the average color from the sensor
-- image : one array of dimensions res_x*res_y*3
--    { r, g, b, r, g, b, r, g, ... }
--    1,2,3 --> pixel [1][1]
--    4,5,6 --> pixel [1][2]
-- RETURNS: { r = avg_r, g = avg_g, b = avg_b }
-- ARGS: the image, the size as array {x, y}
function img_get_average_color_rgb( frame, img_res )
    local avg = {
        r = 0.0,
        g = 0.0,
        b = 0.0
    }
    local n_pixels = img_res[1]*img_res[2]
    
    -- summation of all the values
    for i = 1, n_pixels*3, 3 do
        avg.r = avg.r + frame[i]
        avg.g = avg.g + frame[i + 1]
        avg.b = avg.b + frame[i + 2]
    end
    
    -- average values
    avg.r = math.floor(avg.r / n_pixels + 0.5)
    avg.g = math.floor(avg.g / n_pixels + 0.5)
    avg.b = math.floor(avg.b / n_pixels + 0.5)
    
    return avg
end

-- a simple lookup for a maximum (only three colors)
function detect_color_3( avg )
    if avg.r > avg.g and avg.r > avg.b then
        return "RED"
    elseif avg.g > avg.r and avg.g > avg.b then
        return "GREEN"
    else
        return "BLUE"
    end
end

-- check for new colors
-- RETURNS: if it is a new color, the ID of the color
-- INPUt: avg color array {r=, g=, b=}
function detect_new_color( avg )
    local new_color = false
    local color_ID = 0
    
    -- if the list is empty, the color is for sure new
    if #color_list == 0 then
        table.insert( color_list, avg )
        new_color = true
        color_ID = 1
        
        return new_color, color_ID
    end
    
    -- search for the color
    local found_color = false
    for i = 1, #color_list, 1 do
        local col = color_list[i]
        if col.r == avg.r and col.b == avg.b and col.g == avg.g then
            found_color = true
            color_ID = i
            break
        end
    end
    
    if not found_color then 
        table.insert( color_list, avg )
        new_color = true
        color_ID = #color_list
    end
    
    return new_color, color_ID
end

function sysCall_init()
    -- vision sensor
    vision  = sim.getObjectHandle( "color_sensor" )
    img_resolution = sim.getVisionSensorResolution( vision ) --> {x, y}
    last_frame = {}
    avg_color = { r=0.0, g=0.0, b=0.0 }
    frame_count = 0
    color_list = {}
    
    -- trigger
    trigger = sim.getObjectHandle( "color_sensor_trigger" )
    triggered = false
end

function sysCall_sensing()
    -- attempt to read the trigger
    local trigger_state = sim.readProximitySensor( trigger )
    if trigger_state > 0 and not triggered then
        triggered = true
        
        -- get the image
        last_frame = sim.getVisionSensorImage( vision )
        frame_count = frame_count + 1
        
        -- compute the average color
        avg_color = img_get_average_color_rgb( last_frame, img_resolution )
        local isnewcolor, idcolor = detect_new_color( avg_color )
        if isnewcolor then
            print( "detected color TAG --> " .. idcolor .. " (new color found)" )
        else
            print( "detected color TAG --> " .. idcolor .. " (not a new color)")
        end
        
    elseif trigger_state < 1 and triggered then
        triggered = false
    end
end
```