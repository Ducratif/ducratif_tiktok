# Ducratif TikTok x FiveM – Pack complet

## Contenu
- `ducratif_tiktok/` → ressource FiveM ESX Legacy
- `bridge_tiktok/`   → bridge Node.js qui lit ton live TikTok

---
## Installation (FiveM)
1. Copie le dossier `ducratif_tiktok` dans ton répertoire `resources/`.
2. Dans `server.cfg`, ajoute **après** ESX :
   ```
   ensure ducratif_tiktok
   ```
3. Ouvre `ducratif_tiktok/config.lua` :
   - Mets un **token fort** dans `Config.SharedSecret` (ex: long random).
   - Renseigne ton/tes `Config.StreamerIdentifiers` (license:/steam:/charX:cfx...).
   - Optionnel : modifie les récompenses, la liste des véhicules, etc.
4. (Firewall) Autorise le port HTTP du serveur (par défaut 30120) depuis la machine où tourne le bridge.

## Installation (Bridge Node)
1. Va dans `bridge_tiktok/` :
   ```bash
   npm i
   cp .env.example .env
   ```
2. Édite `.env` :
   - `TIKTOK_USERNAME` = ton pseudo TikTok (sans `@`).
   - `FIVEM_BASE` = `http://IP:30120/ducratif_tiktok` (ou `http://127.0.0.1:30120/ducratif_tiktok` si même machine).
   - `SHARED_TOKEN` = **le même** que `Config.SharedSecret`.
   - `LIKE_STEP` = 1000 (palier likes).
3. Lance :
   ```bash
   node index.js
   ```

## Test sans TikTok
```bash
curl -X POST http://127.0.0.1:30120/ducratif_tiktok/hook \
  -H "Content-Type: application/json" -H "X-Token: CHANGE-MOI-TRES-FORT" \
  -d '{"action":"FIREWORKS","meta":{"viewer":"test","label":"debug"}}'
```

## Événements inclus par défaut
- **Cadeau reçu** → feux d’artifice (FIREWORKS)
- **Rose** → **drop véhicule aléatoire** pour le streamer (VEHICLE_DROP)
- **Tous les 10 gifts** → boost de vitesse global 60s (SPEED_BOOST)
- **Likes palier (1000, 2000, …)** → pluie d’argent (MONEY_RAIN_ALL)
- **Follow** → récompense aléatoire à un joueur connecté (FOLLOW_REWARD)
- **Chat `!nitro`** → boost vitesse global
- **Chat `!confetti`** → confettis pour tous
- **Chat `!heal`** → aura de soin autour du streamer 30s

## Personnalisation rapide
- Modifie la liste des véhicules dans `Config.VehicleDropModels`.
- Change les montants/durées dans `Config.Actions`.
- Ajoute de nouvelles actions dans `server.lua` (cf. `applyAction`). Puis côté Node, envoie `send('NOUVELLE_ACTION', { ... })`.

## Conseils
- Utilise un **token fort** et n’expose pas le port 30120 publiquement si possible. Place le bridge sur la même machine (localhost).
- Si tu as ox_inventory/ox_lib, tu peux remplacer les giveaways par tes propres items/events très facilement dans `server.lua`.
