#!/bin/bash

# Create temporary LaTeX files with the appropriate version set
if [ "$1" = "--security-engineer" ]; then
	echo "Compiling Security Engineer version..."
	# Create a temporary file with security version active
	cat > temp_resume.tex << 'EOF'
\newif\ifsecurityengineer
\newif\ifsoftwareengineer
\securityengineertrue
\softwareengineerfalse
EOF
	cat resume.tex >> temp_resume.tex
	pdflatex -jobname="resume-security-engineer" temp_resume.tex
	rm -f temp_resume.tex temp_resume.aux temp_resume.log temp_resume.out
elif [ "$1" = "--software-engineer" ]; then
	echo "Compiling Software Engineer version..."
	cat > temp_resume.tex << 'EOF'
\newif\ifsecurityengineer
\newif\ifsoftwareengineer
\securityengineerfalse
\softwareengineertrue
EOF
	cat resume.tex >> temp_resume.tex
	pdflatex -jobname="resume-software-engineer" temp_resume.tex
	rm -f temp_resume.tex temp_resume.aux temp_resume.log temp_resume.out
else
	echo "Usage: $0 [--security-engineer | --software-engineer]"
	echo ""
	echo "Examples:"
	echo "  $0 --security-engineer   # Creates resume-security-engineer.pdf"
	echo "  $0 --software-engineer   # Creates resume-software-engineer.pdf"
	exit 1
fi

# Clean up auxiliary files
rm -f *.aux *.log *.out
