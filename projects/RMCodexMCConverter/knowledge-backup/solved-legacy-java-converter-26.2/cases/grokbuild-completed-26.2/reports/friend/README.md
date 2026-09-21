# Friend

Psychological horror mod for Minecraft Forge 1.20.1 focused on stalking behavior, environmental fear and adaptive AI.

Unlike typical cave dweller mods, Friend is designed around tension, paranoia and environmental horror instead of constant chase spam. The entity observes the player from a distance, performs dynamic peek events, appears inside cave systems, reacts to player behavior and becomes more aggressive over time.

The goal of the mod is to create the feeling that something intelligent is always nearby.

---

# Features

## Stalking AI

Friend watches the player instead of instantly attacking.

The entity can:

* stand far away and observe;
* hide behind cave corners;
* disappear when noticed;
* react to the player's home and movement patterns;
* dynamically choose stalking positions.

## Dynamic Peek System

Friend performs cinematic peek events inside caves and structures.

The system:

* searches for believable positions;
* uses fallback logic if a perfect spot is not found;
* avoids obvious scripted behavior;
* supports different angles and directions using shared animations.

## Environmental Horror

The mod focuses heavily on atmosphere and psychological pressure.

Features include:

* cave encounters;
* distant appearances;
* window stalking;
* darkness and light suppression;
* ambient horror events;
* adaptive aggression escalation.

## Adaptive Aggression

Friend does not constantly rush the player.

Attack frequency is intentionally limited to preserve tension:

* attacks have cooldowns;
* fake attacks and stalking are mixed together;
* phase `?` is more aggressive but still avoids constant spam;
* the entity becomes more dangerous over long survival sessions.

## Advanced Movement

The entity uses custom movement and pathfinding systems:

* obstacle handling;
* terrain traversal;
* improved navigation in caves;
* anti-abuse block breaking;
* avoidance of grass and small plants as obstacles.

## Custom Animation System

The mod uses GeckoLib animations for:

* stalking;
* peeking;
* running;
* disappearing;
* window interactions;
* special white variant behavior.

---

# Requirements

## Minecraft Version

* Minecraft Forge 1.20.1
* Java 17

## Dependencies

The following mods are required:

* GeckoLib 4
* SmartBrainLib

---

# Installation

1. Install Minecraft Forge 1.20.1
2. Install required dependencies:

   * GeckoLib 4
   * SmartBrainLib
3. Download the latest Friend `.jar`
4. Place the file into:

```text id="8joh7o"
.minecraft/mods
```

5. Launch Minecraft

---

# Build

Project path:

```text id="2k6hm4"
C:\Users\doxbi\Documents\New project\friend_1.20.1
```

Build command:

```powershell id="g8o3v1"
cd "C:\Users\doxbi\Documents\New project\friend_1.20.1"
.\gradlew.bat build
```

Compiled jars:

```text id="tf6zla"
build/libs/
```

---

# Repository

```text id="cjlwmz"
https://github.com/ThompsonCBB/friend
```

---

# Technologies

* Minecraft Forge 1.20.1
* GeckoLib 4
* SmartBrainLib
* Custom AI systems
* Event-driven horror mechanics
* Custom pathfinding and stalking logic

---

# Development Notes

Friend is intentionally designed to avoid cheap horror design.

The entity should feel:

* intelligent;
* unpredictable;
* distant;
* atmospheric;
* oppressive.

The mod focuses on long-term psychological pressure rather than repetitive jumpscares or constant combat.

---

# Credits

Created by:

* ThompsonCBB
* doxbi
* Пепеся

Inspired by psychological horror media and modern Minecraft horror mods while focusing on unique stalking-oriented gameplay.
