# Less Aggressive AI - PROBE 4 (diagnostic, not for play)
#
# Question: how does a script ask for peace?  The engine's statement keyword
# list contains PEACE next to DECLARE (which gives us `Declare War "X"`), and
# the function table has CREATE_OFFER / ADD_OFFER / ADD_REQUEST /
# OFFER_EXISTS - but no shipped script uses any of them, so the syntax is
# unknown.  A wrong form is a parse error that kills the whole file, which is
# why this is a probe rather than a guess in the mod.
#
# Each faction gets ONE candidate form.  At 20:00 it declares war on the US
# (so there is a war to end), and at 26:00 it tries its candidate.
#
# HOW TO READ THE RESULT
#   * Map select shows "Error parsing file ... <Faction>.txt" -> that form is
#     invalid.  Note which factions are named, hit OK, and the rest still run.
#   * A faction whose file parsed and whose relation with you returns to 1
#     (or which offers you a ceasefire) after 26:00 -> that form WORKS.
#   * Parsed but still at war at 35:00 -> parses, does nothing.
#
# Run to ~35:00, save, and read the relations rows.
# Restore the real mod afterwards with:  powershell -File ..\build.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$dir  = Join-Path $root 'Maps\IronCurtain.virtual\Events'
New-Item -ItemType Directory -Force $dir | Out-Null

$all = @('United States','Soviet Union','NATO','Warsaw Pact','American Allies',
         'Soviet Allies','China','India','Pakistan','Neutral')

# faction -> the line it runs at 26:00
$try = @{
  'Soviet Union'    = '  Peace "United States"'
  'NATO'            = '  Declare Peace "United States"'
  'Warsaw Pact'     = '  Peace With "United States"'
  'American Allies' = '  CREATE_OFFER("United States", "CeaseFire")'
  'Soviet Allies'   = '  CREATE_OFFER("United States", CeaseFire)'
  'China'           = '  def int Off = CREATE_OFFER("United States")' + "`n" + '  ADD_OFFER(Off, "CeaseFire")'
  'India'           = '  CeaseFire "United States"'
  'Pakistan'        = '  Declare CeaseFire "United States"'
  'Neutral'         = '  PEACE "United States"'
}

foreach ($f in $all) {
  if (-not $try.ContainsKey($f)) { continue }
  $txt = @"
// PROBE 4 build - diagnostic only (see diagnostics\probe4_peace_syntax.ps1)
// candidate form for this faction:
//$($try[$f])

BLOCK GoWar()
  AttackFaction "United States"
END

BLOCK TryPeace()
$($try[$f])
END

FOR AI
  ON TICK +MINUTES(20) GoWar()
  ON TICK +MINUTES(26) TryPeace()

FOR BOTH

END
"@
  [IO.File]::WriteAllText((Join-Path $dir "$f.txt"), $txt, (New-Object Text.UTF8Encoding($false)))
}
Remove-Item (Join-Path $dir 'United States.txt') -ErrorAction SilentlyContinue
Write-Host "PROBE 4 files written for $($try.Count) factions. Run build.ps1 to restore the mod."
