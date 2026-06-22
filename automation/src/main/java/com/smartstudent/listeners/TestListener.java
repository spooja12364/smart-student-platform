package com.smartstudent.listeners;

import com.smartstudent.drivers.DriverManager;
import com.smartstudent.reports.ExtentReportManager;
import com.smartstudent.reports.TestResultCollector;
import com.smartstudent.utils.ScreenshotUtils;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.testng.ITestContext;
import org.testng.ITestListener;
import org.testng.ITestResult;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * TestNG listener: hooks into pass/fail/skip events to capture
 * screenshots, log results, and feed the report engines.
 */
public class TestListener implements ITestListener {

    private static final Logger logger = LogManager.getLogger(TestListener.class);

    @Override
    public void onStart(ITestContext context) {
        logger.info("═══════════════════════════════════════════════════");
        logger.info("TEST SUITE STARTED: {}", context.getName());
        logger.info("Start Time: {}", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        logger.info("═══════════════════════════════════════════════════");
        ExtentReportManager.getInstance().startSuite(context.getName());
    }

    @Override
    public void onFinish(ITestContext context) {
        logger.info("═══════════════════════════════════════════════════");
        logger.info("TEST SUITE FINISHED: {}", context.getName());
        logger.info("Total: {} | Passed: {} | Failed: {} | Skipped: {}",
                context.getAllTestMethods().length,
                context.getPassedTests().size(),
                context.getFailedTests().size(),
                context.getSkippedTests().size());
        logger.info("═══════════════════════════════════════════════════");
        ExtentReportManager.getInstance().flushReports();
    }

    @Override
    public void onTestStart(ITestResult result) {
        String testName = getTestName(result);
        logger.info("──────────────────────────────────────────────────");
        logger.info("▶ STARTING: {}", testName);
        ExtentReportManager.getInstance().startTest(testName, getTestDescription(result));
    }

    @Override
    public void onTestSuccess(ITestResult result) {
        String testName = getTestName(result);
        long durationMs = result.getEndMillis() - result.getStartMillis();

        logger.info("✅ PASSED: {} ({}ms)", testName, durationMs);
        ExtentReportManager.getInstance().passTest(testName, "Test passed in " + durationMs + "ms");

        TestResultCollector.addResult(TestResultCollector.TestResult.builder()
                .testId(getTestId(result))
                .module(getModule(result))
                .testName(testName)
                .priority(getPriority(result))
                .status("PASSED")
                .durationMs(durationMs)
                .build());
    }

    @Override
    public void onTestFailure(ITestResult result) {
        String testName = getTestName(result);
        long durationMs = result.getEndMillis() - result.getStartMillis();
        String failureReason = result.getThrowable() != null
                ? result.getThrowable().getMessage() : "Unknown failure";

        logger.error("❌ FAILED: {} | Reason: {}", testName, failureReason);

        // Capture screenshot on failure
        String screenshotPath = null;
        try {
            if (DriverManager.isDriverActive()) {
                ScreenshotUtils ss = new ScreenshotUtils(DriverManager.getDriver());
                screenshotPath = ss.captureFailure(testName);
            }
        } catch (Exception e) {
            logger.warn("Could not capture failure screenshot: {}", e.getMessage());
        }

        ExtentReportManager.getInstance().failTest(testName, failureReason,
                result.getThrowable(), screenshotPath);

        TestResultCollector.addResult(TestResultCollector.TestResult.builder()
                .testId(getTestId(result))
                .module(getModule(result))
                .testName(testName)
                .priority(getPriority(result))
                .status("FAILED")
                .failureReason(failureReason)
                .screenshotPath(screenshotPath)
                .durationMs(durationMs)
                .build());
    }

    @Override
    public void onTestSkipped(ITestResult result) {
        String testName = getTestName(result);
        String skipReason = result.getThrowable() != null
                ? result.getThrowable().getMessage() : "Skipped by framework";

        logger.warn("⚠️ SKIPPED: {} | Reason: {}", testName, skipReason);
        ExtentReportManager.getInstance().skipTest(testName, skipReason);

        TestResultCollector.addResult(TestResultCollector.TestResult.builder()
                .testId(getTestId(result))
                .module(getModule(result))
                .testName(testName)
                .priority(getPriority(result))
                .status("SKIPPED")
                .failureReason(skipReason)
                .durationMs(0L)
                .build());
    }

    @Override
    public void onTestFailedButWithinSuccessPercentage(ITestResult result) {
        logger.warn("⚠️ TEST FAILED WITHIN SUCCESS PERCENTAGE: {}", getTestName(result));
    }

    // ── Helpers ───────────────────────────────────────────────────

    private String getTestName(ITestResult result) {
        return result.getTestClass().getRealClass().getSimpleName()
                + "." + result.getMethod().getMethodName();
    }

    private String getTestDescription(ITestResult result) {
        String desc = result.getMethod().getDescription();
        return (desc != null && !desc.isEmpty()) ? desc : result.getMethod().getMethodName();
    }

    private String getTestId(ITestResult result) {
        String method = result.getMethod().getMethodName();
        // Extract ID from method name if it follows convention TC_MODULE_NNN
        if (method.contains("_TC") || method.toUpperCase().startsWith("TC")) return method.toUpperCase();
        return "TC_" + method.toUpperCase();
    }

    private String getModule(ITestResult result) {
        String className = result.getTestClass().getRealClass().getSimpleName();
        // e.g. "AuthenticationTests" → "Authentication"
        return className.replace("Tests", "").replace("Test", "");
    }

    private String getPriority(ITestResult result) {
        // Read from custom annotation if present, default to Medium
        try {
            var priorityAnn = result.getMethod().getConstructorOrMethod()
                    .getMethod().getAnnotation(com.smartstudent.listeners.TestPriority.class);
            return priorityAnn != null ? priorityAnn.value() : "Medium";
        } catch (Exception e) {
            return "Medium";
        }
    }
}
