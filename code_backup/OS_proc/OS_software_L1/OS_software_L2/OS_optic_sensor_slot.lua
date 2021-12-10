--[[ 
    OS_optic_sensor_slot
        detect the type of the object for each slot. This module manages 3 vision sensors
        at the same time.
    
    ASSUMPTIONS:
    - orthographic sensor is employed, along with a laser sensor (proximity)
    - noise completely absent
    - each object is made up of one base color (out of 3)
    - the number of objects to detect is knows in advance, as well as their informations
    
    SHARED DATA:
    OS_optic_sensor_shared: (array)
    - state: (bool)
        true  --> there's an object in front of the sensor
        false --> sensor zone free
    - last_detection: (string)
        "oiltray", "fuelpump", "camshaft", "none"
--]]
--




--
--- DETECTION FUNCTIONS
--

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
--

-- a simple lookup for a maximum (only three colors)
--    RETURNS 1:red, 2:green, 3:blue
function detect_color_3( avg )
        if avg.r > avg.g and avg.r > avg.b then
        return 1 --> red
    elseif avg.g > avg.r and avg.g > avg.b then
        return 2 --> green
    elseif avg.b > avg.r and avg.b > avg.g then
        return 3 --> blue
    else
        -- ERROR!
        return -1
    end
end
--

--- setup the date for the object detection
function data_setup( )
    -- (1:red, 2:green, 3:blue)
    local sd = {
        "camshaft",
        "fuelpump",
        "oiltray" 
    }
    
    return sd
end
--




--
--- INIT
--

--- Setup the vision sensor and the trigger
function sensor_setup( )
    -- vision sensor
    vision = {
        sim.getObjectHandle( "color_sensor_slot_1" ),
        sim.getObjectHandle( "color_sensor_slot_2" ),
        sim.getObjectHandle( "color_sensor_slot_3" )
    }
    -- note that all the cameras have the same resolution
    img_resolution = sim.getVisionSensorResolution( vision[1] )
    detected = {
        "none",
        "none",
        "none"
    }
    
    -- trigger
    trigger = {
        sim.getObjectHandle( "color_sensor_slot_trigger_1" ),
        sim.getObjectHandle( "color_sensor_slot_trigger_2" ),
        sim.getObjectHandle( "color_sensor_slot_trigger_3" )
    }
    triggered = {
        false,
        false,
        false
    }
end
--

--- Update the shared state of the sensor
function sensor_update_shared( )
    local sensor_status = {
        { state = triggered[1], last_detection = detected[1] },
        { state = triggered[2], last_detection = detected[2] },
        { state = triggered[3], last_detection = detected[3] }
    }
    
    -- send the status of the sensor
    sim.writeCustomDataBlock( self, "OS_optic_sensor_slot_shared", 
        sim.packTable( sensor_status ) )
        
    -- DEBUG
    --[[
    sensor_status = sim.readCustomDataBlock( self, "OS_optic_sensor_slot_shared" )
    sensor_status = sim.unpackTable( sensor_status )
    print( "[sysCall_sensing@OS_optic_sensor] published:" )
    print( sensor_status )
    --]]
end
--

--- init function of the task OS_optic_sensor
function sysCall_init( )
    self = sim.getObjectHandle( sim.handle_self )
    
    -- setup the sensor
    sensor_setup( )
    
    -- setup the informations for the detection
    data = data_setup( )
    
    -- state publication
    sensor_update_shared( )
end
--




--
--- SENSING
--

--- Perception with one camera
function perform_perception( i )
    -- attempt to read the trigger
    local trigger_state = sim.readProximitySensor( trigger[i] )
    
    if trigger_state > 0 and not triggered[i] then
        triggered[i] = true
        
        -- get the image
        local frame = sim.getVisionSensorImage( vision[i] )
        
        -- compute the average color
        local avg_color = img_get_average_color_rgb( frame, img_resolution )
        
        -- detect the object depending on its average color
        local detection_idx = detect_color_3( avg_color )
        if detection_idx > 0 then
            -- get the object type
            detected[i] = data[ detection_idx ]
            
        else
            -- not a known type of object
            print( "[sysCall_sensing@OS_optic_sensor] (cam " .. i .. ") ERROR: not a kown color. " )
            print( "[sysCall_sensing@OS_optic_sensor] (cam " .. i .. ") computed average: " )
            print( avg_color )
            print( "[sysCall_sensing@OS_optic_sensor] (cam " .. i .. ") returned -1" )
            
            detected[i] = "none"
        end
        
    elseif trigger_state < 1 and triggered[i] then
        triggered[i] = false
        detected[i] = "none"
        
    end
end
--

--- The body of the perception controller
function sysCall_sensing( )
    -- perform the sensing for each camera
    for i=1,3,1 do
        perform_perception( i )
    end
    
    -- then, publish the state
    sensor_update_shared( )
end