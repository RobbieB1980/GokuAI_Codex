# Destination Java for installer + agent builds

**Target:** NeoForge **26.2** → JDK major **25**.

## Rule

Installer `-Compile`, dependency jar builds, **and Fix-in-Grok / hosted agents** must always build with the **destination** Java version from the scaffold toolchain — never ambient `JAVA_HOME` (often Java 8 on PATH).

Agents must **not** run bare `gradlew` under ambient/source Java first, fail with `Gradle requires JVM 17+ ... JVM 8`, then rediscover destination Java. Pin destination Java **before the first Gradle invocation**.

## Encoding

| Piece | Behavior |
|---|---|
| `Get-DestinationJavaMajorForMinecraft` | `26.x` → 25 |
| `Get-ProjectRequiredJavaMajor` | `JavaLanguageVersion.of(N)` + `minecraft_version` mapping |
| `Set-ProjectDestinationJavaHome` | writes `org.gradle.java.home` into output `gradle.properties` |
| `Invoke-GradleBuildWithRequiredJava` | pins env `JAVA_HOME` + props before `gradlew` |
| `Write-GradleScaffold` | best-effort pin at scaffold time |
| `Build-WithDestinationJava.ps1` | agent/CLI entrypoint for destination builds |
| `Write-GrokRepairPrompt` | repair prompt always includes destination-Java mandate + pin |

## Agent command

```powershell
powershell -NoProfile -File C:\gokuai\projects\RB-Legacy-Java-Converter\tools\Build-WithDestinationJava.ps1 -ProjectRoot "<FAILED OUTPUT>"
```

## Do not

- Do not run installer or agent compile under Java 8/11/17 when the project toolchain is 25.
- Do not treat a successful manual build on Java 21 + foojay toolchain download as a substitute for the destination-JDK pin.
- Do not treat `Gradle requires JVM 17+ ... configured to use JVM 8` as a mod source error.
