plugins {
    kotlin("jvm") version "{{ .KotlinVersion }}"
    id("io.gatling.gradle") version "{{ .GatlingGradlePluginVersion }}"
}

group = "{{ .Package }}"
version = "0.1.0"

java {
    sourceCompatibility = JavaVersion.toVersion("{{ .JavaVersion }}")
    targetCompatibility = JavaVersion.toVersion("{{ .JavaVersion }}")
}

gatling {
    gatlingVersion = "{{ .GatlingVersion }}"
    includeMainOutput = false
    includeTestOutput = false
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.fromTarget("{{ .JavaVersion }}"))
    }
}

repositories {
    mavenLocal()
    mavenCentral()
}

dependencies {
    gatlingImplementation(kotlin("stdlib"))
    gatlingImplementation("org.galaxio:gatling-picatinny_2.13:{{ .GatlingPicatinnyVersion }}")
    gatlingImplementation("io.gatling.highcharts:gatling-charts-highcharts:{{ .GatlingVersion }}")
    gatlingImplementation("io.gatling:gatling-test-framework:{{ .GatlingVersion }}")
    gatlingImplementation("org.codehaus.janino:janino:3.1.12")
}
