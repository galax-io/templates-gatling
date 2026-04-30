import Dependencies._

enablePlugins(GatlingPlugin)

lazy val root = (project in file("."))
  .settings(
    inThisBuild(
      List(
        organization := "{{ .Package }}",
        scalaVersion := "{{ .ScalaVersion }}",
        version      := "0.1.0",
      ),
    ),
    name := "{{ .Name }}",
    libraryDependencies ++= gatling,
    libraryDependencies ++= gatlingPicatinny,
    libraryDependencies ++= janino,
      scalacOptions ++= Seq (
        "-encoding",
        "UTF-8",
        "-Xfatal-warnings",
        "-deprecation",
        "-feature",
        "-unchecked",
        "-language:implicitConversions",
        "-language:higherKinds",
        "-language:existentials",
        "-language:postfixOps"
      ),
  )
