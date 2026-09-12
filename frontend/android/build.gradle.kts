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
    if (project.name == "mapbox_maps_flutter") {
        pluginManager.apply("org.jetbrains.kotlin.android")
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}
subprojects {
    if (name != "app") {
        val configureSdk: () -> Unit = {
            val android = project.extensions.findByName("android")
            if (android != null) {
                try {
                    val compileSdkGetter = android.javaClass.methods.firstOrNull { it.name == "getCompileSdkVersion" || it.name == "getCompileSdk" }
                    val currentCompileSdk = when (val res = compileSdkGetter?.invoke(android)) {
                        is Number -> res.toInt()
                        is String -> res.replace("android-", "").toIntOrNull() ?: 0
                        else -> 0
                    }
                    if (currentCompileSdk in 1..34) {
                        val setCompileSdk = android.javaClass.methods.firstOrNull {
                            it.name == "setCompileSdk" && it.parameterTypes.size == 1
                        }
                        if (setCompileSdk != null) {
                            setCompileSdk.invoke(android, 35)
                        } else {
                            val compileSdkVersion = android.javaClass.methods.firstOrNull {
                                it.name == "compileSdkVersion" && it.parameterTypes.size == 1
                            }
                            compileSdkVersion?.invoke(android, 35)
                        }
                    }
                } catch (_: Throwable) {}
            }
        }
        if (state.executed) {
            configureSdk()
        } else {
            afterEvaluate { configureSdk() }
        }
    }
}
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        val javaCompile = tasks.withType<JavaCompile>().firstOrNull()
        val target = javaCompile?.targetCompatibility
        when (target) {
            "1.8", "8" -> compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8)
            "11" -> compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
            "17" -> compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            else -> {}
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
