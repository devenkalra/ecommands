#!/bin/bash

# Helper function to validate input file
validate_input_file() {
    if [ ! -f "$1" ]; then
        echo "Error: Input file '$1' does not exist"
        return 1
    fi
    return 0
}

# Helper function to validate output directory
validate_output_dir() {
    local output_dir=$(dirname "$1")
    if [ ! -d "$output_dir" ]; then
        mkdir -p "$output_dir"
    fi
}

# Helper function to resolve file references
resolve_file_reference() {
    local reference="$1"
    if [[ "$reference" =~ ^[0-9]+$ ]] && [ -n "${VIDEO_INFO_FILES[*]}" ]; then
        if [ "$reference" -gt 0 ] && [ "$reference" -le "${#VIDEO_INFO_FILES[@]}" ]; then
            echo "${VIDEO_INFO_FILES[$((reference-1))]}"
            return 0
        else
            echo "Error: Invalid file number. Please use a number between 1 and ${#VIDEO_INFO_FILES[@]}"
            return 1
        fi
    fi
    echo "$reference"
}

# Helper function to format size in MB
format_size() {
    local size="$1"
    if [ ${#size} -gt 8 ]; then
        # Convert to MB with 2 decimal places
        local mb=$(echo "scale=2; $size/1024/1024" | bc)
        echo "${mb}M"
    else
        echo "$size"
    fi
}

# Helper function to format numbers with commas
format_number() {
    local num="$1"
    echo "$num" | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'
}

# Get video information
info() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m info <input_file> [input_file2 ...]"
        echo "    Displays detailed information about one or more videos."
        echo "    For single file: Shows comprehensive details"
        echo "    For multiple files: Shows summarized information in tabular form"
        echo "    Serial numbers can be used to reference files in subsequent commands"
        return 0
    fi
    if [ "$#" -lt 1 ]; then
        echo "Usage: info <input_file> [input_file2 ...]"
        return 1
    fi

    # If first argument is a number and we have stored files
    if [[ "$1" =~ ^[0-9]+$ ]] && [ -n "${VIDEO_INFO_FILES[*]}" ]; then
        if [ "$1" -gt 0 ] && [ "$1" -le "${#VIDEO_INFO_FILES[@]}" ]; then
            # Show detailed info for the referenced file
            local file="${VIDEO_INFO_FILES[$((1-1))]}"
            validate_input_file "$file" || return 1
            
            echo -e "\e[1mVideo Information for:\e[0m $file"
            echo "========================================="
            echo ""

            # Get basic video information
            local info=$(ffprobe -v quiet -print_format json -show_format -show_streams "$file")
            
            # Format information
            echo -e "\e[1mFormat:\e[0m"
            echo "    Format: $(echo "$info" | jq -r '.format.format_name')"
            local duration=$(echo "$info" | jq -r '.format.duration')
            printf "    Duration: %.2f seconds\n" "$duration"
            local size=$(echo "$info" | jq -r '.format.size')
            echo "    Size: $(format_number "$size") bytes"
            local bitrate=$(echo "$info" | jq -r '.format.bit_rate')
            echo "    Bitrate: $(format_number "$bitrate") b/s"
            echo ""

            # Video stream information
            echo -e "\e[1mVideo Stream:\e[0m"
            local video_stream=$(echo "$info" | jq -r '.streams[] | select(.codec_type=="video")')
            local width=$(echo "$video_stream" | jq -r '.width')
            local height=$(echo "$video_stream" | jq -r '.height')
            local resolution="${width}x${height}"
            echo "    Codec: $(echo "$video_stream" | jq -r '.codec_name')"
            echo "    Resolution: $resolution"
            echo "    Display Aspect Ratio: $(echo "$video_stream" | jq -r '.display_aspect_ratio')"
            echo "    Frame rate: $(echo "$video_stream" | jq -r '.r_frame_rate')"
            local video_bitrate=$(echo "$video_stream" | jq -r '.bit_rate')
            echo "    Bitrate: $(format_number "$video_bitrate") b/s"
            echo ""

            # Audio stream information
            echo -e "\e[1mAudio Stream:\e[0m"
            local audio_stream=$(echo "$info" | jq -r '.streams[] | select(.codec_type=="audio")')
            echo "    Codec: $(echo "$audio_stream" | jq -r '.codec_name')"
            echo "    Channels: $(echo "$audio_stream" | jq -r '.channels')"
            echo "    Sample rate: $(echo "$audio_stream" | jq -r '.sample_rate') Hz"
            local audio_bitrate=$(echo "$audio_stream" | jq -r '.bit_rate')
            echo "    Bitrate: $(format_number "$audio_bitrate") b/s"
            return 0
        else
            echo "Error: Invalid file number. Please use a number between 1 and ${#VIDEO_INFO_FILES[@]}"
            return 1
        fi
    fi

    # Validate all input files
    for file in "$@"; do
        validate_input_file "$file" || return 1
    done

    # If only one file, show detailed info
    if [ "$#" -eq 1 ]; then
        # Store the file in the global list for future reference
        declare -g VIDEO_INFO_FILES=("$1")
        
        echo -e "\e[1mVideo Information for:\e[0m $1"
        echo "========================================="
        echo ""

        # Get basic video information
        local info=$(ffprobe -v quiet -print_format json -show_format -show_streams "$1")
        
        # Format information
        echo -e "\e[1mFormat:\e[0m"
        echo "    Format: $(echo "$info" | jq -r '.format.format_name')"
        local duration=$(echo "$info" | jq -r '.format.duration')
        printf "    Duration: %.2f seconds\n" "$duration"
        local size=$(echo "$info" | jq -r '.format.size')
        echo "    Size: $(format_number "$size") bytes"
        local bitrate=$(echo "$info" | jq -r '.format.bit_rate')
        echo "    Bitrate: $(format_number "$bitrate") b/s"
        echo ""

        # Video stream information
        echo -e "\e[1mVideo Stream:\e[0m"
        local video_stream=$(echo "$info" | jq -r '.streams[] | select(.codec_type=="video")')
        local width=$(echo "$video_stream" | jq -r '.width')
        local height=$(echo "$video_stream" | jq -r '.height')
        local resolution="${width}x${height}"
        echo "    Codec: $(echo "$video_stream" | jq -r '.codec_name')"
        echo "    Resolution: $resolution"
        echo "    Display Aspect Ratio: $(echo "$video_stream" | jq -r '.display_aspect_ratio')"
        echo "    Frame rate: $(echo "$video_stream" | jq -r '.r_frame_rate')"
        local video_bitrate=$(echo "$video_stream" | jq -r '.bit_rate')
        echo "    Bitrate: $(format_number "$video_bitrate") b/s"
        echo ""

        # Audio stream information
        echo -e "\e[1mAudio Stream:\e[0m"
        local audio_stream=$(echo "$info" | jq -r '.streams[] | select(.codec_type=="audio")')
        echo "    Codec: $(echo "$audio_stream" | jq -r '.codec_name')"
        echo "    Channels: $(echo "$audio_stream" | jq -r '.channels')"
        echo "    Sample rate: $(echo "$audio_stream" | jq -r '.sample_rate') Hz"
        local audio_bitrate=$(echo "$audio_stream" | jq -r '.bit_rate')
        echo "    Bitrate: $(format_number "$audio_bitrate") b/s"
    else
        # For multiple files, show summarized table
        echo -e "\e[1mVideo Information Summary:\e[0m"
        echo "==================================================================================================="
        printf "%-4s %-30s %-8s %12s %-12s %-8s %-6s %8s\n" "#" "Filename" "Format" "Duration" "Resolution" "FPS" "Audio" "Size"
        echo "---------------------------------------------------------------------------------------------------"
        
        # Store file list for later reference
        local file_list=("$@")
        local i=1
        
        for file in "${file_list[@]}"; do
            local info=$(ffprobe -v quiet -print_format json -show_format -show_streams "$file")
            
            # Truncate filename to 30 characters
            local filename=$(basename "$file")
            if [ ${#filename} -gt 30 ]; then
                filename="${filename:0:27}..."
            fi
            
            # Get and format other information
            local format=$(echo "$info" | jq -r '.format.format_name')
            if [ ${#format} -gt 8 ]; then
                format="${format:0:5}..."
            fi
            
            local duration=$(echo "$info" | jq -r '.format.duration')
            duration=$(printf "%.2f" "$duration")
            if [ ${#duration} -gt 12 ]; then
                duration="${duration:0:9}..."
            fi
            
            local video_stream=$(echo "$info" | jq -r '.streams[] | select(.codec_type=="video")')
            local width=$(echo "$video_stream" | jq -r '.width')
            local height=$(echo "$video_stream" | jq -r '.height')
            local resolution="${width}x${height}"
            if [ ${#resolution} -gt 12 ]; then
                resolution="${resolution:0:9}..."
            fi
            
            local fps=$(echo "$video_stream" | jq -r '.r_frame_rate')
            if [ ${#fps} -gt 8 ]; then
                fps="${fps:0:5}..."
            fi
            
            local audio=$(echo "$info" | jq -r '.streams[] | select(.codec_type=="audio") | .codec_name')
            if [ ${#audio} -gt 6 ]; then
                audio="${audio:0:3}..."
            fi
            
            local size=$(echo "$info" | jq -r '.format.size')
            size=$(format_number "$size")
            
            printf "%-4d %-30s %-8s %12s %-12s %-8s %-6s %8s\n" \
                "$i" \
                "$filename" \
                "$format" \
                "$duration" \
                "$resolution" \
                "$fps" \
                "$audio" \
                "$size"
            
            ((i++))
        done
        echo "==================================================================================================="
        echo "Note: Long values are truncated with '...'"
        echo "      Use serial numbers (#) to reference files in subsequent commands"
        echo "      Size values are shown in MB when too large"
        
        # Store the file list in a global variable for other functions to use
        declare -g VIDEO_INFO_FILES=("${file_list[@]}")
    fi
}

# Convert video format
convert() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m convert <input_file> <output_file> <format>"
        echo "    Converts a video to a specified format."
        echo "    Supported formats: mp4, mkv, avi, webm, mov"
        return 0
    fi
    if [ "$#" -ne 3 ]; then
        echo "Usage: convert <input_file> <output_file> <format>"
        return 1
    fi

    # Resolve the input file reference
    local input_file=$(resolve_file_reference "$1")
    validate_input_file "$input_file" || return 1
    validate_output_dir "$2"

    ffmpeg -i "$input_file" -c:v copy -c:a copy "$2.$3"
    echo "Video converted and saved as $2.$3"
}

# Extract audio from video
extract_audio() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m extract_audio <input_file> <output_file> [format]"
        echo "    Extracts audio from a video file."
        echo "    Format defaults to mp3 if not specified"
        return 0
    fi
    if [ "$#" -lt 2 ]; then
        echo "Usage: extract_audio <input_file> <output_file> [format]"
        return 1
    fi

    # Resolve the input file reference
    local input_file=$(resolve_file_reference "$1")
    validate_input_file "$input_file" || return 1
    validate_output_dir "$2"

    local format="${3:-mp3}"
    ffmpeg -i "$input_file" -vn -acodec libmp3lame "$2.$format"
    echo "Audio extracted and saved as $2.$format"
}

# Trim video
trim() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m trim <input_file> <output_file> <start_time> <duration>"
        echo "    Trims a video to specified start time and duration."
        echo "    Time format: HH:MM:SS or seconds"
        return 0
    fi
    if [ "$#" -ne 4 ]; then
        echo "Usage: trim <input_file> <output_file> <start_time> <duration>"
        return 1
    fi

    # Resolve the input file reference
    local input_file=$(resolve_file_reference "$1")
    validate_input_file "$input_file" || return 1
    validate_output_dir "$2"

    ffmpeg -i "$input_file" -ss "$3" -t "$4" -c:v copy -c:a copy "$2"
    echo "Video trimmed and saved as $2"
}

# Resize video
resize() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m resize <input_file> <output_file> <width> [height]"
        echo "    Resizes a video to specified dimensions."
        echo "    If height is not specified, it will be calculated to maintain aspect ratio"
        return 0
    fi
    if [ "$#" -lt 3 ]; then
        echo "Usage: resize <input_file> <output_file> <width> [height]"
        return 1
    fi

    # Resolve the input file reference
    local input_file=$(resolve_file_reference "$1")
    validate_input_file "$input_file" || return 1
    validate_output_dir "$2"

    if [ "$#" -eq 3 ]; then
        ffmpeg -i "$input_file" -vf "scale=$3:-1" "$2"
    else
        ffmpeg -i "$input_file" -vf "scale=$3:$4" "$2"
    fi
    echo "Video resized and saved as $2"
}

# Change video speed
speed() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m speed <input_file> <output_file> <speed_factor>"
        echo "    Changes the playback speed of a video."
        echo "    Speed factor: 0.5 for half speed, 2.0 for double speed"
        return 0
    fi
    if [ "$#" -ne 3 ]; then
        echo "Usage: speed <input_file> <output_file> <speed_factor>"
        return 1
    fi

    # Resolve the input file reference
    local input_file=$(resolve_file_reference "$1")
    validate_input_file "$input_file" || return 1
    validate_output_dir "$2"

    ffmpeg -i "$input_file" -filter_complex "[0:v]setpts=$3*PTS[v];[0:a]atempo=$3[a]" -map "[v]" -map "[a]" "$2"
    echo "Video speed changed and saved as $2"
}

# Add watermark to video
watermark() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m watermark <input_file> <output_file> <watermark_image> [position]"
        echo "    Adds a watermark image to a video."
        echo "    Position: top-left, top-right, bottom-left, bottom-right (default: bottom-right)"
        return 0
    fi
    if [ "$#" -lt 3 ]; then
        echo "Usage: watermark <input_file> <output_file> <watermark_image> [position]"
        return 1
    fi

    # Resolve the input file reference
    local input_file=$(resolve_file_reference "$1")
    validate_input_file "$input_file" || return 1
    validate_input_file "$3" || return 1
    validate_output_dir "$2"

    local position="${4:-bottom-right}"
    case "$position" in
        "top-left") overlay="10:10" ;;
        "top-right") overlay="main_w-overlay_w-10:10" ;;
        "bottom-left") overlay="10:main_h-overlay_h-10" ;;
        "bottom-right") overlay="main_w-overlay_w-10:main_h-overlay_h-10" ;;
        *) overlay="main_w-overlay_w-10:main_h-overlay_h-10" ;;
    esac

    ffmpeg -i "$input_file" -i "$3" -filter_complex "overlay=$overlay" "$2"
    echo "Watermark added and saved as $2"
}

# Extract frames from video
frames() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m frames <input_file> <output_dir> [frame_rate]"
        echo "    Extracts frames from a video file."
        echo "    Frame rate is optional (default: 1 frame per second)"
        return 0
    fi
    if [ "$#" -lt 2 ]; then
        echo "Usage: frames <input_file> <output_dir> [frame_rate]"
        return 1
    fi

    # Resolve the input file reference
    local input_file=$(resolve_file_reference "$1")
    validate_input_file "$input_file" || return 1
    mkdir -p "$2"
    
    local frame_rate="${3:-1}"
    ffmpeg -i "$input_file" -vf "fps=$frame_rate" "$2/frame_%04d.png"
    echo "Frames extracted to $2"
}

# Create video from images
create_video() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m create_video <input_pattern> <output_file> <frame_rate>"
        echo "    Creates a video from a sequence of images."
        echo "    Input pattern should match the image sequence (e.g., 'frames/frame_%04d.png')"
        return 0
    fi
    if [ "$#" -ne 3 ]; then
        echo "Usage: create_video <input_pattern> <output_file> <frame_rate>"
        return 1
    fi

    validate_output_dir "$2"
    ffmpeg -framerate "$3" -i "$1" -c:v libx264 -pix_fmt yuv420p "$2"
    echo "Video created and saved as $2"
}

# Concatenate videos
concat() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m concat <output_file> <input_file1> [input_file2 ...]"
        echo "    Concatenates multiple videos into one."
        return 0
    fi
    if [ "$#" -lt 3 ]; then
        echo "Usage: concat <output_file> <input_file1> [input_file2 ...]"
        return 1
    fi

    validate_output_dir "$1"
    shift
    local input_files=("$@")
    
    # Create a temporary file with the list of videos
    local list_file=$(mktemp)
    for file in "${input_files[@]}"; do
        echo "file '$file'" >> "$list_file"
    done
    
    ffmpeg -f concat -safe 0 -i "$list_file" -c copy "$1"
    rm "$list_file"
    echo "Videos concatenated and saved as $1"
}

# Enhanced help function with categories
help() {
    if [ "$#" -eq 1 ]; then
        # If there's a search phrase, filter based on it
        search_phrase="$1"
        echo -e "\e[1mSearching for commands matching:\e[0m $search_phrase"
        echo ""
        declare -F | awk '{print $3}' | while read func; do
            if [[ "$func" != "help" && "$func" == *"$search_phrase"* ]]; then
                $func -h
                echo ""
            fi
        done
    else
        echo -e "\e[1mVideo Manipulation Commands:\e[0m"
        echo "============================"
        echo ""
        echo -e "\e[1mBasic Operations:\e[0m"
        echo "----------------"
        info -h
        convert -h
        extract_audio -h
        trim -h
        resize -h
        echo ""
        echo -e "\e[1mAdvanced Operations:\e[0m"
        echo "------------------"
        speed -h
        watermark -h
        frames -h
        create_video -h
        concat -h
        echo ""
        echo -e "\e[1mInformation:\e[0m"
        echo "-----------"
        help -h
    fi
}

# Display detailed information about the script and its capabilities
about() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m about"
        echo "    Displays detailed information about the video manipulation functions."
        return 0
    fi

    echo -e "\e[1mVideo Manipulation Package Information:\e[0m"
    echo "========================================="
    echo ""
    
    echo -e "\e[1mOverview:\e[0m"
    echo "    This package provides a collection of video manipulation commands using ffmpeg."
    echo "    It includes commands for basic operations, advanced manipulations, and batch processing."
    echo ""
    
    echo -e "\e[1mDependencies:\e[0m"
    echo "    - ffmpeg (for video processing)"
    echo "    - ffprobe (for video information)"
    echo "    - jq (for JSON parsing)"
    echo ""
    
    echo -e "\e[1mCommand Categories:\e[0m"
    echo "    1. Basic Operations:"
    echo "       - info: Display video information"
    echo "       - convert: Convert between different video formats"
    echo "       - extract_audio: Extract audio from video"
    echo "       - trim: Trim video to specific duration"
    echo "       - resize: Resize video dimensions"
    echo ""
    echo "    2. Advanced Operations:"
    echo "       - speed: Change video playback speed"
    echo "       - watermark: Add watermark to video"
    echo "       - frames: Extract frames from video"
    echo "       - create_video: Create video from image sequence"
    echo "       - concat: Concatenate multiple videos"
    echo ""
    
    echo -e "\e[1mUsage Tips:\e[0m"
    echo "    - Use 'help' to see all available commands"
    echo "    - Use 'help <search_term>' to search for specific commands"
    echo "    - Use '-h' with any command to see its usage information"
    echo "    - All commands support input validation and error handling"
    echo ""
    
    echo -e "\e[1mFile Management:\e[0m"
    echo "    - Input files are validated before processing"
    echo "    - Output directories are created automatically if they don't exist"
    echo "    - Original files are preserved during processing"
    echo ""
    
    echo -e "\e[1mError Handling:\e[0m"
    echo "    - Commands validate input parameters"
    echo "    - File existence is checked before processing"
    echo "    - Error messages are descriptive and helpful"
    echo ""
    
    echo -e "\e[1mExamples:\e[0m"
    echo "    # Convert video format"
    echo "    convert input.mp4 output.mkv mkv"
    echo ""
    echo "    # Extract audio"
    echo "    extract_audio input.mp4 output mp3"
    echo ""
    echo "    # Trim video"
    echo "    trim input.mp4 output.mp4 00:00:10 00:00:30"
    echo ""
    
    echo -e "\e[1mNotes:\e[0m"
    echo "    - All commands preserve original files"
    echo "    - Output files are created in the specified locations"
    echo "    - Commands return 0 on success, 1 on error"
    echo "    - Error messages are displayed to stderr"
}

# List all available commands with basic usage
commands() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m commands"
        echo "    Lists all available commands and their basic usage syntax."
        return 0
    fi

    echo -e "\e[1mAvailable Commands:\e[0m"
    echo "==================="
    echo ""
    echo -e "\e[1mBasic Operations:\e[0m"
    echo "----------------"
    echo "info <input_file> [input_file2 ...]"
    echo "convert <input_file> <output_file> <format>"
    echo "extract_audio <input_file> <output_file> [format]"
    echo "trim <input_file> <output_file> <start_time> <duration>"
    echo "resize <input_file> <output_file> <width> [height]"
    echo ""
    echo -e "\e[1mAdvanced Operations:\e[0m"
    echo "------------------"
    echo "speed <input_file> <output_file> <speed_factor>"
    echo "watermark <input_file> <output_file> <watermark_image> [position]"
    echo "frames <input_file> <output_dir> [frame_rate]"
    echo "create_video <input_pattern> <output_file> <frame_rate>"
    echo "concat <output_file> <input_file1> [input_file2 ...]"
    echo ""
    echo -e "\e[1mInformation:\e[0m"
    echo "-----------"
    echo "help [search_term]"
    echo "commands"
    echo "about"
    echo ""
    echo "Note: Use '-h' with any command for detailed help"
} 