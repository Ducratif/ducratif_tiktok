CreateThread(function()
    Wait(500) -- petit délai pour pas mélanger avec les autres prints
    print("^6====================================================^7")
    print("^5       🎥  TikTok:^7 Ducratifoff  |  ^4YouTube:^7 DucraDev")
    print("^3       💬  Discord:^7 Ducratif   |  ^2Github:^7 Ducratif")
    print("^1       🔗  https://discord.gg/kpD8pQBBWm")
    print("^6====================================================^7")
    print("^2[ducratif_tiktok]^7 ^1 Ce script est gratuit ! Développer par Ducratif !^7")
    print("^2[ducratif_tiktok]^7 Script chargé avec succès ✅")
end)


-- =========================
-- 🔍 Vérification de mise à jour
-- =========================
local CURRENT_VERSION = "1.0.0"
local VERSION_URL = "https://ducratif.github.io/ducratif_tiktok/version_fivem.txt"

CreateThread(function()
    PerformHttpRequest(VERSION_URL, function(err, text, headers)
        if not text or text == "" then
            print("^1[ducratif_tiktok]^7 Impossible de vérifier la version sur GitHub.")
            return
        end

        local latest = text:gsub("%s+", "") -- clean espaces/newlines
        if latest ~= CURRENT_VERSION then
            print(("^3[ducratif_tiktok]^7 Nouvelle version disponible côté FiveM ! ^2%s^7 (actuelle: ^1%s^7)"):format(latest, CURRENT_VERSION))
            print("^5[ducratif_tiktok]^7 Téléchargez la mise à jour ici: ^4https://github.com/Ducratif/ducratif_tiktok")
        else
            print(("^2[ducratif_tiktok]^7 Vous êtes à jour (version %s)."):format(CURRENT_VERSION))
        end
    end, "GET")
end)

-- =========================

local ESX = exports['es_extended']:getSharedObject()

local doSpawnFanPed

-- Helper: récupère tous les IDs possibles (ESX + FiveM) en minuscules
local function collectAllIds(xPlayer)
  local ids = {}

  if xPlayer and xPlayer.identifier then
    ids[#ids+1] = tostring(xPlayer.identifier)
  end
  if xPlayer and xPlayer.source then
    for _, id in ipairs(GetPlayerIdentifiers(xPlayer.source)) do
      ids[#ids+1] = id
    end
  end

  for i=1, #ids do ids[i] = string.lower(ids[i]) end
  return ids
end

-- ========== Utils ==========
local function dbg(fmt, ...)
  if Config.Debug then
    print(('[ducratif_tiktok] '..string.format(fmt, ...)))
  end
end

local function isStreamer(xPlayer)
  if not xPlayer then return false end

  local have = collectAllIds(xPlayer)
  local wants = {}
  for _, v in ipairs(Config.StreamerIdentifiers or {}) do
    wants[#wants+1] = string.lower(v)
  end

  -- log utile en debug
  if Config.Debug then
    print(('[ducratif_tiktok] IDs for %s (%s): %s'):format(
      xPlayer.getName(), tostring(xPlayer.source), table.concat(have, ', ')
    ))
  end

  -- match strict OU "contient" (pratique si tu mets juste 'char1:cfx:')
  for _, wanted in ipairs(wants) do
    for __, got in ipairs(have) do
      if got == wanted or string.find(got, wanted, 1, true) then
        return true
      end
    end
  end
  return false
end

local function getAnyStreamerSource()
  for _, xPlayer in pairs(ESX.GetExtendedPlayers()) do
    if isStreamer(xPlayer) then return xPlayer.source end
  end
  return nil
end


local function announceToAll(msg)
  TriggerClientEvent('chat:addMessage', -1, { args = { 'TikTok', msg } })
end

-- ========== Actions côté serveur ==========
local function doFireworks(rounds, radius)
  local targetSrc = getAnyStreamerSource()
  TriggerClientEvent('ducratif_tiktok:fireworksAtStreamer', -1, rounds or 3, radius or 6.0, targetSrc)
end

local function doSpeedBoostAll(seconds, mult)
  TriggerClientEvent('ducratif_tiktok:speedBoost', -1, seconds or 60, mult or 1.15)
end

local function doMoneyRainAll(amount, reason)
  amount = amount or 1000
  for _, xPlayer in pairs(ESX.GetExtendedPlayers()) do
    xPlayer.addAccountMoney('money', amount, reason or 'TikTok')
  end
  announceToAll(('^2+%d$ ^7à tous (TikTok)'):format(amount))
end

local function doGiveRandomItemToRandomPlayer(pool)
  local players = ESX.GetExtendedPlayers()
  if #players == 0 then return end
  local xPlayer = players[math.random(1, #players)]
  if not pool or #pool == 0 then return end
  local pick = pool[math.random(1, #pool)]
  xPlayer.addInventoryItem(pick.name, pick.count or 1)
  announceToAll(('^3Récompense TikTok^7: %s x%d pour ^5%s^7'):format(pick.name, pick.count or 1, xPlayer.getName()))
end

local function doShoutout(viewer, what)
  local template = (Config.Actions.SHOUTOUT and Config.Actions.SHOUTOUT.template) or '^6[TikTok]^7 Merci %s pour %s'
  announceToAll(template:format(viewer or 'viewer', what or 'le soutien'))
end

local function doVehicleDrop(cleanupSeconds)
  local targetSrc = getAnyStreamerSource()
  if not targetSrc then
    dbg('Aucun streamer en ligne pour VEHICLE_DROP')
    return
  end

  local xPlayer = ESX.GetPlayerFromId(targetSrc)
  dbg('VEHICLE_DROP -> target src=%s name=%s', tostring(targetSrc), xPlayer and xPlayer.getName() or '??')

  local models = Config.VehicleDropModels or {}
  if #models == 0 then
    dbg('Aucun véhicule configuré pour VEHICLE_DROP')
    return
  end

  local model = models[math.random(1, #models)]
  dbg('VEHICLE_DROP -> model=%s cleanup=%s', tostring(model), tostring(cleanupSeconds or 120))

  TriggerClientEvent('ducratif_tiktok:vehicleDrop', targetSrc, model, cleanupSeconds or 120)
  announceToAll(('^6[TikTok]^7 Drop de véhicule ^5%s^7 pour %s !'):format(
    model, xPlayer and xPlayer.getName() or ('src ' .. tostring(targetSrc))
  ))
end


local function doHealingAura(seconds, radius, tick, heal)
  local targetSrc = getAnyStreamerSource()
  if not targetSrc then return end
  TriggerClientEvent('ducratif_tiktok:healingAura', -1, targetSrc, seconds or 30, radius or 6.0, tick or 500, heal or 2)
  announceToAll('^6[TikTok]^7 Aura de soin autour du streamer !')
end

local function doHealStreamer()
  local targetSrc = getAnyStreamerSource()
  if not targetSrc then
    dbg('Aucun streamer trouvé pour HEAL_STREAMER')
    return
  end
  TriggerClientEvent('ducratif_tiktok:healStreamer', targetSrc)
  announceToAll('^6[TikTok]^7 Vous avez soigné le streamer !')
end


--SI PAS LE JOB ABULANCE_JOB
--local function doReviveStreamer()
--  local targetSrc = getAnyStreamerSource()
--  if not targetSrc then
--    dbg('Aucun streamer trouvé pour REVIVE_STREAMER')
--    return
--  end
--  TriggerClientEvent('ducratif_tiktok:reviveStreamer', targetSrc)
--  announceToAll('^6[TikTok]^7 Les viewers sont des DIEUX !')
--end

local function doReviveStreamer()
  local targetSrc = getAnyStreamerSource()
  if not targetSrc then
    dbg('Aucun streamer trouvé pour REVIVE_STREAMER')
    return
  end

  -- Si esx_ambulancejob est démarré, on utilise son revive
  local ambState = GetResourceState and GetResourceState('esx_ambulancejob') or 'missing'
  if ambState == 'started' then
    -- 1) Event client standard (la plupart des versions l’écoutent)
    TriggerClientEvent('esx_ambulancejob:revive', targetSrc)

    -- 2) (Optionnel) certaines versions n’ont que la commande /revive
    --    Décommente si besoin :
    -- ExecuteCommand(('revive %d'):format(targetSrc))

    dbg('REVIVE_STREAMER via esx_ambulancejob (src=%s)', tostring(targetSrc))
    return
  end

  -- Fallback générique (ton event custom qui marche partout)
  TriggerClientEvent('ducratif_tiktok:reviveStreamer', targetSrc)
  dbg('REVIVE_STREAMER via fallback custom (src=%s)', tostring(targetSrc))
end


--=====

--Ejecte le streamer de la voiture
local function doEjectStreamer()
  local targetSrc = getAnyStreamerSource()
  if not targetSrc then
    dbg('Aucun streamer trouvé pour EJECT_STREAMER')
    return
  end
  TriggerClientEvent('ducratif_tiktok:ejectStreamer', targetSrc)
end

--=====


local function doConfettiAll(rounds)
  TriggerClientEvent('ducratif_tiktok:confettiAll', -1, rounds or 10)
end

local function applyAction(key, meta)
  local def = Config.Actions[key]
  if not def then dbg('Action inconnue: %s', tostring(key)) return end
  if def.type == 'fireworks' then
    doFireworks(def.rounds, def.radius)
  elseif def.type == 'buff_ped_speed' then
    TriggerClientEvent('ducratif_tiktok:speedBoostPed', -1, def.seconds, def.mult)
  elseif def.type == 'buff_vehicle_speed' then
  TriggerClientEvent('ducratif_tiktok:speedBoostVeh', -1, def.seconds, def.power, def.torque, def.max_kmh)
  elseif def.type == 'give_all_money' then
    local amount = def.amount
    if meta and meta.label then
      local n = tonumber((meta.label:match('^(%d+) likes') or '') )  -- récup le palier
      if n then amount = math.floor((def.amount or 100) * (n / (Config.LikeBase or 1000))) end
    end
    doMoneyRainAll(amount, def.reason)
  elseif def.type == 'give_random_item' then
    doGiveRandomItemToRandomPlayer(def.pool)
  elseif def.type == 'announce' then
    doShoutout(meta and meta.viewer, meta and (meta.label or meta.what))
  elseif def.type == 'vehicle_drop_streamer' then
    doVehicleDrop(def.cleanup_seconds)
  elseif def.type == 'healing_aura' then
    doHealingAura(def.seconds, def.radius, def.tick, def.heal)
  elseif def.type == 'heal_streamer' then
    doHealStreamer()
  elseif def.type == 'revive_streamer' then
    doReviveStreamer()
  elseif def.type == 'eject_streamer' then
    doEjectStreamer()


  elseif def.type == 'spawn_fan' then
     local viewer = meta and (meta.viewer or meta.label) or 'viewer'
     doSpawnFanPed(viewer, def.cleanup_seconds)
  elseif def.type == 'confetti' then
    doConfettiAll(def.rounds)
  else
    dbg('Type non géré: %s', tostring(def.type))
  end
end

-- ========== HTTP Handler (PATCH) ==========
-- Accepte: POST JSON sur /ducratif_tiktok/hook ou /hook
-- Body: {"action":"FIREWORKS","meta":{...}}
-- Fallback test: /hook?action=FIREWORKS
SetHttpHandler(function(req, res)
  if req.method ~= 'POST' then
    res.writeHead(405); res.send('method not allowed'); return
  end

  if req.path ~= '/ducratif_tiktok/hook' and req.path ~= '/hook' then
    res.writeHead(404); res.send('not found'); return
  end

  -- Sécurité
  local token = (req.headers and (req.headers['x-token'] or req.headers['X-Token'])) or ''
  if token ~= Config.SharedSecret then
    res.writeHead(401); res.send('unauthorized'); return
  end

  -- Récup du body (peut être appelé plusieurs fois)
  local body = ''
  req.setDataHandler(function(data)
    if data and #data > 0 then body = body .. data end
  end)

  -- Traite une fois tout reçu (petit délai pour être sûr)
  Citizen.SetTimeout(50, function()
    local data = {}
    if body ~= '' then
      local ok, parsed = pcall(json.decode, body)
      if ok and type(parsed) == 'table' then
        data = parsed
      end
    end

    -- Fallback: query string si pas d'action dans le body
    if not data.action or data.action == '' then
      -- Ex: /hook?action=FIREWORKS
      if req.address and req.address.query then
        data.action = req.address.query['action']
      end
    end

    if Config.Debug then
      print(('[ducratif_tiktok] Webhook body (%d bytes): %s'):format(#body, body ~= '' and body or '<empty>'))
      print(('[ducratif_tiktok] Action: %s'):format(tostring(data.action)))
    end

    if not data.action then
      res.writeHead(400); res.send('missing action'); return
    end

    applyAction(data.action, data.meta)
    res.writeHead(200, { ['Content-Type'] = 'application/json' })
    res.send('{"ok":true}')
  end)
end)



--============
--Action FanPed
doSpawnFanPed = function(label, cleanupSeconds)
  local targetSrc = getAnyStreamerSource()
  if not targetSrc then
    dbg('Aucun streamer pour FAN_PED'); return
  end

  -- pick aléatoire
  local models = Config.FanPedModels or {}
  local outfits = Config.FanPedOutfits or {}
  if #models == 0 then dbg('FanPed: aucun model config'); return end
  local model = models[math.random(1, #models)]
  local outfit = (#outfits > 0) and outfits[math.random(1, #outfits)] or {}

  TriggerClientEvent('ducratif_tiktok:spawnFanPed', targetSrc, {
    model = model,
    outfit = outfit,
    label = label or 'viewer',
    followSrc = targetSrc,
    cleanup = cleanupSeconds or (Config.Actions.FAN_PED and Config.Actions.FAN_PED.cleanup_seconds) or 300
  })
  dbg('FAN_PED -> model=%s label=%s', tostring(model), tostring(label or 'viewer'))
end


--===============
--Debug commands in-game

--/tt_ids
--Réponse: OUI si streamer connu

-- /tt_ids : affiche tes IDs vus par le serveur + si tu es reconnu streamer
RegisterCommand('tt_ids', function(source)
  if not Config.EnableTtIds then
    if source ~= 0 then
      TriggerClientEvent('chat:addMessage', source, {
        args = { 'TikTok', '^1Commande désactivée par la configuration.' }
      })
    else
      print('[ducratif_tiktok] /tt_ids désactivée dans le config.')
    end
    return
  end

  local xPlayer = ESX.GetPlayerFromId(source)
  if not xPlayer then
    print('[ducratif_tiktok] /tt_ids depuis console -> rien')
    return
  end

  local ids = collectAllIds(xPlayer)
  local ok = isStreamer(xPlayer)

  TriggerClientEvent('chat:addMessage', source, { args = { 'TikTok', ('^3IDs:^7 %s'):format(table.concat(ids, ', ')) } })
  TriggerClientEvent('chat:addMessage', source, { args = { 'TikTok', ('Reconnu streamer ? ^2%s^7'):format(ok and 'OUI' or 'NON') } })
end, false)




--===
-- /tt_drop : force un drop véhicule sur le streamer (toi)
RegisterCommand('tt_drop', function(src)
    if not Config.EnableTtDrop then
        if src ~= 0 then
            TriggerClientEvent('chat:addMessage', src, {
                args = { 'TikTok', '^1Commande désactivée par la configuration.' }
            })
        else
            print('[ducratif_tiktok] /tt_drop désactivée dans le config.')
        end
        return
    end

    if src == 0 then
        print('[ducratif_tiktok] /tt_drop ne peut pas être utilisé depuis la console.')
        return
    end

    doVehicleDrop(120)
end, false)



--===
-- /tt_healstreamer : soigne le streamer
RegisterCommand('tt_healstreamer', function(src, args, raw)
  if not Config.EnableTtHealStreamer then
    if src ~= 0 then
      TriggerClientEvent('chat:addMessage', src, {
        args = { 'TikTok', '^1Commande désactivée par la configuration.' }
      })
    else
      print('[ducratif_tiktok] /tt_healstreamer désactivée dans le config.')
    end
    return
  end

  if src == 0 then
    doHealStreamer()
  else
    local msg = raw and raw:lower() or ''
    if msg:find('!healme') then
      doHealStreamer()
    end
  end
end, false)