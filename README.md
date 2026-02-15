# Resume Compilation System v2.0

A flexible LaTeX-based resume system that generates role-specific versions from a single master document.

## Table of Contents
- [Features](#features)
- [Quick Start](#quick-start)
- [Role Variants](#role-variants)
- [Optional Sections](#optional-sections)
- [Usage Examples](#usage-examples)
- [Migration from v1.0](#migration-from-v10)
- [Technical Architecture](#technical-architecture)
- [Customization Guide](#customization-guide)

---

## Features

✅ **4 Role Variants** - Generate resumes for different positions from one source
✅ **Modular Content** - Different emphasis on skills, projects, and experience
✅ **Optional Sections** - Toggle thesis, soft skills, and educational tools
✅ **Preview Mode** - See configuration before compiling
✅ **Smart Naming** - Auto-generated filenames with descriptive suffixes
✅ **Clean Output** - Automatic cleanup of auxiliary files
✅ **Validation** - Prevents conflicting role selections

---

## Quick Start

### 1. Ensure LaTeX is Installed

```bash
# Ubuntu/Debian
sudo apt-get install texlive-latex-base texlive-latex-extra

# macOS (with Homebrew)
brew install --cask mactex

# Fedora
sudo dnf install texlive-scheme-full
```

### 2. Compile Your First Resume

```bash
# Make script executable (first time only)
chmod +x compile-resume.sh

# Compile for security engineer role
./compile-resume.sh --security

# Output: resume-security-engineer.pdf
```

### 3. Check Available Options

```bash
./compile-resume.sh --help
```

---

## Role Variants

The system supports 4 distinct role profiles:

| Role | Flag | Best For | Output File |
|------|------|----------|-------------|
| **Cryptography Engineer** | `--crypto` | Defense contractors, cryptography-focused companies, research labs | `resume-cryptography-engineer.pdf` |
| **Security Engineer** | `--security` | Tech companies, cybersecurity vendors, fintech | `resume-security-engineer.pdf` |
| **Software Engineer** | `--software` | General tech companies, startups, product teams | `resume-software-engineer.pdf` |
| **Applied Cryptographer** | `--applied` | Research institutions, R&D teams, academic-industry hybrid roles | `resume-applied-cryptographer.pdf` |

### What Changes Between Roles?

Each role variant customizes:

1. **Professional Summary** - Different career objectives and value propositions
2. **Skills Order** - Cryptography first vs. programming first
3. **Experience Bullets** - Security validation vs. architecture vs. research emphasis
4. **Project Descriptions** - Cryptographic focus vs. engineering focus vs. research focus
5. **Section Presence** - Soft skills more prominent for security/research roles

---

## Optional Sections

### Thesis Section (`--thesis`)

**Include when:**
- Applying to research-oriented roles
- Targeting companies valuing academic contributions
- Position emphasizes R&D or cryptographic protocol design

**Exclude when:**
- Applying to pure software engineering roles
- Thesis is less relevant than other projects
- Space is limited (trying to keep to 1-2 pages)

### Soft Skills Section (`--soft-skills`)

**Include when:**
- Applying to senior or team lead positions
- Job description emphasizes collaboration, communication, or mentorship
- Targeting defense contractors, government, or large enterprises
- Position requires stakeholder management or cross-team coordination

**Exclude when:**
- Applying to pure IC (individual contributor) technical roles
- Startup or small team positions (culture assessed in interview)
- Research-heavy positions (publications speak louder)
- Technical skills are the primary evaluation criteria

**Default:** Excluded (technical skills emphasized)

### Conference Presentations Section (`--conferences`)

**Include when:**
- Applying to research-oriented roles (Applied Cryptographer, research labs)
- Job description mentions publications, academic contributions, or thought leadership
- Targeting positions that value public speaking and community engagement
- Position emphasizes conference attendance or technical evangelism

**Exclude when:**
- Applying to pure engineering/implementation roles
- Space is limited and technical projects are more important
- Company culture doesn't emphasize external engagement

**Default:** Excluded (more space for technical content)

### Educational Tools Section (`--no-edu-tools`)

**Included by default** - showcases:
- Web development skills
- Open-source contributions
- Public engagement and teaching ability
- Ability to simplify complex concepts

**Exclude with `--no-edu-tools` when:**
- Space is extremely limited
- Position has no teaching/education component
- Pure backend/systems role with no frontend work

### Pixel Lab Project (`--no-pixel-lab` for its exclusion)

**Include when:**
- Job requires Python programming skills
- Position involves security testing or PRNG validation
- Role emphasizes statistical analysis or data science
- Company values multi-language proficiency
- Space permits showing breadth of skills

**Exclude when (use `--no-pixel-lab`):**
- Space is extremely limited (1 page requirement)
- Position focuses exclusively on C/C++ development
- Pure cryptographic theory role with no implementation
- Resume already shows sufficient Python skills elsewhere

---

## Usage Examples

### Basic Compilation

```bash
# Cryptography Engineer (most specialized)
./compile-resume.sh --crypto

# Security Engineer (balanced)
./compile-resume.sh --security

# Software Engineer (broadest)
./compile-resume.sh --software

# Applied Cryptographer (research focus)
./compile-resume.sh --applied
```

### With Optional Sections

```bash
# Security engineer with thesis and soft skills
./compile-resume.sh --security --thesis --soft-skills
# Output: resume-security-engineer-thesis-soft.pdf

# Software engineer
./compile-resume.sh --software
# Output: resume-software-engineer.pdf

# Applied cryptographer with research-focused sections
./compile-resume.sh --applied --thesis --conferences --no-pixel-lab
# Output: resume-applied-cryptographer-thesis-conf.pdf

# Cryptography engineer forcing Pixel Lab exclusion
./compile-resume.sh --crypto --thesis --no-pixel-lab
# Output: resume-cryptography-engineer-thesis.pdf
```

### Preview Before Compiling

```bash
# See what will be generated
./compile-resume.sh --security --thesis --preview

# Output shows:
# - Role name and configuration
# - Which sections are included/excluded
# - Expected output filename
# - Prompts for confirmation before compiling
```

### Cleanup

```bash
# Remove auxiliary LaTeX files
./compile-resume.sh --clean
```

---

## Technical Architecture

### File Structure

```
resume-system/
├── resume.tex              # Master resume with conditional content
├── compile-resume.sh       # Compilation orchestrator
├── README.md              # This file
└── output/
    ├── resume-cryptography-engineer.pdf
    ├── resume-security-engineer.pdf
    ├── resume-software-engineer.pdf
    └── resume-applied-cryptographer.pdf
```

### How It Works

1. **Master Document (`resume.tex`)**
   - Contains all possible content variants
   - Uses LaTeX conditionals (`\newif`) for role selection
   - Defines content variant macros for each section

2. **Compilation Script (`compile-resume.sh`)**
   - Validates role selection (prevents conflicts)
   - Creates temporary preamble with flags
   - Concatenates preamble + master document
   - Compiles with `pdflatex`
   - Cleans auxiliary files

3. **Conditional Logic**
   ```latex
   % Only shown for cryptography engineer
   \showcrypto{Content here...}
   
   % Only shown for security OR software roles
   \showsecurityorsoftware{Content here...}
   
   % Shown for all engineering roles (excludes applied)
   \showengineering{Content here...}
   ```

### LaTeX Conditional Flags

These flags are defined in `compile-resume.sh` and prepended to the document:

| Flag | Role/Section |
|------|------|
| `\ifcryptoengineer` | Cryptography Engineer |
| `\ifsecurityengineer` | Security Engineer |
| `\ifsoftwareengineer` | Software Engineer |
| `\ifappliedcrypto` | Applied Cryptographer |
| `\ifincludethesis` | Thesis section |
| `\ifincludesoftskills` | Soft skills section |
| `\ifincludeedutools` | Educational tools section |
| `\ifincludeconferences` | Conference presentations section |

---

## Customization Guide

### Adding New Content

#### 1. Add Content to `resume.tex`

```latex
% In the appropriate section
\showcrypto{
    \item New bullet point for cryptography engineer only
}

\showsoftware{
    \item Different bullet point for software engineer
}
```

#### 2. Add Role-Agnostic Content

```latex
% This appears in ALL versions
\item Universal bullet point for all roles
```

#### 3. Add Conditional Sections

```latex
% Define new conditional
\newif\ifincludemyproject

% Use it in document
\ifincludemyproject
    \subsection{My Project}
    ...
\fi
```

### Adding New Roles

If you need to add a 5th role variant:

1. **Edit `resume.tex`** - Add new conditional:
```latex
\newif\ifmynewrole
\newcommand{\shownewrole}[1]{\ifmynewrole#1\fi}
```

2. **Edit `compile-resume.sh`** - Add new option:
```bash
--mynewrole)
    ROLE="mynewrole"
    ROLE_FLAG="mynewroletrue"
    ROLE_NAME="My New Role Title"
    OUTPUT_SUFFIX="my-new-role"
    ;;
```

3. **Add Content Variants** - Update sections in `resume.tex`:
```latex
\shownewrole{
    Content specific to my new role...
}
```

### Modifying Existing Content

All content is in `resume.tex` within these macros:
- `\professionalsummary` - Opening summary paragraph
- `\technicalskills` - Skills section
- `\professionalexperience` - Work experience bullets
- `\projectsection` - Project descriptions
- `\educationaltoolssection` - Portfolio/demos
- `\softskillssection` - Professional skills
- `\conferencesection` - Publications/presentations
- `\educationsection` - Academic credentials

Edit the macro content directly to update your resume.

---

## Troubleshooting

### Compilation Fails

**Problem:** `pdflatex` errors during compilation

**Solutions:**
1. Check the log file: `resume-[role].log`
2. Look for LaTeX syntax errors
3. Ensure all required packages are installed
4. Try manual compilation for debugging:
   ```bash
   pdflatex resume.tex
   ```

### Wrong Content Appears

**Problem:** Seeing content from wrong role

**Solutions:**
1. Verify only ONE role flag is set in script output
2. Use `--preview` to check configuration
3. Clean and recompile:
   ```bash
   ./compile-resume.sh --clean
   ./compile-resume.sh --security --preview
   ```

### Multiple Roles Specified Error

**Problem:** Script rejects compilation with "Multiple roles specified"

**Solution:** Use exactly one role flag:
```bash
# ❌ WRONG - don't do this
./compile-resume.sh --crypto --security

# ✅ CORRECT
./compile-resume.sh --crypto
```

---

## Best Practices

### When to Use Each Role

| Job Posting Signals | Recommended Role |
|---------------------|------------------|
| "Cryptography", "post-quantum", "cryptographic protocols" | `--crypto` |
| "Security engineer", "cryptographic implementations", "NIST compliance" | `--security` |
| "Software engineer", "backend", "C++", "systems" | `--software` |
| "Applied cryptographer", "research", "R&D", "cryptographic research" | `--applied` |

### Resume Length Guidelines

- **1 page:** Software Engineer (exclude thesis, exclude soft skills)
- **1.5-2 pages:** Security/Crypto Engineer (include thesis OR soft skills)
- **2 pages:** Applied Cryptographer (include thesis AND soft skills)

### Testing Your Resume

Before sending:
```bash
# Generate all versions
./compile-resume.sh --crypto > /dev/null
./compile-resume.sh --security > /dev/null
./compile-resume.sh --software > /dev/null
./compile-resume.sh --applied > /dev/null

# Review each PDF
ls -lh resume-*.pdf

# Pick the best match for the job
```

---

## FAQ

**Q: Can I use multiple roles at once?**  
A: No, the system enforces mutual exclusivity. Choose the single best-matching role.

**Q: What's the difference between `--crypto` and `--applied`?**  
A: `--crypto` emphasizes engineering/implementation; `--applied` emphasizes research/theory.

**Q: Should I always include soft skills?**  
A: No - only for senior roles, management positions, or when collaboration is emphasized.

**Q: How do I add my own projects?**  
A: Edit the `\projectsection` macro in `resume.tex`, following the existing pattern.

**Q: Can I change the order of sections?**  
A: Yes - reorder the macro calls in the document body at the end of `resume.tex`.

---

## Future Enhancements

Potential improvements for future versions:

- [ ] ATS keyword optimization per role
- [ ] PDF metadata customization
- [ ] Cover letter generation
- [ ] Automated job description analysis
- [ ] LaTeX template variants (different layouts)
- [ ] Multi-language support
- [ ] GitHub Actions for automated compilation

---

## Support

For issues or questions:
- GitHub: [@fer-osorio](https://github.com/fer-osorio)
- Email: alexis.fernando.osorio.sarabio@gmail.com

---

## License

This resume system is provided as-is for personal use.

---

**Version:** 2.0  
**Last Updated:** 2025-02-11  
**Author:** Alexis Fernando Osorio Sarabio
