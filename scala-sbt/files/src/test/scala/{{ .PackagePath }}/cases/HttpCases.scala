package {{ .Package }}.cases

import io.gatling.core.Predef._
import io.gatling.http.Predef._

object HttpCases {
  val getMainPage = http("GET /")
    .get("/")
    .check(status.is(200))
}
