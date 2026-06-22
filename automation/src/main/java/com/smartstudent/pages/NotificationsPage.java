package com.smartstudent.pages;

import org.openqa.selenium.By;

/** Notifications page object. */
public class NotificationsPage extends BasePage {
    private static final By PAGE_TITLE = By.xpath(
            "//*[contains(@text,'Notification') or contains(@text,'Alerts')]");
    private static final By NOTIFICATION_ITEMS = By.xpath(
            "//android.view.ViewGroup[@clickable='true']");
    private static final By EMPTY_STATE = By.xpath(
            "//*[contains(@text,'No notification') or contains(@text,'empty') or contains(@text,'Nothing')]");
    private static final By BACK_BTN = By.xpath(
            "//android.widget.ImageButton[@content-desc='Navigate up']");
    private static final By MARK_ALL_READ_BTN = By.xpath(
            "//*[contains(@text,'Mark all') or contains(@text,'Read all')]");

    public boolean isNotificationsPageDisplayed() {
        return isDisplayed(PAGE_TITLE);
    }

    public int getNotificationCount() {
        return getElementCount(NOTIFICATION_ITEMS);
    }

    public boolean hasNotifications() {
        return getNotificationCount() > 0;
    }

    public boolean isEmptyStateDisplayed() {
        return isDisplayed(EMPTY_STATE);
    }

    public void markAllAsRead() {
        try { click(MARK_ALL_READ_BTN); } catch (Exception ignored) {}
    }

    public void clickFirstNotification() {
        try { click(NOTIFICATION_ITEMS); } catch (Exception ignored) {}
    }

    public DashboardPage navigateBack() {
        navigateBack();
        return new DashboardPage();
    }

    @Override
    public boolean isPageLoaded() {
        return isNotificationsPageDisplayed();
    }
}
