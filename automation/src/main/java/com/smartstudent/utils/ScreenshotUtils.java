package com.smartstudent.utils;

import com.smartstudent.config.AppiumConfig;
import io.appium.java_client.android.AndroidDriver;
import org.apache.commons.io.FileUtils;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.openqa.selenium.OutputType;
import org.openqa.selenium.TakesScreenshot;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

/**
 * Screenshot capture utility.
 * Saves screenshots to the configured directory and returns the file path.
 */
public class ScreenshotUtils {

    private static final Logger logger = LogManager.getLogger(ScreenshotUtils.class);
    private static final AppiumConfig config = AppiumConfig.getInstance();
    private static final List<String> capturedScreenshots = new ArrayList<>();

    private final AndroidDriver driver;
    private final String screenshotsDir;

    public ScreenshotUtils(AndroidDriver driver) {
        this.driver = driver;
        this.screenshotsDir = config.getScreenshotsDir();
        ensureDirectoryExists(screenshotsDir);
    }

    /**
     * Capture screenshot and save to screenshots directory.
     *
     * @param name  Base name for the screenshot file
     * @return Absolute path of the saved screenshot, or null on failure
     */
    public String capture(String name) {
        try {
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss_SSS"));
            String sanitized = sanitizeFileName(name);
            String fileName = sanitized + "_" + timestamp + ".png";
            String fullPath = screenshotsDir + File.separator + fileName;

            File srcFile = ((TakesScreenshot) driver).getScreenshotAs(OutputType.FILE);
            FileUtils.copyFile(srcFile, new File(fullPath));

            capturedScreenshots.add(fullPath);
            logger.info("Screenshot captured: {}", fullPath);
            return fullPath;
        } catch (IOException e) {
            logger.error("Failed to capture screenshot '{}': {}", name, e.getMessage());
            return null;
        }
    }

    /**
     * Capture screenshot for a failure scenario.
     */
    public String captureFailure(String testName) {
        return capture("FAIL_" + testName);
    }

    /**
     * Capture screenshot at a specific step.
     */
    public String captureStep(String testName, String stepName) {
        return capture(testName + "_STEP_" + stepName);
    }

    /**
     * Get all captured screenshots in this session.
     */
    public static List<String> getAllScreenshots() {
        return new ArrayList<>(capturedScreenshots);
    }

    /**
     * Clear screenshots list (between test runs).
     */
    public static void clearScreenshotsList() {
        capturedScreenshots.clear();
    }

    /**
     * Get screenshot as Base64 string (useful for HTML embedding).
     */
    public String captureAsBase64(String name) {
        try {
            return ((TakesScreenshot) driver).getScreenshotAs(OutputType.BASE64);
        } catch (Exception e) {
            logger.error("Failed to capture screenshot as Base64: {}", e.getMessage());
            return null;
        }
    }

    private String sanitizeFileName(String name) {
        return name.replaceAll("[^a-zA-Z0-9_\\-]", "_")
                   .replaceAll("_+", "_")
                   .substring(0, Math.min(name.length(), 80));
    }

    private void ensureDirectoryExists(String dir) {
        try {
            Files.createDirectories(Paths.get(dir));
        } catch (IOException e) {
            logger.warn("Could not create screenshots directory: {}", e.getMessage());
        }
    }
}
