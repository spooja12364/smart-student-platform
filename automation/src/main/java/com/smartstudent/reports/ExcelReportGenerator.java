package com.smartstudent.reports;

import com.smartstudent.config.AppiumConfig;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.xssf.usermodel.*;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

/**
 * Generates multi-sheet Excel reports using Apache POI.
 * Sheets: All Tests | Passed | Failed | Skipped | Metrics | Defects | Pass Rate
 */
public class ExcelReportGenerator {

    private static final Logger logger = LogManager.getLogger(ExcelReportGenerator.class);
    private static final AppiumConfig config = AppiumConfig.getInstance();

    // Colour palette (XSSF hex)
    private static final String COLOR_DARK_BLUE  = "1E3A5F";
    private static final String COLOR_GREEN      = "27AE60";
    private static final String COLOR_RED        = "E74C3C";
    private static final String COLOR_YELLOW     = "F39C12";
    private static final String COLOR_LIGHT_GREY = "F2F2F2";
    private static final String COLOR_WHITE      = "FFFFFF";
    private static final String COLOR_HEADER     = "2C3E50";

    public void generateAllReports() {
        try {
            String excelDir = config.getReportsDir() + File.separator + "Excel";
            Files.createDirectories(Paths.get(excelDir));

            generateMainReport(excelDir);
            generatePassedReport(excelDir);
            generateFailedReport(excelDir);
            generateSummaryReport(excelDir);

            logger.info("All Excel reports generated in: {}", excelDir);
        } catch (IOException e) {
            logger.error("Excel report generation failed: {}", e.getMessage(), e);
        }
    }

    // ── Main Report ───────────────────────────────────────────────

    private void generateMainReport(String dir) throws IOException {
        String path = dir + File.separator + "Automation_Test_Report.xlsx";
        try (XSSFWorkbook wb = new XSSFWorkbook()) {
            createAllTestsSheet(wb);
            createPassedSheet(wb);
            createFailedSheet(wb);
            createSkippedSheet(wb);
            createMetricsSheet(wb);
            createDefectSheet(wb);
            createPassRateSheet(wb);
            writeWorkbook(wb, path);
        }
        logger.info("Main report: {}", path);
    }

    private void generatePassedReport(String dir) throws IOException {
        String path = dir + File.separator + "Passed_Test_Cases.xlsx";
        try (XSSFWorkbook wb = new XSSFWorkbook()) {
            createPassedSheet(wb);
            writeWorkbook(wb, path);
        }
    }

    private void generateFailedReport(String dir) throws IOException {
        String path = dir + File.separator + "Failed_Test_Cases.xlsx";
        try (XSSFWorkbook wb = new XSSFWorkbook()) {
            createFailedSheet(wb);
            writeWorkbook(wb, path);
        }
    }

    private void generateSummaryReport(String dir) throws IOException {
        String path = dir + File.separator + "Execution_Summary.xlsx";
        try (XSSFWorkbook wb = new XSSFWorkbook()) {
            createMetricsSheet(wb);
            createPassRateSheet(wb);
            writeWorkbook(wb, path);
        }
    }

    // ── Sheet Builders ────────────────────────────────────────────

    private void createAllTestsSheet(XSSFWorkbook wb) {
        XSSFSheet sheet = wb.createSheet("All Test Cases");
        String[] headers = {"Test ID", "Module", "Test Name", "Priority", "Status",
                            "Duration (ms)", "Failure Reason", "Screenshot"};
        writeSheetHeader(wb, sheet, headers, COLOR_HEADER);

        List<TestResultCollector.TestResult> all = TestResultCollector.getAllResults();
        int row = 1;
        for (TestResultCollector.TestResult r : all) {
            XSSFRow dataRow = sheet.createRow(row++);
            String statusColor = getStatusColor(r.getStatus());
            writeCell(dataRow, 0, r.getTestId(), null, wb);
            writeCell(dataRow, 1, r.getModule(), null, wb);
            writeCell(dataRow, 2, r.getTestName(), null, wb);
            writeCell(dataRow, 3, r.getPriority(), null, wb);
            writeColorCell(dataRow, 4, r.getStatus(), statusColor, wb);
            writeCell(dataRow, 5, String.valueOf(r.getDurationMs()), null, wb);
            writeCell(dataRow, 6, safeStr(r.getFailureReason()), null, wb);
            writeCell(dataRow, 7, safeStr(r.getScreenshotPath()), null, wb);
            styleDataRow(wb, dataRow, row % 2 == 0);
        }
        autoSizeColumns(sheet, headers.length);
        addFilters(sheet, headers.length);
    }

    private void createPassedSheet(XSSFWorkbook wb) {
        XSSFSheet sheet = wb.createSheet("Passed Tests");
        String[] headers = {"Test ID", "Module", "Test Name", "Priority", "Duration (ms)"};
        writeSheetHeader(wb, sheet, headers, COLOR_GREEN);

        int row = 1;
        for (TestResultCollector.TestResult r : TestResultCollector.getPassedResults()) {
            XSSFRow dataRow = sheet.createRow(row++);
            writeCell(dataRow, 0, r.getTestId(), null, wb);
            writeCell(dataRow, 1, r.getModule(), null, wb);
            writeCell(dataRow, 2, r.getTestName(), null, wb);
            writeCell(dataRow, 3, r.getPriority(), null, wb);
            writeCell(dataRow, 4, String.valueOf(r.getDurationMs()), null, wb);
            styleDataRow(wb, dataRow, row % 2 == 0);
        }
        autoSizeColumns(sheet, headers.length);
    }

    private void createFailedSheet(XSSFWorkbook wb) {
        XSSFSheet sheet = wb.createSheet("Failed Tests");
        String[] headers = {"Test ID", "Module", "Test Name", "Priority",
                            "Failure Reason", "Duration (ms)", "Screenshot"};
        writeSheetHeader(wb, sheet, headers, COLOR_RED);

        int row = 1;
        for (TestResultCollector.TestResult r : TestResultCollector.getFailedResults()) {
            XSSFRow dataRow = sheet.createRow(row++);
            writeCell(dataRow, 0, r.getTestId(), null, wb);
            writeCell(dataRow, 1, r.getModule(), null, wb);
            writeCell(dataRow, 2, r.getTestName(), null, wb);
            writeCell(dataRow, 3, r.getPriority(), null, wb);
            writeCell(dataRow, 4, safeStr(r.getFailureReason()), null, wb);
            writeCell(dataRow, 5, String.valueOf(r.getDurationMs()), null, wb);
            writeCell(dataRow, 6, safeStr(r.getScreenshotPath()), null, wb);
            styleDataRow(wb, dataRow, row % 2 == 0);
        }
        autoSizeColumns(sheet, headers.length);
    }

    private void createSkippedSheet(XSSFWorkbook wb) {
        XSSFSheet sheet = wb.createSheet("Skipped Tests");
        String[] headers = {"Test ID", "Module", "Test Name", "Reason"};
        writeSheetHeader(wb, sheet, headers, COLOR_YELLOW);

        int row = 1;
        for (TestResultCollector.TestResult r : TestResultCollector.getSkippedResults()) {
            XSSFRow dataRow = sheet.createRow(row++);
            writeCell(dataRow, 0, r.getTestId(), null, wb);
            writeCell(dataRow, 1, r.getModule(), null, wb);
            writeCell(dataRow, 2, r.getTestName(), null, wb);
            writeCell(dataRow, 3, safeStr(r.getFailureReason()), null, wb);
            styleDataRow(wb, dataRow, row % 2 == 0);
        }
        autoSizeColumns(sheet, headers.length);
    }

    private void createMetricsSheet(XSSFWorkbook wb) {
        XSSFSheet sheet = wb.createSheet("Execution Metrics");
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));

        String[][] metrics = {
            {"Report Generated", timestamp},
            {"Device", config.getDeviceName()},
            {"Android Version", config.getAndroidVersion()},
            {"App Version", config.getAppVersion()},
            {"App Package", config.getAppPackage()},
            {"Build Number", System.getenv().getOrDefault("GITHUB_RUN_NUMBER", "local")},
            {"Branch", System.getenv().getOrDefault("GITHUB_REF_NAME", "local")},
            {"", ""},
            {"Total Tests", String.valueOf(TestResultCollector.getTotalCount())},
            {"Passed", String.valueOf(TestResultCollector.getPassedCount())},
            {"Failed", String.valueOf(TestResultCollector.getFailedCount())},
            {"Skipped", String.valueOf(TestResultCollector.getSkippedCount())},
            {"Blocked", String.valueOf(TestResultCollector.getBlockedCount())},
            {"Pass %", String.format("%.2f%%", TestResultCollector.getPassPercentage())},
            {"Fail %", String.format("%.2f%%", TestResultCollector.getFailPercentage())},
            {"Duration", TestResultCollector.getFormattedDuration()},
        };

        // Title
        XSSFRow titleRow = sheet.createRow(0);
        XSSFCell titleCell = titleRow.createCell(0);
        titleCell.setCellValue("EXECUTION METRICS DASHBOARD");
        titleCell.setCellStyle(createTitleStyle(wb));
        sheet.addMergedRegion(new CellRangeAddress(0, 0, 0, 3));

        int row = 2;
        for (String[] pair : metrics) {
            XSSFRow r = sheet.createRow(row++);
            writeCell(r, 0, pair[0], COLOR_DARK_BLUE, wb);
            writeCell(r, 1, pair[1], null, wb);
        }
        sheet.setColumnWidth(0, 6000);
        sheet.setColumnWidth(1, 6000);
    }

    private void createDefectSheet(XSSFWorkbook wb) {
        XSSFSheet sheet = wb.createSheet("Defect Summary");
        String[] headers = {"Defect #", "Test ID", "Module", "Severity", "Description", "Status"};
        writeSheetHeader(wb, sheet, headers, COLOR_RED);

        int row = 1;
        int defectNum = 1;
        for (TestResultCollector.TestResult r : TestResultCollector.getFailedResults()) {
            XSSFRow dataRow = sheet.createRow(row++);
            writeCell(dataRow, 0, "DEF-" + String.format("%03d", defectNum++), null, wb);
            writeCell(dataRow, 1, r.getTestId(), null, wb);
            writeCell(dataRow, 2, r.getModule(), null, wb);
            writeCell(dataRow, 3, "Critical".equals(r.getPriority()) ? "Critical" : "Major", null, wb);
            writeCell(dataRow, 4, safeStr(r.getFailureReason()), null, wb);
            writeCell(dataRow, 5, "Open", null, wb);
            styleDataRow(wb, dataRow, row % 2 == 0);
        }
        autoSizeColumns(sheet, headers.length);
    }

    private void createPassRateSheet(XSSFWorkbook wb) {
        XSSFSheet sheet = wb.createSheet("Pass Rate by Module");
        String[] headers = {"Module", "Total", "Passed", "Failed", "Skipped", "Pass Rate"};
        writeSheetHeader(wb, sheet, headers, COLOR_DARK_BLUE);

        Map<String, List<TestResultCollector.TestResult>> byModule =
                TestResultCollector.getResultsByModule();

        int row = 1;
        for (Map.Entry<String, List<TestResultCollector.TestResult>> entry : byModule.entrySet()) {
            String module = entry.getKey();
            List<TestResultCollector.TestResult> tests = entry.getValue();
            long passed  = tests.stream().filter(t -> "PASSED".equals(t.getStatus())).count();
            long failed  = tests.stream().filter(t -> "FAILED".equals(t.getStatus())).count();
            long skipped = tests.stream().filter(t -> "SKIPPED".equals(t.getStatus())).count();
            double passRate = tests.isEmpty() ? 0 : (passed * 100.0 / tests.size());

            XSSFRow dataRow = sheet.createRow(row++);
            writeCell(dataRow, 0, module, null, wb);
            writeCell(dataRow, 1, String.valueOf(tests.size()), null, wb);
            writeCell(dataRow, 2, String.valueOf(passed), null, wb);
            writeCell(dataRow, 3, String.valueOf(failed), null, wb);
            writeCell(dataRow, 4, String.valueOf(skipped), null, wb);
            writeColorCell(dataRow, 5, String.format("%.1f%%", passRate),
                    passRate >= 90 ? COLOR_GREEN : passRate >= 70 ? COLOR_YELLOW : COLOR_RED, wb);
            styleDataRow(wb, dataRow, row % 2 == 0);
        }
        autoSizeColumns(sheet, headers.length);
    }

    // ── POI Helpers ───────────────────────────────────────────────

    private void writeSheetHeader(XSSFWorkbook wb, XSSFSheet sheet, String[] headers, String bgColor) {
        XSSFRow header = sheet.createRow(0);
        header.setHeight((short) 600);
        for (int i = 0; i < headers.length; i++) {
            XSSFCell cell = header.createCell(i);
            cell.setCellValue(headers[i]);
            cell.setCellStyle(createHeaderStyle(wb, bgColor));
        }
    }

    private void writeCell(XSSFRow row, int col, String value, String bgColor, XSSFWorkbook wb) {
        XSSFCell cell = row.createCell(col);
        cell.setCellValue(value != null ? value : "");
        if (bgColor != null) {
            XSSFCellStyle style = wb.createCellStyle();
            XSSFColor color = new XSSFColor(hexToBytes(bgColor), null);
            style.setFillForegroundColor(color);
            style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
            XSSFFont font = wb.createFont();
            font.setColor(new XSSFColor(hexToBytes(COLOR_WHITE), null));
            font.setBold(true);
            style.setFont(font);
            cell.setCellStyle(style);
        }
    }

    private void writeColorCell(XSSFRow row, int col, String value, String bgColor, XSSFWorkbook wb) {
        XSSFCell cell = row.createCell(col);
        cell.setCellValue(value);
        XSSFCellStyle style = wb.createCellStyle();
        XSSFColor color = new XSSFColor(hexToBytes(bgColor), null);
        style.setFillForegroundColor(color);
        style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        XSSFFont font = wb.createFont();
        font.setColor(new XSSFColor(hexToBytes(COLOR_WHITE), null));
        font.setBold(true);
        style.setFont(font);
        style.setAlignment(HorizontalAlignment.CENTER);
        cell.setCellStyle(style);
    }

    private void styleDataRow(XSSFWorkbook wb, XSSFRow row, boolean alternate) {
        XSSFCellStyle style = wb.createCellStyle();
        if (alternate) {
            XSSFColor color = new XSSFColor(hexToBytes(COLOR_LIGHT_GREY), null);
            style.setFillForegroundColor(color);
            style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        }
        style.setBorderBottom(BorderStyle.THIN);
        for (int i = 0; i < row.getLastCellNum(); i++) {
            XSSFCell cell = row.getCell(i);
            if (cell != null && cell.getCellStyle().getFillPattern() == FillPatternType.NO_FILL) {
                cell.setCellStyle(style);
            }
        }
    }

    private XSSFCellStyle createHeaderStyle(XSSFWorkbook wb, String bgColor) {
        XSSFCellStyle style = wb.createCellStyle();
        XSSFColor color = new XSSFColor(hexToBytes(bgColor), null);
        style.setFillForegroundColor(color);
        style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        XSSFFont font = wb.createFont();
        font.setBold(true);
        font.setFontHeightInPoints((short) 11);
        font.setColor(new XSSFColor(hexToBytes(COLOR_WHITE), null));
        style.setFont(font);
        style.setAlignment(HorizontalAlignment.CENTER);
        style.setVerticalAlignment(VerticalAlignment.CENTER);
        style.setBorderBottom(BorderStyle.MEDIUM);
        return style;
    }

    private XSSFCellStyle createTitleStyle(XSSFWorkbook wb) {
        XSSFCellStyle style = wb.createCellStyle();
        XSSFFont font = wb.createFont();
        font.setBold(true);
        font.setFontHeightInPoints((short) 16);
        style.setFont(font);
        style.setAlignment(HorizontalAlignment.CENTER);
        return style;
    }

    private void autoSizeColumns(XSSFSheet sheet, int count) {
        for (int i = 0; i < count; i++) {
            sheet.autoSizeColumn(i);
            int width = sheet.getColumnWidth(i);
            if (width < 3000) sheet.setColumnWidth(i, 3000);
            if (width > 15000) sheet.setColumnWidth(i, 15000);
        }
    }

    private void addFilters(XSSFSheet sheet, int cols) {
        sheet.setAutoFilter(new CellRangeAddress(0, 0, 0, cols - 1));
    }

    private void writeWorkbook(XSSFWorkbook wb, String path) throws IOException {
        try (FileOutputStream fos = new FileOutputStream(path)) {
            wb.write(fos);
        }
        logger.info("Excel written: {}", path);
    }

    private byte[] hexToBytes(String hex) {
        hex = hex.replace("#", "");
        int len = hex.length();
        byte[] data = new byte[len / 2];
        for (int i = 0; i < len; i += 2) {
            data[i / 2] = (byte) ((Character.digit(hex.charAt(i), 16) << 4)
                    + Character.digit(hex.charAt(i + 1), 16));
        }
        return data;
    }

    private String safeStr(String s) {
        return s != null ? s : "";
    }
}
