#!/bin/bash

COLOR=16711680
DISCORD_USER="<@&1367481526010249326>"
WEBHOOK_URL=$(</data/webhook.txt)

GOOD_CODES="200 301 302 303"

for URL_FILE in /data/https/urls*.txt; do
  [[ ! -f "$URL_FILE" ]] && continue

  while IFS= read -r url; do
    url="${url//$'\r'/}"
    [[ -z "$url" || "$url" =~ ^# ]] && continue
    status_code=$(curl -o /dev/null -s -w "%{http_code}" --max-time 5 -L "https://$url")

    if ! grep -qw "$status_code" <<< "$GOOD_CODES"; then
      # Safely build JSON using jq
      payload=$(jq -n \
        --arg content "$DISCORD_USER | **https://$url** returned status code $status_code ❌" \
        '{content: $content}')

      curl -s -H "Content-Type: application/json" \
           -X POST \
           -d "$payload" \
           "$WEBHOOK_URL"
    fi
  done < "$URL_FILE"
done