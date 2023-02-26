
helicopter.vector_up = vector.new(0, 1, 0)

function helicopter.get_hipotenuse_value(point1, point2)
    return math.sqrt((point1.x - point2.x) ^ 2 + (point1.y - point2.y) ^ 2 + (point1.z - point2.z) ^ 2)
end

--painting
function helicopter.paint(self, colstr)
    if colstr then
        self.color = colstr
        local l_textures = self.initial_properties.textures
        for _, texture in ipairs(l_textures) do
            local i,indx = texture:find('helicopter_painting.png')
            if indx then
                l_textures[_] = "helicopter_painting.png^[multiply:".. colstr
            end
            local i,indx = texture:find('helicopter_colective.png')
            if indx then
                l_textures[_] = "helicopter_colective.png^[multiply:".. colstr
            end
        end
	    self.object:set_properties({textures=l_textures})
    end
end

function helicopter.setText(self)
    local properties = self.object:get_properties()
    local formatted = string.format(
       "%.2f", self.hp_max
    )
    if properties then
        properties.infotext = "Nice helicopter of " .. self.owner .. ". Current hp: " .. formatted
        self.object:set_properties(properties)
    end
end

--returns 0 for old, 1 for new
function helicopter.detect_player_api(player)
    local player_proterties = player:get_properties()
    local mesh = "character.b3d"
    if player_proterties.mesh == mesh then
        local models = player_api.registered_models
        local character = models[mesh]
        if character then
            if character.animations.sit.eye_height then
                return 1
            else
                return 0
            end
        end
    end

    return 0
end

-- attach player
function helicopter.attach(self, player)
    local name = player:get_player_name()
    self.driver_name = name

    -- sound and animation
    self.sound_handle = minetest.sound_play({name = "helicopter_motor"},
            {object = self.object, gain = 2.0, max_hear_distance = 32, loop = true,})
    self.object:set_animation_frame_speed(60)


    -- attach the driver
    player:set_attach(self.pilot_seat_base, "", {x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
    if helicopter.detect_player_api(player) == 0 then
        player:set_eye_offset({x = 0, y = -4, z = 1}, {x = 0, y = 8, z = -30})
    else
        player:set_eye_offset({x = 0, y = 2, z = 1}, {x = 0, y = 8, z = -30})
    end
    player_api.player_attached[name] = true
    player_api.set_animation(player, "sit")
    -- make the driver sit
    minetest.after(0.2, function()
        local player = minetest.get_player_by_name(name)
        if player then
	        --player_api.set_animation(player, "sit")
            player:set_animation({x =  81, y = 160},30, 0, true)
            update_heli_hud(player)
        end
    end)
    -- disable gravity
    self.object:set_acceleration(vector.new())
end

-- dettach player
function helicopter.dettach(self, player)
    local name = self.driver_name
    helicopter.setText(self)

    -- driver clicked the object => driver gets off the vehicle
    self.driver_name = nil

    -- sound and animation
    if self.sound_handle then
        minetest.sound_stop(self.sound_handle)
        self.sound_handle = nil
    end
    
    self.object:set_animation_frame_speed(0)

    -- detach the player
    player:set_detach()
    player_api.player_attached[name] = nil
    player:set_eye_offset({x=0,y=0,z=0},{x=0,y=0,z=0})
    player_api.set_animation(player, "stand")
    self.object:set_acceleration(vector.multiply(helicopter.vector_up, -helicopter.gravity))

    --remove hud
    if player then remove_heli_hud(player) end
end

-- attach passenger
function helicopter.attach_pax(self, player)
    local name = player:get_player_name()
    self._passenger = name
    -- attach the passenger
    player:set_attach(self.passenger_seat_base, "", {x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
    if helicopter.detect_player_api(player) == 0 then
        player:set_eye_offset({x = 0, y = -4, z = 1}, {x = 0, y = 8, z = -5})
    else
        player:set_eye_offset({x = 0, y = 2, z = 1}, {x = 0, y = 8, z = -5})
    end
    player_api.player_attached[name] = true
    player_api.set_animation(player, "sit")
    -- make the driver sit
    minetest.after(0.2, function()
        local player = minetest.get_player_by_name(name)
        if player then
            player:set_animation({x =  81, y = 160},30, 0, true)
        end
    end)
end

-- dettach passenger
function helicopter.dettach_pax(self, player)
    local name = self._passenger

    -- passenger clicked the object => driver gets off the vehicle
    self._passenger = nil

    -- detach the player
    if player then
        player:set_detach()
        player_api.player_attached[name] = nil
        player:set_eye_offset({x=0,y=0,z=0},{x=0,y=0,z=0})
        player_api.set_animation(player, "stand")
    end
end

-- destroy the helicopter
function helicopter.destroy(self, puncher)
    if self.sound_handle then
        minetest.sound_stop(self.sound_handle)
        self.sound_handle = nil
    end

    if self.driver_name then
        local driver = minetest.get_player_by_name(self.driver_name)
        helicopter.dettach(self, driver)
    end

    if self._passenger then
        local passenger = minetest.get_player_by_name(self._passenger)
        helicopter.dettach_pax(self, passenger)
    end

    local pos = self.object:get_pos()
    if self.pointer then self.pointer:remove() end
    if self.pilot_seat_base then self.pilot_seat_base:remove() end
    if self.passenger_seat_base then self.passenger_seat_base:remove() end

    self.object:remove()

    pos.y=pos.y+2
    for i=1,8 do
	    minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'default:steel_ingot')
    end

    for i=1,7 do
	    minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'default:diamond')
    end

    for i=1,7 do
	    minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'default:mese_crystal')
    end

    minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'default:steelblock')
    minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'default:copperblock')
    minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'nss_helicopter:blades')
end

function helicopter.isAreaProtectedBy(self, player)
    local name = player:get_player_name()
    local pos = self.object:get_pos()

    if minetest.get_modpath("areas") then
        local area_owners = areas:getNodeOwners(pos)
        for _, value in pairs(area_owners) do
            if value == name then
                return true
            end
        end
    end

    if minetest.get_modpath("protector") then
        -- use improvised find_nodes check
        local protector_radius = tonumber(minetest.settings:get("protector_radius")) or 5
        -- find the protector nodes
        local protector_pos = minetest.find_nodes_in_area(
            {x = pos.x - r, y = pos.y - r, z = pos.z - r},
            {x = pos.x + r, y = pos.y + r, z = pos.z + r},
            {"protector:protect", "protector:protect2", "protector:protect_hidden"})
        for n = 1, #protector_pos do
            local meta = minetest.get_meta(protector_pos[n])
            local owner = meta:get_string("owner") or ""
            if owner == name then
                return true
            end
        end
    end
    return false
end
