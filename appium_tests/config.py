# ================================================================
# Smart Student Platform — Appium Test Configuration
# ================================================================

# Android App
APP_PACKAGE = "com.example.smart_student_platform"
APP_ACTIVITY = "com.example.smart_student_platform.MainActivity"
APK_PATH = "../build/app/outputs/flutter-apk/app-debug.apk"

# Appium Server
APPIUM_HOST = "127.0.0.1"
APPIUM_PORT = 4723

# Device
DEVICE_NAME = "emulator-5554"
PLATFORM_VERSION = "14.0"

# Test Credentials
VALID_EMAIL = "testuser@smartstudent.com"
VALID_PASSWORD = "Test@12345"

# Timeouts (seconds)
IMPLICIT_WAIT = 10
EXPLICIT_WAIT = 30
ELEMENT_WAIT = 20

# Reports
REPORTS_DIR = "Test Results"
SCREENSHOTS_DIR = "Test Results/Screenshots"
EXCEL_REPORT_DIR = "Test Results/Excel"
SUMMARY_DIR = "Test Results/Summary"
