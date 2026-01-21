#!/bin/bash

# Create temporary LaTeX files with the appropriate version set
if [ "$1" = "--security-engineer" ]; then
	echo "Compiling Security Engineer version..."
	# Create a temporary file with security version active
	cat > temp_resume.tex << 'EOF'
\newif\ifsecurityengineer
\newif\ifsoftwareengineer
\newif\ifincludethesis
\securityengineertrue
\softwareengineerfalse
EOF
	if [ "$2" = "--include-thesis" ]; then
		echo "Including thesis work..."
		echo "\includethesistrue" >> temp_resume.tex
	else
		echo "\includethesisfalse" >> temp_resume.tex
	fi
	cat resume.tex >> temp_resume.tex
	pdflatex -jobname="resume-security-engineer" temp_resume.tex
	rm -f temp_resume.tex temp_resume.aux temp_resume.log temp_resume.out
elif [ "$1" = "--software-engineer" ]; then
	echo "Compiling Software Engineer version..."
	cat > temp_resume.tex << 'EOF'
\newif\ifsecurityengineer
\newif\ifsoftwareengineer
\newif\ifincludethesis
\securityengineerfalse
\softwareengineertrue
EOF
	if [ "$2" = "--include-thesis" ]; then
		echo "Including thesis work..."
		echo "\includethesistrue" >> temp_resume.tex
	else
		echo "\includethesisfalse" >> temp_resume.tex
	fi
	cat resume.tex >> temp_resume.tex
	pdflatex -jobname="resume-software-engineer" temp_resume.tex
	rm -f temp_resume.tex temp_resume.aux temp_resume.log temp_resume.out
else
	echo "Usage: $0 [--security-engineer | --software-engineer] [options]"
	echo "Options:"
	echo "--include-thesis"
	echo ""
	echo "Examples:"
	echo "  $0 --security-engineer   # Creates resume-security-engineer.pdf"
	echo "  $0 --software-engineer   # Creates resume-software-engineer.pdf"
	echo "  $0 --security-engineer --include-thesis   # Creates resume-security-engineer.pdf with thesis included"
	exit 1
fi

# Clean up auxiliary files
rm -f *.aux *.log *.out
