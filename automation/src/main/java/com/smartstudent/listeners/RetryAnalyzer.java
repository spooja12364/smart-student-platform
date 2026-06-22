package com.smartstudent.listeners;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.testng.IRetryAnalyzer;
import org.testng.ITestResult;

/**
 * Retry analyzer: retries failed tests up to MAX_RETRY_COUNT times.
 * Configured via system property 'retryCount' (default = 2).
 */
public class RetryAnalyzer implements IRetryAnalyzer {

    private static final Logger logger = LogManager.getLogger(RetryAnalyzer.class);
    private int retryCount = 0;
    private static final int MAX_RETRY_COUNT;

    static {
        String retryProp = System.getProperty("retryCount", "2");
        int parsed = 2;
        try { parsed = Integer.parseInt(retryProp); } catch (NumberFormatException ignored) {}
        MAX_RETRY_COUNT = parsed;
    }

    @Override
    public boolean retry(ITestResult result) {
        if (!result.isSuccess() && retryCount < MAX_RETRY_COUNT) {
            retryCount++;
            logger.warn("↺ RETRYING test '{}' — attempt {}/{}",
                    result.getMethod().getMethodName(), retryCount, MAX_RETRY_COUNT);
            return true;
        }
        return false;
    }
}
