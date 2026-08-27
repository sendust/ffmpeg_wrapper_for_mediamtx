
Gemini

채팅

Spark
베타
새 채팅
채팅 검색
이미지
동영상
라이브러리
새 노트북
MediaMTX FFmpeg 래퍼 README 작성
Linux NIC 본딩 설정 방법
Python을 이용한 4분할 웹화면 구현
MediaMTX onDemand 설정 예제
PID 메모리 사용량 주기적 출력
최경희의 진신우 입금 총액 내역
DeckLink SDK 샘플 컴파일 방법
파이썬 raise 문의 동작 방식
Fail2ban 차단 후 IP 감지 원인
채무변제 사실조회 안내문 대응 방법
인버터 에어컨의 기동 콘덴서 유무
접속 로그 및 WebRTC 상태 모니터링
THAT 2162 IC 핀 호환 대체품 안내
구매 내역서 HTML 코드 구현
우분투 TCP 연결 확인 방법
Ubuntu DeckLink 인식 확인 방법
일본 GeoIP JSON 다운로드 방법
Fail2ban Unban Iptables 오류 원인 및 해결
Fix Fail2ban Iptables Multiport Error
HTML 빈 표 생성 요청
Fail2ban을 이용한 비정상 RTSP 스캔 차단 설정
데이터 JSON 형식 변환 요청
Samba `nobody` 세션 강제 종료 및 차단
MediaMTX FFmpeg 인증 오류 해결
JSON 기반 인증으로 웹 페이지 보안 강화
Systemd 서비스 바이너리 저장 위치
Gemini와의 대화
mediamtx 용 ffmpeg wrapper 이다.

기능, 용도를 설명하는 readme.md 작성해줘.

복사하기, 붙여넣기 가능하도록 만들어줘

2. MediaMTX mediamtx.yml 연동 예시
MediaMTX가 시작될 때 자동으로 스크립트가 백그라운드에서 실행되도록 설정할 수 있습니다.

YAML
paths:
  decklink1:
    runOnInit: /path/to/ffmpeg_wrapper.sh 1
    runOnInitRestart: yes
  decklink2:
    runOnInit: /path/to/ffmpeg_wrapper.sh 2
    runOnInitRestart: yes
  decklink3:
    runOnInit: /path/to/ffmpeg_wrapper.sh 3
    runOnInitRestart: yes
  decklink4:
    runOnInit: /path/to/ffmpeg_wrapper.sh 4
    runOnInitRestart: yes
⚙️ 스크립트 주요 변수 설정 (Configuration)
스크립트 내부 상단에서 아래 변수들을 시스템 환경에 맞게 조정할 수 있습니다.

RTSP_PORT: MediaMTX 서버의 RTSP 포트 (기본값: 8554)

BURST_WINDOW: 에러 감지 기준 시간(초) (기본값: 3)

BURST_THRESHOLD: 위 지정된 시간 내에 허용되는 최대 에러 카운트 (기본값: 10). 이 수치를 초과하면 리스타트 됩니다.

🛠️ FFmpeg 파이프라인 상세
Input: -f decklink -i "DeckLink 8K Pro (X)" (비디오/오디오 동시 캡처)

Video: yadif (디인터레이싱) ➔ h264_nvenc (비트레이트 2000k, GOP 30, B-frame 0, 초저지연 모드)

Audio: libopus (2채널, 비트레이트 128k)

Output: f rtsp rtsp://localhost:8554/decklinkX
"""

with open("README.md", "w", encoding="utf-8") as f:
f.write(content)
print("File generated successfully.")


```text?code_stdout&code_event_index=1
File generated successfully.

Your Markdown file is ready

MD 아이콘
README
 MD 
열기
제공해주신 스크립트의 주요 기능(NVENC 하드웨어 인코딩, 채널 매핑, 에러 감지 및 자동 재시작, 좀비 프로세스 방지 등)을 분석하여 누구나 쉽게 이해하고 바로 복사하여 사용할 수 있도록 README.md 파일을 작성해 두었습니다.

단독 실행 방법뿐만 아니라 MediaMTX 설정 파일(mediamtx.yml)과의 연동 예시도 함께 포함되어 있습니다.




Gemini는 AI이며 인물 등에 관한 정보 제공 시 실수를 할 수 있습니다. 개인 정보 보호 및 Gemini새 창에서 열기

분석 중
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
MediaMTX가 시작될 때 자동으로 스크립트가 백그라운드에서 실행되도록 설정할 수 있습니다.
```yaml
paths:
  decklink1:
    runOnInit: /path/to/ffmpeg_wrapper.sh 1
    runOnInitRestart: yes
  decklink2:
    runOnInit: /path/to/ffmpeg_wrapper.sh 2
    runOnInitRestart: yes
  decklink3:
    runOnInit: /path/to/ffmpeg_wrapper.sh 3
    runOnInitRestart: yes
  decklink4:
    runOnInit: /path/to/ffmpeg_wrapper.sh 4
    runOnInitRestart: yes
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
README.md
README.md 항목을 표시하는 중입니다.
