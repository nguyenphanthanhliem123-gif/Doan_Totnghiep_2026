import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.gradle.api.tasks.compile.JavaCompile

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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

allprojects {
    tasks.withType<KotlinCompile>().configureEach {
        // Nhóm các thư viện cũ cần chạy ở chuẩn 1.8
        val oldPlugins = listOf(
            "add_2_calendar", 
            "flutter_facebook_auth", 
            "jitsi_meet_wrapper"
        )
        
        if (project.name in oldPlugins) {
            kotlinOptions.jvmTarget = "1.8"
        } else {
            // Các thư viện mới và phần còn lại chạy ở chuẩn 17
            kotlinOptions.jvmTarget = "17"
        }
    }
}
