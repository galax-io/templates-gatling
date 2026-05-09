package {{ .Package }}.{{ .NameWord }}

import io.gatling.javaapi.core.CoreDsl.atOnceUsers
import io.gatling.javaapi.core.Simulation
import org.galaxio.gatling.javaapi.SimulationConfig.testDuration
import org.galaxio.gatling.javaapi.Utility
import {{ .Package }}.{{ .NameWord }}.scenarios.HttpScenario

class Debug : Simulation() {
    init {
        Utility.diagnostics()

        setUp(
            HttpScenario.create()
                .injectOpen(atOnceUsers(1))
        ).protocols(Performance.httpProtocol)
            .maxDuration(testDuration())
    }
}
