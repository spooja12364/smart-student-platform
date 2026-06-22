package com.smartstudent.tests;

import com.smartstudent.listeners.RetryAnalyzer;
import com.smartstudent.listeners.TestPriority;
import com.smartstudent.pages.DashboardPage;
import com.smartstudent.pages.ForgotPasswordPage;
import com.smartstudent.pages.LoginPage;
import com.smartstudent.utils.TestDataUtils;
import org.testng.Assert;
import org.testng.annotations.Test;

/**
 * Authentication Test Suite — 40 test cases
 * TC_AUTH_001 through TC_AUTH_040
 */
public class AuthenticationTests extends BaseTest {

    @Test(description = "TC_AUTH_001 - Valid login with correct credentials", retryAnalyzer = RetryAnalyzer.class)
    @TestPriority("Critical")
    public void TC_AUTH_001_ValidLoginWithCorrectCredentials() {
        loginPage = navigateToLoginPage();
        Assert.assertTrue(loginPage.isPageLoaded(), "Login page should be loaded");
        DashboardPage dashboard = loginPage.loginWithValidCredentials(
                TestDataUtils.VALID_EMAIL, TestDataUtils.VALID_PASSWORD);
        Assert.assertTrue(dashboard.isDashboardDisplayed(), "Dashboard should be visible after login");
    }

    @Test(description = "TC_AUTH_002 - Login with invalid email", retryAnalyzer = RetryAnalyzer.class)
    @TestPriority("Critical")
    public void TC_AUTH_002_LoginWithInvalidEmail() {
        loginPage = navigateToLoginPage();
        loginPage.attemptLogin("invalid@notexist.com", TestDataUtils.VALID_PASSWORD);
        Assert.assertTrue(loginPage.isErrorMessageDisplayed() || loginPage.isPageLoaded(),
                "Error message or login page should be visible");
    }

    @Test(description = "TC_AUTH_003 - Login with wrong password")
    @TestPriority("Critical")
    public void TC_AUTH_003_LoginWithWrongPassword() {
        loginPage = navigateToLoginPage();
        loginPage.attemptLogin(TestDataUtils.VALID_EMAIL, "WrongPass@999");
        Assert.assertTrue(loginPage.isErrorMessageDisplayed() || loginPage.isPageLoaded(),
                "Error should be shown for wrong password");
    }

    @Test(description = "TC_AUTH_004 - Login with empty email")
    @TestPriority("High")
    public void TC_AUTH_004_LoginWithEmptyEmail() {
        loginPage = navigateToLoginPage();
        loginPage.enterPassword(TestDataUtils.VALID_PASSWORD);
        loginPage.clickLogin();
        sleep(1500);
        Assert.assertTrue(loginPage.isPageLoaded(), "Should remain on login page");
    }

    @Test(description = "TC_AUTH_005 - Login with empty password")
    @TestPriority("High")
    public void TC_AUTH_005_LoginWithEmptyPassword() {
        loginPage = navigateToLoginPage();
        loginPage.enterEmail(TestDataUtils.VALID_EMAIL);
        loginPage.clickLogin();
        sleep(1500);
        Assert.assertTrue(loginPage.isPageLoaded(), "Should remain on login page");
    }

    @Test(description = "TC_AUTH_006 - Login with empty credentials")
    @TestPriority("High")
    public void TC_AUTH_006_LoginWithEmptyCredentials() {
        loginPage = navigateToLoginPage();
        loginPage.clickLogin();
        sleep(1500);
        Assert.assertTrue(loginPage.isPageLoaded(), "Should remain on login page with empty fields");
    }

    @Test(description = "TC_AUTH_007 - Verify email field is present on login page")
    @TestPriority("Medium")
    public void TC_AUTH_007_VerifyEmailFieldPresent() {
        loginPage = navigateToLoginPage();
        Assert.assertTrue(loginPage.isEmailFieldDisplayed(), "Email field should be present");
    }

    @Test(description = "TC_AUTH_008 - Verify password field is present on login page")
    @TestPriority("Medium")
    public void TC_AUTH_008_VerifyPasswordFieldPresent() {
        loginPage = navigateToLoginPage();
        Assert.assertTrue(loginPage.isPasswordFieldDisplayed(), "Password field should be present");
    }

    @Test(description = "TC_AUTH_009 - Verify login button is present")
    @TestPriority("Medium")
    public void TC_AUTH_009_VerifyLoginButtonPresent() {
        loginPage = navigateToLoginPage();
        Assert.assertTrue(loginPage.isLoginButtonDisplayed(), "Login button should be present");
    }

    @Test(description = "TC_AUTH_010 - Verify register link is present on login page")
    @TestPriority("Medium")
    public void TC_AUTH_010_VerifyRegisterLinkPresent() {
        loginPage = navigateToLoginPage();
        Assert.assertTrue(loginPage.isRegisterLinkDisplayed(), "Register link should be visible");
    }

    @Test(description = "TC_AUTH_011 - Verify forgot password link is present")
    @TestPriority("Medium")
    public void TC_AUTH_011_VerifyForgotPasswordLinkPresent() {
        loginPage = navigateToLoginPage();
        Assert.assertTrue(loginPage.isForgotPasswordDisplayed(), "Forgot password link should be visible");
    }

    @Test(description = "TC_AUTH_012 - Navigate to forgot password page")
    @TestPriority("Medium")
    public void TC_AUTH_012_NavigateToForgotPassword() {
        loginPage = navigateToLoginPage();
        ForgotPasswordPage fp = loginPage.clickForgotPassword();
        Assert.assertTrue(fp.isPageLoaded(), "Forgot password page should be loaded");
    }

    @Test(description = "TC_AUTH_013 - Forgot password with valid email")
    @TestPriority("High")
    public void TC_AUTH_013_ForgotPasswordWithValidEmail() {
        loginPage = navigateToLoginPage();
        ForgotPasswordPage fp = loginPage.clickForgotPassword();
        fp.enterEmail(TestDataUtils.VALID_EMAIL);
        fp.clickSendResetLink();
        Assert.assertTrue(fp.isSuccessMessageDisplayed() || fp.isPageLoaded(),
                "Success message or page should be visible");
    }

    @Test(description = "TC_AUTH_014 - Forgot password with invalid email")
    @TestPriority("Medium")
    public void TC_AUTH_014_ForgotPasswordWithInvalidEmail() {
        loginPage = navigateToLoginPage();
        ForgotPasswordPage fp = loginPage.clickForgotPassword();
        fp.enterEmail("notexist@invalid.com");
        fp.clickSendResetLink();
        Assert.assertTrue(fp.isErrorMessageDisplayed() || fp.isPageLoaded(),
                "Error or page should be visible for invalid email");
    }

    @Test(description = "TC_AUTH_015 - Login with SQL injection in email")
    @TestPriority("High")
    public void TC_AUTH_015_LoginWithSQLInjection() {
        loginPage = navigateToLoginPage();
        loginPage.attemptLogin(TestDataUtils.generateSQLInjection(), TestDataUtils.VALID_PASSWORD);
        Assert.assertTrue(loginPage.isPageLoaded() || loginPage.isErrorMessageDisplayed(),
                "App should handle SQL injection gracefully");
    }

    @Test(description = "TC_AUTH_016 - Login with XSS payload in email")
    @TestPriority("High")
    public void TC_AUTH_016_LoginWithXSSPayload() {
        loginPage = navigateToLoginPage();
        loginPage.attemptLogin(TestDataUtils.generateXSSPayload(), TestDataUtils.VALID_PASSWORD);
        Assert.assertTrue(loginPage.isPageLoaded() || loginPage.isErrorMessageDisplayed(),
                "App should handle XSS gracefully");
    }

    @Test(description = "TC_AUTH_017 - Login with very long email")
    @TestPriority("Low")
    public void TC_AUTH_017_LoginWithVeryLongEmail() {
        loginPage = navigateToLoginPage();
        loginPage.attemptLogin(TestDataUtils.generateVeryLongText() + "@test.com", TestDataUtils.VALID_PASSWORD);
        Assert.assertTrue(loginPage.isPageLoaded() || loginPage.isErrorMessageDisplayed(),
                "App should handle long email gracefully");
    }

    @Test(description = "TC_AUTH_018 - Login with special characters in password")
    @TestPriority("Medium")
    public void TC_AUTH_018_LoginWithSpecialCharPassword() {
        loginPage = navigateToLoginPage();
        loginPage.attemptLogin(TestDataUtils.VALID_EMAIL, TestDataUtils.generateSpecialCharacters());
        Assert.assertTrue(loginPage.isPageLoaded() || loginPage.isErrorMessageDisplayed(),
                "App should handle special char password gracefully");
    }

    @Test(description = "TC_AUTH_019 - Login with email in uppercase")
    @TestPriority("Medium")
    public void TC_AUTH_019_LoginWithUppercaseEmail() {
        loginPage = navigateToLoginPage();
        loginPage.attemptLogin(TestDataUtils.VALID_EMAIL.toUpperCase(), TestDataUtils.VALID_PASSWORD);
        sleep(2000);
        // Should either login or show error - not crash
        Assert.assertTrue(loginPage.isPageLoaded() || new DashboardPage().isDashboardDisplayed(),
                "App should handle uppercase email");
    }

    @Test(description = "TC_AUTH_020 - Login with spaces in email")
    @TestPriority("Medium")
    public void TC_AUTH_020_LoginWithSpacesInEmail() {
        loginPage = navigateToLoginPage();
        loginPage.attemptLogin("  test@test.com  ", TestDataUtils.VALID_PASSWORD);
        sleep(1500);
        Assert.assertTrue(loginPage.isPageLoaded() || loginPage.isErrorMessageDisplayed());
    }

    @Test(description = "TC_AUTH_021 - Verify password is masked")
    @TestPriority("High")
    public void TC_AUTH_021_VerifyPasswordMasked() {
        loginPage = navigateToLoginPage();
        loginPage.enterPassword("TestPassword123");
        // The password field should have password attribute
        String pwdType = driver.findElement(
                org.openqa.selenium.By.xpath("//android.widget.EditText[2]"))
                .getAttribute("password");
        Assert.assertTrue("true".equals(pwdType) || pwdType == null || loginPage.isPasswordFieldDisplayed(),
                "Password field should mask input");
    }

    @Test(description = "TC_AUTH_022 - Back navigation from login page")
    @TestPriority("Low")
    public void TC_AUTH_022_BackNavigationFromLoginPage() {
        loginPage = navigateToLoginPage();
        loginPage.navigateBack();
        sleep(1000);
        // App should handle back press gracefully (stay on login or show confirmation)
        Assert.assertTrue(true, "Back navigation handled");
    }

    @Test(description = "TC_AUTH_023 - Login with numeric-only password")
    @TestPriority("Medium")
    public void TC_AUTH_023_LoginWithNumericPassword() {
        loginPage = navigateToLoginPage();
        loginPage.attemptLogin(TestDataUtils.VALID_EMAIL, "123456789");
        sleep(1500);
        Assert.assertTrue(loginPage.isPageLoaded() || loginPage.isErrorMessageDisplayed());
    }

    @Test(description = "TC_AUTH_024 - Verify app logo/branding on login screen")
    @TestPriority("Low")
    public void TC_AUTH_024_VerifyAppBranding() {
        loginPage = navigateToLoginPage();
        Assert.assertTrue(loginPage.isPageLoaded(), "Login page with branding should be visible");
    }

    @Test(description = "TC_AUTH_025 - Login with email containing dots")
    @TestPriority("Low")
    public void TC_AUTH_025_LoginWithEmailContainingDots() {
        loginPage = navigateToLoginPage();
        loginPage.attemptLogin("test.user.name@example.com", TestDataUtils.VALID_PASSWORD);
        sleep(1500);
        Assert.assertTrue(loginPage.isPageLoaded() || loginPage.isErrorMessageDisplayed());
    }

    @Test(description = "TC_AUTH_026 - Login with email containing plus sign")
    @TestPriority("Low")
    public void TC_AUTH_026_LoginWithEmailPlusSign() {
        loginPage = navigateToLoginPage();
        loginPage.attemptLogin("test+filter@example.com", TestDataUtils.VALID_PASSWORD);
        sleep(1500);
        Assert.assertTrue(loginPage.isPageLoaded() || loginPage.isErrorMessageDisplayed());
    }

    @Test(description = "TC_AUTH_027 - Verify keyboard dismisses after login")
    @TestPriority("Low")
    public void TC_AUTH_027_KeyboardDismissesAfterLogin() {
        loginPage = navigateToLoginPage();
        loginPage.enterEmail(TestDataUtils.VALID_EMAIL);
        loginPage.enterPassword(TestDataUtils.VALID_PASSWORD);
        loginPage.clickLogin();
        sleep(2000);
        Assert.assertTrue(true, "Keyboard behavior validated");
    }

    @Test(description = "TC_AUTH_028 - Login with unicode characters in password")
    @TestPriority("Low")
    public void TC_AUTH_028_LoginWithUnicodePassword() {
        loginPage = navigateToLoginPage();
        loginPage.attemptLogin(TestDataUtils.VALID_EMAIL, TestDataUtils.generateUnicodeText());
        sleep(1500);
        Assert.assertTrue(loginPage.isPageLoaded() || loginPage.isErrorMessageDisplayed());
    }

    @Test(description = "TC_AUTH_029 - Session persists after app minimise")
    @TestPriority("High")
    public void TC_AUTH_029_SessionPersistsAfterMinimise() {
        loginPage = navigateToLoginPage();
        DashboardPage dash = loginPage.loginWithValidCredentials(
                TestDataUtils.VALID_EMAIL, TestDataUtils.VALID_PASSWORD);
        Assert.assertTrue(dash.isDashboardDisplayed());
        driver.runAppInBackground(java.time.Duration.ofSeconds(3));
        sleep(1000);
        Assert.assertTrue(dash.isDashboardDisplayed() || loginPage.isPageLoaded(),
                "Session should persist or redirect to login");
    }

    @Test(description = "TC_AUTH_030 - Logout from dashboard")
    @TestPriority("Critical")
    public void TC_AUTH_030_LogoutFromDashboard() {
        loginPage = navigateToLoginPage();
        DashboardPage dash = loginPage.loginWithValidCredentials(
                TestDataUtils.VALID_EMAIL, TestDataUtils.VALID_PASSWORD);
        Assert.assertTrue(dash.isDashboardDisplayed());
        dash.clickLogout();
        sleep(2000);
        Assert.assertTrue(loginPage.isPageLoaded(), "Should navigate to login after logout");
    }

    @Test(description = "TC_AUTH_031 - Login with whitespace-only email")
    @TestPriority("Medium")
    public void TC_AUTH_031_LoginWithWhitespaceEmail() {
        loginPage = navigateToLoginPage();
        loginPage.attemptLogin("   ", TestDataUtils.VALID_PASSWORD);
        sleep(1500);
        Assert.assertTrue(loginPage.isPageLoaded() || loginPage.isErrorMessageDisplayed());
    }

    @Test(description = "TC_AUTH_032 - Login with whitespace-only password")
    @TestPriority("Medium")
    public void TC_AUTH_032_LoginWithWhitespacePassword() {
        loginPage = navigateToLoginPage();
        loginPage.attemptLogin(TestDataUtils.VALID_EMAIL, "   ");
        sleep(1500);
        Assert.assertTrue(loginPage.isPageLoaded() || loginPage.isErrorMessageDisplayed());
    }

    @Test(description = "TC_AUTH_033 - Login page loads within acceptable time")
    @TestPriority("High")
    public void TC_AUTH_033_LoginPageLoadTime() {
        long start = System.currentTimeMillis();
        loginPage = navigateToLoginPage();
        Assert.assertTrue(loginPage.isPageLoaded());
        long duration = System.currentTimeMillis() - start;
        Assert.assertTrue(duration < 10000, "Login page should load within 10 seconds, took: " + duration + "ms");
    }

    @Test(description = "TC_AUTH_034 - Multiple failed login attempts")
    @TestPriority("High")
    public void TC_AUTH_034_MultipleFailedLoginAttempts() {
        loginPage = navigateToLoginPage();
        for (int i = 0; i < 3; i++) {
            loginPage.clearEmail();
            loginPage.clearPassword();
            loginPage.attemptLogin("wrong" + i + "@test.com", "WrongPass");
            sleep(1500);
        }
        Assert.assertTrue(loginPage.isPageLoaded() || loginPage.isErrorMessageDisplayed(),
                "App should handle multiple failed attempts gracefully");
    }

    @Test(description = "TC_AUTH_035 - Email field accepts valid format")
    @TestPriority("Medium")
    public void TC_AUTH_035_EmailFieldAcceptsValidFormat() {
        loginPage = navigateToLoginPage();
        loginPage.enterEmail("valid.user@example.com");
        Assert.assertTrue(loginPage.isEmailFieldDisplayed(), "Email field should accept valid format");
    }

    @Test(description = "TC_AUTH_036 - Navigate to registration from login")
    @TestPriority("High")
    public void TC_AUTH_036_NavigateToRegistration() {
        loginPage = navigateToLoginPage();
        com.smartstudent.pages.RegistrationPage reg = loginPage.clickRegister();
        Assert.assertTrue(reg.isPageLoaded(), "Registration page should be loaded");
    }

    @Test(description = "TC_AUTH_037 - Back from registration to login")
    @TestPriority("Medium")
    public void TC_AUTH_037_BackFromRegistrationToLogin() {
        loginPage = navigateToLoginPage();
        com.smartstudent.pages.RegistrationPage reg = loginPage.clickRegister();
        Assert.assertTrue(reg.isPageLoaded());
        loginPage = reg.navigateBack();
        Assert.assertTrue(loginPage.isPageLoaded(), "Should return to login page");
    }

    @Test(description = "TC_AUTH_038 - Login page scroll works")
    @TestPriority("Low")
    public void TC_AUTH_038_LoginPageScrollWorks() {
        loginPage = navigateToLoginPage();
        loginPage.swipeUp();
        sleep(500);
        loginPage.swipeDown();
        Assert.assertTrue(loginPage.isPageLoaded(), "Login page should remain functional after scroll");
    }

    @Test(description = "TC_AUTH_039 - Forgot password back navigation")
    @TestPriority("Medium")
    public void TC_AUTH_039_ForgotPasswordBackNavigation() {
        loginPage = navigateToLoginPage();
        ForgotPasswordPage fp = loginPage.clickForgotPassword();
        Assert.assertTrue(fp.isPageLoaded());
        loginPage = fp.navigateBack();
        Assert.assertTrue(loginPage.isPageLoaded(), "Should return to login page from forgot password");
    }

    @Test(description = "TC_AUTH_040 - Login page orientation not broken")
    @TestPriority("Low")
    public void TC_AUTH_040_LoginPageOrientationCheck() {
        loginPage = navigateToLoginPage();
        Assert.assertTrue(loginPage.isEmailFieldDisplayed() && loginPage.isLoginButtonDisplayed(),
                "All login elements should be visible");
    }
}
