allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")

    // Paksa semua plugin memakai compileSdk minimal 36
    afterEvaluate {
        val androidExt = extensions.findByName("android") ?: return@afterEvaluate
        val getCompileSdk = androidExt.javaClass.methods.find { it.name == "getCompileSdk" }
        val setCompileSdk = androidExt.javaClass.methods.find {
            it.name == "compileSdk" &&
            it.parameterTypes.size == 1 &&
            it.parameterTypes[0] == Int::class.java
        }
        if (getCompileSdk != null && setCompileSdk != null) {
            val current = getCompileSdk.invoke(androidExt) as? Int ?: 0
            if (current < 36) {
                setCompileSdk.invoke(androidExt, 36)
                logger.lifecycle("Overriding compileSdk for ${project.name} from $current to 36")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}