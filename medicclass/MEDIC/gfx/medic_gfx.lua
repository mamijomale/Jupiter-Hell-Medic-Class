register_gfx_blueprint "moreClasses_armor_shirt_01_D_part"
{
	{
		tag    = "armor",
		render = {	
			mesh     = "data/model/player_male_mesh.nmd:player_body",
			material = "MEDIC/gfx/entities/player/player_body",
		},
	},
	{
		tag    = "armor",
		render = {
			mesh = "data/model/player_male_mesh.nmd:player_trousers_01",
			material = "MEDIC/gfx/entities/player/trousers_01_B",
		},
	},
}

register_gfx_blueprint "moreClasses_player_medic_head_part"
{
	skeleton = "data/model/player_male_mesh.nmd",
	{
		tag = "head",
		render = {
			mesh     = "data/model/player_male_mesh.nmd:player_head_01",
			material = "MEDIC/gfx/entities/player/player_head_01",
		},
	},
	{
		tag = "head",
		attach = "RigHead",
		render = {
			mesh = "data/model/security_mesh.nmd:security_hat_01",
			material = "MEDIC/gfx/entities/player/security_hat_A",
		},
	},
}

register_gfx_blueprint "moreClasses_player_medic"
{
	blueprint = "player",
	slot_base = {
		{ target    = "armor", blueprint = "moreClasses_armor_shirt_01_D_part", },
		{ target    = "head",  blueprint = "moreClasses_player_medic_head_part", },
	},
	{
		tag = "head",
		render = {
			mesh     = "data/model/player_male_mesh.nmd:player_head_01",
			material = "MEDIC/gfx/entities/player/player_head_01",
		},
	},
	{
		render = {
			mesh = "data/model/player_male_mesh.nmd:shoes_01",
			material = "MEDIC/gfx/entities/player/shoes_01_A",
		},
	},
	{
		tag    = "armor",
		render = {
			mesh = "data/model/player_male_mesh.nmd:player_trousers_01",
			material = "MEDIC/gfx/entities/player/trousers_01_B",
		},
	},
	{
		tag = "head",
		attach = "RigHead",
		render = {
			mesh = "data/model/security_mesh.nmd:security_hat_01",
			material = "MEDIC/gfx/entities/player/security_hat_A",
		},
	},
	{
		tag    = "armor",
		render = {
			mesh     = "data/model/player_male_mesh.nmd:player_body",
			material = "MEDIC/gfx/entities/player/player_body",
		},
	},
}


register_gfx_blueprint "moreClasses_orb_resource_blood_pouch"
{
	uisprite = {
		icon   = "MEDIC/gfx/items/ui_consumable_blood_pouch",
		color  = vec4( 1.0, 0.0, 0.0, 1.0 ),
	},
}

register_gfx_blueprint "moreClasses_orb_resource_demon_blood_pouch"
{
	uisprite = {
		icon   = "MEDIC/gfx/items/ui_consumable_blood_pouch_demon",
		color  = vec4( 1.0, 0.5, 0.1, 1.0 ),
	},
}

register_gfx_blueprint "moreClasses_virus"
{
	equip = {},
	persist = true,
	point_generator = {
		type     = "cylinder",
		position = vec3(0.0,0.1,0.0),
		extents  = vec3(0.2,1.0,0.0),
	},
	particle = {
		material        = "data/texture/particles/explosion_01/explosion_mark_01",
		group_id        = "pgroup_fx",
		orientation     = PS_ORIENTED,
		destroy_owner   = true,
		tiling          = 8,
	},
	particle_emitter = {
		rate     = 128,
		size     = vec2(0.1,0.4),
		velocity = 0.1,
		lifetime = 0.5,
		color    = vec4(0.8,0.75,0.1,0.5),
	},
	particle_animator = {
		range = ivec2(0,63),
		rate  = 160.0,
	},
	particle_transform = {
		force = vec3(0,3,0),
	},
	particle_fade = {
		fade_out = 0.5,
	},
}