package com.smartstudent.config;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.yaml.snakeyaml.Yaml;

import java.io.InputStream;
import java.util.Map;
import java.util.Properties;

/**
 * Central configuration manager for Appium test framework.
 * Reads from config.yaml and system properties (CI/CD overrides).
 */
public class AppiumConfig {

    private static final Logger logger = LogManager.getLogger(AppiumConfig.class);
    private static AppiumConfig instance;
    private final Properties props = new Properties();
    private Map<String, Object> yamlConfig;

    private AppiumConfig() {
        loadYamlConfig();
        loadSystemProperties();
        logger.info("AppiumConfig initialized for platform: {}", getPlatform());
    }

    public static synchronized AppiumConfig getInstance() {
        if (instance == null) {
            instance = new AppiumConfig();
        }
        return instance;
    }

    @SuppressWarnings("unchecked")
    private void loadYamlConfig() {
        try {
            Yaml yaml = new Yaml();
            InputStream is = getClass().getClassLoader()
                    .getResourceAsStream("config/config.yaml");
            if (is != null) {
                yamlConfig = yaml.load(is);
                flattenMap("", yamlConfig);
                logger.info("Loaded config.yaml successfully");
            }
        } catch (Exception e) {
            logger.warn("Could not load config.yaml: {}", e.getMessage());
        }
    }

    @SuppressWarnings("unchecked")
    private void flattenMap(String prefix, Map<String, Object> map) {
        for (Map.Entry<String, Object> entry : map.entrySet()) {
            String key = prefix.isEmpty() ? entry.getKey() : prefix + "." + entry.getKey();
            if (entry.getValue() instanceof Map) {
                flattenMap(key, (Map<String, Object>) entry.getValue());
            } else {
                props.setProperty(key, String.valueOf(entry.getValue()));
            }
        }
    }

    private void loadSystemProperties() {
        // System properties override YAML (for CI/CD)
        String[] sysProps = {
            "platform", "deviceName", "appiumHost", "appiumPort",
            "appPackage", "appActivity", "udid", "androidVersion",
            "apkPath", "appiumServerUrl"
        };
        for (String key : sysProps) {
            String val = System.getProperty(key);
            if (val != null && !val.isEmpty()) {
                props.setProperty(key, val);
            }
        }
    }

    public String get(String key) {
        return props.getProperty(key, "");
    }

    public String get(String key, String defaultValue) {
        return props.getProperty(key, defaultValue);
    }

    // ── Appium Server ───────────────────────────────────────────
    public String getAppiumHost() {
        return get("appium.host", "127.0.0.1");
    }

    public int getAppiumPort() {
        return Integer.parseInt(get("appium.port", "4723"));
    }

    public String getAppiumServerUrl() {
        return String.format("http://%s:%d", getAppiumHost(), getAppiumPort());
    }

    // ── Device ──────────────────────────────────────────────────
    public String getPlatform() {
        return get("platform", "Android");
    }

    public String getDeviceName() {
        return get("device.name", "emulator-5554");
    }

    public String getAndroidVersion() {
        return get("device.androidVersion", "14.0");
    }

    public String getUdid() {
        return get("device.udid", "emulator-5554");
    }

    // ── App ─────────────────────────────────────────────────────
    public String getAppPackage() {
        return get("app.package", "com.example.smart_student_platform");
    }

    public String getAppActivity() {
        return get("app.activity", "com.example.smart_student_platform.MainActivity");
    }

    public String getApkPath() {
        return get("app.apkPath", "app/build/outputs/flutter-apk/app-debug.apk");
    }

    public String getAppVersion() {
        return get("app.version", "1.0.0");
    }

    // ── Timeouts ─────────────────────────────────────────────────
    public int getImplicitWait() {
        return Integer.parseInt(get("timeouts.implicitWait", "10"));
    }

    public int getExplicitWait() {
        return Integer.parseInt(get("timeouts.explicitWait", "30"));
    }

    public int getPageLoadTimeout() {
        return Integer.parseInt(get("timeouts.pageLoad", "60"));
    }

    // ── Test Data ────────────────────────────────────────────────
    public String getValidEmail() {
        return get("testData.validEmail", "testuser@smartstudent.com");
    }

    public String getValidPassword() {
        return get("testData.validPassword", "Test@12345");
    }

    // ── Reporting ────────────────────────────────────────────────
    public String getReportsDir() {
        return get("reports.dir", "test-reports");
    }

    public String getScreenshotsDir() {
        return get("reports.screenshots", "test-reports/screenshots");
    }

    public String getLogsDir() {
        return get("reports.logs", "test-reports/logs");
    }

    // ── Parallel / Retry ─────────────────────────────────────────
    public int getThreadCount() {
        return Integer.parseInt(get("execution.threadCount", "1"));
    }

    public int getRetryCount() {
        return Integer.parseInt(get("execution.retryCount", "2"));
    }
}
