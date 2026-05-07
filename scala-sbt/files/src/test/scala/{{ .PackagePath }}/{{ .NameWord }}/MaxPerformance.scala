package {{ .Package }}.{{ .NameWord }}

import io.gatling.core.Predef._
import org.galaxio.gatling.config.SimulationConfig._
import {{ .Package }}.{{ .NameWord }}.scenarios._

class MaxPerformance extends Simulation {

  setUp(
    HttpScenario().inject(
      // интенсивность на ступень
      incrementUsersPerSec((intensity / stagesNumber).toInt)
        // Количество ступеней
        .times(stagesNumber)
        // Длительность полки
        .eachLevelLasting(stageDuration)
        // Длительность разгона
        .separatedByRampsLasting(rampDuration)
        // Начало нагрузки с
        .startingFrom(0),
    ),
  ).protocols(
    httpProtocol,
    // общая длительность теста
  ).maxDuration(testDuration)

}
