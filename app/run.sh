#!/bin/sh

mkdir -p /data/worlds
mkdir -p /data/output

# TODO validate environment variables
# TODO figure out multiprocessing. For now it always generates for each message, which could be a problem if messages are coming faster than we can generate
generate_map() {
    filename="$1"
    echo "Generating map for $filename"
    if [ -f "/backups/$filename" ]; then
        world_dir="/data/worlds/${filename%.zip}"
        mkdir -p "$world_dir" || return 1
        unzip "/backups/$filename" -d "$world_dir" || return 2
        safe_name=$(sed 's/[^[:alnum:]_]//g' "$world_dir/levelname.txt")
        output_dir="/data/output/$safe_name"
        rm -rf "$output_dir"
        mkdir -p "$output_dir"
        bedrock-viz --db "$world_dir" --out "$output_dir" --html-all

        if [ -n "$WEB_HOST_TARGET" ]; then
            rsync -az "$output_dir" "${WEB_HOST_TARGET}/"
        fi
        if [ -n "$MQTT_PUBLISH_TOPIC" ]; then
            mosquitto_pub -h "$MQTT_SERVER_HOST" -I "${MQTT_CLIENT_ID:-bedrock-viz}" -q 0 -t "$MQTT_PUBLISH_TOPIC" -m "Map generated /$safe_name/index.html"
        fi
    fi
}

echo "Starting..."
if [ "$USE_SSH" = "true" ]; then
    # this image does everything as root. That's ok for now.
    mkdir -p /root/.ssh
    cp -a /ssh/* /root/.ssh/
    chown -R root:root /root/.ssh
fi

mosquitto_sub -h "$MQTT_SERVER_HOST" -I "${MQTT_CLIENT_ID:-bedrock-viz}" -q 0 -t "$MQTT_SUBSCRIBE_TOPIC" |
    jq -r --unbuffered 'select(.type == "BACKUP_COMPLETE") | .filename' |
    while read -r filename; do
        if generate_map "$filename"; then
            echo "generated"
        else
            echo "ERROR generating $filename"
        fi

    done
