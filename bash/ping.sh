#!/bin/bash

COLOR=16711680
DISCORD_USER="<@&1367481526010249326>"
WEBHOOK_URL=$(</data/webhook.txt)

for IP_FILE in /data/ping/ip*.txt; do
    [[ ! -f "$IP_FILE" ]] && continue

    while IFS= read -r ip; do
    [[ -z "$ip" || "$ip" =~ ^# ]] && continue

    ping -c 1 -W 1 "$ip" > /dev/null 2>&1 || {
        curl -s -H "Content-Type: application/json" \
            -X POST \
            -d "{\"content\": \"$DISCORD_USER | **$ip** is unreachable ❌\"}" \
            "$WEBHOOK_URL"
    }

    done < "$IP_FILE"
done