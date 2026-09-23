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
# Round 3.  The parser told us the grammar over two runs:
#   `Peace "X"`         -> Expected TREATY / Expected WITH
#   `Peace Treaty "X"`  -> Expected WITH
#   `Peace ... "X" 90000` -> Unexpected ident (no duration argument)
# so the valid forms are `Peace With "X"` and `Peace Treaty With "X"`, both
# of which parse.  This round tests those two with and without a duration;
# the offer-API forms are kept as a fallback.
$try = @{
  # Only forms that have been seen to PARSE are used, because the parser stops
  # at the first bad file and everything after it is never reached - which is
  # how several forms appeared to pass in earlier rounds.
  #   Peace Treaty With "X"  parses (NATO, rounds 3-4)
  #   CeaseFire With "X"     parses (Soviet Union, round 4)
  # Rejected: Peace "X" / Peace Treaty "X" / Peace With "X" / any duration.
  'Soviet Union'    = '  CeaseFire With "United States"'
  'NATO'            = '  Peace Treaty With "United States"'
  'Warsaw Pact'     = '  CeaseFire With "United States"'
  'Neutral'         = '  Peace Treaty With "United States"'
  # the rest declare war and do nothing: controls
}

# every AI faction gets a file: candidates try their form, the rest are
# controls that just declare war (a stale file left behind from an earlier
# round would otherwise be parsed and could block the map load)
foreach ($f in $all) {
  if ($f -eq 'United States') { continue }
  $line = '  // control: no peace attempt'
  if ($try.ContainsKey($f)) { $line = $try[$f] }
  $txt = @"
// PROBE 4 build - diagnostic only (see diagnostics\probe4_peace_syntax.ps1)
// candidate form for this faction:
//$line

BLOCK GoWar()
  AttackFaction "United States"
END

BLOCK TryPeace()
$line
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
