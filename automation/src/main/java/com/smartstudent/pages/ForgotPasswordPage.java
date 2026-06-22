package com.smartstudent.pages;

import org.openqa.selenium.By;

/** Forgot Password page object. */
public class ForgotPasswordPage extends BasePage {
    private static final By EMAIL_FIELD = By.xpath(
            "//android.widget.EditText[contains(@hint,'email') or contains(@hint,'Email')]");
    private static final By SEND_BTN = By.xpath(
            "//*[contains(@text,'Send') or contains(@text,'Reset') or contains(@text,'Submit')]");
    private static final By SUCCESS_MSG = By.xpath(
            "//*[contains(@text,'sent') or contains(@text,'check') or contains(@text,'email')]");
    private static final By ERROR_MSG = By.xpath(
            "//*[contains(@text,'Error') or contains(@text,'Invalid') or contains(@text,'not found')]");
    private static final By BACK_BTN = By.xpath(
            "//android.widget.ImageButton[@content-desc='Navigate up']");

    public ForgotPasswordPage enterEmail(String email) {
        type(EMAIL_FIELD, email);
        return this;
    }

    public void clickSendResetLink() {
        hideKeyboard();
        click(SEND_BTN);
        waitUtils.waitForSeconds(3);
    }

    public boolean isSuccessMessageDisplayed() {
        return isDisplayed(SUCCESS_MSG);
    }

    public boolean isErrorMessageDisplayed() {
        return isDisplayed(ERROR_MSG);
    }

    public LoginPage navigateBack() {
        click(BACK_BTN);
        return new LoginPage();
    }

    @Override
    public boolean isPageLoaded() {
        return isDisplayed(EMAIL_FIELD) || isDisplayed(SEND_BTN);
    }
}
