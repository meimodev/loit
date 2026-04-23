import org.jetbrains.kotlin.gradle.dsl.KotlinVersion
import org.jetbrains.kotlin.gradle.tasks.KotlinCompilationTask

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

    // Kotlin 2.2 rejects `languageVersion = 1.6`, which some Flutter plugins
    // (notably sentry_flutter 8.x) still declare in their own build.gradle.
    // Force every Kotlin compilation in every subproject to language/api 1.8
    // so plugin builds succeed without needing to wait for each plugin to
    // ship an updated Kotlin configuration.
    tasks.withType<KotlinCompilationTask<*>>().configureEach {
        compilerOptions {
            languageVersion.set(KotlinVersion.KOTLIN_1_8)
            apiVersion.set(KotlinVersion.KOTLIN_1_8)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
