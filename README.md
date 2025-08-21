# 🎶 Bridge TikTok → FiveM (Node + ESX)  

> **Développé par Ducratif @2025** — TikTok **@ducratifoff**  
> Discord: **https://discord.gg/kpD8pQBBWm** • YouTube: **DucraDev** • GitHub: **Ducratif**

<p align="center">
  <a href="https://www.tiktok.com/@ducratifoff">
    <img src="https://img.shields.io/badge/TikTok-@ducratifoff-ff0050?style=for-the-badge&logo=tiktok&logoColor=white" />
  </a>
  <a href="https://discord.gg/kpD8pQBBWm">
    <img src="https://img.shields.io/badge/Discord-Join%20Us-5865F2?style=for-the-badge&logo=discord&logoColor=white" />
  </a>
  <a href="https://www.youtube.com/@DucraDev">
    <img src="https://img.shields.io/badge/YouTube-DucraDev-FF0000?style=for-the-badge&logo=youtube&logoColor=white" />
  </a>
  <a href="https://github.com/Ducratif">
    <img src="https://img.shields.io/badge/GitHub-Ducratif-333333?style=for-the-badge&logo=github&logoColor=white" />
  </a>
</p>

---
[![Docs](https://img.shields.io/badge/📖%20Documentation-Visiter%20la%20doc-ff0050?style=for-the-badge&logo=tiktok)](https://ducratif.github.io/ducratif_tiktok)
---

## 🧩 Features
- Lecture **temps réel** du **chat**, **likes**, **gifts**, **follows** TikTok.
- Envoi d’**actions FiveM** (HTTP webhook sécurisé) : confettis, boost(s) pied/veh, heal, revive, eject, drop véhicules, **fan ped** (ped suiveur avec pseudo), pluie d’argent, etc.
- **Config simple** (Node `.env` + FiveM `config.lua`).  
- **Toggles** pour (dés)activer des commandes côté Node **et** côté FiveM.  
- **Debug** verbeux optionnel + scripts de test PowerShell/curl.  

---

## ⚙️ Prérequis
**Node Bridge**
- Node.js ≥ 18
- `npm install`

**FiveM**
- ESX Legacy
- License CFX liée à votre compte

---

## 🔧 Configuration — Node Bridge
Copiez `.env.example` → `.env` puis définissez :

```
TIKTOK_USERNAME=VotrePseudoTikTok     # sans @
FIVEM_BASE=http://127.0.0.1:30120/ducratif_tiktok
SHARED_TOKEN=METTEZ_UN_GROS_TOKEN
LIKE_STEP=1000                        # palier global: argent + confettis (si activés)
FAN_STEP=50                           # toutes les 50 likes PAR VIEWER -> 1 fan ped
```

> **Tip env booléens (optionnel)** : vous pouvez créer des toggles pour vos commandes côté Node
> (ex: `CONFETTI_CMD=true`, `REVIVE_CMD=false`) et les lire avec un helper `envBool(key)`.

**Lancer**
```bash
npm i
node index.js
```
> Le bridge doit voir votre serveur FiveM + votre live TikTok. Il lit les events et envoie les actions via HTTP.

---

## 🔧 Configuration — FiveM
Dans `config.lua` :
- `Config.SharedSecret` : **identique** à `SHARED_TOKEN` côté Node (en-tête HTTP `X-Token`).
- `Config.StreamerIdentifiers` : mettez vos IDs (license/steam/cfx…) pour identifier le **streamer**.
- `Config.Debug` : `true` pour voir les logs du webhook et matching IDs.
- **Toggles commandes** :
  - `Config.EnableTtDrop` — active `/tt_drop`
  - `Config.EnableTtIds` — active `/tt_ids`
  - `Config.EnableTtHealStreamer` — active `/tt_healstreamer`
  - `Config.EjectOnlyDriver` — si `true`, `!eject` ne fonctionne que si le streamer **conduit**.
- **Véhicules drop** : `Config.VehicleDropModels` (supporte véhicules mod si présents sur le serveur).
- **Fan Peds** :
  - `Config.FanPedModels` : modèles de peds (cf. https://docs.fivem.net/docs/game-references/ped-models)
  - `Config.FanPedOutfits` : sets de tenues optionnels (si vous ne savez pas, laissez tel quel).
- **Actions** : _ne touchez pas si vous n’êtes pas sûr_.

**Start**
```txt
# server.cfg (ou équivalent)
ensure ducratif_tiktok
```

---

## 🔌 Webhook — Endpoints & Sécurité
- **Endpoints** acceptés : `POST /ducratif_tiktok/hook` **ou** `POST /hook`
- **Header obligatoire** : `X-Token: <Config.SharedSecret>`
- **Body** JSON : `{"action":"FIREWORKS", "meta":{ ... }}`  
  - Fallback possible via querystring : `/hook?action=FIREWORKS`
- Codes d’erreur courants :
  - `401 unauthorized` → mauvais token
  - `404 not found` → mauvais chemin (utilisez `/hook` si doute)
  - `400 bad request` → body vide (PowerShell : envoyez des **bytes** pour éviter le chunked)

---

## 🗺️ Matrice Événements → Actions (exemples)
| Événement TikTok | Action envoyée | Effet côté FiveM |
|---|---|---|
| `!confetti` (chat) | `CONFETTI_ALL` | Confettis pour tous |
| `!boost` | `SPEED_BOOST_PED` | Boost vitesse **à pied** |
| `!boostv` | `SPEED_BOOST_VEH` | Boost **véhicule** (conducteur) |
| `!heal` | `HEALING_AURA` | Aura de soin autour du streamer |
| `!healme` | `HEAL_STREAMER` | Soigne uniquement le streamer |
| `!revive` | `REVIVE_STREAMER` | Revive le streamer (ambulancejob si présent, sinon fallback) |
| `!eject` | `EJECT_STREAMER` | Éjecte violemment le streamer du véhicule |
| Gift “rose” | `VEHICLE_DROP` | Drop d’un véhicule au streamer |
| Likes palier (`LIKE_STEP`) | `MONEY_RAIN_ALL` (+ `CONFETTI_ALL` si activé) | Argent + confettis |
| Likes par viewer (`FAN_STEP`) | `FAN_PED` | Spawn d’un ped suiveur + pseudo |

---

## 💬 Commandes TikTok (par défaut)
```
!confetti   → Confettis autour du streamer
!boost      → Boost à pied
!boostv     → Boost en véhicule
!heal       → Heal joueurs proches du streamer
!healme     → Heal le streamer
!revive     → Revive le streamer
!eject      → Éjecte le streamer du véhicule
```

---

## 🧪 Tests rapides (PowerShell)

### 🎆 Feux d’artifice
```powershell
$uri = 'http://127.0.0.1:30120/ducratif_tiktok/hook'
$headers = @{ 'X-Token' = 'TON_TOKEN_ICI' }
$body = '{"action":"FIREWORKS","meta":{"viewer":"test","label":"debug"}}'
Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -ContentType 'application/json' -Body $body
```

### 🚗 Véhicule
```powershell
$uri = 'http://127.0.0.1:30120/ducratif_tiktok/hook'
$headers = @{ 'X-Token' = 'TON_TOKEN_ICI' }
$bodyObj = @{ action = 'VEHICLE_DROP'; meta = @{ viewer = 'test'; label = 'debug' } }
$bodyJson = ($bodyObj | ConvertTo-Json -Compress)
$bytes    = [System.Text.Encoding]::UTF8.GetBytes($bodyJson)
Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -ContentType 'application/json' -Body $bytes
```

### ⚡ Boost à pied
```powershell
$uri='http://127.0.0.1:30120/ducratif_tiktok/hook'
$h=@{ 'X-Token'='TON_TOKEN_ICI' }
$body='{"action":"SPEED_BOOST_PED","meta":{"viewer":"test"}}'
Invoke-RestMethod -Uri $uri -Method Post -Headers $h -ContentType 'application/json' -Body $body
```

### 🧍 Fan Ped + pseudo
```powershell
$uri = 'http://127.0.0.1:30120/ducratif_tiktok/hook'
$headers = @{ 'X-Token' = 'TON_TOKEN_ICI' }
$body = '{"action":"FAN_PED","meta":{"viewer":"test","label":"fanUser"}}'
$bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -ContentType 'application/json' -Body $bytes
```

> **Tip Windows** : pour `curl`, utilisez `curl.exe` (PowerShell alias `curl` = `Invoke-WebRequest`).  
> Exemple :
> ```powershell
> curl.exe -X POST http://127.0.0.1:30120/hook -H "X-Token: TON_TOKEN_ICI" -H "Content-Type: application/json" -d "{\"action\":\"FIREWORKS\"}"
> ```

---

## 🧯 Troubleshooting
- **“Aucun streamer en ligne”** : vérifiez `Config.StreamerIdentifiers` (tapez `/tt_ids` pour voir les IDs vus par le serveur).  
- **401 unauthorized** : token `X-Token` ≠ `Config.SharedSecret`.  
- **404** : utilisez `/hook` (sans préfixe) si votre ressource est renommée.  
- **400 body vide** : avec PowerShell, envoyez des **bytes** (`[System.Text.Encoding]::UTF8.GetBytes(...)`).  
- **Boost véhicule invisible** : vous devez être **conducteur**.  
- **Revive** : si `esx_ambulancejob` est **start**, l’event natif `esx_ambulancejob:revive` est utilisé, sinon **fallback** custom.

---

## ✨ Crédits
**Ducratif** — TikTok [@ducratifoff](https://www.tiktok.com/@ducratifoff) • YouTube [DucraDev](https://www.youtube.com/@DucraDev) • Discord [Ducratif](https://discord.gg/kpD8pQBBWm) • GitHub [Ducratif](https://github.com/Ducratif)
