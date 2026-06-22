package com.smartstudent.utils;

import com.github.javafaker.Faker;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Random;

/**
 * Test data generator using JavaFaker and custom logic
 * for Smart Student Platform domain objects.
 */
public class TestDataUtils {

    private static final Faker faker = new Faker();
    private static final Random random = new Random();

    // ── User Data ─────────────────────────────────────────────────

    public static String generateFullName() {
        return faker.name().fullName();
    }

    public static String generateFirstName() {
        return faker.name().firstName();
    }

    public static String generateEmail() {
        return "test_" + System.currentTimeMillis() + "@smartstudent.test";
    }

    public static String generateUniqueEmail(String prefix) {
        return prefix + "_" + System.currentTimeMillis() + "@smartstudent.test";
    }

    public static String generateValidPassword() {
        return "Test@" + faker.number().digits(4) + "!";
    }

    public static String generateWeakPassword() {
        return "1234";
    }

    public static String generateShortPassword() {
        return "Ab1!";
    }

    public static String generatePasswordWithoutSpecialChar() {
        return "TestPassword123";
    }

    public static String generatePasswordWithoutUppercase() {
        return "test@12345";
    }

    // ── Academic Data ─────────────────────────────────────────────

    public static String generateSkill() {
        String[] skills = {
            "Java", "Python", "JavaScript", "Flutter", "React",
            "Machine Learning", "Data Science", "Android Development",
            "iOS Development", "Web Development", "UI/UX Design",
            "SQL", "MongoDB", "Firebase", "DevOps", "Cloud Computing",
            "Cybersecurity", "Blockchain", "AR/VR", "Game Development"
        };
        return skills[random.nextInt(skills.length)];
    }

    public static String generateBio() {
        return "Student passionate about " + generateSkill() + " and " + generateSkill() + ". "
                + faker.lorem().sentence(8);
    }

    public static String generateCourseTitle() {
        String[] courses = {
            "Introduction to Programming", "Data Structures & Algorithms",
            "Mobile App Development", "Machine Learning Fundamentals",
            "Database Management", "Software Engineering", "Web Technologies",
            "Computer Networks", "Operating Systems", "Artificial Intelligence"
        };
        return courses[random.nextInt(courses.length)];
    }

    public static String generateUniversity() {
        return faker.university().name();
    }

    public static String generateDegree() {
        String[] degrees = {"B.Tech", "M.Tech", "BCA", "MCA", "B.Sc", "M.Sc", "MBA"};
        return degrees[random.nextInt(degrees.length)];
    }

    public static int generateGraduationYear() {
        return LocalDate.now().getYear() + random.nextInt(5);
    }

    // ── Message/Content Data ──────────────────────────────────────

    public static String generateMessage() {
        return faker.lorem().sentence(10);
    }

    public static String generateGroupName() {
        return "Study Group - " + generateSkill() + " " + System.currentTimeMillis() % 1000;
    }

    public static String generateSearchQuery() {
        return generateSkill();
    }

    public static String generateLongText() {
        return faker.lorem().paragraph(5);
    }

    public static String generateShortText() {
        return faker.lorem().word();
    }

    // ── Edge Cases ────────────────────────────────────────────────

    public static String generateSQLInjection() {
        return "'; DROP TABLE users; --";
    }

    public static String generateXSSPayload() {
        return "<script>alert('XSS')</script>";
    }

    public static String generateSpecialCharacters() {
        return "!@#$%^&*()_+-=[]{}|;':\",./<>?";
    }

    public static String generateUnicodeText() {
        return "测试用户 テストユーザー 사용자 테스트";
    }

    public static String generateVeryLongText() {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 1000; i++) sb.append("a");
        return sb.toString();
    }

    public static String generateEmptyString() {
        return "";
    }

    public static String generateWhitespaceOnlyString() {
        return "   ";
    }

    // ── Invalid Emails ────────────────────────────────────────────

    public static String[] getInvalidEmails() {
        return new String[]{
            "notanemail",
            "missing@domain",
            "@nodomain.com",
            "spaces in@email.com",
            "double@@email.com",
            "email@",
            "",
            "   ",
            "toolong".repeat(30) + "@domain.com",
            "email@.com",
            "email@domain.",
        };
    }

    public static String getInvalidEmail(int index) {
        String[] emails = getInvalidEmails();
        return emails[index % emails.length];
    }

    // ── Numbers ───────────────────────────────────────────────────

    public static String generatePhoneNumber() {
        return "+91" + faker.number().digits(10);
    }

    public static int generateRandomInt(int min, int max) {
        return faker.number().numberBetween(min, max);
    }

    // ── Credentials (static) ──────────────────────────────────────

    public static final String VALID_EMAIL = "testuser@smartstudent.com";
    public static final String VALID_PASSWORD = "Test@12345";
    public static final String INVALID_EMAIL = "invalid@notexist.com";
    public static final String INVALID_PASSWORD = "WrongPass@999";
    public static final String EMPTY_STRING = "";
}
