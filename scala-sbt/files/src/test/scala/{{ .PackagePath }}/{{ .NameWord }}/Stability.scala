package {{ .Package }}.{{ .NameWord }}

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

class Stability extends Simulation {
  val injector = Seq(
    rampUsersPerSec(0) to intensity during rampDuration,
    constantUsersPerSec(intensity) during stageDuration,
  )

  org.galaxio.gatling.utils.Utility.banner(injector)

  setUp(
    HttpScenario().inject(
      injector,
    ),
{{- if eq .KafkaPluginEnabled "true" }}
    KafkaScenario().inject(
      injector,
    ),
{{- end }}
{{- if eq .JdbcPluginEnabled "true" }}
    JdbcScenario().inject(
      injector,
    ),
{{- end }}
{{- if eq .AmqpPluginEnabled "true" }}
    AmqpScenario().inject(
      injector,
    ),
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
