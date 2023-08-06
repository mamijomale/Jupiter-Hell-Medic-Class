register_blueprint "moreClasses_trait_enforcer"
{
	blueprint = "trait",
	text = {
		name   = "Enforcer",
		desc   = "PASSIVE SKILL - Melee combat with non melee weapons pushes enemies.",
		full   = "Can't shoot with too close range? Force them to keep their distance!\n\n{!LEVEL 1} - Melee combat while carrying a ranged weapon will push the target enemy if the location is free.\n{!LEVEL 2} - The enemy you've pushed will deal small damages to any entity occupying the position. Stun the enemy if pushed toward a wall.\n{!LEVEL 3} - Push the enemy two cells away.",
		abbr   = "Enf",
	},
	attributes = {
		level = 1,
	},
	callbacks = {
		on_activate = [=[
			function(self,entity)
				local lvl, s = gtk.upgrade_trait( entity, "moreClasses_trait_enforcer" )
			end
		]=],
		on_pre_command = [=[
			function ( self, entity, command, w )
				local level = f.attributes.level
				local weapon = w or self:get_weapon()
				local ranged = weapon and weapon.weapon and ( weapon.weapon.type ~= world:hash("melee") )
				if(ranged) then
					
				end
			
			end
		]=],
		on_post_command = [=[
			function ( self, entity, cmt, weapon, time )
				local level = f.attributes.level
			end
		]=],
	}
}

register_blueprint "moreClasses_perk_fastidious_upgrade"
{
	flags      = { EF_NOPICKUP }, 
	armor = {
	},
	attributes = {
		armor = {
			0,
			slash = 0,
			pierce = 0,
			plasma = 0,
		},
		dodge_max = 0,
		dodge_min = 0,
		dodge_value = 0,
	},
}

register_blueprint "moreClasses_trait_fastidious"
{
	blueprint = "trait",
	text = {
		name   = "Fastidious",
		desc   = "PASSIVE SKILL - Repair armor each new floor and evolve with your gear.",
		full   = "You can't help yourself, the equipment you've got should always be as perfect and efficient as the day it left the factory.\n\n{!LEVEL 1} - Entering a new level restore your armor parts by {!10%}. The weapons you carry receive {!+1} to a random stat every time you level up\n{!LEVEL 2} - Entering a new level restore your armor parts by {!20%}. Leveling refill all your magazines and upgrade {!1} random stat of your current armor parts\n{!LEVEL 3} - Entering a new level restore your armor parts by {!30%}. Leveling restore your armors to their full durability. Entering a level refill all your magazines.",
		abbr   = "Fsd",
	},
	attributes = {
		level = 1,
		player_level = 1,
	},
	callbacks = {
		on_level_up = [=[
			function(self,entity,from)
				
				local p_level = world:get_player().progression.level
				local f = entity:child("moreClasses_trait_fastidious")
				local fp_level = f.attributes.player_level
				
				if p_level ~= fp_level then 
					f.attributes.player_level = p_level
					
					local f_level = f.attributes.level
					
					local bonuses = {
						[world:hash("melee")] = {
							[0] = { name = "damage", val = 5,},
							[1] = { name = "swap_time", val = -0.05,},
							[2] = { name = "crit_damage", val = 5,},
							[3] = { name = "melee_guard", val = 5,},
							[4] = { name = "mod_capacity", val = 1,},
							[5] = { name = "blade", val = 1,},
							[6] = { name = "gib_factor", val = 1,},
						},
						[world:hash("auto")] = {
							[0] = { name = "reload_time", val = -0.10,},
							[1] = { name = "damage", val = 1,},
							[2] = { name = "clip_size", val = 2,},
							[3] = { name = "shots", val = 1,},
							[4] = { name = "crit_damage", val = 5,},
							[5] = { name = "mod_capacity", val = 1,},
							[6] = { name = "min_distance", val = -1,},
							[7] = { name = "opt_distance", val = 1,},
							[8] = { name = "max_distance", val = 1,},
							[9] = { name = "swap_time", val = -0.10,},
						},
						[world:hash("rotary")] = {
							[0] = { name = "reload_time", val = -0.10,},
							[1] = { name = "damage", val = 1,},
							[2] = { name = "clip_size", val = 2,},
							[3] = { name = "shots", val = 1,},
							[4] = { name = "crit_damage", val = 5,},
							[5] = { name = "mod_capacity", val = 1,},
							[6] = { name = "min_distance", val = -1,},
							[7] = { name = "opt_distance", val = 1,},
							[8] = { name = "max_distance", val = 1,},
							[9] = { name = "swap_time", val = -0.10,},
							[10] = { name = "shot_delay", val = -2,},
						},
						[world:hash("explosives")] = {
							[0] = { name = "reload_time", val = -0.10,},
							[1] = { name = "damage", val = 2,},
							[2] = { name = "clip_size", val = 1,},
							[3] = { name = "shots", val = 1,},
							[4] = { name = "crit_damage", val = 5,},
							[5] = { name = "mod_capacity", val = 1,},
							[6] = { name = "explosion", val = 1,},
							[7] = { name = "opt_distance", val = 1,},
							[8] = { name = "max_distance", val = 1,},
							[9] = { name = "swap_time", val = -0.10,},
							[10] = { name = "gib_factor", val = 1,},
						},
						[world:hash("pistols")] = {
							[0] = { name = "swap_time", val = -0.10,},
							[1] = { name = "damage", val = 2,},
							[2] = { name = "shots", val = 1,},
							[3] = { name = "clip_size", val = 2,},
							[4] = { name = "crit_damage", val = 5,},
							[5] = { name = "mod_capacity", val = 1,},
							[6] = { name = "opt_distance", val = 1,},
							[7] = { name = "max_distance", val = 1,},
							[8] = { name = "crit_chance", val = 5,},
						},
						[world:hash("semi")] = {
							[0] = { name = "reload_time", val = -0.10,},
							[1] = { name = "damage", val = 1,},
							[2] = { name = "crit_damage", val = 5,},
							[3] = { name = "clip_size", val = 2,},
							[4] = { name = "shots", val = 1,},
							[5] = { name = "mod_capacity", val = 1,},
							[6] = { name = "min_distance", val = -1,},
							[7] = { name = "opt_distance", val = 1,},
							[8] = { name = "max_distance", val = 1,},
							[9] = { name = "swap_time", val = -0.10,},
						},
						[world:hash("shotguns")] = {
							[0] = { name = "damage", val = 1,},
							[1] = { name = "shots", val = 1,},
							[2] = { name = "clip_size", val = 1,},
							[3] = { name = "crit_damage", val = 5,},
							[4] = { name = "spread", val = 1,},
							[5] = { name = "mod_capacity", val = 1,},
							[6] = { name = "opt_distance", val = 1,},
							[7] = { name = "max_distance", val = 1,},
							[8] = { name = "reload_time", val = -0.10,},
							[9] = { name = "swap_time", val = -0.10,},
						},
						[world:hash("smgs")] = {
							[0] = { name = "swap_time", val = -0.10,},
							[1] = { name = "reload_time", val = -0.10,},
							[2] = { name = "damage", val = 1,},
							[3] = { name = "shots", val = 1,},
							[4] = { name = "clip_size", val = 2,},
							[5] = { name = "crit_damage", val = 5,},
							[6] = { name = "shot_delay", val = -5,},
							[7] = { name = "opt_distance", val = 1,},
							[8] = { name = "max_distance", val = 1,},
						},
						["armor"] = {
							[0] = { name = "dodge_max", val = 5,},
							[1] = { name = "armor", val = 1,},
							[2] = { name = "armor", idx = "slash", val = 1,},
							[3] = { name = "armor", idx = "pierce", val = 1,},
							[4] = { name = "armor", idx = "plasma", val = 1,},
							[5] = { name = "health", val = 100,},
							[6] = { name = "mod_capacity", val = 1,},
						},
						["head"] = {
							[0] = { name = "mod_capacity", val = 1,},
							[1] = { name = "health", val = 100,},
							[2] = { name = "armor", val = 1,},
						},
					}
					
					local index = 0
					repeat 
						local w   = world:get_weapon( entity, index, true )
						if not w then break end
						
						local p = w:child("moreClasses_perk_fastidious_upgrade")
						if not p then
							p = generator.add_perk( w, "moreClasses_perk_fastidious_upgrade" )
						end
						
						local bonus_array = bonuses[w.weapon.group]
						local rng = math.random( #bonus_array )
						if p.attributes[bonus_array[rng].name] then
							p.attributes[bonus_array[rng].name] = p.attributes[bonus_array[rng].name] + bonus_array[rng].val
						else
							p.attributes[bonus_array[rng].name] = bonus_array[rng].val
						end
						
						if f_level > 1 then
							local clip_size  = w:attribute( "clip_size" )
							if w.clip and w.clip.count then
								w.clip.count = clip_size
							end
						end
						
						index = index + 1
					until false
					if f_level > 1 then
						for _,a in ipairs({"head","armor"}) do
							local armor_p = world:get_slot( entity, a )
							if armor_p then
								local p = armor_p:child("moreClasses_perk_fastidious_upgrade")
								if not p then
									p = generator.add_perk( armor_p, "moreClasses_perk_fastidious_upgrade" )
								end
								
								local rng = math.random( #bonuses[a] )
								if bonuses[a][rng].name == "armor" then
									local i = 1
									if bonuses[a][rng].idx then
										i = bonuses[a][rng].idx
									end

									if i == 1 then
										if p.attributes.armor then
											p.attributes.armor = bonuses[a][rng].val
										else
											p.attributes.armor = p.attributes.armor + bonuses[a][rng].val
										end
									elseif p.attributes[i] then
										p.attributes[i] = p.attributes[i] + bonuses[a][rng].val
									else
										p.attributes[i] = bonuses[a][rng].val
									end
								elseif bonuses[a][rng].name == "dodge_max" then
									if p.attributes.dodge_max then
										p.attributes.dodge_max = p.attributes.dodge_max + bonuses[a][rng].val
									else
										p.attributes.dodge_max = bonuses[a][rng].val
									end
									p.attributes.dodge_value = p.attributes.dodge_max
									p.attributes.dodge_min = p.attributes.dodge_max
								else
									if p.attributes[bonuses[a][rng].name] then
										p.attributes[bonuses[a][rng].name] = p.attributes[bonuses[a][rng].name] + bonuses[a][rng].val
									else
										p.attributes[bonuses[a][rng].name] = bonuses[a][rng].val
									end
								end
								if f_level == 3 then
									armor_p.health.current = armor_p:attribute( "health" )
								end
							end
						end
					end
				end
			end
		]=],
		on_activate = [=[
			function(self,entity)
				local lvl, s = gtk.upgrade_trait( entity, "moreClasses_trait_fastidious" )
				world:lua_callback( entity, "on_level_up", entity)
			end
		]=],
		on_post_command = [=[
			function ( self, entity, cmt, tgt, time )
				world:lua_callback( entity, "on_level_up", entity)
			end
		]=],
		on_enter_level = [=[
			function ( self, entity, reenter )
				if reenter then return end
				local f = entity:child("moreClasses_trait_fastidious")
				local fa = f.attributes
				local rf = false
				local amount = fa.level * 0.10
				
				local fixa   = core.repair_item( entity, "armor", amount )
				local fixh   = core.repair_item( entity, "head", amount )
				
				if fa.level == 3 then
					local index = 0
					repeat 
						local w   = world:get_weapon( entity, index, true )
						if not w then break end
						
						local clip_size  = w:attribute( "clip_size" )
						
						for c in ecs:children( w ) do
							if c.attributes then
								if c.attributes.clip_size then
									clip_size = clip_size + c.attributes.clip_size
								end
							end
						end
						
						if w.clip and w.clip.count then
							w.clip.count = clip_size	
							rf = true
						end
						
						
						index = index + 1
					until false
				end
				
				if fixa or fixh or rf then
					ui:spawn_fx( entity, "fx_armor", entity )
				end
				
			end
		]=],
	},
}