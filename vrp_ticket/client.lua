-- made by Flaviu1999 taticul nostru - https://discord.gg/UXMsVhVpPv
-- made by Flaviu1999 taticul nostru - https://discord.gg/UXMsVhVpPv
-- made by Flaviu1999 taticul nostru - https://discord.gg/UXMsVhVpPv
-- made by Flaviu1999 taticul nostru - https://discord.gg/UXMsVhVpPv
-- made by Flaviu1999 taticul nostru - https://discord.gg/UXMsVhVpPv
-- made by Flaviu1999 taticul nostru - https://discord.gg/UXMsVhVpPv


local vRP = Proxy.getInterface("vRP")

Citizen.CreateThread(function()
	Wait(1000)
	TriggerServerEvent("vrp_tickets:FetchFeedbackTable")
end)

-------------------------- VARS

local oneSync = false

local FeedbackTable = {}
local canFeedback = true
local timeLeft = Config.FeedbackCooldown

-------------------------- COMMANDS
RegisterNetEvent('vrp_tickets:faticket')
AddEventHandler('vrp_tickets:faticket', function(source, args, rawCommand)
	if canFeedback then 
		FeedbackMenu(false)
	else
		vRP.notify({"Ai facut deja un ticket, mai asteapta!"})
	end
end)
RegisterNetEvent('vrp_tickets:deschideticketele')
AddEventHandler('vrp_tickets:deschideticketele', function(source, args, rawCommand)
	FeedbackMenu(true)
end)


RegisterNetEvent('$legend:feedback',function()
	if canFeedback then
		FeedbackMenu(false)
	else
		vRP.notify({"Ai facut deja un ticket, mai asteapta!"})
	end
end)

-------------------------- MENU

function FeedbackMenu(showAdminMenu)
	SetNuiFocus(true, true)
	if showAdminMenu then
		SendNUIMessage({
			action = "updateFeedback",
			FeedbackTable = FeedbackTable
		})
		SendNUIMessage({
			action = "OpenAdminFeedback",
		})
	else
		SendNUIMessage({
			action = "ClientFeedback",
		})
	end
end

-------------------------- EVENTS

RegisterNetEvent('vrp_tickets:NewFeedback')
AddEventHandler('vrp_tickets:NewFeedback', function(newFeedback)
		FeedbackTable[#FeedbackTable+1] = newFeedback
		SendNUIMessage({
			action = "updateFeedback",
			FeedbackTable = FeedbackTable
		})

end)

RegisterNetEvent('vrp_tickets:FetchFeedbackTable')
AddEventHandler('vrp_tickets:FetchFeedbackTable', function(feedback, admin, oneS)
	FeedbackTable = feedback

	oneSync = oneS
end)

RegisterNetEvent('vrp_tickets:FeedbackConclude')
AddEventHandler('vrp_tickets:FeedbackConclude', function(feedbackID, info)
	local feedbackid = FeedbackTable[feedbackID]
	if not feedbackid then return end
	feedbackid.concluded = info

	SendNUIMessage({
		action = "updateFeedback",
		FeedbackTable = FeedbackTable
	})
end)

-------------------------- ACTIONS

RegisterNUICallback("action", function(data)
	if data.action ~= "concludeFeedback" then
		SetNuiFocus(false, false)
	end

	if data.action == "newFeedback" then
		vRP.notify({"Ticket trimis cu succes!"})
		
		local feedbackInfo = {subject = data.subject, information = data.information, category = data.category}
		TriggerServerEvent("vrp_tickets:NewFeedback", feedbackInfo)

		local time = Config.FeedbackCooldown * 60
		local pastTime = 0
		canFeedback = false

		while (time > pastTime) do
			Citizen.Wait(1000)
			pastTime = pastTime + 1
			timeLeft = time - pastTime
		end
		canFeedback = true
	elseif data.action == "assistFeedback" then
		if FeedbackTable[data.feedbackid] then
			if oneSync then
				TriggerServerEvent("vrp_tickets:AssistFeedback", data.feedbackid, true)
			else
				local playerFeedbackID = FeedbackTable[data.feedbackid].playerid
				local playerID = GetPlayerFromServerId(playerFeedbackID)
				local playerOnline = NetworkIsPlayerActive(playerID)
				if playerOnline then
					SetEntityCoords(PlayerPedId(), GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(playerFeedbackID))))
					TriggerServerEvent("vrp_tickets:AssistFeedback", data.feedbackid, true)
				else
					vRP.notify({"Acest jucator nu mai este pe server!"})
				end
			end
		end
	elseif data.action == "concludeFeedback" then
		local feedbackID = data.feedbackid
		local canConclude = data.canConclude
		local feedbackInfo = FeedbackTable[feedbackID]
		if feedbackInfo then
			if feedbackInfo.concluded ~= true or canConclude then
				TriggerServerEvent("vrp_tickets:FeedbackConclude", feedbackID, canConclude)
				--vRP.notify({"Ticket-ul cu numarul "..feedbackID.." rezolvat!"})
			end
		end
	end
end)