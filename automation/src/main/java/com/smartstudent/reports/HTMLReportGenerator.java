package com.smartstudent.reports;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.smartstudent.config.AppiumConfig;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Generates JSON, HTML dashboard, and Markdown summary reports.
 */
public class HTMLReportGenerator {

    private static final Logger logger = LogManager.getLogger(HTMLReportGenerator.class);
    private static final AppiumConfig config = AppiumConfig.getInstance();
    private static final ObjectMapper mapper = new ObjectMapper()
            .enable(SerializationFeature.INDENT_OUTPUT);

    public void generateAllReports() {
        try {
            String reportsDir = config.getReportsDir();
            String htmlDir    = reportsDir + File.separator + "HTML";
            String jsonDir    = reportsDir + File.separator + "JSON";
            String summaryDir = reportsDir + File.separator + "Summary";

            Files.createDirectories(Paths.get(htmlDir));
            Files.createDirectories(Paths.get(jsonDir));
            Files.createDirectories(Paths.get(summaryDir));

            generateDashboardHTML(htmlDir);
            generateTrendsHTML(htmlDir);
            generateJSON(jsonDir);
            generateMarkdownSummary(summaryDir);

            logger.info("All HTML/JSON/MD reports generated in: {}", reportsDir);
        } catch (IOException e) {
            logger.error("Report generation failed: {}", e.getMessage(), e);
        }
    }

    // ── Dashboard HTML ────────────────────────────────────────────

    private void generateDashboardHTML(String dir) throws IOException {
        String path = dir + File.separator + "dashboard.html";
        int total   = TestResultCollector.getTotalCount();
        int passed  = TestResultCollector.getPassedCount();
        int failed  = TestResultCollector.getFailedCount();
        int skipped = TestResultCollector.getSkippedCount();
        double passRate = TestResultCollector.getPassPercentage();
        String duration = TestResultCollector.getFormattedDuration();
        String ts = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        String buildNum = System.getenv().getOrDefault("GITHUB_RUN_NUMBER", "local");
        String branch = System.getenv().getOrDefault("GITHUB_REF_NAME", "local");
        String commit = System.getenv().getOrDefault("GITHUB_SHA", "N/A");
        if (commit.length() > 8) commit = commit.substring(0, 8);

        StringBuilder failedRows = new StringBuilder();
        for (TestResultCollector.TestResult r : TestResultCollector.getFailedResults()) {
            failedRows.append("<tr>")
                .append("<td>").append(esc(r.getTestId())).append("</td>")
                .append("<td>").append(esc(r.getModule())).append("</td>")
                .append("<td>").append(esc(r.getTestName())).append("</td>")
                .append("<td><span class='badge badge-fail'>FAILED</span></td>")
                .append("<td>").append(esc(safeStr(r.getFailureReason()))).append("</td>")
                .append("</tr>\n");
        }

        StringBuilder moduleRows = new StringBuilder();
        TestResultCollector.getResultsByModule().forEach((mod, tests) -> {
            long p = tests.stream().filter(t -> "PASSED".equals(t.getStatus())).count();
            long f = tests.stream().filter(t -> "FAILED".equals(t.getStatus())).count();
            double rate = tests.isEmpty() ? 0 : (p * 100.0 / tests.size());
            String cls = rate >= 90 ? "badge-pass" : rate >= 70 ? "badge-skip" : "badge-fail";
            moduleRows.append("<tr>")
                .append("<td>").append(esc(mod)).append("</td>")
                .append("<td>").append(tests.size()).append("</td>")
                .append("<td>").append(p).append("</td>")
                .append("<td>").append(f).append("</td>")
                .append("<td><span class='badge ").append(cls).append("'>")
                .append(String.format("%.1f%%", rate)).append("</span></td>")
                .append("</tr>\n");
        });

        String html = "<!DOCTYPE html>\n<html lang='en'>\n<head>\n"
            + "<meta charset='UTF-8'>\n"
            + "<meta name='viewport' content='width=device-width,initial-scale=1'>\n"
            + "<title>Smart Student Platform - Test Dashboard</title>\n"
            + "<style>\n" + getDashboardCSS() + "\n</style>\n"
            + "</head>\n<body>\n"
            + "<div class='header'>\n"
            + "  <h1>🤖 Smart Student Platform</h1>\n"
            + "  <h2>Appium E2E Test Execution Dashboard</h2>\n"
            + "  <div class='meta'>Build #" + buildNum + " | Branch: " + branch
            + " | Commit: " + commit + " | " + ts + "</div>\n"
            + "</div>\n"
            + "<div class='container'>\n"
            + "  <div class='cards'>\n"
            + "    <div class='card card-total'><div class='card-num'>" + total + "</div><div class='card-label'>Total Tests</div></div>\n"
            + "    <div class='card card-pass'><div class='card-num'>" + passed + "</div><div class='card-label'>Passed</div></div>\n"
            + "    <div class='card card-fail'><div class='card-num'>" + failed + "</div><div class='card-label'>Failed</div></div>\n"
            + "    <div class='card card-skip'><div class='card-num'>" + skipped + "</div><div class='card-label'>Skipped</div></div>\n"
            + "    <div class='card card-rate'><div class='card-num'>" + String.format("%.1f%%", passRate) + "</div><div class='card-label'>Pass Rate</div></div>\n"
            + "    <div class='card card-time'><div class='card-num'>" + duration + "</div><div class='card-label'>Duration</div></div>\n"
            + "  </div>\n"
            + "  <div class='section'>\n"
            + "    <h3>📱 Device & App Information</h3>\n"
            + "    <table class='info-table'>\n"
            + "      <tr><td>Device</td><td>" + config.getDeviceName() + "</td></tr>\n"
            + "      <tr><td>Android Version</td><td>" + config.getAndroidVersion() + "</td></tr>\n"
            + "      <tr><td>App Package</td><td>" + config.getAppPackage() + "</td></tr>\n"
            + "      <tr><td>App Version</td><td>" + config.getAppVersion() + "</td></tr>\n"
            + "      <tr><td>Appium Server</td><td>" + config.getAppiumServerUrl() + "</td></tr>\n"
            + "    </table>\n"
            + "  </div>\n"
            + "  <div class='section'>\n"
            + "    <h3>📊 Results by Module</h3>\n"
            + "    <table><thead><tr><th>Module</th><th>Total</th><th>Passed</th><th>Failed</th><th>Pass Rate</th></tr></thead>\n"
            + "    <tbody>" + moduleRows + "</tbody></table>\n"
            + "  </div>\n"
            + "  <div class='section'>\n"
            + "    <h3>❌ Failed Tests</h3>\n"
            + (failed == 0 ? "<div class='no-failures'>🎉 No failures! All tests passed.</div>\n" :
               "<table><thead><tr><th>Test ID</th><th>Module</th><th>Test Name</th><th>Status</th><th>Failure Reason</th></tr></thead>\n"
            + "    <tbody>" + failedRows + "</tbody></table>\n")
            + "  </div>\n"
            + "</div>\n"
            + "<footer><p>Generated by Smart Student Appium Framework | " + ts + "</p>"
            + "<p><a href='execution-report.html'>📋 Full Execution Report</a> | "
            + "<a href='../JSON/execution-results.json'>📄 JSON Report</a></p></footer>\n"
            + "</body>\n</html>";

        writeFile(path, html);
        logger.info("Dashboard HTML: {}", path);
    }

    // ── Trends HTML ───────────────────────────────────────────────

    private void generateTrendsHTML(String dir) throws IOException {
        String path = dir + File.separator + "trends.html";
        String html = "<!DOCTYPE html>\n<html lang='en'>\n<head>\n"
            + "<meta charset='UTF-8'>\n"
            + "<title>Execution Trends</title>\n"
            + "<style>" + getDashboardCSS() + "</style>\n"
            + "<script src='https://cdn.jsdelivr.net/npm/chart.js'></script>\n"
            + "</head>\n<body>\n"
            + "<div class='header'><h1>📈 Execution Trends</h1></div>\n"
            + "<div class='container'>\n"
            + "  <div class='section'><canvas id='trendChart' height='100'></canvas></div>\n"
            + "  <div class='section'><canvas id='pieChart' height='100'></canvas></div>\n"
            + "</div>\n"
            + "<script>\n"
            + "const ctx1 = document.getElementById('trendChart').getContext('2d');\n"
            + "new Chart(ctx1, { type: 'bar', data: {\n"
            + "  labels: ['Current Run'],\n"
            + "  datasets: [\n"
            + "    { label: 'Passed', data: [" + TestResultCollector.getPassedCount() + "], backgroundColor: '#27AE60' },\n"
            + "    { label: 'Failed', data: [" + TestResultCollector.getFailedCount() + "], backgroundColor: '#E74C3C' },\n"
            + "    { label: 'Skipped', data: [" + TestResultCollector.getSkippedCount() + "], backgroundColor: '#F39C12' }\n"
            + "  ]}, options: { responsive: true, plugins: { title: { display: true, text: 'Test Results' }}}});\n"
            + "const ctx2 = document.getElementById('pieChart').getContext('2d');\n"
            + "new Chart(ctx2, { type: 'doughnut', data: {\n"
            + "  labels: ['Passed', 'Failed', 'Skipped'],\n"
            + "  datasets: [{ data: ["
            + TestResultCollector.getPassedCount() + ", "
            + TestResultCollector.getFailedCount() + ", "
            + TestResultCollector.getSkippedCount()
            + "], backgroundColor: ['#27AE60','#E74C3C','#F39C12']}]\n"
            + "}, options: { responsive: true, plugins: { title: { display: true, text: 'Pass/Fail Distribution' }}}});\n"
            + "</script>\n</body>\n</html>";

        writeFile(path, html);
    }

    // ── JSON Report ───────────────────────────────────────────────

    private void generateJSON(String dir) throws IOException {
        String path = dir + File.separator + "execution-results.json";

        Map<String, Object> report = new LinkedHashMap<>();
        report.put("reportMetadata", Map.of(
            "generatedAt", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME),
            "buildNumber", System.getenv().getOrDefault("GITHUB_RUN_NUMBER", "local"),
            "branch", System.getenv().getOrDefault("GITHUB_REF_NAME", "local"),
            "commitSha", System.getenv().getOrDefault("GITHUB_SHA", "N/A")
        ));
        report.put("deviceInfo", Map.of(
            "deviceName", config.getDeviceName(),
            "androidVersion", config.getAndroidVersion(),
            "appPackage", config.getAppPackage(),
            "appVersion", config.getAppVersion()
        ));
        report.put("summary", Map.of(
            "total", TestResultCollector.getTotalCount(),
            "passed", TestResultCollector.getPassedCount(),
            "failed", TestResultCollector.getFailedCount(),
            "skipped", TestResultCollector.getSkippedCount(),
            "blocked", TestResultCollector.getBlockedCount(),
            "passPercentage", TestResultCollector.getPassPercentage(),
            "failPercentage", TestResultCollector.getFailPercentage(),
            "durationMs", TestResultCollector.getTotalDurationMs(),
            "durationFormatted", TestResultCollector.getFormattedDuration()
        ));
        report.put("results", TestResultCollector.getAllResults());

        mapper.writeValue(new File(path), report);
        logger.info("JSON report: {}", path);
    }

    // ── Markdown Summary ──────────────────────────────────────────

    private void generateMarkdownSummary(String dir) throws IOException {
        String path = dir + File.separator + "summary.md";
        String ts = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        String buildNum = System.getenv().getOrDefault("GITHUB_RUN_NUMBER", "local");
        String branch   = System.getenv().getOrDefault("GITHUB_REF_NAME", "local");
        String commit   = System.getenv().getOrDefault("GITHUB_SHA", "N/A");

        StringBuilder md = new StringBuilder();
        md.append("# 🤖 Android Appium E2E Execution Summary\n\n");
        md.append("| Field | Value |\n|---|---|\n");
        md.append("| Build Number | #").append(buildNum).append(" |\n");
        md.append("| Execution Date | ").append(ts).append(" |\n");
        md.append("| Git Commit | `").append(commit, 0, Math.min(commit.length(), 8)).append("` |\n");
        md.append("| Branch | `").append(branch).append("` |\n");
        md.append("| Device | ").append(config.getDeviceName()).append(" |\n");
        md.append("| Android Version | ").append(config.getAndroidVersion()).append(" |\n");
        md.append("| App Version | ").append(config.getAppVersion()).append(" |\n\n");

        md.append("## 📊 Execution Metrics\n\n");
        md.append("| Metric | Count |\n|---|---|\n");
        md.append("| 🔢 Total Test Cases | **").append(TestResultCollector.getTotalCount()).append("** |\n");
        md.append("| ✅ Passed | **").append(TestResultCollector.getPassedCount()).append("** |\n");
        md.append("| ❌ Failed | **").append(TestResultCollector.getFailedCount()).append("** |\n");
        md.append("| ⏭️ Skipped | **").append(TestResultCollector.getSkippedCount()).append("** |\n");
        md.append("| 🚫 Blocked | **").append(TestResultCollector.getBlockedCount()).append("** |\n");
        md.append("| 📈 Pass % | **").append(String.format("%.2f%%", TestResultCollector.getPassPercentage())).append("** |\n");
        md.append("| 📉 Fail % | **").append(String.format("%.2f%%", TestResultCollector.getFailPercentage())).append("** |\n");
        md.append("| ⏱️ Duration | **").append(TestResultCollector.getFormattedDuration()).append("** |\n\n");

        if (!TestResultCollector.getPassedResults().isEmpty()) {
            md.append("## ✅ Passed Tests\n\n");
            TestResultCollector.getPassedResults().forEach(r ->
                md.append("- ✓ `").append(r.getTestId()).append("` — ").append(r.getTestName()).append("\n"));
            md.append("\n");
        }

        if (!TestResultCollector.getFailedResults().isEmpty()) {
            md.append("## ❌ Failed Tests\n\n");
            TestResultCollector.getFailedResults().forEach(r -> {
                md.append("- ✗ `").append(r.getTestId()).append("` — ").append(r.getTestName()).append("\n");
                md.append("  - **Reason:** ").append(safeStr(r.getFailureReason())).append("\n");
            });
            md.append("\n");
        }

        if (!TestResultCollector.getSkippedResults().isEmpty()) {
            md.append("## ⏭️ Skipped Tests\n\n");
            TestResultCollector.getSkippedResults().forEach(r ->
                md.append("- ⊘ `").append(r.getTestId()).append("` — ").append(r.getTestName())
                  .append(" *(").append(safeStr(r.getFailureReason())).append(")*\n"));
            md.append("\n");
        }

        md.append("---\n*Generated by Smart Student Appium Framework*\n");

        writeFile(path, md.toString());
        logger.info("Markdown summary: {}", path);
    }

    // ── CSS ───────────────────────────────────────────────────────

    private String getDashboardCSS() {
        return "* { margin: 0; padding: 0; box-sizing: border-box; }\n"
            + "body { font-family: 'Segoe UI', sans-serif; background: #0f1117; color: #e0e0e0; }\n"
            + ".header { background: linear-gradient(135deg, #1a237e, #283593); padding: 30px; text-align: center; }\n"
            + ".header h1 { font-size: 2em; color: #fff; }\n"
            + ".header h2 { font-size: 1.2em; color: #90caf9; margin: 8px 0; }\n"
            + ".meta { color: #b0bec5; font-size: 0.85em; margin-top: 8px; }\n"
            + ".container { max-width: 1200px; margin: 30px auto; padding: 0 20px; }\n"
            + ".cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 16px; margin-bottom: 30px; }\n"
            + ".card { padding: 20px; border-radius: 12px; text-align: center; box-shadow: 0 4px 15px rgba(0,0,0,0.3); }\n"
            + ".card-num { font-size: 2.5em; font-weight: 700; }\n"
            + ".card-label { font-size: 0.85em; margin-top: 6px; opacity: 0.8; }\n"
            + ".card-total { background: linear-gradient(135deg, #1565C0, #1976D2); }\n"
            + ".card-pass  { background: linear-gradient(135deg, #1B5E20, #27AE60); }\n"
            + ".card-fail  { background: linear-gradient(135deg, #B71C1C, #E74C3C); }\n"
            + ".card-skip  { background: linear-gradient(135deg, #E65100, #F39C12); }\n"
            + ".card-rate  { background: linear-gradient(135deg, #4A148C, #7B1FA2); }\n"
            + ".card-time  { background: linear-gradient(135deg, #006064, #00838F); }\n"
            + ".section { background: #1a1d27; border-radius: 12px; padding: 24px; margin-bottom: 24px; }\n"
            + ".section h3 { color: #90caf9; margin-bottom: 16px; font-size: 1.1em; }\n"
            + "table { width: 100%; border-collapse: collapse; }\n"
            + "th { background: #283593; color: #fff; padding: 10px 14px; text-align: left; }\n"
            + "td { padding: 9px 14px; border-bottom: 1px solid #2a2d3a; }\n"
            + "tr:hover td { background: #252839; }\n"
            + ".badge { padding: 3px 10px; border-radius: 12px; font-size: 0.8em; font-weight: 600; }\n"
            + ".badge-pass { background: #27AE60; color: #fff; }\n"
            + ".badge-fail { background: #E74C3C; color: #fff; }\n"
            + ".badge-skip { background: #F39C12; color: #fff; }\n"
            + ".info-table td:first-child { color: #90caf9; font-weight: 600; width: 200px; }\n"
            + ".no-failures { color: #27AE60; font-size: 1.1em; padding: 20px; text-align: center; }\n"
            + "footer { text-align: center; padding: 24px; color: #607d8b; font-size: 0.85em; }\n"
            + "footer a { color: #90caf9; text-decoration: none; }\n"
            + "footer a:hover { text-decoration: underline; }\n";
    }

    // ── Helpers ───────────────────────────────────────────────────

    private void writeFile(String path, String content) throws IOException {
        try (FileWriter fw = new FileWriter(path)) {
            fw.write(content);
        }
    }

    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
    }

    private String safeStr(String s) { return s != null ? s : ""; }
}
