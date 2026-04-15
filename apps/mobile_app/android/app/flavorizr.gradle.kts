import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("dev") {
            dimension = "flavor-type"
            applicationId = "com.example.fintrack.dev"
            resValue(type = "string", name = "app_name", value = "FinTrack Dev")
        }
        create("staging") {
            dimension = "flavor-type"
            applicationId = "com.example.fintrack.staging"
            resValue(type = "string", name = "app_name", value = "FinTrack Stg")
        }
        create("prod") {
            dimension = "flavor-type"
            applicationId = "com.example.fintrack"
            resValue(type = "string", name = "app_name", value = "FinTrack")
        }
    }
}