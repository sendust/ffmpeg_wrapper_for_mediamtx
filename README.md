# MediaMTX FFmpeg Wrapper for DeckLink 8K Pro

이 스크립트는 MediaMTX 환경에서 Blackmagic DeckLink 8K Pro 캡처 카드의 입력을 받아 RTSP 스트림으로 송출하는 FFmpeg 래퍼(Wrapper) 쉘 스크립트입니다. 하드웨어 가속(NVIDIA NVENC)을 사용하여 초저지연(Ultra-Low Latency) 스트리밍을 제공하며, 에러를 실시간으로 모니터링하여 자동 재시작하는 기능을 통해 높은 안정성을 보장합니다.

## 📌 주요 기능 (Key Features)

1. **다중 채널 인자 매핑 (Dynamic Channel Mapping)**: 
   * 스크립트 실행 시 `1`~`4`의 숫자를 인자로 받아, 해당하는 DeckLink 디바이스(`DeckLink 8K Pro (1~4)`)와 MediaMTX의 RTSP 경로(`decklink1~4`)를 자동으로 매핑합니다.
2. **하드웨어 가속 인코딩 (NVENC Hardware Acceleration)**: 
   * `h264_nvenc` 비디오 코덱과 `ull` (Ultra-low latency) 튜닝, `p1` 프리셋을 사용하여 CPU 부하를 최소화하고 지연 시간을 극도로 줄였습니다.
3. **디인터레이싱 및 포맷 변환 (Deinterlacing)**: 
   * `-vf "yadif=1,format=nv12"` 필터를 적용하여 입력된 인터레이스 신호를 프로그레시브 신호로 부드럽게 변환하고, NVENC 인코더에 최적화된 픽셀 포맷(`nv12`)으로 설정합니다.
4. **에러 버스트 감지 및 자동 복구 (Error Burst Detection & Auto-Restart)**: 
   * FFmpeg의 로그를 실시간으로 분석합니다. 지정된 짧은 시간(`BURST_WINDOW=3`초) 내에 에러나 경고(예: `Past duration`, `Non-monotonically` 등)가 일정 횟수(`BURST_THRESHOLD=10`회) 이상 발생하면, 스트림에 심각한 문제가 생겼다고 판단하여 FFmpeg 프로세스를 강제 종료하고 자동으로 재시작합니다.
5. **좀비 프로세스 방지 (Graceful Shutdown)**: 
   * `trap` 커맨드를 사용하여 MediaMTX나 사용자가 스크립트를 종료할 때(`SIGINT`, `SIGTERM`), 자식 프로세스인 FFmpeg까지 확실하게 함께 종료하여 시스템 자원 누수를 막아줍니다.

---

## 🚀 사용 방법 (Usage)

이 스크립트는 터미널에서 단독으로 실행하거나 MediaMTX 설정 파일(`mediamtx.yml`)에 등록하여 사용할 수 있습니다.

### 1. 단독 실행
```bash
# 스크립트에 실행 권한 부여
chmod +x ffmpeg_wrapper.sh

# 채널 번호(1~4)를 인자로 주어 실행 (예: 1번 채널)
./ffmpeg_wrapper.sh 1
```

### 2. MediaMTX `mediamtx.yml` 연동 예시
MediaMTX가 시작후 vod 요청이 발생하면 자동으로 스크립트가 백그라운드에서 실행되도록 설정할 수 있습니다.
```yaml
paths:
  decklink1:
    runOnDemand: /home/sendust/mediamtx/run_decklink.sh 1
    runOnDemandStartTimeout: 1s
    runOnDemandCloseAfter: 1s

  decklink2:
    runOnDemand: /home/sendust/mediamtx/run_decklink.sh 2
    runOnDemandStartTimeout: 1s
    runOnDemandCloseAfter: 1s

  decklink3:
    runOnDemand: /home/sendust/mediamtx/run_decklink.sh 3
    runOnDemandStartTimeout: 1s
    runOnDemandCloseAfter: 1s

  decklink4:
    runOnDemand: /home/sendust/mediamtx/run_decklink.sh 4
    runOnDemandStartTimeout: 1s
    runOnDemandCloseAfter: 1s

```

---

## ⚙️ 스크립트 주요 변수 설정 (Configuration)

스크립트 내부 상단에서 아래 변수들을 시스템 환경에 맞게 조정할 수 있습니다.

* **`RTSP_PORT`**: MediaMTX 서버의 RTSP 포트 (기본값: `8554`)
* **`BURST_WINDOW`**: 에러 감지 기준 시간(초) (기본값: `3`)
* **`BURST_THRESHOLD`**: 위 지정된 시간 내에 허용되는 최대 에러 카운트 (기본값: `10`). 이 수치를 초과하면 리스타트 됩니다.

---

## 🛠️ FFmpeg 파이프라인 상세

* **Input**: `-f decklink -i "DeckLink 8K Pro (X)"` (비디오/오디오 동시 캡처)
* **Video**: `yadif` (디인터레이싱) ➔ `h264_nvenc` (비트레이트 2000k, GOP 30, B-frame 0, 초저지연 모드)
* **Audio**: `libopus` (2채널, 비트레이트 128k)
* **Output**: `f rtsp rtsp://localhost:8554/decklinkX`
