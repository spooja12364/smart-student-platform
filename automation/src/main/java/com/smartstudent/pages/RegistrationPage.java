package com.smartstudent.pages;

import io.appium.java_client.pagefactory.AndroidFindBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;

/**
 * Page Object for Registration / Sign-Up Screen.
 */
public class RegistrationPage extends BasePage {

    private static final By FULL_NAME_FIELD = By.xpath(
            "//*[contains(@hint,'name') or contains(@hint,'Name') or @index='0']//parent::*//android.widget.EditText[1]");
    private static final By EMAIL_FIELD = By.xpath(
            "//android.widget.EditText[contains(@hint,'email') or contains(@hint,'Email')]");
    private static final By PASSWORD_FIELD = By.xpath(
            "//android.widget.EditText[contains(@hint,'password') or contains(@hint,'Password')][1]");
    private static final By CONFIRM_PASSWORD_FIELD = By.xpath(
            "//android.widget.EditText[contains(@hint,'confirm') or contains(@hint,'Confirm')][last()]");
    private static final By REGISTER_BTN = By.xpath(
            "//*[contains(@text,'Register') or contains(@text,'Sign Up') or contains(@text,'Create Account') or contains(@text,'REGISTER')]");
    private static final By BACK_BTN = By.xpath(
            "//android.widget.ImageButton[@content-desc='Navigate up'] | //*[contains(@text,'Back')]");
    private static final By ERROR_MSG = By.xpath(
            "//*[contains(@text,'Error') or contains(@text,'error') or contains(@text,'already') or contains(@text,'Invalid')]");
    private static final By SUCCESS_MSG = By.xpath(
            "//*[contains(@text,'Success') or contains(@text,'Registered') or contains(@text,'Verification')]");
    private static final By SKILL_FIELD = By.xpath(
            "//android.widget.EditText[contains(@hint,'skill') or contains(@hint,'Skill')]");
    private static final By ROLE_DROPDOWN = By.xpath(
            "//*[contains(@text,'Select') or contains(@text,'Role') or contains(@text,'Student') or contains(@text,'Teacher')]");
    private static final By EMAIL_ALREADY_EXISTS_MSG = By.xpath(
            "//*[contains(@text,'already') or contains(@text,'exists') or contains(@text,'taken')]");

    @AndroidFindBy(xpath = "//android.widget.EditText[1]")
    private WebElement firstField;

    // ── Actions ───────────────────────────────────────────────────

    public RegistrationPage enterFullName(String name) {
        logger.info("Entering name: {}", name);
        try {
            type(FULL_NAME_FIELD, name);
        } catch (Exception e) {
            // Fallback: first EditText
            type(By.xpath("//android.widget.EditText[1]"), name);
        }
        return this;
    }

    public RegistrationPage enterEmail(String email) {
        logger.info("Entering email: {}", email);
        try {
            type(EMAIL_FIELD, email);
        } catch (Exception e) {
            type(By.xpath("//android.widget.EditText[2]"), email);
        }
        return this;
    }

    public RegistrationPage enterPassword(String password) {
        logger.info("Entering password");
        try {
            type(PASSWORD_FIELD, password);
        } catch (Exception e) {
            type(By.xpath("//android.widget.EditText[3]"), password);
        }
        return this;
    }

    public RegistrationPage enterConfirmPassword(String password) {
        logger.info("Entering confirm password");
        try {
            type(CONFIRM_PASSWORD_FIELD, password);
        } catch (Exception e) {
            type(By.xpath("//android.widget.EditText[4]"), password);
        }
        hideKeyboard();
        return this;
    }

    public RegistrationPage enterSkill(String skill) {
        try {
            type(SKILL_FIELD, skill);
        } catch (Exception ignored) {}
        return this;
    }

    public void clickRegister() {
        logger.info("Clicking Register button");
        click(REGISTER_BTN);
        waitUtils.waitForSeconds(3);
    }

    public void registerUser(String name, String email, String password) {
        enterFullName(name);
        enterEmail(email);
        enterPassword(password);
        enterConfirmPassword(password);
        clickRegister();
    }

    public boolean isErrorMessageDisplayed() {
        return isDisplayed(ERROR_MSG);
    }

    public boolean isEmailAlreadyExistsErrorDisplayed() {
        return isDisplayed(EMAIL_ALREADY_EXISTS_MSG);
    }

    public String getErrorMessage() {
        try { return getText(ERROR_MSG); } catch (Exception e) { return ""; }
    }

    public boolean isRegistrationSuccessful() {
        return isDisplayed(SUCCESS_MSG);
    }

    public LoginPage navigateBack() {
        click(BACK_BTN);
        return new LoginPage();
    }

    public boolean isRegisterButtonEnabled() {
        try {
            return driver.findElement(REGISTER_BTN).isEnabled();
        } catch (Exception e) {
            return false;
        }
    }

    @Override
    public boolean isPageLoaded() {
        return isDisplayed(REGISTER_BTN);
    }
}
