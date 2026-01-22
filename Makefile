#
#  atrforge - Atari ATR disk image toolkit
#  Copyright (C) 2016 Daniel Serpell
#  Copyright (C) 2026 Rick Collette & AtariFoundry.com
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License along
#  with this program.  If not, see <http://www.gnu.org/licenses/>
#

# ============================================================================
# Configuration Variables
# ============================================================================

# Project identification
PROJECT_NAME = atrforge
PROJECT_DESCRIPTION = "Atari ATR disk image toolkit"

# Directories
SRC_DIR = src
BUILD_DIR = obj
PROG_DIR = bin
RELEASE_DIR = release
CHANGELOG_PATH = CHANGELOG.md

# Compiler configuration
CC ?= gcc
INCLUDE_DIRS ?=
CFLAGS ?= $(INCLUDE_DIRS) -O2 -Wall
LDFLAGS ?=
LDLIBS ?=

# Programs to build
PROGS = \
 atrforge\
 lsatr\
 convertatr\
 atrcp

# Source files for each program
SOURCES_atrforge = \
 atr.c\
 convert.c\
 crc32.c\
 compat.c\
 darray.c\
 flist.c\
 mkatr.c\
 modatr.c\
 msg.c\
 spartafs.c

SOURCES_lsatr = \
 atr.c\
 compat.c\
 crc32.c\
 lsatr.c\
 lssfs.c\
 lsdos.c\
 lsextra.c\
 lshowfen.c\
 msg.c

SOURCES_convertatr = \
 atr.c\
 convert.c\
 convertatr.c\
 convertatr_main.c\
 crc32.c\
 darray.c\
 flist.c\
 msg.c\
 spartafs.c

SOURCES_atrcp = \
 atr.c\
 compat.c\
 convert.c\
 crc32.c\
 darray.c\
 flist.c\
 lssfs.c\
 msg.c\
 spartafs.c\
 atrcp.c

# Version handling
VERSION_FILE = VERSION
VERSION = $(shell cat $(VERSION_FILE) 2>/dev/null || echo "1.0.0")
VERSION_STAMP = $(BUILD_DIR)/.version-incremented

# Docker image for macOS builds (optional)
# Use existing Docker image if available
DOCKER_IMAGE ?= ghcr.io/shepherdjerred/macos-cross-compiler:latest

# Test target (optional - customize or leave empty)
TEST_TARGET ?=

# Determine executable extension based on compiler
TARGET_EXT := $(if $(findstring mingw,$(CC)),.exe,)

# Build directories
BDIR = $(BUILD_DIR)
ODIR = $(BDIR)

# Generate version.h from VERSION file
src/version.h: $(VERSION_FILE) | $(VERSION_STAMP)
	@echo "#pragma once" > $@
	@echo "const char *prog_version = \"$(shell cat $(VERSION_FILE))\";" >> $@

$(VERSION_STAMP): $(VERSION_FILE) | $(BUILD_DIR)
	@if [ -f $(VERSION_FILE) ]; then \
		SKIP_TARGETS="help clean distclean"; \
		SKIP=0; \
		for target in $$SKIP_TARGETS; do \
			if echo "$(MAKECMDGOALS)" | grep -q "$$target"; then \
				SKIP=1; \
				break; \
			fi; \
		done; \
		if [ $$SKIP -eq 0 ]; then \
			if [ -z "$(SKIP_VERSION_INCREMENT)" ] && [ ! -f $(VERSION_STAMP) ]; then \
				awk -F'.' 'BEGIN{OFS="."} NF==3 {$$3=$$3+1; print $$1"."$$2"."$$3; next} {print}' $(VERSION_FILE) > $(VERSION_FILE).tmp && \
				mv -f $(VERSION_FILE).tmp $(VERSION_FILE) && \
				echo "Version incremented"; \
			fi; \
		fi; \
	fi
	@touch $@

# Default rule
.DEFAULT_GOAL := all
all: src/version.h $(PROGS:%=$(PROG_DIR)/%$(TARGET_EXT))

.PHONY: all clean distclean help test release release-docker release-linux-amd64 release-linux-arm64 release-windows-x86_64 release-macos-x86_64 release-macos-arm64 release-macos github-release github-release-build fix

help:
	@echo "$(PROJECT_NAME) - $(PROJECT_DESCRIPTION)"
	@echo ""
	@echo "Available targets:"
	@echo "  all                  - Build all programs: $(PROGS) (default)"
	@echo "  clean                - Remove all build artifacts"
	@echo "  distclean            - Remove all build artifacts and binaries"
	@if [ -n "$(TEST_TARGET)" ]; then \
		echo "  test                 - Run test programs"; \
	fi
	@echo "  release              - Build release binaries for all platforms"
	@echo "  release-docker       - Build releases using Docker (alternative)"
	@echo "  release-linux-amd64  - Build Linux amd64 binaries"
	@echo "  release-linux-arm64  - Build Linux arm64 binaries"
	@echo "  release-windows-x86_64 - Build Windows x86_64 binaries"
	@echo "  release-macos        - Build macOS binaries (Intel + Apple Silicon) using Docker"
	@echo "  release-macos-x86_64 - Build macOS Intel binary using Docker"
	@echo "  release-macos-arm64  - Build macOS Apple Silicon binary using Docker"
	@echo "  github-release       - Build and create GitHub release (requires gh CLI)"
	@echo "  fix                  - Fix common Git issues (tag conflicts, etc.)"
	@echo "  help                 - Show this help message"
	@echo ""
	@echo "Build output: $(PROG_DIR)/"
	@echo "Object files: $(BUILD_DIR)/"
	@echo "Release output: $(RELEASE_DIR)/"

ifneq ($(TEST_TARGET),)
test: $(PROGS:%=$(PROG_DIR)/%)
	@echo "Running $(PROJECT_NAME) tests..."
	@$(TEST_TARGET)
else
test:
	@echo "No test target configured. Set TEST_TARGET variable to define tests."
endif

# Fix common Git issues (tag conflicts, etc.)
fix:
	@echo ""; \
	echo "=== Fixing Git Issues ==="; \
	echo ""; \
	if [ ! -d .git ]; then \
		echo "  ✗ Not a git repository"; \
		exit 1; \
	fi; \
	echo "Step 1: Checking for tag conflicts..."; \
	echo "  Fetching tags from remote (this may take a moment)..."; \
	FETCH_OUTPUT=$$(timeout 30 git fetch --tags origin 2>&1); \
	FETCH_CODE=$$?; \
	if [ $$FETCH_CODE -eq 124 ]; then \
		echo "  ⚠ Git fetch timed out after 30 seconds"; \
		echo "     This may indicate network issues or a large number of tags"; \
		echo "     Attempting to continue with existing tag information..."; \
		FETCH_OUTPUT=""; \
	elif [ $$FETCH_CODE -ne 0 ] && [ $$FETCH_CODE -ne 1 ]; then \
		echo "  ⚠ Git fetch failed (exit code: $$FETCH_CODE)"; \
		echo "     Continuing anyway..."; \
	fi; \
	if echo "$$FETCH_OUTPUT" | grep -qE '! \[rejected\]'; then \
		echo "  Found tag conflicts:"; \
		echo "$$FETCH_OUTPUT" | grep -E '! \[rejected\]' | sed 's/^/    /'; \
		echo ""; \
		echo "  Extracting conflicting tag names..."; \
		CONFLICTING_TAGS=$$(echo "$$FETCH_OUTPUT" | grep -E '! \[rejected\]' | sed -E 's/.*\[rejected\]\s+[^ ]+\s+->\s+([^ ]+).*/\1/' | sort -u); \
		CONFLICT_COUNT=0; \
		for tag in $$CONFLICTING_TAGS; do \
			if [ -n "$$tag" ] && git rev-parse "$$tag" >/dev/null 2>&1; then \
				TAG_COMMIT_LOCAL=$$(git rev-parse "$$tag" 2>/dev/null); \
				TAG_COMMIT_REMOTE=$$(git ls-remote --tags origin "refs/tags/$$tag" 2>/dev/null | cut -f1); \
				if [ -n "$$TAG_COMMIT_LOCAL" ] && [ -n "$$TAG_COMMIT_REMOTE" ] && [ "$$TAG_COMMIT_LOCAL" != "$$TAG_COMMIT_REMOTE" ]; then \
					echo "    Deleting local tag $$tag"; \
					echo "      Local:  $$(echo $$TAG_COMMIT_LOCAL | cut -c1-7)"; \
					echo "      Remote: $$(echo $$TAG_COMMIT_REMOTE | cut -c1-7)"; \
					git tag -d "$$tag" 2>/dev/null || true; \
					CONFLICT_COUNT=$$((CONFLICT_COUNT + 1)); \
				fi; \
			fi; \
		done; \
		if [ $$CONFLICT_COUNT -gt 0 ]; then \
			echo "  ✓ Deleted $$CONFLICT_COUNT conflicting local tag(s)"; \
		fi; \
	else \
		echo "  ✓ No tag conflicts detected"; \
	fi; \
	echo ""; \
	echo "Step 2: Force-fetching tags from remote..."; \
	if timeout 30 git fetch --tags --force origin >/dev/null 2>&1; then \
		echo "  ✓ Tags synced with remote"; \
	else \
		FETCH_CODE=$$?; \
		if [ $$FETCH_CODE -eq 124 ]; then \
			echo "  ⚠ Force-fetch timed out after 30 seconds"; \
			echo "     Tags may not be fully synced. You may need to run this again."; \
		else \
			echo "  ⚠ Force-fetch failed (exit code: $$FETCH_CODE)"; \
			echo "     Tags may not be fully synced."; \
		fi; \
	fi; \
	echo ""; \
	echo "Step 3: Verifying repository state..."; \
	if [ -n "$$(git status --porcelain 2>/dev/null)" ]; then \
		echo "  ℹ Working directory has uncommitted changes"; \
		git status --short | sed 's/^/    /'; \
	else \
		echo "  ✓ Working directory is clean"; \
	fi; \
	CURRENT_BRANCH=$$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"); \
	echo "  Current branch: $$CURRENT_BRANCH"; \
	echo ""; \
	echo "=== Fix complete ==="; \
	echo ""

# Rule template for building programs
define PROG_template
 # Objects from sources
 OBJS_$(1) = $(addprefix $(ODIR)/,$(SOURCES_$(1):%.c=%.o))
 # All SOURCES/OBJECTS
 SOURCES += $$(SOURCES_$(1))
 OBJS += $$(OBJS_$(1))
 # Determine extension dynamically based on CC
 # Link rule
$(PROG_DIR)/$(1)$$(if $$(findstring mingw,$$(CC)),.exe,): $$(OBJS_$(1)) | $(PROG_DIR)
	$$(CC) $$(CFLAGS) $$(LDFLAGS) $$^ $$(LDLIBS) -o $$@
endef

# Generate all rules
$(foreach prog,$(PROGS),$(eval $(call PROG_template,$(prog))))

DEPS = $(OBJS:%.o=%.d)

clean:
	-rm -f $(OBJS) $(DEPS) $(VERSION_STAMP)
	-rmdir $(BUILD_DIR) 2>/dev/null || true
	-rm -f $(PROGS:%=$(PROG_DIR)/%)
	-rmdir $(PROG_DIR) 2>/dev/null || true
	-rm -rf $(RELEASE_DIR)

distclean: clean
	-rm -rf $(RELEASE_DIR)

# Create output dirs
$(BUILD_DIR):
	mkdir -p $@

$(PROG_DIR):
	mkdir -p $@

$(OBJS): | $(BUILD_DIR)
$(DEPS): | $(BUILD_DIR)
$(PROGS:%=$(PROG_DIR)/%): | $(PROG_DIR)

# Compilation (version.h is a dependency for msg.c)
$(BUILD_DIR)/msg.o: src/msg.c src/version.h
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# Compilation
$(BUILD_DIR)/%.o: src/%.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# Dependencies
$(BUILD_DIR)/%.d: src/%.c
	@$(CC) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(CFLAGS) $(CPPFLAGS) $<

ifneq "$(MAKECMDGOALS)" "clean"
 ifneq "$(MAKECMDGOALS)" "distclean"
  -include $(DEPS)
 endif
endif

# ============================================================================
# Release Builds
# ============================================================================

# Release builds for all platforms
release: $(VERSION_STAMP)
	@$(MAKE) release-linux-amd64 release-linux-arm64 release-windows-x86_64 release-macos
	@echo ""
	@echo "Release builds completed:"
	@ls -lh $(RELEASE_DIR)/ 2>/dev/null || echo "  No release files found"

# macOS builds (require Docker and macOS SDK)
release-macos: release-macos-x86_64 release-macos-arm64
	@echo ""
	@echo "macOS builds completed:"
	@ls -lh $(RELEASE_DIR)/*-macos-* 2>/dev/null || echo "  No macOS binaries found"

# Helper function to build all programs for a platform
define BUILD_ALL_PROGS
	@for prog in $(PROGS); do \
		echo "  Building $$prog..."; \
		EXT=$$(if echo "$(1)" | grep -q mingw; then echo ".exe"; else echo ""; fi); \
		$(MAKE) CC=$(1) \
			CFLAGS="$(INCLUDE_DIRS) $(2)" \
			LDFLAGS="$(LDFLAGS)" \
			LDLIBS="$(LDLIBS)" \
			BDIR=$(3) \
			ODIR=$(3) \
			PROG_DIR=$(3)/bin \
			BUILD_DIR=$(3) \
			SKIP_VERSION_INCREMENT=1 \
			$(3)/bin/$$prog$$EXT || exit 1; \
	done
endef

# Linux amd64 build (native)
release-linux-amd64: $(VERSION_STAMP)
	@mkdir -p $(RELEASE_DIR)
	@echo "Building Linux amd64..."
	@rm -rf $(BDIR)-linux-amd64
	@$(call BUILD_ALL_PROGS,gcc,-O3 -Wall -flto=auto,$(BDIR)-linux-amd64,)
	@VERSION_NUM=$$(cat $(VERSION_FILE) 2>/dev/null || echo "unknown"); \
	for prog in $(PROGS); do \
		cp $(BDIR)-linux-amd64/bin/$$prog $(RELEASE_DIR)/$$prog-$$VERSION_NUM-linux-amd64 && \
		chmod +x $(RELEASE_DIR)/$$prog-$$VERSION_NUM-linux-amd64 && \
		echo "  ✓ $$prog-$$VERSION_NUM-linux-amd64"; \
	done
	@echo "  ✓ Linux amd64 builds complete"

# Linux arm64 build (cross-compile)
release-linux-arm64: $(VERSION_STAMP)
	@mkdir -p $(RELEASE_DIR)
	@echo "Building Linux arm64..."
	@if ! command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then \
		echo "  ⚠ aarch64-linux-gnu-gcc not found. Installing cross-compiler..."; \
		if command -v apt-get >/dev/null 2>&1; then \
			sudo apt-get update && sudo apt-get install -y gcc-aarch64-linux-gnu; \
		elif command -v yum >/dev/null 2>&1; then \
			sudo yum install -y gcc-aarch64-linux-gnu; \
		else \
			echo "  ✗ Please install gcc-aarch64-linux-gnu manually"; \
			exit 1; \
		fi \
	fi
	@rm -rf $(BDIR)-linux-arm64
	@$(call BUILD_ALL_PROGS,aarch64-linux-gnu-gcc,-O3 -Wall -flto=auto,$(BDIR)-linux-arm64,)
	@VERSION_NUM=$$(cat $(VERSION_FILE) 2>/dev/null || echo "unknown"); \
	for prog in $(PROGS); do \
		cp $(BDIR)-linux-arm64/bin/$$prog $(RELEASE_DIR)/$$prog-$$VERSION_NUM-linux-arm64 && \
		chmod +x $(RELEASE_DIR)/$$prog-$$VERSION_NUM-linux-arm64 && \
		echo "  ✓ $$prog-$$VERSION_NUM-linux-arm64"; \
	done
	@echo "  ✓ Linux arm64 builds complete"

# Windows x86_64 build (cross-compile with MinGW)
release-windows-x86_64: $(VERSION_STAMP)
	@mkdir -p $(RELEASE_DIR)
	@echo "Building Windows x86_64..."
	@if ! command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1; then \
		echo "  ⚠ x86_64-w64-mingw32-gcc not found. Installing MinGW..."; \
		if command -v apt-get >/dev/null 2>&1; then \
			sudo apt-get update && sudo apt-get install -y mingw-w64; \
		elif command -v yum >/dev/null 2>&1; then \
			sudo yum install -y mingw64-gcc; \
		else \
			echo "  ✗ Please install mingw-w64 manually"; \
			exit 1; \
		fi \
	fi
	@rm -rf $(BDIR)-windows-x86_64
	@$(call BUILD_ALL_PROGS,x86_64-w64-mingw32-gcc,-O3 -Wall -flto=auto,$(BDIR)-windows-x86_64,)
	@VERSION_NUM=$$(cat $(VERSION_FILE) 2>/dev/null || echo "unknown"); \
	for prog in $(PROGS); do \
		cp $(BDIR)-windows-x86_64/bin/$$prog.exe $(RELEASE_DIR)/$$prog-$$VERSION_NUM-windows-x86_64.exe && \
		echo "  ✓ $$prog-$$VERSION_NUM-windows-x86_64.exe"; \
	done
	@echo "  ✓ Windows x86_64 builds complete"

# macOS Intel build (requires Docker)
release-macos-x86_64: $(VERSION_STAMP)
	@if [ -z "$(DOCKER_IMAGE)" ]; then \
		echo "  ✗ DOCKER_IMAGE not configured. Set DOCKER_IMAGE variable."; \
		exit 1; \
	fi
	@echo "Building macOS Intel (x86_64) using Docker..."
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "  ✗ Docker not found. Please install Docker."; \
		exit 1; \
	fi
	@mkdir -p $(RELEASE_DIR)
	@VERSION_NUM=$$(cat $(VERSION_FILE) 2>/dev/null || echo "unknown"); \
	echo "  Using $(DOCKER_IMAGE) Docker image..."; \
	docker run --platform=linux/amd64 --rm \
		-v $(CURDIR):/workspace \
		-v $(CURDIR)/$(RELEASE_DIR):/workspace/release \
		-w /workspace \
		$(DOCKER_IMAGE) \
		sh -c " \
			VERSION_NUM=$$VERSION_NUM; \
			rm -rf build-macos-x86_64 && \
			for prog in $(PROGS); do \
				make CC=x86_64-apple-darwin24-gcc \
					CFLAGS=\"$(INCLUDE_DIRS) -O3 -Wall -flto=auto\" \
					LDLIBS=\"$(LDLIBS)\" \
					BDIR=build-macos-x86_64 \
					ODIR=build-macos-x86_64 \
					PROG_DIR=build-macos-x86_64/bin \
					BUILD_DIR=build-macos-x86_64 \
					SKIP_VERSION_INCREMENT=1 \
					build-macos-x86_64/bin/\$$prog && \
				cp build-macos-x86_64/bin/\$$prog release/\$$prog-\$$VERSION_NUM-macos-x86_64 && \
				chmod +x release/\$$prog-\$$VERSION_NUM-macos-x86_64; \
			done && \
			echo '  ✓ macOS Intel builds complete' \
		" || echo "  ⚠ macOS Intel builds may have failed. Check Docker output above."

# macOS Apple Silicon build (requires Docker)
release-macos-arm64: $(VERSION_STAMP)
	@if [ -z "$(DOCKER_IMAGE)" ]; then \
		echo "  ✗ DOCKER_IMAGE not configured. Set DOCKER_IMAGE variable."; \
		exit 1; \
	fi
	@echo "Building macOS Apple Silicon (arm64) using Docker..."
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "  ✗ Docker not found. Please install Docker."; \
		exit 1; \
	fi
	@mkdir -p $(RELEASE_DIR)
	@VERSION_NUM=$$(cat $(VERSION_FILE) 2>/dev/null || echo "unknown"); \
	echo "  Using $(DOCKER_IMAGE) Docker image..."; \
	docker run --platform=linux/amd64 --rm \
		-v $(CURDIR):/workspace \
		-v $(CURDIR)/$(RELEASE_DIR):/workspace/release \
		-w /workspace \
		$(DOCKER_IMAGE) \
		sh -c " \
			VERSION_NUM=$$VERSION_NUM; \
			rm -rf build-macos-arm64 && \
			for prog in $(PROGS); do \
				make CC=aarch64-apple-darwin24-gcc \
					CFLAGS=\"$(INCLUDE_DIRS) -O3 -Wall -flto=auto\" \
					LDLIBS=\"$(LDLIBS)\" \
					BDIR=build-macos-arm64 \
					ODIR=build-macos-arm64 \
					PROG_DIR=build-macos-arm64/bin \
					BUILD_DIR=build-macos-arm64 \
					SKIP_VERSION_INCREMENT=1 \
					build-macos-arm64/bin/\$$prog && \
				cp build-macos-arm64/bin/\$$prog release/\$$prog-\$$VERSION_NUM-macos-arm64 && \
				chmod +x release/\$$prog-\$$VERSION_NUM-macos-arm64; \
			done && \
			echo '  ✓ macOS Apple Silicon builds complete' \
		" || echo "  ⚠ macOS Apple Silicon builds may have failed. Check Docker output above."

# Alternative: Build releases using Docker (if cross-compilers are not available)
release-docker:
	@mkdir -p $(RELEASE_DIR)
	@echo "Building releases using Docker..."
	@docker build -f Dockerfile.release -t atrforge-builder .
	@docker run --rm -v $(CURDIR)/$(RELEASE_DIR):/workspace/release atrforge-builder
	@echo ""
	@echo "Docker release builds completed:"
	@ls -lh $(RELEASE_DIR)/

# ============================================================================
# GitHub Release
# ============================================================================

# Create GitHub release with all binaries
# Usage: make github-release [VERSION=v1.2.3] [SKIP_GIT=1] [AUTO_COMMIT=1]
github-release:
	@echo ""; \
	echo "=== Preparing for release ==="; \
	CURRENT_BRANCH=$$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"); \
	echo "Current branch: $$CURRENT_BRANCH"; \
	if [ "$(SKIP_GIT)" != "1" ]; then \
		echo ""; \
		echo "Step 1: Checking git status..."; \
		if [ -n "$$(git status --porcelain 2>/dev/null)" ]; then \
			echo "  Found uncommitted changes:"; \
			git status --short; \
			if [ "$(AUTO_COMMIT)" = "1" ]; then \
				COMMIT_MSG="Prepare release: $$(date '+%Y-%m-%d %H:%M:%S')"; \
				git add -A; \
				git commit -m "$$COMMIT_MSG" || { \
					echo "  ⚠ Failed to commit changes"; \
					exit 1; \
				}; \
				echo "  ✓ Changes committed automatically"; \
			else \
				echo "  Auto-committing changes for automation..."; \
				COMMIT_MSG="Prepare release: $$(date '+%Y-%m-%d %H:%M:%S')"; \
				git add -A; \
				git commit -m "$$COMMIT_MSG" || { \
					echo "  ⚠ Failed to commit changes"; \
					exit 1; \
				}; \
				echo "  ✓ Changes committed"; \
			fi; \
		else \
			echo "  ✓ Working directory clean"; \
		fi; \
		echo ""; \
		echo "Step 2: Pushing to remote..."; \
		if git rev-parse --verify origin/$$CURRENT_BRANCH >/dev/null 2>&1; then \
			echo "  Pushing to origin/$$CURRENT_BRANCH (timeout: 60s)..."; \
			if timeout 60 git push origin $$CURRENT_BRANCH 2>&1; then \
				echo "  ✓ Pushed to origin/$$CURRENT_BRANCH"; \
			else \
				PUSH_CODE=$$?; \
				if [ $$PUSH_CODE -eq 124 ]; then \
					echo "  ⚠ Push timed out after 60 seconds"; \
					echo "     This may indicate network issues"; \
				else \
					echo "  ⚠ Failed to push to origin/$$CURRENT_BRANCH (exit code: $$PUSH_CODE)"; \
				fi; \
				echo "     You may need to push manually: git push origin $$CURRENT_BRANCH"; \
				echo "     Continuing anyway (automation mode)..."; \
			fi; \
		else \
			echo "  Creating and pushing branch $$CURRENT_BRANCH (timeout: 60s)..."; \
			if timeout 60 git push -u origin $$CURRENT_BRANCH 2>&1; then \
				echo "  ✓ Pushed to origin/$$CURRENT_BRANCH"; \
			else \
				PUSH_CODE=$$?; \
				if [ $$PUSH_CODE -eq 124 ]; then \
					echo "  ✗ Push timed out after 60 seconds"; \
					echo "     Please push manually: git push -u origin $$CURRENT_BRANCH"; \
				else \
					echo "  ✗ Failed to push branch (exit code: $$PUSH_CODE)"; \
				fi; \
				exit 1; \
			fi; \
		fi; \
		echo ""; \
		if [ "$$CURRENT_BRANCH" != "develop" ]; then \
			echo "Step 3: Switching to develop branch..."; \
			git fetch origin develop:develop 2>/dev/null || true; \
			git checkout develop 2>/dev/null || { \
				echo "  ⚠ develop branch not found locally or remotely"; \
				echo "     Creating develop branch from current branch..."; \
				git checkout -b develop; \
				git push -u origin develop || { \
					echo "  ⚠ Failed to push develop branch"; \
					exit 1; \
				}; \
			}; \
			if timeout 10 git pull origin develop 2>/dev/null; then \
				echo "  ✓ Switched to develop branch"; \
			else \
				echo "  ⚠ Failed to pull latest develop (timeout or network issue)"; \
				echo "     Continuing anyway..."; \
			fi; \
		else \
			echo "Step 3: Already on develop branch, pulling latest..."; \
			if timeout 10 git pull origin develop 2>/dev/null; then \
				echo "  ✓ Develop branch up to date"; \
			else \
				echo "  ⚠ Failed to pull latest develop (timeout or network issue)"; \
				echo "     Continuing anyway..."; \
			fi; \
		fi; \
		echo ""; \
		echo "Step 4: Waiting for CI to pass..."; \
		if ! command -v gh >/dev/null 2>&1; then \
			echo "  ✗ GitHub CLI (gh) not found. Please install it:"; \
			echo "     https://cli.github.com/"; \
			exit 1; \
		fi; \
		if ! gh auth status >/dev/null 2>&1; then \
			echo "  ✗ Not authenticated with GitHub. Please run: gh auth login"; \
			exit 1; \
		fi; \
		echo "  ✓ GitHub CLI found and authenticated"; \
		echo "  Waiting for CI workflow to complete on develop branch..."; \
		CI_RUN_ID=$$(gh run list --workflow=ci.yml --branch=develop --limit=1 --json databaseId,status,conclusion -q '.[0].databaseId' 2>/dev/null); \
		if [ -z "$$CI_RUN_ID" ]; then \
			echo "  ⚠ No CI run found. Waiting for CI to start..."; \
			sleep 5; \
			CI_RUN_ID=$$(gh run list --workflow=ci.yml --branch=develop --limit=1 --json databaseId,status,conclusion -q '.[0].databaseId' 2>/dev/null); \
			if [ -z "$$CI_RUN_ID" ]; then \
				echo "  ✗ Could not find CI run. Please check GitHub Actions manually."; \
				exit 1; \
			fi; \
		fi; \
		echo "  Watching CI run: $$CI_RUN_ID"; \
		gh run watch $$CI_RUN_ID --exit-status || { \
			echo ""; \
			echo "  ✗ CI failed. Please fix the issues and try again."; \
			echo "     View CI run: gh run view $$CI_RUN_ID"; \
			exit 1; \
		}; \
		echo "  ✓ CI passed"; \
		echo ""; \
		echo "=== Git operations complete ==="; \
		echo ""; \
	fi; \
	$(MAKE) github-release-build

# Internal target: Build and create GitHub release
github-release-build:
	@echo ""; \
	echo "=== Cleaning release directory ==="; \
	rm -rf $(RELEASE_DIR)/*-*; \
	rm -f $(RELEASE_DIR)/notes.md; \
	echo "  ✓ Release directory cleaned"; \
	echo ""; \
	echo "=== Building release binaries ==="; \
	$(MAKE) release; \
	echo ""; \
	echo "=== Creating GitHub release ==="; \
	if ! command -v gh >/dev/null 2>&1; then \
		echo "  ✗ GitHub CLI (gh) not found. Please install it:"; \
		echo "     https://cli.github.com/"; \
		exit 1; \
	fi; \
	if ! gh auth status >/dev/null 2>&1; then \
		echo "  ✗ Not authenticated with GitHub. Please run: gh auth login"; \
		exit 1; \
	fi; \
	echo "  ✓ GitHub CLI found and authenticated"; \
	echo ""; \
	echo "Determining version..."; \
	VERSION=$$( \
		if [ -n "$(VERSION)" ]; then \
			echo "$(VERSION)" | sed 's/^v*/v/'; \
		elif git describe --tags --exact-match >/dev/null 2>&1; then \
			git describe --tags --exact-match; \
		else \
			LATEST_TAG=$$(git describe --tags --abbrev=0 2>/dev/null); \
			if [ -n "$$LATEST_TAG" ]; then \
				MAJOR=$$(echo $$LATEST_TAG | sed 's/^v//' | cut -d. -f1); \
				MINOR=$$(echo $$LATEST_TAG | sed 's/^v//' | cut -d. -f2); \
				PATCH=$$(echo $$LATEST_TAG | sed 's/^v//' | cut -d. -f3); \
				PATCH=$$((PATCH + 1)); \
				echo "v$$MAJOR.$$MINOR.$$PATCH"; \
			else \
				echo "v1.0.0"; \
			fi; \
		fi \
	); \
	if [ -n "$(VERSION)" ]; then \
		echo "  Using specified version: $$VERSION"; \
	elif git describe --tags --exact-match >/dev/null 2>&1; then \
		echo "  Using current tag: $$VERSION"; \
	else \
		LATEST_TAG=$$(git describe --tags --abbrev=0 2>/dev/null); \
		if [ -n "$$LATEST_TAG" ]; then \
			echo "  Auto-incremented from latest tag: $$LATEST_TAG -> $$VERSION"; \
		else \
			echo "  No tags found, using: $$VERSION"; \
		fi; \
	fi; \
	echo ""; \
	echo "Checking if release already exists..."; \
	if gh release view "$$VERSION" >/dev/null 2>&1; then \
		echo "  ⚠ Release $$VERSION already exists on GitHub."; \
		if [ -z "$(VERSION)" ]; then \
			echo "     Auto-incrementing version..."; \
			LATEST_TAG=$$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0"); \
			MAJOR=$$(echo $$LATEST_TAG | sed 's/^v//' | cut -d. -f1); \
			MINOR=$$(echo $$LATEST_TAG | sed 's/^v//' | cut -d. -f2); \
			PATCH=$$(echo $$LATEST_TAG | sed 's/^v//' | cut -d. -f3); \
			PATCH=$$((PATCH + 1)); \
			VERSION="v$$MAJOR.$$MINOR.$$PATCH"; \
			echo "  Using incremented version: $$VERSION"; \
		else \
			echo "     To update it, delete the existing release first, or use a different version."; \
			echo "     Delete: gh release delete $$VERSION"; \
			echo "     Or specify a different version: make github-release VERSION=v1.2.3"; \
			exit 1; \
		fi; \
	fi; \
	echo ""; \
	echo "Creating release notes..."; \
	mkdir -p $(RELEASE_DIR); \
	if [ -f "$(CHANGELOG_PATH)" ]; then \
		RELEASE_DATE=$$(date '+%Y-%m-%d %H:%M:%S'); \
		echo "## Release $$VERSION - $$RELEASE_DATE" > $(RELEASE_DIR)/notes.md; \
		echo "" >> $(RELEASE_DIR)/notes.md; \
		awk '/^## \[/{p=0} /^## \[Unreleased\]/{p=1; next} p' $(CHANGELOG_PATH) > $(RELEASE_DIR)/current-unreleased.md 2>/dev/null; \
		if [ -f .last-changelog.md ]; then \
			echo "  Comparing with previous changelog to extract new changes..."; \
			if [ -s $(RELEASE_DIR)/current-unreleased.md ]; then \
				if ! diff -q .last-changelog.md $(RELEASE_DIR)/current-unreleased.md >/dev/null 2>&1; then \
					diff -u .last-changelog.md $(RELEASE_DIR)/current-unreleased.md 2>/dev/null | \
					awk '/^\+/ && !/^+++/ && !/^\+---/ { \
						line = substr($$0, 2); \
						if (line !~ /^@@/) print line; \
					}' >> $(RELEASE_DIR)/notes.md || \
					cat $(RELEASE_DIR)/current-unreleased.md >> $(RELEASE_DIR)/notes.md; \
				else \
					echo "No new changes detected since last release." >> $(RELEASE_DIR)/notes.md; \
					echo "  ⚠ Warning: [Unreleased] section unchanged since last release"; \
				fi; \
			else \
				echo "No changes found in [Unreleased] section." >> $(RELEASE_DIR)/notes.md; \
			fi; \
		else \
			echo "  No previous changelog found, using all [Unreleased] entries..."; \
			if [ -s $(RELEASE_DIR)/current-unreleased.md ]; then \
				cat $(RELEASE_DIR)/current-unreleased.md >> $(RELEASE_DIR)/notes.md; \
			else \
				echo "No changes found in [Unreleased] section." >> $(RELEASE_DIR)/notes.md; \
			fi; \
		fi; \
		rm -f $(RELEASE_DIR)/current-unreleased.md; \
	else \
		echo "## Changes" > $(RELEASE_DIR)/notes.md; \
		echo "Release $$VERSION" >> $(RELEASE_DIR)/notes.md; \
	fi; \
	IS_PRERELEASE=$$(echo "$$VERSION" | grep -qE '(-|alpha|beta)' && echo "true" || echo "false"); \
	echo "  Creating release $$VERSION (prerelease: $$IS_PRERELEASE)..."; \
	echo ""; \
	echo "Creating/verifying git tag..."; \
	CURRENT_BRANCH=$$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"); \
	if [ "$$CURRENT_BRANCH" != "main" ]; then \
		echo "  ⚠ Warning: Not on main branch (currently on $$CURRENT_BRANCH)"; \
		echo "     Tag will be created on current branch"; \
	fi; \
	TAG_EXISTS_LOCAL=$$(git rev-parse "$$VERSION" >/dev/null 2>&1 && echo "yes" || echo "no"); \
	if timeout 10 git ls-remote --tags origin "$$VERSION" >/dev/null 2>&1; then \
		TAG_EXISTS_REMOTE="yes"; \
	else \
		TAG_EXISTS_REMOTE="no"; \
	fi; \
	CURRENT_COMMIT=$$(git rev-parse HEAD); \
	if [ "$$TAG_EXISTS_LOCAL" = "yes" ]; then \
		TAG_COMMIT=$$(git rev-parse "$$VERSION" 2>/dev/null); \
		if [ "$$TAG_COMMIT" != "$$CURRENT_COMMIT" ]; then \
			echo "  ⚠ Warning: Tag $$VERSION exists but points to different commit"; \
			echo "     Tag points to: $$TAG_COMMIT"; \
			echo "     Current HEAD:  $$CURRENT_COMMIT"; \
			echo "     Deleting local tag to recreate..."; \
			git tag -d "$$VERSION" 2>/dev/null || true; \
			TAG_EXISTS_LOCAL="no"; \
		fi; \
	fi; \
	if [ "$$TAG_EXISTS_LOCAL" = "no" ]; then \
		echo "  Creating git tag $$VERSION..."; \
		git tag -a "$$VERSION" -m "Release $$VERSION" || { \
			echo "  ✗ Failed to create tag"; \
			exit 1; \
		}; \
		echo "  ✓ Tag created locally"; \
	fi; \
	if [ "$$TAG_EXISTS_REMOTE" = "no" ]; then \
		echo "  Pushing tag to remote (timeout: 60s)..."; \
		if timeout 60 git push origin "$$VERSION" 2>&1; then \
			echo "  ✓ Tag pushed to remote"; \
		else \
			PUSH_CODE=$$?; \
			if [ $$PUSH_CODE -eq 124 ]; then \
				echo "  ✗ Push timed out after 60 seconds"; \
				echo "     Please push manually: git push origin $$VERSION"; \
			else \
				echo "  ✗ Failed to push tag to remote (exit code: $$PUSH_CODE)"; \
				echo "     Tag exists locally but not on remote."; \
				echo "     Please push manually: git push origin $$VERSION"; \
				echo "     Or delete local tag and retry: git tag -d $$VERSION"; \
			fi; \
			exit 1; \
		fi; \
	elif [ "$$TAG_EXISTS_LOCAL" = "yes" ]; then \
		echo "  ✓ Tag $$VERSION already exists on remote"; \
	fi; \
	echo ""; \
	echo "Collecting release files..."; \
	VERSION_NUM=$$(echo "$$VERSION" | sed 's/^v//'); \
	RELEASE_FILES=""; \
	for prog in $(PROGS); do \
		for platform in linux-amd64 linux-arm64 windows-x86_64 macos-x86_64 macos-arm64; do \
			if [ "$$platform" = "windows-x86_64" ]; then \
				EXT=".exe"; \
			else \
				EXT=""; \
			fi; \
			VERSIONED_FILE="$(RELEASE_DIR)/$$prog-$$VERSION_NUM-$$platform$$EXT"; \
			UNVERSIONED_FILE="$(RELEASE_DIR)/$$prog-$$platform$$EXT"; \
			if [ -f "$$VERSIONED_FILE" ]; then \
				echo "  ✓ Found versioned file: $$prog-$$VERSION_NUM-$$platform$$EXT"; \
				RELEASE_FILES="$$RELEASE_FILES $$VERSIONED_FILE"; \
			elif [ -f "$$UNVERSIONED_FILE" ]; then \
				echo "  Renaming: $$prog-$$platform$$EXT -> $$prog-$$VERSION_NUM-$$platform$$EXT"; \
				mv "$$UNVERSIONED_FILE" "$$VERSIONED_FILE" && \
				echo "  ✓ $$prog-$$VERSION_NUM-$$platform$$EXT"; \
				RELEASE_FILES="$$RELEASE_FILES $$VERSIONED_FILE"; \
			fi; \
		done; \
	done; \
	if [ -z "$$RELEASE_FILES" ]; then \
		echo "  ✗ No release files found to upload"; \
		echo "  Expected files in $(RELEASE_DIR)/ with pattern: <program>-<version>-<platform>"; \
		echo "  Or unversioned pattern: <program>-<platform>"; \
		exit 1; \
	fi; \
	echo ""; \
	echo "Release files to upload:"; \
	for file in $$RELEASE_FILES; do \
		if [ -f "$$file" ]; then \
			echo "  ✓ $$(basename $$file)"; \
		else \
			echo "  ✗ Missing: $$file"; \
		fi; \
	done; \
	echo ""; \
	echo "Verifying tag exists on remote..."; \
	if timeout 10 git ls-remote --tags origin "$$VERSION" >/dev/null 2>&1; then \
		echo "  ✓ Tag $$VERSION exists on remote"; \
	else \
		CHECK_CODE=$$?; \
		if [ $$CHECK_CODE -eq 124 ]; then \
			echo "  ⚠ Tag check timed out after 10 seconds"; \
			echo "     Assuming tag exists and continuing..."; \
		else \
			echo "  ✗ Tag $$VERSION does not exist on remote"; \
			echo "     Please push the tag first: git push origin $$VERSION"; \
			exit 1; \
		fi; \
	fi; \
	echo ""; \
	echo "Uploading release files..."; \
	gh release create "$$VERSION" \
		--title "Release $$VERSION" \
		--notes-file $(RELEASE_DIR)/notes.md \
		$$RELEASE_FILES \
		--prerelease=$$IS_PRERELEASE \
		--latest || { \
		echo ""; \
		echo "  ✗ Failed to create release."; \
		echo "     Common issues:"; \
		echo "     - Release with tag $$VERSION already exists"; \
		echo "     - Tag $$VERSION doesn't exist (should have been created above)"; \
		echo "     - Insufficient permissions"; \
		echo ""; \
		echo "     Solutions:"; \
		echo "     - Delete existing release: gh release delete $$VERSION"; \
		echo "     - Use a different version: make github-release VERSION=v1.2.3"; \
		echo "     - Check permissions: gh auth status"; \
		exit 1; \
	}; \
	echo ""; \
	echo "  ✓ GitHub release created successfully!"; \
	REPO=$$(gh repo view --json owner,name -q '.owner.login + "/" + .name' 2>/dev/null); \
	if [ -n "$$REPO" ]; then \
		echo "  View it at: https://github.com/$$REPO/releases/latest"; \
	fi; \
	echo ""; \
	echo "Saving changelog state..."; \
	if [ -f "$(CHANGELOG_PATH)" ]; then \
		awk '/^## \[/{p=0} /^## \[Unreleased\]/{p=1; next} p' $(CHANGELOG_PATH) > .last-changelog.md 2>/dev/null && \
		echo "  ✓ Saved current [Unreleased] section to .last-changelog.md" || \
		echo "  ⚠ Failed to save changelog state"; \
	else \
		echo "  ⚠ CHANGELOG.md not found, skipping state save"; \
	fi
