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
    // This machine only has build-tools 36 installed. Flutter plugins default to
    // 35, so pin every Android library module to the available build tools.
    plugins.withId("com.android.library") {
        val androidExtension = extensions.findByName("android")
        androidExtension?.javaClass?.methods
            ?.firstOrNull { it.name == "setBuildToolsVersion" && it.parameterCount == 1 }
            ?.invoke(androidExtension, "36.0.0")
    }
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
