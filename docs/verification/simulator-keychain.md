# 시뮬레이터 Keychain 실패 재현

- 재현 실행: GitHub Actions `44041538586`, 소스 `a1e7271a9417c927499f6144c5e493e778f380f0`.
- 앱·위젯 컴파일과 코어 11개 시험은 통과했습니다. UI 시험에서 첫 Keychain 조회가 실패하여 계정 추가 버튼이 비활성 상태였습니다.
- xcresult 데이터에서 실제 오류 문구 `키체인 접근 실패 (-34018)`을 회수했습니다. 화면이 안 열린다는 현상만으로 코드를 추정하지 않았습니다.
- 기존 CI는 `CODE_SIGNING_ALLOWED=NO`였고 명시적 access group을 생략해도 Keychain entitlement가 없는 실행 파일의 접근이 거부됐습니다.
- 수정 후보: 시뮬레이터 빌드·시험에 무료 임시 서명(`CODE_SIGN_IDENTITY=-`, `CODE_SIGN_STYLE=Manual`)을 적용하여 선언된 Keychain 공유 권한을 포함합니다. 앱·위젯은 같은 access group을 사용하며 평문 저장이나 fake Keychain으로 대체하지 않습니다.
- 회귀 시험은 실제 UI로 시험키 계정 저장 → 프로세스 재시작 → 복원 → 삭제까지 확장했습니다. 새 실행에서 이 경로가 통과하기 전에는 해결됐다고 기록하지 않습니다.
