# Less Aggressive AI - PROBE build (diagnostic, not for play)
#
# Overwrites the Iron Curtain faction event files with tiny scripts that each
# run ONE fixed command sequence at game start.  Start a game, let it reach
# the first autosave (~10 game-minutes), quit, then read each faction's
# PreferredEnemyBitscale / AttackersBitscale / ForceGlobalAttackBitscale /
# LimitedAttackBitscale / BlockedAttackBitscale / BlockedInvasionBitscale and
# Relations from SAVES\AUTO*\world.txt.
#
# Faction bits: US=1 SU=2 NATO=4 WP=8 AmAl=16 SovAl=32 China=64 India=128
#               Pak=256 Neutral=512.  "Block all" = 1023 minus own bit.
#
# Restore the real mod afterwards with:  powershell -File build.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$dir  = Join-Path $root 'Maps\IronCurtain.virtual\Events'
New-Item -ItemType Directory -Force $dir | Out-Null

$all = @('United States','Soviet Union','NATO','Warsaw Pact','American Allies',
         'Soviet Allies','China','India','Pakistan','Neutral')

function BlockAll($self) { ($all | Where-Object { $_ -ne $self } | ForEach-Object { "  BlockAttack `"$_`"" }) -join "`n" }

# faction -> commands run in FOR AI at game start
$probe = @{
  # control: block everyone -> expect BlockedAttack = 1021
  'Soviet Union'    = (BlockAll 'Soviet Union')
  # block all, then AllowAttack US -> what does Allow do?
  'NATO'            = (BlockAll 'NATO') + "`n  AllowAttack `"United States`""
  # block all, AllowAttack US, AllowAttack China -> is Allow an AND, an assignment, or a toggle?
  'Warsaw Pact'     = (BlockAll 'Warsaw Pact') + "`n  AllowAttack `"United States`"`n  AllowAttack `"China`""
  # AllowAttack US from a clean slate (nothing blocked)
  'American Allies' = "  AllowAttack `"United States`""
  # block all, AllowAttack US, then BlockAttack China again -> does a later Block re-set bits?
  'Soviet Allies'   = (BlockAll 'Soviet Allies') + "`n  AllowAttack `"United States`"`n  BlockAttack `"China`""
  # block all, then LimitedAttack US -> which bitscale changes?
  'China'           = (BlockAll 'China') + "`n  LimitedAttack `"United States`""
  # block all, then AttackFaction US -> does it override the block / change relations?
  'India'           = (BlockAll 'India') + "`n  AttackFaction `"United States`""
  # block all, then Declare War US -> relations?
  'Pakistan'        = (BlockAll 'Pakistan') + "`n  Declare War `"United States`""
  # block all, AllowInvasion US -> confirm Invasion semantics (expected 1020-style clear)
  'Neutral'         = (BlockAll 'Neutral') + "`n  AllowInvasion `"United States`""
}

foreach ($f in $all) {
  if (-not $probe.ContainsKey($f)) { continue }
  $txt = "// PROBE build - diagnostic only (see build_probe.ps1)`n`nFOR AI`n" + $probe[$f] + "`n`nFOR BOTH`n`nEND`n"
  [IO.File]::WriteAllText((Join-Path $dir "$f.txt"), $txt, (New-Object Text.UTF8Encoding($false)))
}
# United States: leave the real file out entirely (human player); remove any stale one
Remove-Item (Join-Path $dir 'United States.txt') -ErrorAction SilentlyContinue
Write-Host "PROBE files written for $($probe.Count) factions. Run build.ps1 to restore the mod."
