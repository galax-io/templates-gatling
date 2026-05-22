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
{{- if eq .KafkaPluginEnabled "true" }}
    maven("https://packages.confluent.io/maven/")
{{- end }}
}

dependencies {
    gatlingImplementation(kotlin("stdlib"))
    gatlingImplementation("org.galaxio:gatling-picatinny_2.13:{{ .GatlingPicatinnyVersion }}")
{{- if eq .KafkaPluginEnabled "true" }}
    gatlingImplementation("org.galaxio:gatling-kafka-plugin_2.13:{{ .KafkaPluginVersion }}")
    gatlingImplementation("org.apache.kafka:kafka-streams:{{ .KafkaStreamsVersion }}")
{{- end }}
{{- if eq .JdbcPluginEnabled "true" }}
    gatlingImplementation("org.galaxio:gatling-jdbc-plugin_2.13:{{ .JdbcPluginVersion }}")
    gatlingImplementation("org.postgresql:postgresql:42.7.5")
{{- end }}
{{- if eq .AmqpPluginEnabled "true" }}
    gatlingImplementation("org.galaxio:gatling-amqp-plugin_2.13:{{ .AmqpPluginVersion }}")
{{- end }}
    gatlingImplementation("io.gatling.highcharts:gatling-charts-highcharts:{{ .GatlingVersion }}")
    gatlingImplementation("io.gatling:gatling-test-framework:{{ .GatlingVersion }}")
    gatlingImplementation("org.codehaus.janino:janino:3.1.12")
}
