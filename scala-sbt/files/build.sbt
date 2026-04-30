import Dependencies._

enablePlugins(GatlingPlugin)

ThisBuild / organization := "{{ .Organization }}"
ThisBuild / scalaVersion := "{{ .ScalaVersion }}"
ThisBuild / version      := "0.1.0"

lazy val root = (project in file("."))
  .settings(
    name := "{{ .Name }}",
    libraryDependencies ++= gatling,
    libraryDependencies ++= gatlingPicatinny,
    libraryDependencies ++= janino,
    scalacOptions ++= Seq(
      "-encoding",
      "UTF-8",
      "-deprecation",
      "-feature",
      "-unchecked",
      "-language:postfixOps",
    ),
  )
