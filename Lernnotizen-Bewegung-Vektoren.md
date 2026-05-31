# Lernnotizen — Bewegung und Vektoren

*Zusammenfassung der Konzepte aus dem Bouncing-Ball-/Pong-Experiment.*
*Soll mir auch in drei Wochen noch helfen, alles wieder zu durchdringen.*

---

## Inhalt

1. Die drei Stockwerke: Position, Geschwindigkeit, Beschleunigung
2. `dt` — die Zeit zwischen Frames
3. Vektoren in 2D — Pfeile mit Länge und Richtung
4. Der Einheitsvektor — pure Richtung
5. Geschwindigkeit als Vektor: zwei Darstellungen
6. Bewegungs-Update im polaren Modell
7. Stolperfallen, an die ich denken muss
8. Brücke zu Phase 1 (Asteroids-Schiff)

---

## 1. Die drei Stockwerke

In der Spielephysik gibt es drei aufeinander aufbauende Größen. Jede ist die
zeitliche Änderung der darüberliegenden:

| Größe | Bedeutung | Einheit |
|-------|-----------|---------|
| Position | wo das Objekt ist | Pixel (x, y) |
| Geschwindigkeit | wie schnell und wohin es sich bewegt | Pixel / Sekunde |
| Beschleunigung | wie sich die Geschwindigkeit ändert | Pixel / Sekunde² |

Im Code sieht man die drei Stockwerke in jeweils einer Zeile:

```lua
speed = speed + acceleration * dt     -- Beschleunigung wirkt auf Geschwindigkeit
x     = x + speed * dirX * dt          -- Geschwindigkeit wirkt auf Position
y     = y + speed * dirY * dt
```

Jedes `* dt` ist ein Schritt "ein Stockwerk tiefer" — von einer
Änderungsrate zu einer konkreten kleinen Änderung im aktuellen Frame.

---

## 2. dt — die Zeit zwischen Frames

`dt` ("delta time") ist die Zeit in Sekunden, die seit dem letzten Aufruf
von `love.update` vergangen ist. LÖVE misst das automatisch und übergibt
es als Parameter:

```lua
function love.update(dt)
    -- dt ist hier z. B. ≈ 0.0167 bei 60 FPS
end
```

| Framerate | dt ungefähr |
|-----------|-------------|
| 30 FPS    | 0.033 s |
| 60 FPS    | 0.017 s |
| 144 FPS   | 0.007 s |

### Warum brauche ich das?

**Framerate-Unabhängigkeit.** Ohne `* dt` koppelt sich die Bewegung an die
Bildrate des Monitors:

| Code | bei 60 FPS | bei 144 FPS |
|------|------------|-------------|
| `x = x + 1`       | 60 px/s  | 144 px/s |
| `x = x + 100 * dt` | 100 px/s | 100 px/s |

Mit `* dt` bewegt sich das Objekt **pro echter Sekunde** dieselbe Strecke,
unabhängig von der Bildrate. Das ist die Grundregel für jede saubere
Spielephysik.

### Die "Taktgeber"-Analogie

`dt` ist wie der Taktgeber am Kilometerzähler eines Autos:

- Der Tacho zeigt das **Tempo** (`speed`).
- Der Kilometerzähler will **Strecken**.
- Bei jedem Tick liest er das aktuelle Tempo ab, multipliziert mit der
  vergangenen Zeit, und addiert das Ergebnis:

```
neue_kilometer = alte_kilometer + tempo * vergangene_zeit
```

Genau das macht jede `update`-Funktion in LÖVE — nur viele Male pro Sekunde
und in winzigen Schritten.

### Was passt auf welche Stockwerk-Größe?

- `dt` allein → **nur Zeit**, keine Strecke
- `speed * dt` → **Strecke** im aktuellen Frame (Pixel)
- `acceleration * dt` → **Geschwindigkeitszuwachs** im aktuellen Frame

Faustregel: jede "pro Sekunde"-Größe wird mit `dt` multipliziert, um daraus
eine konkrete kleine Änderung zu bekommen.

> **Wichtig:** `dt` ist *nur* die Zeit, keine Strecke. Erst `speed * dt`
> ist die "Frame-Pixel-Strecke", die der Punkt diesen Frame zurücklegt.

---

## 3. Vektoren in 2D — Pfeile mit Länge und Richtung

Ein Vektor in 2D ist im Kern ein **Pfeil** vom Ursprung zu einem Punkt
`(x, y)`. Er hat zwei Eigenschaften:

- **Länge**: `sqrt(x² + y²)` (Satz des Pythagoras)
- **Richtung**: festgelegt durch das *Verhältnis* der beiden Komponenten

### Beispiel: der Vektor (3, 4)

```
   (0,0) ────── 3 ──────→
        \                |
         \               |
          \              4
           \             |
            ↘            ↓
            (3, 4)
            Länge = √(3² + 4²) = 5
```

*(In LÖVE zeigt positive Y-Achse nach unten — daher diagonal nach
rechts-unten statt rechts-oben.)*

### Gleiche Richtung, verschiedene Länge

Vektoren mit demselben Komponenten-Verhältnis zeigen in dieselbe Richtung:

| Vektor    | Länge  | Bemerkung |
|-----------|--------|-----------|
| (3, 4)    | 5      | Original |
| (6, 8)    | 10     | gleiche Richtung, doppelt so lang |
| (0.6, 0.8) | 1     | gleiche Richtung, "minimal" lang (Einheitsvektor) |
| (4, 3)    | 5      | **andere** Richtung, gleiche Länge |

---

## 4. Der Einheitsvektor — pure Richtung

Ein **Einheitsvektor** ist ein Vektor mit Länge 1. Er beschreibt nur noch
die *Richtung*, ohne Information über das Tempo.

Um aus einem beliebigen Vektor seinen Einheitsvektor zu machen: teile
beide Komponenten durch die Länge ("**Normalisieren**"):

```
Vektor (3, 4), Länge 5
→ Einheitsvektor (3/5, 4/5) = (0.6, 0.8)

Probe: √(0.6² + 0.8²) = √(0.36 + 0.64) = √1 = 1 ✓
```

In Lua-Code:

```lua
local length = math.sqrt(x^2 + y^2)
local unitX  = x / length
local unitY  = y / length
```

Alle Einheitsvektoren zusammen liegen auf dem **Einheitskreis** um den
Ursprung (Radius 1).

### Wofür der ganze Aufwand?

Einheitsvektor × beliebiges Tempo = Geschwindigkeit in dieser Richtung
mit gewünschtem Betrag:

```
5   * (0.6, 0.8) = (3, 4)      -- Tempo 5
10  * (0.6, 0.8) = (6, 8)      -- Tempo 10
100 * (0.6, 0.8) = (60, 80)    -- Tempo 100
```

So kann ich **Tempo und Richtung unabhängig** voneinander steuern.

---

## 5. Geschwindigkeit als Vektor: zwei Darstellungen

Eine Geschwindigkeit in 2D kann man auf zwei Arten speichern:

### Cartesisch
```lua
velocityX = 100
velocityY = 100
```
Beide Komponenten gemeinsam. Einfach für Addition und Positions-Update.

### Polar
```lua
speed = math.sqrt(100^2 + 100^2)  -- ≈ 141
dirX  = 100 / 141                 -- ≈ 0.707
dirY  = 100 / 141                 -- ≈ 0.707
```
Tempo und Richtung getrennt. Schöner, wenn ich beide unabhängig
steuern möchte.

> **Wichtige Regel:** Nur **eine** Darstellung als "Wahrheit" wählen.
> Beide gleichzeitig als Zustand zu halten und nur in eine Richtung zu
> synchronisieren erzeugt sehr subtile Bugs — Änderungen in der "anderen"
> Darstellung werden im nächsten Frame überschrieben.
> Das war einer meiner Bugs.

---

## 6. Bewegungs-Update im polaren Modell

Das saubere Muster für Phase 0 / 1:

```lua
-- Konstanten (oben in der Datei)
local acceleration = 300        -- Pixel / Sekunde²
local maximumSpeed = 1000
local minimumSpeed = 0

-- Zustand
local x, y       = 400, 300
local speed      = 180          -- aktuelles Tempo
local dirX, dirY = 0.6, 0.8     -- Einheitsvektor: Richtung

function love.update(dt)
    -- Gas / Bremse: nur speed anfassen
    if love.keyboard.isDown("right") and speed < maximumSpeed then
        speed = speed + acceleration * dt
    end
    if love.keyboard.isDown("left") and speed > minimumSpeed then
        speed = speed - acceleration * dt
    end
    
    -- Bewegung: aus speed und dir die Verschiebung bauen
    x = x + speed * dirX * dt
    y = y + speed * dirY * dt
    
    -- Wand: nur Richtung umdrehen, speed bleibt
    if (x >= width  and dirX > 0) or (x <= 0 and dirX < 0) then dirX = -dirX end
    if (y >= height and dirY > 0) or (y <= 0 and dirY < 0) then dirY = -dirY end
end
```

### Warum die Wand-Bedingung mit zusätzlichem Richtungs-Check?

`x >= width` allein kann mehrere Frames hintereinander wahr bleiben (weil
der Punkt sich vielleicht noch nicht weit genug zurückbewegt hat). Dann
würde die Richtung jeden Frame neu umgekippt — der Ball klebt an der Wand
und zappelt zwischen zwei Pixeln hin und her.

Mit der zusätzlichen Bedingung `dirX > 0` feuert die Umkehrung nur, wenn
der Punkt sich **auch tatsächlich auf die Wand zubewegt**. Physikalisch:
Ein Stoß tritt nur bei Annäherung auf, nicht beim Entfernen.

---

## 7. Stolperfallen, an die ich denken muss

### 1. `dt` nie vergessen
Jede "pro Sekunde"-Größe braucht die Multiplikation mit `dt`. Sonst läuft
das Spiel auf jedem Rechner anders.

### 2. `acceleration` wird *addiert*, nicht multipliziert
`speed = speed + acceleration * dt`. Die Geschwindigkeit *wächst* um einen
Betrag pro Frame, sie wird **nicht** mit dem Beschleunigungswert
multipliziert.

### 3. Wand-Bedingung braucht Annäherungs-Check
```lua
if x >= width and dirX > 0 then dirX = -dirX end  -- richtig: nur bei Annäherung
if x >= width then dirX = -dirX end               -- falsch: klebt an der Wand
```

### 4. Bei Normalisierung auf Division durch 0 achten
Wenn der Vektor `(0, 0)` ist, ergibt `length = 0`, und das Teilen liefert
`nan`. Defensiv:
```lua
if length > 0 then
    dirX = x / length
    dirY = y / length
end
```

### 5. Nicht zwei Datenrepräsentationen gleichzeitig pflegen
Entweder `(velocityX, velocityY)` als gespeicherter Zustand und
`(speed, dirX, dirY)` bei Bedarf berechnen — oder umgekehrt. Niemals
beide als Zustand und nur in eine Richtung synchronisieren. Das war der
fiese Bug, bei dem `speed = speed + 100` keine Wirkung hatte, weil das
nächste Frame `speed` aus `velocity` neu berechnete und überschrieb.

### 6. `sign(0) = 0` kann lähmen
Wenn man Logik baut, die `sign(velocity)` als Faktor nutzt, blockiert sich
das Schiff selbst, sobald `velocity = 0`. In dem Fall müssen entweder
Sonderfälle abgefangen werden, oder die Geschwindigkeit darf nie genau 0
erreichen (z. B. Mindestbetrag erzwingen).

---

## 8. Brücke zu Phase 1 (Asteroids-Schiff)

Das polare Modell ist nicht nur sauber für das Bouncing-Ball-Experiment —
es ist genau die Vorlage für die Schiffsphysik in Asteroids und Gravity
Force.

### Was bleibt gleich
- `speed` als Tempo-Skalar
- `(dirX, dirY)` als Einheitsvektor für die Richtung
- `x += speed * dirX * dt`, `y += speed * dirY * dt` als Bewegung
- `acceleration` als Rate, mit der sich `speed` ändert

### Was sich ändert
- **Richtung kommt nicht mehr aus Wandkontakten, sondern aus
  Spieler-Rotation.** Statt `dirX = -dirX` (Wandbounce) berechnet man:
  ```lua
  dirX = math.cos(angle)
  dirY = math.sin(angle)
  ```
  wobei `angle` durch Pfeiltasten links/rechts gedreht wird.
- **Schub wirkt nicht mehr abstrakt auf `speed`, sondern als
  Kraft-Vektor in Blickrichtung.** Daraus entsteht echtes "Driften", weil
  die Bewegungsrichtung nicht zwingend mit der Blickrichtung
  übereinstimmt — beim Drehen während des Driftens fliegt das Schiff
  seitwärts weiter.
- **Gravitation** (in Phase 1b) ist nur eine konstante Beschleunigung
  `(0, g)`, die jeden Frame zur Geschwindigkeit dazuaddiert wird.

### Was das bedeutet
Wenn ich Phase 1 angehe, ist das Datenmodell schon vertraut. Der größte
neue Schritt ist die Trigonometrie (`cos`, `sin`) für die Umrechnung
zwischen Winkel und Richtungsvektor — und das Aufgeben des Konzepts
"speed und Richtung lassen sich getrennt steuern" zugunsten von "Schub
wirkt als Vektor in Blickrichtung".

---

## Mantra zum Abschluss

> Wenn etwas in der Spielephysik komisch aussieht, ist das selten ein
> Bug — meistens ist es die Mini-Physik, die einen ehrlichen Hinweis
> gibt: hier passt etwas an deinem Modell der Welt nicht.

— Spielephysik ist Newton in klein. Selbst nachbauen ist die direkteste
Form, sie zu verstehen.
