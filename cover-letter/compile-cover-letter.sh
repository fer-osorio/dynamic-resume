#!/bin/bash

# =============================================================================
# Cover Letter Compiler v1.0
# =============================================================================
# Generates role-specific cover letters in PDF format.
# Architecture mirrors compile-resume.sh v2.0.
#
# Usage: ./compile-cover-letter.sh <role> --json <config.json> [options]
# =============================================================================

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# =============================================================================
# Configuration Variables
# =============================================================================
ROLE=""
ROLE_FLAG=""
ROLE_NAME=""

JSON_CONFIG=""
PREVIEW_MODE=false
CLEAN_ONLY=false

# Project overrides (space-separated project IDs)
ADD_PROJECTS=()
REMOVE_PROJECTS=()

# Internal state (populated after selection)
SELECTED_PROJECTS=()

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DB="${SCRIPT_DIR}/projects/project-definitions.json"
TEMPLATE="${SCRIPT_DIR}/cover-letter.tex"

# Valid project IDs
VALID_PROJECT_IDS=("ntru" "aes" "pixel-lab" "thesis" "educational-tools")

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "${BOLD}  Cover Letter Compiler v1.0${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo ""
}

print_success() { echo -e "${GREEN}✔${NC} $1"; }
print_error()   { echo -e "${RED}✘${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_info()    { echo -e "${BLUE}ℹ${NC} $1"; }

# =============================================================================
# Validation
# =============================================================================

validate_role() {
    if [ -z "$ROLE" ]; then
        print_error "No role specified."
        echo ""
        echo "Choose exactly one: --crypto  --security  --software  --applied  --general"
        echo "Run './compile-cover-letter.sh --help' for usage."
        exit 1
    fi
}

validate_json_arg() {
    if [ -z "$JSON_CONFIG" ]; then
        print_error "No JSON configuration file specified."
        echo ""
        echo "Usage: ./compile-cover-letter.sh <role> --json <path/to/config.json>"
        echo "See configs/examples/ for templates."
        exit 1
    fi
}

check_dependencies() {
    local missing=()

    if ! command -v pdflatex &>/dev/null; then
        missing+=("pdflatex (install texlive-latex-base)")
    fi

    if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
        missing+=("python3 (for JSON parsing)")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        print_error "Missing dependencies:"
        for dep in "${missing[@]}"; do
            echo "  • $dep"
        done
        exit 1
    fi
}

# =============================================================================
# JSON Handling
# =============================================================================

# Portable JSON field extractor (no jq dependency)
json_get() {
    local file="$1"
    local field="$2"
    python3 -c "
import json, sys
try:
    with open('$file') as f:
        data = json.load(f)
    keys = '$field'.split('.')
    val = data
    for k in keys:
        val = val[k]
    print(val if val is not None else '')
except (KeyError, TypeError):
    print('')
except Exception as e:
    print('', file=sys.stderr)
" 2>/dev/null
}

load_and_validate_json() {
    local file="$1"

    # File exists?
    if [ ! -f "$file" ]; then
        print_error "JSON file not found: $file"
        echo ""
        echo "Please provide a valid configuration file."
        echo "See configs/examples/ for templates."
        exit 1
    fi

    # Valid JSON syntax?
    if ! python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
        print_error "Invalid JSON syntax in: $file"
        echo ""
        echo "Common issues: missing commas, trailing commas, unescaped quotes."
        echo "Validate at: https://jsonlint.com"
        exit 1
    fi

    # Required fields
    local company_name
    company_name=$(json_get "$file" "company.name")
    if [ -z "$company_name" ]; then
        print_error "Missing required field: company.name"
        echo ""
        echo 'Add to your JSON: "company": { "name": "CompanyName" }'
        exit 1
    fi

    local primary_req
    primary_req=$(json_get "$file" "job_requirements.primary")
    if [ -z "$primary_req" ]; then
        print_error "Missing required field: job_requirements.primary"
        echo ""
        echo 'Add: "job_requirements": { "primary": "key requirement" }'
        exit 1
    fi

    local projects_mode
    projects_mode=$(json_get "$file" "projects.mode")
    if [ -z "$projects_mode" ]; then
        print_error "Missing required field: projects.mode"
        echo ""
        echo 'Add: "projects": { "mode": "auto" }'
        exit 1
    fi

    # Validate mode enum
    if [[ "$projects_mode" != "auto" && "$projects_mode" != "manual" && "$projects_mode" != "hybrid" ]]; then
        print_error "Invalid projects.mode: '$projects_mode'"
        echo ""
        echo "Valid values: auto | manual | hybrid"
        exit 1
    fi

    print_success "Configuration validated: $file"
}

# =============================================================================
# Project Selection
# =============================================================================

is_valid_project_id() {
    local id="$1"
    for valid in "${VALID_PROJECT_IDS[@]}"; do
        [ "$id" = "$valid" ] && return 0
    done
    return 1
}

array_contains() {
    local needle="$1"; shift
    for item in "$@"; do
        [ "$item" = "$needle" ] && return 0
    done
    return 1
}

get_project_field() {
    local project_id="$1"
    local field="$2"
    python3 -c "
import json
with open('${PROJECT_DB}') as f:
    db = json.load(f)
for p in db['projects']:
    if p['id'] == '$project_id':
        parts = '$field'.split('.')
        val = p
        for part in parts:
            val = val[part]
        print(val)
        break
" 2>/dev/null
}

# Returns projects sorted by relevance (highest first) for the given role
get_sorted_projects_for_role() {
    local role="$1"
    python3 -c "
import json
with open('${PROJECT_DB}') as f:
    db = json.load(f)
projects = sorted(db['projects'], key=lambda p: p['relevance'].get('$role', 0), reverse=True)
for p in projects:
    print(p['id'])
"
}

select_projects() {
    local mode
    mode=$(json_get "$JSON_CONFIG" "projects.mode")

    # Build remove list from JSON + CLI
    local json_remove=()
    while IFS= read -r pid; do
        [ -n "$pid" ] && json_remove+=("$pid")
    done < <(python3 -c "
import json
with open('$JSON_CONFIG') as f:
    d = json.load(f)
for p in d.get('projects', {}).get('remove', []):
    print(p)
" 2>/dev/null)

    local all_remove=("${json_remove[@]}" "${REMOVE_PROJECTS[@]}")

    # Validate CLI add/remove project IDs
    for pid in "${ADD_PROJECTS[@]}" "${REMOVE_PROJECTS[@]}"; do
        if ! is_valid_project_id "$pid"; then
            print_error "Invalid project ID: '$pid'"
            echo ""
            echo "Valid IDs: ntru | aes | pixel-lab | thesis | educational-tools"
            exit 1
        fi
    done

    SELECTED_PROJECTS=()

    # Step 1: Default project (ntru) — always first unless removed
    if ! array_contains "ntru" "${all_remove[@]}"; then
        SELECTED_PROJECTS+=("ntru")
    fi

    # Step 2: Auto/hybrid — fill up to 3 from sorted relevance list
    if [[ "$mode" == "auto" || "$mode" == "hybrid" ]]; then
        while IFS= read -r pid; do
            [ ${#SELECTED_PROJECTS[@]} -ge 3 ] && break
            if ! array_contains "$pid" "${SELECTED_PROJECTS[@]}" && \
               ! array_contains "$pid" "${all_remove[@]}"; then
                SELECTED_PROJECTS+=("$pid")
            fi
        done < <(get_sorted_projects_for_role "$ROLE")
    fi

    # Step 3: Manual additions from JSON
    if [[ "$mode" == "manual" || "$mode" == "hybrid" ]]; then
        while IFS= read -r pid; do
            [ -n "$pid" ] || continue
            if ! array_contains "$pid" "${SELECTED_PROJECTS[@]}"; then
                if [ ${#SELECTED_PROJECTS[@]} -ge 3 ]; then
                    print_warning "Project limit (3) reached; skipping '$pid' from JSON add list."
                else
                    SELECTED_PROJECTS+=("$pid")
                fi
            fi
        done < <(python3 -c "
import json
with open('$JSON_CONFIG') as f:
    d = json.load(f)
for p in d.get('projects', {}).get('add', []):
    print(p)
" 2>/dev/null)
    fi

    # Step 4: CLI additions (highest priority)
    for pid in "${ADD_PROJECTS[@]}"; do
        if ! array_contains "$pid" "${SELECTED_PROJECTS[@]}"; then
            if [ ${#SELECTED_PROJECTS[@]} -ge 3 ]; then
                print_warning "Project limit (3) reached; skipping --add-project '$pid'."
            else
                SELECTED_PROJECTS+=("$pid")
            fi
        fi
    done

    # Step 5: Apply removals to final list
    local final=()
    for pid in "${SELECTED_PROJECTS[@]}"; do
        array_contains "$pid" "${all_remove[@]}" || final+=("$pid")
    done
    SELECTED_PROJECTS=("${final[@]}")

    # Validation
    if [ ${#SELECTED_PROJECTS[@]} -eq 0 ]; then
        print_error "No projects selected after applying filters."
        echo ""
        echo "  Default project (ntru) was removed with no replacements."
        echo "  Fix: remove the 'ntru' entry from your remove list, or add projects with --add-project."
        exit 1
    fi
}

# =============================================================================
# Output filename
# =============================================================================

build_output_filename() {
    local company
    company=$(json_get "$JSON_CONFIG" "company.name")
    # Slugify: lowercase, spaces→hyphens, strip non-alphanum/hyphen
    local slug
    slug=$(echo "$company" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | cut -c1-30)
    echo "cover-letter-${slug}-${ROLE}.pdf"
}

# =============================================================================
# LaTeX Generation
# =============================================================================

escape_latex() {
    # Escape special LaTeX characters in a string
    echo "$1" | sed \
        -e 's/\\/\\textbackslash{}/g' \
        -e 's/&/\\&/g' \
        -e 's/%/\\%/g' \
        -e 's/\$/\\$/g' \
        -e 's/#/\\#/g' \
        -e 's/_/\\_/g' \
        -e 's/{/\\{/g' \
        -e 's/}/\\}/g' \
        -e 's/\^/\\textasciicircum{}/g' \
        -e 's/~/\\textasciitilde{}/g'
}

generate_temp_latex() {
    # Write the Python generator script to a temp file (avoids heredoc escaping issues),
    # then execute it with role/config data passed as env vars.
    local py_script
    py_script=$(mktemp /tmp/cl_gen_XXXXXX.py)

    cat > "$py_script" << 'PYEOF'
import json, sys, os

ROLE       = os.environ["CL_ROLE"]
ROLE_FLAG  = os.environ["CL_ROLE_FLAG"]
TEMPLATE   = os.environ["CL_TEMPLATE"]
PROJECT_DB = os.environ["CL_PROJECT_DB"]
CONFIG     = os.environ["CL_CONFIG"]
SELECTED   = [p for p in os.environ["CL_SELECTED"].split() if p]

def esc(s):
    if not s:
        return ""
    for old, new in [
        ("\\", "\\textbackslash{}"),
        ("&",  "\\&"),
        ("%",  "\\%"),
        ("$",  "\\$"),
        ("#",  "\\#"),
        ("_",  "\\_"),
        ("{",  "\\{"),
        ("}",  "\\}"),
        ("^",  "\\textasciicircum{}"),
        ("~",  "\\textasciitilde{}"),
    ]:
        s = s.replace(old, new)
    return s

cfg = json.load(open(CONFIG))
db  = json.load(open(PROJECT_DB))

company      = esc(cfg["company"].get("name") or "")
position     = esc(cfg["company"].get("position") or "")
focus_area   = esc(cfg["company"].get("focus_area") or "")
primary      = esc(cfg["job_requirements"].get("primary") or "")
secondary    = esc(cfg["job_requirements"].get("secondary") or "")
tertiary     = esc(cfg["job_requirements"].get("tertiary") or "")
cust         = cfg.get("customization") or {}
opening_hook = esc(cust.get("opening_hook") or "")
closing_note = esc(cust.get("closing_note") or "")

def nc(name, val):
    return rf"\newcommand{{\{name}}}{{{val}}}"

lines = [
    "% --- Auto-generated flags and macros (do not edit) ---",
    r"\newif\ifcryptoengineer",
    r"\newif\ifsecurityengineer",
    r"\newif\ifsoftwareengineer",
    r"\newif\ifappliedcrypto",
    r"\newif\ifgeneralapplication",
    r"\cryptoengineerfalse",
    r"\securityengineerfalse",
    r"\softwareengineerfalse",
    r"\appliedcryptofalse",
    r"\generalapplicationfalse",
    "\\" + ROLE_FLAG,
    r"\newif\ifprojectone",
    r"\newif\ifprojecttwo",
    r"\newif\ifprojectthree",
    r"\projectonefalse",
    r"\projecttwofalse",
    r"\projectthreefalse",
]

for i, pid in enumerate(SELECTED):
    lines.append(rf"\project{'one two three'.split()[i]}true")

lines += [
    nc("CompanyName",  company),
    nc("PositionTitle", position),
    nc("FocusArea",    focus_area),
    nc("PrimaryReq",   primary),
    nc("SecondaryReq", secondary),
    nc("TertiaryReq",  tertiary),
    nc("OpeningHook",  opening_hook),
    nc("ClosingNote",  closing_note),
]

caps = ["One", "Two", "Three"]
for i, pid in enumerate(SELECTED):
    proj  = next(p for p in db["projects"] if p["id"] == pid)
    pname = esc(proj["name"])
    purl  = proj["url"]
    pdesc = esc(proj["descriptions"].get(ROLE, proj["descriptions"].get("general", "")))
    sn = caps[i]
    lines += [
        nc(f"ProjectName{sn}", pname),
        nc(f"ProjectURL{sn}",  purl),
        nc(f"ProjectDesc{sn}", pdesc),
    ]

for i in range(len(SELECTED), 3):
    sn = caps[i]
    lines += [nc(f"ProjectName{sn}", ""), nc(f"ProjectURL{sn}", ""), nc(f"ProjectDesc{sn}", "")]

lines.append("% --- End auto-generated ---")

with open(TEMPLATE) as f:
    content = f.read()

marker = "% GENERATED_FLAGS_AND_MACROS_HERE"
if marker not in content:
    print(f"ERROR: marker '{marker}' not found in template", file=sys.stderr)
    sys.exit(1)

content = content.replace(marker, "\n".join(lines), 1)

with open("temp_cover_letter.tex", "w") as f:
    f.write(content)

print("OK")
PYEOF

    # Pass bash variables safely as env vars
    local selected_str
    selected_str="${SELECTED_PROJECTS[*]}"

    CL_ROLE="$ROLE" \
    CL_ROLE_FLAG="$ROLE_FLAG" \
    CL_TEMPLATE="$TEMPLATE" \
    CL_PROJECT_DB="$PROJECT_DB" \
    CL_CONFIG="$JSON_CONFIG" \
    CL_SELECTED="$selected_str" \
    python3 "$py_script"
    local exit_code=$?

    rm -f "$py_script"
    return $exit_code
}



# =============================================================================
# Preview
# =============================================================================

show_preview() {
    local output_file
    output_file=$(build_output_filename)

    local company position primary
    company=$(json_get "$JSON_CONFIG" "company.name")
    position=$(json_get "$JSON_CONFIG" "company.position")
    primary=$(json_get "$JSON_CONFIG" "job_requirements.primary")

    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "${BOLD}  PREVIEW MODE${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BOLD}Role:${NC}             ${ROLE_NAME}"
    echo -e "${BOLD}Company:${NC}          ${company}"
    [ -n "$position" ] && echo -e "${BOLD}Position:${NC}         ${position}"
    echo -e "${BOLD}Primary Req:${NC}      ${primary}"
    echo ""
    echo -e "${BOLD}Selected Projects:${NC}"
    local i=1
    for pid in "${SELECTED_PROJECTS[@]}"; do
        local pname
        pname=$(get_project_field "$pid" "name")
        echo -e "  ${i}. ${pid} — ${pname}"
        i=$((i + 1))
    done
    echo ""
    echo -e "${BOLD}Expected Output:${NC}  ${output_file}"
    echo ""
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo ""
}

# =============================================================================
# Cleanup
# =============================================================================

clean_auxiliary_files() {
    print_info "Cleaning auxiliary files..."
    rm -f *.aux *.log *.out temp_cover_letter.tex 2>/dev/null
    print_success "Cleanup complete."
}

# =============================================================================
# Help
# =============================================================================

show_help() {
    print_header
    echo -e "${BOLD}USAGE:${NC}"
    echo -e "  ./compile-cover-letter.sh <role> --json <config.json> [options]"
    echo ""
    echo -e "${BOLD}ROLES (choose exactly one):${NC}"
    echo -e "  ${CYAN}--crypto${NC}              Cryptography Engineer"
    echo -e "  ${CYAN}--security${NC}            Security Engineer (Cryptography Focus)"
    echo -e "  ${CYAN}--software${NC}            Software Engineer (Security Focus)"
    echo -e "  ${CYAN}--applied${NC}             Applied Cryptographer (research focus)"
    echo -e "  ${CYAN}--general${NC}             General / open application"
    echo ""
    echo -e "${BOLD}REQUIRED:${NC}"
    echo -e "  ${CYAN}--json <path>${NC}         Path to JSON configuration file"
    echo ""
    echo -e "${BOLD}PROJECT OVERRIDES:${NC}"
    echo -e "  ${CYAN}--add-project <id>${NC}    Add a project (repeatable)"
    echo -e "  ${CYAN}--remove-project <id>${NC} Remove a project (repeatable)"
    echo -e "  Valid IDs: ntru | aes | pixel-lab | thesis | educational-tools"
    echo ""
    echo -e "${BOLD}OPTIONS:${NC}"
    echo -e "  ${CYAN}--preview${NC}             Show configuration without compiling"
    echo -e "  ${CYAN}--clean${NC}               Remove auxiliary LaTeX files"
    echo -e "  ${CYAN}--help${NC}                Show this message"
    echo ""
    echo -e "${BOLD}EXAMPLES:${NC}"
    echo -e "  ${GREEN}# Security engineer, auto project selection${NC}"
    echo -e "  ./compile-cover-letter.sh --security --json configs/stripe.json"
    echo ""
    echo -e "  ${GREEN}# Applied cryptographer, preview first${NC}"
    echo -e "  ./compile-cover-letter.sh --applied --json configs/lab.json --preview"
    echo ""
    echo -e "  ${GREEN}# Software engineer, add pixel-lab, drop thesis${NC}"
    echo -e "  ./compile-cover-letter.sh --software --json configs/startup.json \\"
    echo -e "      --add-project pixel-lab --remove-project thesis"
    echo ""
    echo -e "  ${GREEN}# General application${NC}"
    echo -e "  ./compile-cover-letter.sh --general --json configs/janestreet.json"
    echo ""
    echo -e "${BOLD}OUTPUT:${NC}  cover-letter-<company>-<role>.pdf"
    echo ""
}

# =============================================================================
# Argument Parsing
# =============================================================================

if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

while [ $# -gt 0 ]; do
    case "$1" in
        --crypto)
            [ -n "$ROLE" ] && { print_error "Multiple roles specified."; exit 1; }
            ROLE="crypto"; ROLE_FLAG="cryptoengineertrue"; ROLE_NAME="Cryptography Engineer" ;;
        --security)
            [ -n "$ROLE" ] && { print_error "Multiple roles specified."; exit 1; }
            ROLE="security"; ROLE_FLAG="securityengineertrue"; ROLE_NAME="Security Engineer (Cryptography Focus)" ;;
        --software)
            [ -n "$ROLE" ] && { print_error "Multiple roles specified."; exit 1; }
            ROLE="software"; ROLE_FLAG="softwareengineertrue"; ROLE_NAME="Software Engineer (Security Focus)" ;;
        --applied)
            [ -n "$ROLE" ] && { print_error "Multiple roles specified."; exit 1; }
            ROLE="applied"; ROLE_FLAG="appliedcryptotrue"; ROLE_NAME="Applied Cryptographer" ;;
        --general)
            [ -n "$ROLE" ] && { print_error "Multiple roles specified."; exit 1; }
            ROLE="general"; ROLE_FLAG="generalapplicationtrue"; ROLE_NAME="General Application" ;;
        --json)
            shift
            [ -z "$1" ] && { print_error "--json requires a file path."; exit 1; }
            JSON_CONFIG="$1" ;;
        --add-project)
            shift
            [ -z "$1" ] && { print_error "--add-project requires a project ID."; exit 1; }
            ADD_PROJECTS+=("$1") ;;
        --remove-project)
            shift
            [ -z "$1" ] && { print_error "--remove-project requires a project ID."; exit 1; }
            REMOVE_PROJECTS+=("$1") ;;
        --preview)
            PREVIEW_MODE=true ;;
        --clean)
            CLEAN_ONLY=true ;;
        --help)
            show_help; exit 0 ;;
        *)
            print_error "Unknown option: $1"
            echo "Run './compile-cover-letter.sh --help' for usage."
            exit 1 ;;
    esac
    shift
done

# =============================================================================
# Main Execution
# =============================================================================

print_header

if [ "$CLEAN_ONLY" = true ]; then
    clean_auxiliary_files
    exit 0
fi

validate_role
validate_json_arg
check_dependencies
load_and_validate_json "$JSON_CONFIG"
select_projects

if [ "$PREVIEW_MODE" = true ]; then
    show_preview
    echo -ne "${BOLD}Proceed with compilation?${NC} (y/n): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_info "Compilation cancelled."
        exit 0
    fi
    echo ""
fi

OUTPUT_FILE=$(build_output_filename)

print_info "Compiling: ${BOLD}${ROLE_NAME}${NC} → ${OUTPUT_FILE}"
echo ""

generate_temp_latex "${OUTPUT_FILE%.pdf}"

if pdflatex -interaction=nonstopmode -jobname="${OUTPUT_FILE%.pdf}" temp_cover_letter.tex > /dev/null 2>&1; then
    print_success "Compilation successful!"
    echo ""
    print_success "Output: ${BOLD}${OUTPUT_FILE}${NC}"
    clean_auxiliary_files
    echo ""
    print_info "Done."
else
    print_error "Compilation failed!"
    echo ""
    print_warning "Check log: ${OUTPUT_FILE%.pdf}.log"
    rm -f temp_cover_letter.tex
    exit 1
fi

rm -f temp_cover_letter.tex
exit 0
