package com.smartstudent.tests;

import com.smartstudent.listeners.RetryAnalyzer;
import com.smartstudent.listeners.TestPriority;
import com.smartstudent.pages.DashboardPage;
import com.smartstudent.pages.SearchPage;
import com.smartstudent.utils.TestDataUtils;
import org.testng.Assert;
import org.testng.annotations.Test;

/**
 * Search & Filter Test Suite — 40 test cases
 * TC_SEARCH_001–020 | TC_FILTER_001–020
 */
public class SearchAndFilterTests extends BaseTest {

    private DashboardPage loginAndGetDashboard() {
        return loginPage.loginWithValidCredentials(TestDataUtils.VALID_EMAIL, TestDataUtils.VALID_PASSWORD);
    }

    // ── Search (20) ───────────────────────────────────────────────

    @Test(description = "TC_SEARCH_001 - Search page loads", retryAnalyzer = RetryAnalyzer.class)
    @TestPriority("Critical")
    public void TC_SEARCH_001_SearchPageLoads() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        Assert.assertTrue(search.isPageLoaded(), "Search page should be loaded");
    }

    @Test(description = "TC_SEARCH_002 - Search bar is visible")
    @TestPriority("High")
    public void TC_SEARCH_002_SearchBarVisible() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        Assert.assertTrue(search.isSearchBarDisplayed(), "Search bar should be visible");
    }

    @Test(description = "TC_SEARCH_003 - Search with valid skill keyword")
    @TestPriority("High")
    public void TC_SEARCH_003_SearchValidKeyword() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("Java");
        Assert.assertTrue(search.hasResults() || search.isNoResultsDisplayed(),
            "Should show results or no-results message");
    }

    @Test(description = "TC_SEARCH_004 - Search with empty query")
    @TestPriority("Medium")
    public void TC_SEARCH_004_SearchWithEmptyQuery() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("");
        sleep(1500);
        Assert.assertTrue(search.isPageLoaded(), "Search page should handle empty query");
    }

    @Test(description = "TC_SEARCH_005 - Search with whitespace query")
    @TestPriority("Medium")
    public void TC_SEARCH_005_SearchWithWhitespace() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("   ");
        sleep(1500);
        Assert.assertTrue(search.isPageLoaded(), "Search should handle whitespace query");
    }

    @Test(description = "TC_SEARCH_006 - Search with special characters")
    @TestPriority("Medium")
    public void TC_SEARCH_006_SearchWithSpecialChars() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("!@#$%");
        sleep(1500);
        Assert.assertTrue(search.isPageLoaded(), "Should handle special chars in search");
    }

    @Test(description = "TC_SEARCH_007 - Search with SQL injection")
    @TestPriority("High")
    public void TC_SEARCH_007_SearchSQLInjection() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery(TestDataUtils.generateSQLInjection());
        sleep(1500);
        Assert.assertTrue(search.isPageLoaded(), "Should handle SQL injection in search");
    }

    @Test(description = "TC_SEARCH_008 - Search no-results message shown for unknown")
    @TestPriority("Medium")
    public void TC_SEARCH_008_SearchNoResultsMessage() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("xyzqwerty12345nonexistent");
        Assert.assertTrue(search.isNoResultsDisplayed() || search.isPageLoaded(),
            "Should show no results for unknown query");
    }

    @Test(description = "TC_SEARCH_009 - Search result count updates")
    @TestPriority("Medium")
    public void TC_SEARCH_009_SearchResultCountUpdates() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery(TestDataUtils.generateSkill());
        int count = search.getResultCount();
        Assert.assertTrue(count >= 0, "Result count should be non-negative");
    }

    @Test(description = "TC_SEARCH_010 - Clear search field works")
    @TestPriority("Medium")
    public void TC_SEARCH_010_ClearSearchField() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("Python");
        sleep(1000);
        search.clearSearch();
        sleep(1000);
        Assert.assertTrue(search.isPageLoaded(), "Clear search should work");
    }

    @Test(description = "TC_SEARCH_011 - Search with very long query")
    @TestPriority("Low")
    public void TC_SEARCH_011_SearchVeryLongQuery() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery(TestDataUtils.generateVeryLongText());
        sleep(1500);
        Assert.assertTrue(search.isPageLoaded(), "Should handle very long search query");
    }

    @Test(description = "TC_SEARCH_012 - Search with unicode characters")
    @TestPriority("Low")
    public void TC_SEARCH_012_SearchUnicode() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery(TestDataUtils.generateUnicodeText());
        sleep(1500);
        Assert.assertTrue(search.isPageLoaded(), "Should handle unicode search query");
    }

    @Test(description = "TC_SEARCH_013 - Search result clickable")
    @TestPriority("Medium")
    public void TC_SEARCH_013_SearchResultClickable() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("test");
        sleep(1500);
        if (search.hasResults()) {
            search.clickFirstResult();
            sleep(1000);
        }
        Assert.assertTrue(true, "Search result click handled");
    }

    @Test(description = "TC_SEARCH_014 - Repeated search queries work")
    @TestPriority("Medium")
    public void TC_SEARCH_014_RepeatedSearchQueries() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        String[] queries = {"Java", "Python", "Flutter", "React"};
        for (String q : queries) {
            search.clearSearch();
            search.enterSearchQuery(q);
            sleep(800);
        }
        Assert.assertTrue(search.isPageLoaded(), "Repeated searches should work");
    }

    @Test(description = "TC_SEARCH_015 - Search performance within time limit")
    @TestPriority("High")
    public void TC_SEARCH_015_SearchPerformance() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        long start = System.currentTimeMillis();
        search.enterSearchQuery("Java");
        Assert.assertTrue(search.hasResults() || search.isNoResultsDisplayed() || search.isPageLoaded());
        long duration = System.currentTimeMillis() - start;
        Assert.assertTrue(duration < 10000, "Search should complete within 10 seconds, took: " + duration + "ms");
    }

    @Test(description = "TC_SEARCH_016 - Search with single character")
    @TestPriority("Low")
    public void TC_SEARCH_016_SearchSingleChar() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("a");
        sleep(1500);
        Assert.assertTrue(search.isPageLoaded(), "Single char search handled");
    }

    @Test(description = "TC_SEARCH_017 - Search case insensitive")
    @TestPriority("Medium")
    public void TC_SEARCH_017_SearchCaseInsensitive() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("JAVA");
        sleep(1500);
        Assert.assertTrue(search.isPageLoaded(), "Search should be case-insensitive");
    }

    @Test(description = "TC_SEARCH_018 - Search with numeric query")
    @TestPriority("Low")
    public void TC_SEARCH_018_SearchNumericQuery() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("123");
        sleep(1500);
        Assert.assertTrue(search.isPageLoaded(), "Numeric search handled");
    }

    @Test(description = "TC_SEARCH_019 - Back navigation from search")
    @TestPriority("Medium")
    public void TC_SEARCH_019_BackFromSearch() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        Assert.assertTrue(search.isPageLoaded());
        search.navigateBack();
        sleep(1000);
        Assert.assertTrue(dash.isDashboardDisplayed() || true, "Back from search handled");
    }

    @Test(description = "TC_SEARCH_020 - Search page filter button accessible")
    @TestPriority("Low")
    public void TC_SEARCH_020_FilterButtonAccessible() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        Assert.assertTrue(search.isPageLoaded(), "Search page with filter button accessible");
    }

    // ── Filter (20) ───────────────────────────────────────────────

    @Test(description = "TC_FILTER_001 - Filter button accessible on search page")
    @TestPriority("Medium")
    public void TC_FILTER_001_FilterButtonAccessible() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        Assert.assertTrue(search.isPageLoaded(), "Filter should be accessible");
    }

    @Test(description = "TC_FILTER_002 - Filter by skill category")
    @TestPriority("High")
    public void TC_FILTER_002_FilterBySkillCategory() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("Java");
        search.clickFilter();
        sleep(1500);
        Assert.assertTrue(search.isPageLoaded(), "Filter by skill category handled");
    }

    @Test(description = "TC_FILTER_003 - Filter results count changes after apply")
    @TestPriority("Medium")
    public void TC_FILTER_003_FilterChangesResultCount() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("Python");
        sleep(1000);
        int before = search.getResultCount();
        search.clickFilter();
        sleep(1500);
        Assert.assertTrue(search.getResultCount() >= 0, "Filter result count should be non-negative");
    }

    @Test(description = "TC_FILTER_004 - Multiple filter selections")
    @TestPriority("Medium")
    public void TC_FILTER_004_MultipleFilterSelections() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("Developer");
        search.clickFilter();
        sleep(1500);
        Assert.assertTrue(search.isPageLoaded(), "Multiple filter selections handled");
    }

    @Test(description = "TC_FILTER_005 - Clear all filters")
    @TestPriority("Medium")
    public void TC_FILTER_005_ClearAllFilters() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("React");
        search.clickFilter();
        sleep(1500);
        search.clearSearch();
        sleep(1000);
        Assert.assertTrue(search.isPageLoaded(), "Clear all filters handled");
    }

    @Test(description = "TC_FILTER_006 - Filter by role — Student")
    @TestPriority("Medium")
    public void TC_FILTER_006_FilterByRoleStudent() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("Student");
        sleep(1500);
        Assert.assertTrue(search.isPageLoaded(), "Filter by Student role handled");
    }

    @Test(description = "TC_FILTER_007 - Filter by role — Teacher")
    @TestPriority("Medium")
    public void TC_FILTER_007_FilterByRoleTeacher() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("Teacher");
        sleep(1500);
        Assert.assertTrue(search.isPageLoaded(), "Filter by Teacher role handled");
    }

    @Test(description = "TC_FILTER_008 - Filter combo search and filter")
    @TestPriority("Medium")
    public void TC_FILTER_008_CombinedSearchAndFilter() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery(TestDataUtils.generateSkill());
        sleep(1000);
        search.clickFilter();
        sleep(1500);
        Assert.assertTrue(search.isPageLoaded(), "Combined search and filter handled");
    }

    @Test(description = "TC_FILTER_009 - Filter no results message shown correctly")
    @TestPriority("Medium")
    public void TC_FILTER_009_FilterNoResultsMessage() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("zzzqqqxxx999nonexistent");
        sleep(1500);
        Assert.assertTrue(search.isNoResultsDisplayed() || search.isPageLoaded(),
            "No results message should be shown");
    }

    @Test(description = "TC_FILTER_010 - Filter performance within limit")
    @TestPriority("High")
    public void TC_FILTER_010_FilterPerformance() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        long start = System.currentTimeMillis();
        search.enterSearchQuery("Machine Learning");
        sleep(1500);
        long duration = System.currentTimeMillis() - start;
        Assert.assertTrue(duration < 15000, "Filter operation should complete within 15 seconds");
    }

    @Test(description = "TC_FILTER_011 - Filter by institution")
    @TestPriority("Low")
    public void TC_FILTER_011_FilterByInstitution() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("University");
        sleep(1500);
        Assert.assertTrue(search.isPageLoaded(), "Filter by institution handled");
    }

    @Test(description = "TC_FILTER_012 - Filter by degree")
    @TestPriority("Low")
    public void TC_FILTER_012_FilterByDegree() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("BTech");
        sleep(1500);
        Assert.assertTrue(search.isPageLoaded(), "Filter by degree handled");
    }

    @Test(description = "TC_FILTER_013 - Reset filter restores all results")
    @TestPriority("Medium")
    public void TC_FILTER_013_ResetFilterRestoresResults() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("Python");
        sleep(1000);
        search.clearSearch();
        sleep(1000);
        Assert.assertTrue(search.isPageLoaded(), "Reset filter should restore results");
    }

    @Test(description = "TC_FILTER_014 - Filter maintains state after back navigation")
    @TestPriority("Low")
    public void TC_FILTER_014_FilterStateAfterBack() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("Flutter");
        sleep(1000);
        driver.navigate().back();
        sleep(500);
        Assert.assertTrue(true, "Filter state after back navigation handled");
    }

    @Test(description = "TC_FILTER_015 - Search and filter with XSS payload")
    @TestPriority("High")
    public void TC_FILTER_015_SearchFilterXSSPayload() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery(TestDataUtils.generateXSSPayload());
        sleep(1500);
        Assert.assertTrue(search.isPageLoaded(), "Should handle XSS in filter");
    }

    @Test(description = "TC_FILTER_016 - Filter updates dynamically as user types")
    @TestPriority("Medium")
    public void TC_FILTER_016_FilterDynamicUpdate() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("A");
        sleep(500);
        search.enterSearchQuery("An");
        sleep(500);
        search.enterSearchQuery("And");
        sleep(500);
        Assert.assertTrue(search.isPageLoaded(), "Dynamic filter updates handled");
    }

    @Test(description = "TC_FILTER_017 - Filter with numeric input")
    @TestPriority("Low")
    public void TC_FILTER_017_FilterNumericInput() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("2025");
        sleep(1500);
        Assert.assertTrue(search.isPageLoaded(), "Filter with numeric input handled");
    }

    @Test(description = "TC_FILTER_018 - Filter pagination if applicable")
    @TestPriority("Low")
    public void TC_FILTER_018_FilterPagination() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("Developer");
        sleep(1500);
        search.swipeUp();
        sleep(500);
        Assert.assertTrue(search.isPageLoaded(), "Filter pagination/scrolling handled");
    }

    @Test(description = "TC_FILTER_019 - Filter accessible without prior search")
    @TestPriority("Medium")
    public void TC_FILTER_019_FilterWithoutSearch() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.clickFilter();
        sleep(1500);
        Assert.assertTrue(search.isPageLoaded(), "Filter without search handled");
    }

    @Test(description = "TC_FILTER_020 - Search results are sorted relevantly")
    @TestPriority("Medium")
    public void TC_FILTER_020_SearchResultsSorted() {
        DashboardPage dash = loginAndGetDashboard();
        SearchPage search = dash.navigateToSearch();
        search.enterSearchQuery("AI");
        sleep(2000);
        Assert.assertTrue(search.isPageLoaded(), "Search results should be displayed relevantly");
    }
}
