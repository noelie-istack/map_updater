# map_updater

A Flutter web tool for extracting booth and sponsored area data from SVG floorplan files.

## What it does

Given an SVG floorplan, **map_updater** parses the file and extracts structured JSON data for two categories of elements:

- **Exhibitor Booths** — `<g>` elements whose `id` matches the pattern `[ABC]NN` (e.g. `A01`, `B12`)
- **Sponsored Area Booths** — `<g>` elements whose `id` matches a configurable list of named areas

The extracted data includes the path geometry (`d`) of each booth, ready to be used in other tools or configs.

## Features

- 📂 **Upload SVG** — replace the default floorplan asset with any SVG file from your machine
- 🔍 **Auto-parse** — dimensions, exhibitor booths, and sponsored area booths are parsed automatically on load or upload
- 🏷️ **Filter chips** — quickly toggle sponsored area IDs from a preset list; JSON updates instantly on each tap
- ✏️ **Manual input** — type comma-separated IDs directly and press **Apply** to re-parse
- 📋 **Copy to clipboard** — copy height, width, or either JSON output with one click
- 📐 **Dimensions display** — shows the SVG `width` and `height` attribute values

## Default sponsored area IDs

```
MainStage, ExhibitionBar, RelaxationBeach, NetworkingZone, BusinessHub,
MeetingTables, Cafe, MediaCentre, Info, BreakOutStage, ExhibitorLounge,
BeerGarden, MassageArea, SpeakerLounge, ConnectZone
```

> IDs must exactly match the `id` attribute of a `<g>` element inside the SVG.

## Running the app

```bash
flutter run -d chrome
```

## Dependencies

| Package | Purpose |
|---|---|
| `flutter_svg` | Render SVG files |
| `file_picker` | Pick SVG files from disk |
| `xml` | Parse SVG XML structure |
