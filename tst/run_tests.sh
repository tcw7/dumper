#!/bin/bash

# Test suite for the dump script
SCRIPT="../dump"
TEST_DIR="test-data"
FAILED=0
TOTAL=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

setup() {
    echo "🔧 Setting up test environment..."
    mkdir -p "$TEST_DIR/subdir"
    echo "Hello world" > "$TEST_DIR/test.txt"
    echo "Python code" > "$TEST_DIR/script.py"
    echo "Shell script" > "$TEST_DIR/run.sh"
    echo "Nested file" > "$TEST_DIR/subdir/nested.txt"
    echo -e "\x89PNG" > "$TEST_DIR/binary.png"  # Binary file
}

cleanup() {
    echo "🧹 Cleaning up..."
    rm -rf "$TEST_DIR" dump.txt test-* final-test hybrid-test mini-test
    rm -f custom-output.txt filtered-output.txt multi-filtered.txt test-data-output.txt
}

run_test() {
    local test_name="$1"
    local test_cmd="$2"
    local expected_exit="$3"
    
    ((TOTAL++))
    echo -e "\n${YELLOW}Test $TOTAL: $test_name${NC}"
    
    # Run the command and capture output
    output=$(eval "$test_cmd" 2>&1)
    exit_code=$?
    
    if [[ $exit_code -eq $expected_exit ]]; then
        echo -e "${GREEN}✓ PASS${NC}"
        [[ -n "$output" ]] && echo "$output" | head -5
    else
        echo -e "${RED}✗ FAIL${NC} (exit code: $exit_code, expected: $expected_exit)"
        echo "$output"
        ((FAILED++))
    fi
}

verify_file() {
    local file="$1"
    local expected_lines="$2"
    local test_name="$3"
    
    ((TOTAL++))
    echo -e "\n${YELLOW}Test $TOTAL: $test_name${NC}"
    
    if [[ -f "$file" ]]; then
        lines=$(wc -l < "$file")
        if [[ $lines -ge $expected_lines ]]; then
            echo -e "${GREEN}✓ PASS${NC} ($lines lines, expected >= $expected_lines)"
        else
            echo -e "${RED}✗ FAIL${NC} ($lines lines, expected >= $expected_lines)"
            ((FAILED++))
        fi
    else
        echo -e "${RED}✗ FAIL${NC} (file not created)"
        ((FAILED++))
    fi
}

echo "🧪 Running dump script test suite..."

# Ensure cleanup happens on exit (including interrupts)
trap cleanup EXIT

# Setup test environment
setup

echo -e "\n${YELLOW}=== Basic Functionality Tests ===${NC}"

# Test 1: Help display (no args)
run_test "Help display (no args)" "$SCRIPT" 0

# Test 2: Help display (-h flag)
run_test "Help display (-h)" "$SCRIPT -h" 0

# Test 3: Error handling (non-existent directory)
run_test "Non-existent directory" "$SCRIPT /nonexistent" 1

# Test 4: Basic dump (current directory)
run_test "Basic dump current directory" "$SCRIPT ." 0
verify_file "dump.txt" 10 "Output file created with content"

# Test 5: Custom output filename
run_test "Custom output filename" "$SCRIPT . custom-output.txt" 0
verify_file "custom-output.txt" 10 "Custom output file created"

# Test 6: File type filtering
run_test "Filter .txt files only" "$SCRIPT $TEST_DIR filtered-output.txt .txt" 0
verify_file "filtered-output.txt" 5 "Filtered output contains text files"

# Test 7: Multiple file type filtering
run_test "Filter multiple file types" "$SCRIPT $TEST_DIR multi-filtered.txt .txt .py" 0
verify_file "multi-filtered.txt" 8 "Multi-type filtered output"

# Test 8: Test with test data directory
run_test "Test data directory processing" "$SCRIPT $TEST_DIR test-data-output.txt" 0
verify_file "test-data-output.txt" 3 "Test data processed correctly"

echo -e "\n${YELLOW}=== Content Verification Tests ===${NC}"

# Test 9: Verify file headers are present
((TOTAL++))
echo -e "\n${YELLOW}Test $TOTAL: File headers present${NC}"
if grep -q "^--- .* ---$" dump.txt 2>/dev/null; then
    echo -e "${GREEN}✓ PASS${NC} (File headers found)"
else
    echo -e "${RED}✗ FAIL${NC} (No file headers found)"
    ((FAILED++))
fi

# Test 10: Verify file footers are present
((TOTAL++))
echo -e "\n${YELLOW}Test $TOTAL: File footers present${NC}"
if grep -q "^--- End of .* ---$" dump.txt 2>/dev/null; then
    echo -e "${GREEN}✓ PASS${NC} (File footers found)"
else
    echo -e "${RED}✗ FAIL${NC} (No file footers found)"
    ((FAILED++))
fi

# Cleanup
cleanup

# Summary
echo -e "\n${YELLOW}=== Test Summary ===${NC}"
PASSED=$((TOTAL - FAILED))
echo "Total tests: $TOTAL"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"

if [[ $FAILED -eq 0 ]]; then
    echo -e "\n🎉 ${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "\n💥 ${RED}Some tests failed!${NC}"
    exit 1
fi