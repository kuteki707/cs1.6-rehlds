# CS 1.6 ReHLDS Server

Containerized Counter-Strike 1.6 ReHLDS environment optimized for low-latency hosting. Includes ReGameDLL, AMX Mod X, Metamod-r, server-side anticheat (WHBlocker + ReAimDetector), and an Nginx FastDL sidecar for instant map downloads.

## Architecture & Stack
*   **Game Server:** `kuteki/cs1.6-rehlds:1.2`
*   **FastDL Server:** `nginx:alpine` sidecar serving UDP-throttled assets over TCP/80.
*   **Engine:** ReHLDS + ReGameDLL (optimized tickrates, fixed engine exploits).
*   **Auth Module:** Reunion (Supports mixed Steam / Non-Steam topologies).
*   **Anticheat:** 
    *   **WHBlocker:** Server-side geometry culling (prevents ESP/Wallhacks).
    *   **ReAimDetector:** Heuristic aimbot and NoSpread telemetry tracking.

## Deployment

1. Clone the repository.
2. Update the `sv_downloadurl` in `./config/server.cfg` to match your host's IP for FastDL routing.
3. Generate a secure `SteamIdHashSalt` in `./config/reunion.cfg`.
4. Deploy the stack:
```bash
   docker compose up -d
```