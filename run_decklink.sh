#!/bin/bash
#RTSP_PORT=$1
#RTSP_PATH=$2


# --- 1. 인자(Argument) 유효성 검사 (1 ~ 4 허용) ---
CHANNEL_ID=$1

if [[ ! "$CHANNEL_ID" =~ ^[1-4]$ ]]; then
    echo "[Error] Invalid argument: '$CHANNEL_ID'"
    echo "Usage: $0 {1|2|3|4}"
    exit 1
fi

# 0-based 인덱스 계산 (1 -> 0, 2 -> 1, ...)
IDX=$((CHANNEL_ID - 1))

# --- 2. 배열 정의 및 변수 매핑 ---
RTSP_PATHS=("decklink1" "decklink2" "decklink3" "decklink4")
DEVICE_NAMES=(
    "DeckLink 8K Pro (1)"
    "DeckLink 8K Pro (2)"
    "DeckLink 8K Pro (3)"
    "DeckLink 8K Pro (4)"
)

RTSP_PORT=8554
RTSP_PATH="${RTSP_PATHS[$IDX]}"
DEVICE_NAME="${DEVICE_NAMES[$IDX]}"



BURST_WINDOW=3
BURST_THRESHOLD=10


echo "[Config] Selected Channel: $CHANNEL_ID"
echo "[Config] Device Name     : $DEVICE_NAME"
echo "[Config] RTSP Path       : rtsp://localhost:$RTSP_PORT/$RTSP_PATH"


# ------------------------

# 1. FFmpeg 실행 명령어를 배열 변수(cmd_run)에 통째로 할당
# 배열 내부에서 "$DEVICE_NAME"을 큰따옴표로 감싸야 공백이 유지됩니다.
cmd_run2=(
    /usr/local/bin/ffmpeg 
    -loglevel warning 
    -format_code Hi59 
    -channels 2 
    -f decklink 
    -i "$DEVICE_NAME" 
    -vf "yadif=1,format=yuv420p" 
    -c:v h264 
    -tune zerolatency 
    -preset:v veryfast 
    -bf 0 
    -delay 0 
    -g 30 
    -b:v 2000k 
    -c:a libopus 
    -b:a 128k 
    -f rtsp 
    "rtsp://localhost:$RTSP_PORT/$RTSP_PATH"
)

cmd_run=(
    /usr/local/bin/ffmpeg 
    -loglevel warning 
    -format_code Hi59 
    -channels 2 
    -f decklink 
    -i "$DEVICE_NAME" 
    -vf "yadif=1,format=nv12" 
    -c:v h264_nvenc
    -preset p1
    -tune ull
    -bf 0 
    -delay 0 
    -g 30 
    -b:v 2000k 
    -c:a libopus 
    -b:a 128k 
    -f rtsp 
    "rtsp://localhost:$RTSP_PORT/$RTSP_PATH"
)



# MediaMTX가 스크립트를 종료할 때 자식 프로세스까지 확실히 죽이도록 시그널 트랩 추가
trap 'pkill -P $$; exit 0' SIGINT SIGTERM
echo "[Monitor] script PID is $$"
while true; do
    echo "[Monitor] Starting FFmpeg..."
    
    # 2. 실행 전 터미널에 명령어 전체 라인을 출력합니다.
    echo "[Monitor] Executing command: ${cmd_run[*]}"
    
    ERROR_TIMESTAMPS=()

    # ★ /usr/local/bin/ffmpeg 명령 시작
    while read -r line; do
        echo "[FFmpeg] $line"

        if [[ "$line" =~ "Error" || "$line" =~ "error" || "$line" =~ "Warning" || "$line" =~ "warning" || "$line" =~ "Past duration" || "$line" =~ "Non-monotonically" ]]; then
            CURRENT_TIME=$(date +%s)
            ERROR_TIMESTAMPS+=($CURRENT_TIME)

            VALID_TIMESTAMPS=()
            for ts in "${ERROR_TIMESTAMPS[@]}"; do
                if (( CURRENT_TIME - ts <= BURST_WINDOW )); then
                    VALID_TIMESTAMPS+=($ts)
                fi
            done
            ERROR_TIMESTAMPS=("${VALID_TIMESTAMPS[@]}")

            if (( ${#ERROR_TIMESTAMPS[@]} >= BURST_THRESHOLD )); then
                echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                echo "[Monitor] ERROR BURST DETECTED (${#ERROR_TIMESTAMPS[@]} errors in ${BURST_WINDOW}s)!"
                echo "[Monitor] Killing current FFmpeg process to restart..."
                echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"

                # -f 옵션 추가로 확실하게 종료
                pkill -f -P $$ ffmpeg
                break
            fi
        fi
     done < <("${cmd_run[@]}" 2>&1) # 3. 배열 변수를 정상적으로 실행하고 에러 리다이렉션을 붙입니다.

    echo "[Monitor] FFmpeg stopped. Restarting loop in 3 seconds..."
    sleep 3
done
