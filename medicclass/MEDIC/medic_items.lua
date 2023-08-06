register_blueprint "medkit_large"
{
	flags = { EF_ITEM, EF_CONSUMABLE },
	lists = {
		group    = "item",
		keywords = { "medical", },
		weight   = 200,
		dmin     = 4,
		dmed     = 7,
	},
	text = {
		name = "large medkit",
		desc = "Standard military issue medical kit. Too bad it doesn't regrow lost limbs. Heals all damage and pain.",
	},
	stack = {
		max    = 1,
		amount = 1,
	},
	ascii     = {
		glyph     = "+",
		color     = RED,
	},
	callbacks = {
		on_use = [=[
		function(self,entity)
			local attr    = entity.attributes
			local current = entity.health.current
			if current < attr.health then
				local mod = attr.medkit_mod or 1.0
				world:play_sound( "medkit_large", entity )
				entity.health.current = math.min( current + math.ceil( attr.health * mod ), attr.health )
				local epain = entity:child("pain")
				if epain then
					epain.attributes.accuracy = 0
					epain.attributes.value    = 0
				end
				ui:spawn_fx( entity, "fx_heal", entity )
				if current <= 30 then
					world:play_voice("vo_imedkit")
				else
					world:play_voice("vo_medkit")
				end
				world:destroy( entity:child("bleed") )
				world:destroy( entity:child("poisoned") )
				world:destroy( entity:child("acided") )
				world:destroy( entity:child("burning") )
				world:destroy( entity:child("freeze") )
				gtk.remove_fire( entity:get_position() )
				return 100
			end
			return -1
		end
		]=],
	},
}

register_blueprint "stimpack_large"
{
	flags = { EF_ITEM, EF_CONSUMABLE }, 
	lists = {
		group    = "item",
		keywords = { "medical", },
		weight   = 100,
		dmin     = 7,
		dmed     = 14,
	},
	text = {
		name = "military stimpack",
		desc = "Standard military stimpack. Fully heals you, resets all skill cooldowns, regenerates class resource, and removes pain and grants resistances for a longer time. We'd suggest you not overuse it, but we know you better. You monster.",
	},
	stack = {
		max    = 1,
		amount = 1,
	},
	ascii     = {
		glyph     = "+",
		color     = GREEN,
	},
	callbacks = {
		on_use = [=[
		function(self,entity)
			local hd      = entity.health
			local attr    = entity.attributes
			local mod     = world:get_attribute_mul( entity, "medkit_mod" ) or 1.0
			local current = hd.current

			world:play_sound( "medkit_large", entity )
			if attr.health > 60 then
				attr.health = math.max( attr.health - 5, 60 )
			end
			if hd.current < attr.health then
				hd.current = math.min( current + math.ceil( attr.health * mod ), attr.health )
			end
			local epain = entity:child("pain")
			if epain then
				epain.attributes.accuracy = 0
				epain.attributes.value    = 0
			end
			for c in ecs:children( entity ) do
				if c.resource then
					local attr   = c.attributes
					attr.value   = math.max( attr.value, attr.max )
				end
				if c.skill then
					if c.attributes then
						c.attributes.skill_reset = 1
					end
					if c.skill.time_left ~= 0 then
						c.skill.time_left = 0
					end
				end
			end
			world:add_buff( entity, "buff_stimpack", 3000 )
			ui:spawn_fx( entity, "fx_heal", entity )
			if current <= 30 then
				world:play_voice("vo_imedkit")
			else
				world:play_voice("vo_medkit")
			end
			world:destroy( entity:child("bleed") )
			world:destroy( entity:child("poisoned") )
			world:destroy( entity:child("acided") )
			world:destroy( entity:child("burning") )
			world:destroy( entity:child("freeze") )
			gtk.remove_fire( entity:get_position() )
			return 100
		end
		]=],
	},
}