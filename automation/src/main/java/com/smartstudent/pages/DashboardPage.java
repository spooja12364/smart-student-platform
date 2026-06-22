package com.smartstudent.pages;

import org.openqa.selenium.By;

/**
 * Page Object for Dashboard / Home Screen.
 */
public class DashboardPage extends BasePage {

    private static final By DASHBOARD_TITLE = By.xpath(
            "//*[contains(@text,'Dashboard') or contains(@text,'Home') or contains(@text,'Feed')]");
    private static final By PROFILE_ICON = By.xpath(
            "//*[contains(@content-desc,'Profile') or contains(@content-desc,'profile') or @index='4']");
    private static final By SEARCH_ICON = By.xpath(
            "//*[contains(@content-desc,'Search') or contains(@content-desc,'search')]");
    private static final By CHAT_ICON = By.xpath(
            "//*[contains(@content-desc,'Chat') or contains(@content-desc,'Message')]");
    private static final By NOTIFICATIONS_ICON = By.xpath(
            "//*[contains(@content-desc,'Notification') or contains(@content-desc,'notification')]");
    private static final By CONNECTION_TAB = By.xpath(
            "//*[contains(@text,'Connection') or contains(@text,'Connect') or contains(@content-desc,'Connection')]");
    private static final By AI_MATCHING_BTN = By.xpath(
            "//*[contains(@text,'AI') or contains(@text,'Match') or contains(@text,'Suggest')]");
    private static final By LOGOUT_BTN = By.xpath(
            "//*[contains(@text,'Logout') or contains(@text,'Sign Out') or contains(@text,'Log Out')]");
    private static final By BOTTOM_NAV = By.xpath(
            "//android.widget.BottomNavigationView | //android.view.ViewGroup[@content-desc='Navigation']");
    private static final By WELCOME_TEXT = By.xpath(
            "//*[contains(@text,'Welcome') or contains(@text,'Hello')]");
    private static final By SKILLS_TAB = By.xpath(
            "//*[contains(@text,'Skill') or contains(@text,'Skills') or contains(@content-desc,'Skills')]");
    private static final By GROUPS_TAB = By.xpath(
            "//*[contains(@text,'Group') or contains(@content-desc,'Group')]");
    private static final By DISCOVER_TAB = By.xpath(
            "//*[contains(@text,'Discover') or contains(@text,'Explore') or contains(@content-desc,'Discover')]");
    private static final By OVERFLOW_MENU = By.xpath(
            "//android.widget.ImageView[@content-desc='More options']");

    // ── Actions ───────────────────────────────────────────────────

    public ProfilePage navigateToProfile() {
        logger.info("Navigating to Profile");
        click(PROFILE_ICON);
        return new ProfilePage();
    }

    public SearchPage navigateToSearch() {
        logger.info("Navigating to Search");
        click(SEARCH_ICON);
        return new SearchPage();
    }

    public NotificationsPage navigateToNotifications() {
        logger.info("Navigating to Notifications");
        click(NOTIFICATIONS_ICON);
        return new NotificationsPage();
    }

    public void clickLogout() {
        logger.info("Clicking Logout");
        try {
            click(OVERFLOW_MENU);
            waitUtils.waitForSeconds(1);
        } catch (Exception ignored) {}
        click(LOGOUT_BTN);
        waitUtils.waitForSeconds(2);
    }

    public boolean isDashboardDisplayed() {
        return isDisplayed(DASHBOARD_TITLE) || isDisplayed(BOTTOM_NAV);
    }

    public boolean isWelcomeTextDisplayed() {
        return isDisplayed(WELCOME_TEXT);
    }

    public boolean isProfileIconDisplayed() {
        return isDisplayed(PROFILE_ICON);
    }

    public boolean isSearchIconDisplayed() {
        return isDisplayed(SEARCH_ICON);
    }

    public boolean isChatIconDisplayed() {
        return isDisplayed(CHAT_ICON);
    }

    public boolean isConnectionTabDisplayed() {
        return isDisplayed(CONNECTION_TAB);
    }

    public boolean isAIMatchingDisplayed() {
        return isDisplayed(AI_MATCHING_BTN);
    }

    public boolean isBottomNavVisible() {
        return isDisplayed(BOTTOM_NAV);
    }

    public String getDashboardTitle() {
        try { return getText(DASHBOARD_TITLE); } catch (Exception e) { return ""; }
    }

    public void navigateToConnections() {
        try { click(CONNECTION_TAB); } catch (Exception ignored) {}
    }

    public void navigateToSkills() {
        try { click(SKILLS_TAB); } catch (Exception ignored) {}
    }

    public void navigateToGroups() {
        try { click(GROUPS_TAB); } catch (Exception ignored) {}
    }

    public void navigateToDiscover() {
        try { click(DISCOVER_TAB); } catch (Exception ignored) {}
    }

    public void clickAIMatching() {
        try { click(AI_MATCHING_BTN); } catch (Exception ignored) {}
    }

    @Override
    public boolean isPageLoaded() {
        return isDashboardDisplayed();
    }
}
