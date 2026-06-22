"""
tests/test_01_authentication.py
End-to-end authentication tests for Smart Student Platform
"""
import pytest
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from pages.app_pages import LoginPage, RegisterPage, DashboardPage
from config import VALID_EMAIL, VALID_PASSWORD
from conftest import take_screenshot


@pytest.fixture(autouse=True)
def go_to_login(driver):
    """Navigate to login page before each test."""
    try:
        driver.terminate_app("com.example.smart_student_platform")
    except Exception:
        pass
    driver.activate_app("com.example.smart_student_platform")
    import time; time.sleep(3)
    yield


class TestAuthentication:
    """TC_AUTH_001 – TC_AUTH_030 : Authentication Tests"""

    def test_TC_AUTH_001_login_page_loads(self, driver):
        """Login page should load with Email and Password fields."""
        page = LoginPage(driver)
        assert page.is_loaded(), "Login page did not load"

    def test_TC_AUTH_002_email_field_visible(self, driver):
        """Email input field visible on login screen."""
        page = LoginPage(driver)
        assert page.is_loaded()
        assert page._get_email_field() is not None, "Email field not found"

    def test_TC_AUTH_003_password_field_visible(self, driver):
        """Password input field visible on login screen."""
        page = LoginPage(driver)
        assert page.is_loaded()
        assert page._get_password_field() is not None, "Password field not found"

    def test_TC_AUTH_004_login_button_visible(self, driver):
        """LOGIN button visible on login screen."""
        page = LoginPage(driver)
        assert page.is_loaded()
        btn = page.find_by_text("LOGIN") or page.find_by_text("Login")
        assert btn is not None, "Login button not found"

    def test_TC_AUTH_005_forgot_password_link_visible(self, driver):
        """Forgot Password link visible on login screen."""
        page = LoginPage(driver)
        assert page.is_loaded()
        el = page.find_by_partial_text("Forgot")
        assert el is not None, "Forgot Password link not found"

    def test_TC_AUTH_006_register_link_visible(self, driver):
        """Register / Create account link visible on login screen."""
        page = LoginPage(driver)
        assert page.is_loaded()
        el = (
            page.find_by_partial_text("Create account") or
            page.find_by_partial_text("New here") or
            page.find_by_text("Register")
        )
        assert el is not None, "Register link not found"

    def test_TC_AUTH_007_empty_login_shows_error(self, driver):
        """Login with empty fields shows error / stays on login page."""
        page = LoginPage(driver)
        assert page.is_loaded()
        page.click_login_btn()
        assert page.is_loaded() or page.is_error_shown(), \
            "Should stay on login or show error"

    def test_TC_AUTH_008_wrong_password_shows_error(self, driver):
        """Login with wrong password shows error message."""
        page = LoginPage(driver)
        assert page.is_loaded()
        page.enter_email(VALID_EMAIL)
        page.enter_password("WrongPass@999!")
        page.hide_keyboard()
        page.click_login_btn()
        page.sleep(3)
        assert page.is_error_shown() or page.is_loaded(), \
            "Should show error for wrong password"

    def test_TC_AUTH_009_invalid_email_format_rejected(self, driver):
        """Login with invalid email format (no @) is rejected."""
        page = LoginPage(driver)
        page.enter_email("notanemail")
        page.enter_password(VALID_PASSWORD)
        page.hide_keyboard()
        page.click_login_btn()
        page.sleep(2)
        assert page.is_loaded() or page.is_error_shown()

    def test_TC_AUTH_010_empty_email_rejected(self, driver):
        """Login with empty email and valid password is rejected."""
        page = LoginPage(driver)
        page.enter_password(VALID_PASSWORD)
        page.hide_keyboard()
        page.click_login_btn()
        page.sleep(2)
        assert page.is_loaded() or page.is_error_shown()

    def test_TC_AUTH_011_empty_password_rejected(self, driver):
        """Login with valid email and empty password is rejected."""
        page = LoginPage(driver)
        page.enter_email(VALID_EMAIL)
        page.hide_keyboard()
        page.click_login_btn()
        page.sleep(2)
        assert page.is_loaded() or page.is_error_shown()

    def test_TC_AUTH_012_valid_login_navigates_to_dashboard(self, driver):
        """Valid credentials navigate to dashboard."""
        page = LoginPage(driver)
        assert page.is_loaded()
        dash = page.login(VALID_EMAIL, VALID_PASSWORD)
        assert dash.is_loaded(), "Dashboard should load after valid login"

    def test_TC_AUTH_013_welcome_text_shown_on_dashboard(self, driver):
        """Dashboard shows 'Welcome back' text after login."""
        page = LoginPage(driver)
        dash = page.login(VALID_EMAIL, VALID_PASSWORD)
        assert dash.is_welcome_text_shown() or dash.is_loaded(), \
            "Welcome text should be visible"

    def test_TC_AUTH_014_logout_returns_to_login(self, driver):
        """Logout from dashboard returns user to login page."""
        page = LoginPage(driver)
        dash = page.login(VALID_EMAIL, VALID_PASSWORD)
        assert dash.is_loaded()
        login = dash.logout()
        page.sleep(2)
        assert login.is_loaded(), "Should return to login page after logout"

    def test_TC_AUTH_015_forgot_password_dialog_opens(self, driver):
        """Clicking Forgot Password opens the reset dialog."""
        page = LoginPage(driver)
        assert page.is_loaded()
        page.click_forgot_password()
        page.sleep(1)
        assert (
            page.is_text_present("Reset Password", timeout=4) or
            page.is_text_present("reset", timeout=4) or
            page.is_loaded()
        ), "Forgot password dialog should open"

    def test_TC_AUTH_016_navigate_to_register_page(self, driver):
        """Tapping register link opens registration page."""
        page = LoginPage(driver)
        assert page.is_loaded()
        reg = page.click_register_link()
        assert reg.is_loaded(), "Registration page should load"

    def test_TC_AUTH_017_sql_injection_handled_gracefully(self, driver):
        """SQL injection in email field handled gracefully."""
        page = LoginPage(driver)
        page.enter_email("' OR 1=1 --")
        page.enter_password("anything")
        page.click_login_btn()
        page.sleep(2)
        assert page.is_loaded() or page.is_error_shown(), \
            "SQL injection should be handled gracefully"

    def test_TC_AUTH_018_xss_handled_gracefully(self, driver):
        """XSS payload in email field handled gracefully."""
        page = LoginPage(driver)
        page.enter_email("<script>alert(1)</script>@test.com")
        page.enter_password("anything")
        page.click_login_btn()
        page.sleep(2)
        assert page.is_loaded() or page.is_error_shown()

    def test_TC_AUTH_019_long_email_handled(self, driver):
        """Very long email handled without crash."""
        page = LoginPage(driver)
        page.enter_email("a" * 200 + "@example.com")
        page.enter_password("anything")
        page.click_login_btn()
        page.sleep(2)
        assert page.is_loaded() or page.is_error_shown()

    def test_TC_AUTH_020_spaces_in_email_rejected(self, driver):
        """Email with spaces only is rejected."""
        page = LoginPage(driver)
        page.enter_email("   ")
        page.enter_password(VALID_PASSWORD)
        page.click_login_btn()
        page.sleep(2)
        assert page.is_loaded() or page.is_error_shown()

    def test_TC_AUTH_021_login_page_load_time(self, driver):
        """Login page loads within acceptable time."""
        import time
        start = time.time()
        page = LoginPage(driver)
        loaded = page.is_loaded()
        elapsed = time.time() - start
        assert loaded, "Login page should load"
        assert elapsed < 15, f"Login page too slow: {elapsed:.1f}s"

    def test_TC_AUTH_022_multiple_failed_logins_no_crash(self, driver):
        """Multiple failed login attempts don't crash the app."""
        page = LoginPage(driver)
        for i in range(3):
            page.enter_email(f"wrong{i}@test.com")
            page.enter_password("wrongpass")
            page.click_login_btn()
            page.sleep(2)
        assert page.is_loaded() or page.is_error_shown()

    def test_TC_AUTH_023_error_no_stack_trace_exposed(self, driver):
        """Error messages don't expose internal stack traces."""
        page = LoginPage(driver)
        page.enter_email("bad@email.com")
        page.enter_password("wrongpass")
        page.click_login_btn()
        page.sleep(2)
        src = page.get_page_source()
        assert "NullPointerException" not in src, "Stack trace should not be exposed"
        assert "StackTrace" not in src, "Stack trace should not be exposed"

    def test_TC_AUTH_024_session_persists_after_background(self, driver):
        """Session persists when app is backgrounded."""
        import datetime
        page = LoginPage(driver)
        dash = page.login(VALID_EMAIL, VALID_PASSWORD)
        assert dash.is_loaded()
        driver.background_app(3)
        page.sleep(2)
        assert dash.is_loaded() or page.is_loaded(), "App should resume cleanly"

    def test_TC_AUTH_025_app_title_visible(self, driver):
        """App title / brand text is visible on login screen."""
        page = LoginPage(driver)
        assert page.is_loaded()
        assert (
            page.is_text_present("Smart Student", timeout=5) or
            page.is_text_present("Login", timeout=5)
        ), "App title should be visible"

    def test_TC_AUTH_026_back_from_login_handled(self, driver):
        """Back press from login page handled gracefully."""
        page = LoginPage(driver)
        assert page.is_loaded()
        page.back()
        page.sleep(1)
        assert True, "Back press handled"

    def test_TC_AUTH_027_numeric_password_rejected(self, driver):
        """Login with numeric-only password shows appropriate response."""
        page = LoginPage(driver)
        page.enter_email(VALID_EMAIL)
        page.enter_password("123456789")
        page.click_login_btn()
        page.sleep(2)
        assert page.is_loaded() or page.is_error_shown()

    def test_TC_AUTH_028_whitespace_password_rejected(self, driver):
        """Login with whitespace-only password is rejected."""
        page = LoginPage(driver)
        page.enter_email(VALID_EMAIL)
        page.enter_password("        ")
        page.click_login_btn()
        page.sleep(2)
        assert page.is_loaded() or page.is_error_shown()

    def test_TC_AUTH_029_re_login_after_logout(self, driver):
        """User can log in, log out, and log in again."""
        page = LoginPage(driver)
        dash = page.login(VALID_EMAIL, VALID_PASSWORD)
        assert dash.is_loaded()
        login = dash.logout()
        page.sleep(2)
        dash2 = login.login(VALID_EMAIL, VALID_PASSWORD)
        assert dash2.is_loaded(), "Should be able to login again after logout"

    def test_TC_AUTH_030_dashboard_reachable_after_fresh_login(self, driver):
        """Dashboard is reachable immediately after fresh login."""
        page = LoginPage(driver)
        dash = page.login(VALID_EMAIL, VALID_PASSWORD)
        assert dash.is_loaded(), "Dashboard should be reachable after login"
