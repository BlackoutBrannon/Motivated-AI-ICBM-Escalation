# Project notes

Working notes for whoever picks this up — including future me. The README
describes what the mod *does*; this is how it works underneath, what the
engine actually allows, and what is left to do.

## Where things stand

Version 2.4.0 + unreleased fixes. Everything below has been verified in play
unless marked otherwise.

**Working and tested**

- Leash: every faction blocked at start, re-asserted on a delay
- Motive scoring: per-region land grab (intel-gated), grievances, distraction,
  occupier, rivalry, standoff pressure
- Territorial wars open with `AttackFaction` and the vanilla engine invades
  (Hamburg captured 3.5 min after a declaration); punitive wars stay limited
- Retaliation, mutual defence, partner/ally exemption
- Nuclear doctrine: tactical and strategic tiers, in-kind response, AI
  actually fires tactical weapons once permitted
- Ceasefire/treaty respect with a one-hour cooldown
- Stalemate stand-down issuing a real `CeaseFire With`
- Survives save/load; staggered evaluations keep the frame cost flat

**Not yet tested in play** (all added after the last long run)

- Graduated response: every provocation short of sustained attack is a
  grievance (shot +20, incursion +40, unit destroyed +70); three losses to
  one faction means war regardless of score
- Aircraft-at-home no longer provoke
- EMP as a tactical weapon
- Territorial loss having to be *held* for three evaluations (broad attrition
  only — a vital region about to fall authorises strategic immediately)
- The `ON Destroyed anything ATTACKER "X"` hook form

## Engine facts, all learned the hard way

**Files and loading**

- Files reached via `USE` resolve to the base game, so a mod override of them
  is silently ignored. Only files the engine opens directly can be replaced:
  `Maps/<map>.virtual/Events/<Faction>.txt`, `Maps/<map>.txt`,
  `AI/StrategyConquest.txt`, `AI/limits.txt`, `AI/GroupsConquest.txt`,
  `AI/Conditional.txt`, `AI/DefenceDef.txt`. Hence `build.ps1` stamping one
  source into ten faction files.
- The parser **stops at the first bad file**; everything after it is never
  read. Forms that "passed" in an earlier probe round may simply never have
  been reached.
- A parse error at map select becomes a map-load failure at game start.
- Blocks must be defined **above** their first use, including blocks named in
  an `ON` registration. `build.ps1` now checks this.

**War control**

- Being attacked does **not** start a war. The victim's AI must declare one,
  and a `BlockAttack` leash prevents it — which is why the mod needs its own
  retaliation hooks.
- `AllowAttack` is a **no-op**. `LimitedAttack X` and `AttackFaction X` clear
  the block *and* declare war. `Declare War X` sets relations only.
- Both are **one-shot**: the engine restores the block afterwards, so the war
  mode must be re-issued every evaluation.
- One war mode per faction, last order wins: a `LimitedAttack` retaliation
  cancels an `AttackFaction` war already in force against someone else.
- Only `AttackFaction` produces ground invasions.
- Going to war **wipes all of a faction's attack blocks**. Re-blocking in the
  *same tick after* a war order **freezes the faction** (no orders, war
  dropped); two minutes later is fine. This also reset the player's warplan
  countdown.
- `GlobalAttack` forces war on everyone. Avoid.
- Peace: `CeaseFire With "X"` and `Peace Treaty With "X"` work. `Peace "X"`,
  `Peace Treaty "X"`, `Peace With "X"` and any trailing duration are parse
  errors.
- You cannot strike a **city** of a faction you are at peace with (the order
  is silently dropped), but you can strike its **units** — that is how
  contact wars start.

**Weapons**

- `ENABLE`/`DISABLE Missiles ai_category` has no visible effect; the
  **geneva** form is what actually withholds weapons. Scope with `FOR ME`.
- Weapon categories do not map cleanly to yield: 100kt/250kt ALBMs are
  AI-category *Tactical Nuclear* but carry geneva *High-Yield Nukes*, so
  keying the strategic tier off that tag promoted factions for being shelled.
- EMP warheads carry only `EMP Weapons` and were the one nuclear category the
  disable list missed.

**Other**

- Event-handler arguments are evaluated **when the event fires**, not when it
  is registered — never pass a loop variable. `build.ps1` stamps literal
  faction names into the hooks for this reason.
- `set += (a + b)` appends **both operands as separate elements**; it does not
  evaluate the expression. Caught as `ProtectedUntil {43, 10}` where 53 was
  meant, which desynced it from the `Protected` set it is indexed against.
  Compile-time constants like `(0 - 1)` are folded and do yield one element.
  Always compute into an `int` before appending.
- A stalemate `CeaseFire With` is a **request, not a result**: the war only
  ends once both sides issue one. Evaluations are staggered 40s per faction,
  so the second half lands an evaluation later and a save taken between the
  two looks like the statement did nothing. The engine ceasefire that results
  is short — about 10 game-minutes — so `PEACE_COOLDOWN_EVALS` (60 minutes)
  is what actually keeps the peace afterwards.
- `REGION_OWNER` reports the occupier while a region is merely *contested*,
  so a snapshot counts battlefields as conquests.
- `Region_Invaded` fires on mere unit presence, not on an actual assault —
  auto-deploy across a disputed border was enough to start an India-Pakistan
  war at 0:06, before any evaluation had run. It cannot be treated as an
  attack.
- Factions build one item at a time, ~0.4 cost-units per 10 game-minutes.
  Warhead-bearing items are throttled by warhead production efficiency
  (Nuclear Fuel techs cap it at 40/55/70/85/100%). AI-built units sit in
  reserve until a plan deploys them, so a late-era AI has the *tech* for
  silos and SSBNs but not the *units* for hours.
- The unit hover label is drawn by the engine from the unit type. `SET_NAME`
  does not reach it and there is no info panel for hostile units, so faction
  ownership cannot be surfaced as text. (Hence the optional palette instead.)
- Saves are plain text: `SAVES/<name>/world.txt`. Line 6 `Time <ticks>`,
  ticks/60 = displayed seconds. Each `Player` block carries `Relations`
  (0 war, 1 neutral, 2 partner, 3 permanent ally), `CeaseFire` expiry ticks,
  the AI bitscales, and — invaluably — the script's own variables under
  `VariableArray`. That is how almost every bug here was diagnosed.

## Debugging method

Read the save. `Relations` gives the war matrix; `Released` / `TotalWar` in a
faction's `VariableArray` separate *chosen* wars from reactions; `NukeTier`,
`RivalGrievance`, `RivalStandoff` show the script's reasoning. Diagnostics
live in `diagnostics/` — each probe answers one question by giving every
faction a different candidate behaviour in a throwaway game.

## Backlog

1. **Multiplayer.** Untested, and `AllowEventsInMultiplayer` is a config
   setting whose default is unknown — if events are off in MP the mod does
   nothing there. This matters: co-op is a stated use case.
2. **Earth map.** Only Iron Curtain is stamped. Adding it is ten faction
   names in `build.ps1` plus checking its `DefaultEnemy` list parses.
3. **Occupier tuning** — the motive exists but has never fired in a test.
4. **`outpaced`** has never fired either; AI build rates are so slow that
   sustained relative growth barely happens. May need a longer horizon.
5. One unexplained crash (~1:00 game time, no message in `Fatal.txt`),
   seen once, never reproduced.

## Release checklist

- [x] `DEBUG_MESSAGES` defaults to 1 (events only)
- [x] `$ColorblindPalette` defaults to `$false`
- [ ] One clean long run on the current build with no unexplained wars
- [ ] Decide: ship as Iron Curtain only, or add the Earth map first
- [ ] Decide the published name (folder says "Less Aggressive AI", the
      project is "Motivated AI")
- [ ] Workshop upload needs a preview image and tags
