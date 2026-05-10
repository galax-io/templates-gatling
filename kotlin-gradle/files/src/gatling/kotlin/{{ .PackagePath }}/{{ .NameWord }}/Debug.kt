package {{ .Package }}.{{ .NameWord }}

import io.gatling.javaapi.core.CoreDsl.atOnceUsers
import io.gatling.javaapi.core.Simulation
import org.galaxio.gatling.javaapi.SimulationConfig.testDuration
import org.galaxio.gatling.javaapi.Utility
import {{ .Package }}.{{ .NameWord }}.scenarios.HttpScenario
{{- if eq .KafkaPluginEnabled "true" }}
import {{ .Package }}.{{ .NameWord }}.scenarios.KafkaScenario
{{- end }}
{{- if eq .JdbcPluginEnabled "true" }}
import {{ .Package }}.{{ .NameWord }}.scenarios.JdbcScenario
{{- end }}
{{- if eq .AmqpPluginEnabled "true" }}
import {{ .Package }}.{{ .NameWord }}.scenarios.AmqpScenario
{{- end }}

class Debug : Simulation() {
    init {
        Utility.diagnostics()

        setUp(
            HttpScenario.create()
                .injectOpen(atOnceUsers(1))
{{- if eq .KafkaPluginEnabled "true" }}
            , KafkaScenario.create()
                .injectOpen(atOnceUsers(1))
{{- end }}
{{- if eq .JdbcPluginEnabled "true" }}
            , JdbcScenario.create()
                .injectOpen(atOnceUsers(1))
{{- end }}
{{- if eq .AmqpPluginEnabled "true" }}
            , AmqpScenario.create()
                .injectOpen(atOnceUsers(1))
{{- end }}
        ).protocols(
            Performance.httpProtocol
{{- if eq .KafkaPluginEnabled "true" }}
            , Performance.kafkaProtocol
{{- end }}
{{- if eq .JdbcPluginEnabled "true" }}
            , Performance.jdbcProtocol
{{- end }}
{{- if eq .AmqpPluginEnabled "true" }}
            , Performance.amqpProtocol
{{- end }}
        )
            .maxDuration(testDuration())
    }
}
