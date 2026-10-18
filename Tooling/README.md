# Development tooling

Reviewers need only Xcode 26 or newer with an iOS 26 simulator: open `Tahudu.xcodeproj` and press ⌘R. The generated project and shared scheme are included. The build runs no scripts and downloads no packages. Nothing in this folder runs in a fresh clone. Mise, Ruby, Fastlane, Tuist and the Git hook are only for contributors. Simulator builds do not need an Apple account.

## Layout

```text
Tooling/
├── Gemfile
├── Gemfile.lock
├── README.md
├── .swiftformat
├── gitleaks.toml
├── Hooks/pre-commit
└── fastlane/Fastfile
```

`.mise.toml`, `Project.swift` and `.gitignore` stay at the repository root for normal tool discovery. Mise searches the current directory and its parents, so root-level version pins apply to app, package and tooling commands. A config stored only in `Tooling/` would not apply to sibling app/package directories. GitHub requires workflows under `.github/workflows/`. App and package sources remain in their existing folders.

## Contributor setup

Install mise with Homebrew (`brew install mise`, or `brew upgrade mise`), then run from the repository root:

```sh
mise trust .mise.toml
mise install
(cd Tooling && mise exec -- bundle install)
git config --local core.hooksPath Tooling/Hooks
```

The last command selects this repository's hook directory. If you already maintain custom hooks, integrate this hook with them. There is no installer or Python dependency.

`.mise.toml` contains only exact Ruby, Tuist, SwiftFormat and Gitleaks versions. `mise exec --` makes those versions available to the following command. There are no mise tasks, environment settings or lockfile.

## Ruby dependencies

Fastlane is written in Ruby. A gem is a Ruby package; Bundler selects the packages for a project.

`Tooling/Gemfile` declares Fastlane and a compatible Ruby range. `Tooling/Gemfile.lock` locks Fastlane, its transitive dependencies and Bundler; the exact Ruby runtime is pinned in mise.

Run Bundler and Fastlane from `Tooling/`, where Bundler finds the Gemfile and Fastlane finds its conventional `fastlane/` directory. Dependencies are installed in the mise-managed Ruby's gem home, outside this repository. Multiple gem versions can coexist there, and `bundle exec` selects this project's locked versions. No `vendor/` folder or local Bundler path configuration is needed.

CI uses `BUNDLE_FROZEN=true` to reject unexpected dependency-lock changes. These gems are development tools and are not linked into the iOS app.

## Formatting rules

`.swiftformat` is a plain SwiftFormat configuration file, not another tool. It defines the agreed Swift language mode, indentation, line width and exclusions. The pre-commit hook and CI use this same file so their results agree. Mise pins the formatter executable version; this file defines its formatting rules.

SwiftFormat and Gitleaks only discover config files at the repository root or beside the files they check. These configs live in `Tooling/`, so always pass them explicitly: `--config Tooling/.swiftformat` and `--config Tooling/gitleaks.toml`. That applies to every command, editor integration and the SwiftFormat Xcode extension. A plain `swiftformat .` falls back to SwiftFormat's defaults, which format differently (for example, trailing commas in argument lists).

## Common commands

From the repository root:

```sh
mise exec -- swiftformat . --config Tooling/.swiftformat
mise exec -- swiftformat . --config Tooling/.swiftformat --lint
mise exec -- gitleaks dir . --config Tooling/gitleaks.toml --redact --no-banner
mise exec -- tuist generate --no-open
```

For Fastlane, enter `Tooling/`:

```sh
cd Tooling
mise exec -- bundle exec fastlane ios test
mise exec -- bundle exec fastlane ios build
mise exec -- bundle exec fastlane ios ci
```

The three lanes are:

- `test`: run the unit tests from `TestPlans/Tahudu.xctestplan` on an iPhone 17 / iOS 26.2 simulator.
- `build`: build an unsigned Release simulator app.
- `ci`: run the tests, then build Release.

Builds use a generic iOS Simulator destination. Local runs use whichever Xcode is selected (`xcode-select -p`), while CI uses Xcode 26.3 and mise 2026.10.11. To match CI's Xcode, prefix a command with `DEVELOPER_DIR=/Applications/Xcode_26.3.app/Contents/Developer`, or switch with `xcode-select`. Overrides are available:

```sh
mise exec -- bundle exec fastlane ios build configuration:Debug
mise exec -- bundle exec fastlane ios test device:"iPhone 17 Pro (26.2)"
```

All output is under the repository's ignored `build/` directory: build and test logs in `build/logs/`, test reports and the `.xcresult` in `build/tests/`, DerivedData in `build/DerivedData/`, and Fastlane's disposable lane summary in `build/report.xml`. The entire `build/` folder is disposable and ignored by Git; deleting it clears build caches and reports, and the next Fastlane run recreates it. There are no signing, upload or deployment lanes.

## Pre-commit

Git uses `Tooling/Hooks/pre-commit` because `core.hooksPath` points there. A fresh clone has no hooks until someone runs the setup command. The hook is a Bash script with direct SwiftFormat and Gitleaks commands.

It reads each staged Swift file from Git's index and pipes that content into `swiftformat stdin --lint`. This checks exactly what will be committed, including partially staged files, without changing the index or working copies. There are no helper scripts or temporary files. The config's exclusions also apply here.

Gitleaks checks staged changes with secret values redacted. Both checks run even when formatting fails. To fix formatting, run the format command above, review the changes and stage the intended result.

Only real findings block a commit. Git apps launched from the Dock (Xcode, Fork, Tower) run hooks without Homebrew on `PATH`, so the hook also looks for mise in `/opt/homebrew/bin`, `/usr/local/bin` and `~/.local/bin`. If mise, SwiftFormat or Gitleaks still can't run, the hook prints a notice and lets the commit through. CI runs the same checks.

Inspect or run the hook without committing:

```sh
git config --get core.hooksPath
git hook run pre-commit
```

## Tuist project generation

`Project.swift` defines the app, build settings and shared scheme. Its options disable automatic schemes and unused generated bundle/resource helpers. The local package and its modules stay defined only in `Packages/PropertyFinderKit/Package.swift`.

No `Tuist.swift` is needed for the current setup. The shared scheme contains no dependency on the Tuist executable.

The shared scheme runs `TestPlans/Tahudu.xctestplan`, which selects the package's `NetworkingTests`, `ListingsTests`, `SettingsTests` and `SnapshotTests`. They are XCTest tests with stubs only, so they never call the real API. The snapshot references live in `Tests/SnapshotTests/__Snapshots__/` (excluded from the target in `Package.swift`) and are only compared on iOS 26.2 (English (US) only, US region). If you rename a test target, update the plan.

Keep `Tahudu.xcodeproj/` and `Project.swift` in version control. Update the manifest and regenerate rather than editing generated project files manually. The convenience workspace and local caches are ignored.

Normal Xcode incremental builds reuse local DerivedData. No cross-run DerivedData cache is configured in GitHub Actions. Tuist binary caching has no eligible targets with the current native Swift-package integration. Tuist's separate Xcode compilation cache would require an account/project, service setup and CI authentication; it remains deferred.

## GitHub Actions

`.github/workflows/ci.yml` runs on pull requests, pushes to `main` and manual dispatch. Its single `macos-26` / Xcode 26.3 job has a 40-minute limit, which leaves room for a first run that has to install tools:

1. Checks out the repository and installs mise-pinned tools.
2. Checks Swift formatting and scans fetched Git history for secrets.
3. Regenerates the project and fails on any change to the included project, including newly generated files.
4. Enters `Tooling/`, installs locked gems and runs `bundle exec fastlane ios ci`, which runs the unit tests and then builds Release.
5. Uploads build logs and test results, including on failure.

The mise action exposes tools on `PATH`. Actions use pinned commits and read-only repository permissions. The workflow needs no repository secrets.
