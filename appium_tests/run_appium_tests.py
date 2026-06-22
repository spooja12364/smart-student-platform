"""
run_appium_tests.py — Master runner script
Runs all Appium tests then generates the Excel + JSON + Summary reports.
Usage:
    python run_appium_tests.py                    # full suite
    python run_appium_tests.py --suite auth       # auth only
    python run_appium_tests.py --report-only      # generate reports without running tests
"""
import os
import sys
import json
import time
import argparse
import subprocess
from datetime import datetime
from pathlib import Path

# ── Args ─────────────────────────────────────────────────────────
parser = argparse.ArgumentParser(description="Smart Student Platform — Appium Test Runner")
parser.add_argument("--suite",       default="all",  help="Suite: all | auth | navigation | registration | features")
parser.add_argument("--report-only", action="store_true", help="Skip tests, only generate reports")
parser.add_argument("--device",      default="emulator-5554", help="ADB device name")
parser.add_argument("--android",     default="14.0",  help="Android version")
parser.add_argument("--no-excel",    action="store_true", help="Skip Excel generation")
args = parser.parse_args()

BASE_DIR = Path(__file__).parent
RESULTS_DIR = BASE_DIR / "Test Results"
JSON_DIR    = RESULTS_DIR / "JSON"
EXCEL_DIR   = RESULTS_DIR / "Excel"
SUMMARY_DIR = RESULTS_DIR / "Summary"
SCREENSHOTS_DIR = RESULTS_DIR / "Screenshots"
LOGS_DIR    = RESULTS_DIR / "Logs"

for d in [JSON_DIR, EXCEL_DIR, SUMMARY_DIR, SCREENSHOTS_DIR, LOGS_DIR]:
    d.mkdir(parents=True, exist_ok=True)

# ── Suite mapping ─────────────────────────────────────────────────
SUITE_FILES = {
    "all":          ["tests/"],
    "auth":         ["tests/test_01_authentication.py"],
    "navigation":   ["tests/test_02_navigation.py"],
    "registration": ["tests/test_03_registration.py"],
    "features":     ["tests/test_04_profile_search_chat.py"],
}


def print_banner():
    print("\n" + "="*65)
    print("  🤖 SMART STUDENT PLATFORM — APPIUM E2E TEST RUNNER")
    print(f"     Suite   : {args.suite}")
    print(f"     Device  : {args.device}")
    print(f"     Android : {args.android}")
    print(f"     Date    : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*65 + "\n")


def run_tests() -> int:
    """Execute pytest and capture results."""
    suite_paths = SUITE_FILES.get(args.suite, SUITE_FILES["all"])

    # JSON report for internal use
    json_report_path = JSON_DIR / "pytest_report.json"
    html_report_path = RESULTS_DIR / "HTML" / "test_report.html"
    html_report_path.parent.mkdir(parents=True, exist_ok=True)

    cmd = [
        sys.executable, "-m", "pytest",
        *suite_paths,
        "-v",
        "--tb=short",
        f"--html={html_report_path}",
        "--self-contained-html",
        f"--json-report",
        f"--json-report-file={json_report_path}",
        "--capture=no",
        "--color=yes",
    ]

    print("🧪 Executing Appium tests...")
    print(f"   Command: {' '.join(str(c) for c in cmd)}\n")
    print("-"*65)

    start = time.time()

    # Try with json-report plugin, fallback without
    try:
        result = subprocess.run(
            cmd,
            cwd=str(BASE_DIR),
            env={**os.environ, "DEVICE_NAME": args.device, "ANDROID_VERSION": args.android},
        )
    except Exception:
        cmd_fallback = [
            sys.executable, "-m", "pytest",
            *suite_paths,
            "-v",
            "--tb=short",
            f"--html={html_report_path}",
            "--self-contained-html",
        ]
        result = subprocess.run(
            cmd_fallback,
            cwd=str(BASE_DIR),
            env={**os.environ, "DEVICE_NAME": args.device, "ANDROID_VERSION": args.android},
        )

    elapsed = time.time() - start
    print(f"\n{'='*65}")
    print(f"   ⏱️  Tests completed in {elapsed:.1f} seconds")
    print(f"   Exit code: {result.returncode}")
    return result.returncode


def parse_pytest_json() -> list[dict]:
    """Parse pytest JSON report into our format."""
    json_path = JSON_DIR / "pytest_report.json"
    if not json_path.exists():
        return []
    try:
        with open(json_path) as f:
            data = json.load(f)
        results = []
        for test in data.get("tests", []):
            nodeid = test.get("nodeid", "")
            # Extract module from file name
            parts = nodeid.split("::")
            module = "Unknown"
            if parts:
                fname = Path(parts[0]).stem
                for m in ["authentication", "navigation", "registration", "profile", "search", "chat", "notifications", "connections", "skills"]:
                    if m in fname.lower():
                        module = m.title()
                        break

            # Extract TC id from test name
            name = parts[-1] if len(parts) > 1 else nodeid
            tc_id = name.split("_")[0] if name.startswith("test_TC") else "TC"
            if "TC_" in name:
                tc_id = name.split("_TC_")[1].split("_")[0] if "_TC_" in name else tc_id

            outcome_raw = test.get("outcome", "failed")
            outcome = "PASS" if outcome_raw == "passed" else ("SKIP" if outcome_raw == "skipped" else "FAIL")

            error = ""
            if outcome == "FAIL" and test.get("call"):
                error = test["call"].get("longrepr", "")[:300]

            results.append({
                "id": nodeid,
                "tc_id": tc_id,
                "name": name,
                "module": module,
                "outcome": outcome,
                "duration": round(test.get("call", {}).get("duration", 0) or 0, 2),
                "error": error,
            })
        return results
    except Exception as e:
        print(f"⚠️  Could not parse pytest JSON: {e}")
        return []


def save_results_json(results: list[dict]):
    """Save unified results JSON for report generators."""
    out = JSON_DIR / "test_results.json"
    with open(out, "w") as f:
        json.dump(results, f, indent=2)
    print(f"   ✅ Results JSON saved: {out}")


def generate_summary(results: list[dict], exit_code: int):
    """Write a Markdown summary."""
    total   = len(results)
    passed  = sum(1 for r in results if r["outcome"] == "PASS")
    failed  = sum(1 for r in results if r["outcome"] == "FAIL")
    skipped = sum(1 for r in results if r["outcome"] == "SKIP")
    pct     = (passed / total * 100) if total else 0
    dur     = sum(r.get("duration", 0) for r in results)

    status_icon = "✅ PASSED" if failed == 0 else f"❌ FAILED ({failed} failures)"

    md = f"""# 🤖 Smart Student Platform — Appium E2E Test Report

## 📊 Execution Summary

| Metric | Value |
|--------|-------|
| **Overall Status** | {status_icon} |
| **Total Tests** | {total} |
| ✅ Passed | {passed} |
| ❌ Failed | {failed} |
| ⏭ Skipped | {skipped} |
| **Pass Rate** | {pct:.1f}% |
| **Total Duration** | {dur:.1f}s |
| **Device** | {args.device} |
| **Android** | {args.android} |
| **Date** | {datetime.now().strftime("%Y-%m-%d %H:%M:%S")} |

## 📦 Module Breakdown

"""
    from collections import defaultdict
    module_data = defaultdict(lambda: {"pass": 0, "fail": 0, "skip": 0})
    for r in results:
        m = r.get("module", "Unknown")
        if r["outcome"] == "PASS":   module_data[m]["pass"] += 1
        elif r["outcome"] == "FAIL": module_data[m]["fail"] += 1
        else:                        module_data[m]["skip"] += 1

    md += "| Module | ✅ Pass | ❌ Fail | ⏭ Skip | Status |\n"
    md += "|--------|--------|--------|--------|--------|\n"
    for mod, d in sorted(module_data.items()):
        s = "✅" if d["fail"] == 0 else "❌"
        md += f"| {mod} | {d['pass']} | {d['fail']} | {d['skip']} | {s} |\n"

    if failed > 0:
        md += "\n## ❌ Failed Tests\n\n"
        for r in results:
            if r["outcome"] == "FAIL":
                md += f"- **{r.get('tc_id', '?')}** `{r.get('name', '')}` — {r.get('error', 'Assertion failed')[:100]}\n"

    md += f"\n---\n*Generated by Smart Student Platform Appium Framework*\n"

    out = SUMMARY_DIR / "summary.md"
    with open(out, "w", encoding="utf-8") as f:
        f.write(md)
    print(f"   ✅ Summary saved: {out}")


def main():
    print_banner()

    exit_code = 0

    if not args.report_only:
        exit_code = run_tests()

    print("\n📊 Generating Reports...")
    print("-"*65)

    # Parse results
    results = parse_pytest_json()
    if not results:
        print("   ⚠️  No pytest results found — using demo data for report")

    save_results_json(results)
    generate_summary(results, exit_code)

    if not args.no_excel:
        print("   → Generating Excel report...")
        try:
            # Run the Excel generator
            subprocess.run(
                [sys.executable, "generate_excel_report.py"],
                cwd=str(BASE_DIR),
            )
        except Exception as e:
            print(f"   ⚠️  Excel generation error: {e}")

    print("\n" + "="*65)
    print("📁 REPORTS LOCATION:")
    print(f"   Excel   : {EXCEL_DIR / 'Appium_E2E_Test_Report_SmartStudent.xlsx'}")
    print(f"   HTML    : {RESULTS_DIR / 'HTML' / 'test_report.html'}")
    print(f"   JSON    : {JSON_DIR / 'test_results.json'}")
    print(f"   Summary : {SUMMARY_DIR / 'summary.md'}")
    print("="*65 + "\n")

    return exit_code


if __name__ == "__main__":
    sys.exit(main())
