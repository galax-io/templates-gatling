package main

import (
	"bytes"
	"flag"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"text/template"
)

type templateData struct {
	Name                    string
	Organization            string
	Package                 string
	PackagePath             string
	Description             string
	BaseUrl                 string
	ScalaVersion            string
	SbtVersion              string
	GatlingVersion          string
	SbtGatlingVersion       string
	SbtScalafmtVersion      string
	GatlingPicatinnyVersion string
}

func main() {
	templateName := flag.String("template", "scala-sbt", "template directory to render")
	out := flag.String("out", "", "render output directory")
	flag.Parse()

	if *out == "" {
		fmt.Fprintln(os.Stderr, "--out is required")
		os.Exit(2)
	}

	data := templateData{
		Name:                    "orders-api",
		Organization:            "org.example",
		Package:                 "org.example.performance",
		PackagePath:             "org/example/performance",
		Description:             "Rendered Gatling smoke project.",
		BaseUrl:                 "https://example.test",
		ScalaVersion:            "2.13.18",
		SbtVersion:              "1.12.2",
		GatlingVersion:          "3.11.5",
		SbtGatlingVersion:       "4.18.0",
		SbtScalafmtVersion:      "2.5.6",
		GatlingPicatinnyVersion: "1.0.1",
	}

	if err := render(filepath.Join(*templateName, "files"), *out, data); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	required := []string{
		"build.sbt",
		"project/Dependencies.scala",
		"project/plugins.sbt",
		"src/test/resources/simulation.conf",
		"src/test/scala/org/example/performance/DebugSimulation.scala",
		"src/test/scala/org/example/performance/cases/HttpCases.scala",
		"src/test/scala/org/example/performance/feeders/Feeders.scala",
		"src/test/scala/org/example/performance/scenarios/MainScenario.scala",
	}
	for _, name := range required {
		if _, err := os.Stat(filepath.Join(*out, name)); err != nil {
			fmt.Fprintf(os.Stderr, "expected rendered file %s: %v\n", name, err)
			os.Exit(1)
		}
	}
}

func render(root string, out string, data templateData) error {
	return filepath.WalkDir(root, func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() {
			return nil
		}

		relative, err := filepath.Rel(root, path)
		if err != nil {
			return err
		}
		targetRelative, err := renderString("path", filepath.ToSlash(relative), data)
		if err != nil {
			return err
		}
		if strings.Contains(targetRelative, "{{") {
			return fmt.Errorf("unresolved placeholder in rendered path %q", targetRelative)
		}

		payload, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		rendered, err := renderString(relative, string(payload), data)
		if err != nil {
			return err
		}
		if strings.Contains(rendered, "{{") {
			return fmt.Errorf("unresolved placeholder in rendered file %s", relative)
		}

		target := filepath.Join(out, filepath.FromSlash(targetRelative))
		if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
			return err
		}
		return os.WriteFile(target, []byte(rendered), 0o644)
	})
}

func renderString(name string, value string, data templateData) (string, error) {
	tmpl, err := template.New(name).Parse(value)
	if err != nil {
		return "", err
	}

	var rendered bytes.Buffer
	if err := tmpl.Execute(&rendered, data); err != nil {
		return "", err
	}
	return rendered.String(), nil
}
