import 'dotenv/config'
import { TikTokLiveConnection, WebcastEvent } from 'tiktok-live-connector'

const USER = process.env.TIKTOK_USERNAME
const BASE = process.env.FIVEM_BASE || 'http://127.0.0.1:30120/ducratif_tiktok'
const TOKEN = process.env.SHARED_TOKEN
const LIKE_STEP = parseInt(process.env.LIKE_STEP || '1000', 10)
let likeBucket = 0

const FAN_STEP = parseInt(process.env.FAN_STEP || 20)
const likePerUser = new Map(); // key=uniqueId, value=compteur likes (mod FAN_STEP)

//----------------------------------
function envBool(key, def=false) {
  return /^true|1|yes|on$/i.test((process.env[key] || '').trim()) ? true : def;
}

const CONFETTI_CMD = envBool('CONFETTI_CMD');
const SPEED_BOOST_PED_CMD = envBool('SPEED_BOOST_PED_CMD');
const SPEED_BOOST_VEH_CMD = envBool('SPEED_BOOST_VEH_CMD');
const HEALING_AURA_CMD = envBool('HEALING_AURA_CMD');
const HEAL_STREAMER_CMD = envBool('HEAL_STREAMER_CMD');
const REVIVE_STREAMER_CMD = envBool('REVIVE_STREAMER_CMD');
const EJECT_STREAMER_CMD = envBool('EJECT_STREAMER_CMD');
const gift_role_cmd = envBool('gift_role_cmd');
//-------------------------------

// NE SURTOUT PAS TOUCHER !!!!!!
const CURRENT_VERSION = "1.0.0";
const VERSION_URL = "https://ducratif.github.io/ducratif_tiktok/version_node.txt";

async function checkVersion() {
  try {
    const res = await fetch(VERSION_URL, { signal: AbortSignal.timeout(5000) });
    if (!res.ok) {
      console.warn("⚠️ [ducratif_tiktok] Impossible de vérifier la version GitHub.");
      return;
    }
    const latest = (await res.text()).trim();
    if (latest !== CURRENT_VERSION) {
      console.log("=======================================");
      console.log("🚨 Nouvelle version du Bridge TikTok disponible !");
      console.log(`👉 Version actuelle : ${CURRENT_VERSION}`);
      console.log(`👉 Dernière version : ${latest}`);
      console.log("🔗 Téléchargez la mise à jour : https://github.com/Ducratif/ducratif_tiktok");
      console.log("=======================================");
    } else {
      console.log(`✅ [ducratif_tiktok] Vous êtes à jour (v${CURRENT_VERSION})`);
    }
  } catch (e) {
    console.warn("⚠️ [ducratif_tiktok] Erreur lors de la vérification de version :", e.message);
  }
}

//--------------------------------------

if (!USER) {
  console.error('Missing TIKTOK_USERNAME in .env')
  process.exit(1)
}
if (!TOKEN) {
  console.error('Missing SHARED_TOKEN in .env')
  process.exit(1)
}

async function send(action, meta = {}) {
  try {
    const res = await fetch(`${BASE}/hook`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-Token': TOKEN },
      body: JSON.stringify({ action, meta }),
      signal: AbortSignal.timeout(5000),
    })
    if (!res.ok) {
      console.error('HTTP', res.status, await res.text())
    }
  } catch (e) {
    console.error('HTTP error', e?.message || e)
  }
}

const conn = new TikTokLiveConnection(USER, {
  processInitialData: false,
  enableExtendedGiftInfo: true,
})

let giftCount = 0
let nextLikeMilestone = LIKE_STEP

// --- Events TikTok -> actions FiveM --- //
conn.on(WebcastEvent.CONNECTED, (state) => {
  console.log('✅ Connecté au live TikTok (roomId:', state.roomId, ')')
})
conn.on(WebcastEvent.DISCONNECTED, () => {
  console.warn('⚠️ Déconnecté de TikTok, nouvelle tentative dans 10s...')
  ttConnected = false
  setTimeout(connectTikTokOnce, 10_000)
})
conn.on(WebcastEvent.ERROR, (e) => console.error('TT error', e?.message || e))

conn.on(WebcastEvent.CHAT, (d) => {
  const comment = d.comment || ''
  const user = d.user?.uniqueId || 'viewer'
  if (/^!boostv\b/i.test(comment)) {
    // Boost véhicule TRÈS rapide
    if (SPEED_BOOST_VEH_CMD) {
      send('SPEED_BOOST_VEH', { viewer: user, label: '!boostv' })
    }
    else{console.log('Commande: !boostv désactiver')}
  }
  if (/^!boost\b/i.test(comment)) {
    // Boost à pied TRÈS rapide
    if (SPEED_BOOST_PED_CMD) {
      send('SPEED_BOOST_PED', { viewer: user, label: '!boost' })
    }
    else{console.log('Commande: !boost désactiver')}
  }
  if (/^!confetti\b/i.test(comment)) {
    if (CONFETTI_CMD) {
      send('CONFETTI_ALL', { viewer: user, label: '!confetti' })
    }
    else{console.log('Commande: !confetti désactiver')}
  }
  if (/^!heal\b/i.test(comment)) {
    if (HEALING_AURA_CMD) {
      send('HEALING_AURA', { viewer: user, label: '!heal' })
    }
    else{console.log('Commande: !heal désactiver')}
  }
  if (/^!healme\b/i.test(comment)) {
    // Soigne UNIQUEMENT le streamer (nouvelle action côté FiveM)
    if (HEAL_STREAMER_CMD) {
      send('HEAL_STREAMER', { viewer: user, label: '!healme' })
    }
    else{console.log('Commande: !healme désactiver')}
  }
  if (/^!revive\b/i.test(comment) || /^!reviveme\b/i.test(comment)) {
    // Réanime uniquement le streamer
    
    if (REVIVE_STREAMER_CMD) {
      send('REVIVE_STREAMER', { viewer: user, label: '!revive' })
    }
    else{console.log('Commande: !revive désactiver')}
  }
    if (/^!eject\b/i.test(comment) || /^!yeet\b/i.test(comment)) {
    // Éjecte violemment le streamer de son véhicule
    if (EJECT_STREAMER_CMD) {
        send('EJECT_STREAMER', { viewer: user, label: '!eject' })
    }
    else{console.log('Commande: !eject désactiver')}
  }



})

conn.on(WebcastEvent.GIFT, (d) => {
  giftCount++
  const gName = d?.gift?.name || d.giftName || 'gift'
  const user = d.user?.uniqueId || 'viewer'

  // Rose -> Drop véhicule
  if (/rose/i.test(gName)) {
    if (gift_role_cmd) {
      send('VEHICLE_DROP', { viewer: user, label: gName })
    }
    else{console.log('Action des roses désactiver')}
  } else {
    // autres cadeaux -> feux d’artifice
    if (gift_role_cmd) {
      send('VEHICLE_DROP', { viewer: user, label: gName })
      //send('FIREWORKS', { viewer: user, label: gName })
    }
    else{console.log('Action des roses désactiver')}
  }

  // palier toutes les 10 unités -> boost vitesse global
  if (giftCount % 10 === 0) {
    send('SPEED_BOOST', { viewer: 'milestone', label: `${giftCount} gifts` })
  }
})


conn.on(WebcastEvent.LIKE, (d) => {
  // --- Paliers globaux (argent, etc.) ---
  if (typeof d.totalLikeCount === 'number' && d.totalLikeCount > 0) {
    while (d.totalLikeCount >= nextLikeMilestone) {
      send('MONEY_RAIN_ALL', { label: `${nextLikeMilestone} likes` })
      send('CONFETTI_ALL',   { label: `${nextLikeMilestone} likes` })
      nextLikeMilestone += LIKE_STEP
    }
  } else {
    // fallback quand totalLikeCount n'est pas fourni
    likeBucket += (typeof d.likeCount === 'number' ? d.likeCount : 1)
    while (likeBucket >= LIKE_STEP) {
      likeBucket -= LIKE_STEP
      send('MONEY_RAIN_ALL', { label: `+${LIKE_STEP} likes` })
      //send('CONFETTI_ALL',   { label: `+${LIKE_STEP} likes` })
    }
  }

  // --- Fan ped: toutes les 20 likes (par défaut) PAR viewer ---
  const uid = d.user?.uniqueId || null
  if (uid) {
    const inc = (typeof d.likeCount === 'number' && d.likeCount > 0) ? d.likeCount : 1
    const prev = likePerUser.get(uid) || 0
    let rem = prev + inc

    while (rem >= FAN_STEP) {
      rem -= FAN_STEP
      // spawn d'un ped fan qui suit le streamer, label = pseudo du viewer
      send('FAN_PED', { viewer: uid, label: `${uid}` })
    }
    likePerUser.set(uid, rem)
  }
})


//=====================



conn.on(WebcastEvent.FOLLOW, (d) => {
  const user = d.user?.uniqueId || 'viewer'
  send('FOLLOW_REWARD', { viewer: user, label: 'follow' })
})

// --- Connexion TikTok gérée proprement (pas de double connect) --- //
let ttConnecting = false
let ttConnected = false
async function connectTikTokOnce() {
  if (ttConnected || ttConnecting) return
  ttConnecting = true
  try {
    const state = await conn.connect()
    ttConnected = true
    console.log('✅ Connecté au live TikTok (roomId:', state.roomId, ')')
  } catch (err) {
    // Si tu n’es pas en live, c’est normal d’avoir une erreur ici.
    console.error('❌ Erreur connexion TikTok:', err?.message || err)
  } finally {
    ttConnecting = false
  }
}

// --- Ping FiveM + retry tant que ça ne répond pas --- //
let fivemInterval = null
async function pingFiveM() {
  try {
    const res = await fetch(`${BASE}/hook`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-Token': TOKEN },
      body: JSON.stringify({ action: 'SHOUTOUT', meta: { viewer: 'System', label: 'Startup test' } }),
      signal: AbortSignal.timeout(5000),
    })
    if (res.ok) {
      console.log('✅ Serveur FiveM connecté (token OK)')
      if (fivemInterval) {
        clearInterval(fivemInterval)
        fivemInterval = null
      }
      return true
    } else {
      console.error('❌ Erreur FiveM:', res.status, await res.text())
    }
  } catch (e) {
    console.error('❌ Impossible de joindre FiveM:', e?.message || e)
  }
  return false
}

// --- Démarrage orchestré --- //
async function startup() {
  console.log('Developped By Ducratif -> Tiktok: ducratifoff')
  console.log('🚀 Lancement du bridge TikTok -> FiveM...')

  // 1) Ping FiveM (une fois, puis retry toutes les 10s si down)
  const ok = await pingFiveM()
  if (!ok && !fivemInterval) {
    fivemInterval = setInterval(pingFiveM, 10_000)
  }

  // 2) Connexion TikTok (une seule fois, auto-retry sur disconnect)
  await connectTikTokOnce()
}

startup()
checkVersion();