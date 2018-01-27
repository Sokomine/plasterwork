-- the machine that adds a layer of plaster to nodes

-- anyone who can build there can use the machine
plasterwork.can_use = function( pos, player )
	return not(minetest.is_protected(pos, player:get_player_name()));
end

-- the actual formspec menu for the machine
plasterwork.update_formspec = function(pos, meta, inv)
	local formspec = "size[8,8.5]"..
			default.gui_bg..
			default.gui_bg_img..
			default.gui_slots..
			"list[context;src;1.75,2.0;2,1;]"..
			"list[context;dst;4.75,2.0;1,1;]"..
			"list[current_player;main;0,4.25;8,1;]"..
			"list[current_player;main;0,5.5;8,3;8]"..
			default.get_hotbar_bg(0, 4.25);

	local can_pay = inv:contains_item("price", plasterwork.scan_price);
	-- substract the price for the scan
	if( can_pay ) then
		inv:remove_item( "price", plasterwork.scan_price);
	end

	local node_below = minetest.get_node( {x=pos.x, y=pos.y-1, z=pos.z});
	
	if( can_pay and node_below and node_below.name) then
		local old_name = node_below.name;
		-- exchange the node below with a random plastered one
		if( node_below.name == plasterwork.random_block) then
			node_below.name = plasterwork.node_list[ math.random( 1, #plasterwork.node_list )];
		-- ..or with a specific one if it is the right type
		else
			for k,v in pairs( plasterwork.supported ) do
				if( k and v and v[3] and v[3]==node_below.name ) then
					node_below.name = k;
				end
			end

		end
		-- we found a new one
		if( old_name ~= node_below.name ) then
			node_below.param2 = math.random(0,255);
			minetest.set_node( {x=pos.x, y=pos.y-1, z=pos.z}, node_below );
		end
	end

	if( not( can_pay ) or not( node_below ) or not( node_below.name )
	  or not( minetest.registered_nodes[ node_below.name ])
	  or not( minetest.registered_nodes[ node_below.name ].paramtype2 )
	  or minetest.registered_nodes[ node_below.name ].paramtype2 ~= "color"
	  or not( plasterwork.supported[ node_below.name ])) then
		meta:set_string( "target_node",  "" );
		meta:set_int(    "target_color", 0 );
		meta:set_string("formspec", formspec..
			"label[3.25,1.5;Inventory (unused):]"..
			"label[0.25,0.5;Price for scan:]"..
			"label[0.50,1.25;1x]"..
			"item_image[0.75,1.0;1,1;"..plasterwork.scan_price.."]"..
			"list[context;price;0.50,2.0;1,1;]"..
			"label[0.50,3.0;Pay price]"..
			"label[2.50,-0.2;Machine unconfigured.]"..
			"label[2.25,0.3;Please insert one "..
				minetest.formspec_escape(
					minetest.registered_items[ plasterwork.scan_price ].description ).."]"..
			"label[2.25,0.6;and click on the scan button below.]"..
			"label[2.25,0.9;Hint: Scanning a "..
				minetest.formspec_escape(
					minetest.registered_nodes[ plasterwork.random_block ].description )..
				" will turn it]"..
			"label[2.25,1.2;into a randomly plastered and colored one.]"..
				
			"button[2.25,3.25;4.0,0.5;scan;Scan sample node below]");
		return;
	end

	local price_data = plasterwork.supported[ node_below.name ];
	meta:set_string( "formspec", formspec..
			"list[context;price;7.00,0.5;1,1;]"..
			"label[7.00,0.2;Take:]"..
			"label[2.25,1.5;Input:]"..
			"label[4.75,1.5;Output:]"..
			"image[3.75,0.5;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
			"image[3.75,2.0;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
			"label[3.00,0.15;"..price_data[ 2 ].."x]"..
			"label[5.00,0.15;1x]"..
			"item_image[2.75,0.5;1,1;"..price_data[ 1 ].."]"..
			"item_image[4.75,0.5;1,1;"..--minetest.formspec_escape(node_below.name).."]"..
				minetest.itemstring_with_palette( node_below.name, node_below.param2 ).."]"..
			"button[3.25,3.25;2.0,0.5;start;Start coating]");
	-- those nodes may vanish through digging
	meta:set_string( "target_node",  node_below.name );
	meta:set_int(    "target_color", node_below.param2 );
end


plasterwork.on_receive_fields = function(pos, formname, fields, sender)
	-- check if the player is allowed to use the machine
	if( not( plasterwork.can_use( pos, sender ))) then
		return;
	end

	-- find out which kind of plaster and color to use
	if( fields.scan ) then
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory();
		plasterwork.update_formspec(pos, meta, inv);
		return;
	end
	-- do the actual covering with plaster
	if( fields.start ) then
		local meta  = minetest.get_meta(pos);
		local inv   = meta:get_inventory();
		local typ   = meta:get_string( "target_node" );
		local color = meta:get_int(    "target_color" );
		local node_below = minetest.get_node( {x=pos.x, y=pos.y-1, z=pos.z});
		-- if the node has changed since the last scan: scan anew
		if( not( typ ) or typ=="" or not( node_below ) or not( node_below.name )
		  or node_below.name ~= typ 
		  or not( plasterwork.supported[ typ ])) then
			plasterwork.update_formspec(pos, meta, inv);
			return;
		end
		local will_consume = plasterwork.supported[ typ ][1].." "..
				     plasterwork.supported[ typ ][2];
		-- not enough left for one conversion
		if( not( inv:contains_item("src", will_consume))) then
			return;
		end
	
		-- get all inputs and outputs which need checking
		local stack1 = inv:get_stack("src",1);
		local stack2 = inv:get_stack("src",2);
		local stack3 = inv:get_stack("dst",1);
		local input_name = plasterwork.supported[ typ ][1];
		local output_name = minetest.itemstring_with_palette( typ, color );
		-- if any stack contains a node that does not match input or output: give up
		if(  not(stack1:is_empty() or stack1:get_name()==input_name)
		  or not(stack2:is_empty() or stack2:get_name()==input_name)
		  or not(stack3:is_empty() or stack3:get_name()==typ)) then --output_name)) then
			minetest.chat_send_player( sender:get_player_name(),
					"Please remove unsuitable input and/or output first!");
			return;
		end
		
		-- how many can we convert on the input side?
		local anz = inv:get_stack("src",1):get_count() + inv:get_stack("src",2):get_count();
		local max_convert = math.floor( anz / plasterwork.supported[ typ ][2] );

		-- how much space do we have on the output side?
		-- important: the *color* is not checked here. but a way to recolor nodes can't hurt either, so...
		local free = inv:get_stack("dst",1):get_free_space();
		if( free < 1 ) then
			return;
		end

		-- actually do the conversion
		max_convert = math.min( max_convert, free );
		inv:remove_item( "src", plasterwork.supported[ typ ][1].." "..
					plasterwork.supported[ typ ][2] * max_convert );
		inv:set_stack(   "dst", 1, minetest.itemstring_with_palette(
					typ.." "..(max_convert+stack3:get_count()), color ));
	end
end


-- the machine to do the coloring
minetest.register_node("plasterwork:machine", {
    description = "Machine that adds plaster coats. Place on top of a sample block and insert material.",
	tiles = {
		"plasterwork_machine_top.png",
		"plasterwork_machine_top.png^[transformFY",
		"plasterwork_machine_side.png",
		"plasterwork_machine_side.png^[transformFX",
		"plasterwork_machine_back.png",
		"plasterwork_machine_front.png"
	},
        groups = {cracky = 3, stone = 1},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{0.3125, -0.25, -0.5, 0.5, -0.1875, 0.5}, -- NodeBox1
			{-0.3125, -0.25, 0.3125, 0.3125, -0.1875, 0.5}, -- NodeBox2
			{-0.3125, -0.25, -0.5, 0.3125, -0.1875, -0.3125}, -- NodeBox3
			{-0.5, -0.25, -0.5, -0.3125, -0.1875, 0.5}, -- NodeBox4
			{0.3125, -0.5, -0.4375, 0.4375, -0.125, -0.3125}, -- NodeBox5
			{0.3125, -0.5, 0.3125, 0.4375, -0.125, 0.4375}, -- NodeBox6
			{-0.4375, -0.5, 0.3125, -0.3125, -0.125, 0.4375}, -- NodeBox7
			{-0.4375, -0.5, -0.4375, -0.3125, -0.125, -0.3125}, -- NodeBox8
			{-0.25, -0.3125, 0.1875, 0.25, -0.125, 0.5}, -- NodeBox9
			{-0.25, -0.25, -0.0625, -0.1875, -0.1875, 0.1875}, -- NodeBox10
			{0.1875, -0.25, -0.0625, 0.25, -0.1875, 0.1875}, -- NodeBox11
			{-0.125, -0.3125, -0.125, 0.125, -0.0625, 0.125}, -- NodeBox12
			{-0.1875, -0.3125, -0.5, 0.1875, -0.125, -0.25}, -- NodeBox13
			{-0.0625, -0.25, -0.5, 0.0625, -0.1875, -0.1875}, -- NodeBox14
			{-0.125, -0.375, 0.25, 0.125, -0.0625, 0.4375}, -- NodeBox15
			{-0.0625, -0.375, 0.3125, 0.0625, 0.5, 0.4375}, -- NodeBox16
			{-0.0625, 0.375, -0.0625, 0.0625, 0.5, 0.5}, -- NodeBox17
			{-0.125, 0.3125, -0.125, 0.125, 0.4375, 0.125}, -- NodeBox18
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
	},

	after_place_node = function(pos, placer, itemstack)
		local meta = minetest.get_meta( pos );
		meta:set_string( "infotext",
			"Machine that adds plaster coats. If placed on a block that has such a coat, "..
			"the machine will analyze the pattern of the coat and apply it to blocks placed "..
			"inside it.");
		local inv = meta:get_inventory()
		inv:set_size('src', 2);
		inv:set_size('dst', 1);
		inv:set_size('price', 1);
		plasterwork.update_formspec( pos, meta, inv );
	end,
	on_receive_fields = plasterwork.on_receive_fields,

	-- check if the player is allowed to access the inventory
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		if( not( plasterwork.can_use( pos, player ))) then
			return 0;
		end
		return count;
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if( not( plasterwork.can_use( pos, player ))) then
			return 0;
		end
		return stack:get_count();
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if( not( plasterwork.can_use( pos, player ))) then
			return 0;
		end
		return stack:get_count();
	end,
	can_dig = function(pos, player)
		if( player and not( plasterwork.can_use( pos, player ))) then
			return false;
		end
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory();
		return ( inv:is_empty("src")
		     and inv:is_empty("dst")
		     and inv:is_empty("price"));
	end,
})

minetest.register_craft({
	output = "plasterwork:machine",
	recipe = {
		{"default:mese_crystal_fragment", "default:mese_crystal_fragment", "default:mese_crystal_fragment"},
		{"default:chest",        "default:mese",        "default:chest"},
		{"default:mese_crystal", "default:copperblock", "default:mese_crystal"},
	}});
