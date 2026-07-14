# ETX Workshop Structure Correction

## Current Problem

We created `day1-git-fundamentals.adoc` (30+ minute lab) that doesn't fit the workshop structure.

## Workshop Day 1 Actual Agenda

```
Day 1 Afternoon (5+ hours):
├─ DevX Assessment Solution (1H)
├─ Fundamental Knowledge Presentations (2H)
│  └─ IDPs, inner/outer loop, SDLC, TDD, Platform Engineering, Golden Path
├─ MBPM (2H)
│  └─ Theoretical + Exercise
└─ Lab Setup (45M TOTAL) ← Only 45 minutes for ALL lab/setup
   ├─ Branching Strategies (Presentation & Lab)
   └─ Requirements (Git Server + Git Client validation)
```

**Key Points:**
- Day 1 = Presentations + Theory (5+ hours)
- Day 1 = Setup/Validation (45 minutes)
- Day 1 ≠ Hands-on Labs

**Compare with Day 2/3:**
- Day 2/3 = Overview (presentation) + Lab 1 (hands-on) + Lab 2 (hands-on)
- Day 2/3 = Multiple hours of hands-on exercises

## Recommended Structure

### **Day 1: Foundation & Setup (45 minutes)**

#### Part 1: Requirements & Environment Setup (10-15 min)

```asciidoc
= Requirements & Environment Setup

== Verify OpenShift Cluster Access
[source,bash]
----
oc login --server=<cluster-url>
oc whoami
oc get nodes
----

== Verify Git Client
[source,bash]
----
git --version
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
----

== Verify Git Server Access
[source,bash]
----
# Test GitLab access
curl -I {gitlab_url}

# Clone test repo (if available)
git clone {gitlab_url}/test/example.git
----

== Next Steps
Proceed to xref:day1-branching-strategies.adoc[Branching Strategies].
```

#### Part 2: Branching Strategies (30-35 min)

```asciidoc
= Branching Strategies
:navtitle: Branching Strategies

== Git Basics Validation (5 minutes)

Quick verification that Git works:

[source,bash]
----
# Clone the workshop repository
git clone {gitlab_url}/software-factory/parasol-insurance-lab.git
cd parasol-insurance-lab

# Verify basic commands work
git status
git branch
git log --oneline -5
----

== Branching Models Presentation (15-20 minutes)

=== Trunk-Based Development
* Single main branch
* Short-lived feature branches
* Frequent integration
* Best for: Continuous delivery, small teams

=== GitFlow
* Multiple long-lived branches (develop, release, hotfix)
* Structured release process
* Well-defined promotion path
* Best for: Scheduled releases, larger teams

=== GitHub Flow
* Simplified: main + feature branches
* Pull requests for all changes
* CI/CD on every merge
* Best for: Continuous deployment, web applications

=== Choosing the Right Model
[comparison table and decision tree]

== Lab Exercise: Branching in Practice (10-15 minutes)

=== Exercise 1: Create a Feature Branch

[source,bash]
----
# Create and switch to feature branch
git checkout -b feature/update-readme

# Make a simple change
echo "## Workshop Notes" >> README.md

# Stage and commit
git add README.md
git commit -m "docs: add workshop notes section"

# View your commit
git log --oneline -1
----

=== Exercise 2: Push to Remote

[source,bash]
----
# Push your branch
git push -u origin feature/update-readme

# Verify in GitLab UI
----

=== Exercise 3: Simulate Branch Merge

[source,bash]
----
# Switch to main
git checkout main

# Merge your feature (instructor demo or individual)
git merge feature/update-readme

# Clean up
git branch -d feature/update-readme
----

== Key Takeaways

* Git branching enables parallel development
* Different models suit different team workflows
* Choose based on: team size, release cadence, deployment frequency
* Day 2 labs will use these concepts with CI/CD pipelines

== Next Steps

You're now ready for Day 2:
* xref:day2-lab1-environment.adoc[Software Factory Lab]
* CI/CD with Tekton
* GitOps with Argo CD
```

**Total time: ~35 minutes**

## What to Do with Git Fundamentals

### Option 1: Delete (Recommended for Minimal Change)

Simply remove `day1-git-fundamentals.adoc` and its partials. The expanded Branching Strategies provides sufficient Git validation.

**Pros:**
- Clean, fits workshop structure
- No confusion
- Matches Day 1 timing

**Cons:**
- Loses detailed Git content
- Assumes attendees know Git basics

### Option 2: Move to Pre-Work Module

Create optional pre-workshop content for self-study:

```
content/modules/
├─ ROOT/
│  └─ pages/day1-*.adoc
└─ prework/
   ├─ nav.adoc
   ├─ pages/
   │  ├─ index.adoc
   │  └─ git-fundamentals.adoc
   └─ partials/git-fundamentals/
```

Update main nav:

```asciidoc
.Pre-Workshop (Optional)
* xref:prework:index.adoc[Pre-Work Overview]
* xref:prework:git-fundamentals.adoc[Git Fundamentals Refresher]

.Day 1: Foundation & Setup
...
```

**Pros:**
- Preserves detailed Git content
- Helps attendees who need Git refresher
- Doesn't interfere with workshop timing

**Cons:**
- More complex module structure
- Optional content might be ignored

### Option 3: External Reference

Keep `git-fundamentals.adoc` but reference it only as optional reading:

```asciidoc
.Additional Resources (Not Part of Workshop)
* xref:resources-git-fundamentals.adoc[Git Fundamentals Deep Dive]
```

**Pros:**
- Available for those who want it
- Doesn't impact workshop flow

**Cons:**
- Might confuse structure

## Recommended Action Plan

1. **Expand `day1-branching-strategies.adoc`**
   - Add 5-minute Git validation
   - Keep 15-minute presentation
   - Keep 10-minute exercise
   - Total: ~30 minutes

2. **Keep `day1-requirements.adoc` simple**
   - 10-15 minutes max
   - Just verification, no deep setup

3. **Handle Git Fundamentals:**
   - **Immediate:** Delete from Day 1 structure
   - **Future:** Consider pre-work module if there's demand
   - **Document:** Add note in CONTRIBUTING.md about workshop vs pre-work content

4. **Update navigation:**
   ```asciidoc
   .Day 1: Foundation & Setup (45 minutes)
   * xref:day1-requirements.adoc[Requirements & Environment Setup]
   * xref:day1-branching-strategies.adoc[Branching Strategies]
   ```

5. **Commit message:**
   ```
   refactor: restructure Day 1 to match workshop timing (45 min)

   BREAKING CHANGE: Remove Git Fundamentals lab

   - Remove day1-git-fundamentals.adoc (doesn't fit 45-min Day 1)
   - Expand day1-branching-strategies.adoc with Git validation
   - Day 1 is now: Requirements (15 min) + Branching Strategies (30 min)

   Rationale:
   - Day 1 agenda allows only 45 minutes total for "Lab Setup"
   - Branching Strategies includes Presentation & Lab per workshop design
   - Git Fundamentals (30 min) was too extensive for Day 1 scope
   - Day 1 focuses on foundation/validation, not hands-on labs
   - Day 2/3 contain the actual hands-on lab exercises

   Workshop Structure:
   Day 1: Presentations (5+ hours) + Setup/Validation (45 min)
   Day 2: Overview + Lab 1 + Lab 2 (hands-on)
   Day 3: Overview + Lab 3 (hands-on)
   ```

## Testing

After restructure, verify:

```bash
# Total time for Day 1 content
- Requirements reading time: ~10 minutes
- Branching Strategies reading + exercises: ~30 minutes
- Total: ~40 minutes (fits in 45-minute slot) ✓

# Day 1 purpose
- Validates environment is ready ✓
- Introduces branching concepts ✓
- Prepares for Day 2 GitOps/CI/CD ✓
- Doesn't duplicate Day 2 content ✓
```

## Documentation Updates Needed

1. **CONTRIBUTING.md**
   - Add section on "Workshop vs Pre-Work content"
   - Explain Day 1 timing constraints
   - Document 45-minute limit

2. **README.adoc**
   - Update Day 1 description
   - Clarify Day 1 = setup, Day 2/3 = labs

3. **content/antora.yml**
   - Add timing attributes if needed
   - Document workshop phases
