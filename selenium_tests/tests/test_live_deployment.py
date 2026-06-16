import pytest
from pages.welcome_page import WelcomePage

class TestLiveDeployment:

    def test_app_loads_successfully(self, driver, base_url):
        # Initialize the Welcome Page
        welcome_page = WelcomePage(driver)
        
        # Navigate to the deployed GitHub Pages URL
        welcome_page.navigate(base_url)
        
        # Verify that the Flutter application engine loads
        assert welcome_page.is_loaded(), "Flutter app canvas did not load in time."
        
        # Verify title if available
        title = welcome_page.get_page_title()
        assert "Smart Student Platform" in title, f"Expected title to contain 'Smart Student Platform', got '{title}'"
