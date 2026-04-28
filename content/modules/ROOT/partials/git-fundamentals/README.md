# Git Fundamentals Lab - Modular Structure

This directory contains the modular components of the Git Fundamentals lab.

## Purpose

The lab is divided into partials to enable:
- **Parallel development**: Multiple contributors can work on different exercises simultaneously
- **Reusability**: Individual exercises can be referenced from other labs
- **Maintainability**: Easier to update specific sections without affecting the entire lab
- **Conflict avoidance**: Minimize Git merge conflicts in collaborative work

## Structure

```
git-fundamentals/
├── README.md                     # This file
├── introduction.adoc             # Lab overview and objectives
├── exercise-01-clone.adoc        # Clone and explore repository
├── exercise-02-changes.adoc      # Making changes and commits
├── exercise-03-branches.adoc     # Working with multiple branches
├── exercise-04-merging.adoc      # Merging branches
├── exercise-05-remote.adoc       # Remote repository operations
├── exercise-06-conflicts.adoc    # Merge conflict resolution
├── exercise-07-pull.adoc         # Pulling changes
├── summary.adoc                  # Key concepts and workflow diagram
└── reference.adoc                # Quick reference card
```

## Main Orchestrator

The main file that includes all partials:
- **Location**: `content/modules/ROOT/pages/day1-git-fundamentals.adoc`
- **Purpose**: Entry point for the lab, includes all partials in order

## How to Edit

### Editing Individual Exercises

1. Locate the exercise partial you want to modify
2. Edit only that partial file
3. Test locally before committing
4. Commit with a descriptive message

Example:
```bash
# Edit a specific exercise
code content/modules/ROOT/partials/git-fundamentals/exercise-02-changes.adoc

# Commit only the changed partial
git add content/modules/ROOT/partials/git-fundamentals/exercise-02-changes.adoc
git commit -m "docs: update exercise 2 with better commit message examples"
```

### Adding New Exercises

1. Create a new partial file (e.g., `exercise-08-stash.adoc`)
2. Add the include directive to the main orchestrator file
3. Update navigation if needed

Example:
```asciidoc
// In day1-git-fundamentals.adoc
include::partial$git-fundamentals/exercise-08-stash.adoc[]
```

### Reusing Exercises

Individual exercises can be included in other labs:

```asciidoc
// In another lab file
include::partial$git-fundamentals/exercise-01-clone.adoc[leveloffset=+1]
```

## Conventions

- **File naming**: `exercise-NN-<topic>.adoc` where NN is zero-padded number
- **Section levels**: Use `==` for main sections within exercises
- **Code blocks**: Use `[source,bash,role=execute]` for executable commands
- **Attributes**: Use Antora attributes like `{gitlab_url}`, `{user}`, `{password}`

## Testing

Test the entire lab locally:

```bash
# Start local preview
podman run --rm -v "C:\Users\sergi\git\etx_app_showroom_content:/antora:z" -p 8080:8080 -it ghcr.io/juliaaano/antora-viewer

# Open browser to http://localhost:8080
# Navigate to Day 1 > Git Fundamentals Lab
```

## Integration with Main Repository

- **Navigation**: Only `content/modules/ROOT/nav.adoc` references this lab
- **Minimal touch**: Single line addition to nav.adoc
- **Self-contained**: All content in `partials/git-fundamentals/` directory

This modular approach minimizes conflicts with other contributors working on Day 2 and Day 3 labs.
