#!/usr/bin/env bash
# ~/.agents/token_summary.sh
# Daily token usage summary from Copilot OTel file exporter.
#
# Prerequisites:
#   ~/.zshrc must contain:
#     export COPILOT_OTEL_FILE_EXPORTER_PATH=~/.copilot/logs/otel.jsonl
#
# Usage:
#   bash ~/.agents/token_summary.sh           # today's usage
#   bash ~/.agents/token_summary.sh --all     # all-time totals
#   bash ~/.agents/token_summary.sh --alert   # exit 1 if over daily threshold

set -euo pipefail

OTEL_LOG="${COPILOT_OTEL_FILE_EXPORTER_PATH:-$HOME/.copilot/logs/otel.jsonl}"
DAILY_WARN_THRESHOLD=200000    # tokens — yellow alert
DAILY_CRIT_THRESHOLD=500000    # tokens — red alert
MODE="${1:-}"

# ──────────────────────────────────────────────
# Helper: check dependencies
# ──────────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
  echo "❌ python3 is required but not found." >&2
  exit 1
fi

if [[ ! -f "$OTEL_LOG" ]]; then
  echo "⚠️  OTel log not found at: $OTEL_LOG"
  echo "   Make sure COPILOT_OTEL_FILE_EXPORTER_PATH is set in ~/.zshrc"
  echo "   and at least one gh copilot session has run since then."
  exit 0
fi

# ──────────────────────────────────────────────
# Parse tokens by model (today or all-time)
# ──────────────────────────────────────────────
TODAY=$(date '+%Y-%m-%d')

python3 - "$OTEL_LOG" "$MODE" "$TODAY" "$DAILY_WARN_THRESHOLD" "$DAILY_CRIT_THRESHOLD" <<'PYEOF'
import sys, json, os
from collections import defaultdict

log_path, mode, today, warn_t, crit_t = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]), int(sys.argv[5])

by_model_today   = defaultdict(int)
by_model_all     = defaultdict(int)
sessions_today   = set()
sessions_all     = set()
tool_calls_today = defaultdict(int)

with open(log_path) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            d = json.loads(line)
        except json.JSONDecodeError:
            continue

        name  = d.get("name", "")
        attrs = d.get("attributes", {})
        ts    = d.get("timestamp", "")
        val   = d.get("value", 0)
        model = attrs.get("gen_ai.model", "unknown")
        sess  = attrs.get("session.id", "")
        tok_type = attrs.get("gen_ai.token.type", "")

        is_today = ts.startswith(today)

        # Token usage
        if name == "gen_ai.client.token.usage" and tok_type == "input":
            by_model_all[model] += val
            sessions_all.add(sess)
            if is_today:
                by_model_today[model] += val
                sessions_today.add(sess)

        # Tool calls (today only)
        if is_today and name == "github.copilot.tool.call.count":
            tool = attrs.get("tool.name", "unknown")
            tool_calls_today[tool] += int(val)

total_today = sum(by_model_today.values())
total_all   = sum(by_model_all.values())

print(f"\n{'='*54}")
print(f"  GitHub Copilot — Token Usage Report")
print(f"  Date: {today}")
print(f"{'='*54}")

print(f"\n📊 TODAY ({today})")
print(f"  Sessions: {len(sessions_today)}")
if by_model_today:
    for m, t in sorted(by_model_today.items(), key=lambda x: -x[1]):
        bar = "█" * min(30, t // 5000)
        print(f"  {m:<35} {t:>8,} tokens  {bar}")
    print(f"  {'TOTAL':<35} {total_today:>8,} tokens")
else:
    print("  No token data for today (yet).")

# Alert thresholds
if total_today >= crit_t:
    print(f"\n🔴 CRITICAL: {total_today:,} tokens today (limit: {crit_t:,})")
    print("   → Run /compact before starting new sessions")
elif total_today >= warn_t:
    print(f"\n🟡 WARNING:  {total_today:,} tokens today (threshold: {warn_t:,})")
    print("   → Consider /compact for long sessions")
else:
    print(f"\n✅ Under daily threshold ({total_today:,} / {warn_t:,} warning level)")

if tool_calls_today:
    print(f"\n🔧 TOP TOOL CALLS TODAY")
    for tool, count in sorted(tool_calls_today.items(), key=lambda x: -x[1])[:10]:
        print(f"  {tool:<45}  {count:>4}x")

if "--all" in mode or mode == "--all":
    print(f"\n📈 ALL-TIME TOTALS")
    print(f"  Total sessions: {len(sessions_all)}")
    for m, t in sorted(by_model_all.items(), key=lambda x: -x[1]):
        print(f"  {m:<35} {t:>10,} tokens")
    print(f"  {'TOTAL':<35} {total_all:>10,} tokens")

print(f"\n{'='*54}\n")

# Exit code for --alert mode
if "--alert" in mode or mode == "--alert":
    if total_today >= crit_t:
        sys.exit(2)
    elif total_today >= warn_t:
        sys.exit(1)
PYEOF

