#!/bin/bash
# Cowrie Log Analysis Script
# Provides quick statistics and insights from Cowrie logs

set -e

COWRIE_LOG="cowrie/var/log/cowrie/cowrie.json"
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [ ! -f "$COWRIE_LOG" ]; then
    echo "Error: Cowrie log file not found at $COWRIE_LOG"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Install it with: sudo apt-get install jq"
    exit 1
fi

echo -e "${BOLD}=== Cowrie Honeypot Analysis ===${NC}\n"

# Total sessions
echo -e "${BLUE}${BOLD}📊 Session Statistics${NC}"
TOTAL_SESSIONS=$(jq -r 'select(.eventid=="cowrie.session.connect")' "$COWRIE_LOG" | wc -l)
echo "Total sessions: $TOTAL_SESSIONS"

# Successful logins
SUCCESS_LOGINS=$(jq -r 'select(.eventid=="cowrie.login.success")' "$COWRIE_LOG" | wc -l)
echo "Successful logins: $SUCCESS_LOGINS"

# Failed logins
FAILED_LOGINS=$(jq -r 'select(.eventid=="cowrie.login.failed")' "$COWRIE_LOG" | wc -l)
echo "Failed logins: $FAILED_LOGINS"

# Commands executed
COMMANDS=$(jq -r 'select(.eventid=="cowrie.command.input")' "$COWRIE_LOG" | wc -l)
echo "Commands executed: $COMMANDS"

# Files downloaded
DOWNLOADS=$(jq -r 'select(.eventid=="cowrie.session.file_download")' "$COWRIE_LOG" | wc -l)
echo "Files downloaded: $DOWNLOADS"

echo ""

# Top 10 attacking IPs
echo -e "${BLUE}${BOLD}🌍 Top 10 Attacking IP Addresses${NC}"
jq -r 'select(.eventid=="cowrie.session.connect") | .src_ip' "$COWRIE_LOG" | \
    sort | uniq -c | sort -rn | head -10 | \
    awk '{printf "  %5d  %s\n", $1, $2}'

echo ""

# Top 10 usernames
echo -e "${BLUE}${BOLD}👤 Top 10 Attempted Usernames${NC}"
jq -r 'select(.eventid=="cowrie.login.success" or .eventid=="cowrie.login.failed") | .username' "$COWRIE_LOG" | \
    sort | uniq -c | sort -rn | head -10 | \
    awk '{printf "  %5d  %s\n", $1, $2}'

echo ""

# Top 10 passwords
echo -e "${BLUE}${BOLD}🔑 Top 10 Attempted Passwords${NC}"
jq -r 'select(.eventid=="cowrie.login.success" or .eventid=="cowrie.login.failed") | .password' "$COWRIE_LOG" | \
    sort | uniq -c | sort -rn | head -10 | \
    awk '{printf "  %5d  %s\n", $1, $2}'

echo ""

# Top 10 commands
echo -e "${BLUE}${BOLD}⌨️  Top 10 Executed Commands${NC}"
jq -r 'select(.eventid=="cowrie.command.input") | .input' "$COWRIE_LOG" | \
    sort | uniq -c | sort -rn | head -10 | \
    awk '{printf "  %5d  %s\n", $1, $2}'

echo ""

# Downloaded files
echo -e "${BLUE}${BOLD}📥 Downloaded Files (URLs)${NC}"
DOWNLOAD_COUNT=$(jq -r 'select(.eventid=="cowrie.session.file_download") | .url' "$COWRIE_LOG" | wc -l)
if [ "$DOWNLOAD_COUNT" -gt 0 ]; then
    jq -r 'select(.eventid=="cowrie.session.file_download") | "\(.timestamp) - \(.url)"' "$COWRIE_LOG" | head -20
else
    echo "  No files downloaded yet"
fi

echo ""

# Unique countries (if geoip data available)
echo -e "${BLUE}${BOLD}🗺️  Attack Sources by Country${NC}"
COUNTRIES=$(jq -r 'select(.src_ip) | .src_ip' "$COWRIE_LOG" | sort -u | wc -l)
echo "Unique IP addresses: $COUNTRIES"

echo ""

# Recent activity (last 10 events)
echo -e "${BLUE}${BOLD}🕐 Recent Activity (Last 10 Events)${NC}"
tail -10 "$COWRIE_LOG" | jq -r '"\(.timestamp) - \(.eventid) - \(.message // .src_ip // "")"'

echo ""
echo -e "${GREEN}Analysis complete!${NC}"
echo -e "Full logs available at: ${YELLOW}$COWRIE_LOG${NC}"

