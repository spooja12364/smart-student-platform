package com.smartstudent.pages;

import io.appium.java_client.pagefactory.AndroidFindBy;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;

/**
 * Page Object for Login Screen.
 * App package: com.example.smart_student_platform
 */
public class LoginPage extends BasePage {

    // ── Locators ──────────────────────────────────────────────────
    @AndroidFindBy(xpath = "//android.widget.EditText[1]")
    private WebElement emailField;

    @AndroidFindBy(xpath = "//android.widget.EditText[2]")
    private WebElement passwordField;

    @AndroidFindBy(xpath = "//*[contains(@text,'Login') or contains(@text,'Sign In') or contains(@text,'LOG IN')]")
    private WebElement loginButton;

    @AndroidFindBy(xpath = "//*[contains(@text,'Register') or contains(@text,'Sign Up') or contains(@text,'Create Account')]")
    private WebElement registerLink;

    @AndroidFindBy(xpath = "//*[contains(@text,'Forgot') or contains(@text,'forgot') or contains(@text,'Reset')]")
    private WebElement forgotPasswordLink;

    @AndroidFindBy(xpath = "//*[contains(@text,'Google') or contains(@content-desc,'Google')]")
    private WebElement googleSignInButton;

    @AndroidFindBy(xpath = "//*[contains(@text,'Invalid') or contains(@text,'Error') or contains(@text,'incorrect')]")
    private WebElement errorMessage;

    @AndroidFindBy(xpath = "//*[contains(@text,'Smart Student') or contains(@text,'Welcome')]")
    private WebElement appTitle;

    @AndroidFindBy(xpath = "//*[contains(@text,'email') or contains(@hint,'email')]")
    private WebElement emailHintField;

    private static final By EMAIL_FIELD = By.xpath("//android.widget.EditText[1]");
    private static final By PASSWORD_FIELD = By.xpath("//android.widget.EditText[2]");
    private static final By LOGIN_BTN = By.xpath(
            "//*[contains(@text,'Login') or contains(@text,'Sign In') or contains(@text,'LOG IN')]");
    private static final By ERROR_MSG = By.xpath(
            "//*[contains(@text,'Invalid') or contains(@text,'Error') or contains(@text,'incorrect') or contains(@text,'wrong')]");
    private static final By REGISTER_LINK = By.xpath(
            "//*[contains(@text,'Register') or contains(@text,'Sign Up') or contains(@text,'Create')]");
    private static final By FORGOT_PWD_LINK = By.xpath(
            "//*[contains(@text,'Forgot') or contains(@text,'forgot') or contains(@text,'Reset')]");
    private static final By WELCOME_TEXT = By.xpath(
            "//*[contains(@text,'Smart Student') or contains(@text,'Welcome') or contains(@text,'Login')]");

    // ── Actions ───────────────────────────────────────────────────

    public LoginPage enterEmail(String email) {
        logger.info("Entering email: {}", email);
        type(EMAIL_FIELD, email);
        return this;
    }

    public LoginPage enterPassword(String password) {
        logger.info("Entering password");
        type(PASSWORD_FIELD, password);
        hideKeyboard();
        return this;
    }

    public void clickLogin() {
        logger.info("Clicking Login button");
        click(LOGIN_BTN);
    }

    public DashboardPage loginWithValidCredentials(String email, String password) {
        enterEmail(email);
        enterPassword(password);
        clickLogin();
        waitUtils.waitForSeconds(3);
        return new DashboardPage();
    }

    public LoginPage attemptLogin(String email, String password) {
        enterEmail(email);
        enterPassword(password);
        clickLogin();
        waitUtils.waitForSeconds(2);
        return this;
    }

    public RegistrationPage clickRegister() {
        logger.info("Clicking Register / Sign Up link");
        click(REGISTER_LINK);
        return new RegistrationPage();
    }

    public ForgotPasswordPage clickForgotPassword() {
        logger.info("Clicking Forgot Password");
        click(FORGOT_PWD_LINK);
        return new ForgotPasswordPage();
    }

    public boolean isErrorMessageDisplayed() {
        return isDisplayed(ERROR_MSG);
    }

    public String getErrorMessage() {
        try {
            return getText(ERROR_MSG);
        } catch (Exception e) {
            return "";
        }
    }

    public boolean isEmailFieldDisplayed() {
        return isDisplayed(EMAIL_FIELD);
    }

    public boolean isPasswordFieldDisplayed() {
        return isDisplayed(PASSWORD_FIELD);
    }

    public boolean isLoginButtonDisplayed() {
        return isDisplayed(LOGIN_BTN);
    }

    public boolean isRegisterLinkDisplayed() {
        return isDisplayed(REGISTER_LINK);
    }

    public boolean isForgotPasswordDisplayed() {
        return isDisplayed(FORGOT_PWD_LINK);
    }

    public String getEmailFieldText() {
        try {
            return getAttribute(emailField, "text");
        } catch (Exception e) {
            return "";
        }
    }

    public LoginPage clearEmail() {
        click(EMAIL_FIELD);
        driver.findElement(EMAIL_FIELD).clear();
        return this;
    }

    public LoginPage clearPassword() {
        click(PASSWORD_FIELD);
        driver.findElement(PASSWORD_FIELD).clear();
        return this;
    }

    public boolean isLoginButtonEnabled() {
        try {
            return driver.findElement(LOGIN_BTN).isEnabled();
        } catch (Exception e) {
            return false;
        }
    }

    @Override
    public boolean isPageLoaded() {
        return isDisplayed(LOGIN_BTN) || isDisplayed(EMAIL_FIELD);
    }
}
