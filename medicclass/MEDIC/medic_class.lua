register_blueprint "moreClasses_orb_resource_blood_pouch"
{
	flags = { EF_ITEM, EF_POWERUP }, 
	text = {
		name = "blood pouch",
		desc = "Fresh blood for your veins!",
	},
	ascii     = {
		glyph     = "*",
		color     = RED,
	},
	attributes = {
		amount = 2,
	},
	callbacks = {
		on_enter = [=[
			function( self, entity )
				local blood = entity:child("moreClasses_resource_blood_pouch")
				if blood then
					world:play_sound( "armor_shard", entity )
					local attr   = blood.attributes
					local value  = attr.value
					local amount = self.attributes.amount
					
					local bonus  = entity:attribute("blood_bonus") 
					
					attr.value   = value + amount + bonus
					world:lua_callback( entity, "on_moreClasses_resource_blood_pouch", amount + bonus )
					return 1 -- destroy
				end
				return 0
			end
		]=],
	},

}

register_blueprint "moreClasses_resource_blood_pouch"
{
	flags = { EF_NOPICKUP }, 
	text = {
		name   = "Blood Pouch",
		desc   = "PASSIVE SKILL - Medic resource",
		full   = "INTERNAL!",
		abbr   = "Blood",
	},
	attributes = {
		value = 40,
		max   = 40,
	},
	resource = {
		color    = RED,
		overflow = ORANGE,
		block_size = 5,
	},
	callbacks = {
		on_kill = [=[
			function ( self, entity, target, weapon )
				if target then
					if target.data and target.data.ai and target.flags then
						local flags  = target.flags
						local amount = 0
						local eattr = entity.attributes
						if flags.data[ EF_TARGETABLE ] and target.data then
							if not target.data.is_mechanical then
								if target.data.ai.group == "zombie" or target.data.ai.group == "cri" then
									amount = 2
									if target.data.is_semimechanical then
										amount = 1
									end

									amount = (amount + (eattr.temp_blood_bonus or 0)) * (eattr.blood_coef or 1)
									eattr.temp_blood_bonus = 0
									eattr.blood_coef = 1.0
									
									if amount > 0 then
										local orb = world:get_level():add_entity( "moreClasses_orb_resource_blood_pouch", target:get_position() )
										orb.attributes.amount = amount
									end
								end
							end
						end
					end
				end
			end
		]=],
		on_enter_level = [=[
			function ( self, entity )
				local attr   = self.attributes
				local max    = attr.max
				if attr.value > max then
					attr.value = max
				end
			end
		]=],
	},
}

register_blueprint "moreClasses_ktrait_medical_stash"
{
	blueprint = "trait",
	text = {
		name   = "Medical Stash",
		desc   = "5 Blood Pouches and a chance to loot one extra health item in every box",
		full   = "Anyone can get hurt anywhere so they have hidden additional medical {?cursed|shit|stuff} everywhere. Good thing you perfectly know where they are!\n\n{!LEVEL 1} - only medical boxes are affected\n{!LEVEL 2} - all boxes are affected\n{!LEVEL 3} - every fourth chest has an instant health orb drop",
		abbr   = "Med",
	},
	attributes = {
		level   = 1,
		counter = 0,
	},
	callbacks = {
		on_activate = [=[
			function(self,entity)
				gtk.upgrade_trait( entity, "moreClasses_ktrait_medical_stash" )
			end
		]=],
		on_lootbox_open = [=[
			function(self,who,what)
				local sattr  = self.attributes
				local tlevel = sattr.level
				if tlevel == 1 then
					if world:get_id( what ) ~= "lootbox_medical_small"  then
						if world:get_id( what ) ~= "lootbox_medical"  then
							return
						end
					end
				end
				local blood = who:child("moreClasses_resource_blood_pouch")
				if blood then
					local battr = blood.attributes
					local value = battr.value
					battr.value = value + 5
				end
				local rng = math.random(100)
				local info = world:get_level().level_info
				local linfo  = world.data.level[ world.data.current ]
				if rng <= 25 then
					what:attach( core.lists.item.medical:roll( info.ilevel, linfo.item_mod ))
				end
				if tlevel == 3 then
					sattr.counter = sattr.counter + 1
					if sattr.counter == 4 then
						sattr.counter = 0
						
						what:attach( core.lists.item.orb:roll( info.ilevel, linfo.item_mod ))
					end
				end
			end
		]=],
	},
}


register_blueprint "moreClasses_ktrait_skilled_medic"
{
	blueprint = "trait",
	text = {
		name   = "Skilled",
		desc   = "PASSIVE SKILL - improve your class traits",
		full   = "You're great at what you are. First aids occurs at higher health percents, you can carry more blood pouches and restore more health from the field rescue.\n\n{!LEVEL 1} First Aids below {!25%} and {+20} on blood pouches limit. - \n{!LEVEL 2} First Aids below {!35%}, Field Rescue restore {!15} health and {+20} on blood pouches limit. - \n{!LEVEL 3} - First Aids below {!45%}, Field Rescue restore {!20} health, you only need {!2} small medkits to make a large one and {+20} on blood pouches limit.",
		abbr   = "Skl",
	},
	callbacks = {
		on_activate = [=[
			function(self,entity)
				local attr  = entity.attributes
				local level = ( attr.skilled_bonus or 0 ) + 1
				attr.first_aids_bonus = level
				attr.skilled_bonus = level
				
				local blood = entity:child( "moreClasses_resource_blood_pouch" )
				local battr = blood.attributes
				battr.max   = battr.max + 20
				
				if level > 1 then
					attr.field_healing_bonus = level
				end
				if level > 2 then
					attr.medkit_amount_discount = 1
				end
			end
		]=],
	},
}

register_blueprint "moreClasses_ktrait_first_aids"
{
	blueprint = "trait",
	text = {
		name   = "First Aids",
		desc   = "PASSIVE SKILL - waiting heals you when your health is below 15%",
		full   = "INTERNAL!",
		abbr   = "FA",
	},
	attributes = {
		first_aids_conditions = 0,
		first_aids_heal_bonus = 0,
	},
	callbacks = {
		on_activate = [=[
			function(self,entity)
				entity:attach( "moreClasses_ktrait_first_aids" )
			end
		]=],
		
		on_pre_command = [[
			function ( self, entity, command, weapon )
				local sattr = self.attributes
				local conditions = (sattr.first_aids_conditions or 0)
				local valid = 0
				
				if command == COMMAND_WAIT then
					valid = 1
				elseif command == COMMAND_MOVE and conditions == 1 then
					valid = 1
				elseif conditions > 1 then
					valid = 1
				end
				
				if valid > 0 then 
					local hc = entity.health.current
					local max = entity.attributes.health
					local modifier = entity:attribute("first_aids_bonus")
					local modifier2 = (sattr.first_aids_heal_bonus or 0)
					if hc < (max * (0.15 + modifier * 0.1)) then
						entity.health.current = entity.health.current + 1 + modifier2
						world:lua_callback( entity, "on_first_aids", 1 + modifier2 )
					end
				end
			end
		]],

	},
}

register_blueprint "moreClasses_ktrait_field_healing"
{
	blueprint = "trait",
	text = {
		name   = "Field rescue",
		desc   = "ACTIVE SKILL - consume some blood to regain health",
		full   = "You can performe surgery in the worst places to save lives. Today it's only yours, and your best tool is the blood of your enemies.",
		abbr   = "FR",
		cant_use = "You are too healthy to use such ability.",
	},
	attributes = {},
	callbacks = {
		on_activate = [=[
			function(self,entity)
				entity:attach( "moreClasses_ktrait_field_healing" )
			end
		]=],
		on_use = [=[
			function ( self, entity, level, target )
				local attr = entity.attributes
				local hp = entity.health.current
				world:play_sound( "medkit_large", entity )
				if hp >= (attr.health + 40) then 
					ui:set_hint( self.text.cant_use, 50, 1 )
					return -1
				end
				world:play_sound( "medkit_large", entity )
				
				local blood = entity:child("moreClasses_resource_blood_pouch")
				if blood then
					local battr = blood.attributes
					local value = battr.value
					local pouch_price = math.min(10,value)
					local fhb = entity:attribute("field_healing_bonus")
					local coef  = (fhb * 5 + 10) / 10
					
					battr.value = math.max(0,value + 1 - pouch_price)
					entity.health.current = math.min(hp + math.ceil(pouch_price * coef),attr.health + 40)
				end
				return 1
			end
		]=],
	},
	skill = {
		resource = "moreClasses_resource_blood_pouch",
		fail_vo  = "vo_cooldown",
		cost     = 1,
		cooldown = 50,
	},
}

register_blueprint "moreClasses_ktrait_med_assemble"
{
	blueprint = "trait",
	text = {
		name   = "Sorting medicine",
		desc   = "ACTIVE SKILL - mix and select lesser medications from 3 small medkits to create 1 large medkit",
		full   = "They all think that medkits used by civilians are different from those use by the military. They are all {?cursed|fucking|foolish} ignorants : it's just a question of dose and ability to read the {?curse|god damned|useful} instructions!",
		abbr   = "MC",
		cant_use = "Not enough small medkits to assemble",
		used = "Medkits successfully assembled",
	},
	attributes = {},
	callbacks = {
		on_activate = [=[
			function(self,entity)
				entity:attach( "moreClasses_ktrait_med_assemble" )
			end
		]=],
		on_use = [=[
			function(self,entity,level, target)
				local medkit_amount = 3 - entity:attribute("medkit_amount_discount")
				if world:has_item( entity, "medkit_small" ) < medkit_amount then 
					ui:set_hint( self.text.cant_use, 50, 1 )
					--entity:pickup( "medkit_small", true )
					return -1 
				end
				ui:set_hint( self.text.used, 50, 1 )
				world:play_sound( "medkit_large", entity )
				local am = world:remove_items( entity, "medkit_small", 10000 )

				entity:pickup( "medkit_large", true )
				
				for i=1,(am - medkit_amount) do
					entity:pickup( "medkit_small", true )
				end
				
				return 100
			end
		]=],
	},
	skill = {
		cooldown     = 0,
		cost    	 = 0,
	},
}


register_blueprint "moreClasses_ktrait_harvester"
{
	blueprint = "trait",
	text = {
		name   = "Harvester",
		desc   = "Collect more blood from enemies. Even more with melee attacks. Also more if they're bleeding.",
		full   = "Blood for the god of blood! Make your enemies dry the precious scarlet gold out of their veins for your own needs.\n\n{!LEVEL 1} - Enemies drop {!+1} blood pouches, {!twice} more if they were killed by a melee attack and drop {!+1} extra blood pouch if they died with the bleeding affliction. \n{!LEVEL 2} - {!+1} blood pouch on organic enemies death, your ranged weapons have {!30%} chance to inflict bleeding on the target. \n{!LEVEL 3} - {!+1} blood pouch on organic enemies death, your ranged weapons have {!50%} chance to inflict bleeding on the target.",
		abbr   = "HAR",
	},
	attributes = {

	},
	callbacks = {
		on_activate = [=[
			function(self,entity)
				entity:attach( "moreClasses_ktrait_harvester" )
				local eattr = entity.attributes
				eattr.blood_bonus = (eattr.blood_bonus or 0) + 1
			end
		]=],
		on_kill = [[
			function ( self, entity, target, weapon )
				if target then
					if target.data and target.data.ai then
						local eattr = entity.attributes
						if weapon and weapon.weapon then
							if ( weapon.weapon.group == world:hash("melee") ) then 
								eattr.blood_coef = 2.0
							end
						end
						if target:child("bleed") then
							eattr.temp_blood_bonus = 1
						end
					end
				end
			end
		]],
	},
}

register_blueprint "moreClasses_ktrait_phd"
{
	blueprint = "trait",
	text = {
		name   = "PhD",
		desc   = "Increase the size of health items stacks.",
		full   = "Holy {?cursed|fuck|moly}! You're so smart you're sure that half of the tools in the kits are just useless and bulky {?cursed|shit|junk} for rookies. Toss these to carry more!\n\n{!LEVEL 1} - Can stack {!+2} small medkit and {!+1} large medkit\n{!LEVEL 2} - Can stack {!+1} small medkit, {!+2} small stimpack, and {!+1} large medkit\n{!LEVEL 3} - Can stack {!+1} large medkit and {!+1} large stimpack",
		abbr   = "PhD",
	},
	attributes = {
		level = 1,
	},
	callbacks = {
		on_activate = [=[
			function(self,entity)
				local tlevel, phd = gtk.upgrade_trait( entity, "moreClasses_ktrait_phd" )

				local st = {
					[1] = {
							["medkit_small"]     = { id = "medkit_small",     max = 5, },
							["medkit_large"]     = { id = "medkit_large",     max = 2, },
						},
					[2] = {
							["medkit_small"]     = { id = "medkit_small",     max = 6, },
							["medkit_large"]     = { id = "medkit_large",     max = 3, },
							["stimpack_small"]   = { id = "stimpack_small",   max = 5, },
						},
					[3] = {
							["stimpack_small"]   = { id = "stimpack_small",   max = 5, },
							["stimpack_large"]   = { id = "stimpack_large",   max = 2, },
							["medkit_small"]     = { id = "medkit_small",     max = 6, },
							["medkit_large"]     = { id = "medkit_large",     max = 4, },
						},
				}
				local max = st[phd.attributes.level]
				
				for k,data in pairs(max) do
					local count = world:remove_items( entity, k, 1000 )
					if count > 0 then
						for _=1,count do 
							local e = world:create_entity( k )
							if not e.stack then e.stack = {} end
							e.stack.max = data.max
							e.stack.amount = 1
							entity:pickup( e, true )
						end
					end
				end
			end
		]=],
		
		on_pickup = [=[
			function ( self, user, item )
				local id    = world:get_id( item )
				local phd = user:child("moreClasses_ktrait_phd")
				local st = {
					[1] = {
							["medkit_small"]     = { id = "medkit_small",     max = 5, },
							["medkit_large"]     = { id = "medkit_large",     max = 2, },
						},
					[2] = {
							["medkit_small"]     = { id = "medkit_small",     max = 6, },
							["medkit_large"]     = { id = "medkit_large",     max = 3, },
							["stimpack_small"]   = { id = "stimpack_small",   max = 5, },
						},
					[3] = {
							["stimpack_small"]   = { id = "stimpack_small",   max = 5, },
							["stimpack_large"]   = { id = "stimpack_large",   max = 2, },
							["medkit_small"]     = { id = "medkit_small",     max = 6, },
							["medkit_large"]     = { id = "medkit_large",     max = 4, },
						},
				}
				local max_tab = st[phd.attributes.level]
				
				if max_tab[id] then
					local amount = 1
					local max = max_tab[id]["max"]
					if item.stack then 			
						amount = item.stack.amount
					end
					world:destroy(item)
					user:equip( id, { stack = { amount = amount, max = max_tab[id]["max"] } } )
				end
				return 0
			end
		]=],

	},
}

register_blueprint "moreClasses_ktrait_blood_saving"
{
	blueprint = "trait",
	text = {
		name   = "Blood saving",
		desc   = "ACTIVE SKILL - Converts your health into its equivalent amount of Blood Pouches.",
		full   = "What the {?cursed|hell|heck} will you do with that much health? Better save it for later since these {?cursed|fucking|silly} health items can't overheal!\n\n{!LEVEL 1} - Converts {!10} health into the equivalent of blood pouches. {+10} on blood pouches limit. \n{!LEVEL 2} - PASSIVE - Slash and Pierce damages have {!25%} chances to generate {!1} blood pouch. {+10} on blood pouches limit. ACTIVE - Saving your blood cure {!Bleeding} status \n{!LEVEL 3} - PASSIVE - Slash and Pierce damages have {!50%} chances to generate {!2} blood pouch. {+10} on blood pouches limit. - ACTIVE - Saving your blood cure {!Bleeding} and {!Toxin} status",
		abbr   = "BSv",
		cant_use = "FOOL! YOU WOULD DIE! Not enough blood!",
		used = "Health drained",
	},
	attributes = {
		level = 1,
	},
	callbacks = {
		on_activate = [=[
			function(self,entity)
				local tlevel,t = gtk.upgrade_trait( entity, "moreClasses_ktrait_blood_saving" )

				local blood = entity:child("moreClasses_resource_blood_pouch")
				local battr = blood.attributes
				battr.max   = battr.max + 10
			end
		]=],
		on_receive_damage = [=[
			function ( self, entity, source, weapon, amount )
				if self.attributes.level < 2 then return end
				if weapon then
					if weapon.damage_type then
						if weapon.damage_type == "slash" or weapon.damage_type == "pierce" then
							local blood = entity:child("moreClasses_resource_blood_pouch")
							local rng = math.random(100)
							if blood and rng < (25 * (self.attributes.level - 1)) then
								local battr = blood.attributes
								local value = battr.value
								battr.value = value + self.attributes.level - 1
							end
						end
					end
				end
			end
		]=],
		on_use = [=[
			function(self,entity,level, target)
				local eattr = entity.attributes
				local health = entity.health
				self.skill.cooldown = 100
				if health.current <= 1 then
					ui:set_hint( self.text.cant_use, 50, 1 )
					self.skill.cooldown = 0
					return -1
				end
				
				local blood = entity:child("moreClasses_resource_blood_pouch")
				if blood then
					local health_price = math.min(10,health.current)
					local attr  = entity.attributes
					local fhb = (attr.field_healing_bonus or 0)
					local coef  = 10 / math.max(10,fhb * 5 + 10)
					local battr = blood.attributes
					local value = battr.value
					battr.value = value + math.ceil(health_price * coef)
					health.current = health.current - health_price
					ui:set_hint( health_price.." "..self.text.used, 50, 1 )
				end
				if self.attributes.level > 1 then
					world:destroy(entity:child("bleed"))
					if self.attributes.level > 2 then
						world:destroy(entity:child("toxin"))
					end
				end
				return 1
			end
		]=],
	},
	skill = {
		cooldown     = 100,
		cost    	 = 0,
	},
}


register_blueprint "moreClasses_kbuff_healthy"
{
	flags = { EF_NOPICKUP }, 
	text = {
		name = "Fit",
		desc = "grants damage and speed bonus",
	},
	ui_buff = {
		color = LIGHTGREEN,
	},
	attributes = {
		move_time       = 0.8,
		damage_mult = 1.2,
	},
}


register_blueprint "moreClasses_fit"
{
	flags = { EF_NOPICKUP }, 
	text = {
		name      = "Fit",
		killed_by = "excessive sane lifestyle (lmao NOOB!)",
		sname     = "fit",
		desc      = "Permanent buff as long as you are full health.",
		edesc     = "Permanent buff as long as you are full health.",
	},
	source = {},
	callbacks = {
		on_timer = [[
			function ( self, first )
				if first then return 99 end
				local attr   = self.attributes
				local target = ecs:parent( self )
				if target and target.data then
					local tattr = target.attributes
					
					if target.health.current < tattr.health then
						world:mark_destroy( self )
						return 0
					end
				end
				return 100
			end
		]],
		on_die = [[
			function ( self )
				world:mark_destroy( self )
			end
		]],
	},
	attributes = {
		amount = 0,
		move_time = 0.7,
		damage_mult = 1.3,
	},
	ui_buff = {
		color     = GREEN,
		style     = 3,
		attribute = "amount",
	},
}

register_blueprint "moreClasses_ktrait_master_an_apple_a_day"
{
	blueprint = "trait",
	text = {
		name   = "AN APPLE A DAY",
		desc   = "MASTER TRAIT - You will receive extra health bonus with some speed and damage buffs if you reach an elevator full health.",
		full   = "Your lifestyle is so healthy! Resting in an elevator with no scratch is enough to make you a true devil in shape. \n\n{!LEVEL 1} - Overheal bonus equal to {!25%} of max health, temporary damage bonus of {!50%}. Increase move speed by {!20%}.  \n{!LEVEL 2} - Overheal bonus equal to {!75%} of max health. Temporary damage bonus of {!50%}. Increase move speed by {!30%}. \n{!LEVEL 3} - Overheal bonus equal to {!100%} of max health. Extra damage and move speed bonus of {!30%} when full health or above. \nYou can pick only one MASTER trait per character.",
		abbr   = "MAD",
	},
	attributes = {
		level    = 1,
		health_bonus = 25,
		speed_bonus = 0.8,
		damage_bonus = 1.2,
		damage_mult  = 1.0,
		speed       = 1.0,
	},
	callbacks = {
		on_activate = [=[
			function(self,entity)
				local tlevel,t = gtk.upgrade_master( entity, "moreClasses_ktrait_master_an_apple_a_day" )
				local tattr = t.attributes
				if tlevel == 2 then
					tattr.speed_bonus = 0.7
					tattr.damage_bonus = 1.5
				end
				if tlevel > 2 and not entity:child("moreClasses_fit") then
					local eattr = entity.attributes
					if entity.health <= eattr.health.current then
						core.apply_damage_status( entity, "moreClasses_fit", "moreClasses_fit", 1, entity )
					end
				end
				tattr.health_bonus = 25 * tlevel
			end
		]=],
		on_enter_level = [=[
			function(self,entity,reenter)
				if reenter then return end
				local sattr = self.attributes
				local tlevel = sattr.level
				local eattr = entity.attributes
				if eattr.health <= entity.health.current then
					world:add_buff(entity,"moreClasses_kbuff_healthy",12000)
					local healthy = entity:child("moreClasses_kbuff_healthy")
					healthy.attributes.move_time = sattr.speed_bonus
					healthy.attributes.damage_mult = sattr.damage_bonus
					
					if tlevel == 3 and not entity:child("moreClasses_fit") then
						core.apply_damage_status( entity, "moreClasses_fit", "moreClasses_fit", 1, entity )
					end
				
					entity.health.current = entity.health.current + sattr.health_bonus
				end
			end
		]=],
		
		on_receive_damage = [[
			function ( self, entity, source, weapon, amount )
				local sattr = self.attributes
				local tlevel = sattr.level
				if tlevel == 3 then
					if not entity then return 0 end
					local eh  = entity.health
					local emh  = entity.attributes.health
					if eh.current < emh and entity:child("moreClasses_fit") then
						world:mark_destroy(entity:child("moreClasses_fit"))
					end
				end
				return 1
			end
		]],
		
		on_post_command = [[
			function ( self, actor, cmt, weapon, time )
				if time <= 1 then return end
				local sattr = self.attributes
				local tlevel = sattr.level
				if tlevel == 3 then
					if not actor then return 0 end
					local eh  = actor.health
					local emh  = actor.attributes.health
					if eh.current >= emh and not actor:child("moreClasses_fit") then
						core.apply_damage_status( actor, "moreClasses_fit", "moreClasses_fit", 1, actor )
					end
				end
				return 1
			end
		]],

	},
}

register_blueprint "moreClasses_ktrait_master_keep_the_doctor_away"
{
	blueprint = "trait",
	text = {
		name   = "KEEP THE DR AWAY",
		desc   = "MASTER TRAIT - Improve the First Aids skill with a better healing, cover bonus and new conditions.",
		full   = "An average medic uses first aids to save endangered lives until they reach safety. You can't afford doing this for you own life thus you will treat these {?cursed|fucking|annoying} wounds as soon as you received them!\n\n{!LEVEL 1} - First Aids heals {!2} health and grants you a {!+50%} dodge bonus if you wait \n{!LEVEL 2} - First Aids heals {!4} health and is active when you are moving or waiting.\n{!LEVEL 3} - First Aids heals {!6} health and is active no matter your action.\nYou can pick only one MASTER trait per character.",
		abbr   = "MDA",
	},
	attributes = {
		level    = 1,
	},
	callbacks = {
		on_activate = [=[
			function(self,entity)
				local tlevel, t = gtk.upgrade_master( entity, "moreClasses_ktrait_master_keep_the_doctor_away" )
				local aids = entity:child("moreClasses_ktrait_first_aids")
				if aids then
					local tattr = aids.attributes
					tattr.first_aids_conditions = tattr.first_aids_conditions + 1
					tattr.first_aids_heal_bonus = (tlevel * 2) - 1
				end
			end
		]=],
		
		on_first_aids = [=[
			function(self,actor,amount)
				local FA = actor:child("moreClasses_ktrait_first_aids")
				if FA then
					local hunker = actor:child("hunker")
					if hunker then
						hunker.attributes.cover_mod = 50
					end
				end
			end
		]=],

	},
}


register_blueprint "moreClasses_virus"
{
	flags = { EF_NOPICKUP }, 
	text = {
		name      = "Infected",
		killed_by = "mortal virus",
		sname     = "moreClasses_virus",
		desc      = "every {!1} seconds does {!internal} damage, prevents regeneration effects",
		edesc     = "every {!1} seconds does {!internal} damage and reduce speed by {!20} percent, prevents regeneration effects",
	},
	source = {},
	callbacks = {
		on_timer = [[
			function ( self, first )
				if first then return 1 end
				local attr   = self.attributes
				local target = ecs:parent( self )
				local p = world:get_player()
				if target == p then
					world:mark_destroy( self )
					return 0
				end
				if target and target.data and not target.data.is_mechanical then
					local slevel = attr.amount
					if slevel > 1 then
						self.attributes.speed = 0.8
					end
					world:get_level():apply_damage( self, target, 5 * math.max(1,(slevel - 1)),  ivec2(), "internal" )
					
					
					local targets = {}
					local level   = world:get_level()
					local ill	  = world:get_position( target )
					for b in level:targets( target, 2 ) do 
						local diff  = world:get_position( b ) - ill
						local range = 2
						if b.size then range = b.size.size + 1 end
						local eligible = 0
						if b.data and not b.data.is_mechanical and p~=b then
							eligible = 1
						end
						
						if math.abs( diff.x ) < range and math.abs( diff.y ) < range and eligible then
							table.insert( targets, b )
						end
					end
					if #targets > 0 then
						for _,v in pairs(targets) do
							local rng = math.random( 100 )
							if rng < (50 * math.ceil(slevel * 0.5)) and not v:child("moreClasses_virus") and v.health  then
								core.apply_damage_status( v, "moreClasses_virus", "moreClasses_virus", slevel, world:get_player() )
							end
						end
					end
					if target.health then
						if target.health.current == -1000 then
							world:mark_destroy( self )
						end
						if target.health.current <= 0 then
							target.health.current = -1000
						end
					end
				end
				return 100
			end
		]],
		on_die = [[
			function ( self )
				world:mark_destroy( self )
			end
		]],
	},
	attributes = {
		amount = 0,
	},
	ui_buff = {
		color     = RED,
		style     = 3,
		attribute = "amount",
	},
}


register_blueprint "moreClasses_kperk_virus"
{
	flags = { EF_NOPICKUP }, 
	callbacks = {
		on_area_damage = [[
			function ( self, weapon, level, c, damage, distance, center, source, is_repeat )
				if not is_repeat then
					for e in level:entities( c ) do
						local p = world:get_player()
						if e.data and not e.data.is_mechanical and p~=e then
							local infection_rate = p:attribute("infection_rate")
							local chance  = math.min(50,infection_rate)
							if weapon and weapon.weapon then
								if ( weapon.weapon.group == world:hash("melee") ) then 
									chance = 100
								end
							end
							local rng = math.random(100)
							if rng <= chance then
								if e:child("moreClasses_virus") then
									world:mark_destroy(e:child("moreClasses_virus"))
								end
								local slevel = infection_rate *0.04
								core.apply_damage_status( e, "moreClasses_virus", "moreClasses_virus", slevel, world:get_player() )
							end
						end
					end
				end
			end
		]],
	},
}

register_blueprint "moreClasses_ktrait_master_plague_doctor"
{
	blueprint = "trait",
	text = {
		name   = "PLAGUE DOCTOR",
		desc   = "MASTER TRAIT - Spread a disease with your bullets or melee weapons to slowly kill non-mechanical hostiles.",
		full   = "...and that is how you lost your medical license! You are a maniac spreading death from his evil genius! Test these {?cursed|bastards|bad guys}' immunity by spreading a deadly virus! \n\n{!LEVEL 1} -  {!25%} chances to infect by Ranged attacks. {!100%} chances to infect by Melee Attack. Infected have {!50%} chances to spread to virus. \n{!LEVEL 2} - {!50%} chances to infect by Ranged attacks. {!50%} to infect enemies attacking you with melee attacks. Infected's speed reduced by {!20%}.  \n{!LEVEL 3} - {!100%} chances to spread. Virus deals {!twice} more damages. \nYou can pick only one MASTER trait per character.",
		abbr   = "MPD",
	},
	attributes = {
		level    = 1,
	},
	callbacks = {
		on_activate = [=[
			function(self,entity)
				local tlevel, t = gtk.upgrade_master( entity, "moreClasses_ktrait_master_plague_doctor" )

				entity.attributes.infection_rate = 25 * tlevel
				local index = 0
				repeat 
					local w   = world:get_weapon( entity, index, true )
					if not w then break end
					local vir = w:child("moreClasses_kperk_virus")
					if not vir then
						w:attach("moreClasses_kperk_virus")
					end
					index = index + 1
				until false
			end
		]=],
		on_pickup = [=[
			function ( self, user, w )
				if w and w.weapon and ( not w.stack ) then
					local vir = w:child("moreClasses_kperk_virus")
					if not vir then
						w:attach("moreClasses_kperk_virus")
					end
				end
			end
		]=],
		on_receive_damage = [[
			function ( self, entity, source, weapon, amount )
				if not source then return end
				if weapon and weapon.weapon and source ~= world:get_player() then
					local rng = math.random(100)
					if rng <= 50 then
						core.apply_damage_status( source, "moreClasses_virus", "moreClasses_virus", self.attributes.level, world:get_player() )
					end
				end
			end
		]],

	},
}


register_blueprint "moreClasses_kbuff_demon_blood"
{
    flags = { EF_NOPICKUP }, 
    text = {
		name  = "Demonblood",
		desc  = "Demon blood flows through your veins.\n\n Unexpected effects.",
		bdesc = "demon blood flows through your veins (unexpected effects)",
    },
	ui_buff = {
		color = LIGHTRED,
		style = 2,
	},
	attributes = {
		pain_reduction = 0,
		
		crit_chance = 0,
		crit_damage = 0,
		evasion = 0,
		cover_mod = 0,
		aim_mod   = 0,
		accuracy = 0,
		
		pain_factor = 1.0,
		move_time  = 1.0,
		use_time = 1.0,
		
		speed  = 1.0,
		medkit_mod  = 1.0,
		damage_mod = 1.0,
		damage_mult = 1.0,
		resist = {
			bleed   = 0,
			toxin   = 0,
			cold   = 0,
			acid   = 0,
			ignite   = 0,
			internal   = 0,
		},
	},
	callbacks = {
		on_enter_level = [[
			function(self,entity,reenter)
				world:mark_destroy(self)
			end
		]],
	},
}


register_blueprint "moreClasses_orb_resource_demon_blood_pouch"
{
	flags = { EF_ITEM, EF_POWERUP }, 
	text = {
		name = "demon blood pouch",
		desc = "Fresh demonic blood for your veins!",
		edesc = "Fresh demonic blood for your veins!",
	},
	ascii     = {
		glyph     = "*",
		color     = LIGHTRED,
	},
	attributes = {
		amount = 3,
		buff_amount = 1,
		buff_turns = 5,
		buff_chance = 25,
	},
	callbacks = {
		on_enter = [=[
			function( self, entity )
				local blood = entity:child("moreClasses_resource_blood_pouch")
				if blood then
					world:play_sound( "armor_shard", entity )
					local attr   = blood.attributes
					local value  = attr.value
					local amount = self.attributes.amount
					
					local bonus  = entity:attribute("blood_bonus") 
					
					attr.value   = value + amount + bonus
					world:lua_callback( entity, "on_moreClasses_resource_blood_pouch", amount + bonus )
					
					local rng = math.random(100)

					if rng <= self.attributes.buff_chance then
						world:add_buff(entity,"moreClasses_kbuff_demon_blood",self.attributes.buff_turns*200)
						local demon_buff = entity:child("moreClasses_kbuff_demon_blood")
						local dbattr = demon_buff.attributes
					
						local buffs = self.attributes.buff_amount
						world:play_sound( "medkit_large", entity )
						
						local bonus_tab = {
							[0] = {name = "pain_reduction", factor = -1, str = "pain reduction"},
							[1] = {name = "crit_chance", str = "critical chance"},
							[2] = {name = "crit_damage", str = "critical damage"},
							[3] = {name = "evasion", str = "evasion"},
							[4] = {name = "cover_mod", str = "coverage"},
							[5] = {name = "aim_mod", str = "aim bonus"},
							[6] = {name = "accuracy", str = "accuracy"},
							[7] = {name = "pain_factor", factor = 0.01, str = "percent pain reduction"},
							[8] = {name = "move_time", factor = 0.01, str = "move speed"},
							[9] = {name = "use_time", factor = 0.01, str = "item use speed"},
							[10] = {name = "speed", factor = 0.01, reverse = true, str = "speed"},
							[11] = {name = "medkit_mod", factor = 0.01, reverse = true, str = "medkit use speed"},
							[12] = {name = "damage_mod", factor = 0.01, reverse = true, str = "damage bonus"},
							[13] = {name = "damage_mult", factor = 0.01, reverse = true, str = "percent damage"},
							[14] = {name = "bleed", is_resistance = true, str = "bleeding resistance"},
							[15] = {name = "toxin", is_resistance = true, str = "poison resistance"},
							[16] = {name = "cold", is_resistance = true, str = "cold resistance"},
							[17] = {name = "ignite", is_resistance = true, str = "fire resistance"},
							[18] = {name = "acid", is_resistance = true, str = "acid resistance"},
							[19] = {name = "internal", is_resistance = true, str = "internal resistance"},
						}
						
						for _=0,buffs do

							local random_buff = math.random(#bonus_tab)-1
							local buff = bonus_tab[random_buff]
							value = math.random(100)
							

							
							if buff.factor then
								value = value * buff.factor
							end
							if buff.reverse then
								value = 2 - value
							end
							
							if buff.is_resistance then
								dbattr[buff.name..".resist"] = value
							else
								dbattr[buff.name] = value
							end
						end

					end
					
					return 1 -- destroy
				end
				return 0
			end
		]=],
	},

}

register_blueprint "moreClasses_kperk_antidemon"
{
	flags = { EF_NOPICKUP }, 
	callbacks = {
		on_area_damage = [[
			function ( self, weapon, level, c, damage, distance, center, source, is_repeat )
				if not is_repeat then
					for e in level:entities( c ) do
						if e then
							if e.data and e.data.ai and e.flags then
								local flags  = e.flags
								if flags.data[ EF_TARGETABLE ] and e.data then
							
									if e.data.ai.group == "demon" or e.data.ai.group == "exalted" then
										local p = world:get_player()
										local demono = p:child("moreClasses_ktrait_master_demonologist")
										local dattr = demono.attributes
										world:get_level():apply_damage( self, e, (damage * math.max(1,1+(dattr.anti_demon/100))) - damage,  ivec2(), "internal" )
									end
								end
							end
						end
					end
				end
			end
		]],
	},
}

register_blueprint "moreClasses_ktrait_master_demonologist"
{
	blueprint = "trait",
	text = {
		name   = "DEMONOLOGIST",
		desc   = "MASTER TRAIT - Collect blood pouches from demons with some random buffs.",
		full   = "You have splatted so much of these {?cursed|fuckers|demons} from hell, you slowly took interest in their inners and discovered interesting properties : make their blood yours!\n\n{!LEVEL 1} - Demons drop Blood Pouches depending on their max health. {!10%} chances to get a random buff. {!10%} more damages to demons and exalted.\n{!LEVEL 2} - {!25%} chances to get a buff. {!20%} more damages to demons and exalted.\n{!LEVEL 3} - {!40%} chances to get a buff. {!30%} more damages to demons and exalted.\n\nYou can pick only one MASTER trait per character.",
		abbr   = "MDM",
	},
	attributes = {
		level    = 1,
		anti_demon = 0,
		buff_chance = 0,
	},
	callbacks = {
		on_activate = [=[
			function(self,entity)
				local tlevel, t = gtk.upgrade_master( entity, "moreClasses_ktrait_master_demonologist" )
				t.attributes.anti_demon = 10 + 10 * tlevel-1
				t.attributes.buff_chance = 10 + 15 * tlevel-1
				local index = 0
				repeat 
					local w   = world:get_weapon( entity, index, true )
					if not w then break end
					local ad = w:child("moreClasses_kperk_antidemon")
					if not ad then
						w:attach("moreClasses_kperk_antidemon")
					end
					index = index + 1
				until false
			end
		]=],
		on_pickup = [=[
			function ( self, user, w )
				if w and w.weapon and ( not w.stack ) then
					local ad = w:child("moreClasses_kperk_antidemon")
					if not ad then
						w:attach("moreClasses_kperk_antidemon")
					end
				end
			end
		]=],
		on_kill = [=[
			function ( self, entity, target, weapon )
				if target then
					if target.data and target.data.ai and target.flags then
						if not target.data.ai.group or target.data.boss then
							return
						end
						local flags  = target.flags
						local amount = 0
						local eattr = entity.attributes
						local tattr = target.attributes
						if flags.data[ EF_TARGETABLE ] and target.data then
							if target.data.ai.group == "demon" or target.data.ai.group == "exalted" then
								amount = math.max(2,math.floor(tattr.health/20))
								if target.data.is_semimechanical then
									amount = math.max(1,math.ceil(amount * 0.75))
								end
							
						
								amount = (amount + (eattr.temp_blood_bonus or 0)) *  math.max(1,(eattr.blood_coef or 1))
								eattr.temp_blood_bonus = 0
								eattr.blood_coef = 1.0
								
								if amount > 0 then
									local orb = world:get_level():add_entity( "moreClasses_orb_resource_demon_blood_pouch", target:get_position() )
									orb.attributes.amount = amount
									orb.attributes.buff_chance = self.attributes.buff_chance
									orb.attributes.buff_turns = 5 + math.floor(tattr.experience_value/30)
								end
							end
						end
					end
				end
			end
		]=],

	},
}



register_blueprint "moreClasses_mister_hyde"
{
	flags = { EF_NOPICKUP }, 
	text = {
		name      = "Mr Hyde",
		sname      = "Mr Hyde",
		killed_by = "Dr Jekyll won!",
		sname     = "moreClasses_mrhyde",
		desc      = "Your madness and anger took over. You are me and I am you.",
		drjekyll = "Good to see you again, doctor!"
	},
	source = {},
	callbacks = {
		on_timer = [[
			function ( self, first )
				if first then return 99 end
				local attr   = self.attributes
				local target = ecs:parent( self )
				if target and target.data then
					local tattr = target.attributes
					local slevel = attr.amount
					
					local mr_hyde = 1 + ((15 + 10 * (slevel - 1))/100)
					if attr.speed < mr_hyde then
						attr.speed = mr_hyde
						attr.damage_mult = mr_hyde
					end
					
					local dr_jekyll = 10 + 10 * (slevel - 1)
					if target.health.current > (tattr.health * (dr_jekyll/100)) then
						ui:set_hint( "{!"..self.text.drjekyll.."}", 2001, 0 )
						world:mark_destroy( self )
						return 0
					end
				end
				return 100
			end
		]],
	},
	attributes = {
		amount = 0,
		speed = 1.15,
		damage_mult = 1.15,
	},
	ui_buff = {
		color     = RED,
		style     = 3,
		attribute = "amount",
	},
}

register_blueprint "moreClasses_ktrait_master_mr_hyde"
{
	blueprint = "trait",
	text = {
		name   = "MISTER HYDE",
		desc   = "MASTER TRAIT - When your life shall reach 0 health or below, your blood pouches act as a second health bar and your speed and damages are increased.",
		full   = "You have seen so much lives you can't save. It's now time to let your dark side take over...\n\n{!LEVEL 1} - Damage and speed bonus of {!15%}. Bonus lost above {!10%} of your max health. \n{!LEVEL 2} -  Mr Hyde's damages and speed increased by {!25%}. Lost bonus at {!20%} of your max health. \n{!LEVEL 3} - Damage and speed bonus of {!35%}. Bonus lost above {!30%} of your max health. \nYou can pick only one MASTER trait per character.",
		abbr   = "MMH",
		
		mrhyde = "<< YOUR DARK SELF RISES >>"
	},
	attributes = {
		level    = 1,
		mr_hyde = 25,
		dr_drjekyll = 15,
	},
	callbacks = {
		on_activate = [=[
			function(self,entity)
				local slevel, t = gtk.upgrade_master( entity, "moreClasses_ktrait_master_mr_hyde" )
				local hyde = entity:child("moreClasses_mister_hyde")
				if hyde then
					local hattr = hyde.attributes
					if hattr.amount < slevel then
						world:mark_destroy(hyde)
						core.apply_damage_status( entity, "moreClasses_mister_hyde", "moreClasses_mister_hyde", slevel, entity )
					end
				end
			end
		]=],
		on_receive_damage = [[
			function ( self, entity, source, weapon, amount )
				if not entity then return end
				local eh  = entity.health
				if eh.current <= 0 then
					local blood = entity:child("moreClasses_resource_blood_pouch")
					if blood then
						local battr = blood.attributes
						local attr  = entity.attributes
						local fhb = (attr.field_healing_bonus or 0)
						local coef  = math.max(10,fhb* 5 + 10)
						local value = battr.value
						
						local total_blood_health = value * coef
						total_blood_health = total_blood_health + eh.current
						if total_blood_health > 0  then
							battr.value = total_blood_health / coef
							eh.current = 1
							if not entity:child("moreClasses_mister_hyde") then
								core.apply_damage_status( entity, "moreClasses_mister_hyde", "moreClasses_mister_hyde", self.attributes.level, entity )
								ui:set_hint( "{R"..self.text.mrhyde.."}", 2001, 0 )
							else
								local hyde = entity:child("moreClasses_mister_hyde")
								local hattr = hyde.attributes
								if hattr.amount < self.attributes.level then
									world:mark_destroy(hyde)
									core.apply_damage_status( entity, "moreClasses_mister_hyde", "moreClasses_mister_hyde", self.attributes.level, entity )
								end
							end
						end
					end
				end
			end
		]],

	},
}

register_blueprint "moreClasses_klass_medic"
{
	text = {
		name  = "Para-Medic",
		short = "Medic",
		desc = "Both soldiers and doctors, they can take as much life as they can save.\n\n{!RESOURCE} - Medics uses {!Blood Pouch} as a class resource, it can be harvested on any dead human bodies. It can overflow until you leave a level.\n\n{!PASSIVE} - Medics use first aids that restore {!1} health every time they wait if their health below {!15%}.\n\n{!ACTIVE} - Use {!10} Blood Pouches to regain {!10} health. This skill can overheal up to {!40}, this extra health will be lost if you leave a level.\n\n{!ACTIVE} - you can assemble {!3} small medkits into a large one.\n\n{!GEAR} - Medics start with {!1} stimpack but less ammo.",
		abbr = "D",
		--entity = "moreClasses_player_medic",
		--klass  = "moreClasses_medic",
	},
	callbacks = {
		on_activate = [=[
			function(self,entity)
				entity:attach( "moreClasses_resource_blood_pouch" )
				local fr = entity:attach( "moreClasses_ktrait_field_healing" )
				fr.skill.cost = 1
				entity:attach( "moreClasses_ktrait_med_assemble" )
				entity:attach( "moreClasses_ktrait_first_aids" )
				entity:attach( "pistol" )
				entity:attach( "ammo_9mm", { stack = { amount = 24 } } )
				entity:attach( "stimpack_small", { stack = { amount = 1 } } )
			end
		]=],
		
	},
	klass = {
		id = "medic",
		entity = "moreClasses_player_medic",
		res = "moreClasses_resource_blood_pouch",
		traits = {
			{ "moreClasses_ktrait_skilled_medic", max = 3, },
			{ "trait_field_medic",	max = 3, },
			{ "moreClasses_ktrait_medical_stash", max = 3, },
			{ "trait_ironman",       max = 3, },
			{ "trait_swashbuckler",max = 3, },
			{ "trait_cover_master",  max = 3, },
			{ "trait_gun",           max = 3, },
			{ "trait_juggler",       max = 3, },
			{ "trait_hellrunner",    max = 3, },
			{ "trait_tough",  		 max = 3, },

			{ "moreClasses_ktrait_harvester", max = 3, require = { trait_field_medic = 1, } },
			{ "trait_eagle_eye",    max = 3, require = { trait_gun = 2, } },
			{ "moreClasses_ktrait_phd", 		max = 3, require = { moreClasses_ktrait_skilled_medic = 2, } },
			{ "trait_scavenger",   max = 3, require = { trait_juggler = 1, } },
			{ "moreClasses_ktrait_blood_saving",    max = 3, require = { moreClasses_ktrait_medical_stash = 1, } },
			{ "trait_bladedancer", max = 3, require = { trait_swashbuckler = 1, } },
			{ "trait_bloodhound",  max = 3, require = { trait_cover_master = 1, } },
		
			{ "moreClasses_ktrait_master_an_apple_a_day", max = 3, master = true, require = { 
				moreClasses_ktrait_medical_stash = 1, trait_tough = 1, level = 6, level_inc = 4,
			} },
			{ "moreClasses_ktrait_master_keep_the_doctor_away", max = 3, master = true, require = { 
				trait_ironman = 1, trait_cover_master = 1, level = 6, level_inc = 4,
			} },
			{ "moreClasses_ktrait_master_plague_doctor", max = 3, master = true, require = { 
				moreClasses_ktrait_skilled_medic = 1, trait_juggler = 1, level = 6, level_inc = 4,
			} },
			{ "moreClasses_ktrait_master_demonologist", max = 3, master = true, require = { 
				moreClasses_ktrait_phd = 1, trait_gun = 1, level = 6, level_inc = 4,
			} },
			{ "moreClasses_ktrait_master_mr_hyde", max = 3, master = true, require = { 
				trait_hellrunner = 1, moreClasses_ktrait_harvester = 1, level = 6, level_inc = 4,
			} },
		},
	},
}