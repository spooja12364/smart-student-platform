package com.smartstudent.drivers;

import com.smartstudent.config.AppiumConfig;
import io.appium.java_client.android.AndroidDriver;
import io.appium.java_client.android.options.UiAutomator2Options;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.openqa.selenium.remote.DesiredCapabilities;

import java.io.File;
import java.net.URL;
import java.time.Duration;

/**
 * Manages AndroidDriver instances per thread for parallel execution.
 */
public class DriverManager {

    private static final Logger logger = LogManager.getLogger(DriverManager.class);
    private static final ThreadLocal<AndroidDriver> driverThreadLocal = new ThreadLocal<>();
    private static final AppiumConfig config = AppiumConfig.getInstance();

    private DriverManager() {}

    /**
     * Initialize and return a new AndroidDriver using UiAutomator2.
     */
    public static AndroidDriver initializeDriver() {
        try {
            UiAutomator2Options options = buildOptions();
            String appiumUrl = config.getAppiumServerUrl() + "/";
            logger.info("Connecting to Appium at: {}", appiumUrl);
            logger.info("Device: {} | Package: {}", config.getDeviceName(), config.getAppPackage());

            AndroidDriver driver = new AndroidDriver(new URL(appiumUrl), options);
            driver.manage().timeouts().implicitlyWait(Duration.ofSeconds(config.getImplicitWait()));

            driverThreadLocal.set(driver);
            logger.info("AndroidDriver initialized successfully. Session ID: {}", driver.getSessionId());
            return driver;
        } catch (Exception e) {
            logger.error("Failed to initialize AndroidDriver: {}", e.getMessage(), e);
            throw new RuntimeException("Driver initialization failed: " + e.getMessage(), e);
        }
    }

    private static UiAutomator2Options buildOptions() {
        UiAutomator2Options options = new UiAutomator2Options();

        // Platform
        options.setPlatformName("Android");
        options.setAutomationName("UiAutomator2");
        options.setDeviceName(config.getDeviceName());
        options.setPlatformVersion(config.getAndroidVersion());
        options.setUdid(config.getUdid());

        // App
        String apkPath = config.getApkPath();
        File apkFile = new File(apkPath);
        if (apkFile.exists()) {
            options.setApp(apkFile.getAbsolutePath());
            logger.info("Using APK from: {}", apkFile.getAbsolutePath());
        } else {
            // Use package + activity if APK not found (app already installed)
            options.setAppPackage(config.getAppPackage());
            options.setAppActivity(config.getAppActivity());
            logger.info("APK not found, using app package: {}", config.getAppPackage());
        }

        // Behavior
        options.setNoReset(false);
        options.setFullReset(false);
        options.setAutoGrantPermissions(true);

        // Performance
        options.setNewCommandTimeout(Duration.ofSeconds(300));
        options.setAdbExecTimeout(Duration.ofMillis(60000));

        // UiAutomator2 specific
        options.setSkipServerInstallation(false);
        options.setSkipDeviceInitialization(false);
        options.setIgnoreHiddenApiPolicyError(true);
        options.setDisableWindowAnimation(true);

        return options;
    }

    /**
     * Get the current thread's driver.
     */
    public static AndroidDriver getDriver() {
        AndroidDriver driver = driverThreadLocal.get();
        if (driver == null) {
            throw new IllegalStateException("Driver not initialized for thread: " + Thread.currentThread().getName());
        }
        return driver;
    }

    /**
     * Quit and clean up the current thread's driver.
     */
    public static void quitDriver() {
        AndroidDriver driver = driverThreadLocal.get();
        if (driver != null) {
            try {
                driver.quit();
                logger.info("Driver quit successfully");
            } catch (Exception e) {
                logger.warn("Error quitting driver: {}", e.getMessage());
            } finally {
                driverThreadLocal.remove();
            }
        }
    }

    /**
     * Check if a driver is active for the current thread.
     */
    public static boolean isDriverActive() {
        AndroidDriver driver = driverThreadLocal.get();
        if (driver == null) return false;
        try {
            driver.getSessionId();
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}
