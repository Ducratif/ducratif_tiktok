fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'ducratif_tiktok'
author 'Ducratif'
version '1.1.0'
description 'Bridge TikTok -> ESX (events in-game)'

server_scripts {
  '@es_extended/imports.lua',
  'config.lua',
  'server.lua'
}

client_scripts {
  'config.lua',
  'client.lua'
}

--escrow_ignore {
--    'config.lua',
--}