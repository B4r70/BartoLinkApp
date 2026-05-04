# DBTicker-Erweiterungen — Architektur-Skizze

**Stand:** 04.05.2026
**Erweiterungen:** (1) Trip-Gruppierung in der Inbox, (2) Manueller Refresh-Button

---

## Ausgangslage (was ich im Code gesehen habe)

```
┌──────────────────────────────────────────────────────────────────┐
│  systemd-Timer (alle 5 Min, Mo-Fr)                               │
│    └─> dbticker.service (oneshot)                                │
│         └─> src/main.py                                          │
│              ├─ Config + State (JSON in /var/lib/dbticker/)      │
│              ├─ pro aktive Route: DB API → Checker → State       │
│              └─ ggf. notifier.py → POST /hooks/agent             │
│                                                                  │
│  OpenClaw (laufender Service)                                    │
│    └─> Agent formatiert Nachricht                                │
│         ├─> Telegram-Message                                     │
│         └─> BartoLink /push                                      │
│                                                                  │
│  BartoLink (laufender FastAPI-Service)                           │
│    └─> APNs → iOS-Device                                         │
│                                                                  │
│  iOS-App                                                         │
│    └─> Empfängt Push, speichert lokal in Inbox                   │
└──────────────────────────────────────────────────────────────────┘
```

**Wichtige Konsequenz:** Die Inbox in der iOS-App ist eine **lokale Sammlung
empfangener Pushes**. Es gibt aktuell keinen Server, der eine "Inbox" als
Resource pflegt und auslieferbar macht.

---

## Was sich daraus für die zwei Features ergibt

### Feature 1: Trip-Gruppierung

Zwei mögliche Wege:

#### Variante A: Client-seitige Gruppierung (lokale iOS-Logik)

Die iOS-App gruppiert ihre lokal gespeicherten Pushes selbst, anhand eines
`tripKey`-Feldes, das im Push-`meta` mitkommt.

**Pro:**
- Kein Server-Umbau nötig
- Funktioniert auch offline
- Schnell umgesetzt (1-2 Tage)

**Kontra:**
- Push-Spam bleibt: für jede Verspätungs-Änderung kommt weiterhin eine eigene
  Notification ins Banner (8 Banners statt 1).
- Wenn Push verloren geht, fehlt ein Eintrag in der History.

#### Variante B: Server-seitige Aggregation (BartoLink hält Trips)

BartoLink bekommt eine SQLite-Tabelle für Trips und stellt eine API bereit.
iOS holt sich die Inbox aus dieser API statt nur aus lokalem Push-Cache.

**Pro:**
- Server kann entscheiden: eine Push-Notification pro Trip (silent push für
  Updates, sichtbar nur bei "signifikanter" Änderung).
- History ist server-seitig vorhanden → App-Neuinstallation behält Daten.
- Voraussetzung für den Refresh-Button (Feature 2 braucht eh einen Endpoint).

**Kontra:**
- Mehr Aufwand (BartoLink wird mehr als nur Push-Gateway).
- iOS braucht eine API-Schicht.
- Bei Internet-Ausfall keine History sichtbar.

#### Empfehlung

**Variante B**, weil Feature 2 eh einen Server-Endpoint braucht. Wenn man B
für Feature 1 nicht macht, baut man die halbe Server-Logik trotzdem — dann
lieber gleich richtig.

---

### Feature 2: Manueller Refresh-Button

Drei Schichten:

```
[iOS Tap "Aktualisieren"]
        │
        ▼
[BartoLink: POST /trips/{tripKey}/refresh]
        │
        ├─ Rate-Limit-Check (1/60s pro Trip + 30/h global)
        │       └─ blockiert? → 429 + retryAfter
        │
        ├─ dbticker-Logik aufrufen für genau diesen Trip
        │
        ├─ Ergebnis in trip_updates speichern
        │
        ├─ falls "signifikant geändert" → Push raus
        │
        └─ 200 + neuer Trip-Stand zurück
```

**Wie ruft BartoLink dbticker auf?**

dbticker ist heute ein One-Shot-Skript ohne CLI-Argumente für "nur diese Route".
Es gibt drei Optionen (wie in der vorherigen Skizze diskutiert):

1. **Subprocess mit Single-Route-Modus**: `main.py --route hin-0631`. Schnell
   gebaut, aber pro Refresh ~1-2 Sek Subprocess-Startup.
2. **dbticker-Logik als Library**: `from dbticker import check_route_now`.
   Sauberer, BartoLink importiert direkt. Etwas mehr Refactoring.
3. **dbticker als laufender Worker mit Queue**: Overkill.

Für den Anfang: **Variante 1**. Wenn's nervt, später auf 2 umsteigen.

---

## Daten-Modell (Vorschlag für BartoLink)

### Neue Tabellen in BartoLink-SQLite

```sql
-- Eine konkrete Fahrt (Zugnummer + Datum)
CREATE TABLE trip_updates (
    trip_key            TEXT PRIMARY KEY,    -- z.B. "12623_2026-05-04"
    line                TEXT NOT NULL,       -- "RB23"
    train_number        TEXT NOT NULL,       -- "12623"
    direction           TEXT NOT NULL,       -- "Nassau(Lahn)"
    planned_departure   TEXT NOT NULL,       -- "16:16"
    current_status      TEXT NOT NULL,       -- "on_time" | "delayed" | "cancelled"
    current_delay_min   INTEGER,             -- NULL bei on_time / cancelled
    current_platform    TEXT,                -- z.B. "3"
    planned_platform    TEXT,                -- für Gleiswechsel-Erkennung
    last_update_at      TEXT NOT NULL,       -- ISO-Datum
    departure_station   TEXT,                -- "Niederlahnstein"
    arrival_station     TEXT                 -- "Bad Ems"
);

-- Jede einzelne Statusänderung (für History in DetailView)
CREATE TABLE trip_events (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    trip_key            TEXT NOT NULL REFERENCES trip_updates(trip_key),
    event_type          TEXT NOT NULL,       -- "delay" | "platform_change" | "cancelled" | "on_time"
    delay_min           INTEGER,
    platform            TEXT,
    message             TEXT,                -- Roh-Text (z.B. Messagecode-Beschreibung)
    received_at         TEXT NOT NULL        -- ISO-Datum
);

CREATE INDEX idx_trip_events_trip ON trip_events(trip_key, received_at DESC);

-- Rate-Limiting für /refresh
CREATE TABLE refresh_log (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    trip_key        TEXT,                    -- NULL bei globalem Throttle-Hit
    requested_at    TEXT NOT NULL,
    was_throttled   INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_refresh_log_recent ON refresh_log(requested_at DESC);
```

### Neue API-Endpoints in BartoLink

```
# Inbox-Liste (gruppiert pro Trip)
GET /trips
    Response: list[TripSummary]
    Sortiert: nach last_update_at DESC

# Einzelner Trip mit voller History
GET /trips/{trip_key}
    Response: { trip: TripDetail, events: list[TripEvent] }

# Manueller Refresh
POST /trips/{trip_key}/refresh
    200: { trip: TripDetail, refreshed_at, next_refresh_allowed_at }
    429: { retry_after_seconds, reason: "per_trip" | "global" }

# Neue Signal-Events von dbticker rein (statt /push direkt)
POST /trips/events
    Body: { trip_key, event_type, delay_min, platform, message, ... }
    → Server entscheidet, ob/wann Push raus geht
```

---

## Push-Strategie (Server-seitig)

Mit der neuen Architektur entscheidet **BartoLink** (nicht mehr dbticker), ob
ein Push-Banner sichtbar wird. Logik:

```python
def should_push_visible(prev_state, new_event):
    # Erste Meldung → ja
    if prev_state is None:
        return True

    # Statuswechsel → ja
    if new_event.status != prev_state.current_status:
        return True

    # Gleisänderung → JA (das ist der Edge-Case von vorhin!)
    if new_event.platform != prev_state.current_platform:
        return True

    # Verspätungs-Update nur, wenn Delta ≥ 3 Min
    if abs(new_event.delay_min - prev_state.current_delay_min) >= 3:
        return True

    # Sonst: silent update (Trip wird in DB aktualisiert, aber kein Banner)
    return False
```

Optional: Bei "silent update" trotzdem einen **silent Push** schicken (mit
`content-available: 1` und ohne `alert`), damit die iOS-App die Inbox im
Hintergrund refresht — aber kein Banner ploppt auf.

---

## Migrationspfad — empfohlene Reihenfolge

### Phase 1: BartoLink-Schema erweitern
- Neue Tabellen anlegen (Migration).
- `POST /trips/events`-Endpoint bauen.
- Aggregations-Logik: `event` rein → `trip_updates` upserten + `trip_events`
  einfügen.
- *Test:* Manuell ein paar fake-Events POSTen, DB-Inhalt prüfen.

### Phase 2: dbticker auf neuen Endpoint umstellen
- `notifier.py` ändert: statt OpenClaw-Hook direkt → `POST /trips/events` an
  BartoLink.
- `agent_prompt.py` wandert ggf. nach BartoLink (Telegram-Nachricht baut jetzt
  BartoLink, falls weiterhin gewünscht).
- **Wichtig:** Gleiswechsel mitsenden! In `state.py` `last_reported_platform`
  aufnehmen.
- *Test:* Einen Tag lang parallel laufen lassen, vergleichen mit alten Logs.

### Phase 3: iOS auf API umstellen
- `GET /trips` als Inbox-Quelle.
- DetailView holt sich `GET /trips/{trip_key}`.
- Push wird für Banner + Refresh-Trigger genutzt, aber nicht mehr als
  primäre Datenquelle.

### Phase 4: Refresh-Endpoint
- `POST /trips/{trip_key}/refresh` mit Rate-Limit.
- dbticker bekommt einen Single-Trip-Modus (`main.py --route ID`).
- iOS-Button + Cooldown-State.

---

## Offene Fragen, die ich vor dem Coden noch klären will

1. **Gleisänderung:** Speichert dbticker im aktuellen `state.py` schon das
   Gleis? Aus dem gesehenen Code: nein. Das müsste in Phase 2 mit rein.

2. **Trip-Key-Format:** `{train_number}_{date}` reicht, oder brauchen wir noch
   die Strecke (falls dieselbe Zugnummer auf zwei Routen läuft)?

3. **dbticker-Routen vs. Trip-Keys:** Ein dbticker-Eintrag in `routes.toml` ist
   eine *Pendlerroute* (z.B. "morgens hin"). Dahinter steht jeden Tag dieselbe
   Zugnummer. Mapping muss klar sein, damit der Refresh-Button auf dem Server
   weiß, welche Route in dbticker auszuführen ist.

4. **Push-Inhalt vs. Trip-Daten:** Aktuell formatiert OpenClaw-Agent die
   Telegram-Nachricht. Für iOS-Banner brauchen wir kürzeren, strukturierten
   Text. Bauen wir das in BartoLink, oder bleibt OpenClaw weiter dazwischen?

5. **History-Retention:** Wie lange `trip_events` aufheben? 30 Tage? Forever?

---

## TL;DR

- Beide Features hängen zusammen — Feature 2 erzwingt eine Server-API,
  Feature 1 wird durch dieselbe API massiv besser.
- BartoLink bekommt 3 neue Tabellen und 4 neue Endpoints.
- dbticker muss `notifier.py` umstellen + Gleis ins State aufnehmen +
  Single-Trip-Modus.
- iOS-App stellt Inbox auf API-Quelle um, behält Push für Banner-Trigger.
- Insgesamt 4 Phasen, jede Phase einzeln testbar und releasable.
