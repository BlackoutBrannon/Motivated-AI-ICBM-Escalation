# Motivated AI — ICBM: Escalation

A mod for *ICBM: Escalation* (Slitherine / SoftWarWare) that gives the AI
**reasons** to go to war instead of a readiness timer.

The vanilla AI has two states: preparing for war, and at war. This mod puts a
scripted motive layer in front of it. Every AI faction scores each rival
separately, every few game-minutes, and only opens a war against *that
faction* when an opportunity and a reason coincide.

## What the AI weighs

| Motive | Points | What it means |
|---|---|---|
| Land grab | +40 (+20 at ≥300%) | A specific border region of theirs is thinly held compared with what we can bring: our divisions next to it plus 30% of our whole army by air and sea (their reinforcements one region away count at half) |
| Outpaced | +45 | Their military has out-grown ours for three evaluations running |
| Distracted | +25 | They have been tied up for at least two evaluations in a war against somebody **we are not also fighting** (a shared enemy is a common front, not a distraction) |
| Ally at war | +45 | They are fighting one of our permanent allies |
| Occupier | +50 | They hold regions that were ours or an ally's |
| Old rivalry | +15 | The map lists them as a default enemy |
| Grievance | up to +120, decays | Units of ours destroyed (+70), their units inside our borders (+40), shots that destroy nothing (+20), aircraft in our air-defence zone, frontier reinforcements |
| Stronger | −70 / −130 | Their visible power clearly outweighs ours |
| Blind | −40 | We can see fewer than half their divisions |
| Committed | −40 × n(n+1)/2 | We already have n wars of our own: −40 for a second front, −120 for a third, −240 for a fourth |

A rival that has sat within reach of the threshold for a long time wears
down restraint: after 90 game-minutes of such a standoff there is a small
chance (5% per evaluation) that the AI acts on the opportunity anyway — the
reason then reads `lost-patience`.

100 points opens a war **against that faction only**, and **the motive picks
the kind of war**: territorial reasons (land grab, occupied land) or backing
an ally open the engine's full war, invasion included; punitive reasons
(grievances, being out-built) open a limited war of rolling strikes with
invasion still barred. A limited war escalates to invasion if a territorial
opportunity later clears the threshold. Opportunity alone can never reach
100: a thin border needs a second reason.

**Intel matters.** Everything the AI knows about a rival comes from what its
radars, satellites, spy planes and spies can actually see. A rival it cannot
see is not "weak", it is unknown, and the AI will not invade what it cannot
assess. Shooting down spy planes and keeping your army out of radar coverage
are real defensive measures.

**Stalemates end in a ceasefire.** A war that has run two game-hours with
neither side taking ground is wound down: the faction asks the engine for a
ceasefire, stops prosecuting the war, re-leashes the enemy and holds the
peace cooldown for a game-hour so nothing re-declares on the spot.

**Peace is respected.** A war the engine ends — ceasefire, peace treaty,
surrender — stays ended: the faction is stood down against, re-leashed and
protected from any scored declaration for a game-hour. A declaration the
engine refuses (for example under a treaty) is withdrawn the same way. Only a
real attack cuts through the cooldown.

**Incidents are not wars — but they are a powder keg.** Everything short of a
sustained attack is a grievance that accumulates and decays: a shot that
destroys nothing (+20), an uninvited border crossing (+40), a unit of ours
destroyed (+70). A faction with nothing else against you shrugs off a stray
kill; one that already holds a grudge, a rivalry or a weak border in view
tips into war on the spot. **Three losses to the same faction means war
regardless of the score.** Wars entered this way are punitive: rolling
limited strikes, never an invasion by themselves. A war the engine brings a
faction into on behalf of a permanent ally is fought in full.

**Nuclear weapons are a last resort.** Every AI starts with all nuclear
categories withheld and releases them tier by tier, never taking them back.
Broad attrition has to be *held* to count, because a contested region reads
as a conquest in any single snapshot — but a **vital** region about to fall
needs no waiting period. If Moscow may be lost, the answer is now:

| Tier | Released | When |
|---|---|---|
| Tactical | tactical nukes, nuclear artillery, EMP | at war and being invaded in a region **worth defending** (≥5% of its starting economy) that it may not hold (invaders ≥ defenders there), or having already lost two starting regions — or hit by tactical nukes first |
| Strategic | fission, MIRV, strategic, SLBM | at war and the threat is existential — **territorial**: at least 20% (and at least two) of its starting regions lost **and held for three evaluations** (a contested region reads as lost in a snapshot), or — **immediately** — a single region worth ≥25% of its starting economy that it may not hold (invaders there ≥ defenders) — or hit by strategic weapons first |
| Salted | salted weapons | only in kind |

`NUCLEAR_DOCTRINE 0` restores vanilla behaviour.

**Colourblind palette (optional, off by default).** Setting
`$ColorblindPalette = $true` in `build.ps1` replaces the ten faction colours with a set built for a weak red cone:
factions are separated by lightness and the blue–yellow axis, there are no
purples, and reds are kept light so they cannot collapse into the browns.
Your side is bright (sky blue, white, mint); the Eastern bloc is dark (brown,
maroon, orange-red).

Also included:

- higher war-readiness thresholds on every difficulty
- a 30-minute warm-up at game start during which no scored war is declared
- (optional, off by default) a stricter home garrison before an AI can
  invade — `$StricterGarrison` in `build.ps1`

## What a game looks like

From a fully autonomous long run (no player involvement, late era, Iron
Curtain):

- **0:00–1:30** — peace. Every faction sits on one or two opportunities it
  can see (the Soviets on Norway, Pakistan on West India, NATO on Bulgaria)
  and does nothing, because opportunity alone is never enough. Four
  partnerships form on their own.
- **~1:30** — NATO, having stared at an open Bulgaria for ninety minutes,
  loses patience and declares on the Warsaw Pact. The Pact answers; the
  Soviets join under mutual defence; the allied blocs follow; Neutral is
  dragged in by contact.
- **~1:40** — the Pact is inside NATO territory. Tactical weapons are
  authorised on both sides and used — 33 battlefield shells in ten minutes.
  Nobody has lost enough land for the strategic tier; global fallout stays
  negligible.

That is the intended shape: long standoffs, one reasoned war at a time,
proportionate escalation.

## Install

Copy this folder to `<game>\MODS\LessAggressiveAI\` and enable
**Less Aggressive AI** in the game's mod list (below the DLC entries).
Currently supports the **Iron Curtain** map.

## Layout

```
src/WarMotives.txt      the motive script (edit this)
src/StaticDefence.txt   optional stricter garrison rules (off by default)
build.ps1               stamps both into the files the game actually loads
diagnostics/            throwaway probe builds used to reverse-engineer the engine (not for play)
AI/                     limits.txt (readiness thresholds); StrategyConquest.txt only with the garrison switch on
Maps/IronCurtain.virtual/Events/   generated: one script copy per faction
```

After editing anything in `src/`, run

```
powershell -ExecutionPolicy Bypass -File build.ps1
```

and start a **new** game. Tunables (threshold, weights, warm-up, reporting)
are at the top of `src/WarMotives.txt`.

`DEBUG_MESSAGES` controls what the AI tells you on screen:

| Level | Shows |
|---|---|
| 0 | nothing |
| **1** (default) | **events only** — a faction declares war, stands down, or authorises nuclear weapons, each with the reason |
| 2 | + every faction's top-scoring rival each evaluation, and every pairing with `DEBUG_WATCH` |
| 3 | + every rival pairing of every faction (very noisy) |

See [NOTES.md](NOTES.md) for how the mod works underneath, the engine
behaviour it had to be built around, and what is still open.

## Why the generated copies

Files the game reaches through `USE` resolve to the base game, so a mod
cannot override them. The map's per-faction event files (and
`AI/StrategyConquest.txt`) are opened directly, so the build script stamps
the shared source into each of them.

## Engine findings (verified from save files)

- Being attacked does **not** start a war; the victim's AI has to declare it,
  and a `BlockAttack` leash stops it from doing so.
- Script `AllowAttack` is a no-op. `LimitedAttack X` and `AttackFaction X`
  clear the block and declare war; `Declare War X` only sets relations.
- Going to war wipes all of a faction's attack blocks. Re-blocking others
  **in the same tick after** a war order freezes the faction outright (no
  orders, war dropped); re-blocking two minutes later holds and the war goes
  on. The mod restores the leash on a delay and always issues blocks before
  war orders within an evaluation.
- `LimitedAttack` / `AttackFaction` are one-shot operations; the mod re-issues
  the faction's war mode every evaluation for each current enemy.
- Event-handler arguments are evaluated when the event fires, not when it is
  registered — never pass a loop variable.
- Factions build one item at a time, ~0.4 cost-units per 10 game-minutes;
  warhead-bearing items are throttled by warhead production efficiency
  (Nuclear Fuel techs). AI-built units sit in reserve until a plan deploys
  them.
