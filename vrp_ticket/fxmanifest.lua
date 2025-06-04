fx_version 'adamant'
game 'gta5'
version '1.1'
ui_page 'web/ui.html'
files {
	'web/*.*',
}
shared_script 'config.lua'
client_scripts {
	"@vrp/lib/utils.lua",
	"@vrp/client/Proxy.lua",
    "@vrp/client/Tunnel.lua",
	'client.lua'
}
server_scripts {
	"@vrp/lib/utils.lua",
	'server.lua',
}

print('fv-Tickets by Flaviu1999 taticul nostru')
