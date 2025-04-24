#!/bin/bash

# Test suite for filemanager.bashrc

# Load the filemanager commands
source filemanager.bashrc

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test directories
TEST_DIR="test_dir"
TEST_SRC_DIR="$TEST_DIR/src"
TEST_DEST_DIR="$TEST_DIR/dest"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test helper functions
setup() {
    mkdir -p "$TEST_SRC_DIR"
    mkdir -p "$TEST_DEST_DIR"
    # Create test files
    echo "test1" > "$TEST_SRC_DIR/file1.txt"
    echo "test2" > "$TEST_SRC_DIR/file2.txt"
    echo "test3" > "$TEST_SRC_DIR/file3.txt"
    mkdir -p "$TEST_SRC_DIR/subdir"
    echo "test4" > "$TEST_SRC_DIR/subdir/file4.txt"
}

cleanup() {
    rm -rf "$TEST_DIR"
}

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    local ignore_output="${4:-false}"
    local expect_error="${5:-false}"
    
    ((TESTS_RUN++))
    echo -e "${YELLOW}Running test: $test_name${NC}"
    
    # Run the test command
    local result
    if [ "$ignore_output" = true ]; then
        # For commands where we don't care about the output, just check exit code
        eval "$test_command" >/dev/null 2>&1
        local exit_code=$?
        if [ "$expect_error" = true ]; then
            # We expect an error (non-zero exit code)
            if [ $exit_code -ne 0 ]; then
                echo -e "${GREEN}PASSED: $test_name${NC}"
                ((TESTS_PASSED++))
            else
                echo -e "${RED}FAILED: $test_name${NC}"
                echo "Expected error but command succeeded"
                ((TESTS_FAILED++))
            fi
        else
            # We expect success (zero exit code)
            if [ $exit_code -eq 0 ]; then
                echo -e "${GREEN}PASSED: $test_name${NC}"
                ((TESTS_PASSED++))
            else
                echo -e "${RED}FAILED: $test_name${NC}"
                echo "Command failed with exit code: $exit_code"
                ((TESTS_FAILED++))
            fi
        fi
    else
        # For commands where we care about the output
        result=$(eval "$test_command" 2>&1)
        local exit_code=$?
        
        # Check if the test passed
        if [[ "$result" == *"$expected_result"* ]] && [ $exit_code -eq 0 ]; then
            echo -e "${GREEN}PASSED: $test_name${NC}"
            ((TESTS_PASSED++))
        else
            echo -e "${RED}FAILED: $test_name${NC}"
            echo "Expected: $expected_result"
            echo "Got: $result"
            ((TESTS_FAILED++))
        fi
    fi
}

# Test summary
print_summary() {
    echo -e "\nTest Summary:"
    echo "============="
    echo -e "Total tests: $TESTS_RUN"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
}

# Main test execution
main() {
    echo "Starting filemanager.bashrc tests..."
    
    # Setup test environment
    setup
    
    # Test check_file function
    run_test "check_file with existing file" \
        "check_file '$TEST_SRC_DIR/file1.txt'" \
        ""
    
    run_test "check_file with non-existent file" \
        "check_file '$TEST_SRC_DIR/nonexistent.txt'" \
        "" \
        true \
        true
    
    # Test check_dir function
    run_test "check_dir with existing directory" \
        "check_dir '$TEST_SRC_DIR'" \
        ""
    
    run_test "check_dir with non-existent directory" \
        "check_dir '$TEST_SRC_DIR/nonexistent'" \
        "" \
        true \
        true
    
    # Reset test environment for list tests
    setup
    
    # Test list command
    run_test "list command basic functionality" \
        "list '$TEST_SRC_DIR' | grep -c 'file1.txt'" \
        "1"
    
    run_test "list command with pattern" \
        "list -p '*.txt' '$TEST_SRC_DIR' | grep -c 'file1.txt'" \
        "1"
    
    # Reset test environment for copy/move tests
    setup
    
    # Test copy command
    run_test "copy command" \
        "copy '$TEST_SRC_DIR/file1.txt' '$TEST_DEST_DIR/' && [ -f '$TEST_DEST_DIR/file1.txt' ]" \
        "" \
        true
    
    # Test move command
    run_test "move command" \
        "move '$TEST_SRC_DIR/file2.txt' '$TEST_DEST_DIR/' 2>/dev/null && [ ! -f '$TEST_SRC_DIR/file2.txt' ] && [ -f '$TEST_DEST_DIR/file2.txt' ]" \
        "" \
        true
    
    # Reset test environment for rename tests
    setup
    
    # Test rename command
    run_test "rename command" \
        "rename 'file' 'new_' '$TEST_SRC_DIR' && [ -f '$TEST_SRC_DIR/new_3.txt' ]" \
        "" \
        true
    
    # Reset test environment for backup tests
    setup
    
    # Test backup command
    run_test "backup command" \
        "backup '$TEST_SRC_DIR/file3.txt' 2>/dev/null && backup_file=\$(ls -1 '$TEST_DEST_DIR' | grep 'file3.txt_') && echo \"Backup file: \$backup_file\" && [ -f \"$TEST_DEST_DIR/\$backup_file\" ]" \
        "Backup file:" \
        false
    
    # Reset test environment for organize tests
    setup
    
    # Test organize command
    run_test "organize command" \
        "organize '$TEST_SRC_DIR' && [ -d '$TEST_SRC_DIR/txt' ]" \
        "" \
        true
    
    # Reset test environment for date_move tests
    setup
    
    # Test date_move command
    run_test "date_move command dry run" \
        "date_move -n '*.txt' '$TEST_DEST_DIR'" \
        "Would move:"
    
    # Reset test environment for exif_move tests
    setup
    
    # Test exif_move command
    run_test "exif_move command dry run" \
        "exif_move -n '*.txt' '$TEST_DEST_DIR'" \
        "Would move:"
    
    # Reset test environment for find_duplicates tests
    setup
    
    # Test find_duplicates command
    run_test "find_duplicates command" \
        "cp '$TEST_SRC_DIR/file3.txt' '$TEST_SRC_DIR/duplicate.txt' && find_duplicates '$TEST_SRC_DIR' | grep -q 'duplicate.txt'" \
        "" \
        true
    
    # Reset test environment for clean_empty tests
    setup
    
    # Test clean_empty command
    run_test "clean_empty command" \
        "mkdir -p '$TEST_SRC_DIR/empty' && clean_empty '$TEST_SRC_DIR' && [ ! -d '$TEST_SRC_DIR/empty' ]" \
        "" \
        true
    
    # Reset test environment for file_info tests
    setup
    
    # Test file_info command
    run_test "file_info command" \
        "file_info '$TEST_SRC_DIR/file3.txt' | grep -q 'File:'" \
        "" \
        true
    
    # Reset test environment for info tests
    setup
    
    # Test info command
    run_test "info command" \
        "info '$TEST_SRC_DIR' | grep -q 'Directory:'" \
        "" \
        true
    
    # Cleanup
    cleanup
    
    # Print summary
    print_summary
    
    # Exit with appropriate status
    if [ $TESTS_FAILED -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run the tests
main 