#!/bin/bash

# =============================================================================
# Resume Compiler v2.0
# =============================================================================
# Compiles LaTeX resume with role-specific customization
# Supports 4 role variants with optional sections
# =============================================================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# =============================================================================
# Configuration Variables
# =============================================================================
ROLE=""
ROLE_FLAG=""
ROLE_NAME=""
OUTPUT_SUFFIX=""

INCLUDE_THESIS=false
INCLUDE_SOFT_SKILLS=false
INCLUDE_EDU_TOOLS=true  # Default ON
INCLUDE_CONFERENCES=false  # Default OFF (more research-oriented)
INCLUDE_PIXEL_LAB=""  # Role-based default (set after role selection)

PREVIEW_MODE=false
CLEAN_ONLY=false

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  Resume Compiler v2.0${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

show_help() {
    print_header
    echo -e "${BOLD}USAGE:${NC}"
    echo -e "  ./compile-resume.sh <role> [options]"
    echo ""
    echo -e "${BOLD}ROLES (choose exactly one):${NC}"
    echo -e "  ${CYAN}--crypto${NC}              Cryptography Engineer (most specialized)"
    echo -e "  ${CYAN}--security${NC}            Security Engineer (Cryptography Focus)"
    echo -e "  ${CYAN}--software${NC}            Software Engineer (Security Focus)"
    echo -e "  ${CYAN}--applied${NC}             Applied Cryptographer (research focus)"
    echo ""
    echo -e "${BOLD}OPTIONS:${NC}"
    echo -e "  ${CYAN}--thesis${NC}              Include thesis project section"
    echo -e "  ${CYAN}--soft-skills${NC}         Include professional/soft skills section"
    echo -e "  ${CYAN}--conferences${NC}         Include conference presentations section"
    echo -e "  ${CYAN}--pixel-lab${NC}           Include Pixel Lab project (default: auto per role)"
    echo -e "  ${CYAN}--no-edu-tools${NC}        Exclude educational tools section (included by default)"
    echo -e "  ${CYAN}--preview${NC}             Show configuration without compiling"
    echo -e "  ${CYAN}--clean${NC}               Clean auxiliary files and exit"
    echo -e "  ${CYAN}--help${NC}                Show this help message"
    echo ""
    echo -e "${BOLD}EXAMPLES:${NC}"
    echo -e "  ${GREEN}# Cryptography Engineer with thesis${NC}"
    echo -e "  ./compile-resume.sh --crypto --thesis"
    echo ""
    echo -e "  ${GREEN}# Software Engineer with Python project (auto-included)${NC}"
    echo -e "  ./compile-resume.sh --software"
    echo ""
    echo -e "  ${GREEN}# Security Engineer, preview before compile${NC}"
    echo -e "  ./compile-resume.sh --security --preview"
    echo ""
    echo -e "  ${GREEN}# Applied Cryptographer with all research sections${NC}"
    echo -e "  ./compile-resume.sh --applied --thesis --conferences"
    echo ""
    echo -e "${BOLD}OUTPUT FILES:${NC}"
    echo -e "  resume-cryptography-engineer.pdf"
    echo -e "  resume-security-engineer.pdf"
    echo -e "  resume-software-engineer.pdf"
    echo -e "  resume-applied-cryptographer.pdf"
    echo ""
    echo -e "  (suffixes added for --thesis, --soft-skills, --conferences)"
    echo ""
}

clean_auxiliary_files() {
    print_info "Cleaning auxiliary files..."
    rm -f *.aux *.log *.out temp_resume.tex 2>/dev/null
    print_success "Cleanup complete"
}

validate_role() {
    if [ -z "$ROLE" ]; then
        print_error "No role specified"
        echo ""
        echo "Please specify exactly one role:"
        echo "  --crypto, --security, --software, or --applied"
        echo ""
        echo "Run './compile-resume.sh --help' for usage information"
        exit 1
    fi
}

build_output_filename() {
    local filename="resume-${OUTPUT_SUFFIX}"

    # Add suffixes for optional sections
    if [ "$INCLUDE_THESIS" = true ]; then
        filename="${filename}-thesis"
    fi

    if [ "$INCLUDE_SOFT_SKILLS" = true ]; then
        filename="${filename}-soft"
    fi

    if [ "$INCLUDE_CONFERENCES" = true ]; then
        filename="${filename}-conf"
    fi

    if [ "$INCLUDE_PIXEL_LAB" = true ]; then
        filename="${filename}-pxl"
    fi

    echo "${filename}.pdf"
}

show_preview() {
    local output_file=$(build_output_filename)

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  PREVIEW MODE${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BOLD}Role:${NC}             ${ROLE_NAME}"
    echo -e "${BOLD}Role Flag:${NC}        ${ROLE_FLAG}"
    echo ""
    echo -e "${BOLD}Optional Sections:${NC}"

    if [ "$INCLUDE_THESIS" = true ]; then
        echo -e "  Thesis:         ${GREEN}✓ INCLUDED${NC}"
    else
        echo -e "  Thesis:         ${YELLOW}✗ EXCLUDED${NC}"
    fi

    if [ "$INCLUDE_SOFT_SKILLS" = true ]; then
        echo -e "  Soft Skills:    ${GREEN}✓ INCLUDED${NC}"
    else
        echo -e "  Soft Skills:    ${YELLOW}✗ EXCLUDED${NC}"
    fi

    if [ "$INCLUDE_CONFERENCES" = true ]; then
        echo -e "  Conferences:    ${GREEN}✓ INCLUDED${NC}"
    else
        echo -e "  Conferences:    ${YELLOW}✗ EXCLUDED${NC} (default)"
    fi

    if [ "$INCLUDE_PIXEL_LAB" = true ]; then
        echo -e "  Pixel Lab:      ${GREEN}✓ INCLUDED${NC}"
    else
        echo -e "  Pixel Lab:      ${YELLOW}✗ EXCLUDED${NC}"
    fi

    if [ "$INCLUDE_EDU_TOOLS" = true ]; then
        echo -e "  Edu Tools:      ${GREEN}✓ INCLUDED${NC} (default)"
    else
        echo -e "  Edu Tools:      ${YELLOW}✗ EXCLUDED${NC}"
    fi

    echo ""
    echo -e "${BOLD}Expected Output:${NC}  ${output_file}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# =============================================================================
# Argument Parsing
# =============================================================================

if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --crypto)
            if [ -n "$ROLE" ]; then
                print_error "Multiple roles specified. Choose only one role."
                exit 1
            fi
            ROLE="crypto"
            ROLE_FLAG="cryptoengineertrue"
            ROLE_NAME="Cryptography Engineer"
            OUTPUT_SUFFIX="cryptography-engineer"
            ;;
        --security)
            if [ -n "$ROLE" ]; then
                print_error "Multiple roles specified. Choose only one role."
                exit 1
            fi
            ROLE="security"
            ROLE_FLAG="securityengineertrue"
            ROLE_NAME="Security Engineer (Cryptography Focus)"
            OUTPUT_SUFFIX="security-engineer"
            ;;
        --software)
            if [ -n "$ROLE" ]; then
                print_error "Multiple roles specified. Choose only one role."
                exit 1
            fi
            ROLE="software"
            ROLE_FLAG="softwareengineertrue"
            ROLE_NAME="Software Engineer (Security Focus)"
            OUTPUT_SUFFIX="software-engineer"
            ;;
        --applied)
            if [ -n "$ROLE" ]; then
                print_error "Multiple roles specified. Choose only one role."
                exit 1
            fi
            ROLE="applied"
            ROLE_FLAG="appliedcryptotrue"
            ROLE_NAME="Applied Cryptographer"
            OUTPUT_SUFFIX="applied-cryptographer"
            ;;
        --thesis)
            INCLUDE_THESIS=true
            ;;
        --soft-skills)
            INCLUDE_SOFT_SKILLS=true
            ;;
        --conferences)
            INCLUDE_CONFERENCES=true
            ;;
        --pixel-lab)
            INCLUDE_PIXEL_LAB="true"  # Explicit override
            ;;
        --no-edu-tools)
            INCLUDE_EDU_TOOLS=false
            ;;
        --preview)
            PREVIEW_MODE=true
            ;;
        --clean)
            CLEAN_ONLY=true
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo ""
            echo "Run './compile-resume.sh --help' for usage information"
            exit 1
            ;;
    esac
    shift
done

# =============================================================================
# Main Execution
# =============================================================================

print_header

# Handle clean-only mode
if [ "$CLEAN_ONLY" = true ]; then
    clean_auxiliary_files
    exit 0
fi

# Validate role selection
validate_role

# Set role-based defaults for Pixel Lab (if not explicitly set by user)
if [ -z "$INCLUDE_PIXEL_LAB" ]; then
    case "$ROLE" in
        crypto|applied)
            INCLUDE_PIXEL_LAB=false  # Prioritize C/C++ crypto projects
            ;;
        security|software)
            INCLUDE_PIXEL_LAB=true   # Show Python skills
            ;;
    esac
fi

# Show preview if requested
if [ "$PREVIEW_MODE" = true ]; then
    show_preview

    # Ask for confirmation
    echo -ne "${BOLD}Proceed with compilation?${NC} (y/n): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_info "Compilation cancelled"
        exit 0
    fi
    echo ""
fi

# Build output filename
OUTPUT_FILE=$(build_output_filename)

# Display compilation info
print_info "Compiling: ${BOLD}${ROLE_NAME}${NC}"
if [ "$INCLUDE_THESIS" = true ] || [ "$INCLUDE_SOFT_SKILLS" = true ] || [ "$INCLUDE_CONFERENCES" = true ] || [ "$INCLUDE_PIXEL_LAB" = true ]; then
    echo -ne "  Optional sections: "
    [ "$INCLUDE_THESIS" = true ] && echo -n "thesis "
    [ "$INCLUDE_SOFT_SKILLS" = true ] && echo -n "soft-skills "
    [ "$INCLUDE_CONFERENCES" = true ] && echo -n "conferences "
    [ "$INCLUDE_PIXEL_LAB" = true ] && echo -n "pixel-lab "
    echo ""
fi

# =============================================================================
# Create temporary LaTeX file with flags
# =============================================================================

cat > temp_resume.tex << 'PREAMBLE_END'
% Auto-generated preamble - DO NOT EDIT MANUALLY
\newif\ifcryptoengineer
\newif\ifsecurityengineer
\newif\ifsoftwareengineer
\newif\ifappliedcrypto
\newif\ifincludethesis
\newif\ifincludesoftskills
\newif\ifincludeedutools
\newif\ifincludeconferences
\newif\ifincludepixellab

% Set role flags (only one should be true)
\cryptoengineerfalse
\securityengineerfalse
\softwareengineerfalse
\appliedcryptofalse

PREAMBLE_END

# Add the selected role flag
echo "\\${ROLE_FLAG}" >> temp_resume.tex

# Add optional section flags
if [ "$INCLUDE_THESIS" = true ]; then
    echo "\\includethesistrue" >> temp_resume.tex
else
    echo "\\includethesisfalse" >> temp_resume.tex
fi

if [ "$INCLUDE_SOFT_SKILLS" = true ]; then
    echo "\\includesoftskillstrue" >> temp_resume.tex
else
    echo "\\includesoftskillsfalse" >> temp_resume.tex
fi

if [ "$INCLUDE_EDU_TOOLS" = true ]; then
    echo "\\includeedutoolstrue" >> temp_resume.tex
else
    echo "\\includeedutoolsfalse" >> temp_resume.tex
fi

if [ "$INCLUDE_CONFERENCES" = true ]; then
    echo "\\includeconferencestrue" >> temp_resume.tex
else
    echo "\\includeconferencesfalse" >> temp_resume.tex
fi

if [ "$INCLUDE_PIXEL_LAB" = true ]; then
    echo "\\includepixellabtrue" >> temp_resume.tex
else
    echo "\\includepixellabfalse" >> temp_resume.tex
fi

# Append the main resume content
cat resume.tex >> temp_resume.tex

# =============================================================================
# Compile with pdflatex
# =============================================================================

print_info "Running pdflatex..."
echo ""

# Run pdflatex (suppress most output, show only errors)
if pdflatex -interaction=nonstopmode -jobname="${OUTPUT_FILE%.pdf}" temp_resume.tex > /dev/null 2>&1; then
    print_success "Compilation successful!"
    echo ""
    print_success "Output file: ${BOLD}${OUTPUT_FILE}${NC}"

    # Clean up auxiliary files
    clean_auxiliary_files

    echo ""
    print_info "Done! Your resume is ready."
else
    print_error "Compilation failed!"
    echo ""
    print_warning "Check the log file for details:"
    echo "  ${OUTPUT_FILE%.pdf}.log"
    echo ""

    # Don't clean files on error so user can debug
    rm -f temp_resume.tex
    exit 1
fi

# Remove temporary file
rm -f temp_resume.tex

exit 0
