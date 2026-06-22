package com.smartstudent.reports;

import lombok.Builder;
import lombok.Data;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Thread-safe collector for all test results during a run.
 * Used by report generators after execution completes.
 */
public class TestResultCollector {

    private static final Logger logger = LogManager.getLogger(TestResultCollector.class);
    private static final List<TestResult> results = Collections.synchronizedList(new ArrayList<>());
    private static long suiteStartTime = System.currentTimeMillis();
    private static long suiteEndTime;

    @Data
    @Builder
    public static class TestResult {
        private String testId;
        private String module;
        private String testName;
        private String priority;
        private String status;          // PASSED / FAILED / SKIPPED / BLOCKED
        private String failureReason;
        private String screenshotPath;
        private String stackTrace;
        private long durationMs;
        private String preconditions;
        private String testSteps;
        private String expectedResult;
        private String actualResult;
    }

    // ── Mutation ──────────────────────────────────────────────────

    public static void addResult(TestResult result) {
        results.add(result);
        logger.debug("Result recorded: {} - {}", result.getTestId(), result.getStatus());
    }

    public static void markSuiteStart() {
        suiteStartTime = System.currentTimeMillis();
        results.clear();
    }

    public static void markSuiteEnd() {
        suiteEndTime = System.currentTimeMillis();
    }

    // ── Queries ───────────────────────────────────────────────────

    public static List<TestResult> getAllResults() {
        return new ArrayList<>(results);
    }

    public static List<TestResult> getPassedResults() {
        return results.stream()
                .filter(r -> "PASSED".equalsIgnoreCase(r.getStatus()))
                .collect(Collectors.toList());
    }

    public static List<TestResult> getFailedResults() {
        return results.stream()
                .filter(r -> "FAILED".equalsIgnoreCase(r.getStatus()))
                .collect(Collectors.toList());
    }

    public static List<TestResult> getSkippedResults() {
        return results.stream()
                .filter(r -> "SKIPPED".equalsIgnoreCase(r.getStatus()))
                .collect(Collectors.toList());
    }

    public static List<TestResult> getBlockedResults() {
        return results.stream()
                .filter(r -> "BLOCKED".equalsIgnoreCase(r.getStatus()))
                .collect(Collectors.toList());
    }

    public static Map<String, List<TestResult>> getResultsByModule() {
        return results.stream().collect(Collectors.groupingBy(TestResult::getModule));
    }

    // ── Metrics ───────────────────────────────────────────────────

    public static int getTotalCount()   { return results.size(); }
    public static int getPassedCount()  { return getPassedResults().size(); }
    public static int getFailedCount()  { return getFailedResults().size(); }
    public static int getSkippedCount() { return getSkippedResults().size(); }
    public static int getBlockedCount() { return getBlockedResults().size(); }

    public static double getPassPercentage() {
        int total = getTotalCount();
        return total == 0 ? 0.0 : (getPassedCount() * 100.0) / total;
    }

    public static double getFailPercentage() {
        int total = getTotalCount();
        return total == 0 ? 0.0 : (getFailedCount() * 100.0) / total;
    }

    public static long getTotalDurationMs() {
        if (suiteEndTime > 0) return suiteEndTime - suiteStartTime;
        return results.stream().mapToLong(TestResult::getDurationMs).sum();
    }

    public static String getFormattedDuration() {
        long ms = getTotalDurationMs();
        long minutes = ms / 60000;
        long seconds = (ms % 60000) / 1000;
        return String.format("%dm %ds", minutes, seconds);
    }

    public static long getSuiteStartTime()  { return suiteStartTime; }
    public static long getSuiteEndTime()    { return suiteEndTime; }
}
