buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.4")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
        kotlinOptions {
            jvmTarget = "1.8"
        }
    }
}

// Custom build directory configuration
val newBuildDir = layout.buildDirectory.dir("../../build").get()
layout.buildDirectory.set(newBuildDir)

subprojects {
    // Set custom build directory for each subproject
    layout.buildDirectory.set(newBuildDir.dir(project.name))
    
    // Ensure app project is evaluated first
    afterEvaluate {
        if (project != rootProject && project.path != ":app") {
            evaluationDependsOn(":app")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(layout.buildDirectory)
    delete("${rootProject.projectDir}/build")
}