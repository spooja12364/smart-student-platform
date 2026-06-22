package com.smartstudent.pages;

import com.smartstudent.drivers.DriverManager;
import com.smartstudent.utils.ScreenshotUtils;
import com.smartstudent.utils.WaitUtils;
import io.appium.java_client.android.AndroidDriver;
import io.appium.java_client.pagefactory.AppiumFieldDecorator;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.PageFactory;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.time.Duration;
import java.util.List;

/**
 * Base Page Object providing common actions for all page objects.
 */
public abstract class BasePage {

    protected final Logger logger = LogManager.getLogger(getClass());
    protected AndroidDriver driver;
    protected WaitUtils waitUtils;
    protected ScreenshotUtils screenshotUtils;

    public BasePage() {
        this.driver = DriverManager.getDriver();
        this.waitUtils = new WaitUtils(driver);
        this.screenshotUtils = new ScreenshotUtils(driver);
        PageFactory.initElements(new AppiumFieldDecorator(driver, Duration.ofSeconds(15)), this);
    }

    // ── Click ────────────────────────────────────────────────────

    protected void click(WebElement element) {
        waitUtils.waitForClickable(element);
        element.click();
        logger.debug("Clicked: {}", element);
    }

    protected void click(By locator) {
        WebElement el = waitUtils.waitForVisible(locator);
        el.click();
        logger.debug("Clicked by locator: {}", locator);
    }

    // ── Type ─────────────────────────────────────────────────────

    protected void type(WebElement element, String text) {
        waitUtils.waitForClickable(element);
        element.clear();
        element.sendKeys(text);
        logger.debug("Typed '{}' into element", text);
    }

    protected void type(By locator, String text) {
        WebElement el = waitUtils.waitForVisible(locator);
        el.clear();
        el.sendKeys(text);
    }

    protected void clearAndType(WebElement element, String text) {
        waitUtils.waitForClickable(element);
        element.clear();
        element.sendKeys(text);
    }

    // ── Read ─────────────────────────────────────────────────────

    protected String getText(WebElement element) {
        waitUtils.waitForVisible(element);
        return element.getText().trim();
    }

    protected String getText(By locator) {
        return waitUtils.waitForVisible(locator).getText().trim();
    }

    protected String getAttribute(WebElement element, String attr) {
        waitUtils.waitForVisible(element);
        return element.getAttribute(attr);
    }

    // ── Visibility ───────────────────────────────────────────────

    protected boolean isDisplayed(WebElement element) {
        try {
            return element.isDisplayed();
        } catch (Exception e) {
            return false;
        }
    }

    protected boolean isDisplayed(By locator) {
        try {
            return driver.findElement(locator).isDisplayed();
        } catch (Exception e) {
            return false;
        }
    }

    protected boolean isEnabled(WebElement element) {
        try {
            return element.isEnabled();
        } catch (Exception e) {
            return false;
        }
    }

    // ── Wait Helpers ─────────────────────────────────────────────

    protected WebElement waitForElement(By locator, int timeoutSeconds) {
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(timeoutSeconds));
        return wait.until(ExpectedConditions.visibilityOfElementLocated(locator));
    }

    protected boolean waitForText(By locator, String text, int timeoutSeconds) {
        try {
            WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(timeoutSeconds));
            return wait.until(ExpectedConditions.textToBePresentInElementLocated(locator, text));
        } catch (Exception e) {
            return false;
        }
    }

    protected boolean waitForElementToDisappear(By locator, int timeoutSeconds) {
        try {
            WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(timeoutSeconds));
            return wait.until(ExpectedConditions.invisibilityOfElementLocated(locator));
        } catch (Exception e) {
            return false;
        }
    }

    // ── List ─────────────────────────────────────────────────────

    protected List<WebElement> getElements(By locator) {
        return driver.findElements(locator);
    }

    protected int getElementCount(By locator) {
        return driver.findElements(locator).size();
    }

    // ── Scroll ───────────────────────────────────────────────────

    protected void scrollToElement(By locator) {
        try {
            driver.findElement(locator).click();
        } catch (Exception e) {
            // Scroll using UiScrollable
            String uiScrollable = "new UiScrollable(new UiSelector().scrollable(true))"
                    + ".scrollIntoView(new UiSelector().resourceId(\"" + locator + "\"))";
            driver.findElement(By.xpath("//*[@scrollable='true']"));
        }
    }

    protected void swipeUp() {
        int height = driver.manage().window().getSize().getHeight();
        int width  = driver.manage().window().getSize().getWidth();
        driver.executeScript("mobile: swipeGesture", new java.util.HashMap<String, Object>() {{
            put("left", width / 4);
            put("top", (int)(height * 0.75));
            put("width", width / 2);
            put("height", (int)(height * 0.5));
            put("direction", "up");
            put("percent", 0.85);
        }});
    }

    protected void swipeDown() {
        int height = driver.manage().window().getSize().getHeight();
        int width  = driver.manage().window().getSize().getWidth();
        driver.executeScript("mobile: swipeGesture", new java.util.HashMap<String, Object>() {{
            put("left", width / 4);
            put("top", (int)(height * 0.25));
            put("width", width / 2);
            put("height", (int)(height * 0.5));
            put("direction", "down");
            put("percent", 0.85);
        }});
    }

    // ── Screenshot ───────────────────────────────────────────────

    protected String captureScreenshot(String name) {
        return screenshotUtils.capture(name);
    }

    // ── Navigate Back ─────────────────────────────────────────────

    protected void navigateBack() {
        driver.navigate().back();
        logger.debug("Navigated back");
    }

    protected void pressHome() {
        driver.executeScript("mobile: pressKey", new java.util.HashMap<String, Object>() {{
            put("keycode", 3);
        }});
    }

    // ── Keyboard ─────────────────────────────────────────────────

    protected void hideKeyboard() {
        try {
            driver.hideKeyboard();
        } catch (Exception e) {
            logger.debug("Keyboard not present or already hidden");
        }
    }

    // ── Abstract ─────────────────────────────────────────────────

    /**
     * Verify the page is loaded/displayed.
     */
    public abstract boolean isPageLoaded();
}
