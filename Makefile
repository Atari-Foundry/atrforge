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

.PHONY: all clean distclean help test release release-docker release-linux-amd64 release-linux-arm64 release-windows-x86_64 release-macos-x86_64 release-macos-arm64 release-macos github-release github-release-build

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
	VERBOSE=$$([ "$(VERBOSE)" = "1" ] && echo "1" || echo "0"); \
	if [ "$$VERBOSE" = "1" ]; then \
		echo "[VERBOSE] SKIP_GIT=$(SKIP_GIT)"; \
		echo "[VERBOSE] AUTO_COMMIT=$(AUTO_COMMIT)"; \
		echo "[VERBOSE] VERSION=$(VERSION)"; \
	fi; \
	echo ""; \
	echo "Step 0: Cleaning build artifacts..."; \
	if [ "$$VERBOSE" = "1" ]; then \
		echo "  [VERBOSE] Running: make clean"; \
	fi; \
	$(MAKE) clean || { \
		echo "  ⚠ Warning: make clean failed, continuing anyway..."; \
	}; \
	echo "  ✓ Clean complete"; \
	echo ""; \
	CURRENT_BRANCH=$$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"); \
	echo "Current branch: $$CURRENT_BRANCH"; \
	if [ "$(SKIP_GIT)" != "1" ]; then \
		echo ""; \
		echo "Step 1: Checking git status..."; \
		if [ "$$VERBOSE" = "1" ]; then \
			echo "  [VERBOSE] Running: git status --porcelain"; \
		fi; \
		STATUS_OUTPUT=$$(git status --porcelain 2>&1); \
		STATUS_CODE=$$?; \
		if [ "$$VERBOSE" = "1" ]; then \
			echo "  [VERBOSE] git status exit code: $$STATUS_CODE"; \
			if [ -n "$$STATUS_OUTPUT" ]; then \
				echo "  [VERBOSE] git status output:"; \
				echo "$$STATUS_OUTPUT" | sed 's/^/    /'; \
			fi; \
		fi; \
		if [ -n "$$STATUS_OUTPUT" ]; then \
			echo "  Found uncommitted changes:"; \
			git status --short; \
			if [ "$(AUTO_COMMIT)" = "1" ]; then \
				COMMIT_MSG="Prepare release: $$(date '+%Y-%m-%d %H:%M:%S')"; \
				if [ "$$VERBOSE" = "1" ]; then \
					echo "  [VERBOSE] AUTO_COMMIT=1, committing automatically"; \
					echo "  [VERBOSE] Commit message: $$COMMIT_MSG"; \
				fi; \
				if [ "$$VERBOSE" = "1" ]; then echo "  [VERBOSE] Running: git add -A"; fi; \
				git add -A; \
				if [ "$$VERBOSE" = "1" ]; then echo "  [VERBOSE] Running: git commit -m \"$$COMMIT_MSG\""; fi; \
				git commit -m "$$COMMIT_MSG" || { \
					echo "  ⚠ Failed to commit changes"; \
					if [ "$$VERBOSE" = "1" ]; then \
						echo "  [VERBOSE] git commit failed, exit code: $$?"; \
					fi; \
					exit 1; \
				}; \
				echo "  ✓ Changes committed automatically"; \
			else \
				echo "  Auto-committing changes for automation..."; \
				COMMIT_MSG="Prepare release: $$(date '+%Y-%m-%d %H:%M:%S')"; \
				if [ "$$VERBOSE" = "1" ]; then \
					echo "  [VERBOSE] Auto-committing for automation"; \
					echo "  [VERBOSE] Commit message: $$COMMIT_MSG"; \
				fi; \
				if [ "$$VERBOSE" = "1" ]; then echo "  [VERBOSE] Running: git add -A"; fi; \
				git add -A; \
				if [ "$$VERBOSE" = "1" ]; then echo "  [VERBOSE] Running: git commit -m \"$$COMMIT_MSG\""; fi; \
				git commit -m "$$COMMIT_MSG" || { \
					echo "  ⚠ Failed to commit changes"; \
					if [ "$$VERBOSE" = "1" ]; then \
						echo "  [VERBOSE] git commit failed, exit code: $$?"; \
					fi; \
					exit 1; \
				}; \
				echo "  ✓ Changes committed"; \
			fi; \
		else \
			echo "  ✓ Working directory clean"; \
		fi; \
		echo ""; \
		echo "Step 2: Pushing to remote..."; \
		if [ "$$VERBOSE" = "1" ]; then \
			echo "  [VERBOSE] Checking if origin/$$CURRENT_BRANCH exists..."; \
			echo "  [VERBOSE] Running: git rev-parse --verify origin/$$CURRENT_BRANCH"; \
		fi; \
		if git rev-parse --verify origin/$$CURRENT_BRANCH >/dev/null 2>&1; then \
			if [ "$$VERBOSE" = "1" ]; then \
				echo "  [VERBOSE] Branch origin/$$CURRENT_BRANCH exists"; \
				echo "  [VERBOSE] Running: git push origin $$CURRENT_BRANCH"; \
			fi; \
			PUSH_OUTPUT=$$(git push origin $$CURRENT_BRANCH 2>&1); \
			PUSH_CODE=$$?; \
			if [ $$PUSH_CODE -ne 0 ]; then \
				echo "  ⚠ Failed to push to origin/$$CURRENT_BRANCH"; \
				if [ "$$VERBOSE" = "1" ]; then \
					echo "  [VERBOSE] git push exit code: $$PUSH_CODE"; \
					echo "  [VERBOSE] git push output:"; \
					echo "$$PUSH_OUTPUT" | sed 's/^/    /'; \
				fi; \
				echo "     You may need to push manually: git push origin $$CURRENT_BRANCH"; \
				echo "     Continuing with release anyway (automation mode)..."; \
			else \
				if [ "$$VERBOSE" = "1" ]; then \
					echo "  [VERBOSE] git push succeeded"; \
					if [ -n "$$PUSH_OUTPUT" ]; then \
						echo "  [VERBOSE] git push output:"; \
						echo "$$PUSH_OUTPUT" | sed 's/^/    /'; \
					fi; \
				fi; \
			fi; \
		else \
			echo "  Creating and pushing branch $$CURRENT_BRANCH..."; \
			if [ "$$VERBOSE" = "1" ]; then \
				echo "  [VERBOSE] Branch origin/$$CURRENT_BRANCH does not exist"; \
				echo "  [VERBOSE] Running: git push -u origin $$CURRENT_BRANCH"; \
			fi; \
			PUSH_OUTPUT=$$(git push -u origin $$CURRENT_BRANCH 2>&1); \
			PUSH_CODE=$$?; \
			if [ $$PUSH_CODE -ne 0 ]; then \
				echo "  ⚠ Failed to push branch"; \
				if [ "$$VERBOSE" = "1" ]; then \
					echo "  [VERBOSE] git push exit code: $$PUSH_CODE"; \
					echo "  [VERBOSE] git push output:"; \
					echo "$$PUSH_OUTPUT" | sed 's/^/    /'; \
				fi; \
				exit 1; \
			else \
				if [ "$$VERBOSE" = "1" ]; then \
					echo "  [VERBOSE] git push succeeded"; \
					if [ -n "$$PUSH_OUTPUT" ]; then \
						echo "  [VERBOSE] git push output:"; \
						echo "$$PUSH_OUTPUT" | sed 's/^/    /'; \
					fi; \
				fi; \
			fi; \
		fi; \
		echo "  ✓ Pushed to origin/$$CURRENT_BRANCH"; \
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
			if [ "$$VERBOSE" = "1" ]; then \
				echo "  [VERBOSE] Running: git pull origin develop"; \
			fi; \
			PULL_OUTPUT=$$(git pull origin develop 2>&1); \
			PULL_CODE=$$?; \
			if [ $$PULL_CODE -eq 0 ]; then \
				if [ "$$VERBOSE" = "1" ]; then \
					echo "  [VERBOSE] git pull succeeded"; \
					if [ -n "$$PULL_OUTPUT" ]; then \
						echo "  [VERBOSE] git pull output:"; \
						echo "$$PULL_OUTPUT" | sed 's/^/    /'; \
					fi; \
				fi; \
				echo "  ✓ Switched to develop branch"; \
			else \
				echo "  ⚠ Failed to pull latest develop (network issue or already up to date)"; \
				if [ "$$VERBOSE" = "1" ]; then \
					echo "  [VERBOSE] git pull exit code: $$PULL_CODE"; \
					echo "  [VERBOSE] git pull output:"; \
					echo "$$PULL_OUTPUT" | sed 's/^/    /'; \
				fi; \
				echo "     Continuing with release anyway..."; \
			fi; \
		else \
			echo "Step 3: Already on develop branch, pulling latest..."; \
			if [ "$$VERBOSE" = "1" ]; then \
				echo "  [VERBOSE] Running: git pull origin develop"; \
			fi; \
			PULL_OUTPUT=$$(git pull origin develop 2>&1); \
			PULL_CODE=$$?; \
			if [ $$PULL_CODE -eq 0 ]; then \
				if [ "$$VERBOSE" = "1" ]; then \
					echo "  [VERBOSE] git pull succeeded"; \
					if [ -n "$$PULL_OUTPUT" ]; then \
						echo "  [VERBOSE] git pull output:"; \
						echo "$$PULL_OUTPUT" | sed 's/^/    /'; \
					fi; \
				fi; \
				echo "  ✓ Develop branch up to date"; \
			else \
				echo "  ⚠ Failed to pull latest develop (network issue or already up to date)"; \
				if [ "$$VERBOSE" = "1" ]; then \
					echo "  [VERBOSE] git pull exit code: $$PULL_CODE"; \
					echo "  [VERBOSE] git pull output:"; \
					echo "$$PULL_OUTPUT" | sed 's/^/    /'; \
				fi; \
				echo "     Continuing with release anyway..."; \
			fi; \
		fi; \
		echo ""; \
		echo "  ℹ Note: GitHub Actions will automatically merge develop to main after CI passes."; \
		echo ""; \
		echo "=== Git operations complete ==="; \
		echo ""; \
	fi; \
	if [ "$$VERBOSE" = "1" ]; then \
		echo "[VERBOSE] Starting github-release-build..."; \
	fi; \
	$(MAKE) github-release-build VERBOSE=$(VERBOSE)

# Internal target: Build and create GitHub release
github-release-build:
	@echo ""; \
	VERBOSE=$$([ "$(VERBOSE)" = "1" ] && echo "1" || echo "0"); \
	if [ "$$VERBOSE" = "1" ]; then \
		echo "[VERBOSE] github-release-build started"; \
		echo "[VERBOSE] RELEASE_DIR=$(RELEASE_DIR)"; \
	fi; \
	echo "=== Cleaning release directory ==="; \
	if [ "$$VERBOSE" = "1" ]; then \
		echo "  [VERBOSE] Running: rm -rf $(RELEASE_DIR)/*-*"; \
		echo "  [VERBOSE] Running: rm -f $(RELEASE_DIR)/notes.md"; \
	fi; \
	rm -rf $(RELEASE_DIR)/*-*; \
	rm -f $(RELEASE_DIR)/notes.md; \
	echo "  ✓ Release directory cleaned"; \
	echo ""; \
	echo "=== Building release binaries ==="; \
	if [ "$$VERBOSE" = "1" ]; then \
		echo "  [VERBOSE] Running: make release"; \
	fi; \
	$(MAKE) release; \
	echo ""; \
	echo "=== Creating GitHub release ==="; \
	if [ "$$VERBOSE" = "1" ]; then \
		echo "  [VERBOSE] Checking for GitHub CLI (gh)..."; \
	fi; \
	if ! command -v gh >/dev/null 2>&1; then \
		echo "  ✗ GitHub CLI (gh) not found. Please install it:"; \
		echo "     https://cli.github.com/"; \
		exit 1; \
	fi; \
	if [ "$$VERBOSE" = "1" ]; then \
		echo "  [VERBOSE] GitHub CLI found: $$(command -v gh)"; \
		echo "  [VERBOSE] Running: gh auth status"; \
	fi; \
	AUTH_OUTPUT=$$(gh auth status 2>&1); \
	AUTH_CODE=$$?; \
	if [ $$AUTH_CODE -ne 0 ]; then \
		echo "  ✗ Not authenticated with GitHub. Please run: gh auth login"; \
		if [ "$$VERBOSE" = "1" ]; then \
			echo "  [VERBOSE] gh auth status exit code: $$AUTH_CODE"; \
			echo "  [VERBOSE] gh auth status output:"; \
			echo "$$AUTH_OUTPUT" | sed 's/^/    /'; \
		fi; \
		exit 1; \
	fi; \
	if [ "$$VERBOSE" = "1" ]; then \
		echo "  [VERBOSE] Authentication successful"; \
		echo "  [VERBOSE] gh auth status output:"; \
		echo "$$AUTH_OUTPUT" | sed 's/^/    /'; \
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
	if [ "$$VERBOSE" = "1" ]; then \
		echo "  [VERBOSE] Current branch: $$CURRENT_BRANCH"; \
		echo "  [VERBOSE] Version: $$VERSION"; \
	fi; \
	if [ "$$CURRENT_BRANCH" != "main" ]; then \
		echo "  ⚠ Warning: Not on main branch (currently on $$CURRENT_BRANCH)"; \
		echo "     Tag will be created on current branch"; \
	fi; \
	if [ "$$VERBOSE" = "1" ]; then \
		echo "  [VERBOSE] Checking if tag exists locally..."; \
		echo "  [VERBOSE] Running: git rev-parse \"$$VERSION\""; \
	fi; \
	TAG_EXISTS_LOCAL=$$(git rev-parse "$$VERSION" >/dev/null 2>&1 && echo "yes" || echo "no"); \
	if [ "$$VERBOSE" = "1" ]; then \
		echo "  [VERBOSE] Tag exists locally: $$TAG_EXISTS_LOCAL"; \
		if [ "$$TAG_EXISTS_LOCAL" = "yes" ]; then \
			TAG_COMMIT_LOCAL=$$(git rev-parse "$$VERSION" 2>/dev/null); \
			echo "  [VERBOSE] Local tag points to: $$TAG_COMMIT_LOCAL"; \
		fi; \
		echo "  [VERBOSE] Checking if tag exists on remote..."; \
		echo "  [VERBOSE] Running: git ls-remote --tags origin \"$$VERSION\""; \
	fi; \
	TAG_EXISTS_REMOTE=$$(git ls-remote --tags origin "$$VERSION" >/dev/null 2>&1 && echo "yes" || echo "no"); \
	if [ "$$VERBOSE" = "1" ]; then \
		echo "  [VERBOSE] Tag exists on remote: $$TAG_EXISTS_REMOTE"; \
		if [ "$$TAG_EXISTS_REMOTE" = "yes" ]; then \
			TAG_REMOTE_OUTPUT=$$(git ls-remote --tags origin "$$VERSION" 2>&1); \
			echo "  [VERBOSE] Remote tag info:"; \
			echo "$$TAG_REMOTE_OUTPUT" | sed 's/^/    /'; \
		fi; \
	fi; \
	CURRENT_COMMIT=$$(git rev-parse HEAD); \
	if [ "$$VERBOSE" = "1" ]; then \
		echo "  [VERBOSE] Current HEAD commit: $$CURRENT_COMMIT"; \
	fi; \
	TAG_NEEDS_PUSH=false; \
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
		echo "  Pushing tag to remote..."; \
		if [ "$(SKIP_GIT)" = "1" ]; then \
			echo "  ⚠ SKIP_GIT=1, but tag needs to be pushed for release"; \
			echo "  Attempting to push tag anyway..."; \
		fi; \
		if ! git push origin "$$VERSION" 2>/dev/null; then \
			echo "  ⚠ Failed to push tag to remote"; \
			echo "     Tag exists locally but not on remote."; \
			echo "     Will use --target flag for gh release create"; \
			TAG_NEEDS_PUSH=true; \
		else \
			echo "  ✓ Tag pushed to remote"; \
		fi; \
	else \
		echo "  ✓ Tag $$VERSION already exists on remote"; \
	fi; \
	echo ""; \
	echo "Collecting release files..."; \
	VERSION_NUM=$$(echo "$$VERSION" | sed 's/^v//'); \
	if [ "$$VERBOSE" = "1" ]; then \
		echo "  [VERBOSE] Version number (without 'v'): $$VERSION_NUM"; \
		echo "  [VERBOSE] Programs to collect: $(PROGS)"; \
		echo "  [VERBOSE] Release directory: $(RELEASE_DIR)"; \
	fi; \
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
				if [ "$$VERBOSE" = "1" ]; then \
					FILE_SIZE=$$(stat -c%s "$$VERSIONED_FILE" 2>/dev/null || stat -f%z "$$VERSIONED_FILE" 2>/dev/null || echo "unknown"); \
					echo "    [VERBOSE] File size: $$FILE_SIZE bytes"; \
				fi; \
				RELEASE_FILES="$$RELEASE_FILES $$VERSIONED_FILE"; \
			elif [ -f "$$UNVERSIONED_FILE" ]; then \
				echo "  Renaming: $$prog-$$platform$$EXT -> $$prog-$$VERSION_NUM-$$platform$$EXT"; \
				if [ "$$VERBOSE" = "1" ]; then \
					echo "  [VERBOSE] Running: mv \"$$UNVERSIONED_FILE\" \"$$VERSIONED_FILE\""; \
				fi; \
				mv "$$UNVERSIONED_FILE" "$$VERSIONED_FILE" && \
				echo "  ✓ $$prog-$$VERSION_NUM-$$platform$$EXT"; \
				RELEASE_FILES="$$RELEASE_FILES $$VERSIONED_FILE"; \
			fi; \
		done; \
	done; \
	if [ -z "$$RELEASE_FILES" ]; then \
		echo "  ✗ No release files found to upload"; \
		echo "  Expected files in $(RELEASE_DIR)/ with pattern: <program>-<version>-<platform>"; \
		if [ "$$VERBOSE" = "1" ]; then \
			echo "  [VERBOSE] Listing all files in $(RELEASE_DIR)/:"; \
			ls -la $(RELEASE_DIR)/ 2>/dev/null | sed 's/^/    /' || echo "    (directory not found or empty)"; \
		fi; \
		exit 1; \
	fi; \
	if [ "$$VERBOSE" = "1" ]; then \
		echo "  [VERBOSE] Total release files found: $$(echo $$RELEASE_FILES | wc -w)"; \
	fi; \
	echo ""; \
	echo "Release files to upload:"; \
	for file in $$RELEASE_FILES; do \
		if [ -f "$$file" ]; then \
			FILE_SIZE=$$(stat -c%s "$$file" 2>/dev/null || stat -f%z "$$file" 2>/dev/null || echo "unknown"); \
			echo "  ✓ $$(basename $$file) ($$FILE_SIZE bytes)"; \
		else \
			echo "  ✗ Missing: $$file"; \
			if [ "$$VERBOSE" = "1" ]; then \
				echo "    [VERBOSE] File does not exist at path: $$file"; \
			fi; \
		fi; \
	done; \
	echo ""; \
	echo "Generating release manifest..."; \
	MANIFEST_FILE="$(RELEASE_DIR)/manifest.json"; \
	echo "{" > "$$MANIFEST_FILE"; \
	echo "  \"version\": \"$$VERSION\"," >> "$$MANIFEST_FILE"; \
	echo "  \"release_date\": \"$$(date -u +%Y-%m-%dT%H:%M:%SZ)\"," >> "$$MANIFEST_FILE"; \
	echo "  \"files\": [" >> "$$MANIFEST_FILE"; \
	FIRST_FILE=true; \
	for file in $$RELEASE_FILES; do \
		if [ -f "$$file" ]; then \
			FILENAME=$$(basename "$$file"); \
			FILE_SIZE=$$(stat -c%s "$$file" 2>/dev/null || stat -f%z "$$file" 2>/dev/null || echo "0"); \
			if command -v sha256sum >/dev/null 2>&1; then \
				FILE_SHA256=$$(sha256sum "$$file" | cut -d' ' -f1); \
			elif command -v shasum >/dev/null 2>&1; then \
				FILE_SHA256=$$(shasum -a 256 "$$file" | cut -d' ' -f1); \
			else \
				FILE_SHA256=""; \
			fi; \
			PROG_NAME=$$(echo "$$FILENAME" | sed -E 's/-[0-9]+\.[0-9]+\.[0-9]+-.*//'); \
			PLATFORM_PART=$$(echo "$$FILENAME" | sed -E 's/.*-[0-9]+\.[0-9]+\.[0-9]+-(.*)$$/\1/' | sed 's/\.exe$$//'); \
			OS=$$(echo "$$PLATFORM_PART" | cut -d'-' -f1); \
			ARCH=$$(echo "$$PLATFORM_PART" | cut -d'-' -f2-); \
			if [ "$$OS" = "windows" ]; then \
				EXT=".exe"; \
			else \
				EXT=""; \
			fi; \
			if [ "$$FIRST_FILE" = "true" ]; then \
				FIRST_FILE=false; \
			else \
				echo "," >> "$$MANIFEST_FILE"; \
			fi; \
			printf "    {" >> "$$MANIFEST_FILE"; \
			printf "\"name\": \"$$FILENAME\"," >> "$$MANIFEST_FILE"; \
			printf "\"program\": \"$$PROG_NAME\"," >> "$$MANIFEST_FILE"; \
			printf "\"os\": \"$$OS\"," >> "$$MANIFEST_FILE"; \
			printf "\"arch\": \"$$ARCH\"," >> "$$MANIFEST_FILE"; \
			printf "\"size\": $$FILE_SIZE," >> "$$MANIFEST_FILE"; \
			if [ -n "$$FILE_SHA256" ]; then \
				printf "\"sha256\": \"$$FILE_SHA256\"," >> "$$MANIFEST_FILE"; \
			fi; \
			printf "\"download_url\": \"https://github.com/Atari-Foundry/atrforge/releases/download/$$VERSION/$$FILENAME\"" >> "$$MANIFEST_FILE"; \
			printf "}" >> "$$MANIFEST_FILE"; \
		fi; \
	done; \
	echo "" >> "$$MANIFEST_FILE"; \
	echo "  ]" >> "$$MANIFEST_FILE"; \
	echo "}" >> "$$MANIFEST_FILE"; \
	echo "  ✓ Manifest generated: $$MANIFEST_FILE"; \
	if [ "$$VERBOSE" = "1" ]; then \
		echo "  [VERBOSE] Manifest contents:"; \
		cat "$$MANIFEST_FILE" | sed 's/^/    /'; \
	fi; \
	echo ""; \
	echo "Verifying tag exists on remote..."; \
	if [ "$$TAG_NEEDS_PUSH" = "true" ]; then \
		echo "  ⚠ Tag not pushed, will use --target flag"; \
	else \
		if [ "$$VERBOSE" = "1" ]; then \
			echo "  [VERBOSE] Running: timeout 5 git ls-remote --tags origin \"$$VERSION\""; \
		fi; \
		TAG_CHECK_OUTPUT=$$(timeout 5 git ls-remote --tags origin "$$VERSION" 2>&1); \
		TAG_CHECK_CODE=$$?; \
		if [ $$TAG_CHECK_CODE -eq 124 ]; then \
			echo "  ⚠ Tag check timed out (network issue), will use --target flag"; \
			if [ "$$VERBOSE" = "1" ]; then \
				echo "  [VERBOSE] git ls-remote timed out after 5 seconds"; \
			fi; \
			TAG_NEEDS_PUSH=true; \
		elif [ $$TAG_CHECK_CODE -ne 0 ] || [ -z "$$TAG_CHECK_OUTPUT" ]; then \
			echo "  ⚠ Tag $$VERSION does not exist on remote or check failed"; \
			if [ "$$VERBOSE" = "1" ]; then \
				echo "  [VERBOSE] git ls-remote exit code: $$TAG_CHECK_CODE"; \
				if [ -n "$$TAG_CHECK_OUTPUT" ]; then \
					echo "  [VERBOSE] git ls-remote output:"; \
					echo "$$TAG_CHECK_OUTPUT" | sed 's/^/    /'; \
				fi; \
			fi; \
			echo "     Will use --target flag to create release"; \
			TAG_NEEDS_PUSH=true; \
		else \
			echo "  ✓ Tag $$VERSION exists on remote"; \
			if [ "$$VERBOSE" = "1" ]; then \
				echo "  [VERBOSE] Tag found on remote:"; \
				echo "$$TAG_CHECK_OUTPUT" | sed 's/^/    /'; \
			fi; \
		fi; \
	fi; \
	echo ""; \
	echo "Uploading release files..."; \
	TARGET_FAILED=false; \
	USE_TARGET=false; \
	if [ "$$TAG_NEEDS_PUSH" = "true" ]; then \
		USE_TARGET=true; \
	elif [ "$(SKIP_GIT)" = "1" ]; then \
		echo "  SKIP_GIT=1, using --target flag to ensure tag is created..."; \
		USE_TARGET=true; \
	fi; \
	if [ "$$USE_TARGET" = "true" ]; then \
		echo "  Creating release with --target flag at current commit..."; \
		if [ "$$VERBOSE" = "1" ]; then \
			echo "  [VERBOSE] Using --target flag with commit: $$CURRENT_COMMIT"; \
			echo "  [VERBOSE] Release files count: $$(echo $$RELEASE_FILES | wc -w)"; \
			echo "  [VERBOSE] Release files:"; \
			for f in $$RELEASE_FILES; do echo "    - $$f"; done; \
			echo "  [VERBOSE] Running: gh release create \"$$VERSION\" --title \"Release $$VERSION\" --notes-file $(RELEASE_DIR)/notes.md --target \"$$CURRENT_COMMIT\" $$RELEASE_FILES $(RELEASE_DIR)/manifest.json --prerelease=$$IS_PRERELEASE --latest"; \
		fi; \
		RELEASE_OUTPUT=$$(gh release create "$$VERSION" \
			--title "Release $$VERSION" \
			--notes-file $(RELEASE_DIR)/notes.md \
			--target "$$CURRENT_COMMIT" \
			$$RELEASE_FILES \
			$(RELEASE_DIR)/manifest.json \
			--prerelease=$$IS_PRERELEASE \
			--latest 2>&1); \
		RELEASE_CODE=$$?; \
		if [ $$RELEASE_CODE -ne 0 ]; then \
			TARGET_FAILED=true; \
			if [ "$$VERBOSE" = "1" ]; then \
				echo "  [VERBOSE] gh release create exit code: $$RELEASE_CODE"; \
				echo "  [VERBOSE] gh release create output:"; \
				echo "$$RELEASE_OUTPUT" | sed 's/^/    /'; \
			fi; \
		else \
			if [ "$$VERBOSE" = "1" ]; then \
				echo "  [VERBOSE] gh release create succeeded"; \
				if [ -n "$$RELEASE_OUTPUT" ]; then \
					echo "  [VERBOSE] gh release create output:"; \
					echo "$$RELEASE_OUTPUT" | sed 's/^/    /'; \
				fi; \
			fi; \
		fi; \
	else \
		echo "  Creating release (tag exists on remote)..."; \
		if [ "$$VERBOSE" = "1" ]; then \
			echo "  [VERBOSE] Not using --target flag (tag exists on remote)"; \
			echo "  [VERBOSE] Release files count: $$(echo $$RELEASE_FILES | wc -w)"; \
			echo "  [VERBOSE] Release files:"; \
			for f in $$RELEASE_FILES; do echo "    - $$f"; done; \
			echo "  [VERBOSE] Running: gh release create \"$$VERSION\" --title \"Release $$VERSION\" --notes-file $(RELEASE_DIR)/notes.md $$RELEASE_FILES $(RELEASE_DIR)/manifest.json --prerelease=$$IS_PRERELEASE --latest"; \
		fi; \
		RELEASE_OUTPUT=$$(gh release create "$$VERSION" \
			--title "Release $$VERSION" \
			--notes-file $(RELEASE_DIR)/notes.md \
			$$RELEASE_FILES \
			$(RELEASE_DIR)/manifest.json \
			--prerelease=$$IS_PRERELEASE \
			--latest 2>&1); \
		RELEASE_CODE=$$?; \
		if [ $$RELEASE_CODE -ne 0 ]; then \
			TARGET_FAILED=true; \
			if [ "$$VERBOSE" = "1" ]; then \
				echo "  [VERBOSE] gh release create exit code: $$RELEASE_CODE"; \
				echo "  [VERBOSE] gh release create output:"; \
				echo "$$RELEASE_OUTPUT" | sed 's/^/    /'; \
			fi; \
		else \
			if [ "$$VERBOSE" = "1" ]; then \
				echo "  [VERBOSE] gh release create succeeded"; \
				if [ -n "$$RELEASE_OUTPUT" ]; then \
					echo "  [VERBOSE] gh release create output:"; \
					echo "$$RELEASE_OUTPUT" | sed 's/^/    /'; \
				fi; \
			fi; \
		fi; \
	fi; \
	if [ "$$TARGET_FAILED" = "true" ]; then \
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
	fi; \
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
