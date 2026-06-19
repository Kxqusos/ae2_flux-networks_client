# AE2 + Flux Networks OpenComputers Client

Lua program for an OpenComputers computer that pushes Flux Networks energy stats and AE2
inventory/craftables (items and fluids) to a dashboard server, polls for pending orders, and
triggers AE2 autocraft. See the separate `dashboard` repo for the server this talks to.

## In-game requirements

- OpenComputers computer: CPU, RAM, an OS/EEPROM, **Internet Card**.
- **Adapter** facing the AE2 ME Controller (exposes `me_controller`/`me_interface`).
- **Adapter** facing the Flux Networks Controller (exposes the Flux component).

## Deployment

**One-command install (requires an Internet Card, with `raw.githubusercontent.com` allowed
in `opencomputers.cfg`'s http whitelist):**

```sh
wget -f https://raw.githubusercontent.com/Kxqusos/ae2_flux-networks_client/main/install.lua /home/install.lua && install
```

This downloads `json.lua`, `http.lua`, `flux.lua`, `ae2.lua`, `config.lua`, `main.lua` into
`/home/client/`. Re-running it later (e.g. `install`) updates everything except an existing
`config.lua` (your settings are preserved) — run `reboot` afterwards, since OpenComputers
caches loaded modules in memory for the whole boot session and won't pick up the new files
until the Lua VM restarts.

**Manual alternative** (no Internet Card / offline): copy all `.lua` files
(`json.lua`, `http.lua`, `flux.lua`, `ae2.lua`, `config.lua`, `main.lua`) into `/home/client/`
on the computer's filesystem via floppy disk or HDD.

Then:
1. Edit `/home/client/config.lua`: set `dashboard_url` to the dashboard's base URL and
   `api_token` to the value of the dashboard's `API_TOKEN` environment variable.
2. Run `cd /home/client && main` (or `lua main.lua`). It loops forever, polling every
   `poll_interval` seconds (default 60).

## Running tests (on your dev machine, not in-game)

```bash
luarocks install busted
busted
```

## API Contract (shared with the `dashboard` repo)

All requests carry header `Authorization: Bearer <api_token>`.
`kind` is `"item"` or `"fluid"` on every inventory/craftable/order entry. Fluid quantities are in mB.

- `POST /api/client/flux` — `{"energy_in", "energy_out", "buffer", "capacity"?}` → `{"ok": true}`
- `POST /api/client/inventory` — `{"items": [...], "craftables": [...]}` → `{"ok": true}`
- `GET /api/client/orders/pending` — → `{"orders": [{"id", "kind", "item", "label", "amount"}]}`
- `POST /api/client/orders/{id}/result` — `{"status": "requested"|"done"|"failed", "message"?}` → `{"ok": true}`

## In-game verification status

- `flux.lua`: **verified 2026-06-20.** Real `flux_controller` API uses `getEnergyInfo()`
  returning `{energyInput, energyOutput, totalBuffer, totalEnergy}`; no method exposes total
  network capacity, so `capacity` is always `nil`.
- `ae2.lua`: **verified 2026-06-20.** Real `me_controller` API matches the original placeholder
  exactly — `getItemsInNetwork`, `getFluidsInNetwork`, `getCraftables` all exist as named.
  Still unconfirmed: whether `craftable.request(amount)` uses plain-function or colon-method
  (`self`-first) call semantics — test this before relying on autocraft in production (see
  `ae2.lua`'s `find_craftable`/`request_craft`).
