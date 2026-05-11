import Dependencies._

enablePlugins(GatlingPlugin)

lazy val root = (project in file("."))
  .settings(
    inThisBuild(
      List(
        organization := "{{ .Package }}",
        scalaVersion := "{{ .ScalaVersion }}",
        version      := "0.1.0",
      ),
    ),
    name := "{{ .Name }}",
{{- if eq .KafkaPluginEnabled "true" }}
    resolvers += "Confluent" at "https://packages.confluent.io/maven/",
{{- end }}
    libraryDependencies ++= gatling,
    libraryDependencies ++= gatlingPicatinny,
{{- if eq .KafkaPluginEnabled "true" }}
    libraryDependencies ++= kafkaPlugin,
{{- end }}
{{- if eq .JdbcPluginEnabled "true" }}
    libraryDependencies ++= jdbcPlugin,
{{- end }}
{{- if eq .AmqpPluginEnabled "true" }}
    libraryDependencies ++= amqpPlugin,
{{- end }}
    libraryDependencies ++= janino,
      scalacOptions ++= Seq (
        "-encoding",
        "UTF-8",
        "-Xfatal-warnings",
        "-deprecation",
        "-feature",
        "-unchecked",
        "-language:implicitConversions",
        "-language:higherKinds",
        "-language:existentials",
        "-language:postfixOps"
      ),
  )
