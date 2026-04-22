# dynamic-resume

A LaTeX-based system for generating role-specific resumes and cover letters from a single master document per artifact.

---

## Table of Contents

- [Overview](#overview)
- [Dependencies](#dependencies)
- [Role Variants](#role-variants)
- [Resume System](#resume-system)
  - [Quick Start](#resume-quick-start)
  - [Optional Sections](#optional-sections)
  - [Usage Examples](#resume-usage-examples)
  - [Technical Architecture](#technical-architecture)
  - [Customization Guide](#customization-guide)
- [Cover Letter System](#cover-letter-system)
  - [Quick Start](#cover-letter-quick-start)
  - [JSON Configuration](#json-configuration)
  - [CLI Reference](#cli-reference)
  - [Usage Examples](#cover-letter-usage-examples)
  - [Project Relevance Matrix](#project-relevance-matrix)
- [Language Support](#language-support)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [FAQ](#faq)

---

## Overview

Two compilation systems sharing a common content directory:

- **Resume Compilation System** — generates role-specific resumes from `resume.tex` via `compile-resume.sh`
- **Cover Letter Automation System** — generates role-specific cover letters from `cover-letter.tex` via `compile-cover-letter.sh`

Both systems follow the same architecture: a language-agnostic LaTeX master document, role flags passed as preamble conditionals, and a `content/` directory of macro definition files.

---

## Dependencies

```bash
# Ubuntu/Debian
sudo apt-get install texlive-latex-base texlive-latex-extra

# macOS (Homebrew)
brew install --cask mactex

# Fedora
sudo dnf install texlive-scheme-full
```

The cover letter system also requires `python3` for project selection logic.

---

## Role Variants

Both systems support the same role flags:

| Flag | Title | Best For |
|------|-------|----------|
| `--crypto` | Cryptography Engineer | Defense contractors, cryptography-focused companies, research labs |
| `--security` | Security Engineer | Tech companies, cybersecurity vendors, fintech |
| `--software` | Software Engineer | General tech, startups, product teams |
| `--applied` | Applied Cryptographer | R&D teams, research institutions, academic-industry hybrid roles |
| `--general` | General Application | Cover letters only: networking, open applications |

---

## Resume System

### Quick Start

```bash
# Make executable (first time only)
chmod +x compile-resume.sh

# Compile for security engineer role
./compile-resume.sh --security
# Output: resume-security-engineer.pdf

# See all options
./compile-resume.sh --help
```

### Optional Sections

#### Thesis (`--thesis`)

Include when applying to research-oriented roles, targeting companies valuing academic contributions, or where the position emphasizes R&D or cryptographic protocol design. Exclude for pure software engineering roles or when space is limited.

#### Soft Skills (`--soft-skills`)

Include for senior or team lead positions, roles emphasizing collaboration or stakeholder management, and defense/government/enterprise targets. Exclude for pure IC technical roles, research-heavy positions, or startups where culture is assessed in interview. Default: excluded.

#### Conference Presentations (`--conferences`)

Include when applying to research-oriented roles or positions that value thought leadership, publications, or technical evangelism. Exclude for pure engineering/implementation roles or when space is limited. Default: excluded.

#### Security Portfolio (`--no-sec-portfolio`)

Included by default. Showcases web development, open-source contributions, and interactive cryptographic demonstrations. Exclude with `--no-sec-portfolio` for space-constrained or pure backend/systems roles with no frontend component.

#### Pixel Lab Project (`--no-pixel-lab`)

Included by default. Demonstrates Python, security testing, and statistical analysis skills. Exclude with `--no-pixel-lab` for strict 1-page requirements, pure C/C++ roles, or when the resume already shows sufficient Python coverage.

### Usage Examples

```bash
# Basic compilation
./compile-resume.sh --crypto
./compile-resume.sh --security
./compile-resume.sh --software
./compile-resume.sh --applied

# With optional sections
./compile-resume.sh --security --thesis --soft-skills
# Output: resume-security-engineer-thesis-soft.pdf

./compile-resume.sh --applied --thesis --conferences --no-pixel-lab
# Output: resume-applied-cryptographer-thesis-conf.pdf

./compile-resume.sh --crypto --thesis --no-pixel-lab
# Output: resume-cryptography-engineer-thesis.pdf

# Preview configuration before compiling
./compile-resume.sh --security --thesis --preview

# Remove auxiliary LaTeX files
./compile-resume.sh --clean
```

**Output filename convention:**

```
resume-<role>[-<sections>][-<lang>].pdf
```

### Technical Architecture

#### File Structure

```
resume-system/
├── resume.tex              # Master resume (language-agnostic; macro calls only)
├── compile-resume.sh       # Compilation orchestrator
├── content/
│   ├── en.tex              # English strings (116 macros)
│   └── es.tex              # Spanish strings (116 macros)
└── output/
    ├── resume-cryptography-engineer.pdf
    ├── resume-security-engineer.pdf
    ├── resume-software-engineer.pdf
    └── resume-applied-cryptographer.pdf
```

#### How It Works

1. **`resume.tex`** — contains all content variants using LaTeX conditionals (`\newif`) for role selection
2. **`compile-resume.sh`** — validates role selection, creates a temporary preamble with flags, concatenates preamble + master document, compiles with `pdflatex`, and cleans auxiliary files

#### LaTeX Conditional Flags

| Flag | Role / Section |
|------|----------------|
| `\ifcryptoengineer` | Cryptography Engineer |
| `\ifsecurityengineer` | Security Engineer |
| `\ifsoftwareengineer` | Software Engineer |
| `\ifappliedcrypto` | Applied Cryptographer |
| `\ifincludethesis` | Thesis section |
| `\ifincludesoftskills` | Soft skills section |
| `\ifincludesecportfolio` | Security portfolio section |
| `\ifincludeconferences` | Conference presentations section |

#### Conditional Macros in `resume.tex`

```latex
% Only shown for cryptography engineer
\showcrypto{Content here...}

% Only shown for security OR software roles
\showsecurityorsoftware{Content here...}

% Shown for all engineering roles (excludes applied)
\showengineering{Content here...}
```

### Customization Guide

#### Adding Content to a Role

```latex
\showcrypto{
    \item New bullet point for cryptography engineer only
}

\showsoftware{
    \item Different bullet point for software engineer
}
```

#### Adding Role-Agnostic Content

```latex
% Appears in ALL versions
\item Universal bullet point for all roles
```

#### Adding a New Role

1. Add a new conditional in `resume.tex`:
   ```latex
   \newif\ifmynewrole
   \newcommand{\shownewrole}[1]{\ifmynewrole#1\fi}
   ```
2. Add the flag handler in `compile-resume.sh`:
   ```bash
   --mynewrole)
       ROLE="mynewrole"
       ROLE_FLAG="mynewroletrue"
       ROLE_NAME="My New Role Title"
       OUTPUT_SUFFIX="my-new-role"
       ;;
   ```
3. Add content variants in `resume.tex` using `\shownewrole{...}`.

#### Content Macros

All content lives in `resume.tex` within these macros:

- `\professionalsummary`
- `\technicalskills`
- `\professionalexperience`
- `\projectsection`
- `\secportfoliosection`
- `\softskillssection`
- `\conferencesection`
- `\educationsection`

---

## Cover Letter System

### Quick Start

```bash
# Make executable (first time only)
chmod +x compile-cover-letter.sh

# Copy and edit a config template
cp configs/examples/template-role-specific.json configs/mycompany.json
$EDITOR configs/mycompany.json

# Compile
./compile-cover-letter.sh --security --json configs/mycompany.json
# Output: cover-letter-mycompany-security.pdf
```

### JSON Configuration

**Required fields:**

```json
{
  "company": {
    "name": "Anthropic",
    "position": "Security Engineer",
    "focus_area": "cryptographic safety research"
  },
  "job_requirements": {
    "primary": "post-quantum cryptography",
    "secondary": "NIST compliance",
    "tertiary": null
  },
  "projects": {
    "mode": "auto",
    "add": [],
    "remove": []
  },
  "customization": {
    "opening_hook": null,
    "closing_note": null
  }
}
```

**`projects.mode`**

| Value | Behaviour |
|-------|-----------|
| `auto` | Select top 3 projects by role relevance |
| `manual` | Use only the `add` list (+ `ntru` default) |
| `hybrid` | Auto-select, then apply `add`/`remove` |

**Project IDs:** `ntru` · `aes` · `pixel-lab` · `thesis` · `security-portfolio`

`ntru` is always included by default unless explicitly removed.

### CLI Reference

```bash
./compile-cover-letter.sh <role> --json <path> [options]

Roles (choose one):  --crypto  --security  --software  --applied  --general

Required:
  --json <path>           JSON configuration file

Project overrides:
  --add-project <id>      Add a project (repeatable)
  --remove-project <id>   Remove a project (repeatable)

Options:
  --lang <code>           Output language: en (default), es
  --preview               Show configuration, prompt before compiling
  --clean                 Remove auxiliary LaTeX files
  --help                  Show help
```

### Usage Examples

```bash
# Security engineer, Stripe
./compile-cover-letter.sh --security --json configs/examples/security-stripe.json

# Applied cryptographer, preview first
./compile-cover-letter.sh --applied --json configs/examples/applied-mozilla.json --preview

# Software engineer: add pixel-lab, drop thesis
./compile-cover-letter.sh --software --json configs/examples/software-vercel.json \
    --add-project pixel-lab --remove-project thesis

# General application
./compile-cover-letter.sh --general --json configs/examples/general-janestreet.json

# Crypto engineer, include thesis
./compile-cover-letter.sh --crypto --json configs/anthropic.json --add-project thesis
```

**Output filename convention:**

```
cover-letter-<company-slug>-<role>[-<lang>].pdf
```

### File Structure

```
cover-letter/
├── compile-cover-letter.sh
├── configs/
│   ├── examples/
│   │   ├── crypto-antropic.json
│   │   └── general-janestreet.json
│   ├── schema.json
│   └── templates/
│       ├── general.json
│       └── role-specific.json
├── cover-letter.tex
└── projects/
    └── project-definitions.json

content/                        # project root (shared with resume system)
├── en-cover.tex                # English cover letter macros
└── es-cover.tex                # Spanish cover letter macros
```

### Project Relevance Matrix

Higher score = more likely to be auto-selected for that role.

| Project | crypto | security | software | applied | general |
|---------|--------|----------|----------|---------|---------|
| ntru | 10 | 9 | 7 | 10 | 8 |
| aes | 9 | 10 | 8 | 7 | 7 |
| pixel-lab | 7 | 8 | 9 | 8 | 6 |
| thesis | 8 | 7 | 5 | 10 | 6 |
| security-portfolio | 5 | 6 | 7 | 6 | 8 |

---

## Language Support

Both systems support the same languages via a `--lang` flag.

### Supported Languages

| Code | Language | Default |
|------|----------|---------|
| `en` | English | yes |
| `es` | Spanish | no |

### Usage

```bash
# Resume — default English, no flag needed
./compile-resume.sh --security

# Resume — Spanish
./compile-resume.sh --security --lang es
# Output: resume-security-engineer-es.pdf

# Resume — Spanish with optional sections
./compile-resume.sh --applied --thesis --conferences --lang es
# Output: resume-applied-cryptographer-thesis-conf-es.pdf

# Cover letter — default English
./compile-cover-letter.sh --security --json configs/stripe.json

# Cover letter — Spanish
./compile-cover-letter.sh --security --json configs/stripe.json --lang es
# Output: cover-letter-stripe-security-es.pdf
```

The language suffix is appended only for non-English output. Passing `--lang en` produces the same filename as omitting the flag entirely.

### Adding a New Language

**Resume system:**

1. Create `content/<code>.tex` defining all macros present in `content/en.tex`. Every macro name must match exactly — no additions or omissions.
2. Add the language code to `SUPPORTED_LANGS` in `compile-resume.sh`:
   ```bash
   SUPPORTED_LANGS=("en" "es" "de")
   ```
3. Compile and verify: `./compile-resume.sh --security --lang de`

**Cover letter system:**

1. Create `content/<code>-cover.tex` at the project root, defining all macros present in `content/en-cover.tex`.
2. Add the language code to `SUPPORTED_LANGS` in `compile-cover-letter.sh`:
   ```bash
   SUPPORTED_LANGS=("en" "es" "de")
   ```
3. Compile and verify: `./compile-cover-letter.sh --security --json configs/myco.json --lang de`

---

## Troubleshooting

### Resume

**Compilation fails** — check `resume-[role].log` for LaTeX errors. For interactive debugging: `pdflatex resume.tex`

**Wrong content appears** — use `--preview` to inspect the active configuration, then clean and recompile:
```bash
./compile-resume.sh --clean
./compile-resume.sh --security --preview
```

**"Multiple roles specified" error** — exactly one role flag is required:
```bash
# Wrong
./compile-resume.sh --crypto --security

# Correct
./compile-resume.sh --crypto
```

### Cover Letter

**Compilation fails** — check `<output-name>.log` for LaTeX errors.

**"No projects selected"** — the remove list eliminated all projects. Add at least one via `--add-project` or shorten the `remove` list in the JSON config.

**"Invalid project ID"** — valid IDs are: `ntru`, `aes`, `pixel-lab`, `thesis`, `security-portfolio`.

**JSON parse errors** — common causes: trailing commas, unescaped quotes.

---

## Best Practices

### Choosing a Role

| Job Posting Signals | Recommended Role |
|---------------------|------------------|
| "Cryptography", "post-quantum", "cryptographic protocols" | `--crypto` |
| "Security engineer", "cryptographic implementations", "NIST compliance" | `--security` |
| "Software engineer", "backend", "C++", "systems" | `--software` |
| "Applied cryptographer", "research", "R&D" | `--applied` |

### Resume Length Guidelines

- **1 page:** `--software` — exclude thesis, exclude soft skills
- **1.5–2 pages:** `--security` / `--crypto` — include thesis OR soft skills
- **2 pages:** `--applied` — include thesis AND soft skills

### Verifying All Variants

```bash
./compile-resume.sh --crypto
./compile-resume.sh --security
./compile-resume.sh --software
./compile-resume.sh --applied
ls -lh output/resume-*.pdf
```

---

## FAQ

**Can I use multiple roles at once?**
No. Both systems enforce mutual exclusivity. Choose the single best-matching role.

**What is the difference between `--crypto` and `--applied`?**
`--crypto` emphasizes engineering and implementation; `--applied` emphasizes research and theory.

**Should I always include soft skills?**
No — only for senior roles, management positions, or when collaboration is explicitly emphasized in the job description.

**How do I add a project to the resume?**
Edit the `\projectsection` macro in `resume.tex`, following the existing pattern.

**Can I change the section order?**
Yes — reorder the macro calls in the document body at the end of `resume.tex`.

**How do I add a project to a specific cover letter without modifying the JSON?**
Use `--add-project <id>` on the command line; it takes precedence over the config file.

---

*Resume Compilation System v3.0 · Cover Letter Automation System v2.0 · Last Updated: 2026-04-07 · Author: Alexis Fernando Osorio Sarabio*
