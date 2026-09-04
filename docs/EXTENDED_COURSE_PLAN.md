# Extended Course Details Plan

## Purpose

Add richer golf course information without disrupting the existing scorecard workflow. A course should support both a quick scorecard setup and a useful reference view with hole-by-hole details.

The design is informed by the structure of the Chimera Golf Club course page: course overview, front/back nine sections, hole descriptions, par, handicap, tee yardages, green dimensions, and optional flyover links.

## Current State

- `Course` stores a name and a list of `Hole` values.
- `Hole` currently stores only its number and par.
- Course holes are serialized as JSON in the `courses.holes_json` column.
- Rounds use only hole number and par for scoring.
- Courses are currently created manually or populated through AI lookup.
- The app is on-device only, with no backend, accounts, or login.
- Player handicap tracking is outside the current product scope.

This existing shape allows the first release to remain backward-compatible: new fields can be optional, and old course JSON can continue to load with defaults.

## Goals

- Let users view a course as a reference, not only as a round-start shortcut.
- Support hole-by-hole course information.
- Support multiple tee sets without hardcoding tee names.
- Keep score entry fast and unchanged for users who only need par values.
- Preserve existing courses and historical rounds.
- Keep course data usable offline.
- Make imported details editable before they are saved.

## Non-Goals

- Player handicap calculation or handicap-based scoring.
- Tee-time booking or external golf service integration.
- A backend, user accounts, or cloud synchronization.
- Automatically treating AI-generated course information as authoritative.
- Reproducing third-party course copy or media without appropriate permission.

## Proposed Data Model

### Course

Add optional overview metadata to the existing course model:

- `location`
- `description`
- `designer`
- `yearOpened`
- `websiteUrl`
- `imageUrl`
- `teeSets`
- `source` (`manual`, `aiImported`, or `aiReviewed`)

The existing `name` and `holes` fields remain the core required data.

### Hole

Extend each hole with optional reference data:

- `description`
- `handicap`
- `yardagesByTee`
- `greenDepth`
- `greenWidth`
- `flyoverUrl`

The `handicap` value is a single course scorecard index per hole (not split by men's/women's tee), matching typical casual-play scorecards. It does not introduce player handicap tracking.

### TeeSet

Introduce a reusable tee-set model instead of hardcoding names such as Pegasus or Serpent:

- `name`
- `color` or display color value
- `yardageByHole`
- `rating`
- `slope`

Tee-set yardage can be represented either on `TeeSet` or as a per-hole map, but the serialization should have one clear owner. A per-hole map is preferable for the first release because it matches how scorecards are displayed and supports incomplete data cleanly.

Tee-set rules:

- A tee set may be incomplete; it is not required to cover every hole. Missing per-hole yardage displays as a placeholder (e.g. a dash), not a zero or an error.
- Tee-set names must be unique within a course, but yardage completeness is not validated beyond that.
- Deleting a tee set removes it from the selector immediately. If it was the currently selected tee set in the details view, selection falls back to the first remaining tee set, or to a par-only view if none remain. Deleting a tee set never modifies hole data (`number`, `par`, `handicap`, etc.).
- Tee-set color is stored as a display color value (ARGB int) rather than a fixed palette name, so it maps directly to a Flutter `Color` without a lookup table, while remaining free-form enough for AI-imported or user-picked colors.

### Field Categories

To keep edit rules, migrations, and future snapshot behavior unambiguous, fields are split into two categories:

- **Scoring-critical**: `hole.number`, `hole.par`. These directly drive round scoring and totals.
- **Reference-only**: everything else — tee sets and their yardages, `handicap`, `description`, green dimensions, `flyoverUrl`, course overview metadata. These never affect scoring calculations and can be edited freely regardless of round history.

Example conceptual shape:

```text
Course
  name
  overview metadata
  teeSets
  holes

Hole
  number
  par
  handicap
  description
  yardagesByTee
  green dimensions
  flyover URL
```

## Persistence Strategy

Continue storing course details in the existing `holes_json` payload for the first release. Add optional top-level course fields as additional columns only if the JSON becomes difficult to query or maintain.

Serialization requirements:

- `toMap` must omit or safely encode absent optional values.
- `fromMap` must default missing fields for old records.
- Numeric values must be parsed defensively where data may have come from AI or hand-edited JSON.
- Existing courses created before this feature must load without migration errors.
- Existing round records must continue resolving their course and calculating scores.

A database version bump is not required if all new fields remain inside the existing JSON column. Add an explicit database migration later if course search, filtering, or reporting requires SQL-level fields.

Define a single `Course` serialization contract (one `toMap`/`fromMap` pair) that every persistence path shares, even while everything lives in JSON. This avoids the mapping complexity of a hybrid SQL-columns-plus-JSON approach creeping in one field at a time; if SQL columns are added later, they replace parts of this single contract rather than living alongside a second one.

`imageUrl` and `flyoverUrl` are stored as remote URLs only for the first release (no local file storage or upload flow). Offline, the app never blocks on fetching them: the details screen renders the image/flyover section only when the link is reachable, and hides it cleanly otherwise rather than showing a broken-image placeholder.

## User Experience

### Course List

Change the primary course-card action from directly starting a round to opening course details. Add a separate, visually clear play action for starting a round.

Each course card can continue showing:

- Course name
- Hole count
- Total par
- Optional primary tee yardage

### Course Details Screen

Create a read-only `CourseDetailsScreen` with:

- Course name and overview
- Location and designer when available
- Summary metrics: hole count, par, and selected tee yardage
- Tee-set selector
- Front 9 and back 9 sections
- Compact scorecard table with hole, par, handicap, and yardage
- Expandable hole rows for description and green dimensions
- Optional flyover link
- Actions to edit the course and start a round

For 9-hole courses, show only the available holes and do not assume a back nine.

### Course Editor

Keep the existing fast-entry flow and add an advanced details path:

1. Basic course information
2. Hole count and par grid
3. Tee-set management
4. Per-hole yardage and handicap
5. Optional descriptions, green dimensions, and flyover links
6. Review and save

The simple path should remain practical for users who only want to record pars. Advanced fields should not create a wall of required inputs.

Validation should cover:

- Positive hole count
- Sequential, unique hole numbers
- Pars in the supported range, while allowing the existing behavior to remain compatible
- Non-negative yardages and green dimensions
- Unique tee-set names
- Valid URLs when a link is provided

## Round Integration

The scoring model should continue using only `hole.number` and `hole.par` for calculations. Course details are reference data and must not change scoring semantics.

Optional round-screen enhancements:

- Show selected tee yardage beside the current hole.
- Show handicap as secondary information.
- Provide a collapsible hole description.
- Keep the score entry control as the dominant interaction.

When a course is edited after rounds have been recorded, historical rounds must not unexpectedly change. This is treated as a first-release requirement, not a later enhancement: once a course has at least one recorded round, its scoring-critical fields (`hole.number`, `hole.par`, and hole count) are frozen in the editor — the UI disables changes to them and explains why. Reference-only fields remain freely editable at any time, since they cannot affect historical totals. A future enhancement may snapshot the relevant course data into each round and lift this restriction.

## AI Lookup

The current AI lookup returns only course name and par per hole. Extend it in stages:

### Stage 1

Keep the current response contract and make the new model fields optional.

### Stage 2

Allow optional tee names, yardages, and handicap indexes in the response.

### Rules

- Treat AI output as an editable draft.
- Do not invent descriptions, yardages, green measurements, or URLs when unknown.
- Continue supporting the existing minimal response.
- Parse missing and null values without failing the entire import.
- Show the user what will be saved before committing it.
- Prefer a supplied official scorecard or course URL when a trustworthy source is available.
- Track provenance on the course record itself: a `source` value of `manual`, `aiImported`, or `aiReviewed` (set to `aiReviewed` once a user edits and saves AI-imported data). This lets the app avoid implying that all saved metadata is equally verified, without blocking any existing flow.

## Delivery Plan

### Phase 1: Backward-Compatible Models

- Extend `Hole` and `Course` with optional fields.
- Add `TeeSet`.
- Update `toMap` and `fromMap`.
- Add tests for old JSON and new JSON.
- Verify round scoring is unchanged.

### Phase 2: Course Details View

- Add `CourseDetailsScreen`.
- Add front-nine and back-nine presentation.
- Add tee-set selection.
- Add compact scorecard rows and expandable details.
- Update navigation from the course list.

### Phase 3: Detailed Editing

- Preserve the existing par grid.
- Add tee-set creation and editing.
- Add per-hole detail editing.
- Add validation and empty-state behavior.
- Support editing imported data before saving.

If schedule pressure appears, tee sets, per-hole yardages, and handicap are the highest-value additions to keep; descriptions, green dimensions, and flyover links are the easiest to defer to a later phase without weakening the core feature.

### Phase 4: AI Import Enhancements

- Expand the prompt with optional fields.
- Parse partial responses defensively.
- Add an import review state.
- Keep a minimal fallback response path.

### Phase 5: Round Reference Details

- Add optional yardage and handicap context to the scoring screen.
- Keep score entry uncluttered and performant.
- Test that course-detail changes do not alter historical score calculations.

## Testing Strategy

### Model and Persistence Tests

- Deserialize legacy course JSON containing only `number` and `par`.
- Serialize and deserialize a fully populated course.
- Handle absent, null, and partial tee data.
- Confirm course totals and hole counts remain correct.

### Provider Tests

- Add, update, load, and delete courses containing extended details.
- Confirm updates preserve course IDs.
- Confirm list sorting remains name-based.

### Widget Tests

- Open course details from the course list.
- Start a round from the details screen.
- Render 9-hole and 18-hole courses correctly.
- Switch tee sets and verify displayed yardages.
- Expand and collapse hole details.
- Edit and save optional fields.

### Regression Tests

- Existing course creation still works with only par values.
- Existing rounds still load.
- Score totals and relative-to-par values are unchanged.
- Courses with missing optional metadata do not show broken labels or empty layout gaps.

## Acceptance Criteria

- Existing saved courses load without errors after the feature is added.
- Existing rounds calculate scores exactly as before.
- A course can display multiple tee sets with per-hole yardages.
- Users can view all holes grouped into front and back nine when applicable.
- Users can edit imported or manually entered details.
- Optional information remains optional throughout creation and display.
- Invalid or uncertain AI data is never silently presented as verified.
- The app remains fully usable offline.
- The feature does not introduce player handicap tracking or other scope expansion.
- Editing a course that already has recorded rounds cannot silently change historical totals or hole structure (scoring-critical fields are frozen once rounds exist).
- A partially populated tee set displays cleanly and does not break totals, tables, or course details.
- Deleting or changing optional media and links never creates broken offline layouts.
- AI-imported partial data can be saved, edited later, and reloaded without lossy serialization.

## Decisions

These were open questions in earlier drafts; resolved after reviewing Codex's addendum below.

- **Course overview fields**: remain in the existing `holes_json` payload for the first release, behind one canonical `Course` serialization contract shared by all persistence paths. Dedicated SQL columns are added later only if querying/filtering/reporting needs them.
- **Handicap**: a single course index per hole, not separate men's/women's indexes.
- **Tee colors**: stored as a display color value (ARGB int), not a name or fixed palette.
- **Course images**: `imageUrl` is included in the first release as a remote URL only — no local file storage or upload flow. The details screen hides the image/flyover sections cleanly when unreachable rather than showing a broken layout.
- **Historical rounds**: not snapshotted in the first release. Instead, scoring-critical fields (`hole.number`, `hole.par`, hole count) are frozen in the editor once a course has any recorded round. Reference-only fields stay editable. Snapshotting remains a future enhancement that would lift this restriction.

## Codex Addendum: Review Comments and Feedback

**Resolution**: every clarification below has been incorporated into the sections above (Field Categories, Persistence Strategy, Round Integration, TeeSet rules, AI Lookup provenance, and Decisions) and the acceptance additions have been merged into Acceptance Criteria. This section is kept as the original review record.

### Overall Assessment

This is a strong plan. It keeps the current score-entry workflow protected, treats richer course data as optional, and stages AI expansion in a responsible way.

The biggest remaining risk is not the UI complexity. It is data ownership: which course fields are safe to edit after rounds exist, which fields are only reference data, and when historical rounds should stop depending on the live course record.

### Recommended Clarifications

- Treat historical round protection as an earlier design decision, not a later enhancement. The current app reconstructs round views from the saved course record, so edits to hole count or par can create drift in history. If snapshotting is not part of the first release, the plan should explicitly freeze scoring-relevant fields for courses that already have rounds.
- Define one canonical serialized course payload early. A hybrid approach with some course fields in SQL columns and others in `holes_json` can work, but it will add mapping complexity quickly. Even if the database remains unchanged for now, it would help to define a single `Course` serialization contract that all persistence paths share.
- Split fields into two categories in the plan: scoring-critical fields and reference-only fields. `hole.number` and `par` are scoring-critical. Yardages, handicap indexes, descriptions, green dimensions, and flyover links are reference-only. That distinction will make edit rules, migrations, and future snapshot behavior much clearer.
- Tighten the tee-set rules. The plan should say whether incomplete tee sets are allowed, whether every tee set must cover every hole, and what happens if a tee set is deleted after being selected in the details view or attached to imported data.
- Narrow Phase 3 if schedule pressure appears. Tee sets, per-hole yardages, and handicap feel like the highest-value additions. Descriptions, green dimensions, and flyover links are useful, but they seem like the easiest fields to defer without weakening the main feature.
- Add provenance language for imported data. “Editable draft” is the right direction, but it may help to persist whether a course was manually entered, AI-seeded, or later reviewed by the user so the app does not imply that all saved metadata is equally verified.
- Make the offline expectation explicit for remote media and links. If `imageUrl` and `flyoverUrl` are stored as URLs only, the course should still render cleanly offline with those sections absent or disabled.

### Suggested Acceptance Additions

- Editing a course that already has recorded rounds cannot silently change historical totals or hole structure.
- A partially populated tee set displays cleanly and does not break totals, tables, or course details.
- Deleting or changing optional media and links never creates broken offline layouts.
- AI-imported partial data can be saved, edited later, and reloaded without lossy serialization.
