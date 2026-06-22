package com.smartstudent.pages;

import org.openqa.selenium.By;

/**
 * Page Object for Profile Screen.
 */
public class ProfilePage extends BasePage {

    private static final By PROFILE_TITLE = By.xpath(
            "//*[contains(@text,'Profile') or contains(@text,'My Profile')]");
    private static final By EDIT_BTN = By.xpath(
            "//*[contains(@text,'Edit') or contains(@content-desc,'Edit')]");
    private static final By USERNAME_FIELD = By.xpath(
            "//*[contains(@text,'@') or contains(@hint,'username')]");
    private static final By EMAIL_LABEL = By.xpath(
            "//*[contains(@text,'@') and contains(@text,'.')]");
    private static final By AVATAR = By.xpath(
            "//android.widget.ImageView[@index='0']");
    private static final By BIO_FIELD = By.xpath(
            "//*[contains(@hint,'bio') or contains(@hint,'Bio') or contains(@hint,'About')]");
    private static final By SKILLS_SECTION = By.xpath(
            "//*[contains(@text,'Skills') or contains(@text,'skills')]");
    private static final By SAVE_BTN = By.xpath(
            "//*[contains(@text,'Save') or contains(@text,'Update') or contains(@text,'SAVE')]");
    private static final By BACK_BTN = By.xpath(
            "//android.widget.ImageButton[@content-desc='Navigate up']");
    private static final By CONNECTIONS_COUNT = By.xpath(
            "//*[contains(@text,'Connection') or contains(@text,'Followers')]");
    private static final By CHANGE_PHOTO_BTN = By.xpath(
            "//*[contains(@text,'Change') or contains(@text,'Photo') or contains(@text,'Avatar')]");
    private static final By NAME_FIELD = By.xpath(
            "//android.widget.EditText[1]");

    // ── Actions ───────────────────────────────────────────────────

    public EditProfilePage clickEdit() {
        logger.info("Clicking Edit Profile");
        click(EDIT_BTN);
        return new EditProfilePage();
    }

    public boolean isProfileDisplayed() {
        return isDisplayed(PROFILE_TITLE) || isDisplayed(AVATAR);
    }

    public boolean isEditButtonDisplayed() {
        return isDisplayed(EDIT_BTN);
    }

    public boolean isSkillsSectionDisplayed() {
        return isDisplayed(SKILLS_SECTION);
    }

    public boolean isConnectionsCountDisplayed() {
        return isDisplayed(CONNECTIONS_COUNT);
    }

    public String getEmailText() {
        try { return getText(EMAIL_LABEL); } catch (Exception e) { return ""; }
    }

    public DashboardPage navigateBack() {
        click(BACK_BTN);
        return new DashboardPage();
    }

    public boolean isChangePhotoDisplayed() {
        return isDisplayed(CHANGE_PHOTO_BTN);
    }

    @Override
    public boolean isPageLoaded() {
        return isProfileDisplayed();
    }
}
