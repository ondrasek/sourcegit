# SourceGit

Cross-platform Git GUI client built with Avalonia (C#/.NET 10).

## Quick Reference

```bash
dotnet build src/SourceGit.csproj        # Build
dotnet format src/SourceGit.csproj       # Format code
```

No test projects exist yet. No `dotnet test` available.

## Project Structure

- `src/` — single project (SourceGit.csproj), MVVM architecture (ViewModels/, Views/, Models/, Commands/)
- `depends/AvaloniaEdit/` — git submodule dependency (do not modify)
- `SourceGit.slnx` — modern solution format
- `VERSION` — CalVer version (e.g. `2026.05`), read by .csproj at build time

## Conventions

- **Formatting**: `.editorconfig` enforced by `dotnet format`. Block-scoped namespaces, Allman braces, `var` preferred.
- **Naming**: `_camelCase` for private fields, `s_camelCase` for private static fields, `PascalCase` for constants.
- **No tests**: When adding testable logic, prefer pure methods in Models/ or ViewModels/.
- **AOT/Trimming**: Enabled in Release builds. Avoid reflection-heavy patterns.
- **Submodule**: Run `git submodule update --init` after clone.

## Quality Hooks

- **Per-edit**: Auto-formats C# files on every edit
- **Quality gate**: Runs on Stop — format check → build → NuGet vulnerability audit
- **Session start**: Non-blocking NuGet vulnerability + outdated package warnings
