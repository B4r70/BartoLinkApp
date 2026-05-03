# Handoff: BartoLink — Signal Light Redesign

## Overview

Designentwurf für die bestehende **BartoLink** iOS-App (SwiftUI). Das Redesign behält den Funktionsumfang (Push-Inbox, Notification-Detail mit Zug-Metadaten, Status-Diagnose), bringt aber:

- einen **klareren Aufbau** (Live-Hero oben, dichte Listen, KPI-Grids)
- den **bestehenden Pastell-Blau-Hintergrund** aus `Theme.swift`
- die **iOS System-Schriftart** (SF Pro / `.system`) — keine Custom-Fonts
- konsistente **Status-Chips** und farbige **Akzent-Kanten** für wichtige Karten

## About the Design Files

Die Dateien in diesem Ordner sind **Design-Referenzen, erstellt in HTML/React**. Sie zeigen Aussehen und Verhalten des Redesigns — sie sind **nicht** zum direkten Übernehmen gedacht.

Die Aufgabe ist, dieses Design **in der bestehenden SwiftUI-Codebasis** der BartoLink-App **nachzubauen**, mit den Patterns, die dort schon etabliert sind (`Theme.swift`, `BackgroundView`, `StoredNotification`, SwiftData-Queries, NavigationStack, TabView). Wenn die HTML-Spec und Swift-Konventionen sich widersprechen, **gewinnen Swift-Konventionen** — nutze native SwiftUI-Komponenten (`List`, `Section`, `Label`, `LabeledContent`, `Capsule`, etc.), nicht 1:1 die HTML-DOM-Struktur.

## Fidelity

**High-Fidelity.** Farben, Typo-Größen, Spacing, Radien sind festgelegt. Kleinere Anpassungen für SwiftUI-Idiome (z. B. statt eigener "Chip"-View einfach `.foregroundStyle()` + `.background(.capsule)`) sind erwünscht und sollen die App **nativer** wirken lassen.

## Screens / Views

Die App hat drei Haupt-Views (entsprechen den bestehenden Files):

### 1. `NotificationListView` — Inbox

**Zweck:** Liste aller empfangenen Push-Notifications, gruppiert nach Tag, mit einem Live-Hero für die wichtigste aktive Benachrichtigung (z. B. nächster Zug).

**Layout (von oben nach unten):**
1. **Header** (außerhalb von List, im ZStack über BackgroundView)
   - Eyebrow-Label: `"Sonntag · 03 Mai"` — uppercase, 12 pt, semibold, color `ink3`
   - Titel: `"Inbox"` — 34 pt, bold, letterSpacing `-0.022em`
   - Rechts: zwei runde Icon-Buttons (`magnifyingglass`, `ellipsis`) — 36×36, `.ultraThinMaterial`-Hintergrund
2. **Live-Hero-Karte** (nur wenn es eine aktive Push-Benachrichtigung mit Zug-Metadaten und `delayMinutes > 0` oder `statusRaw == "delayed"` gibt)
   - Hintergrund: weiß-transparent + Top-Verlauf in der Akzentfarbe (Amber bei Verspätung, Green bei pünktlich)
   - Status-Chip oben links (z. B. `● Verspätet · +7 Min`)
   - Rechts: Relative Zeit (`vor 12 min`)
   - Große Zeit-Anzeige: `actualDeparture` 48 pt bold + `plannedDeparture` 16 pt durchgestrichen
   - Zuglinien-Pille (z. B. `RB23`) in Blau + Beschreibung (`nach Andernach · Gleis 1`)
   - Fortschrittsbalken (5 pt hoch) zwischen `fromStation` und `toStation`
3. **Tagessektionen** ("Heute", "Gestern", Datum)
   - Sektion-Header: 17 pt bold + Anzahl Signale rechts in 12 pt
   - Listen-Container = eine Glas-Karte (`borderRadius: 18`) mit Rows darin
4. **Tab-Bar** (siehe Tab-Bar-Spec unten)

**Row-Komponente (jede Notification):**
- Layout: Icon (40×40, color-mix Hintergrund) + Content
- Top-Zeile: Source-Label (lowercase, 11.5 pt semibold) + Status-Chip rechts + ggf. roter Unread-Dot
- Title: 16 pt semibold
- Bottom-Zeile: Body 13.5 pt secondary + Zeit rechts in 12 pt tertiary
- Trennlinie zwischen Rows: 1 px hairline

### 2. `NotificationDetailView` — Detail

**Zweck:** Komplette Metadaten einer Notification (Zug-Daten, Verspätungsgrund, Strecke, Raw Body).

**Layout:**
1. **NavBar** mit `← Inbox`-Button (in Akzentfarbe Blau) und ⋯
2. **Headline-Block:**
   - Severity-Chip oben (z. B. `● Verspätung · Hoch` in Amber)
   - Titel zweizeilig: `"RB23 nach"` / `"Andernach"` — 30 pt bold
   - Untertitel: Datum + Uhrzeit + `source` (z. B. `dbticker.transit`)
3. **Zeit-Karte** mit Akzent-Kante links in Amber:
   - 3-Spalten-Grid: `Geplant` (06:31, durchgestrichen, secondary) → Pfeil → `Neu` (06:38, 38 pt bold)
   - Untere Reihe (durch hairline getrennt): KPI-Grid `Linie | Gleis | Verspätung`
4. **Grund-Karte** (nur wenn `delayReason` vorhanden):
   - Label-Header + `Severity`-Chip (Farbe nach `delayReasonSeverity`: critical=red, high=amber, medium=yellow, low=green)
   - Grund-Text 20 pt semibold
   - Erklär-Hinweis 14 pt secondary
5. **Strecke-Karte** (nur wenn `fromStation` / `toStation` vorhanden):
   - Vertikale Timeline mit zwei Punkten (gefüllt + outline)
   - `fromStation` = "Einsteigen", `toStation` = "Aussteigen" mit Zeit
6. **Nachricht-Karte:** Roher `body` als pre-formatted text

### 3. `StatusView` — Status

**Zweck:** Diagnose-Tab — APNs, Backend, App-Info, plus Live-Health-Indikator.

**Layout:**
1. **Header:** "System · Live" Eyebrow + "Status" 34 pt bold + Health-Chip rechts
2. **Health-Hero-Karte:**
   - Top-Verlauf in `green` 16 % Tönung
   - "● Alle Systeme nominal" Eyebrow
   - "99,8% Uptime" — 36 pt bold (Zahl) + secondary suffix
   - Sparkline-SVG (in nativem Code: `Chart` via Swift Charts oder Path mit `LinearGradient` fill)
   - X-Achsenlabels: `−30 Tage` / `Jetzt`
   - Untere Reihe: KPI-Grid `Latenz | Pushes | Queue`
3. **APNs-Karte** mit Akzent-Kante Blau:
   - Header + `● Registriert`-Chip (oder `● Fehler` rot, oder `● Wartet…` neutral)
   - Token in monospace, in einem inset-Code-Block (oder Apple's `Text(...).font(.system(.caption, design: .monospaced))`)
4. **Backend-Karte** mit Akzent-Kante Green:
   - Header + Verbunden-Chip
   - Key-Value-Liste: `Device`, `Endpoint`, `Environment`
5. **App-Karte** (kein Akzent):
   - Bundle-ID, Version, APNs-Env

## Design Tokens

### Farben (alle als Theme erweitern)

```swift
// Background — bleibt wie aktuell in Theme.backgroundGradient(.light)
// Light:
//   top:    Color(red: 0.85, green: 0.93, blue: 1.00)   // hell
//   bottom: Color(red: 0.72, green: 0.85, blue: 0.98)   // tiefer

// Ink (Vordergrund-Stufen)
ink   = Color(hex: 0x0F1F33)    // primary
ink2  = Color(hex: 0x4A5A72)    // secondary
ink3  = Color(hex: 0x8593A8)    // tertiary

// Karten
cardFill   = Color.white.opacity(0.78)         // mit .background(.ultraThinMaterial)
cardStroke = Color(red: 0.06, green: 0.13, blue: 0.24, opacity: 0.08)
hairline   = Color(red: 0.06, green: 0.13, blue: 0.24, opacity: 0.10)

// Akzente — alle gleiche Sättigung/Lightness, nur Hue variiert
// In Swift: per Color(red:green:blue:) approximieren oder Color(hue:saturation:brightness:)
blue   ≈ #2A7DD9   // Hauptakzent (Tab-Bar aktiv, Links, Zuglinie)
amber  ≈ #E08B2C   // Verspätung, "high" severity
green  ≈ #2BA76B   // OK, healthy, "low" severity
violet ≈ #8B6FE0   // System / mailcontrol
red    ≈ #DA4A3A   // critical
```

### Source → Akzent-Mapping (erweitert `Theme.style(for:)`)

| Source | Color | SF Symbol |
|---|---|---|
| `dbticker`, `transit` | blue (oder amber wenn delayed) | `tram.fill` |
| `mailcontrol` | violet | `envelope.fill` |
| `system`, `barto-link`, `manual-test` | violet | `server.rack` |
| `smarthome`, `home` | green | `house.fill` |
| default | ink3 | `bell.fill` |

### Severity → Color

| `delayReasonSeverity` | Color |
|---|---|
| `critical` | red |
| `high` | amber |
| `medium` | amber (heller) |
| `low` | green |
| `nil` / sonst | ink3 |

### Typografie

Alles **iOS System Font** (`.system(...)`) — KEINE Custom-Fonts. Konkret:

| Rolle | Größe | Weight | Tracking |
|---|---|---|---|
| Display Title (Inbox/Status) | 34 pt | bold | `-0.022em` |
| Detail-Titel | 30 pt | bold | `-0.022em` |
| Hero-Time (Inbox) | 48 pt | bold | `-0.03em` |
| Detail-Time (neu) | 38 pt | bold | `-0.025em` |
| KPI-Value | 24 pt | bold | `-0.018em` |
| Section-Header | 17 pt | bold | `-0.01em` |
| Card-Title / Row-Title | 16 pt | semibold | `-0.005em` |
| Body | 14 pt | regular | — |
| Body-Secondary | 13.5 pt | regular | — |
| Eyebrow / Label | 12 pt | semibold uppercase | `0.04em` |
| Chip | 11 pt | semibold | `0.02em` |
| Mono (nur Token/IDs) | 12.5 pt | regular | — (`.system(.body, design: .monospaced)`) |

In SwiftUI z. B.:
```swift
.font(.system(size: 34, weight: .bold).leading(.tight))
```

### Spacing

- Außen-Padding: 20 pt
- Karten-Padding: 16 pt
- Karten-Abstand vertikal: 12 pt
- Sektion-Abstand vertikal: 18–20 pt
- Row-Padding: 14 pt vertikal × 14 pt horizontal

### Radien

- Karten: 18 pt
- Icon-Container in Rows: 10 pt
- Chips / Capsules: `Capsule()` (= komplett rund)
- Tab-Bar: 22 pt außen, 17 pt aktive Pille
- Inset-Code-Block (Token): 10 pt

### Schatten

- Karten: `.shadow(color: Color(red:0.06,green:0.13,blue:0.24,opacity:0.06), radius: 18, x: 0, y: 6)`
- Tab-Bar: `.shadow(color: ...10, radius: 32, y: 12)`

## Komponenten zum Bauen

Lege diese in `bartolink/UI/` als wiederverwendbare Views an:

1. **`SLLabel(_ text:)`** — Eyebrow-Label (uppercase, 12 pt semibold, `ink3`)
2. **`SLChip(text:color:filled:)`** — Capsule, Dot + Text, color-mix Hintergrund
3. **`SLCard<Content>`** — Glaskarte mit optionalem `accent: Color` (linker 3-pt-Streifen)
4. **`SLKPI(label:value:sub:valueColor:)`** — KPI-Block für 3-Spalten-Grids
5. **`SLKeyValue(_ key:_ value:mono:)`** — Zeile mit hairline-bottom
6. **`SLIconButton(systemName:)`** — runder 36×36 Glasknopf
7. **`SLTabBar`** — Custom Tab-Bar (ersetzt das Standard-`TabView`-Tab-Bar oder als Overlay über `TabView` mit `.toolbar(.hidden, for: .tabBar)`)

## Interactions & Behavior

- **Tap auf Row** → Push `NotificationDetailView` (bleibt wie aktuell)
- **Swipe-to-delete** auf Row → SwiftData `modelContext.delete()`
- **Pull-to-refresh** auf Inbox: optional, kein API-Pull nötig — kann ein UI-Hint sein, dass die App passiv via APNs empfängt
- **Live-Hero**: nur sichtbar wenn:
  - es eine `StoredNotification` gibt mit `hasTrainMetadata == true`
  - die `receivedAt` < 30 Min zurück liegt
  - `plannedDeparture` < 60 Min in der Zukunft liegt
- **Animations:**
  - Karten-Erscheinen: `.transition(.opacity.combined(with: .move(edge: .top)))`
  - Status-Chip-Farbwechsel: `.animation(.easeInOut(duration: 0.3), value: status)`
  - Sparkline: trace-on bei View-Erscheinen (`.animation(...).onAppear`)

## State Management

Bleibt wie aktuell:
- `@Query` für `StoredNotification`
- `@EnvironmentObject var tokenStore: PushTokenStore` für StatusView
- `@Environment(\.modelContext)` für Delete-Operationen

Neu:
- `Theme.style(for:)` um optionalen `delayed`-Override erweitern: bei `dbticker` mit `delayMinutes > 0` → Farbe = amber statt blue
- Computed Property auf `StoredNotification` für `liveHeroEligible: Bool`

## Files

In diesem Bundle:

- `Signal Light.html` — Standalone Vorschau aller drei Screens nebeneinander. **Im Browser öffnen** für Pixel-Referenz.
- `variant-signal-light.jsx` — React-Quellcode der drei Views (Inbox, Detail, Status). Hier stehen exakte Farben, Größen, Komponenten-Aufbau.
- `ios-frame.jsx` — iPhone-16-Pro-Frame, der die Screens umrahmt — nicht relevant für die App-Implementierung.

## Tipps für die Umsetzung

1. **Erweitere `Theme.swift`** zuerst um die neuen Token (Farben, Typo-Helper). Halte die bestehenden Funktionen und ergänze sie.
2. **Baue die UI-Bausteine** (`SLCard`, `SLChip`, `SLKPI`, `SLLabel`) als nächstes, mit `#Preview` für jeden.
3. **Refactore die Views** danach Stück für Stück:
   - Zuerst Header + Background-Integration
   - Dann Row-Komponente (entspricht `NotificationRow`)
   - Dann Live-Hero (neu)
   - Dann Detail
   - Dann Status
4. **Tab-Bar:** Wenn du das Custom-Look willst, blende die System-`TabView`-Bar aus (`.toolbar(.hidden, for: .tabBar)`) und overlaye `SLTabBar` über `ZStack`.
5. **Akzeptiere `colorScheme`-Differenzen:** `Theme` hat schon Light/Dark — der Entwurf zielt aktuell auf Light; ein Dark-Pendant kann später folgen.
6. **Accessibility:** `Dynamic Type` muss funktionieren — nutze `.font(.system(.title2, weight: .bold))` statt fixe Pixel, wo es geht. Für Display-Größen (48 pt Time) ggf. `@ScaledMetric`.

## Was NICHT geändert werden soll

- Der existierende `BackgroundView` und seine Light/Dark-Logik in `Theme.backgroundGradient(for:)` bleiben — der neue Entwurf nutzt den hellblauen Verlauf direkt.
- `StoredNotification` Schema bleibt — keine Migration nötig.
- `APIClient`, `AppDelegate`, APNs-Logik bleiben unangetastet.
- Die TabView-Struktur kann bleiben (`Inbox` + `Status`); nur das Aussehen der Bar ggf. anpassen.

---

Bei Fragen zur Spec → schau in `variant-signal-light.jsx`. Die JSX-Komponenten sind 1:1 zu dem, was im Entwurf zu sehen ist.
