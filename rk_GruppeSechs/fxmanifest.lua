
fx_version 'cerulean'
game 'gta5'

author 'Rk Script'
description 'Job Gruppe Sechs ESX con ox_target'
version '1.0.0'

shared_script 'Config.lua'

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@es_extended/imports.lua',
    'server/main.lua'
}

ui_page 'html/main.html'

files {
    'html/main.html',
    'html/main.css',
    'html/main.js',
    'html/img/tablet_bg.png'
}
