# Cover Letter Automation System v2.0

Generates role-specific cover letters in PDF format from a single LaTeX template.
Architecture mirrors **Resume Compilation System v2.0**.

---

## Quick Start

```bash
# 1. Make executable (first time only)
chmod +x compile-cover-letter.sh

# 2. Create a JSON config (copy & edit a template)
cp configs/examples/template-role-specific.json configs/mycompany.json
$EDITOR configs/mycompany.json

# 3. Compile
./compile-cover-letter.sh --security --json configs/mycompany.json

# Output: cover-letter-mycompany-security.pdf
```

**Dependencies:** `pdflatex` (texlive) · `python3`

---

## Roles

| Flag | Title | Best for |
|------|-------|----------|
| `--crypto` | Cryptography Engineer | Defense, crypto-focused startups, research labs |
| `--security` | Security Engineer | Tech companies, fintech, cybersecurity vendors |
| `--software` | Software Engineer | General tech, startups, product teams |
| `--applied` | Applied Cryptographer | R&D teams, research institutions |
| `--general` | General Application | Networking, open applications |

---

## JSON Configuration

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
| `manual` | Use only the `add` list (+ ntru default) |
| `hybrid` | Auto-select, then apply `add`/`remove` |

**Project IDs:** `ntru` · `aes` · `pixel-lab` · `thesis` · `educational-tools`

`ntru` is always included by default unless explicitly removed.

---

## CLI Reference

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

---

## Examples

```bash
# Security engineer, Stripe — auto project selection
./compile-cover-letter.sh --security --json configs/examples/security-stripe.json

# Applied cryptographer, preview first
./compile-cover-letter.sh --applied --json configs/examples/applied-mozilla.json --preview

# Software engineer: add pixel-lab, drop thesis
./compile-cover-letter.sh --software --json configs/examples/software-vercel.json \
    --add-project pixel-lab --remove-project thesis

# General application with manual project list
./compile-cover-letter.sh --general --json configs/examples/general-janestreet.json

# Crypto engineer, ATS-heavy role — include thesis too
./compile-cover-letter.sh --crypto --json configs/anthropic.json --add-project thesis
```

---

## Output

Files are written to the working directory:

```
cover-letter-<company-slug>-<role>[-<lang>].pdf
```

The language suffix is appended only for non-English output:

| Command | Output filename |
|---------|----------------|
| `--security --json ...` | `cover-letter-stripe-security.pdf` |
| `--security --json ... --lang en` | `cover-letter-stripe-security.pdf` |
| `--security --json ... --lang es` | `cover-letter-stripe-security-es.pdf` |

---

## Language Support

### Supported Languages

| Code | Language | Default |
|------|----------|---------|
| `en` | English  | ✅ yes  |
| `es` | Spanish  | no      |

### Usage

```bash
# Default (English)
./compile-cover-letter.sh --security --json configs/stripe.json

# Spanish
./compile-cover-letter.sh --security --json configs/stripe.json --lang es
# Output: cover-letter-stripe-security-es.pdf
```

### Adding a New Language

1. Create `content/<code>-cover.tex` at the project root, defining all macros
   present in `content/en-cover.tex`.
2. Add the language code to `SUPPORTED_LANGS` in `compile-cover-letter.sh`:
   ```bash
   SUPPORTED_LANGS=("en" "es" "de")
   ```
3. Compile: `./compile-cover-letter.sh --security --json configs/myco.json --lang de`

---

## Project Relevance Matrix

Higher = more likely to be auto-selected for that role.

| Project | crypto | security | software | applied | general |
|---------|--------|----------|----------|---------|---------|
| ntru | 10 | 9 | 7 | 10 | 8 |
| aes | 9 | 10 | 8 | 7 | 7 |
| pixel-lab | 7 | 8 | 9 | 8 | 6 |
| thesis | 8 | 7 | 5 | 10 | 6 |
| educational-tools | 5 | 6 | 7 | 6 | 8 |

---

## Troubleshooting

**Compilation fails** → check `<output-name>.log` for LaTeX errors.

**"No projects selected"** → your remove list eliminated all projects; add at least one via `--add-project` or remove an entry from the `remove` list.

**"Invalid project ID"** → valid IDs are: `ntru`, `aes`, `pixel-lab`, `thesis`, `educational-tools`.

**JSON errors** → validate at https://jsonlint.com; common issues: trailing commas, unescaped quotes.

---

## File Structure

```
cover-letter/
├── compile-cover-letter.sh
├── configs
│   ├── examples
│   │   ├── crypto-antropic.json
│   │   └── general-janestreet.json
│   ├── schema.json
│   └── templates
│       ├── general.json
│       └── role-specific.json
├── cover-letter.tex
├── projects
│   └── project-definitions.json
└── README.md

content/                        # project root (shared with resume system)
├── en-cover.tex                # English cover letter macros
└── es-cover.tex                # Spanish cover letter macros
```

---

**Version:** 2.0 · **Last Updated:** 2026-04-06 · **Author:** Alexis Fernando Osorio Sarabio
