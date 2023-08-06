nova.require "ANY/trait"


register_blueprint "moreClasses_perk_aa_regen_boost"
{
	blueprint = "perk",
	lists = {
		group    = "perk_ca",
		keywords = { "medic", "amp", },
	},
	text = {
		name = "Improved first aids",
		desc = "use first aids with higher health",
	},
	attributes = {
		level = 2,
		first_aids_bonus = 1,
	},
}


register_blueprint "moreClasses_perk_ca_healgen"
{
	blueprint = "perk",
	lists = {
		group    = "perk_ca",
		keywords = { "medic", "amp", "armor", },
	},
	text = {
		name = "Extra aids",
		desc = "First aids heals you faster",
	},
	attributes = {
		level = 2,
		first_aids_heal_bonus = 1,
	},
}

register_blueprint "perk_ta_capacitor"
{
	blueprint = "perk",
	lists = {
		group    = "perk_ca",
		keywords = { "armor", },
	},
	text = {
		name = "Capacitor matrix",
		desc = "receiving damage recharges class skill (up to 100%)",
	},
	attributes = {
		level = 2,
	},
	callbacks = {
		on_receive_damage = [[
			function ( self, entity, source, weapon, amount )
				if not entity then return end
				if amount < 5 then return end
				local restore
				
				local klass = gtk.get_klass_id( entity )
				local resource
				if klass == "marine" then
					resource = entity:child( "resource_fury" )
					restore = math.floor( amount * 0.2 )
				else
					if klass == "scout" then
						resource = entity:child( "resource_energy" )
						restore = math.floor( amount * 0.2 )
					else						
						if klass == "tech" then 
							resource = entity:child( "resource_power" )
							restore = math.floor( amount * 0.2 )
						else
							local klass_hash = player.progression.klass
							local klass_id   = world:resolve_hash( klass_hash )
							local k = blueprints[ klass_id ]
							if not k.klass or not k.klass.res then
								return
							end
							resource = entity:child( k.res )
							restore = math.floor( amount * 0.2 )
						end
					end
				end
				local rattr = resource.attributes
				if rattr.value < rattr.max then
					rattr.value = math.min( rattr.value + restore, rattr.max )
				end
			end
		]],
	}
}