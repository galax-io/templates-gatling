import sbt._

object Dependencies {
  lazy val gatling: Seq[ModuleID] = Seq(
    "io.gatling.highcharts" % "gatling-charts-highcharts",
    "io.gatling"            % "gatling-test-framework",
  ).map(_ % "{{ .GatlingVersion }}" % Test)

  lazy val gatlingPicatinny: Seq[ModuleID] = Seq("org.galaxio" %% "gatling-picatinny" % "{{ .GatlingPicatinnyVersion }}")
  lazy val janino: Seq[ModuleID]           = Seq("org.codehaus.janino" % "janino" % "3.1.12")
{{- if eq .KafkaPluginEnabled "true" }}
  lazy val kafkaPlugin: Seq[ModuleID] = Seq(
    "org.galaxio" %% "gatling-kafka-plugin" % "{{ .KafkaPluginVersion }}",
    "org.apache.kafka" % "kafka-streams" % "{{ .KafkaStreamsVersion }}",
    "com.sksamuel.avro4s" %% "avro4s-core" % "4.1.2",
  )
{{- end }}
{{- if eq .JdbcPluginEnabled "true" }}
  lazy val jdbcPlugin: Seq[ModuleID] = Seq("org.galaxio" %% "gatling-jdbc-plugin" % "{{ .JdbcPluginVersion }}")
{{- end }}
{{- if eq .AmqpPluginEnabled "true" }}
  lazy val amqpPlugin: Seq[ModuleID] = Seq("org.galaxio" %% "gatling-amqp-plugin" % "{{ .AmqpPluginVersion }}")
{{- end }}
}
