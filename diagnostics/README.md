# Diagnostics

Throwaway builds used to reverse-engineer the engine's script commands from
save files. **Not for play** — each one overwrites the Iron Curtain faction
event files with a tiny experiment per faction.

| Script | Question it answered |
|---|---|
| `probe1_command_semantics.ps1` | What `BlockAttack` / `AllowAttack` / `LimitedAttack` / `AttackFaction` / `Declare War` actually do to the bitscales and relations. (`AllowAttack` is a no-op.) |
| `probe2_war_openers.ps1` | Which way of opening a war makes the AI fight, and whether re-issuing orders freezes it. (All work; `GlobalAttack` forces war on everyone.) |
| `probe4_peace_syntax.ps1` | How a script asks for peace: nine candidate forms of `Peace` / `CREATE_OFFER` / `CeaseFire`, one per faction. (Not yet run.) |
| `probe3_reblock_timing.ps1` | How to restore the leash on other factions after going to war without freezing. (Never block in the same tick after a war order; two minutes later is fine.) |

To run one: `powershell -ExecutionPolicy Bypass -File diagnostics\<probe>.ps1`,
start a new Iron Curtain game as the United States, let it reach the time
noted in the script, save, and read `SAVES\<save>\world.txt`.

Afterwards restore the real mod with `powershell -ExecutionPolicy Bypass -File build.ps1`.
