#!/bin/bash
# Real-time Cowrie monitoring script
# Shows live events as they happen

COWRIE_LOG="cowrie/var/log/cowrie/cowrie.json"
BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ ! -f "$COWRIE_LOG" ]; then
    echo "Error: Cowrie log file not found at $COWRIE_LOG"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is required. Install it with: sudo apt-get install jq"
    exit 1
fi

echo -e "${BOLD}=== Cowrie Real-Time Monitor ===${NC}"
echo -e "${CYAN}Monitoring: $COWRIE_LOG${NC}"
echo -e "${CYAN}Press Ctrl+C to stop${NC}\n"

tail -f "$COWRIE_LOG" | while read -r line; do
    EVENTID=$(echo "$line" | jq -r '.eventid // empty')
    TIMESTAMP=$(echo "$line" | jq -r '.timestamp // empty')
    
    case "$EVENTID" in
        "cowrie.session.connect")
            SRC_IP=$(echo "$line" | jq -r '.src_ip')
            echo -e "${GREEN}[CONNECT]${NC} $TIMESTAMP - New connection from ${BOLD}$SRC_IP${NC}"
            ;;
        "cowrie.login.success")
            USERNAME=$(echo "$line" | jq -r '.username')
            PASSWORD=$(echo "$line" | jq -r '.password')
            SRC_IP=$(echo "$line" | jq -r '.src_ip')
            echo -e "${YELLOW}[LOGIN SUCCESS]${NC} $TIMESTAMP - ${BOLD}$USERNAME${NC}:${BOLD}$PASSWORD${NC} from $SRC_IP"
            ;;
        "cowrie.login.failed")
            USERNAME=$(echo "$line" | jq -r '.username')
            PASSWORD=$(echo "$line" | jq -r '.password')
            SRC_IP=$(echo "$line" | jq -r '.src_ip')
            echo -e "${RED}[LOGIN FAILED]${NC} $TIMESTAMP - ${BOLD}$USERNAME${NC}:${BOLD}$PASSWORD${NC} from $SRC_IP"
            ;;
        "cowrie.command.input")
            INPUT=$(echo "$line" | jq -r '.input')
            echo -e "${BLUE}[COMMAND]${NC} $TIMESTAMP - ${BOLD}$INPUT${NC}"
            ;;
        "cowrie.session.file_download")
            URL=$(echo "$line" | jq -r '.url')
            OUTFILE=$(echo "$line" | jq -r '.outfile')
            echo -e "${CYAN}[DOWNLOAD]${NC} $TIMESTAMP - ${BOLD}$URL${NC} -> $OUTFILE"
            ;;
        "cowrie.session.closed")
            DURATION=$(echo "$line" | jq -r '.duration')
            echo -e "${RED}[DISCONNECT]${NC} $TIMESTAMP - Session closed (duration: ${DURATION}s)"
            ;;
        *)
            # Show other events in gray
            if [ -n "$EVENTID" ]; then
                echo -e "\033[0;90m[OTHER]${NC} $TIMESTAMP - $EVENTID"
            fi
            ;;
    esac
done

