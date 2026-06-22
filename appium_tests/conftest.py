"""
conftest.py — Pytest fixtures shared across all Appium tests
"""
import os
import time
import pytest
from appium import webdriver
from appium.options import UiAutomator2Options
from config import (
    APP_PACKAGE, APP_ACTIVITY, APK_PATH,
    APPIUM_HOST, APPIUM_PORT,
    DEVICE_NAME, PLATFORM_VERSION,
    IMPLICIT_WAIT, SCREENSHOTS_DIR
)

# ── Global results collector ──────────────────────────────────────
_results = []


def get_results():
    return _results


def add_result(result: dict):
    _results.append(result)


# ── Driver fixture ────────────────────────────────────────────────
@pytest.fixture(scope="function")
def driver():
    """Initialise Appium driver before each test, quit after."""
    options = UiAutomator2Options()
    options.platform_name = "Android"
    options.device_name = DEVICE_NAME
    options.platform_version = PLATFORM_VERSION
    options.app_package = APP_PACKAGE
    options.app_activity = APP_ACTIVITY
    options.no_reset = True
    options.auto_grant_permissions = True
    options.new_command_timeout = 120
    options.android_install_timeout = 120
    options.adb_exec_timeout = 120

    # Only set apk path if file exists
    apk = os.path.abspath(os.path.join(os.path.dirname(__file__), APK_PATH))
    if os.path.isfile(apk):
        options.app = apk

    url = f"http://{APPIUM_HOST}:{APPIUM_PORT}"
    drv = None
    try:
        drv = webdriver.Remote(url, options=options)
        drv.implicitly_wait(IMPLICIT_WAIT)
        yield drv
    finally:
        if drv:
            try:
                drv.quit()
            except Exception:
                pass


# ── Screenshot helper ─────────────────────────────────────────────
def take_screenshot(driver, name: str) -> str:
    """Capture screenshot and return file path."""
    os.makedirs(SCREENSHOTS_DIR, exist_ok=True)
    ts = time.strftime("%Y%m%d_%H%M%S")
    fname = f"{SCREENSHOTS_DIR}/{name}_{ts}.png"
    try:
        driver.save_screenshot(fname)
    except Exception:
        pass
    return fname


# ── pytest hooks ─────────────────────────────────────────────────
def pytest_runtest_makereport(item, call):
    """Hook: capture test results for our report generator."""
    if call.when == "call":
        outcome = "PASS" if call.excinfo is None else "FAIL"
        error_msg = ""
        if call.excinfo:
            error_msg = str(call.excinfo.value)[:300]

        add_result({
            "id": item.nodeid,
            "name": item.name,
            "module": item.parent.name if item.parent else "Unknown",
            "outcome": outcome,
            "duration": round(call.duration, 2),
            "error": error_msg,
        })
