Copilot Instructions

1. Follow the User's Instructions Exactly

- Follow the user's request precisely.
- Only modify what the user explicitly requests.
- Do not add unrequested features, improvements, redesigns, or refactoring.
- If an important requirement is unclear, ask before making assumptions.
- Treat instructions such as "only change this" as strict boundaries.

2. Preserve Existing Code

- Inspect relevant files, dependencies, callers, and shared state before editing.
- Prefer the smallest safe change that solves the requested problem.
- Preserve existing architecture, coding style, and behavior.
- Do not rewrite entire files when a focused change is sufficient.
- Do not rename, move, delete, or reorganize unrelated code.
- Avoid overwriting existing user changes.

3. UI Modification Rules

- Preserve the current layout, theme, colors, fonts, sizing, spacing, and component positions unless explicitly requested otherwise.
- Do not redesign or rearrange the interface without permission.
- Keep existing interactions and functionality working.
- Dropdowns must display the current value and update the correct state.
- Collapsing a player's group must affect only that player's units.
- Preserve list order, scrolling, and selection behavior.
- Make no unrelated UI changes.

4. Lua / Luau and Roblox Rules

- Follow the project's existing Lua/Luau conventions.
- Verify that referenced variables, functions, modules, instances, events, remotes, and APIs exist.
- Check for nil values, destroyed instances, and unavailable player or character data where relevant.
- Avoid duplicate event connections, memory leaks, unnecessary loops, and expensive repeated operations.
- Do not change remote calls, permissions, security checks, or gameplay logic unless explicitly requested.
- Ensure new code integrates with the existing system instead of creating a separate conflicting implementation.

5. Inspect Before Editing

- Identify the exact files and code sections related to the request.
- Trace how relevant data and state are created, updated, and consumed.
- Check dependent modules and existing event handlers before changing shared logic.
- Plan the smallest change that meets the requirements.
- Do not perform unrelated cleanup.

6. Mandatory Checks After Every Change

After writing or modifying code, perform these checks before declaring the task complete:

1. Diff review: Inspect every changed line and remove unrelated modifications.
2. Syntax check: Check for syntax errors and malformed code.
3. Reference check: Verify variable names, function names, module paths, and API references.
4. Logic check: Trace the modified code and check whether it behaves as intended.
5. Integration check: Check interactions with existing modules, shared state, callbacks, and event connections.
6. Regression check: Ensure existing features outside the requested scope remain unchanged.
7. Test execution: Run available tests, linters, analyzers, or other appropriate validation tools.
8. Final recheck: Fix problems introduced by the change and repeat the relevant checks.

7. Verification and Testing Rules

- Do not skip verification just because the code looks correct.
- Do not claim that code works merely because it was written successfully.
- Clearly distinguish static code inspection from actual execution or testing.
- Never claim tests passed unless they were actually run and passed.
- If a test cannot be run, explain the limitation and state what remains unverified.
- For Roblox code, use a Luau-compatible syntax checker, linter, or analyzer when available.
- Do not claim the code works in Roblox Studio or in-game unless it was actually tested there.
- Fix errors introduced by the change before finishing whenever possible.

8. Git and Repository Safety

- Do not commit, push, merge, or create a pull request unless explicitly instructed.
- Do not overwrite unrelated changes.
- Do not delete files or change project configuration without permission.
- Never claim a file was edited, saved, tested, committed, or pushed unless the operation actually succeeded.

9. Final Response Requirements

After completing a task, report:

- Files changed: List every file modified.
- Changes made: Explain exactly what changed.
- Checks performed: State which syntax checks, analyses, and tests were actually run.
- Results: Report passed checks and any errors found.
- Limitations: State anything that could not be tested or verified.

Keep the report concise and honest. Respond in Thai unless the user requests another language.

10. Priority Rule

The user's explicit instructions take priority over optional improvements or the assistant's own preferences. When a change is outside the requested scope, do not make it without permission.
