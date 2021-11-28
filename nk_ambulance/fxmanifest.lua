fx_version 'adamant'

game 'gta5'

client_scripts {
    '@es_extended/locale.lua',
    'cl_menu.lua',
    'menu.lua',
    'config.lua',
    'fr.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    '@es_extended/locale.lua',
    'sv_deco.lua',
    'config.lua',
    'fr.lua'
}

dependencies {
    'es_extended'
}
