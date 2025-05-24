#!/bin/bash

PORT="/dev/ttyACM0"
BAUD="9600"
TIMEOUT=10
STOPMOTION_RUNNING=0
CAPTURE_PID=0
CAPTURE_FOLDER=""
PIPE="/tmp/serial_pipe"

STREAM_LED_PIN=17
STREAM_API="http://localhost:9997/v3/paths/list"
PATH_NAME="cam"

pinctrl set $STREAM_LED_PIN op
pinctrl set $STREAM_LED_PIN dl

if [ ! -e "$PORT" ]; then
    echo "[!] Serial port $PORT not found. Exiting."
    exit 1
fi

rm -f "$PIPE"
mkfifo "$PIPE"

cleanup() {
    echo "[!] Cleaning up listener..."
    kill "$CAT_PID" 2>/dev/null
    rm -f "$PIPE"
    exit 0
}

trap cleanup SIGINT SIGTERM

stty -F "$PORT" cs8 $BAUD igncr -icanon -echo
stdbuf -oL cat "$PORT" > "$PIPE" &
CAT_PID=$!

echo "[*] Listening on $PORT..."
last_signal_time=$(date +%s)

stop_stopmotion() {
    echo "[>] Stopping StopMotion..."
    if [ "$STOPMOTION_RUNNING" -eq 1 ]; then
        if [ "$CAPTURE_PID" -gt 0 ] && kill -0 "$CAPTURE_PID" 2>/dev/null; then
            kill "$CAPTURE_PID"
            wait "$CAPTURE_PID" 2>/dev/null
        fi
	pinctrl set 17 dl

        TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
        nice -n 10 ffmpeg -y \
            -framerate 2 \
            -i "$CAPTURE_FOLDER/frame_%03d.jpg" \
            -c:v libx264 \
            -preset ultrafast \
            -crf 30 \
            -pix_fmt yuv420p \
            -r 10 \
            "/home/group7/ha_media/stopmotion_${TIMESTAMP}.mp4"

        rm -rf "$CAPTURE_FOLDER"
        STOPMOTION_RUNNING=0
        echo "[✓] StopMotion video saved."
    fi
}

while true; do

    viewers=$(curl -s "$STREAM_API" | jq ".items[] | select(.name==\"$PATH_NAME\") | .readers | length")
    if [ "$STOPMOTION_RUNNING" -eq 0 ]; then
	    if [[ "$viewers" -gt 0 ]]; then
		pinctrl set 17 dh
		echo "Stream has viewers — LED ON (GPIO 17)"
	    else
		pinctrl set 17 dl
		echo "Stream has no viewers — LED OFF (GPIO 17)"
	    fi
	fi

    if read -t 1 -r line < "$PIPE"; then
        echo "[Serial] $line"
        now=$(date +%s)

        if [[ "$line" == "motion" || "$line" == "touch" ]]; then
            last_signal_time=$now
            echo "[Event] Detected: $line"

            if [ "$STOPMOTION_RUNNING" -eq 0 ]; then
                echo "[>] Starting StopMotion..."
                TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
                CAPTURE_FOLDER="/home/group7/Desktop/camera/frames/$TIMESTAMP"
                mkdir -p "$CAPTURE_FOLDER"

		pinctrl set 17 dh
                nohup python3 /home/group7/Desktop/camera/stopmotion.py "$CAPTURE_FOLDER" > /tmp/stopmotion.log 2>&1 &
                CAPTURE_PID=$!
                STOPMOTION_RUNNING=1
            fi

            if [[ "$line" == "touch" ]]; then
                echo "[>] Sending doorbell notification..."
                curl -X POST \
                    -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiI4ZWVmZDFjNmU3MjE0NDhjOWRmYTIxNjVkMTVhMjkyZSIsImlhdCI6MTc0NjM3MDI2MCwiZXhwIjoyMDYxNzMwMjYwfQ.Dv2A0Vu96VUyN4vt2k_IFMYOGRq43lQK-fYM0bQG318" \
                    -H "Content-Type: application/json" \
                    -d '{"message": "Someone rang the doorbell!"}' \
                    http://192.168.1.86:8123/api/services/notify/notify
            fi
        fi
    fi

    now=$(date +%s)
    elapsed=$((now - last_signal_time))

    if [ "$STOPMOTION_RUNNING" -eq 1 ]; then
    	if ! kill -0 "$CAPTURE_PID" 2>/dev/null; then
	    echo "[!] StopMotion process finalizou inesperadamente."
	    STOPMOTION_RUNNING=0
	    pinctrl set $STREAM_LED_PIN dl
	fi
        if [ "$elapsed" -ge "$TIMEOUT" ]; then
            echo "[!] Timeout reached ($elapsed s)"
            stop_stopmotion
    	elif [[ "$viewers" -gt 0 ]]; then
            echo "[!] Stream is active → stopping"
            stop_stopmotion
        fi
    fi

done
