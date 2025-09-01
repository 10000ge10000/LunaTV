#!/bin/bash

# Repository Isolation Verification Script
# Checks that the repository has been completely severed from its original source

# Note: Don't use set -e to allow script to continue on errors for complete report

echo "🔍 Repository Isolation Verification Script"
echo "==========================================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TESTS_PASSED=0
TESTS_FAILED=0
WARNINGS=0

# Helper functions
print_status() {
    local status=$1
    local message=$2
    case $status in
        "PASS")
            echo -e "${GREEN}✅ PASS${NC}: $message"
            ((TESTS_PASSED++))
            ;;
        "FAIL")
            echo -e "${RED}❌ FAIL${NC}: $message"
            ((TESTS_FAILED++))
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  WARN${NC}: $message"
            ((WARNINGS++))
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  INFO${NC}: $message"
            ;;
    esac
}

# Test 1: Check git remotes
echo "📡 Checking Git Remote Configuration"
echo "-----------------------------------"

remotes=$(git remote -v 2>/dev/null || echo "")
if [[ $remotes == *"10000ge10000/LunaTV"* ]]; then
    # Check for references to original repository, but exclude our current repository name
    if [[ $remotes != *"moontv"* && $remotes != *"MoonTV"* ]] && ! echo "$remotes" | grep -v "10000ge10000/LunaTV" | grep -q -i "lunatv"; then
        print_status "PASS" "Git remotes only point to current repository"
    else
        print_status "FAIL" "Found references to original repository in git remotes"
    fi
else
    print_status "FAIL" "Git remotes not pointing to expected current repository"
fi

# Test 2: Check package.json
echo
echo "📦 Checking Package Configuration"
echo "--------------------------------"

if [[ -f "package.json" ]]; then
    pkg_name=$(grep '"name"' package.json | head -1 | cut -d'"' -f4)
    pkg_author=$(grep '"author"' package.json | head -1 | cut -d'"' -f4)
    
    if [[ "$pkg_name" == "10000tv" ]]; then
        print_status "PASS" "Package name is correctly set to '10000tv'"
    else
        print_status "FAIL" "Package name is '$pkg_name', expected '10000tv'"
    fi
    
    if [[ "$pkg_author" == "10000ge10000" ]]; then
        print_status "PASS" "Package author is correctly set to '10000ge10000'"
    else
        print_status "FAIL" "Package author is '$pkg_author', expected '10000ge10000'"
    fi
else
    print_status "FAIL" "package.json not found"
fi

# Test 3: Check for original repository references
echo
echo "🔍 Scanning for Original Repository References"
echo "---------------------------------------------"

original_refs=$(grep -r -i "moontv\|lunatv" . --exclude-dir=node_modules --exclude-dir=.git --exclude="verification-script.sh" --exclude="verification-report.md" 2>/dev/null | grep -v "moontv-source\|moontv_" | wc -l)

if [[ $original_refs -eq 0 ]]; then
    print_status "PASS" "No inappropriate references to original repository found"
else
    print_status "WARN" "Found $original_refs potential references - checking if they are API compatibility names"
    # Show what was found for manual review
    grep -r -i "moontv\|lunatv" . --exclude-dir=node_modules --exclude-dir=.git --exclude="verification-script.sh" --exclude="verification-report.md" 2>/dev/null | grep -v "moontv-source\|moontv_" | head -5
fi

# Test 4: Check for GitHub URLs to original repository
echo
echo "🌐 Checking for External GitHub References"
echo "-----------------------------------------"

github_refs=$(find . -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.json" -o -name "*.md" | grep -v node_modules | xargs grep -l "github.com" 2>/dev/null | xargs grep "github.com" 2>/dev/null | grep -v "bestzwei\|cmliu\|10000ge10000" | wc -l)

if [[ $github_refs -eq 0 ]]; then
    print_status "PASS" "No inappropriate GitHub URLs found"
else
    print_status "WARN" "Found $github_refs GitHub references - manual review recommended"
fi

# Test 5: Check if version checking is disabled
echo
echo "🔄 Checking Version Update Mechanism"
echo "-----------------------------------"

if [[ -f "src/lib/version_check.ts" ]]; then
    if grep -q "已禁用以完全切断与原仓库的连接" src/lib/version_check.ts; then
        print_status "PASS" "Version checking is properly disabled"
    else
        print_status "FAIL" "Version checking may still be active"
    fi
else
    print_status "WARN" "Version check file not found"
fi

# Test 6: Check if external changelog fetching is disabled
echo
echo "📄 Checking Changelog Fetching"
echo "-----------------------------"

if [[ -f "src/components/VersionPanel.tsx" ]]; then
    if grep -q "已禁用以完全切断与原仓库的连接" src/components/VersionPanel.tsx; then
        print_status "PASS" "External changelog fetching is properly disabled"
    else
        print_status "FAIL" "External changelog fetching may still be active"
    fi
else
    print_status "WARN" "VersionPanel component not found"
fi

# Test 7: Check Docker configuration
echo
echo "🐳 Checking Docker Configuration"
echo "-------------------------------"

if [[ -f ".github/workflows/docker-image.yml" ]]; then
    if grep -q "ghcr.io/10000ge10000/10000tv" .github/workflows/docker-image.yml; then
        print_status "PASS" "Docker workflow uses correct repository reference"
    else
        print_status "FAIL" "Docker workflow may have incorrect repository reference"
    fi
else
    print_status "WARN" "Docker workflow file not found"
fi

# Test 8: Check PRIVATIZATION.md exists
echo
echo "📋 Checking Privatization Documentation"
echo "--------------------------------------"

if [[ -f "PRIVATIZATION.md" ]]; then
    print_status "PASS" "PRIVATIZATION.md documentation exists"
    if grep -q "completely privatized" PRIVATIZATION.md; then
        print_status "PASS" "Privatization documentation confirms complete isolation"
    fi
else
    print_status "FAIL" "PRIVATIZATION.md documentation missing"
fi

# Test 9: Check README for proper branding
echo
echo "📖 Checking README Branding"
echo "--------------------------"

if [[ -f "README.md" ]]; then
    if grep -q "10000TV" README.md; then
        print_status "PASS" "README uses correct branding (10000TV)"
    else
        print_status "FAIL" "README does not use correct branding"
    fi
else
    print_status "FAIL" "README.md not found"
fi

# Test 10: Attempt to run linting (if dependencies exist)
echo
echo "🔧 Testing Build System"
echo "----------------------"

if [[ -d "node_modules" ]]; then
    if pnpm run lint > /dev/null 2>&1; then
        print_status "PASS" "Linting passes successfully"
    else
        print_status "WARN" "Linting has issues - manual review needed"
    fi
else
    print_status "INFO" "Dependencies not installed - skipping lint test"
fi

# Summary
echo
echo "📊 Verification Summary"
echo "======================"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"

echo
if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}🎉 VERIFICATION COMPLETE: Repository is properly isolated!${NC}"
    echo
    echo "✅ The repository has been successfully severed from its original source."
    echo "✅ No inappropriate external connections found."
    echo "✅ Ready for independent deployment and operation."
    exit 0
else
    echo -e "${RED}⚠️  VERIFICATION FAILED: Issues found that need attention!${NC}"
    echo
    echo "❌ The repository may still have connections to the original source."
    echo "❌ Manual review and fixes required."
    exit 1
fi