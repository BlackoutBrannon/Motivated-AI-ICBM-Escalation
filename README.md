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
| Land grab | +40 (+20 at ≥300%) | A specific border region of theirs is thinly held compared with our divisions next to it (their reinforcements one province away count at half) |
| Outpaced | +45 | Their military has out-grown ours for three evaluations running |
| Distracted | +30 | They are already at war with someone else |
| Ally at war | +45 | They are fighting one of our permanent allies |
| Occupier | +50 | They hold regions that were ours or an ally's |
| Old rivalry | +15 | The map lists them as a default enemy |
| Grievance | up to +120, decays | Frontier reinforcements against us, their aircraft over our territory |
| Stronger | −70 / −130 | Their visible power clearly outweighs ours |
| Blind | −40 | We can see fewer than half their divisions |
| Committed | −40 | We already chose a war elsewhere |

100 points opens a **limited war against that faction only**. Opportunity
alone can never reach 100 — a thin border needs a second reason.

**Intel matters.** Everything the AI knows about a rival comes from what its
radars, satellites, spy planes and spies can actually see. A rival it cannot
see is not "weak", it is unknown, and the AI will not invade what it cannot
assess. Shooting down spy planes and keeping your army out of radar coverage
are real defensive measures.

**Being attacked is answered immediately.** Any faction that is attacked
drops its restraint against the attacker at once.

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
build_probe.ps1         diagnostic build used to reverse-engineer script commands
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
- The engine wipes a faction's attack blocks when it goes to war; the mod
  re-asserts them every evaluation.
- Event-handler arguments are evaluated when the event fires, not when it is
  registered — never pass a loop variable.
- Factions build one item at a time, ~0.4 cost-units per 10 game-minutes;
  warhead-bearing items are throttled by warhead production efficiency
  (Nuclear Fuel techs). AI-built units sit in reserve until a plan deploys
  them.
