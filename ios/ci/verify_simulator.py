import json
import os
import pathlib
import subprocess
import sys

out = pathlib.Path(os.environ.get("RUNNER_TEMP", ".")) / "verification"
out.mkdir(parents=True, exist_ok=True)

def run(args, **kwargs):
    return subprocess.run(args, check=True, timeout=kwargs.pop("timeout", 180), **kwargs)

def read_json(args):
    return json.loads(subprocess.check_output(args, text=True, timeout=60))

runtimes = [r for r in read_json(["xcrun", "simctl", "list", "runtimes", "-j"])["runtimes"]
            if r.get("isAvailable") and r["identifier"].startswith("com.apple.CoreSimulator.SimRuntime.iOS-")]
if not runtimes:
    raise SystemExit("사용 가능한 iOS 런타임이 없습니다.")
runtime = max(runtimes, key=lambda r: tuple(map(int, r["version"].split("."))))
devices = read_json(["xcrun", "simctl", "list", "devices", "available", "-j"])["devices"].get(runtime["identifier"], [])
phones = [d for d in devices if "iPhone" in d["name"]]
if not phones:
    raise SystemExit("선택한 런타임에 iPhone 시뮬레이터가 없습니다.")
device = next((d for d in phones if d["name"] == "iPhone 16 Pro"), phones[0])
udid = device["udid"]
(out / "environment.json").write_text(json.dumps({"runtime": runtime, "device": device}, indent=2))
if device["state"] != "Booted":
    run(["xcrun", "simctl", "boot", udid])
run(["open", "-a", "Simulator", "--args", "-CurrentDeviceUDID", udid])
run(["xcrun", "simctl", "bootstatus", udid, "-b"], timeout=300)
args = ["xcodebuild", "test", "-project", "ios/LockscreenOTP.xcodeproj", "-scheme", "LockscreenOTP",
        "-destination", f"platform=iOS Simulator,id={udid}", "-derivedDataPath", str(out / "derived"),
        "-resultBundlePath", str(out / "ui-tests.xcresult"), "-parallel-testing-enabled", "NO",
        "CODE_SIGNING_ALLOWED=YES", "CODE_SIGN_IDENTITY=-", "CODE_SIGN_STYLE=Manual", "-IDEBuildingContinueBuildingAfterErrors=YES"]
with (out / "ui-tests.log").open("w") as log:
    test = subprocess.run(args, stdout=log, stderr=subprocess.STDOUT, timeout=1200)
subprocess.run(["xcrun", "xcresulttool", "export", "attachments", "--path", str(out / "ui-tests.xcresult"), "--output-path", str(out / "attachments")], timeout=120)
with (out / "vault-events.log").open("w") as log:
    subprocess.run(["xcrun", "simctl", "spawn", udid, "log", "show", "--last", "10m", "--style", "compact", "--predicate", 'subsystem == "kr.b-612.lockscreenotp"'], stdout=log, stderr=subprocess.STDOUT, timeout=120)
text = (out / "ui-tests.log").read_text()
for line in text.splitlines():
    if any(word in line for word in ["error:", "Test Case", "TEST SUCCEEDED", "TEST FAILED"]):
        print(line)
if test.returncode:
    print(text[-10000:])
    raise SystemExit(test.returncode)
app = out / "derived/Build/Products/Debug-iphonesimulator/LockscreenOTP.app"
run(["xcrun", "simctl", "install", udid, str(app)])
run(["xcrun", "simctl", "launch", "--terminate-running-process", udid, "kr.b-612.lockscreenotp"])
# UI tests above already wait for app views and keep XCTest screenshot attachments.
run(["xcrun", "simctl", "io", udid, "screenshot", str(out / "app-launch.png")])
(out / "result.json").write_text(json.dumps({"ui_tests": "passed", "widget_build": "passed", "physical_widget_refresh": "not_tested"}, indent=2))
print("시뮬레이터 UI 시험 통과. 실기기 위젯 자동 갱신은 미검증.")
