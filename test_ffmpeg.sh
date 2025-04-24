#!/bin/bash

# Source the ffmpeg functions
source ffmpeg.bashrc

# Colors for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to run a test
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_exit="$3"
    
    echo -n "Running test: $test_name... "
    ((TESTS_RUN++))
    
    # Run the command and capture output and exit code
    local output
    output=$(eval "$command" 2>&1)
    local exit_code=$?
    
    if [ "$exit_code" -eq "$expected_exit" ]; then
        echo -e "${GREEN}PASSED${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}FAILED${NC}"
        echo "Command: $command"
        echo "Expected exit code: $expected_exit"
        echo "Actual exit code: $exit_code"
        echo "Output:"
        echo "$output"
        ((TESTS_FAILED++))
    fi
}

# Setup test environment
setup_test_env() {
    echo "Setting up test environment..."
    mkdir -p test_files
    
    # Create test video files with audio
    ffmpeg -f lavfi -i testsrc=duration=10:size=1280x720:rate=30 -f lavfi -i anullsrc=r=44100:cl=mono -t 10 -c:v libx264 -c:a aac -strict experimental test_files/test1.mp4
    ffmpeg -f lavfi -i testsrc=duration=5:size=640x480:rate=30 -f lavfi -i anullsrc=r=44100:cl=mono -t 5 -c:v libx264 -c:a aac -strict experimental test_files/test2.mp4
    
    # Create test watermark image with transparency
    convert -size 100x100 xc:none -pointsize 20 -fill white -draw "text 10,50 'Test'" -alpha on test_files/watermark.png
    
    # Initialize VIDEO_INFO_FILES array
    VIDEO_INFO_FILES=()
}

# Cleanup test environment
cleanup_test_env() {
    echo "Cleaning up test environment..."
    rm -rf test_files
    unset VIDEO_INFO_FILES
}

# Test info command
test_info() {
    echo "Testing info command..."
    
    # Test help
    run_test "info help" "info -h" 0
    
    # Test with non-existent file
    run_test "info non-existent" "info non_existent.mp4" 1
    
    # Test with single file
    run_test "info single file" "info test_files/test1.mp4" 0
    
    # Test with multiple files
    run_test "info multiple files" "info test_files/test1.mp4 test_files/test2.mp4" 0
    
    # Test with numeric reference (after running info on files)
    info test_files/test1.mp4 test_files/test2.mp4 > /dev/null
    run_test "info numeric reference" "info 1" 0
}

# Test convert command
test_convert() {
    echo "Testing convert command..."
    
    # Test help
    run_test "convert help" "convert -h" 0
    
    # Test with non-existent file
    run_test "convert non-existent" "convert non_existent.mp4 output.mkv mkv" 1
    
    # Test with invalid format (using a valid container but unsupported codec)
    run_test "convert invalid format" "convert test_files/test1.mp4 output.avi avi" 1
    
    # Test valid conversion
    run_test "convert mp4 to mkv" "convert test_files/test1.mp4 test_files/output.mkv mkv" 0
}

# Test extract_audio command
test_extract_audio() {
    echo "Testing extract_audio command..."
    
    # Test help
    run_test "extract_audio help" "extract_audio -h" 0
    
    # Test with non-existent file
    run_test "extract_audio non-existent" "extract_audio non_existent.mp4 output.mp3 mp3" 1
    
    # Test with default format
    run_test "extract_audio default format" "extract_audio test_files/test1.mp4 test_files/audio.mp3" 0
    
    # Test with specified format
    run_test "extract_audio specified format" "extract_audio test_files/test1.mp4 test_files/audio2.mp3 mp3" 0
}

# Test trim command
test_trim() {
    echo "Testing trim command..."
    
    # Test help
    run_test "trim help" "trim -h" 0
    
    # Test with non-existent file
    run_test "trim non-existent" "trim non_existent.mp4 output.mp4 0 5" 1
    
    # Test with invalid time format
    run_test "trim invalid time" "trim test_files/test1.mp4 test_files/trimmed.mp4 invalid 5" 1
    
    # Test valid trim
    run_test "trim valid" "trim test_files/test1.mp4 test_files/trimmed.mp4 0 5" 0
}

# Test resize command
test_resize() {
    echo "Testing resize command..."
    
    # Test help
    run_test "resize help" "resize -h" 0
    
    # Test with non-existent file
    run_test "resize non-existent" "resize non_existent.mp4 output.mp4 640 480" 1
    
    # Test with width only
    run_test "resize width only" "resize test_files/test1.mp4 test_files/resized1.mp4 640" 0
    
    # Test with width and height
    run_test "resize width and height" "resize test_files/test1.mp4 test_files/resized2.mp4 640 480" 0
}

# Test speed command
test_speed() {
    echo "Testing speed command..."
    
    # Test help
    run_test "speed help" "speed -h" 0
    
    # Test with non-existent file
    run_test "speed non-existent" "speed non_existent.mp4 output.mp4 2.0" 1
    
    # Test with invalid speed factor
    run_test "speed invalid factor" "speed test_files/test1.mp4 test_files/speed.mp4 0" 1
    
    # Test valid speed change
    run_test "speed valid" "speed test_files/test1.mp4 test_files/speed.mp4 2.0" 0
}

# Test watermark command
test_watermark() {
    echo "Testing watermark command..."
    
    # Test help
    run_test "watermark help" "watermark -h" 0
    
    # Test with non-existent video
    run_test "watermark non-existent video" "watermark non_existent.mp4 output.mp4 test_files/watermark.png" 1
    
    # Test with non-existent watermark
    run_test "watermark non-existent watermark" "watermark test_files/test1.mp4 output.mp4 non_existent.png" 1
    
    # Test with default position
    run_test "watermark default position" "watermark test_files/test1.mp4 test_files/watermarked1.mp4 test_files/watermark.png" 0
    
    # Test with specified position
    run_test "watermark specified position" "watermark test_files/test1.mp4 test_files/watermarked2.mp4 test_files/watermark.png top-left" 0
}

# Test frames command
test_frames() {
    echo "Testing frames command..."
    
    # Test help
    run_test "frames help" "frames -h" 0
    
    # Test with non-existent file
    run_test "frames non-existent" "frames non_existent.mp4 test_files/frames" 1
    
    # Test with default frame rate
    run_test "frames default rate" "frames test_files/test1.mp4 test_files/frames1" 0
    
    # Test with specified frame rate
    run_test "frames specified rate" "frames test_files/test1.mp4 test_files/frames2 2" 0
    
    # Wait for frames to be extracted
    sleep 2
}

# Test create_video command
test_create_video() {
    echo "Testing create_video command..."
    
    # Test help
    run_test "create_video help" "create_video -h" 0
    
    # Test with non-existent pattern
    run_test "create_video non-existent pattern" "create_video non_existent/frame_%04d.png output.mp4 30" 1
    
    # Test with invalid frame rate
    run_test "create_video invalid frame rate" "create_video test_files/frames1/frame_%04d.png output.mp4 0" 1
    
    # Test valid creation (only if frames were extracted)
    if [ -d "test_files/frames1" ] && [ "$(ls -1 test_files/frames1 | wc -l)" -gt 0 ]; then
        run_test "create_video valid" "create_video test_files/frames1/frame_%04d.png test_files/created.mp4 30" 0
    else
        echo "Skipping create_video valid test - no frames available"
    fi
}

# Test concat command
test_concat() {
    echo "Testing concat command..."
    
    # Test help
    run_test "concat help" "concat -h" 0
    
    # Test with non-existent input file
    run_test "concat non-existent" "concat test_files/output.mp4 non_existent.mp4 test_files/test2.mp4" 1
    
    # Test with multiple files
    run_test "concat multiple files" "concat test_files/concatenated.mp4 test_files/test1.mp4 test_files/test2.mp4" 0
    
    # Test with same file twice (effectively testing single file concatenation)
    run_test "concat same file twice" "concat test_files/concatenated2.mp4 test_files/test1.mp4 test_files/test1.mp4" 0
}

# Test help command
test_help() {
    echo "Testing help command..."
    
    # Test basic help
    run_test "help basic" "help" 0
    
    # Test search help
    run_test "help search" "help info" 0
}

# Test commands command
test_commands() {
    echo "Testing commands command..."
    
    # Test basic commands
    run_test "commands basic" "commands" 0
    
    # Test commands help
    run_test "commands help" "commands -h" 0
}

# Test about command
test_about() {
    echo "Testing about command..."
    
    # Test basic about
    run_test "about basic" "about" 0
    
    # Test about help
    run_test "about help" "about -h" 0
}

# Run all tests
run_all_tests() {
    setup_test_env
    
    test_info
    test_convert
    test_extract_audio
    test_trim
    test_resize
    test_speed
    test_watermark
    test_frames
    test_create_video
    test_concat
    test_help
    test_commands
    test_about
    
    cleanup_test_env
    
    echo ""
    echo "Test Summary:"
    echo "Total tests run: $TESTS_RUN"
    echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
    
    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed.${NC}"
        return 1
    fi
}

# Run the tests
run_all_tests 