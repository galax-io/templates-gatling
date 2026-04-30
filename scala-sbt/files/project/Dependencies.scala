import sbt._

object Dependencies {
  lazy val gatling: Seq[ModuleID] = Seq(
    "io.gatling.highcharts" % "gatling-charts-highcharts",
    "io.gatling"            % "gatling-test-framework",
  ).map(_ % "{{ .GatlingVersion }}" % Test)

  lazy val gatlingPicatinny: Seq[ModuleID] = Seq("org.galaxio" %% "gatling-picatinny" % "{{ .GatlingPicatinnyVersion }}")
  lazy val janino: Seq[ModuleID]           = Seq("org.codehaus.janino" % "janino" % "3.1.12")
}
