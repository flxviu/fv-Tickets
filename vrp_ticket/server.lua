

-- local vRP = Proxy.getloc
local Proxy = module("vrp","lib/Proxy")
local Tunnel = module("vrp", "lib/Tunnel")
local vRP = Proxy.getInterface[[vRP]]
vRPclient = Tunnel.getInterface("vRP","vrp_ticete")
local TicketFacut = {}
local LastTicket = {}
local totaltickets = 0
local oneSync = true;

-------------------------- VARS

local Webhook = 'https://discord.com/api/webhooks/1321590164023410761/4X6382QpVRMhMxB71cb47IK002NwgoWC5WWs8HqAKhrTJjw-6YAgmYA2z0GgpkTSsE8l'

local FeedbackTable = {}

-------------------------- NEW FEEDBACK

RegisterNetEvent("vrp_tickets:NewFeedback")
AddEventHandler("vrp_tickets:NewFeedback", function(data)
	local identifierlist = ExtractIdentifiers(source)
	local user_id = vRP.getUserId({source})
	if TicketFacut[user_id] then return vRPclient.notify(source,{'Eroare: Ai deja un ticket facut.'}) end;
	local newFeedback = {
		feedbackid = #FeedbackTable+1,
		playerid = source,
		identifier = identifierlist.license:gsub("license2:", ""),
		idjucator = user_id,
		subject = data.subject,
		information = data.information,
		category = data.category,
		concluded = false,
		discord = "<@"..identifierlist.discord:gsub("discord:", "")..">"
	}

	FeedbackTable[#FeedbackTable+1] = newFeedback
	TicketFacut[user_id] = true
	TriggerClientEvent('3dme:shareDisplay', -1, 'OOC: Jucatorul a realizat un Ticket', source)
	totaltickets = totaltickets + 1
	TriggerClientEvent('ples:setTickets',-1, totaltickets)
	TriggerClientEvent("vrp_tickets:NewFeedback", -1, newFeedback)
	sendStaffMessage('Un nou ticket a fost facut!')
	if Webhook ~= '' then
		newFeedbackWebhook(newFeedback)
	end
end)

-------------------------- FETCH FEEDBACK

RegisterNetEvent("vrp_tickets:FetchFeedbackTable")
AddEventHandler("vrp_tickets:FetchFeedbackTable", function()

		--staffs[source] = true
		TriggerClientEvent("vrp_tickets:FetchFeedbackTable", source, FeedbackTable, staff, oneSync)

end)

-------------------------- ASSIST FEEDBACK

RegisterNetEvent("vrp_tickets:AssistFeedback")
AddEventHandler("vrp_tickets:AssistFeedback", function(feedbackId, canAssist)

		if canAssist then

			local id = FeedbackTable[feedbackId].playerid

			if GetPlayerPing(id) > 0 then
				local ped = GetPlayerPed(id)
				local uid = vRP.getUserId({source})
				if vRP.isUserTrialHelper({uid}) then
					local playerCoords = GetEntityCoords(ped)
					local pedSource = GetPlayerPed(source)
					--local user_id = 1
					local identifierlist = ExtractIdentifiers(source)
					local assistFeedback = {
						feedbackid = feedbackId,
						discord = "<@"..identifierlist.discord:gsub("discord:", "")..">"
					}

					SetEntityCoords(pedSource, playerCoords.x, playerCoords.y, playerCoords.z)
					-- print(GetPlayerRoutingBucket(source),GetPlayerRoutingBucket(id))
					if GetPlayerRoutingBucket(source) ~= GetPlayerRoutingBucket(id) then
						SetPlayerRoutingBucket(source, GetPlayerRoutingBucket(id))
					end
				
					exports.oxmysql:query("UPDATE vrp_users SET raport = raport + 1 WHERE id = "..uid,{})
					vRPclient.notify(source,{"Te-ai dus la ticket-ul cu numarul "..feedbackId.."!"})
					vRPclient.notify(id,{"Un admin ti-a preluat ticket-ul!"})
					local targetId = vRP.getUserId({id})
					if TicketFacut[targetId] then
						totaltickets = totaltickets - 1
						TicketFacut[targetId] = false
						TriggerClientEvent('ples:setTickets',-1, totaltickets)

						LastTicket[source] = id
					end

					if Webhook ~= '' then
						assistFeedbackWebhook(assistFeedback)
					end
				end
			else	
				vRPclient.notify(id,{"Acest player nu mai este pe server!"})
			end
			if not FeedbackTable[feedbackId].concluded then
				FeedbackTable[feedbackId].concluded = "assisting"
			end
			TriggerClientEvent("vrp_tickets:FeedbackConclude", -1, feedbackId, FeedbackTable[feedbackId].concluded)
		end
end)


RegisterCommand('lasttk',function(source,args)
	local user_id = vRP.getUserId{source}
	if vRP.isUserTrialHelper{user_id} then
		local TargetSource = LastTicket[source]

		if TargetSource ~= nil then
			local playerPed = GetPlayerPed(source);
			local TargetPed = GetPlayerPed(TargetSource);
			local TargetCoords = GetEntityCoords(TargetPed)

			SetEntityCoords(playerPed, TargetCoords[1], TargetCoords[2], TargetCoords[3])
			vRPclient.notify(source,{'Te-ai teleportat la ultimul Ticket.'})
		else
			vRPclient.notify(source,{'Nu ai un ultim Ticket'})
		end
	else
		vRPclient.notify(source,{'Nu ai acces la aceasta comanda'})
	end
end)

function sendStaffMessage(msg)
	for _,v in pairs(vRP.getOnlineStaff({})) do
		local player = vRP.getUserSource{v};
		if not player then return end;
		vRPclient.notify(player, {msg})
	end
end

RegisterCommand("tk", function(player, args, rawCommand)
	local user_id = vRP.getUserId({player})
	if vRP.isUserTrialHelper({user_id}) then
		TriggerClientEvent("vrp_tickets:deschideticketele", player)
	else
		vRPclient.notify(player,{"Nu esti membru staff!"})
	end

end, false)

-------------------------- CONCLUDE FEEDBACK

RegisterNetEvent("vrp_tickets:FeedbackConclude")
AddEventHandler("vrp_tickets:FeedbackConclude", function(feedbackId, canConclude)

		local feedback = FeedbackTable[feedbackId]
		local identifierlist = ExtractIdentifiers(source)
		local concludeFeedback = {
			feedbackid = feedbackId,
			discord = "<@"..identifierlist.discord:gsub("discord:", "")..">"
		}

		if feedback then
			if feedback.concluded ~= true or canConclude then
				if canConclude then
					if FeedbackTable[feedbackId].concluded == true then
						FeedbackTable[feedbackId].concluded = false
					else
						FeedbackTable[feedbackId].concluded = true
					end
				else
					FeedbackTable[feedbackId].concluded = true
				end
				TriggerClientEvent("vrp_tickets:FeedbackConclude", -1, feedbackId, FeedbackTable[feedbackId].concluded)
				-- totaltickets = totaltickets - 1
				-- TriggerClientEvent('ples:setTickets',-1, totaltickets)

				if Webhook ~= '' then
					concludeFeedbackWebhook(concludeFeedback)
				end
			end
		end

end)

-------------------------- HAS PERMISSION

function hasPermission(id,source)
	local staff = false
	local user_id = vRP.getUserId({source})
	if Config.ESX then
		local player = ESX.GetPlayerFromId(id)
		local playerGroup = player.getGroup()

		if playerGroup ~= nil and playerGroup == "superadmin" or playerGroup == "admin" or playerGroup == "mod" then 
			staff = true
		end
	else
		for i, a in ipairs(Config.AdminList) do
	        for x, b in ipairs(GetPlayerIdentifiers(id)) do
	            if vRP.isUserTrialHelper({user_id}) then
	                staff = true
	            end
	        end
	    end
	end

	return staff
end



RegisterCommand('fixtickete',function(source,args)
	local user_id = vRP.getUserId({source})
	if vRP.isUserOwner{user_id} then
		totaltickets = 0
		-- TriggerClientEvent('ples:setTickets',-1, totaltickets)
	end
end)




AddEventHandler("vRP:playerLeave",function(user_id,source)
	if TicketFacut[user_id] then
		totaltickets = totaltickets - 1
		-- TriggerClientEvent('ples:setTickets',-1, totaltickets)
		TicketFacut[user_id] = nil
	end
end)

-------------------------- IDENTIFIERS

function ExtractIdentifiers(id)
    local identifiers = {
        steam = "",
        ip = "",
        discord = "",
        license = "",
        xbl = "",
        live = ""
    }

    for i = 0, GetNumPlayerIdentifiers(id) - 1 do
        local playerID = GetPlayerIdentifier(id, i)

        if string.find(playerID, "steam") then
            identifiers.steam = playerID
        elseif string.find(playerID, "ip") then
            identifiers.ip = playerID
        elseif string.find(playerID, "discord") then
            identifiers.discord = playerID
        elseif string.find(playerID, "license") then
            identifiers.license = playerID
        elseif string.find(playerID, "xbl") then
            identifiers.xbl = playerID
        elseif string.find(playerID, "live") then
            identifiers.live = playerID
        end
    end

    return identifiers
end

-------------------------- NEW FEEDBACK WEBHOOK

function newFeedbackWebhook(data)
	if data.category == 'player_report' then
		category = 'Player Report'
	elseif data.category == 'question' then
		category = 'Question'
	else
		category = 'Bug'
	end

	local information = {
		{
			["color"] = Config.NewFeedbackWebhookColor,
			["author"] = {
				["icon_url"] = Config.IconURL,
				["name"] = Config.ServerName..' - Logs',
			},
			["title"] = 'TICKET NOU #NR.'..data.feedbackid,
			["description"] = '**Categorie:** '..category..'\n**Subiect:** '..data.subject..'\n**Informatii:** '..data.information..'\n\n**ID:** '..data.playerid..'\n**Identifier:** '..data.identifier..'\n**Discord:** '..data.discord,
			["footer"] = {
				["text"] = os.date(Config.DateFormat),
			}
		}
	}
	PerformHttpRequest(Webhook, function(err, text, headers) end, 'POST', json.encode({username = Config.BotName, embeds = information}), {['Content-Type'] = 'application/json'})
end

-------------------------- ASSIST FEEDBACK WEBHOOK

function assistFeedbackWebhook(data)
	local information = {
		{
			["color"] = Config.AssistFeedbackWebhookColor,
			["author"] = {
				["icon_url"] = Config.IconURL,
				["name"] = Config.ServerName..' - Logs',
			},
			["description"] = '**TICKETUL CU #NR.'..data.feedbackid..'** a fost acceptat de '..data.discord,
			["footer"] = {
				["text"] = os.date(Config.DateFormat),
			}
		}
	}
	PerformHttpRequest(Webhook, function(err, text, headers) end, 'POST', json.encode({username = Config.BotName, embeds = information}), {['Content-Type'] = 'application/json'})
end

-------------------------- CONCLUDE FEEDBACK WEBHOOK

function concludeFeedbackWebhook(data)
end