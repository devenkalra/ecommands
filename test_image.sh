#!/bin/bash

# Source the main script
source image.bashrc

# Colors for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper function
run_test() {
    local test_name="$1"
    local test_cmd="$2"
    local expected_exit="$3"
    
    ((TESTS_RUN++))
    echo -n "Testing $test_name... "
    
    # Run the command and capture output and exit code
    output=$(eval "$test_cmd" 2>&1)
    exit_code=$?
    
    if [ "$exit_code" -eq "$expected_exit" ]; then
        echo -e "${GREEN}PASSED${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}FAILED${NC}"
        echo "Command: $test_cmd"
        echo "Expected exit code: $expected_exit"
        echo "Got exit code: $exit_code"
        echo "Output: $output"
        ((TESTS_FAILED++))
    fi
}

# Setup test environment
setup_test_env() {
    echo "Setting up test environment..."
    mkdir -p test_files
    # Create test images
    convert -size 100x100 xc:white test_files/test1.jpg
    convert -size 200x200 xc:blue test_files/test2.png
    convert -size 150x150 xc:red test_files/test3.gif
    # Create test video
    ffmpeg -f lavfi -i color=c=red:s=320x240:d=5 test_files/test_video.mp4 2>/dev/null
}

# Cleanup test environment
cleanup_test_env() {
    echo "Cleaning up test environment..."
    rm -rf test_files
}

# Test info command
test_info() {
    echo "Testing info command..."
    run_test "info help" "info -h" 0
    run_test "info single file" "info test_files/test1.jpg" 0
    run_test "info multiple files" "info test_files/test1.jpg test_files/test2.png" 0
    run_test "info nonexistent file" "info nonexistent.jpg" 1
    # First run info to populate IMAGE_INFO_FILES
    info test_files/test1.jpg test_files/test2.png >/dev/null
    run_test "info with number reference" "info 1" 0
}

# Test resize command
test_resize() {
    echo "Testing resize command..."
    run_test "resize help" "resize -h" 0
    run_test "resize with width only" "resize test_files/test1.jpg test_files/resized1.jpg 50" 0
    run_test "resize with width and height" "resize test_files/test1.jpg test_files/resized2.jpg 50 50" 0
    run_test "resize nonexistent file" "resize nonexistent.jpg output.jpg 50" 1
    run_test "resize with invalid arguments" "resize test_files/test1.jpg" 1
    # Test numeric reference
    info test_files/test1.jpg >/dev/null
    run_test "resize with number reference" "resize 1 test_files/resized3.jpg 50" 0
}

# Test convert command
test_convert() {
    echo "Testing convert command..."
    run_test "convert help" "convert -h" 0
    run_test "convert to PNG" "convert test_files/test1.jpg test_files/converted.png png" 0
    run_test "convert to invalid format" "convert test_files/test1.jpg test_files/converted.xyz xyz" 1
    run_test "convert nonexistent file" "convert nonexistent.jpg output.png png" 1
    # Test numeric reference
    info test_files/test1.jpg >/dev/null
    run_test "convert with number reference" "convert 1 test_files/converted2.png png" 0
}

# Test grayscale command
test_grayscale() {
    echo "Testing grayscale command..."
    run_test "grayscale help" "grayscale -h" 0
    run_test "grayscale conversion" "grayscale test_files/test1.jpg test_files/gray1.jpg" 0
    run_test "grayscale nonexistent file" "grayscale nonexistent.jpg output.jpg" 1
    # Test numeric reference
    info test_files/test1.jpg >/dev/null
    run_test "grayscale with number reference" "grayscale 1 test_files/gray2.jpg" 0
}

# Test crop command
test_crop() {
    echo "Testing crop command..."
    run_test "crop help" "crop -h" 0
    run_test "crop image" "crop test_files/test1.jpg test_files/cropped.jpg 50 50 0 0" 0
    run_test "crop with invalid arguments" "crop test_files/test1.jpg test_files/cropped.jpg" 1
    # Test numeric reference
    info test_files/test1.jpg >/dev/null
    run_test "crop with number reference" "crop 1 test_files/cropped2.jpg 50 50 0 0" 0
}

# Test rotate command
test_rotate() {
    echo "Testing rotate command..."
    run_test "rotate help" "rotate -h" 0
    run_test "rotate 90 degrees" "rotate test_files/test1.jpg test_files/rotated.jpg 90" 0
    run_test "rotate with invalid arguments" "rotate test_files/test1.jpg" 1
    # Test numeric reference
    info test_files/test1.jpg >/dev/null
    run_test "rotate with number reference" "rotate 1 test_files/rotated2.jpg 90" 0
}

# Test thumbnail command
test_thumbnail() {
    echo "Testing thumbnail command..."
    run_test "thumbnail help" "thumbnail -h" 0
    run_test "create thumbnail" "thumbnail test_files/test1.jpg test_files/thumb.jpg 50" 0
    run_test "thumbnail with invalid arguments" "thumbnail test_files/test1.jpg" 1
    # Test numeric reference
    info test_files/test1.jpg >/dev/null
    run_test "thumbnail with number reference" "thumbnail 1 test_files/thumb2.jpg 50" 0
}

# Test merge command
test_merge() {
    echo "Testing merge command..."
    run_test "merge help" "merge -h" 0
    run_test "merge images" "merge test_files/test1.jpg test_files/test2.png test_files/merged.jpg" 0
    run_test "merge with invalid arguments" "merge test_files/test1.jpg" 1
    # Test numeric references
    info test_files/test1.jpg test_files/test2.png >/dev/null
    run_test "merge with number references" "merge 1 2 test_files/merged2.jpg" 0
}

# Test watermark command
test_watermark() {
    echo "Testing watermark command..."
    run_test "watermark help" "watermark -h" 0
    run_test "add watermark" "watermark test_files/test1.jpg test_files/watermarked.jpg 'Test'" 0
    run_test "watermark with invalid arguments" "watermark test_files/test1.jpg" 1
    # Test numeric reference
    info test_files/test1.jpg >/dev/null
    run_test "watermark with number reference" "watermark 1 test_files/watermarked2.jpg 'Test'" 0
}

# Test optimize command
test_optimize() {
    echo "Testing optimize command..."
    run_test "optimize help" "optimize -h" 0
    run_test "optimize image" "optimize test_files/test1.jpg test_files/optimized.jpg" 0
    run_test "optimize with invalid arguments" "optimize test_files/test1.jpg" 1
    # Test numeric reference
    info test_files/test1.jpg >/dev/null
    run_test "optimize with number reference" "optimize 1 test_files/optimized2.jpg" 0
}

# Test display command
test_display() {
    echo "Testing display command..."
    run_test "display help" "display -h" 0
    # Note: We can't actually test display as it opens a window
    run_test "display with invalid arguments" "display" 1
    # Test numeric reference
    info test_files/test1.jpg >/dev/null
    run_test "display with number reference" "display 1" 0
}

# Test collage command
test_collage() {
    echo "Testing collage command..."
    run_test "collage help" "collage -h" 0
    run_test "create collage" "collage test_files/collage.jpg 2x2 test_files/test1.jpg test_files/test2.png test_files/test3.gif test_files/test1.jpg" 0
    run_test "collage with invalid arguments" "collage test_files/collage.jpg" 1
    # Test numeric references
    info test_files/test1.jpg test_files/test2.png test_files/test3.gif >/dev/null
    run_test "collage with number references" "collage test_files/collage2.jpg 2x2 1 2 3 1" 0
}

# Test text command
test_text() {
    echo "Testing text command..."
    run_test "text help" "text -h" 0
    run_test "add text" "text test_files/test1.jpg test_files/text.jpg 'Test Text'" 0
    run_test "add text with position" "text test_files/test1.jpg test_files/text2.jpg 'Test Text' center" 0
    run_test "text with invalid arguments" "text test_files/test1.jpg" 1
    # Test numeric reference
    info test_files/test1.jpg >/dev/null
    run_test "text with number reference" "text 1 test_files/text3.jpg 'Test Text'" 0
}

# Test gif command
test_gif() {
    echo "Testing gif command..."
    run_test "gif help" "gif -h" 0
    run_test "create gif" "gif test_files/animated.gif 10 test_files/test1.jpg test_files/test2.png test_files/test3.gif" 0
    run_test "gif with invalid arguments" "gif test_files/animated.gif" 1
    # Test numeric references
    info test_files/test1.jpg test_files/test2.png test_files/test3.gif >/dev/null
    run_test "gif with number references" "gif test_files/animated2.gif 10 1 2 3" 0
}

# Test frames command
test_frames() {
    echo "Testing frames command..."
    run_test "frames help" "frames -h" 0
    run_test "extract frames" "frames test_files/test_video.mp4 test_files/frames/" 0
    run_test "frames with invalid arguments" "frames test_files/test_video.mp4" 1
}

# Test batch command
test_batch() {
    echo "Testing batch command..."
    run_test "batch help" "batch -h" 0
    mkdir -p test_files/batch_input test_files/batch_output
    cp test_files/test1.jpg test_files/batch_input/
    cp test_files/test2.png test_files/batch_input/
    run_test "batch process" "batch test_files/batch_input test_files/batch_output resize 50" 0
    run_test "batch with invalid arguments" "batch test_files/batch_input" 1
}

# Test help command
test_help() {
    echo "Testing help command..."
    run_test "help with no arguments" "help" 0
    run_test "help with search term" "help resize" 0
}

# Test about command
test_about() {
    echo "Testing about command..."
    run_test "about command" "about" 0
    run_test "about help" "about -h" 0
}

# Run all tests
run_all_tests() {
    setup_test_env
    
    test_info
    test_resize
    test_convert
    test_grayscale
    test_crop
    test_rotate
    test_thumbnail
    test_merge
    test_watermark
    test_optimize
    test_display
    test_collage
    test_text
    test_gif
    test_frames
    test_batch
    test_help
    test_about
    
    cleanup_test_env
    
    # Print summary
    echo ""
    echo "Test Summary:"
    echo "============="
    echo "Total tests: $TESTS_RUN"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    
    # Return non-zero if any tests failed
    [ "$TESTS_FAILED" -eq 0 ]
}

# Run the tests
run_all_tests 