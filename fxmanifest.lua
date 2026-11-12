fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'

name 'ox_fuel'
author 'Overextended'
version '1.5.4'
repository 'https://github.com/overextended/ox_fuel'
description 'Fuel management system with ox_inventory support'

dependencies {
	'ox_lib',
	'cobalt_core',
	'cobalt_inventory',
}

shared_scripts {
	'@ox_lib/init.lua',
	'config.lua'
}

server_scripts {
	'bridge/ui/server.lua',
	'server.lua',
	'bridge/money/server.lua',
}

client_scripts {
	'bridge/ui/client.lua',
	'client/init.lua',
	'bridge/money/client.lua',
}

files {
	'locales/*.json',
	'data/stations.lua',
	'client/*.lua',
	'bridge/inventory/client.lua',
}

ox_libs {
	'math',
	'locale',
}
