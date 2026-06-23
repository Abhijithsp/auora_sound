allprojects {
    repositories {
        google()
        mavenCentral()
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

subprojects {
    plugins.withId("com.android.library") {
        val android = extensions.getByType<com.android.build.gradle.LibraryExtension>()
        
        // Dynamically set namespace from AndroidManifest.xml if missing
        if (android.namespace == null) {
            val manifestFile = file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                val manifestXml = manifestFile.readText()
                val packageMatcher = java.util.regex.Pattern.compile("package=\"([^\"]+)\"").matcher(manifestXml)
                if (packageMatcher.find()) {
                    val pkg = packageMatcher.group(1)
                    android.namespace = pkg
                    logger.lifecycle("Dynamically set namespace for library subproject :${project.name} to $pkg")
                }
            }
        }
    }

    val configureAndroid = {
        val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        android?.apply {
            val currentSdk = compileSdkVersion
            if (currentSdk != null) {
                val sdkVersionStr = currentSdk.replace("android-", "")
                val sdkVersion = sdkVersionStr.toIntOrNull()
                if (sdkVersion != null && sdkVersion < 36) {
                    compileSdkVersion(36)
                    logger.lifecycle("Forced compileSdkVersion for :${project.name} from $currentSdk to 36")
                }
            }
        }
    }

    if (project.state.executed) {
        configureAndroid()
    } else {
        project.afterEvaluate {
            configureAndroid()
        }
    }
    
    plugins.withId("org.jetbrains.kotlin.android") {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            try {
                // Dynamically match Kotlin's jvmTarget to the Android extension's targetCompatibility
                val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
                val targetCompatibility = android?.compileOptions?.targetCompatibility
                if (targetCompatibility != null) {
                    val jvmTargetVal = when (targetCompatibility) {
                        JavaVersion.VERSION_1_8 -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
                        JavaVersion.VERSION_11 -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
                        JavaVersion.VERSION_17 -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                        JavaVersion.VERSION_21 -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21
                        else -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                    }
                    compilerOptions {
                        jvmTarget.set(jvmTargetVal)
                    }
                } else {
                    compilerOptions {
                        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
                    }
                }
            } catch (e: Exception) {
                // Already finalized or compilation options not accessible
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
