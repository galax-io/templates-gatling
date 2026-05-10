package {{ .Package }}.{{ .NameWord }}.cases

import io.gatling.javaapi.core.ChainBuilder
import io.gatling.javaapi.core.CoreDsl.exec
import io.gatling.javaapi.http.HttpDsl.http
import io.gatling.javaapi.http.HttpDsl.status

object HttpActions {
    val getMainPage: ChainBuilder = exec(
        http("GET /").get("/").check(status().`is`(200))
    )
}
