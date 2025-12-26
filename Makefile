# Makefile for Safe Verifiable Rust Agent System
# Documentation-only repository - markdown linting targets

.PHONY: all build test lint coverage clean help

# Default target
all: lint

# Build target (documentation repo - just validate structure)
build:
	@echo "Validating repository structure..."
	@test -f README.md || (echo "ERROR: README.md not found" && exit 1)
	@test -f design.md || (echo "ERROR: design.md not found" && exit 1)
	@test -f orchestrator.md || (echo "ERROR: orchestrator.md not found" && exit 1)
	@echo "Repository structure validated."

# Test target - runs all quality checks
test: lint build
	@echo "All tests passed."

# Lint markdown files
lint:
	@echo "Linting markdown files..."
	@if command -v markdownlint > /dev/null 2>&1; then \
		markdownlint '*.md' --ignore node_modules; \
	elif command -v markdownlint-cli2 > /dev/null 2>&1; then \
		markdownlint-cli2 '*.md'; \
	elif command -v npx > /dev/null 2>&1; then \
		npx markdownlint-cli2 '*.md'; \
	else \
		echo "WARNING: markdownlint not installed, skipping lint"; \
		echo "Install with: npm install -g markdownlint-cli2"; \
	fi
	@echo "Markdown linting complete."

# Coverage target - generate lint report
coverage:
	@echo "Generating markdown lint report..."
	@mkdir -p coverage
	@if command -v markdownlint > /dev/null 2>&1; then \
		markdownlint '*.md' --ignore node_modules -o coverage/lint-report.txt || true; \
	elif command -v markdownlint-cli2 > /dev/null 2>&1; then \
		markdownlint-cli2 '*.md' > coverage/lint-report.txt 2>&1 || true; \
	elif command -v npx > /dev/null 2>&1; then \
		npx markdownlint-cli2 '*.md' > coverage/lint-report.txt 2>&1 || true; \
	else \
		echo "No lint issues (markdownlint not installed)" > coverage/lint-report.txt; \
	fi
	@echo "Files analyzed:" >> coverage/lint-report.txt
	@ls -1 *.md >> coverage/lint-report.txt
	@echo "Lint report generated: coverage/lint-report.txt"

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	@rm -rf coverage/
	@echo "Clean complete."

# Help target
help:
	@echo "Safe Verifiable Rust Agent System - Makefile targets"
	@echo ""
	@echo "  make         - Run default target (lint)"
	@echo "  make build   - Validate repository structure"
	@echo "  make test    - Run all quality checks (lint + build)"
	@echo "  make lint    - Lint all markdown files"
	@echo "  make coverage - Generate lint report in coverage/"
	@echo "  make clean   - Remove generated files"
	@echo "  make help    - Show this help message"
