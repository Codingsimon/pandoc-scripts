---
title: Scripts für Pandoc
author: Thomas Fragner
titlepage: true
toc: true
numbersections: true
---

## Einleitung

In diesem Repository werden verschiedene Scripts zur Verfügung gestellt, die im Zuge des Publishing Workflows verwendet werden. Grundsätzlich wird zwischen zwei Dokumententypen unterschieden:

- Einzele Markdown Dokumente
- Kombinierte Markdown Dokumente aka Bücher

## Pandoc Befehlsstruktur

Der Basisbefehl für die Erzeugung von PDF Dateien mit Pandoc lautet:

```bash
pandoc --data-dir ${PWD}/.pandoc INPUT_FILE -o OUTPUT_FILE
```
Dieser Befehl wird durch Definitionen die in Environment Dateien spezifiziert sind erweitert.

Die Environment Dateien können an verschiedenen Stellen abgelegt werden:

- Basis im `.pandoc` Verzeichnis.
- Im Root Verzeichnis des Repositories.
- In Unterordnern an beliebiger Stelle.

## Parameter

Building Parameter können an verschiedenen Stellen innerhalb eines Repositories gesetzt werden. Dokumentenspzifische Einstellungen werden im Frontmatter der einzelnen Markdown Dateien gesetzt. Voreinstellungen werden in Environment Dateien gespeichert.

::: {.importantbox}
Parameter die in Voreinstellungsdateien definiert sind können auf Dokumentenebene im Frontmatter nicht mehr verändert werden.
:::

Die Reihenfolge in der die Einstellungen gelesen werden ist:

- Verzeichnisspezifsiche Voreinstellungen
- Globale Repository Voreinstellungen
- Allgemeine Voreinstellungen

### Allgemeine Voreinstellungen

Allgemeine Voreinstellungen sind in der Datei `./pandoc/base.env` definiert. Dabei handelt es sich um Einstellungen ohne die das System nicht funktionieren kann. Folgendene Einstellungen bzw. Command Line Parameter für pandoc sind in dieser Datei definiert:

- **PANDOC_DATA_DIR**: Das Verzeichnis mit den Vorlagen und Filtern die standardmäßig zur Verfügung gestellt werden.
- **PANDOC_DEFAULT_TEMPLATE**: Standardtemplate das für alle Dokumente verwendet werden soll. Hier ist *eisvogel* voreingestellt. Das Template kann später verändert werden.

### Globale Repository Voreinstellungen

### Verzeichnisspezifsiche Voreinstellungen

### Dokumentenspezifische Einstellungen

### Eisvogel spezifische Parameter
