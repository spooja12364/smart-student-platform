package com.smartstudent.utils;

import io.appium.java_client.android.AndroidDriver;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.time.Duration;

/**
 * Wait utility for explicit waits and polling.
 */
public class WaitUtils {

    private static final Logger logger = LogManager.getLogger(WaitUtils.class);
    private final AndroidDriver driver;
    private final int defaultTimeout;

    public WaitUtils(AndroidDriver driver) {
        this.driver = driver;
        this.defaultTimeout = 30;
    }

    public WaitUtils(AndroidDriver driver, int defaultTimeout) {
        this.driver = driver;
        this.defaultTimeout = defaultTimeout;
    }

    // ── Element Waits ─────────────────────────────────────────────

    public WebElement waitForVisible(By locator) {
        return waitForVisible(locator, defaultTimeout);
    }

    public WebElement waitForVisible(By locator, int timeout) {
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(timeout));
        return wait.until(ExpectedConditions.visibilityOfElementLocated(locator));
    }

    public WebElement waitForVisible(WebElement element) {
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(defaultTimeout));
        return wait.until(ExpectedConditions.visibilityOf(element));
    }

    public WebElement waitForClickable(By locator) {
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(defaultTimeout));
        return wait.until(ExpectedConditions.elementToBeClickable(locator));
    }

    public WebElement waitForClickable(WebElement element) {
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(defaultTimeout));
        return wait.until(ExpectedConditions.elementToBeClickable(element));
    }

    public boolean waitForInvisible(By locator) {
        return waitForInvisible(locator, defaultTimeout);
    }

    public boolean waitForInvisible(By locator, int timeout) {
        try {
            WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(timeout));
            return wait.until(ExpectedConditions.invisibilityOfElementLocated(locator));
        } catch (Exception e) {
            return false;
        }
    }

    public boolean waitForText(By locator, String text) {
        try {
            WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(defaultTimeout));
            return wait.until(ExpectedConditions.textToBePresentInElementLocated(locator, text));
        } catch (Exception e) {
            return false;
        }
    }

    public boolean waitForPresence(By locator, int timeout) {
        try {
            WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(timeout));
            wait.until(ExpectedConditions.presenceOfElementLocated(locator));
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    // ── Time Waits ────────────────────────────────────────────────

    public void waitForSeconds(int seconds) {
        try {
            Thread.sleep(seconds * 1000L);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    public void waitForMilliseconds(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    // ── Polling ───────────────────────────────────────────────────

    public boolean waitUntilElementPresent(By locator, int maxWaitSeconds) {
        long end = System.currentTimeMillis() + (maxWaitSeconds * 1000L);
        while (System.currentTimeMillis() < end) {
            try {
                if (!driver.findElements(locator).isEmpty()) return true;
            } catch (Exception ignored) {}
            waitForMilliseconds(500);
        }
        return false;
    }

    public boolean waitUntilTextContains(By locator, String partialText, int maxWaitSeconds) {
        long end = System.currentTimeMillis() + (maxWaitSeconds * 1000L);
        while (System.currentTimeMillis() < end) {
            try {
                String text = driver.findElement(locator).getText();
                if (text != null && text.contains(partialText)) return true;
            } catch (Exception ignored) {}
            waitForMilliseconds(500);
        }
        return false;
    }
}
