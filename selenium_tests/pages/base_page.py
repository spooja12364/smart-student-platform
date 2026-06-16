from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

class BasePage:
    def __init__(self, driver):
        self.driver = driver
        self.timeout = 15

    def navigate(self, url):
        self.driver.get(url)

    def wait_for_element(self, locator):
        return WebDriverWait(self.driver, self.timeout).until(
            EC.presence_of_element_located(locator)
        )

    def click(self, locator):
        element = self.wait_for_element(locator)
        element.click()

    def get_text(self, locator):
        element = self.wait_for_element(locator)
        return element.text
