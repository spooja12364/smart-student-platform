package com.smartstudent.tests;

import com.smartstudent.config.AppiumConfig;
import com.smartstudent.drivers.DriverManager;
import com.smartstudent.listeners.RetryAnalyzer;
import com.smartstudent.listeners.TestListener;
import com.smartstudent.pages.LoginPage;
import com.smartstudent.reports.ExcelReportGenerator;
import com.smartstudent.reports.ExtentReportManager;
import com.smartstudent.reports.HTMLReportGenerator;
import com.smartstudent.reports.TestResultCollector;
import com.smartstudent.utils.ScreenshotUtils;
import com.smartstudent.utils.WaitUtils;
import io.appium.java_client.android.AndroidDriver;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.testng.ITestResult;
import org.testng.annotations.*;

/**
 * Base test class – all test classes must extend this.
 * Handles driver lifecycle, suite-level reporting, and cleanup.
 */
@Listeners({TestListener.class})
public abstract class BaseTest {

    protected final Logger logger = LogManager.getLogger(getClass());
    protected AndroidDriver driver;
    protected WaitUtils waitUtils;
    protected ScreenshotUtils screenshotUtils;
    protected LoginPage loginPage;
    protected final AppiumConfig config = AppiumConfig.getInstance();

    // ── Suite Hooks ───────────────────────────────────────────────

    @BeforeSuite(alwaysRun = true)
    public void beforeSuite() {
        logger.info("============================================================");
        logger.info("   SMART STUDENT PLATFORM - APPIUM E2E AUTOMATION SUITE");
        logger.info("============================================================");
        TestResultCollector.markSuiteStart();
        ExtentReportManager.reset();
        ExtentReportManager.getInstance();
    }

    @AfterSuite(alwaysRun = true)
    public void afterSuite() {
        TestResultCollector.markSuiteEnd();
        generateReports();
        logger.info("============================================================");
        logger.info("   SUITE COMPLETE | Pass: {} | Fail: {} | Skip: {} | Pass%: {:.1f}%",
                TestResultCollector.getPassedCount(),
                TestResultCollector.getFailedCount(),
                TestResultCollector.getSkippedCount(),
                TestResultCollector.getPassPercentage());
        logger.info("============================================================");
    }

    // ── Test Hooks ────────────────────────────────────────────────

    @BeforeMethod(alwaysRun = true)
    public void setUp() {
        try {
            driver = DriverManager.initializeDriver();
            waitUtils = new WaitUtils(driver);
            screenshotUtils = new ScreenshotUtils(driver);
            loginPage = new LoginPage();
            logger.info("Driver ready. Session: {}", driver.getSessionId());
        } catch (Exception e) {
            logger.error("Driver initialization failed: {}", e.getMessage(), e);
            throw new RuntimeException("Setup failed", e);
        }
    }

    @AfterMethod(alwaysRun = true)
    public void tearDown(ITestResult result) {
        try {
            if (result.getStatus() == ITestResult.FAILURE && DriverManager.isDriverActive()) {
                screenshotUtils.captureFailure(result.getMethod().getMethodName());
            }
        } catch (Exception e) {
            logger.warn("Error in teardown cleanup: {}", e.getMessage());
        } finally {
            DriverManager.quitDriver();
        }
    }

    // ── Helpers ───────────────────────────────────────────────────

    protected LoginPage navigateToLoginPage() {
        try {
            driver.activateApp(config.getAppPackage());
        } catch (Exception ignored) {}
        return new LoginPage();
    }

    protected void generateReports() {
        try {
            logger.info("Generating Excel reports...");
            new ExcelReportGenerator().generateAllReports();
            logger.info("Generating HTML/JSON/MD reports...");
            new HTMLReportGenerator().generateAllReports();
            ExtentReportManager.getInstance().flushReports();
            logger.info("All reports generated successfully");
        } catch (Exception e) {
            logger.error("Report generation error: {}", e.getMessage(), e);
        }
    }

    protected void sleep(int ms) {
        try { Thread.sleep(ms); } catch (InterruptedException e) { Thread.currentThread().interrupt(); }
    }
}
