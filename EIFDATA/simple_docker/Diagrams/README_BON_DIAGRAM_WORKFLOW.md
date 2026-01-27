Below is generate by ChatGPT 

# EiffelStudio BON diagram views (multi-view) – step-by-step workflow

This README documents a reliable workflow for creating **multiple BON diagram views** in **ISE EiffelStudio** (newer versions that store diagrams under `EIFDATA/<program-name>/Diagrams/`) and replacing the generated XML safely without EiffelStudio overwriting it.

## Core principle

> Let EiffelStudio create the diagram bundle file and each view first, then replace content while keeping the bundle identity consistent.

## Where diagrams live (newer EiffelStudio)

Diagrams are stored in:

- `EIFDATA/<program-name>/Diagrams/`

## Bundle identity (why “extra files” appear)

EiffelStudio commonly uses a bundle file name derived from:

- `<project-uuid>@<system>@<cluster>@<center-class>.xml`

If the IDE switches center class (or otherwise changes the bundle identity), it will create another file and your views may look “missing” because they are in a different bundle.

## Step-by-step

1. **Compile once**
   - Open the `.ecf`
   - `Project -> Compile` (classes must resolve)

2. **Open Diagram tool**
   - `View -> Tools -> Diagram`

3. **Create the bundle from inside EiffelStudio**
   - Start from `DEFAULT:BON`
   - Pick/ensure the desired center class (example: `DOCKER_CLIENT`)
   - Close EiffelStudio once so the bundle file is written

4. **Create additional views**
   - In the Diagram tool’s *View dropdown*, **type** a new name and press **Enter**
   - Repeat for each view you want (examples below)
   - Close EiffelStudio once so the view XML stubs are written

5. **Replace content safely**
   - Edit the active bundle file in `EIFDATA/.../Diagrams/`
   - **Keep `DEFAULT:BON` as EiffelStudio generated** (recommended)
   - For each custom view, replace only the diagram elements (typically `ROOT_ELEMENTS`) using an EiffelStudio-generated view as the schema template

6. **Reopen and verify**
   - Restart EiffelStudio
   - Switch between views in the Diagram tool
   - Close/reopen the IDE to confirm it does not overwrite your changes

## Troubleshooting

### A new extra XML file appears
You are likely editing the wrong bundle. The active one often ends with the current center class, e.g. `...@DOCKER_CLIENT.xml`.

### Only `ANY` shows up or your classes vanish
Your pasted XML probably did not match EiffelStudio’s expected schema. Use an EiffelStudio-generated view as the template and only replace `ROOT_ELEMENTS`.

### View exists but is blank
Try `Fit to window` or `Auto-layout`. If still blank, open a class in the editor and then refresh/recompute the diagram.

### EiffelStudio overwrites your changes on exit
Preserve EiffelStudio’s metadata and edit only the diagram parts. Work inside the bundle file EiffelStudio created.

## Suggested view names

- `SIMPLE_DOCKER_VIEW:BON`
- `SIMPLE_DOCKER_OVERVIEW:BON`
- `SIMPLE_DOCKER_DOMAIN:BON`
- `SIMPLE_DOCKER_BUILDERS:BON`
- `SIMPLE_DOCKER_API:BON`

## Lessons learned (short)

- `DEFAULT:BON` is special and may be regenerated.
- Diagrams are bundled by center class. “Extra files” usually mean a new bundle.
- Don’t hand-write the full XML. Start from EiffelStudio output and replace only what you need.
- Create views in the UI first (type name + Enter), then replace content.
