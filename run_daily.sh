#!/bin/bash
# Daily DevProd pipeline: research update → quality evaluation
# Logs to /Users/shankar.krishnan/DevProd/cron.log

CLAUDE="/Users/shankar.krishnan/.local/bin/claude"
LOG="/Users/shankar.krishnan/DevProd/cron.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "" >> "$LOG"
echo "========================================" >> "$LOG"
echo "[$DATE] Starting daily DevProd pipeline" >> "$LOG"
echo "========================================" >> "$LOG"

# Step 1: Research update
echo "[$DATE] Step 1/2: Running DevProd research agent..." >> "$LOG"
"$CLAUDE" -p "Run the DevProd agent: research the latest AI developer productivity news, tools, and company case studies published in the last 24-48 hours. Update the knowledge base markdown files in /Users/shankar.krishnan/DevProd/ with new findings. Update daily_update_log.md with today's date and a summary of what was found. Update index.html if there are significant new findings." \
  --dangerously-skip-permissions >> "$LOG" 2>&1

DEVPROD_EXIT=$?
echo "[$DATE] DevProd agent exited with code $DEVPROD_EXIT" >> "$LOG"

# Step 2: Evaluation (always runs, even if step 1 had issues — so we capture failures)
echo "[$DATE] Step 2/2: Running DevProdEval agent..." >> "$LOG"
"$CLAUDE" -p "Run the DevProdEval agent: evaluate the quality of today's DevProd research run. Read the files in /Users/shankar.krishnan/DevProd/, score the run on all 5 dimensions, and append the results to /Users/shankar.krishnan/DevProd/eval_log.md." \
  --dangerously-skip-permissions >> "$LOG" 2>&1

EVAL_EXIT=$?
echo "[$DATE] DevProdEval agent exited with code $EVAL_EXIT" >> "$LOG"
echo "[$DATE] Daily pipeline complete." >> "$LOG"
