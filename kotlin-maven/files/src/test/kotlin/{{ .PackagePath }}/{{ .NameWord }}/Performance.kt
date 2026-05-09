package {{ .Package }}.{{ .NameWord }}

import io.gatling.javaapi.http.HttpDsl.http
import io.gatling.javaapi.http.HttpProtocolBuilder
import org.galaxio.gatling.javaapi.SimulationConfig.baseUrl

object Performance {
    val httpProtocol: HttpProtocolBuilder = http
        .baseUrl(baseUrl())
        .acceptHeader("application/json")
        .contentTypeHeader("application/json")
        .disableFollowRedirect()
}
