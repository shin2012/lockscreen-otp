# 잠금 OTP

![Swift](https://img.shields.io/badge/Swift-6-orange?logo=swift&logoColor=white&style=flat-square)
![iOS](https://img.shields.io/badge/iOS-17%2B-black?logo=apple&logoColor=white&style=flat-square)

## 🧪 목적
아이폰 잠금 화면의 원형 한 칸·시간 위 한 줄에서 표준 TOTP를 자동 표시할 수 있는지 검증하는 앱입니다. 실제 키는 사용자가 기기에서 직접 입력합니다.

> [!WARNING]
> 실기기 확인: 잠금 화면이 켜져 있을 때는 30초마다 번호가 바뀝니다. 상시 표시 화면(AOD)에서는 iOS가 위젯을 다시 그리지 않아 번호가 멈추므로, 위젯 설정 기본값은 AOD에서 번호를 가리는 것입니다. 실제 계정 키는 소스·CI·서버에 넣지 않습니다.

## 📱 포함한 기능
- 표준 TOTP 계정 추가·삭제·선택, Base32 비밀키 직접 입력 및 otpauth 등록 주소 가져오기
- SHA-1·SHA-256·SHA-512, 6자리·8자리, 직접 입력 30초·60초, 등록 주소 1~3600초
- 원형 한 칸·시간 위 한 줄 WidgetKit 위젯
- 위젯별 설정(위젯 편집에서 탭): 표시할 계정 선택(비우면 앱 선택 계정), 이름 표시 켜기/끄기. 계정 목록은 앱에서 위젯 키 접근을 허용한 뒤에만 보입니다.
- 계정 이름 편집·기본 계정 지정·순서 변경, 한 줄 형태의 간결한 목록과 남은 시간 링
- 위젯별 설정: 계정, 이름 표시, 남은 시간 링(얇게·굵게·끄기, 한 줄 위젯은 초 카운트다운), AOD에서 번호 가리기
- 사전 계산 범위 설정, 잠금 상태 노출 동의
- 기기 내부 공유 Keychain 저장. 기본 보호는 잠금 해제 중만 접근, 위젯 허용 시 첫 잠금 해제 이후 접근으로 명시 변경

## ✅ 검증 구분
- 코어: RFC 6238 벡터·Base32·등록 주소 검증·타임라인 시험
- 시뮬레이터: 앱·위젯 빌드 및 UI 시험을 CI에서 실행
- 실기기: 자동 갱신·상시 표시·잠금 상태 노출·서명된 Keychain 공유는 별도 검증 필요
- 앱 내부 위젯 모양은 공유 View의 미리보기이지 실제 잠금 화면 갱신의 증거가 아닙니다.

## 🔧 개발과 시험
`swift test -j 4`

`xcodegen generate --spec ios/project.yml`

`xcodebuild build -project ios/LockscreenOTP.xcodeproj -scheme LockscreenOTP -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual`

리눅스 코어 시험은 Apple Swift Crypto, 애플 플랫폼은 시스템 CryptoKit을 사용합니다. iOS 앱은 외부 패키지·서버·네트워크 없이 동작합니다. 시뮬레이터는 무료 임시 서명으로 공유 Keychain 엔타이틀먼트를 넣어 시험합니다. 기기 서명·실제 잠금 상태의 보호 정책은 별도 검증 대상입니다.

## 🚀 TestFlight
저장소 Secrets에 `APPLE_TEAM_ID`, `ASC_ISSUER_ID`, `ASC_KEY_ID`, `ASC_KEY_P8`가 필요합니다. 비밀값은 저장소 설정에서만 입력하며 채팅·소스·로그에 남기지 않습니다.

앱 번들 ID: `kr.b-612.lockscreenotp`, 위젯 번들 ID: `kr.b-612.lockscreenotp.widget`.
서명 준비가 번들 ID를 등록한 후 App Store Connect에서 해당 번들 ID의 앱 레코드를 만들어야 합니다. 워크플로 수동 실행에서 TestFlight 업로드를 켭니다.

## 🔐 보안·제약
자세한 내용은 [개인정보 안내](docs/PRIVACY.md), [실기기 시험표](docs/verification/lockscreen-matrix.md)를 확인하세요. 내보내기·백업·복구·QR 카메라 스캔은 이번 버전에 포함하지 않습니다. 아이콘은 임시 자체 제작 이미지입니다.
