# Contributing to ETX App Platform Showroom Content

This guide helps contributors add content to the ETX Application Platform workshop in a collaborative environment.

## Repository Structure

```
etx_app_showroom_content/
├── content/
│   ├── antora.yml                    # Component configuration
│   └── modules/
│       └── ROOT/
│           ├── nav.adoc              # Navigation orchestrator (minimal edits)
│           ├── pages/               # Main lab pages
│           │   ├── day1-*.adoc      # Day 1 labs
│           │   ├── day2-*.adoc      # Day 2 labs
│           │   └── day3-*.adoc      # Day 3 labs
│           └── partials/            # Modular reusable content
│               ├── git-fundamentals/
│               └── [your-lab]/
├── site.yml                         # Antora playbook (DO NOT MODIFY)
└── ui-config.yml                    # Showroom UI configuration
```

## Collaboration Guidelines

### File Naming Conventions

All lab pages follow this pattern:

```
dayN-[lab-name]-[section].adoc
```

Examples:
- `day1-requirements.adoc`
- `day1-git-fundamentals.adoc`
- `day2-lab1-environment.adoc`
- `day2-lab1-ci-pipeline.adoc`

### Directory Organization

**Single Module Approach**: Everything lives in `modules/ROOT/`

**Why?** 
- Simpler navigation structure
- Easier attribute sharing
- Current repository convention

### Modular Content with Partials

For labs with multiple exercises, use partials:

```asciidoc
content/modules/ROOT/
├── pages/
│   └── day2-mylab.adoc              # Main orchestrator
└── partials/
    └── mylab/
        ├── README.md                 # Collaboration guide
        ├── introduction.adoc         # Lab intro
        ├── exercise-01-setup.adoc    # Individual exercises
        ├── exercise-02-build.adoc
        └── summary.adoc              # Wrap-up
```

**Benefits:**
- Multiple contributors can work on different exercises simultaneously
- Reduced merge conflicts
- Individual sections can be reused in other labs
- Easier to review and maintain

### Adding New Content

#### Step 1: Create a Feature Branch

```bash
git checkout -b feature/my-new-lab
```

#### Step 2: Create Your Lab Structure

**Option A: Single File Lab** (Simple, <200 lines)

```bash
# Create the lab file
code content/modules/ROOT/pages/day2-my-lab.adoc
```

**Option B: Modular Lab** (Complex, multiple exercises)

```bash
# Create partials directory
mkdir -p content/modules/ROOT/partials/my-lab

# Create partial files
touch content/modules/ROOT/partials/my-lab/introduction.adoc
touch content/modules/ROOT/partials/my-lab/exercise-01-*.adoc
touch content/modules/ROOT/partials/my-lab/summary.adoc
touch content/modules/ROOT/partials/my-lab/README.md

# Create orchestrator
code content/modules/ROOT/pages/day2-my-lab.adoc
```

**Orchestrator Template:**

```asciidoc
= My Lab Title
:navtitle: My Lab

// Include partials with leveloffset for proper heading hierarchy
include::partial$my-lab/introduction.adoc[leveloffset=+1]

include::partial$my-lab/exercise-01-setup.adoc[leveloffset=+1]

include::partial$my-lab/summary.adoc[leveloffset=+1]
```

#### Step 3: Update Navigation (Minimal Touch)

Edit `content/modules/ROOT/nav.adoc`:

```asciidoc
.Day 2: Software Factory & Application Lifecycle
** Lab 1: Software Factory
* xref:day2-lab1-environment.adoc[Environment Overview]
* xref:day2-my-lab.adoc[My New Lab]  // <-- Add ONE line
```

**Critical**: Only add ONE line for your lab. Don't restructure or reformat.

#### Step 4: Test Locally

```bash
# Start local preview
podman run --rm --name antora \
  -v "C:\Users\sergi\git\etx_app_showroom_content:/antora:z" \
  -p 8080:8080 \
  -it ghcr.io/juliaaano/antora-viewer

# Open http://localhost:8080
# Navigate to your lab and verify content
```

#### Step 5: Commit and Push

```bash
# Stage your changes
git add content/modules/ROOT/pages/day2-my-lab.adoc
git add content/modules/ROOT/partials/my-lab/
git add content/modules/ROOT/nav.adoc

# Commit with conventional commit format
git commit -m "feat: add Day 2 my new lab

- Add modular lab structure
- Create 3 exercises covering X, Y, Z
- Integrate with Day 2 navigation"

# Push to remote
git push -u origin feature/my-new-lab
```

#### Step 6: Create Pull Request

```bash
gh pr create --title "Add Day 2: My New Lab" \
  --body "
## Summary
Adds a new lab for Day 2 covering [topic].

## Content Structure
- Modular partials in \`partials/my-lab/\`
- Main orchestrator at \`pages/day2-my-lab.adoc\`
- Single line addition to navigation

## Testing
- ✅ Tested locally with Antora viewer
- ✅ All partials render correctly
- ✅ No conflicts with existing labs
"
```

## Content Guidelines

### Use Antora Attributes

Reference dynamic values with attributes:

```asciidoc
Login to GitLab: {gitlab_url}
Username: {user}
Password: {password}
OpenShift Console: {openshift_console_url}
```

**Available Attributes:**
See `content/antora.yml` for the complete list.

### Executable Code Blocks

Make commands copy-pasteable:

```asciidoc
[source,bash,role=execute]
----
oc get pods -n myproject
----
```

### Section Levels in Partials

When creating partials that will be included:

```asciidoc
// In partial file: use == for main sections
== Exercise 1: Setup

=== Step 1: Clone Repository

// The orchestrator will use leveloffset=+1 to adjust hierarchy
```

### Commit Message Format

Follow conventional commits:

```
<type>: <subject>

<body>

<footer>
```

**Types:**
- `feat:` New lab or exercise
- `fix:` Fix errors or typos
- `docs:` Documentation updates
- `refactor:` Restructure without changing functionality
- `test:` Add tests or validation

**Examples:**

```
feat: add Day 3 TSSC pipeline exercise

- Create partials for TSSC pipeline lab
- Add exercises for TAS and TPA integration
- Include troubleshooting section
```

```
fix: correct git clone URL in Day 1 lab

The URL was pointing to the wrong repository.
Updated to use the correct GitLab instance.
```

## Avoiding Merge Conflicts

### DO:
- ✅ Work in your own partial directory
- ✅ Add only ONE line to `nav.adoc`
- ✅ Use feature branches
- ✅ Pull latest `main` before creating PR
- ✅ Test locally before pushing

### DON'T:
- ❌ Modify other people's labs
- ❌ Reformat existing files
- ❌ Change `site.yml` or `antora.yml`
- ❌ Restructure navigation
- ❌ Work directly on `main` branch

## Review Checklist

Before submitting PR, verify:

- [ ] Content follows naming conventions (`dayN-*.adoc`)
- [ ] Modular labs use partials structure
- [ ] Only ONE line added to `nav.adoc`
- [ ] Tested locally with Antora viewer
- [ ] Code blocks use `[role=execute]` where appropriate
- [ ] Antora attributes used for dynamic values
- [ ] Commit messages follow conventional format
- [ ] No merge conflicts with `main`
- [ ] Partials include README.md for collaboration

## Getting Help

- **Antora Documentation**: https://docs.antora.org
- **Showroom Template**: https://github.com/rhpds/showroom_template_nookbag
- **Issues**: Create GitHub issue in this repository

## Example: Git Fundamentals Lab

See `content/modules/ROOT/partials/git-fundamentals/` for a complete example of:
- Modular partial structure
- Orchestrator file with includes
- README for collaboration
- Proper heading levels

This lab demonstrates best practices for creating collaborative content.
