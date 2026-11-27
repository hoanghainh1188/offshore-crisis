@AGENTS.md

# Claude Code — extra rules for Offshore Crisis

## Communication

- Talk to Harry in **Vietnamese**, with clear step-by-step reasoning.
- Write everything that goes into the repo in **English** (see AGENTS.md).

## Workflow

- Start each session by checking the active change in `openspec/changes/`.
- Use `/opsx:explore` before proposing when the direction is unclear.
- After creating a proposal, stop and wait for Harry's approval.
- End each session with a commit and a 3-line devlog entry in the change notes.

## Tools

- Use the **Godot MCP** to run scenes and read errors instead of guessing.
- Run tests headless: `godot --headless --path game -s addons/gut/gut_cmdln.gd`
- Export the web build to check it runs: `godot --headless --path game --export-release "Web" ../build/web/index.html`

## Guardrails

- Do not change the Godot version, project settings, or export presets unless the change asks for it.
- Do not edit files in a change owned by Antigravity.
- Never print, log or commit the contents of `.env`.
