# Go workflow

For each Go change:

```bash
gofmt -w . # Formats Go files in this repo
go build ./... # Builds all packages in the project but does not output a binary
go test ./... # Runs tests for all packages (Only matters if tests exists)
go vet ./... # Vets all files, can step in even if it compiles
go run ./cmd/niriland # Runs the app
go build -o bin/niriland ./cmd/niriland # Builds the actual bin in the actual path, not bin for the computer but in `pwd`
```

Example of vet:
```go
package main

import "fmt"

func main() {
	name := "pby"
	fmt.Printf("count: %d\n", name)
}
```
`go build` will build because Printf can take any but `go vet` will give a warning that `%d` expects an integer but name is a string

Example of test:
```go
// app_test.go
package app

import "testing"

func testExample(t *testing.T) {
	got := 1 + 1
	want := 2

	if got != want {
		t.Fatalf("got %d, want %d", got, want)
	}
}
```
`go test` will run this file automatically because the name matches `*_test.go`, and will run on `package app`, and this file would normal next to the code they test like so:
```bash
internal/app/
  app.go
  app_test.go
```
The standard `"testing"` library is the go to normally in Go, so we will also use this.

For linting, there is no built-in standard. Therefore the most used one is `golangci-lint` which needs to be installed seperately on the system or in the Github actions.
I have added a `.golanci.yml` file to define the linting for this project:
- `govet`: Should catch something that is probably a bug but compiles
- `errcheck`: Fails when you ignore an error return, so think “you called something that can fail, but you threw away the error.”
- `ineffassign`: Catches assignments that never matter, usually means you assigned a value, then overwrote it before using it.
- `staticcheck`: Broad analysis for correctness, simplification, deprecated APIs, useless code, bad patterns and performance-ish mistakes. Usually one of the best linters.
- `unused`: Finds code that is declared but never used, so think “this variable/function/type is just sitting there.”
- `run.timeout: 2m`: Tells the linting to stop, if it takes longer that 2 min
- `version: "2"`: Tells the config file that it is using version 2.

Linting is good to have because it will keep the standard of the code very high but also make sure that when I am learning go while making this project, that I will do it in the Go way, not just random code.

For logging in Go, the older standard package is `log`, but for new code `log/slog` is the standard structured logging choice.

`log/slog` is part of the Go standard library.

It is common to create a small local logging file or package that constructs and returns a configured logger.

Example:

```go
// logging.go
package logging

import (
	"log/slog"
	"os"
)

func New() *slog.Logger {
	return slog.New(slog.NewTextHandler(os.Stderr, nil))
}
```
This creates a logger that returns text to stderr which can be used everywhere:
```go
package main

import "logging"

logger := logging.New()
logger.Debug("Resolved something")
logger.Info("Starting Niriland")
logger.Warn("Something not found")
logger.Error("Build failed")
````

For naming, the baseline is:

exported: CamelCase
unexported: camelCase

```go
// app.go
package app

import "fmt"

func RunApp() {
	runApp()
}

func runApp() {
	fmt.Println("Running app...")
}
```

and then in `main.go`, you would never call `runApp` because it is camelCase which in Go is the standard for a unexported function whereas `RunApp` is CamelCase so the standard for exported function:
```go
// main.go
package main

import "github.com/Furyfree/niriland/internal/app"

func main() {
	app.RunApp()
}
```

- `main.go` should stay small. All the logic should be within `internal/`.
- Put tests next to the code they test
- Prefer standard library first if there is a good one

Use `fmt` for the real CLI output and `slog` for logs.

- `fmt` is for what the command is meant to return or show
- `slog` is for diagnostics, warnings, errors, and internal execution details

Even if both appear in the terminal, they usually go to different streams:
- `fmt` -> `stdout`
- `slog` -> `stderr`

That separation matters because command output can be redirected or piped without mixing in logs.

## Likely packages for `niriland`

### Standard library
These are good default choices and should cover a lot before adding dependencies:

- `flag` - basic CLI flag parsing
- `fmt` - user-facing output
- `os` - environment variables, files, process interaction
- `os/exec` - running external commands and scripts
- `path/filepath` - safe filesystem paths
- `errors` - error creation and wrapping
- `context` - cancellation and scoped execution
- `encoding/json` - state files, machine-readable output, cached metadata
- `testing` - standard Go testing
- `log/slog` - structured logging

### External packages likely useful for this repo

- `github.com/spf13/cobra`
  Good choice for a real CLI with subcommands like `install`, `update`, `plan`, `resume`, `doctor`, and `run-step`.
  Useful for help text, shell completions, command structure, and a cleaner CLI surface than raw `flag`.

- `go.yaml.in/yaml/v3`
  Good choice for YAML-backed manifests and structured config files.
  Likely useful if package manifests, step manifests, or optional component metadata move into YAML.

- `github.com/google/go-cmp/cmp`
  Useful in tests when comparing structs, slices, maps, and other nested values.

### TUI packages
These do different jobs:

- `charm.land/bubbletea/v2`
  The actual TUI framework.
  Use this if `niriland` gets an interactive terminal UI.

- `github.com/charmbracelet/bubbles`
  Prebuilt Bubble Tea UI components.
  Things like lists, text inputs, viewports, spinners, and progress components.

- `charm.land/lipgloss/v2`
  Styling and layout for terminal UIs.
  Useful for colors, spacing, borders, alignment, and making the TUI look intentional.

### Practical default direction

- Start with the standard library first
- Add `cobra` when the CLI grows beyond simple `flag`
- Use `go.yaml.in/yaml/v3` for structured manifests
- Add Bubble Tea + Bubbles + Lip Gloss when the TUI work starts

Updating the Go version for a project is done by `go get`, which updates the `go.mod` file. Should always chose the minor version, not patch, and of course major version if there is something newer than 1:
`<MAJOR>.<MINOR>.<PATCH>` -> `1.26.0` is a good project version, not `1.26.2`.
