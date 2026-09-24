# Project notes

Working notes for whoever picks this up — including future me. The README
describes what the mod *does*; this is how it works underneath, what the
engine actually allows, and what is left to do.

## Where things stand

Version 2.5.0, the first release candidate. Everything below has been verified in play
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
- **Stalemate stand-down, verified end to end** (run of 2026-09-23, eval 43):
  Soviet Union and NATO both stood down against Soviet Allies, Soviet Allies
  reciprocated on its own eval 43, and the engine ended both wars. The peace
  survived the engine ceasefire lapsing 10 minutes later and held for at
  least two further evaluations.
- Territorial loss having to be *held* for three evaluations — NATO, the
  Soviet Union and Soviet Allies each reached `RegionsLostStreak 3` and
  authorised strategic weapons off real conquest, not contested border ticks
- Aircraft-at-home no longer provoke (no phantom war in a 4.5-hour run)
- A border crossing as a grievance rather than an attack
- Survives save/load; staggered evaluations keep the frame cost flat

All of the above re-verified on the current build in the run of 2026-09-24,
which also settled the four fixes that had no evidence behind them:

- **No duplicates** in `Released` / `TotalWar` — 16 war entries across six
  factions, every one exact (`84f94a6`)
- **The peace cooldown lasts** — `ProtectedUntil = {43}` and `{44}`, single
  elements, each `EvalCount + 10`, on both sides of a real ceasefire
  (`c0e0d49`). It read `{43, 10}` and expired on creation the day before.
- **The powder keg** — four factions carried kill-grievances against
  factions they never declared on (`5a0c5c7`)
- **A 12-evaluation stalemate** fires on schedule: China stood down against
  the Soviet Union at eval 33, exactly 12 after `WarSince 21` (`ba3b02b`)
- **The `ON Destroyed anything ATTACKER "X"` hook** registers and attributes
  correctly to the faction, human players included

- **A vital region about to fall authorises strategic immediately**
  (`1ce6f1c`). Forced on 2026-09-24 by playing India and invading Pakistan,
  whose single region is 100% of its economy:

      Pakistan authorises TACTICAL nuclear weapons: holding Pakistan
        (11 invaders v 0 defenders)
      Pakistan authorises STRATEGIC nuclear weapons: existential:
        may lose Pakistan (11 invaders v 0 defenders)

  Both tiers in one pass, on the evaluation *after* the war opened, with
  `RegionsLostStreak = 0` — so the attrition path contributed nothing and
  this was the instant path alone. Note it needs an actual **invasion**:
  the check counts enemy ground units in the region, and a faction fighting
  four limited wars never sees one. In an earlier game Pakistan was at war
  with four factions for an hour and none of them invaded.

**Not yet tested in play**

- EMP as a tactical weapon (the tier worked; no EMP was observed fired)
- The **negative** half of the vital-region test: invaders present but
  *fewer* than defenders, which must NOT authorise. Only the positive half
  was run. Worth knowing that with the ratio at 100% a lone invader in an
  *undefended* vital region does fire, since `DefSafe` clamps to 1 — for a
  one-region nation that reads as correct, but it is the edge to check if
  the trigger ever feels hasty.

**`LOSS_WAR_LOSSES` is a long stop, not a normal path.** The "three losses
means war regardless of score" backstop has never fired and in practice
almost cannot. `OnAttackedBy` only counts while the attacker is **not**
already in `Released`, and factions at peace rarely shoot each other at all —
AI units do not engage a faction they are not at war with unless ordered. So
the first kill's +70 grievance (or the engine's own contact-war rule) starts
the war, which closes the guard and freezes the counter at one. Across a
four-hour ten-faction game, all fifteen nonzero loss counters read exactly 1
and not one ever reached 2. Left in as a harmless backstop; the README no
longer advertises it as a normal route to war. If it is ever wanted as a real
behaviour, the useful version is counting losses *during* a war and using the
threshold to escalate a limited war into a full one.

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
  contact wars start. Confirmed from the player's side: bombing NATO
  installations put the two at war through the **engine**, not the script.
  The victim's message then reads `at war` (the `RespondToWar` reason), not
  a scored motive — so a declaration whose reason is `at war` means the
  engine got there first and the script merely picked a mode for it.

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
  ticks/60 = displayed seconds — **floor it**; PowerShell's `[int]` cast
  rounds to nearest and silently reported every game clock an hour high.
  The save *folder* mtime is stale, so find the newest run by the inner
  `world.txt`, and note the game reuses `SAVE1` etc. regardless of the name
  typed in the UI. Each `Player` block carries `Relations`
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

Items 1 and 2 are **not backlog any more** — they are the two things the
release is waiting on. See the checklist at the end.

1. **Multiplayer.** `AllowEventsInMultiplayer` **defaults to `true`** (line 87
   of `Documents\My Games\ICBM-Escalation\ICBM.CFG`, unedited), so events do
   run in MP and the mod should work. Still unverified in an actual session:
   whether every player needs the mod installed (almost certainly yes, or the
   clients desync), and whether the host's copy of the setting governs.
2. **Earth map.** Plumbing is done — set `$IncludeEarthMap = $true` in
   `build.ps1` and all ten faction files generate, rivalries and all. Left
   **off** because it has never been played. Two traps it already handles:
   the map folder `EarthRRUltraV3.virtual` is described by `EarthRRUltra.txt`
   (not `EarthRRUltraV3.txt`), and `Central/South Asia` writes to
   `Central-South Asia.txt` while keeping the slashed name inside the script.
   The colourblind palette is Iron Curtain only; Earth keeps vanilla colours.
3. **Occupier tuning** — the motive exists but has never fired in a test.
4. **`outpaced`** has never fired either; AI build rates are so slow that
   sustained relative growth barely happens. May need a longer horizon.
5. One unexplained crash (~1:00 game time, no message in `Fatal.txt`),
   seen once, never reproduced.
6. **A late game becomes a free-for-all.** By 4:30 in the 2026-09-23 run all
   ten factions were at war, 26 pairs, six at strategic. Each war was
   individually well-motivated — the leash, the scoring and the nuclear tiers
   all behaved — but wars accumulate faster than the stalemate drains them,
   because a stand-down needs 20 evaluations of *no ground changing hands*
   and the Warsaw Pact (6 → 18 regions) and China (10 → 22) kept
   disqualifying pairs by winning. If the intent is that a map should settle
   rather than saturate, the drain needs to be faster than the fill: a
   shorter `STALEMATE_EVALS`, or a stand-down path for a war that is being
   *lost* rather than only one that is going nowhere.

## Release checklist

- [x] `DEBUG_MESSAGES` defaults to 1 (events only)
- [x] `$ColorblindPalette` defaults to `$false`
- [x] One clean long run on the current build with no unexplained wars
      (2026-09-24, four hours: standoffs into wars, a stalemate ceasefire,
      tactical and strategic both earned, no cascade, four factions never
      dragged in)
- [x] Every behavioural change verified in play
- [x] **Published as "Motivated AI"** (`info.txt`, which is what the game's
      mod list and the Workshop page read). The repo folder is still
      `LessAggressiveAI`; that name is now cosmetic and can be changed
      whenever nothing is running out of it.

**2.5.0 is a complete, shippable Iron Curtain build.** Publication is
deliberately held back to widen the first release rather than to fix
anything. Two things to do first:

- [ ] **Earth map.** Flip `$IncludeEarthMap = $true` and play it. The
      plumbing is verified — ten faction files generate with correct
      rivalries and staggered offsets — but nobody has played a game on it.
      Watch the motives that are geography-dependent: land grab (different
      borders, no Neutral-equivalent with 93 regions), blindness, and the
      economy percentages behind the nuclear tiers, since Earth's ten
      factions may not be production-balanced the way Iron Curtain's are.
- [ ] **Multiplayer with a second player.** `AllowEventsInMultiplayer`
      defaults to `true`, so events should run. Unknown: whether every
      client needs the mod (almost certainly yes, or they desync) and
      whether the host's copy of the setting is the one that counts.

Then:

- [ ] Workshop upload needs a preview image and tags
- [ ] Say plainly on the Workshop page which maps are supported and what the
      co-op requirements are
