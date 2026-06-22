package com.smartstudent.pages;

import org.openqa.selenium.By;

/** EditProfile page object. */
public class EditProfilePage extends BasePage {
    private static final By NAME_FIELD = By.xpath("//android.widget.EditText[1]");
    private static final By BIO_FIELD = By.xpath(
            "//android.widget.EditText[contains(@hint,'bio') or contains(@hint,'About') or @index='1']");
    private static final By SKILL_FIELD = By.xpath(
            "//android.widget.EditText[contains(@hint,'skill') or contains(@hint,'Skill')]");
    private static final By SAVE_BTN = By.xpath(
            "//*[contains(@text,'Save') or contains(@text,'Update') or contains(@text,'SAVE')]");
    private static final By BACK_BTN = By.xpath(
            "//android.widget.ImageButton[@content-desc='Navigate up']");
    private static final By SUCCESS_TOAST = By.xpath(
            "//*[contains(@text,'updated') or contains(@text,'saved') or contains(@text,'Success')]");

    public EditProfilePage enterName(String name) {
        type(NAME_FIELD, name);
        return this;
    }

    public EditProfilePage enterBio(String bio) {
        try { type(BIO_FIELD, bio); } catch (Exception ignored) {}
        return this;
    }

    public EditProfilePage enterSkill(String skill) {
        try { type(SKILL_FIELD, skill); } catch (Exception ignored) {}
        return this;
    }

    public ProfilePage clickSave() {
        hideKeyboard();
        click(SAVE_BTN);
        waitUtils.waitForSeconds(2);
        return new ProfilePage();
    }

    public boolean isSuccessToastDisplayed() {
        return isDisplayed(SUCCESS_TOAST);
    }

    public ProfilePage navigateBack() {
        click(BACK_BTN);
        return new ProfilePage();
    }

    @Override
    public boolean isPageLoaded() {
        return isDisplayed(SAVE_BTN) || isDisplayed(NAME_FIELD);
    }
}
