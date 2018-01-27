
-- reserve namespace for functions etc.
plasterwork = {};

-- default palette for colorization
plasterwork.palette = "unifieddyes_palette_extended.png";

-- this block will - when scanned - turn into a randomly plastered one;
-- make sure that block has a description
plasterwork.random_block = "default:bronzeblock";

-- each scan (adjustment to new plaster and color type) costs that much:
plasterwork.scan_price = "default:mese_crystal_fragment";

-- only nodes listed here can be colored
plasterwork.supported = {};
-- content of the table: { name of source node that can be plastered,
--                         amount needed for one output}

-- list of all supported nodes (=indices of plasterwork.supported)
plasterwork.node_list = {};

local path = minetest.get_modpath( minetest.get_current_modname());
-- register the actual nodes that may receive a plaster coat
-- (there's also a function for registering more)
dofile( path.."/nodes.lua")
-- the machine that applies the coating
dofile( path.."/machine.lua")
