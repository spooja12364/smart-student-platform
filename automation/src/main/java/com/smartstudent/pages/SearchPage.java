package com.smartstudent.pages;

import org.openqa.selenium.By;

/** Search & Discover page object. */
public class SearchPage extends BasePage {
    private static final By SEARCH_BAR = By.xpath(
            "//android.widget.EditText[contains(@hint,'Search') or contains(@hint,'search') or contains(@hint,'Find')]");
    private static final By SEARCH_RESULTS = By.xpath(
            "//*[contains(@resource-id,'result') or contains(@resource-id,'item')]");
    private static final By NO_RESULTS_MSG = By.xpath(
            "//*[contains(@text,'No results') or contains(@text,'not found') or contains(@text,'empty')]");
    private static final By BACK_BTN = By.xpath(
            "//android.widget.ImageButton[@content-desc='Navigate up']");
    private static final By FILTER_BTN = By.xpath(
            "//*[contains(@text,'Filter') or contains(@content-desc,'Filter')]");
    private static final By CLEAR_BTN = By.xpath(
            "//*[contains(@text,'Clear') or contains(@content-desc,'Clear')]");
    private static final By FIRST_RESULT = By.xpath(
            "//android.view.ViewGroup[@clickable='true'][1]");

    public SearchPage enterSearchQuery(String query) {
        logger.info("Searching for: {}", query);
        click(SEARCH_BAR);
        type(SEARCH_BAR, query);
        hideKeyboard();
        waitUtils.waitForSeconds(2);
        return this;
    }

    public boolean hasResults() {
        return getElementCount(SEARCH_RESULTS) > 0 || isDisplayed(FIRST_RESULT);
    }

    public boolean isNoResultsDisplayed() {
        return isDisplayed(NO_RESULTS_MSG);
    }

    public int getResultCount() {
        return getElementCount(SEARCH_RESULTS);
    }

    public void clearSearch() {
        try { click(CLEAR_BTN); } catch (Exception e) {
            driver.findElement(SEARCH_BAR).clear();
        }
    }

    public void clickFirstResult() {
        click(FIRST_RESULT);
    }

    public boolean isSearchBarDisplayed() {
        return isDisplayed(SEARCH_BAR);
    }

    public void clickFilter() {
        try { click(FILTER_BTN); } catch (Exception ignored) {}
    }

    public DashboardPage navigateBack() {
        click(BACK_BTN);
        return new DashboardPage();
    }

    @Override
    public boolean isPageLoaded() {
        return isDisplayed(SEARCH_BAR);
    }
}
