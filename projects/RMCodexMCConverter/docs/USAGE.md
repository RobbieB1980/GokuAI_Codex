# Usage examples

## Convert without compile

```powershell
.\Convert-Forge1201-ToNeoForge262.ps1 `
  -Path "C:\mods\legacy\mymod" `
  -OutputPath "C:\mods\mymod-26.2"
```

## Convert and run the complete build

```powershell
.\Convert-Forge1201-ToNeoForge262.ps1 `
  -Path "C:\mods\legacy\mymod" `
  -OutputPath "C:\mods\mymod-26.2" `
  -Compile
# Success produces an installable JAR in build\libs.
# Failure preserves the scaffold and writes compile-errors.log and COMPILE_REPORT.md.
```

If the conversion cannot complete, click **Repair with GokuCodexAI** in the
GUI or run:

```powershell
.\Open-CodexRepairSession.ps1 -FailedOutput "C:\mods\mymod-26.2"
```

The launcher writes `CODEX_REPAIR_REQUEST.md`, installs native Codex guidance
and skills into the failed output, configures the local Minecraft knowledge
MCP from `C:\GokuCodexAI`, and opens Codex as the repair orchestrator. The
NeoForge target remains 26.2. Luna High (`gpt-5.6-luna-high`) is the primary
route; hard issues and failures fall back to Sol Medium
(`gpt-5.6-sol-medium`). Local KAT/Qwen workers are optional.

## Finished NeoForge 1.21.x jar → 26.2 scaffold

```powershell
.\Convert-OldJarToNeoForge262.ps1 `
  -JarPath "C:\mods\the_knocker-1.5.2-neoforge-1.21.8.jar" `
  -OutputPath "C:\mods\the_knocker-26.2" `
  -Compile
```

Then fix remaining compile errors if needed and:

```powershell
cd "C:\mods\the_knocker-26.2"
.\gradlew.bat build
# Install build\libs\*.jar only — not the original 1.21.8 jar
```

## Pin NeoForge version

```powershell
.\Convert-Forge1201-ToNeoForge262.ps1 `
  -Path "C:\mods\legacy\mymod" `
  -OutputPath "C:\mods\mymod-26.2" `
  -NeoVersion "26.2.0.72" `
  -ModDevGradleVersion "2.0.144"
```

## Convert with dependency download + recursive port

```powershell
.\Convert-Forge1201-ToNeoForge262.ps1 `
  -Path "C:\mods\legacy\mymod" `
  -OutputPath "C:\mods\mymod-26.2" `
  -DependencyJarDir "C:\mods\legacy\jars" `
  -Compile
# See DEPENDENCY_REPORT.md — official 26.2 jars in libs\, converted required mods in converted-deps\
```

Preview declared dependencies without writing files:

```powershell
.\Convert-Forge1201-ToNeoForge262.ps1 `
  -Path "C:\mods\legacy\mymod" `
  -OutputPath "C:\mods\mymod-26.2" `
  -DryRun
```

