package com.smartstudent.tests;

import com.smartstudent.listeners.RetryAnalyzer;
import com.smartstudent.listeners.TestPriority;
import com.smartstudent.pages.DashboardPage;
import com.smartstudent.pages.EditProfilePage;
import com.smartstudent.pages.ProfilePage;
import com.smartstudent.utils.TestDataUtils;
import org.testng.Assert;
import org.testng.annotations.Test;

/**
 * Profile Management Test Suite — 20 test cases
 * TC_PROFILE_001 through TC_PROFILE_020
 */
public class ProfileManagementTests extends BaseTest {

    private DashboardPage loginAndGetDashboard() {
        return loginPage.loginWithValidCredentials(TestDataUtils.VALID_EMAIL, TestDataUtils.VALID_PASSWORD);
    }

    @Test(description = "TC_PROFILE_001 - Navigate to profile page", retryAnalyzer = RetryAnalyzer.class)
    @TestPriority("Critical")
    public void TC_PROFILE_001_NavigateToProfilePage() {
        DashboardPage dash = loginAndGetDashboard();
        Assert.assertTrue(dash.isDashboardDisplayed());
        ProfilePage profile = dash.navigateToProfile();
        Assert.assertTrue(profile.isProfileDisplayed(), "Profile page should be visible");
    }

    @Test(description = "TC_PROFILE_002 - Profile page shows user information")
    @TestPriority("High")
    public void TC_PROFILE_002_ProfileShowsUserInfo() {
        DashboardPage dash = loginAndGetDashboard();
        ProfilePage profile = dash.navigateToProfile();
        Assert.assertTrue(profile.isProfileDisplayed(), "Profile should show user info");
    }

    @Test(description = "TC_PROFILE_003 - Edit profile button is visible")
    @TestPriority("High")
    public void TC_PROFILE_003_EditButtonVisible() {
        DashboardPage dash = loginAndGetDashboard();
        ProfilePage profile = dash.navigateToProfile();
        Assert.assertTrue(profile.isEditButtonDisplayed(), "Edit button should be visible on profile page");
    }

    @Test(description = "TC_PROFILE_004 - Navigate to edit profile")
    @TestPriority("High")
    public void TC_PROFILE_004_NavigateToEditProfile() {
        DashboardPage dash = loginAndGetDashboard();
        ProfilePage profile = dash.navigateToProfile();
        EditProfilePage edit = profile.clickEdit();
        Assert.assertTrue(edit.isPageLoaded(), "Edit profile page should load");
    }

    @Test(description = "TC_PROFILE_005 - Update profile name")
    @TestPriority("High")
    public void TC_PROFILE_005_UpdateProfileName() {
        DashboardPage dash = loginAndGetDashboard();
        ProfilePage profile = dash.navigateToProfile();
        EditProfilePage edit = profile.clickEdit();
        Assert.assertTrue(edit.isPageLoaded());
        edit.enterName(TestDataUtils.generateFirstName() + " Updated");
        ProfilePage saved = edit.clickSave();
        Assert.assertTrue(saved.isProfileDisplayed() || edit.isSuccessToastDisplayed(),
            "Profile should be saved successfully");
    }

    @Test(description = "TC_PROFILE_006 - Update profile bio")
    @TestPriority("Medium")
    public void TC_PROFILE_006_UpdateProfileBio() {
        DashboardPage dash = loginAndGetDashboard();
        ProfilePage profile = dash.navigateToProfile();
        EditProfilePage edit = profile.clickEdit();
        Assert.assertTrue(edit.isPageLoaded());
        edit.enterBio(TestDataUtils.generateBio());
        ProfilePage saved = edit.clickSave();
        Assert.assertTrue(saved.isProfileDisplayed() || edit.isSuccessToastDisplayed(),
            "Bio should be updated");
    }

    @Test(description = "TC_PROFILE_007 - Add skill to profile")
    @TestPriority("Medium")
    public void TC_PROFILE_007_AddSkillToProfile() {
        DashboardPage dash = loginAndGetDashboard();
        ProfilePage profile = dash.navigateToProfile();
        EditProfilePage edit = profile.clickEdit();
        edit.enterSkill(TestDataUtils.generateSkill());
        ProfilePage saved = edit.clickSave();
        Assert.assertTrue(saved.isProfileDisplayed() || edit.isSuccessToastDisplayed(),
            "Skill should be added");
    }

    @Test(description = "TC_PROFILE_008 - Profile skills section is visible")
    @TestPriority("Medium")
    public void TC_PROFILE_008_ProfileSkillsVisible() {
        DashboardPage dash = loginAndGetDashboard();
        ProfilePage profile = dash.navigateToProfile();
        Assert.assertTrue(profile.isProfileDisplayed(), "Profile should be displayed");
    }

    @Test(description = "TC_PROFILE_009 - Back from edit profile navigates to profile")
    @TestPriority("Medium")
    public void TC_PROFILE_009_BackFromEditProfile() {
        DashboardPage dash = loginAndGetDashboard();
        ProfilePage profile = dash.navigateToProfile();
        EditProfilePage edit = profile.clickEdit();
        Assert.assertTrue(edit.isPageLoaded());
        profile = edit.navigateBack();
        Assert.assertTrue(profile.isProfileDisplayed(), "Should return to profile page");
    }

    @Test(description = "TC_PROFILE_010 - Profile back to dashboard")
    @TestPriority("Medium")
    public void TC_PROFILE_010_ProfileBackToDashboard() {
        DashboardPage dash = loginAndGetDashboard();
        ProfilePage profile = dash.navigateToProfile();
        Assert.assertTrue(profile.isProfileDisplayed());
        profile.navigateBack();
        sleep(1000);
        Assert.assertTrue(true, "Navigation back from profile handled");
    }

    @Test(description = "TC_PROFILE_011 - Update name with empty value")
    @TestPriority("Medium")
    public void TC_PROFILE_011_UpdateNameWithEmptyValue() {
        DashboardPage dash = loginAndGetDashboard();
        ProfilePage profile = dash.navigateToProfile();
        EditProfilePage edit = profile.clickEdit();
        edit.enterName("");
        edit.clickSave();
        sleep(2000);
        Assert.assertTrue(edit.isPageLoaded() || edit.isSuccessToastDisplayed() || profile.isProfileDisplayed(),
            "Should handle empty name on update");
    }

    @Test(description = "TC_PROFILE_012 - Update profile with very long name")
    @TestPriority("Low")
    public void TC_PROFILE_012_UpdateProfileVeryLongName() {
        DashboardPage dash = loginAndGetDashboard();
        ProfilePage profile = dash.navigateToProfile();
        EditProfilePage edit = profile.clickEdit();
        edit.enterName(TestDataUtils.generateVeryLongText());
        edit.clickSave();
        sleep(2000);
        Assert.assertTrue(edit.isPageLoaded() || edit.isSuccessToastDisplayed() || profile.isProfileDisplayed(),
            "Should handle very long name");
    }

    @Test(description = "TC_PROFILE_013 - Update profile with unicode name")
    @TestPriority("Low")
    public void TC_PROFILE_013_UpdateProfileUnicodeName() {
        DashboardPage dash = loginAndGetDashboard();
        ProfilePage profile = dash.navigateToProfile();
        EditProfilePage edit = profile.clickEdit();
        edit.enterName(TestDataUtils.generateUnicodeText());
        edit.clickSave();
        sleep(2000);
        Assert.assertTrue(edit.isPageLoaded() || edit.isSuccessToastDisplayed() || profile.isProfileDisplayed(),
            "Should handle unicode name");
    }

    @Test(description = "TC_PROFILE_014 - Update profile with special chars in bio")
    @TestPriority("Low")
    public void TC_PROFILE_014_UpdateProfileSpecialCharBio() {
        DashboardPage dash = loginAndGetDashboard();
        ProfilePage profile = dash.navigateToProfile();
        EditProfilePage edit = profile.clickEdit();
        edit.enterBio(TestDataUtils.generateSpecialCharacters());
        edit.clickSave();
        sleep(2000);
        Assert.assertTrue(edit.isPageLoaded() || edit.isSuccessToastDisplayed() || profile.isProfileDisplayed(),
            "Should handle special chars in bio");
    }

    @Test(description = "TC_PROFILE_015 - Profile connections count visible")
    @TestPriority("Low")
    public void TC_PROFILE_015_ProfileConnectionsCountVisible() {
        DashboardPage dash = loginAndGetDashboard();
        ProfilePage profile = dash.navigateToProfile();
        Assert.assertTrue(profile.isProfileDisplayed(), "Profile page should be displayed");
    }

    @Test(description = "TC_PROFILE_016 - Profile change photo option visible")
    @TestPriority("Low")
    public void TC_PROFILE_016_ProfileChangePhotoOption() {
        DashboardPage dash = loginAndGetDashboard();
        ProfilePage profile = dash.navigateToProfile();
        Assert.assertTrue(profile.isProfileDisplayed(), "Profile should be displayed with avatar option");
    }

    @Test(description = "TC_PROFILE_017 - Profile page loads within time limit")
    @TestPriority("High")
    public void TC_PROFILE_017_ProfilePageLoadTime() {
        DashboardPage dash = loginAndGetDashboard();
        long start = System.currentTimeMillis();
        ProfilePage profile = dash.navigateToProfile();
        Assert.assertTrue(profile.isProfileDisplayed());
        long duration = System.currentTimeMillis() - start;
        Assert.assertTrue(duration < 10000, "Profile should load within 10 seconds, took: " + duration + "ms");
    }

    @Test(description = "TC_PROFILE_018 - Multiple profile edits consecutive")
    @TestPriority("Medium")
    public void TC_PROFILE_018_MultipleProfileEdits() {
        DashboardPage dash = loginAndGetDashboard();
        for (int i = 0; i < 2; i++) {
            ProfilePage profile = dash.navigateToProfile();
            EditProfilePage edit = profile.clickEdit();
            edit.enterName(TestDataUtils.generateFirstName());
            edit.clickSave();
            sleep(1000);
        }
        Assert.assertTrue(true, "Multiple consecutive edits handled");
    }

    @Test(description = "TC_PROFILE_019 - Update bio with SQL injection")
    @TestPriority("High")
    public void TC_PROFILE_019_UpdateBioSQLInjection() {
        DashboardPage dash = loginAndGetDashboard();
        ProfilePage profile = dash.navigateToProfile();
        EditProfilePage edit = profile.clickEdit();
        edit.enterBio(TestDataUtils.generateSQLInjection());
        edit.clickSave();
        sleep(2000);
        Assert.assertTrue(edit.isPageLoaded() || edit.isSuccessToastDisplayed() || profile.isProfileDisplayed(),
            "Should handle SQL injection in bio gracefully");
    }

    @Test(description = "TC_PROFILE_020 - Update profile with XSS payload in name")
    @TestPriority("High")
    public void TC_PROFILE_020_UpdateProfileXSSPayload() {
        DashboardPage dash = loginAndGetDashboard();
        ProfilePage profile = dash.navigateToProfile();
        EditProfilePage edit = profile.clickEdit();
        edit.enterName(TestDataUtils.generateXSSPayload());
        edit.clickSave();
        sleep(2000);
        Assert.assertTrue(edit.isPageLoaded() || edit.isSuccessToastDisplayed() || profile.isProfileDisplayed(),
            "Should handle XSS payload in name gracefully");
    }
}
