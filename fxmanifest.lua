fx_version 'cerulean'
game 'gta5'

author 'j0w1_xR'
description 'Nombre en la cabeza'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    'server.lua'
}

lua54 'yes'