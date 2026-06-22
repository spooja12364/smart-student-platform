"""
Page Objects for Smart Student Platform — All Screens
"""
import time
from appium.webdriver.common.appiumby import AppiumBy
from selenium.common.exceptions import NoSuchElementException
from pages.base_page import BasePage


# ════════════════════════════════════════════════════════════════
# WELCOME PAGE
# ════════════════════════════════════════════════════════════════
class WelcomePage(BasePage):
    def is_loaded(self):
        return (
            self.is_text_present("Smart Student", timeout=10) or
            self.is_text_present("Welcome", timeout=3) or
            self.is_text_present("Get Started", timeout=3) or
            self.is_text_present("LOGIN", timeout=3)
        )

    def click_login(self):
        el = (
            self.find_by_text("LOGIN") or
            self.find_by_text("Login") or
            self.find_by_partial_text("login")
        )
        if el:
            el.click()
            self.sleep(1)
            return LoginPage(self.driver)
        return LoginPage(self.driver)

    def click_register(self):
        el = (
            self.find_by_text("REGISTER") or
            self.find_by_text("Register") or
            self.find_by_partial_text("Create") or
            self.find_by_partial_text("Sign Up")
        )
        if el:
            el.click()
            self.sleep(1)
        return RegisterPage(self.driver)


# ════════════════════════════════════════════════════════════════
# LOGIN PAGE
# ════════════════════════════════════════════════════════════════
class LoginPage(BasePage):
    def is_loaded(self):
        return (
            self.is_text_present("Login", timeout=10) or
            self.is_text_present("Email", timeout=5) or
            self.is_text_present("LOGIN", timeout=5)
        )

    def _get_email_field(self):
        return (
            self.find_field_by_hint("Email") or
            self.find_field_by_hint("Email Address") or
            self.find(AppiumBy.ANDROID_UIAUTOMATOR,
                      'new UiSelector().className("android.widget.EditText").instance(0)')
        )

    def _get_password_field(self):
        return (
            self.find_field_by_hint("Password") or
            self.find(AppiumBy.ANDROID_UIAUTOMATOR,
                      'new UiSelector().className("android.widget.EditText").instance(1)')
        )

    def enter_email(self, email):
        el = self._get_email_field()
        if el:
            el.clear()
            el.send_keys(email)
            return True
        return False

    def enter_password(self, password):
        el = self._get_password_field()
        if el:
            el.clear()
            el.send_keys(password)
            return True
        return False

    def click_login_btn(self):
        el = (
            self.find_by_text("LOGIN") or
            self.find_by_text("Login") or
            self.find_by_text("SIGN IN")
        )
        if el:
            el.click()
        self.sleep(2)

    def login(self, email, password):
        self.enter_email(email)
        self.enter_password(password)
        self.hide_keyboard()
        self.click_login_btn()
        self.sleep(3)
        return DashboardPage(self.driver)

    def click_forgot_password(self):
        el = (
            self.find_by_text("Forgot Password?") or
            self.find_by_partial_text("Forgot")
        )
        if el:
            el.click()
            self.sleep(1)
        return self

    def click_register_link(self):
        el = (
            self.find_by_partial_text("Create account") or
            self.find_by_partial_text("New here") or
            self.find_by_text("Register")
        )
        if el:
            el.click()
            self.sleep(1)
        return RegisterPage(self.driver)

    def is_error_shown(self):
        return (
            self.is_text_present("Invalid", timeout=3) or
            self.is_text_present("Wrong", timeout=3) or
            self.is_text_present("No user", timeout=3) or
            self.is_text_present("fill all", timeout=3) or
            self.is_text_present("Login Failed", timeout=3)
        )

    def get_error_text(self):
        for msg in ["Invalid", "Wrong", "No user", "fill all", "Login Failed", "Error"]:
            if self.is_text_present(msg, timeout=2):
                el = self.find_by_partial_text(msg)
                return el.text if el else msg
        return ""


# ════════════════════════════════════════════════════════════════
# REGISTER PAGE  (4-step wizard)
# ════════════════════════════════════════════════════════════════
class RegisterPage(BasePage):
    def is_loaded(self):
        return (
            self.is_text_present("Who are you", timeout=8) or
            self.is_text_present("Verification", timeout=5) or
            self.is_text_present("Full Name", timeout=5) or
            self.is_text_present("NEXT", timeout=5)
        )

    def enter_full_name(self, name):
        return self.type_into_hint("Full Name", name)

    def enter_username(self, username):
        return self.type_into_hint("Username", username)

    def enter_email(self, email):
        return self.type_into_hint("Email", email)

    def enter_skills(self, skills):
        return self.type_into_hint("Skills", skills) or self.type_into_hint("skills", skills)

    def enter_city(self, city):
        return self.type_into_hint("City", city) or self.type_into_hint("city", city)

    def click_next(self):
        el = self.find_by_text("NEXT") or self.find_by_text("Next")
        if el:
            el.click()
            self.sleep(1)

    def click_complete_registration(self):
        el = (
            self.find_by_text("COMPLETE REGISTRATION") or
            self.find_by_text("Complete Registration") or
            self.find_by_text("REGISTER")
        )
        if el:
            el.click()
            self.sleep(3)

    def is_error_shown(self):
        return (
            self.is_text_present("Please fill", timeout=3) or
            self.is_text_present("already exists", timeout=3) or
            self.is_text_present("must be", timeout=3) or
            self.is_text_present("do not match", timeout=3)
        )

    def already_have_account(self):
        el = (
            self.find_by_partial_text("Already have") or
            self.find_by_partial_text("Login here")
        )
        if el:
            el.click()
            self.sleep(1)
        return LoginPage(self.driver)


# ════════════════════════════════════════════════════════════════
# DASHBOARD PAGE
# ════════════════════════════════════════════════════════════════
class DashboardPage(BasePage):
    def is_loaded(self):
        return (
            self.is_text_present("Welcome back", timeout=10) or
            self.is_text_present("Dashboard", timeout=8) or
            self.is_text_present("Recent Activity", timeout=8) or
            self.is_text_present("Home", timeout=5)
        )

    def is_welcome_text_shown(self):
        return self.is_text_present("Welcome back", timeout=5)

    def tap_search_tab(self):
        el = (
            self.find_by_text("Search") or
            self.find_by_text("Discover") or
            self.find(AppiumBy.ACCESSIBILITY_ID, "Search")
        )
        if el:
            el.click()
            self.sleep(1)
        return SearchPage(self.driver)

    def tap_profile_tab(self):
        el = (
            self.find_by_text("Profile") or
            self.find(AppiumBy.ACCESSIBILITY_ID, "Profile")
        )
        if el:
            el.click()
            self.sleep(1)
        return ProfilePage(self.driver)

    def tap_connections_tab(self):
        el = (
            self.find_by_text("Connections") or
            self.find(AppiumBy.ACCESSIBILITY_ID, "Connections")
        )
        if el:
            el.click()
            self.sleep(1)
        return self

    def tap_chat_tab(self):
        el = (
            self.find_by_text("Chats") or
            self.find_by_text("Chat") or
            self.find(AppiumBy.ACCESSIBILITY_ID, "Chats")
        )
        if el:
            el.click()
            self.sleep(1)
        return ChatPage(self.driver)

    def tap_notifications(self):
        el = (
            self.find_by_text("Notifications") or
            self.find(AppiumBy.ACCESSIBILITY_ID, "Notifications")
        )
        if el:
            el.click()
            self.sleep(1)
        return NotificationsPage(self.driver)

    def tap_skills_tab(self):
        el = (
            self.find_by_text("Skills") or
            self.find_by_text("My Skills") or
            self.find(AppiumBy.ACCESSIBILITY_ID, "Skills")
        )
        if el:
            el.click()
            self.sleep(1)
        return self

    def tap_ai_matching(self):
        el = (
            self.find_by_partial_text("AI") or
            self.find_by_partial_text("Matching")
        )
        if el:
            el.click()
            self.sleep(1)

    def logout(self):
        # Navigate to profile tab and find logout
        self.tap_profile_tab()
        self.sleep(1)
        el = self.find_by_text("Logout") or self.find_by_text("LOGOUT") or self.find_by_text("Sign Out")
        if el:
            el.click()
            self.sleep(2)
        return LoginPage(self.driver)


# ════════════════════════════════════════════════════════════════
# PROFILE PAGE
# ════════════════════════════════════════════════════════════════
class ProfilePage(BasePage):
    def is_loaded(self):
        return (
            self.is_text_present("Profile", timeout=8) or
            self.is_text_present("Skills", timeout=5) or
            self.is_text_present("Edit", timeout=5)
        )

    def tap_edit(self):
        el = (
            self.find_by_text("Edit Profile") or
            self.find_by_text("EDIT") or
            self.find_by_text("Edit") or
            self.find(AppiumBy.ACCESSIBILITY_ID, "Edit")
        )
        if el:
            el.click()
            self.sleep(1)
        return EditProfilePage(self.driver)

    def is_user_name_shown(self, name):
        return self.is_text_present(name, timeout=5)

    def tap_logout(self):
        el = self.find_by_text("Logout") or self.find_by_text("LOGOUT")
        if el:
            el.click()
            self.sleep(2)
        return LoginPage(self.driver)


# ════════════════════════════════════════════════════════════════
# EDIT PROFILE PAGE
# ════════════════════════════════════════════════════════════════
class EditProfilePage(BasePage):
    def is_loaded(self):
        return (
            self.is_text_present("Edit", timeout=8) or
            self.is_text_present("Save", timeout=5) or
            self.is_text_present("Bio", timeout=5)
        )

    def update_name(self, name):
        fields = self.finds(AppiumBy.CLASS_NAME, "android.widget.EditText")
        if fields:
            fields[0].clear()
            fields[0].send_keys(name)
            return True
        return False

    def update_bio(self, bio):
        el = (
            self.find_field_by_hint("Bio") or
            self.find_field_by_hint("bio") or
            self.find_field_by_hint("About")
        )
        if el:
            el.clear()
            el.send_keys(bio)
            return True
        return False

    def click_save(self):
        el = (
            self.find_by_text("Save") or
            self.find_by_text("SAVE") or
            self.find_by_text("Update")
        )
        if el:
            el.click()
            self.sleep(2)
        return ProfilePage(self.driver)

    def is_save_success(self):
        return (
            self.is_text_present("saved", timeout=3) or
            self.is_text_present("Updated", timeout=3) or
            self.is_text_present("Success", timeout=3)
        )


# ════════════════════════════════════════════════════════════════
# SEARCH / DISCOVER PAGE
# ════════════════════════════════════════════════════════════════
class SearchPage(BasePage):
    def is_loaded(self):
        return (
            self.is_text_present("Search", timeout=8) or
            self.is_text_present("Discover", timeout=5) or
            self.is_text_present("Find", timeout=5)
        )

    def search(self, query):
        el = (
            self.find_field_by_hint("Search") or
            self.find_field_by_hint("Search students") or
            self.find_field_by_hint("Find people") or
            self.find(AppiumBy.CLASS_NAME, "android.widget.EditText")
        )
        if el:
            el.clear()
            el.send_keys(query)
            self.sleep(2)
            return True
        return False

    def has_results(self):
        # Check if any result card / name is shown
        results = self.finds(AppiumBy.CLASS_NAME, "android.widget.TextView")
        return len(results) > 2

    def is_no_result_shown(self):
        return (
            self.is_text_present("No result", timeout=3) or
            self.is_text_present("no user", timeout=3) or
            self.is_text_present("not found", timeout=3)
        )

    def clear_search(self):
        el = self.find(AppiumBy.CLASS_NAME, "android.widget.EditText")
        if el:
            el.clear()


# ════════════════════════════════════════════════════════════════
# NOTIFICATIONS PAGE
# ════════════════════════════════════════════════════════════════
class NotificationsPage(BasePage):
    def is_loaded(self):
        return (
            self.is_text_present("Notification", timeout=8) or
            self.is_text_present("notification", timeout=5)
        )

    def has_notifications(self):
        items = self.finds(AppiumBy.CLASS_NAME, "android.widget.TextView")
        return len(items) > 2

    def is_empty_state(self):
        return (
            self.is_text_present("No notification", timeout=3) or
            self.is_text_present("empty", timeout=3)
        )


# ════════════════════════════════════════════════════════════════
# CHAT / MESSAGES PAGE
# ════════════════════════════════════════════════════════════════
class ChatPage(BasePage):
    def is_loaded(self):
        return (
            self.is_text_present("Chat", timeout=8) or
            self.is_text_present("Message", timeout=5) or
            self.is_text_present("Conversation", timeout=5)
        )

    def has_chats(self):
        items = self.finds(AppiumBy.CLASS_NAME, "android.widget.TextView")
        return len(items) > 2


# ════════════════════════════════════════════════════════════════
# CONNECTIONS PAGE
# ════════════════════════════════════════════════════════════════
class ConnectionsPage(BasePage):
    def is_loaded(self):
        return (
            self.is_text_present("Connection", timeout=8) or
            self.is_text_present("People", timeout=5)
        )

    def has_connections(self):
        items = self.finds(AppiumBy.CLASS_NAME, "android.widget.TextView")
        return len(items) > 2


# ════════════════════════════════════════════════════════════════
# AI MATCHING PAGE
# ════════════════════════════════════════════════════════════════
class AIMatchingPage(BasePage):
    def is_loaded(self):
        return (
            self.is_text_present("AI", timeout=8) or
            self.is_text_present("Match", timeout=5) or
            self.is_text_present("Recommend", timeout=5)
        )


# ════════════════════════════════════════════════════════════════
# MY SKILLS PAGE
# ════════════════════════════════════════════════════════════════
class SkillsPage(BasePage):
    def is_loaded(self):
        return (
            self.is_text_present("Skill", timeout=8) or
            self.is_text_present("Add skill", timeout=5)
        )

    def add_skill(self, skill_name):
        el = self.find_by_partial_text("Add") or self.find(
            AppiumBy.CLASS_NAME, "android.widget.EditText"
        )
        if el:
            el.send_keys(skill_name)
            return True
        return False
