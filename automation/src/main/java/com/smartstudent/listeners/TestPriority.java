package com.smartstudent.listeners;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Custom annotation to mark test priority level.
 * Values: "Critical", "High", "Medium", "Low"
 */
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface TestPriority {
    String value() default "Medium";
}
