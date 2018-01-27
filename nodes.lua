-- there is no way of crafting these colored variants. Digging a colored clay
-- block would yield 4 uncolored clay lumps - which is not exactly helpful.
-- Even if the lumps would be colored, that would still be inconvenient due
-- to too many non-stacking nodes filling up the player's inventory.

plasterwork.register_plaster_node = function( node_name, description, image, palette, price_node, price_amount,
		randomly_from_source_block )
	minetest.register_node( node_name, {
		description = description,
		tiles = {image},
		is_ground_content = false,
		groups = {cracky = 3, stone = 1, plasterwork=1, not_in_creative_inventory=1},
		paramtype2 = "color",
		palette = palette,
		sounds = default.node_sound_stone_defaults(),
	});
	if( price_node and price_amount ) then
		-- maintain a list of supported nodes for easy selection of random nodes
		if( not( plasterwork.supported[ node_name ])) then
			table.insert( plasterwork.node_list, node_name );
		end
		plasterwork.supported[ node_name ] = { price_node, price_amount, randomly_from_source_block };
	end
end

plasterwork.register_plaster_node( "plasterwork:rough_plaster", "Stone with clay plaster",
	"default_clay.png", plasterwork.palette, "default:cobble", 2, "default:copperblock" );

plasterwork.register_plaster_node( "plasterwork:smooth_plaster", "Stone with smooth plaster",
	"default_coral_skeleton.png", plasterwork.palette, "default:cobble", 4, "default:steelblock" );

plasterwork.register_plaster_node( "plasterwork:tin_plaster", "Stone with metallic plaster",
	"default_tin_block.png", plasterwork.palette, "default:cobble", 6, "default:tinblock" );

plasterwork.register_plaster_node( "plasterwork:sandstone_plaster", "Stone with sandstone plaster",
	"default_sandstone.png", plasterwork.palette, "default:cobble", 6, "default:goldblock" );
