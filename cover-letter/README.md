# Cover Letter Automation System v1.0

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

Modes:
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
cover-letter-<company-slug>-<role>.pdf
```

Examples: `cover-letter-anthropic-crypto.pdf` · `cover-letter-stripe-security.pdf`

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
```

---

**Version:** 1.0 · **Author:** Alexis Fernando Osorio Sarabio
