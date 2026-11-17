# 잠금 OTP 실험실

![Swift](https://img.shields.io/badge/Swift-6-orange?logo=swift&logoColor=white&style=flat-square)
![iOS](https://img.shields.io/badge/iOS-17%2B-black?logo=apple&logoColor=white&style=flat-square)

## 🧪 목적
아이폰 잠금 화면의 원형 한 칸·시간 위 한 줄에서 표준 TOTP를 자동 표시할 수 있는지 검증하는 시험 앱입니다.

> [!WARNING]
> 시험키만 사용합니다. 실제 인증 계정을 등록하지 마세요. 30초 갱신은 실기기에서 아직 검증하지 않았습니다.

## ✅ 현재 상태
TOTP 코어와 검증용 앱을 구현 중입니다. 빌드·갱신·실기기 검증 결과는 별도로 기록합니다.

## 🔧 코어 시험
`swift test -j 4`

리눅스는 Apple Swift Crypto, 애플 플랫폼은 CryptoKit을 사용합니다. 앱은 서버 없이 동작하도록 설계합니다.
