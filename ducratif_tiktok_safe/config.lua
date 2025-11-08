-- Source: https://github.com/Ducratif/ducratif_tiktok
-- Docs: https://ducratif.github.io/ducratif_tiktok

Config = {}

-- ========= SÉCURITÉ =========
-- Token partagé avec le bridge Node (header HTTP: X-Token)
Config.SharedSecret = 'TON_TOKEN_ICI'

-- Identifiers du/ des streamers (license:/steam:/charX:cfx ou autre)
Config.StreamerIdentifiers = {
    'char1:cf872e2dbff1cf3152fff72b147ca07238315148',
    'license2:cf872e2dbff1cf3152fff72b147ca07238315148',
    'steam:11000011799716e'
    -- 'license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    -- 'char1:cfx:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
}

-- Laisser true le temps des tests
Config.Debug = false




-- Activer ou désactiver les commandes chat FiveM
Config.EnableTtDrop = true  -- ou false pour désactiver /tt_drop
Config.EnableTtIds = true -- ou false pour désactiver /tt_ids
Config.EnableTtHealStreamer = true -- ou false pour désactiver /tt_healstreamer


-- true = uniquement si le streamer est conducteur
-- false = eject même s’il est passager
Config.EjectOnlyDriver = true

-- ========= ACTIONS =========
-- Liste des véhicules autorisés au "drop" (rose)
-- Fonctionne meme avec les véhicules "modder" s'ils sont ajouter sur votre serveur
-- Vérifier juste le nom, tester via la commande: /car NOM_VEHICULE
Config.VehicleDropModels = {
    'adder', 'schafter2', 'sultan', 'bati', 'dominator', 'buffalo', 'elegy', 'zentorno', 'rhino'
}


--------------------------------------------------
------NE PAS TOUCHER PRINCIPALEMENT !!!! SI VOUS FAITE N'IMPORTE QUOI CELA FONCTIONNERA PAS XD ET JE NE SUIS PAS RESPONSABLE--------
-- Récompenses/Actions pré-définies
Config.Actions = {
  FIREWORKS = { type = 'fireworks', rounds = 4, radius = 7.0 },

-- Boost à pied (méga rapide)
SPEED_BOOST_PED = { type = 'buff_ped_speed', seconds = 10, mult = 100.0 },

-- Boost véhicule (très rapide)
SPEED_BOOST_VEH = { type = 'buff_vehicle_speed', seconds = 20, power = 300.0, torque = 5.0, max_kmh = 990.0 },

  MONEY_RAIN_ALL  = { type = 'give_all_money', amount = 1000, reason = '1000 LIKE LES BG !!!' },
  FOLLOW_REWARD   = { type = 'give_random_item', pool = {
      { name = 'medikit', count = 1 },
      { name = 'water',   count = 2 },
      { name = 'bread',   count = 2 },
  }},

    SHOUTOUT        = { type = 'announce', template = '^6[TikTok - Ducratif]^7 Merci à ^5%s^7 pour %s !' },
    VEHICLE_DROP    = { type = 'vehicle_drop_streamer', cleanup_seconds = 120 }, -- Drop véhicule pour le streamer
    HEALING_AURA    = { type = 'healing_aura', seconds = 30, radius = 6.0, tick = 500, heal = 2 }, -- aura de soin autour du streamer
    CONFETTI_ALL    = { type = 'confetti', rounds = 10 }, -- confettis pour tous
    FAN_PED = { type = 'spawn_fan', cleanup_seconds = 300 }, -- -- Action “fan ped” 5 min de durée par défaut
    HEAL_STREAMER = { type = 'heal_streamer' }, -- Soigner le streamer
    REVIVE_STREAMER = { type = 'revive_streamer' }, -- Revive le streamer
    EJECT_STREAMER = { type = 'eject_streamer' }, -- Ejecte le streamer de la voiture

}





-- Spawn de ped + drawa (texte ped) + tenues ped
-- PEDs fans (modèles possibles)
Config.FanPedModels = {
  'a_m_m_business_01', 'a_m_m_skater_01', 'a_f_y_fitness_01', 'a_m_y_hipster_01'
}

-- Tenues possibles (aléatoires). Chaque entrée = un set de composants.
-- (drawables/textures pour 0..11. Laisse nil pour ne pas toucher)
Config.FanPedOutfits = {
  { -- tenue 1
    [3]={draw=0,tex=0},  [4]={draw=1,tex=0},  [6]={draw=1,tex=0},  [8]={draw=0,tex=0}, [11]={draw=1,tex=0}
  },
  { -- tenue 2
    [3]={draw=14,tex=0}, [4]={draw=10,tex=0}, [6]={draw=5,tex=0},  [8]={draw=15,tex=0},[11]={draw=5,tex=0}
  },
  { -- tenue 3
    [3]={draw=4,tex=0},  [4]={draw=4,tex=0},  [6]={draw=7,tex=0},  [8]={draw=1,tex=0}, [11]={draw=10,tex=0}
  }
}


