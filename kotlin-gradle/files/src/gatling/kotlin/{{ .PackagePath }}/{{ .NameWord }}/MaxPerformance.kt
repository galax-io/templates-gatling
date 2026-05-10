package {{ .Package }}.{{ .NameWord }}

import io.gatling.javaapi.core.CoreDsl.incrementUsersPerSec
import io.gatling.javaapi.core.OpenInjectionStep
import io.gatling.javaapi.core.Simulation
import org.galaxio.gatling.javaapi.SimulationConfig
import org.galaxio.gatling.javaapi.Utility
import {{ .Package }}.{{ .NameWord }}.scenarios.HttpScenario

class MaxPerformance : Simulation() {
    init {
        val injectionProfile: Array<OpenInjectionStep> = arrayOf(
            incrementUsersPerSec(SimulationConfig.intensity() / SimulationConfig.stagesNumber())
                .times(SimulationConfig.stagesNumber())
                .eachLevelLasting(SimulationConfig.stageDuration())
                .separatedByRampsLasting(SimulationConfig.rampDuration())
                .startingFrom(0.0)
        )

        Utility.banner(*injectionProfile)

        setUp(
            HttpScenario.create()
                .injectOpen(*injectionProfile)
        ).protocols(Performance.httpProtocol)
            .maxDuration(SimulationConfig.testDuration())
    }
}
