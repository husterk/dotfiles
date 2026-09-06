#!/bin/bash
# Claude Code subagent status line: one custom row per subagent in the agent panel.
# Input: JSON on stdin with a `tasks` array; output: one JSON line per row to override,
# in the form {"id": "<task id>", "content": "<row body>"}. ANSI escapes are JSON-encoded
# and decoded back by Claude Code, so real ESC (\033) bytes are fine here.
# Row format:  <status> label  model·effort  <tokens · ctx%>  <elapsed>
#   label = description (what this agent is doing) if present, else the agent name.
#   model is shortened: us.anthropic.claude-opus-4-8 -> opus-4-8
#   elapsed derived from startTime (epoch ms, epoch seconds, or ISO — auto-detected)

input=$(cat)

echo "$input" | jq -rc '
  def esc: "";
  def c(n): esc + "[" + (n|tostring) + "m";
  def reset: c(0);
  def dim: c(2);
  def cyan: c(36);
  def green: c(32);
  def yellow: c(33);
  def red: c(31);
  def magenta: c(35);

  def kfmt(n): if n >= 1000 then ((n/1000)|floor|tostring) + "k" else (n|tostring) end;

  # status glyph + color
  def statusmark:
    if   . == "running"   then green + "●" + reset
    elif . == "completed" then dim + "✓" + reset
    elif . == "failed"    then red + "✗" + reset
    elif . == "waiting"   then yellow + "◐" + reset
    else dim + "○" + reset end;

  # shorten model id: strip provider/region prefixes and the "claude-" stem
  #   us.anthropic.claude-opus-4-8 -> opus-4-8 ; claude-haiku-4-5-20251001 -> haiku-4-5-20251001
  def shortmodel:
    . | sub("^[a-z]+\\.anthropic\\."; "") | sub("^anthropic\\."; "") | sub("^claude-"; "");

  # startTime -> epoch seconds, tolerating ms / seconds / ISO-8601 string
  def start_epoch:
    if   type == "number" then (if . > 1e12 then . / 1000 else . end)
    elif type == "string" then (try (. | fromdateiso8601) catch (try (tonumber | if . > 1e12 then ./1000 else . end) catch null))
    else null end;

  # seconds -> compact human duration (45s, 3m, 1h2m)
  def humandur:
    (. | floor) as $s |
    if   $s < 60   then ($s|tostring) + "s"
    elif $s < 3600 then (($s/60)|floor|tostring) + "m"
    else (($s/3600)|floor|tostring) + "h" + ((($s%3600)/60)|floor|tostring) + "m" end;

  now as $now |

  .tasks[]? |
  ( .status // "" | statusmark ) as $mark |
  ( .name // .type // "agent" ) as $name |
  # lead with the description (the useful distinguisher); fall back to the name
  ( .description // .label // .name // .type // "agent" ) as $label |
  ( .model // "" ) as $model |
  ( .effort // "" ) as $effort |
  ( .tokenCount // 0 ) as $tok |
  ( .contextWindowSize // 0 ) as $win |

  # model·effort segment (only what is present)
  ( [ ($model | if . != "" then shortmodel else empty end),
      ($effort | if . != "" then . else empty end) ]
    | join("·") ) as $me |

  # context segment: absolute tokens · percentage (colored by fill), when known
  ( if $win > 0 and $tok > 0
    then (($tok * 100 / $win) | floor) as $p
      | ( if $p >= 90 then red elif $p >= 70 then yellow else dim end ) as $pc
      | dim + kfmt($tok) + " · " + reset + $pc + ($p|tostring) + "%" + reset
    else "" end ) as $ctx |

  # elapsed since start (skip for finished tasks, where it would keep growing)
  ( (.startTime // null | start_epoch) as $st |
    if $st != null and ($mark | test("●|◐"))   # running / waiting only
    then ($now - $st) as $el
      | if $el >= 0 then dim + ($el | humandur) + reset else "" end
    else "" end ) as $elapsed |

  ( [ ($mark + " " + cyan + $label + reset),
      ( if $me      != "" then dim + $me + reset else empty end ),
      ( if $ctx     != "" then $ctx else empty end ),
      ( if $elapsed != "" then $elapsed else empty end )
    ] | join("  ")
  ) as $content |

  { id: (.id // ""), content: $content }
'
