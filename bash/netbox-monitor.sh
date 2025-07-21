curl -s -H "Authorization: Token X" 'https://netbox/api/ipam/ip-addresses/?limit=0' | jq -s '
  [ .[].results[]
    | select(.custom_fields.Ping == true)
    | select(.assigned_object.device != null)
    | {
        ip: (.address | split("/")[0]),
        device: .assigned_object.device.name,
        description: .description,
        device_description: .assigned_object.device.description,
        status: "unknown"
      }
  ]
' > ips.json

JSON_FILE="/data/ping/ips.json"
TMP_FILE="/data/ping/ips.tmp.json"
updated_entries=()

# Read each JSON entry
while IFS= read -r entry; do
    ip=$(jq -r '.ip' <<< "$entry")
    device=$(jq -r '.device' <<< "$entry")

    [[ -z "$ip" ]] && continue

    if ping -c 1 -W 1 "$ip" > /dev/null 2>&1; then
        status="success"
    else
        status="failed"
        echo "FAIL: $ip ($device)"
    fi

    # Update the full original entry with new status
    updated_entry=$(jq --arg status "$status" '.status = $status' <<< "$entry")
    updated_entries+=("$updated_entry")

done < <(jq -c '.[]' "$JSON_FILE")

# Combine all updated entries into valid JSON array
jq -s '.' <<< "${updated_entries[@]}" > "$TMP_FILE" && mv "$TMP_FILE" "$JSON_FILE"
