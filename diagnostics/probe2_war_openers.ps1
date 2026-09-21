# Less Aggressive AI - PROBE 2 (diagnostic, not for play)
#
# Question: which way of opening a war actually makes the AI FIGHT?
# Each faction blocks everyone at start, then at 20:00 (after auto-deploy)
# opens a war on the United States in a different way.  Let the game run to
# ~35:00, save, then compare per faction: relations, bitscales, number of
# units with orders, plan counts, and whether anything attacked you.
#
#   Soviet Union   AttackFaction, once
#   NATO           AttackFaction, re-issued every 2 min  (what the mod did)
#   Warsaw Pact    Declare War + AttackFaction + GlobalAttack  (campaign form)
#   American Allies  AttackFaction + GlobalAttack
#   Soviet Allies  LimitedAttack, once
#   China          LimitedAttack, re-issued every 2 min
#   India          GlobalAttack only (everyone but the US still blocked)
#   Pakistan       control: block all, nothing else
#   Neutral        Declare War only
#
# Restore the real mod afterwards with:  powershell -File build.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$dir  = Join-Path $root 'Maps\IronCurtain.virtual\Events'
New-Item -ItemType Directory -Force $dir | Out-Null

$all = @('United States','Soviet Union','NATO','Warsaw Pact','American Allies',
         'Soviet Allies','China','India','Pakistan','Neutral')
function BlockAll($self) { ($all | Where-Object { $_ -ne $self } | ForEach-Object { "  BlockAttack `"$_`"`n  BlockInvasion `"$_`"" }) -join "`n" }

$probe = @{
  'Soviet Union'    = "BLOCK Go()`n  AttackFaction `"United States`"`n  AllowInvasion `"United States`"`nEND`n`nFOR AI`n" + (BlockAll 'Soviet Union') + "`n  ON TICK +MINUTES(20) Go()"
  'NATO'            = "BLOCK Go()`n  AttackFaction `"United States`"`n  AllowInvasion `"United States`"`nEND`n`nFOR AI`n" + (BlockAll 'NATO') + "`n  ON TICK +MINUTES(20) Go()`n  ON EACH TICK +MINUTES(2) Go()"
  'Warsaw Pact'     = "BLOCK Go()`n  Declare War `"United States`"`n  AttackFaction `"United States`"`n  AllowInvasion `"United States`"`n  GlobalAttack`nEND`n`nFOR AI`n" + (BlockAll 'Warsaw Pact') + "`n  ON TICK +MINUTES(20) Go()"
  'American Allies' = "BLOCK Go()`n  AttackFaction `"United States`"`n  AllowInvasion `"United States`"`n  GlobalAttack`nEND`n`nFOR AI`n" + (BlockAll 'American Allies') + "`n  ON TICK +MINUTES(20) Go()"
  'Soviet Allies'   = "BLOCK Go()`n  LimitedAttack `"United States`"`nEND`n`nFOR AI`n" + (BlockAll 'Soviet Allies') + "`n  ON TICK +MINUTES(20) Go()"
  'China'           = "BLOCK Go()`n  LimitedAttack `"United States`"`nEND`n`nFOR AI`n" + (BlockAll 'China') + "`n  ON TICK +MINUTES(20) Go()`n  ON EACH TICK +MINUTES(2) Go()"
  'India'           = "BLOCK Go()`n  GlobalAttack`nEND`n`nFOR AI`n" + (($all | Where-Object { $_ -ne 'India' -and $_ -ne 'United States' } | ForEach-Object { "  BlockAttack `"$_`"`n  BlockInvasion `"$_`"" }) -join "`n") + "`n  ON TICK +MINUTES(20) Go()"
  'Pakistan'        = "FOR AI`n" + (BlockAll 'Pakistan')
  'Neutral'         = "BLOCK Go()`n  Declare War `"United States`"`nEND`n`nFOR AI`n" + (BlockAll 'Neutral') + "`n  ON TICK +MINUTES(20) Go()"
}

foreach ($f in $all) {
  if (-not $probe.ContainsKey($f)) { continue }
  $txt = "// PROBE 2 build - diagnostic only (see build_probe2.ps1)`n`n" + $probe[$f] + "`n`nFOR BOTH`n`nEND`n"
  [IO.File]::WriteAllText((Join-Path $dir "$f.txt"), $txt, (New-Object Text.UTF8Encoding($false)))
}
Remove-Item (Join-Path $dir 'United States.txt') -ErrorAction SilentlyContinue
Write-Host "PROBE 2 files written for $($probe.Count) factions. Run build.ps1 to restore the mod."
