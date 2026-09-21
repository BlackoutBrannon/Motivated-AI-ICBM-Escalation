# Less Aggressive AI - PROBE 3 (diagnostic, not for play)
#
# Question: after a faction goes to war (AttackFaction on the US at 20:00,
# which wipes ALL its attack blocks), how can the leash on everyone ELSE be
# put back without freezing the faction or cancelling its war?
#
#   Soviet Union     AttackFaction only (baseline - no re-block)
#   NATO             +2 min: BlockAttack every other faction (not the US)
#   Warsaw Pact      +2 min: BlockInvasion every other faction
#   American Allies  same tick, AFTER AttackFaction: BlockAttack others   (what the mod did)
#   Soviet Allies    same tick, BEFORE AttackFaction: BlockAttack others
#   China            every 2 min: AttackFaction US, then BlockAttack others (mod's re-issue pattern)
#   India            every 2 min: BlockAttack others, then AttackFaction US
#   Pakistan         control: block all, nothing else
#   Neutral          +2 min: BlockAttack ONE other faction only (China)
#
# Run to ~35:00, save.  Compare: force bit, BlockedAttack, units with orders,
# and wars started with anyone other than the US.
# Restore the real mod afterwards with:  powershell -File build.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$dir  = Join-Path $root 'Maps\IronCurtain.virtual\Events'
New-Item -ItemType Directory -Force $dir | Out-Null

$all = @('United States','Soviet Union','NATO','Warsaw Pact','American Allies',
         'Soviet Allies','China','India','Pakistan','Neutral')
function BlockAll($self)     { ($all | Where-Object { $_ -ne $self } | ForEach-Object { "  BlockAttack `"$_`"`n  BlockInvasion `"$_`"" }) -join "`n" }
function BlockOthers($self)  { ($all | Where-Object { $_ -ne $self -and $_ -ne 'United States' } | ForEach-Object { "  BlockAttack `"$_`"" }) -join "`n" }
function BlockInvOthers($self) { ($all | Where-Object { $_ -ne $self -and $_ -ne 'United States' } | ForEach-Object { "  BlockInvasion `"$_`"" }) -join "`n" }
$war = "  AttackFaction `"United States`"`n  AllowInvasion `"United States`""

$probe = @{
  'Soviet Union'    = "BLOCK Go()`n$war`nEND`n`nFOR AI`n" + (BlockAll 'Soviet Union') + "`n  ON TICK +MINUTES(20) Go()"
  'NATO'            = "BLOCK Go()`n$war`nEND`nBLOCK Reblock()`n" + (BlockOthers 'NATO') + "`nEND`n`nFOR AI`n" + (BlockAll 'NATO') + "`n  ON TICK +MINUTES(20) Go()`n  ON TICK +MINUTES(22) Reblock()"
  'Warsaw Pact'     = "BLOCK Go()`n$war`nEND`nBLOCK Reblock()`n" + (BlockInvOthers 'Warsaw Pact') + "`nEND`n`nFOR AI`n" + (BlockAll 'Warsaw Pact') + "`n  ON TICK +MINUTES(20) Go()`n  ON TICK +MINUTES(22) Reblock()"
  'American Allies' = "BLOCK Go()`n$war`n" + (BlockOthers 'American Allies') + "`nEND`n`nFOR AI`n" + (BlockAll 'American Allies') + "`n  ON TICK +MINUTES(20) Go()"
  'Soviet Allies'   = "BLOCK Go()`n" + (BlockOthers 'Soviet Allies') + "`n$war`nEND`n`nFOR AI`n" + (BlockAll 'Soviet Allies') + "`n  ON TICK +MINUTES(20) Go()"
  'China'           = "BLOCK Go()`n$war`n" + (BlockOthers 'China') + "`nEND`n`nFOR AI`n" + (BlockAll 'China') + "`n  ON TICK +MINUTES(20) Go()`n  ON EACH TICK +MINUTES(2) Go()"
  'India'           = "BLOCK Go()`n" + (BlockOthers 'India') + "`n$war`nEND`n`nFOR AI`n" + (BlockAll 'India') + "`n  ON TICK +MINUTES(20) Go()`n  ON EACH TICK +MINUTES(2) Go()"
  'Pakistan'        = "FOR AI`n" + (BlockAll 'Pakistan')
  'Neutral'         = "BLOCK Go()`n$war`nEND`nBLOCK Reblock()`n  BlockAttack `"China`"`nEND`n`nFOR AI`n" + (BlockAll 'Neutral') + "`n  ON TICK +MINUTES(20) Go()`n  ON TICK +MINUTES(22) Reblock()"
}

foreach ($f in $all) {
  if (-not $probe.ContainsKey($f)) { continue }
  $txt = "// PROBE 3 build - diagnostic only (see build_probe3.ps1)`n`n" + $probe[$f] + "`n`nFOR BOTH`n`nEND`n"
  [IO.File]::WriteAllText((Join-Path $dir "$f.txt"), $txt, (New-Object Text.UTF8Encoding($false)))
}
Remove-Item (Join-Path $dir 'United States.txt') -ErrorAction SilentlyContinue
Write-Host "PROBE 3 files written for $($probe.Count) factions. Run build.ps1 to restore the mod."
