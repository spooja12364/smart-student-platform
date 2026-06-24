allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    if (name != "app") {
        extra.set("flutter", mapOf(
            "compileSdkVersion" to 35,
            "minSdkVersion" to 23,
            "targetSdkVersion" to 35,
            "buildToolsVersion" to "34.0.0"
        ))
    }
    afterEvaluate {
        extensions.findByName("android")?.let { ext ->
            try {
                ext.javaClass.getMethod("setBuildToolsVersion", String::class.java).invoke(ext, "34.0.0")
            } catch (e: Exception) {
                // Ignore if method not found
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
