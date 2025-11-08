local function ensurePtfx(asset)
  if not HasNamedPtfxAssetLoaded(asset) then
    RequestNamedPtfxAsset(asset)
    while not HasNamedPtfxAssetLoaded(asset) do Wait(0) end
  end
end

local function loadModel(model)
  local hash = (type(model) == 'number') and model or GetHashKey(model)
  if not IsModelInCdimage(hash) then return nil end
  RequestModel(hash)
  local waitTime = GetGameTimer() + 5000
  while not HasModelLoaded(hash) and GetGameTimer() < waitTime do
    Wait(0)
  end
  if not HasModelLoaded(hash) then return nil end
  return hash
end

RegisterNetEvent('ducratif_tiktok:fireworksAtStreamer', function(rounds, radius, streamerSrc)
  rounds = rounds or 3
  radius = radius or 6.0

  local targetCoords
  if streamerSrc and GetPlayerFromServerId(streamerSrc) ~= -1 then
    local ped = GetPlayerPed(GetPlayerFromServerId(streamerSrc))
    targetCoords = GetEntityCoords(ped)
  else
    targetCoords = GetEntityCoords(PlayerPedId())
  end

  ensurePtfx('scr_indep_fireworks')
  for i=1, rounds do
    local angle = math.random() * math.pi * 2
    local dist  = math.random() * radius
    local off   = vector3(math.cos(angle)*dist, math.sin(angle)*dist, 0.0)
    UseParticleFxAssetNextCall('scr_indep_fireworks')
    StartParticleFxNonLoopedAtCoord('scr_indep_firework_starburst', targetCoords.x+off.x, targetCoords.y+off.y, targetCoords.z+1.5, 0.0, 0.0, 0.0, 1.0, false, false, false)
    Wait(500)
  end
end)

--===============================================================
RegisterNetEvent('ducratif_tiktok:speedBoost', function(seconds, mult)
    seconds = seconds or 60
    mult = mult or 1.15
    local ped = PlayerPedId()

    -- on boost directement la vitesse du joueur via sprint multiplier (clampé max ~1.49)
    local pid = PlayerId()
    SetRunSprintMultiplierForPlayer(pid, math.min(mult, 1.49))
    SetSwimMultiplierForPlayer(pid, math.min(mult, 1.49))

    -- en plus on force un mega boost de mouvement si mult > 1.49
    if mult > 1.49 then
        SetPedMoveRateOverride(ped, mult / 1.49)  -- ex: 3.0 = ~3x plus vite
        SetRunSprintMultiplierForPlayer(pid, 1.49)
        SetSwimMultiplierForPlayer(pid, 1.49)
    end

    Wait(seconds * 1000)

    -- reset clean
    SetRunSprintMultiplierForPlayer(pid, 1.0)
    SetSwimMultiplierForPlayer(pid, 1.0)
    SetPedMoveRateOverride(ped, 1.0)
end)
--==================================================================

--Boost a pied
RegisterNetEvent('ducratif_tiktok:speedBoostPed', function(seconds, mult)
  seconds = seconds or 10
  mult = mult or 5.0
  local ped = PlayerPedId()
  local pid = PlayerId()

  -- limite native 1.49 + override pour gros boosts
  local runMult = math.min(mult, 1.49)
  SetRunSprintMultiplierForPlayer(pid, runMult)
  SetSwimMultiplierForPlayer(pid, runMult)

  if mult > 1.49 then
    SetPedMoveRateOverride(ped, mult / 1.49) -- 10.0 => ~10x
  end

  Wait(seconds * 1000)

  -- reset
  SetRunSprintMultiplierForPlayer(pid, 1.0)
  SetSwimMultiplierForPlayer(pid, 1.0)
  SetPedMoveRateOverride(ped, 1.0)
end)

--Boost en vehicule
RegisterNetEvent('ducratif_tiktok:speedBoostVeh', function(seconds, power, torque, maxKmh)
  seconds = seconds or 10
  power   = power   or 100.0  -- 0..100 (au-delà instable)
  torque  = torque  or 3.0    -- x3 couple (au-delà clownesque)
  maxKmh  = maxKmh  or 500.0  -- cap vitesse (km/h). Mets 9999 pour quasi-sans limite.

  local ped = PlayerPedId()
  local veh = GetVehiclePedIsIn(ped, false)
  if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then
    -- pas conducteur -> on ignore
    return
  end

  -- applique le boost
  SetVehicleEnginePowerMultiplier(veh, power)
  SetVehicleEngineTorqueMultiplier(veh, torque)
  local maxSpeedMs = (maxKmh / 3.6)
  SetEntityMaxSpeed(veh, maxSpeedMs)

  Wait(seconds * 1000)

  -- reset
  if DoesEntityExist(veh) then
    SetVehicleEnginePowerMultiplier(veh, 0.0)
    SetVehicleEngineTorqueMultiplier(veh, 1.0)
    SetEntityMaxSpeed(veh, 1000.0) -- remet large
  end
end)


--======================

-- Spawn d'un véhicule pour le streamer (local -> networked)
RegisterNetEvent('ducratif_tiktok:vehicleDrop', function(model, cleanupSeconds)
  local ped = PlayerPedId()
  local coords = GetEntityCoords(ped)
  local fwd = GetEntityForwardVector(ped)
  local spawn = coords + fwd * 4.0

  local hash = loadModel(model)
  if not hash then
    print('[ducratif_tiktok] Model invalide: '..tostring(model))
    return
  end

  local veh = CreateVehicle(hash, spawn.x, spawn.y, spawn.z, GetEntityHeading(ped), true, true)
  SetVehicleNumberPlateText(veh, 'TIKTOK')
  SetEntityAsMissionEntity(veh, true, true)
  SetVehicleOnGroundProperly(veh)
  SetVehicleColours(veh, 111, 111)
  TaskWarpPedIntoVehicle(ped, veh, -1)
  SetModelAsNoLongerNeeded(hash)

  -- Cleanup automatique
  if cleanupSeconds and cleanupSeconds > 0 then
    CreateThread(function()
      Wait(cleanupSeconds * 1000)
      if DoesEntityExist(veh) then
        SetEntityAsMissionEntity(veh, false, true)
        DeleteEntity(veh)
      end
    end)
  end

  -- petit effet confetti sur le drop
  ensurePtfx('scr_indep_fireworks')
  UseParticleFxAssetNextCall('scr_indep_fireworks')
  StartParticleFxNonLoopedOnEntity('scr_indep_firework_trailburst', veh, 0.0, 0.0, 0.5, 0.0, 0.0, 0.0, 1.0, false, false, false)
end)

-- Aura de soin autour du streamer
RegisterNetEvent('ducratif_tiktok:healingAura', function(streamerSrc, seconds, radius, tick, heal)
  local endTime = GetGameTimer() + (seconds or 30000)
  radius = radius or 6.0
  tick = tick or 500
  heal = heal or 2

  local function isNearStreamer()
    if streamerSrc and GetPlayerFromServerId(streamerSrc) ~= -1 then
      local ped = GetPlayerPed(GetPlayerFromServerId(streamerSrc))
      local me = PlayerPedId()
      local p1, p2 = GetEntityCoords(ped), GetEntityCoords(me)
      return #(p1 - p2) <= radius, p1
    end
    return false, GetEntityCoords(PlayerPedId())
  end

  while GetGameTimer() < endTime do
    local near, pos = isNearStreamer()
    if near then
      local me = PlayerPedId()
      local hp = GetEntityHealth(me)
      if hp < 200 then
        SetEntityHealth(me, math.min(200, hp + heal))
      end
      -- petit marker de zone
      DrawMarker(1, pos.x, pos.y, pos.z - 1.0, 0.0,0.0,0.0, 0.0,0.0,0.0, radius*2.0, radius*2.0, 1.0, 0, 255, 100, 100, false, true, 2, nil, nil, false)
    end
    Wait(tick)
  end
end)

--Soigne le streamer
RegisterNetEvent('ducratif_tiktok:healStreamer', function()
  local ped = PlayerPedId()
  SetEntityHealth(ped, 200) -- full vie
  -- petit effet visuel
  ensurePtfx('scr_indep_fireworks')
  UseParticleFxAssetNextCall('scr_indep_fireworks')
  StartParticleFxNonLoopedOnEntity('scr_indep_firework_trailburst', ped, 0.0, 0.0, 0.8, 0.0, 0.0, 0.0, 1.0, false, false, false)
end)


--Revive le streamer
RegisterNetEvent('ducratif_tiktok:reviveStreamer', function()
  local ped = PlayerPedId()
  local coords = GetEntityCoords(ped)
  local heading = GetEntityHeading(ped)

  -- Si mort/agonisant, on ressuscite proprement
  if IsPedDeadOrDying(ped, true) or GetEntityHealth(ped) <= 101 then
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
    ClearPedTasksImmediately(ped)
    ClearPedBloodDamage(ped)
    AnimpostfxStopAll()
    StopAllScreenEffects()
  end

  -- Remet full vie/armure, enlève ragdoll
  SetEntityHealth(ped, 200)
  SetPedArmour(ped, 100)
  ResetPedRagdollTimer(ped)
  SetPedCanRagdoll(ped, true)

  -- Petit effet visuel pour feedback
  ensurePtfx('scr_indep_fireworks')
  UseParticleFxAssetNextCall('scr_indep_fireworks')
  StartParticleFxNonLoopedOnEntity('scr_indep_firework_trailburst', ped, 0.0, 0.0, 0.8, 0.0, 0.0, 0.0, 1.0, false, false, false)
end)


-- Ejecte le streamer de la voiture
RegisterNetEvent('ducratif_tiktok:ejectStreamer', function()
  local ped = PlayerPedId()
  local veh = GetVehiclePedIsIn(ped, false)
  if veh == 0 then return end

   -- Vérifie conducteur seulement si Config le demande
  if Config.EjectOnlyDriver and GetPedInVehicleSeat(veh, -1) ~= ped then
    return
  end
  
  -- On récupère la direction et la vitesse du véhicule
  local fwd = GetEntityForwardVector(veh)
  local vX, vY, vZ = table.unpack(GetEntityVelocity(veh))
  local vx = vX + fwd.x * 8.0
  local vy = vY + fwd.y * 8.0
  local vz = math.max(vZ + 6.0, 6.0)

  -- Position d’éjection: légèrement devant et au-dessus du capot
  local pos = GetEntityCoords(veh)
  local ejectPos = vector3(pos.x + fwd.x * 2.5, pos.y + fwd.y * 2.5, pos.z + 0.8)

  -- Sortie brutale + ragdoll + projection
  ClearPedTasksImmediately(ped)
  TaskLeaveVehicle(ped, veh, 4160) -- flags: leave violently
  Wait(0)
  SetEntityCoordsNoOffset(ped, ejectPos.x, ejectPos.y, ejectPos.z, false, false, false)
  SetPedToRagdoll(ped, 3000, 3000, 0, false, false, false)
  SetEntityVelocity(ped, vx, vy, vz)

  -- petit feedback visuel
  ensurePtfx('scr_indep_fireworks')
  UseParticleFxAssetNextCall('scr_indep_fireworks')
  StartParticleFxNonLoopedOnEntity('scr_indep_firework_trailburst', ped, 0.0, 0.0, 0.8, 0.0, 0.0, 0.0, 1.0, false, false, false)
end)



-- Confettis pour tous
RegisterNetEvent('ducratif_tiktok:confettiAll', function(rounds)
  rounds = rounds or 10
  local me = PlayerPedId()
  local pos = GetEntityCoords(me)
  ensurePtfx('scr_indep_fireworks')
  for i=1, rounds do
    UseParticleFxAssetNextCall('scr_indep_fireworks')
    StartParticleFxNonLoopedAtCoord('scr_indep_firework_trailburst', pos.x, pos.y, pos.z + 1.2, 0.0, 0.0, 0.0, 1.0, false, false, false)
    Wait(250)
  end
end)



--==================================
--Action FanPed
local FanPeds = {} -- { entity=ped, label="name", cleanup=ms, followSrc=serverId }

local function applyOutfit(ped, outfit)
  if not outfit then return end
  for comp, v in pairs(outfit) do
    if v and v.draw then
      SetPedComponentVariation(ped, tonumber(comp), v.draw or 0, v.tex or 0, 0)
    end
  end
end

local function draw3DText(pos, text)
  SetDrawOrigin(pos.x, pos.y, pos.z, 0)
  SetTextScale(0.35, 0.35)
  SetTextFont(0)
  SetTextProportional(1)
  SetTextOutline()
  SetTextColour(255,255,255,215)
  SetTextCentre(1)
  BeginTextCommandDisplayText('STRING')
  AddTextComponentSubstringPlayerName(text)
  EndTextCommandDisplayText(0.0, 0.0)
  ClearDrawOrigin()
end

--Event de spawn + suivi + cleanup
RegisterNetEvent('ducratif_tiktok:spawnFanPed', function(data)
  local model = data.model or 'a_m_m_business_01'
  local outfit = data.outfit or {}
  local label = data.label or 'viewer'
  local followSrc = data.followSrc
  local cleanup = (data.cleanup or 300)

  local hash = GetHashKey(model)
  if not IsModelInCdimage(hash) then print('[fanped] model invalide', model) return end
  RequestModel(hash); while not HasModelLoaded(hash) do Wait(0) end

  local me = PlayerPedId()
  local myCoords = GetEntityCoords(me)
  local spawn = myCoords + GetEntityForwardVector(me) * 2.5
  local ped = CreatePed(4, hash, spawn.x, spawn.y, spawn.z, GetEntityHeading(me), true, true)
  SetModelAsNoLongerNeeded(hash)
  SetPedFleeAttributes(ped, 0, true)
  SetBlockingOfNonTemporaryEvents(ped, true)
  SetPedCanRagdoll(ped, false)
  SetEntityAsMissionEntity(ped, true, true)

  applyOutfit(ped, outfit)

  table.insert(FanPeds, { entity = ped, label = label, followSrc = followSrc, cleanup = GetGameTimer() + cleanup*1000 })

  -- tâche de suivi
  CreateThread(function()
    while DoesEntityExist(ped) do
      local tgt = (followSrc and GetPlayerFromServerId(followSrc) ~= -1) and GetPlayerPed(GetPlayerFromServerId(followSrc)) or me
      TaskFollowToOffsetOfEntity(ped, tgt, 0.0, -1.0, 0.0, 2.0, -1, 1.0, true)
      Wait(1500)
    end
  end)

  -- cleanup
  CreateThread(function()
    while DoesEntityExist(ped) and GetGameTimer() < (GetGameTimer() + cleanup*1000) do
      Wait(1000)
    end
    if DoesEntityExist(ped) then
      DeleteEntity(ped)
    end
  end)
end)

--Loop d'affiche des pseudos au dessus des peds
CreateThread(function()
  while true do
    local now = GetGameTimer()
    for i=#FanPeds,1,-1 do
      local fp = FanPeds[i]
      if not DoesEntityExist(fp.entity) or now >= fp.cleanup then
        if DoesEntityExist(fp.entity) then DeleteEntity(fp.entity) end
        table.remove(FanPeds, i)
      else
        local pos = GetEntityCoords(fp.entity) + vector3(0.0, 0.0, 1.1)
        draw3DText(pos, ('~p~%s'):format(fp.label))
      end
    end
    Wait(0)
  end
end)



--================================================
AddEventHandler('ducratif_tiktok:vehicleDrop', function()
  print('[ducratif_tiktok] vehicleDrop reçu (client)')
end)


--=============================
CreateThread(function()
    Wait(1000) -- délai pour pas spam au tout début
    print("===============================================")
    print("   🎥  TikTok: Ducratifoff  |  YouTube: DucraDev")
    print("   💬  Discord: Ducratif   |  Github: Ducratif")
    print("   🔗  https://discord.gg/kpD8pQBBWm")
    print("===============================================")
    print("[ducratif_tiktok] Script client chargé ✅")
end)
