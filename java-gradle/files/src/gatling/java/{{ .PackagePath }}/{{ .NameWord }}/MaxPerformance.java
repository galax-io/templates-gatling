package {{ .Package }}.{{ .NameWord }};

import io.gatling.javaapi.core.OpenInjectionStep;
import io.gatling.javaapi.core.Simulation;
import org.galaxio.gatling.javaapi.SimulationConfig;
import org.galaxio.gatling.javaapi.Utility;
import {{ .Package }}.{{ .NameWord }}.scenarios.HttpScenario;
{{- if eq .KafkaPluginEnabled "true" }}
import {{ .Package }}.{{ .NameWord }}.scenarios.KafkaScenario;
{{- end }}
{{- if eq .JdbcPluginEnabled "true" }}
import {{ .Package }}.{{ .NameWord }}.scenarios.JdbcScenario;
{{- end }}
{{- if eq .AmqpPluginEnabled "true" }}
import {{ .Package }}.{{ .NameWord }}.scenarios.AmqpScenario;
{{- end }}

import static io.gatling.javaapi.core.CoreDsl.incrementUsersPerSec;

public class MaxPerformance extends Simulation {

    {
        OpenInjectionStep[] injectionProfile = new OpenInjectionStep[]{
                incrementUsersPerSec(SimulationConfig.intensity() / SimulationConfig.stagesNumber())
                        .times(SimulationConfig.stagesNumber())
                        .eachLevelLasting(SimulationConfig.stageDuration())
                        .separatedByRampsLasting(SimulationConfig.rampDuration())
                        .startingFrom(0.0)
        };

        Utility.banner(injectionProfile);

        setUp(
                HttpScenario.create()
                        .injectOpen(injectionProfile)
{{- if eq .KafkaPluginEnabled "true" }}
                , KafkaScenario.create()
                        .injectOpen(injectionProfile)
{{- end }}
{{- if eq .JdbcPluginEnabled "true" }}
                , JdbcScenario.create()
                        .injectOpen(injectionProfile)
{{- end }}
{{- if eq .AmqpPluginEnabled "true" }}
                , AmqpScenario.create()
                        .injectOpen(injectionProfile)
{{- end }}
        ).protocols(
                Performance.httpProtocol
{{- if eq .KafkaPluginEnabled "true" }}
                , Performance.kafkaProtocol()
{{- end }}
{{- if eq .JdbcPluginEnabled "true" }}
                , Performance.jdbcProtocol()
{{- end }}
{{- if eq .AmqpPluginEnabled "true" }}
                , Performance.amqpProtocol()
{{- end }}
        )
                .maxDuration(SimulationConfig.testDuration());
    }
}
