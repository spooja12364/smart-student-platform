package com.smartstudent.reports;

import com.aventstack.extentreports.ExtentReports;
import com.aventstack.extentreports.ExtentTest;
import com.aventstack.extentreports.MediaEntityBuilder;
import com.aventstack.extentreports.Status;
import com.aventstack.extentreports.reporter.ExtentSparkReporter;
import com.aventstack.extentreports.reporter.configuration.Theme;
import com.smartstudent.config.AppiumConfig;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

/**
 * Singleton ExtentReports manager.
 * Produces a rich HTML execution report via ExtentSparkReporter.
 */
public class ExtentReportManager {

    private static final Logger logger = LogManager.getLogger(ExtentReportManager.class);
    private static ExtentReportManager instance;

    private ExtentReports extent;
    private final Map<String, ExtentTest> testMap = new HashMap<>();
    private final AppiumConfig config = AppiumConfig.getInstance();
    private String reportPath;

    private ExtentReportManager() {
        initializeReport();
    }

    public static synchronized ExtentReportManager getInstance() {
        if (instance == null) {
            instance = new ExtentReportManager();
        }
        return instance;
    }

    private void initializeReport() {
        try {
            String htmlDir = config.getReportsDir() + File.separator + "HTML";
            Files.createDirectories(Paths.get(htmlDir));

            reportPath = htmlDir + File.separator + "execution-report.html";
            ExtentSparkReporter spark = new ExtentSparkReporter(reportPath);

            // Styling
            spark.config().setTheme(Theme.DARK);
            spark.config().setDocumentTitle("Smart Student Platform - E2E Test Report");
            spark.config().setReportName("Appium Automation Execution Report");
            spark.config().setTimelineEnabled(true);
            spark.config().setEncoding("utf-8");

            extent = new ExtentReports();
            extent.attachReporter(spark);

            // System info
            extent.setSystemInfo("Application", "Smart Student Platform");
            extent.setSystemInfo("Platform", config.getPlatform());
            extent.setSystemInfo("Device", config.getDeviceName());
            extent.setSystemInfo("Android Version", config.getAndroidVersion());
            extent.setSystemInfo("App Package", config.getAppPackage());
            extent.setSystemInfo("App Version", config.getAppVersion());
            extent.setSystemInfo("Appium Server", config.getAppiumServerUrl());
            extent.setSystemInfo("Execution Date",
                    LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
            extent.setSystemInfo("Build Number", System.getenv().getOrDefault("GITHUB_RUN_NUMBER", "local"));
            extent.setSystemInfo("Branch", System.getenv().getOrDefault("GITHUB_REF_NAME", "local"));
            extent.setSystemInfo("Commit", System.getenv().getOrDefault("GITHUB_SHA", "N/A"));

            logger.info("ExtentReports initialized. Report path: {}", reportPath);
        } catch (Exception e) {
            logger.error("Failed to initialize ExtentReports: {}", e.getMessage(), e);
        }
    }

    public void startSuite(String suiteName) {
        logger.debug("Suite started: {}", suiteName);
    }

    public synchronized void startTest(String testName, String description) {
        ExtentTest test = extent.createTest(testName, description);
        testMap.put(Thread.currentThread().getName() + "_" + testName, test);
    }

    public synchronized void passTest(String testName, String message) {
        ExtentTest test = getCurrentTest(testName);
        if (test != null) test.pass(message);
    }

    public synchronized void failTest(String testName, String reason, Throwable throwable, String screenshotPath) {
        ExtentTest test = getCurrentTest(testName);
        if (test == null) return;

        if (screenshotPath != null && new File(screenshotPath).exists()) {
            try {
                test.fail("Test failed: " + reason,
                        MediaEntityBuilder.createScreenCaptureFromPath(screenshotPath).build());
            } catch (Exception e) {
                test.fail("Test failed: " + reason);
            }
        } else {
            test.fail("Test failed: " + reason);
        }

        if (throwable != null) {
            test.fail(throwable);
        }
    }

    public synchronized void skipTest(String testName, String reason) {
        ExtentTest test = getCurrentTest(testName);
        if (test != null) test.skip(reason);
    }

    public synchronized void logInfo(String testName, String message) {
        ExtentTest test = getCurrentTest(testName);
        if (test != null) test.info(message);
    }

    public synchronized void logStep(String testName, String step) {
        ExtentTest test = getCurrentTest(testName);
        if (test != null) test.log(Status.INFO, "STEP: " + step);
    }

    private ExtentTest getCurrentTest(String testName) {
        // First try thread-specific key, then fallback to testName only
        String key = Thread.currentThread().getName() + "_" + testName;
        ExtentTest test = testMap.get(key);
        if (test == null) {
            // Try to find by suffix
            for (Map.Entry<String, ExtentTest> entry : testMap.entrySet()) {
                if (entry.getKey().endsWith("_" + testName)) return entry.getValue();
            }
        }
        return test;
    }

    public synchronized void flushReports() {
        if (extent != null) {
            extent.flush();
            logger.info("Extent report flushed to: {}", reportPath);
        }
    }

    public String getReportPath() {
        return reportPath;
    }

    // Force re-initialization (for new test run)
    public static synchronized void reset() {
        instance = null;
    }
}
