package {{ .Package }}.{{ .NameWord }}

import io.gatling.http.Predef._
import io.gatling.core.Predef._
{{- if eq .KafkaPluginEnabled "true" }}
import org.galaxio.gatling.kafka.Predef._
{{- end }}
{{- if eq .JdbcPluginEnabled "true" }}
import org.galaxio.gatling.jdbc.Predef._
{{- end }}
{{- if eq .AmqpPluginEnabled "true" }}
import org.galaxio.gatling.amqp.Predef._
{{- end }}
import org.galaxio.gatling.config.SimulationConfig._
import {{ .Package }}.{{ .NameWord }}.scenarios._

class Debug extends Simulation {
  org.galaxio.gatling.utils.Utility.diagnostics()

  setUp(
    HttpScenario().inject(atOnceUsers(1)),
{{- if eq .KafkaPluginEnabled "true" }}
    KafkaScenario().inject(atOnceUsers(1)),
{{- end }}
{{- if eq .JdbcPluginEnabled "true" }}
    JdbcScenario().inject(atOnceUsers(1)),
{{- end }}
{{- if eq .AmqpPluginEnabled "true" }}
    AmqpScenario().inject(atOnceUsers(1)),
{{- end }}
  ).protocols(
    httpProtocol,
{{- if eq .KafkaPluginEnabled "true" }}
    kafkaProtocol,
{{- end }}
{{- if eq .JdbcPluginEnabled "true" }}
    jdbcProtocol,
{{- end }}
{{- if eq .AmqpPluginEnabled "true" }}
    amqpProtocol,
{{- end }}
  ).maxDuration(testDuration)

}
