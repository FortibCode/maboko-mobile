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

// Supprimé : subprojects { project.evaluationDependsOn(":app") } 
// car il provoque des blocages avec les versions récentes de Flutter et Gradle.

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
