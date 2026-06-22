"""
base_page.py — Base Page Object with common element interactions
"""
import time
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import (
    TimeoutException, NoSuchElementException, WebDriverException
)
from config import EXPLICIT_WAIT, ELEMENT_WAIT


class BasePage:
    """All Page Objects inherit from this class."""

    def __init__(self, driver):
        self.driver = driver
        self.wait = WebDriverWait(driver, EXPLICIT_WAIT)
        self.short_wait = WebDriverWait(driver, ELEMENT_WAIT)

    # ── Wait helpers ──────────────────────────────────────────────

    def wait_for_element(self, by, value, timeout=None):
        t = timeout or ELEMENT_WAIT
        try:
            return WebDriverWait(self.driver, t).until(
                EC.presence_of_element_located((by, value))
            )
        except TimeoutException:
            return None

    def wait_for_clickable(self, by, value, timeout=None):
        t = timeout or ELEMENT_WAIT
        try:
            return WebDriverWait(self.driver, t).until(
                EC.element_to_be_clickable((by, value))
            )
        except TimeoutException:
            return None

    # ── Find helpers ──────────────────────────────────────────────

    def find(self, by, value):
        try:
            return self.driver.find_element(by, value)
        except (NoSuchElementException, WebDriverException):
            return None

    def finds(self, by, value):
        try:
            return self.driver.find_elements(by, value)
        except (NoSuchElementException, WebDriverException):
            return []

    def find_by_text(self, text):
        return self.find(
            AppiumBy.ANDROID_UIAUTOMATOR,
            f'new UiSelector().text("{text}")'
        )

    def find_by_partial_text(self, text):
        return self.find(
            AppiumBy.ANDROID_UIAUTOMATOR,
            f'new UiSelector().textContains("{text}")'
        )

    def find_field_by_hint(self, hint_text):
        return self.find(
            AppiumBy.ANDROID_UIAUTOMATOR,
            f'new UiSelector().text("{hint_text}")'
        )

    # ── Interaction helpers ───────────────────────────────────────

    def tap(self, by, value, timeout=None):
        el = self.wait_for_clickable(by, value, timeout)
        if el:
            el.click()
            return True
        return False

    def type_text(self, by, value, text, clear=True):
        el = self.wait_for_element(by, value)
        if el:
            if clear:
                el.clear()
            el.send_keys(text)
            return True
        return False

    def type_into_hint(self, hint_text, text):
        """Type into a Flutter TextField identified by its hint."""
        el = self.find_field_by_hint(hint_text)
        if el:
            el.clear()
            el.send_keys(text)
            return True
        return False

    def is_displayed(self, by, value, timeout=5):
        el = self.wait_for_element(by, value, timeout=timeout)
        try:
            return el is not None and el.is_displayed()
        except Exception:
            return False

    def is_text_present(self, text, timeout=5):
        el = self.wait_for_element(
            AppiumBy.ANDROID_UIAUTOMATOR,
            f'new UiSelector().textContains("{text}")',
            timeout=timeout
        )
        return el is not None

    def get_text(self, by, value):
        el = self.find(by, value)
        return el.text if el else ""

    # ── Navigation ────────────────────────────────────────────────

    def back(self):
        try:
            self.driver.back()
        except Exception:
            pass

    def hide_keyboard(self):
        try:
            self.driver.hide_keyboard()
        except Exception:
            pass

    # ── Swipe ─────────────────────────────────────────────────────

    def swipe_up(self):
        size = self.driver.get_window_size()
        w, h = size["width"], size["height"]
        self.driver.swipe(w // 2, int(h * 0.75), w // 2, int(h * 0.25), 600)

    def swipe_down(self):
        size = self.driver.get_window_size()
        w, h = size["width"], size["height"]
        self.driver.swipe(w // 2, int(h * 0.25), w // 2, int(h * 0.75), 600)

    # ── Utility ───────────────────────────────────────────────────

    def sleep(self, seconds=1):
        time.sleep(seconds)

    def get_page_source(self):
        try:
            return self.driver.page_source
        except Exception:
            return ""

    def is_keyboard_shown(self):
        try:
            return self.driver.is_keyboard_shown()
        except Exception:
            return False
