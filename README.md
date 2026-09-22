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
| Distracted | +25 | They have been at war with someone else for at least two evaluations |
| Ally at war | +45 | They are fighting one of our permanent allies |
| Occupier | +50 | They hold regions that were ours or an ally's |
| Old rivalry | +15 | The map lists them as a default enemy |
| Grievance | up to +120, decays | Frontier reinforcements against us, their aircraft over our territory |
| Stronger | −70 / −130 | Their visible power clearly outweighs ours |
| Blind | −40 | We can see fewer than half their divisions |
| Committed | −40 | We already chose a war elsewhere |

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

**Peace is respected.** A war the engine ends — ceasefire, peace treaty,
surrender — stays ended: the faction is stood down against, re-leashed and
protected from any scored declaration for a game-hour. A declaration the
engine refuses (for example under a treaty) is withdrawn the same way. Only a
real attack cuts through the cooldown.

**Being attacked is answered immediately.** Any faction that is attacked
hits back at once with a rolling series of limited operations — proportionate,
and never an invasion by itself. A war the engine brings a faction into on
behalf of a permanent ally is fought in full.

**Nuclear weapons are a last resort.** Every AI starts with all nuclear
categories withheld and releases them tier by tier, never taking them back:

| Tier | Released | When |
|---|---|---|
| Tactical | tactical nukes, nuclear artillery | at war and being invaded in a region it may not hold (invaders ≥ defenders there) — or hit by tactical nukes first |
| Strategic | fission, MIRV, strategic, SLBM | at war and the threat is existential — **territorial**: at least 20% (and at least two) of its starting regions lost, or any single region worth ≥25% of its starting economy — or hit by strategic weapons first |
| Salted | salted weapons | only in kind |

`NUCLEAR_DOCTRINE 0` restores vanilla behaviour.

**Ownership readable in text.** Every AI unit is renamed with its faction
tag — `[SU] Destroyer`, `[NATO] Army Division` — so who owns a unit can be
read in the hover label rather than only from its colour. `TAG_UNIT_NAMES 0`
turns it off.

Also included:

- higher war-readiness thresholds on every difficulty
- a 30-minute warm-up at game start during which no scored war is declared
- (optional, off by default) a stricter home garrison before an AI can
  invade — `$StricterGarrison` in `build.ps1`

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

and start a **new** game. Tunables (threshold, weights, warm-up, debug) are
at the top of `src/WarMotives.txt`. `DEBUG_MESSAGES 1` prints each AI's
reasoning on screen every evaluation; set it to `0` for normal play.

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
