from selenium.webdriver.common.by import By
from .base_page import BasePage

class WelcomePage(BasePage):
    # Depending on whether Flutter Web is built with CanvasKit or HTML renderer,
    # locating elements may require interacting with accessibility semantics (flt-semantics)
    # For now, we will verify the page load by checking the title or a basic element
    
    # Locators
    CANVAS_ELEMENT = (By.TAG_NAME, 'flt-glass-pane')
    
    def __init__(self, driver):
        super().__init__(driver)

    def is_loaded(self):
        # Wait for the main Flutter canvas or glass pane to appear
        # This indicates the Flutter engine has initialized
        self.wait_for_element(self.CANVAS_ELEMENT)
        return True

    def get_page_title(self):
        return self.driver.title
