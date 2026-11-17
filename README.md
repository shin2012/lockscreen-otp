# 잠금 OTP

![Swift](https://img.shields.io/badge/Swift-6-orange?logo=swift&logoColor=white&style=flat-square)
![iOS](https://img.shields.io/badge/iOS-17%2B-black?logo=apple&logoColor=white&style=flat-square)

## 🧪 목적
아이폰 잠금 화면의 원형 한 칸·시간 위 한 줄에서 표준 TOTP를 자동 표시할 수 있는지 검증하는 앱입니다. 실제 키는 사용자가 기기에서 직접 입력합니다.

> [!WARNING]
> 30초 자동 갱신은 실기기에서 아직 검증하지 않았습니다. 먼저 공개 시험키로 확인하고 기존 인증 수단을 유지하세요. 실제 계정 키는 소스·CI·서버에 넣지 않습니다.

## 📱 포함한 기능
- 표준 TOTP 계정 추가·삭제·선택, Base32 비밀키 직접 입력 및 otpauth 등록 주소 가져오기
- SHA-1·SHA-256·SHA-512, 6자리·8자리, 직접 입력 30초·60초, 등록 주소 1~3600초
- 원형 한 칸·시간 위 한 줄 WidgetKit 위젯
- 시험키, 사전 계산 범위 설정, 잠금 상태 노출 동의, 자동 갱신 검증 화면
- 기기 내부 공유 Keychain 저장. 기본 보호는 잠금 해제 중만 접근, 위젯 허용 시 첫 잠금 해제 이후 접근으로 명시 변경

## ✅ 검증 구분
- 코어: RFC 6238 벡터·Base32·등록 주소 검증·타임라인 시험
- 시뮬레이터: 앱·위젯 빌드 및 UI 시험을 CI에서 실행
- 실기기: 자동 갱신·상시 표시·잠금 상태 노출·서명된 Keychain 공유는 별도 검증 필요
- 앱 내부 위젯 모양은 공유 View의 미리보기이지 실제 잠금 화면 갱신의 증거가 아닙니다.

## 🔧 개발과 시험
`swift test -j 4`

`xcodegen generate --spec ios/project.yml`

`xcodebuild build -project ios/LockscreenOTP.xcodeproj -scheme LockscreenOTP -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO`

리눅스 코어 시험은 Apple Swift Crypto, 애플 플랫폼은 시스템 CryptoKit을 사용합니다. iOS 앱은 외부 패키지·서버·네트워크 없이 동작합니다. 시뮬레이터는 서명된 공유 키체인 권한이 없으므로 기기별 기본 키체인을 사용하며 앱·위젯 공유 검증으로 간주하지 않습니다.

## 🚀 TestFlight
저장소 Secrets에 `APPLE_TEAM_ID`, `ASC_ISSUER_ID`, `ASC_KEY_ID`, `ASC_KEY_P8`가 필요합니다. 비밀값은 저장소 설정에서만 입력하며 채팅·소스·로그에 남기지 않습니다.

앱 번들 ID: `kr.b-612.lockscreenotp`, 위젯 번들 ID: `kr.b-612.lockscreenotp.widget`.
서명 준비가 번들 ID를 등록한 후 App Store Connect에서 해당 번들 ID의 앱 레코드를 만들어야 합니다. 워크플로 수동 실행에서 TestFlight 업로드를 켭니다.

## 🔐 보안·제약
자세한 내용은 [개인정보 안내](docs/PRIVACY.md), [실기기 시험표](docs/verification/lockscreen-matrix.md)를 확인하세요. 내보내기·백업·복구·QR 카메라 스캔은 이번 버전에 포함하지 않습니다. 아이콘은 임시 자체 제작 이미지입니다.
