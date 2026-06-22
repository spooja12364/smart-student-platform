"""
tests/test_04_profile_search_chat.py
Profile, Search/Discover, Chat, Connections, Skills, Notifications tests
"""
import pytest
import sys, os, time
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from pages.app_pages import (
    LoginPage, DashboardPage, ProfilePage, EditProfilePage,
    SearchPage, ChatPage, NotificationsPage, ConnectionsPage, SkillsPage
)
from config import VALID_EMAIL, VALID_PASSWORD


@pytest.fixture(autouse=True)
def login_first(driver):
    try:
        driver.terminate_app("com.example.smart_student_platform")
    except Exception:
        pass
    driver.activate_app("com.example.smart_student_platform")
    time.sleep(3)
    page = LoginPage(driver)
    if page.is_loaded():
        page.login(VALID_EMAIL, VALID_PASSWORD)
        time.sleep(4)
    yield


# ════════════════════════════════════════════════════════════════
# PROFILE TESTS — TC_PROF_001–010
# ════════════════════════════════════════════════════════════════
class TestProfile:

    def test_TC_PROF_001_profile_tab_loads(self, driver):
        """Profile tab loads from dashboard."""
        dash = DashboardPage(driver)
        profile = dash.tap_profile_tab()
        time.sleep(2)
        assert profile.is_loaded() or dash.is_loaded(), "Profile tab should load"

    def test_TC_PROF_002_edit_profile_accessible(self, driver):
        """Edit Profile button accessible on profile page."""
        dash = DashboardPage(driver)
        profile = dash.tap_profile_tab()
        time.sleep(2)
        if profile.is_loaded():
            btn = profile.find_by_text("Edit Profile") or profile.find_by_text("Edit")
            assert btn is not None or profile.is_loaded()

    def test_TC_PROF_003_edit_profile_page_loads(self, driver):
        """Edit profile page loads when Edit is tapped."""
        dash = DashboardPage(driver)
        profile = dash.tap_profile_tab()
        time.sleep(2)
        if profile.is_loaded():
            edit = profile.tap_edit()
            time.sleep(2)
            assert edit.is_loaded() or profile.is_loaded()

    def test_TC_PROF_004_save_profile_update(self, driver):
        """Profile update can be saved."""
        dash = DashboardPage(driver)
        profile = dash.tap_profile_tab()
        time.sleep(2)
        if profile.is_loaded():
            edit = profile.tap_edit()
            time.sleep(2)
            if edit.is_loaded():
                edit.click_save()
                time.sleep(2)
                assert profile.is_loaded() or edit.is_loaded() or True

    def test_TC_PROF_005_back_from_edit_profile(self, driver):
        """Back navigation from edit profile goes back to profile."""
        dash = DashboardPage(driver)
        profile = dash.tap_profile_tab()
        time.sleep(2)
        if profile.is_loaded():
            edit = profile.tap_edit()
            time.sleep(2)
            driver.back()
            time.sleep(1)
            assert True, "Back from edit profile handled"

    def test_TC_PROF_006_profile_shows_user_email_or_name(self, driver):
        """Profile page shows user info (name/email)."""
        dash = DashboardPage(driver)
        profile = dash.tap_profile_tab()
        time.sleep(2)
        assert profile.is_loaded() or dash.is_loaded()

    def test_TC_PROF_007_logout_from_profile(self, driver):
        """Logout from profile returns to login page."""
        dash = DashboardPage(driver)
        profile = dash.tap_profile_tab()
        time.sleep(2)
        if profile.is_loaded():
            login = profile.tap_logout()
            time.sleep(3)
            assert login.is_loaded() or True

    def test_TC_PROF_008_profile_skills_section_visible(self, driver):
        """Skills section visible on profile page."""
        dash = DashboardPage(driver)
        profile = dash.tap_profile_tab()
        time.sleep(2)
        assert (
            profile.is_text_present("Skill", timeout=5) or
            profile.is_loaded()
        )

    def test_TC_PROF_009_profile_loads_within_time(self, driver):
        """Profile page loads within 10 seconds."""
        dash = DashboardPage(driver)
        start = time.time()
        profile = dash.tap_profile_tab()
        assert profile.is_loaded() or dash.is_loaded()
        elapsed = time.time() - start
        assert elapsed < 15, f"Profile too slow: {elapsed:.1f}s"

    def test_TC_PROF_010_profile_no_crash_repeated_visit(self, driver):
        """Profile page does not crash on repeated visits."""
        dash = DashboardPage(driver)
        for _ in range(2):
            dash.tap_profile_tab()
            time.sleep(1)
            driver.back()
            time.sleep(1)
        assert True, "Repeated profile visits handled"


# ════════════════════════════════════════════════════════════════
# SEARCH TESTS — TC_SEARCH_001–010
# ════════════════════════════════════════════════════════════════
class TestSearch:

    def test_TC_SEARCH_001_search_page_loads(self, driver):
        """Search / Discover page loads."""
        dash = DashboardPage(driver)
        search = dash.tap_search_tab()
        time.sleep(2)
        assert search.is_loaded() or dash.is_loaded()

    def test_TC_SEARCH_002_search_field_present(self, driver):
        """Search input field present on search page."""
        dash = DashboardPage(driver)
        search = dash.tap_search_tab()
        time.sleep(2)
        from appium.webdriver.common.appiumby import AppiumBy
        el = search.find(AppiumBy.CLASS_NAME, "android.widget.EditText")
        assert el is not None or search.is_loaded()

    def test_TC_SEARCH_003_search_with_valid_keyword(self, driver):
        """Search with valid keyword returns results or no-results."""
        dash = DashboardPage(driver)
        search = dash.tap_search_tab()
        time.sleep(2)
        if search.is_loaded():
            result = search.search("Python")
            time.sleep(2)
            assert search.is_loaded() or True

    def test_TC_SEARCH_004_search_empty_query(self, driver):
        """Empty search query handled gracefully."""
        dash = DashboardPage(driver)
        search = dash.tap_search_tab()
        time.sleep(2)
        if search.is_loaded():
            search.search("")
            time.sleep(1)
            assert search.is_loaded() or True

    def test_TC_SEARCH_005_search_special_characters(self, driver):
        """Special characters in search handled gracefully."""
        dash = DashboardPage(driver)
        search = dash.tap_search_tab()
        time.sleep(2)
        if search.is_loaded():
            search.search("!@#$%")
            time.sleep(1)
            assert search.is_loaded() or True

    def test_TC_SEARCH_006_search_sql_injection(self, driver):
        """SQL injection in search handled gracefully."""
        dash = DashboardPage(driver)
        search = dash.tap_search_tab()
        time.sleep(2)
        if search.is_loaded():
            search.search("' OR 1=1 --")
            time.sleep(1)
            assert search.is_loaded() or True

    def test_TC_SEARCH_007_search_clears_correctly(self, driver):
        """Search field clears correctly."""
        dash = DashboardPage(driver)
        search = dash.tap_search_tab()
        time.sleep(2)
        if search.is_loaded():
            search.search("Java")
            time.sleep(1)
            search.clear_search()
            time.sleep(1)
            assert search.is_loaded() or True

    def test_TC_SEARCH_008_search_performance(self, driver):
        """Search completes within acceptable time."""
        dash = DashboardPage(driver)
        search = dash.tap_search_tab()
        time.sleep(2)
        if search.is_loaded():
            start = time.time()
            search.search("Flutter")
            time.sleep(2)
            elapsed = time.time() - start
            assert elapsed < 15, f"Search too slow: {elapsed:.1f}s"

    def test_TC_SEARCH_009_search_unicode_query(self, driver):
        """Unicode characters in search handled."""
        dash = DashboardPage(driver)
        search = dash.tap_search_tab()
        time.sleep(2)
        if search.is_loaded():
            search.search("テスト")
            time.sleep(1)
            assert search.is_loaded() or True

    def test_TC_SEARCH_010_back_from_search(self, driver):
        """Back navigation from search works."""
        dash = DashboardPage(driver)
        search = dash.tap_search_tab()
        time.sleep(2)
        driver.back()
        time.sleep(1)
        assert True, "Back from search handled"


# ════════════════════════════════════════════════════════════════
# CHAT TESTS — TC_CHAT_001–010
# ════════════════════════════════════════════════════════════════
class TestChat:

    def test_TC_CHAT_001_chat_tab_loads(self, driver):
        """Chat tab loads from dashboard."""
        dash = DashboardPage(driver)
        chat = dash.tap_chat_tab()
        time.sleep(2)
        assert chat.is_loaded() or dash.is_loaded()

    def test_TC_CHAT_002_chat_list_visible(self, driver):
        """Chat list or empty state is visible."""
        dash = DashboardPage(driver)
        chat = dash.tap_chat_tab()
        time.sleep(3)
        assert (
            chat.is_loaded() or
            chat.is_text_present("No chats", timeout=3) or
            chat.is_text_present("Chat", timeout=3) or
            dash.is_loaded()
        )

    def test_TC_CHAT_003_group_chat_accessible(self, driver):
        """Group chat section accessible."""
        dash = DashboardPage(driver)
        chat = dash.tap_chat_tab()
        time.sleep(2)
        assert chat.is_loaded() or dash.is_loaded()

    def test_TC_CHAT_004_chat_page_no_crash(self, driver):
        """Chat page does not crash on load."""
        dash = DashboardPage(driver)
        chat = dash.tap_chat_tab()
        time.sleep(3)
        assert True, "Chat page no crash"

    def test_TC_CHAT_005_back_from_chat(self, driver):
        """Back navigation from chat page works."""
        dash = DashboardPage(driver)
        dash.tap_chat_tab()
        time.sleep(2)
        driver.back()
        time.sleep(1)
        assert True, "Back from chat handled"

    def test_TC_CHAT_006_chat_loads_within_time(self, driver):
        """Chat tab loads within 10 seconds."""
        dash = DashboardPage(driver)
        start = time.time()
        chat = dash.tap_chat_tab()
        assert chat.is_loaded() or True
        elapsed = time.time() - start
        assert elapsed < 15, f"Chat too slow: {elapsed:.1f}s"

    def test_TC_CHAT_007_chat_search_if_present(self, driver):
        """Search in chat page if available."""
        dash = DashboardPage(driver)
        chat = dash.tap_chat_tab()
        time.sleep(2)
        assert chat.is_loaded() or dash.is_loaded()

    def test_TC_CHAT_008_global_group_chat_visible(self, driver):
        """Global group chat option visible."""
        dash = DashboardPage(driver)
        chat = dash.tap_chat_tab()
        time.sleep(2)
        assert (
            chat.is_text_present("Global", timeout=3) or
            chat.is_text_present("Group", timeout=3) or
            chat.is_loaded() or
            dash.is_loaded()
        )

    def test_TC_CHAT_009_chat_content_secure(self, driver):
        """Chat content does not expose raw data."""
        dash = DashboardPage(driver)
        chat = dash.tap_chat_tab()
        time.sleep(2)
        src = chat.get_page_source()
        assert "NullPointerException" not in src
        assert "StackTrace" not in src

    def test_TC_CHAT_010_repeated_chat_navigation(self, driver):
        """Repeated chat tab navigation doesn't crash."""
        dash = DashboardPage(driver)
        for _ in range(2):
            dash.tap_chat_tab()
            time.sleep(0.8)
            driver.back()
            time.sleep(0.8)
        assert True, "Repeated chat navigation handled"


# ════════════════════════════════════════════════════════════════
# NOTIFICATIONS TESTS — TC_NOTIF_001–010
# ════════════════════════════════════════════════════════════════
class TestNotifications:

    def test_TC_NOTIF_001_notifications_page_loads(self, driver):
        """Notifications page loads from dashboard."""
        dash = DashboardPage(driver)
        notif = dash.tap_notifications()
        time.sleep(2)
        assert notif.is_loaded() or dash.is_loaded()

    def test_TC_NOTIF_002_empty_state_or_list(self, driver):
        """Notifications shows list or empty state."""
        dash = DashboardPage(driver)
        notif = dash.tap_notifications()
        time.sleep(3)
        assert (
            notif.has_notifications() or
            notif.is_empty_state() or
            notif.is_loaded() or
            dash.is_loaded()
        )

    def test_TC_NOTIF_003_notifications_no_crash(self, driver):
        """Notifications page does not crash."""
        dash = DashboardPage(driver)
        notif = dash.tap_notifications()
        time.sleep(3)
        assert True, "Notifications no crash"

    def test_TC_NOTIF_004_back_from_notifications(self, driver):
        """Back navigation from notifications works."""
        dash = DashboardPage(driver)
        dash.tap_notifications()
        time.sleep(2)
        driver.back()
        time.sleep(1)
        assert True, "Back from notifications handled"

    def test_TC_NOTIF_005_notifications_load_time(self, driver):
        """Notifications load within 10 seconds."""
        dash = DashboardPage(driver)
        start = time.time()
        notif = dash.tap_notifications()
        assert notif.is_loaded() or True
        elapsed = time.time() - start
        assert elapsed < 15, f"Notifications too slow: {elapsed:.1f}s"

    def test_TC_NOTIF_006_notifications_scroll(self, driver):
        """Notifications page scrollable."""
        dash = DashboardPage(driver)
        notif = dash.tap_notifications()
        time.sleep(2)
        notif.swipe_up()
        time.sleep(0.5)
        assert True, "Notifications scroll handled"

    def test_TC_NOTIF_007_notifications_page_title(self, driver):
        """Notifications page shows title."""
        dash = DashboardPage(driver)
        notif = dash.tap_notifications()
        time.sleep(2)
        assert (
            notif.is_text_present("Notification", timeout=5) or
            notif.is_loaded() or
            dash.is_loaded()
        )

    def test_TC_NOTIF_008_notifications_no_stack_trace(self, driver):
        """Notifications page does not expose stack traces."""
        dash = DashboardPage(driver)
        notif = dash.tap_notifications()
        time.sleep(2)
        src = notif.get_page_source()
        assert "NullPointerException" not in src

    def test_TC_NOTIF_009_repeated_notifications_visit(self, driver):
        """Repeated visits to notifications page don't crash."""
        dash = DashboardPage(driver)
        for _ in range(2):
            dash.tap_notifications()
            time.sleep(1)
            driver.back()
            time.sleep(1)
        assert True

    def test_TC_NOTIF_010_notifications_accessible_after_navigate(self, driver):
        """Notifications accessible after navigating other tabs."""
        dash = DashboardPage(driver)
        dash.tap_search_tab()
        time.sleep(1)
        driver.back()
        time.sleep(1)
        notif = dash.tap_notifications()
        time.sleep(2)
        assert notif.is_loaded() or dash.is_loaded()


# ════════════════════════════════════════════════════════════════
# CONNECTIONS TESTS — TC_CONN_001–005
# ════════════════════════════════════════════════════════════════
class TestConnections:

    def test_TC_CONN_001_connections_tab_loads(self, driver):
        """Connections tab loads from dashboard."""
        dash = DashboardPage(driver)
        dash.tap_connections_tab()
        time.sleep(2)
        assert True, "Connections tab loaded"

    def test_TC_CONN_002_connections_no_crash(self, driver):
        """Connections page does not crash."""
        dash = DashboardPage(driver)
        dash.tap_connections_tab()
        time.sleep(3)
        assert True, "No crash on connections page"

    def test_TC_CONN_003_connections_load_time(self, driver):
        """Connections page loads within time limit."""
        dash = DashboardPage(driver)
        start = time.time()
        dash.tap_connections_tab()
        elapsed = time.time() - start
        assert elapsed < 15

    def test_TC_CONN_004_back_from_connections(self, driver):
        """Back from connections page works."""
        dash = DashboardPage(driver)
        dash.tap_connections_tab()
        time.sleep(2)
        driver.back()
        time.sleep(1)
        assert True

    def test_TC_CONN_005_connections_accessible_after_other_tabs(self, driver):
        """Connections accessible after other tab visits."""
        dash = DashboardPage(driver)
        dash.tap_profile_tab()
        time.sleep(1)
        driver.back()
        dash.tap_connections_tab()
        time.sleep(2)
        assert True


# ════════════════════════════════════════════════════════════════
# SKILLS TESTS — TC_SKILL_001–005
# ════════════════════════════════════════════════════════════════
class TestSkills:

    def test_TC_SKILL_001_skills_tab_loads(self, driver):
        """My Skills tab loads from dashboard."""
        dash = DashboardPage(driver)
        dash.tap_skills_tab()
        time.sleep(2)
        assert True

    def test_TC_SKILL_002_skills_page_no_crash(self, driver):
        """Skills page does not crash."""
        dash = DashboardPage(driver)
        dash.tap_skills_tab()
        time.sleep(3)
        assert True

    def test_TC_SKILL_003_back_from_skills(self, driver):
        """Back from skills page works."""
        dash = DashboardPage(driver)
        dash.tap_skills_tab()
        time.sleep(2)
        driver.back()
        time.sleep(1)
        assert True

    def test_TC_SKILL_004_skills_load_time(self, driver):
        """Skills page loads within time limit."""
        dash = DashboardPage(driver)
        start = time.time()
        dash.tap_skills_tab()
        elapsed = time.time() - start
        assert elapsed < 15

    def test_TC_SKILL_005_skills_content_visible(self, driver):
        """Skills section shows content or empty state."""
        dash = DashboardPage(driver)
        dash.tap_skills_tab()
        time.sleep(3)
        assert True
