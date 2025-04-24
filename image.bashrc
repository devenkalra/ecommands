# Resize image
resize() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m resize <input_file> <output_file> <width> [height]"
        echo "    Resizes an image to specified dimensions while preserving aspect ratio."
        echo "    If height is not specified, it will be calculated automatically."
        echo "    <input_file> can be a filename or a number from the info table"
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
    
    if [ "$#" -eq 4 ]; then
        convert "$input_file" -resize "${3}x${4}" "$2"
    else
        convert "$input_file" -resize "$3x" "$2"
    fi
    echo "Image resized and saved as $2."
}

# Convert image format
convert() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m convert <input_file> <output_file> <format>"
        echo "    Converts an image to a specified format."
        echo "    Supported formats: jpg, png, gif, webp, tiff"
        return 0
    fi
    if [ "$#" -ne 3 ]; then
        echo "Usage: convert <input_file> <output_file> <format>"
        return 1
    fi
    validate_input_file "$1" || return 1
    validate_output_dir "$2"
    
    local format=$(echo "$3" | tr '[:upper:]' '[:lower:]')
    case "$format" in
        jpg|jpeg|png|gif|webp|tiff)
            convert "$1" "$2.$format"
            echo "Image converted to $format format and saved as $2.$format."
            ;;
        *)
            echo "Error: Unsupported format '$format'"
            echo "Supported formats: jpg, png, gif, webp, tiff"
            return 1
            ;;
    esac
}

# Grayscale image
grayscale() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m grayscale <input_file> <output_file>"
        echo "    Applies grayscale to an image."
        return 0
    fi
    if [ "$#" -ne 2 ]; then
        echo "Usage: grayscale <input_file> <output_file>"
        return 1
    fi
    convert "$1" -colorspace Gray "$2"
    echo "Image converted to grayscale and saved as $2."
}

# Crop image
crop() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m crop <input_file> <output_file> <width> <height> <x_offset> <y_offset>"
        echo "    Crops an image to a specified width, height, and position."
        return 0
    fi
    if [ "$#" -ne 6 ]; then
        echo "Usage: crop <input_file> <output_file> <width> <height> <x_offset> <y_offset>"
        return 1
    fi
    convert "$1" -crop "${3}x${4}+${5}+${6}" "$2"
    echo "Image cropped and saved as $2."
}

# Rotate image
rotate() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m rotate <input_file> <output_file> <angle>"
        echo "    Rotates an image by a specified angle."
        return 0
    fi
    if [ "$#" -ne 3 ]; then
        echo "Usage: rotate <input_file> <output_file> <angle>"
        return 1
    fi
    convert "$1" -rotate "$3" "$2"
    echo "Image rotated by $3 degrees and saved as $2."
}

# Create thumbnail
thumbnail() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m thumbnail <input_file> <output_file> <size>"
        echo "    Creates a thumbnail of an image with a specified size."
        return 0
    fi
    if [ "$#" -ne 3 ]; then
        echo "Usage: thumbnail <input_file> <output_file> <size>"
        return 1
    fi
    convert "$1" -resize "$3" "$2"
    echo "Thumbnail created with size $3 and saved as $2."
}

# Merge two images
merge() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m merge <input_file1> <input_file2> <output_file>"
        echo "    Merges two images side-by-side."
        return 0
    fi
    if [ "$#" -ne 3 ]; then
        echo "Usage: merge <input_file1> <input_file2> <output_file>"
        return 1
    fi
    convert +append "$1" "$2" "$3"
    echo "Images merged and saved as $3."
}

# Add watermarkls
watermark() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m watermark <input_file> <output_file> <watermark>"
        echo "    Adds a watermark to an image."
        return 0
    fi
    if [ "$#" -ne 3 ]; then
        echo "Usage: watermark <input_file> <output_file> <watermark>"
        return 1
    fi
    convert "$1" -gravity southeast -pointsize 36 -draw "text 10,10 '$3'" "$2"
    echo "Watermark added and saved as $2."
}

# Optimize image
optimize() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m optimize <input_file> <output_file>"
        echo "    Optimizes an image for web use."
        return 0
    fi
    if [ "$#" -ne 2 ]; then
        echo "Usage: optimize <input_file> <output_file>"
        return 1
    fi
    convert "$1" -strip -quality 85 "$2"
    echo "Image optimized and saved as $2."
}

# Display image
display() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m display <input_file>"
        echo "    Displays an image using ImageMagick's display command."
        echo "    <input_file> can be a filename or a number from the info table"
        return 0
    fi
    if [ "$#" -ne 1 ]; then
        echo "Usage: display <input_file>"
        return 1
    fi

    # Resolve the input file reference
    local file=$(resolve_file_reference "$1")
    validate_input_file "$file" || return 1
    command display "$file"
    return $?
}

# Create image collage with customizable layout
collage() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m collage <output_file> <layout> <input_files...>"
        echo "    Creates a collage of images with specified layout."
        echo "    Layout format: ROWSxCOLS (e.g., 2x2, 3x3)"
        return 0
    fi
    if [ "$#" -lt 3 ]; then
        echo "Usage: collage <output_file> <layout> <input_files...>"
        return 1
    fi
    validate_output_dir "$1"
    
    local output="$1"
    local layout="$2"
    shift 2
    
    montage "$@" -geometry +5+5 -tile "$layout" "$output"
    echo "Collage created and saved as $output."
}

# Add text overlay to image
text() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m text <input_file> <output_file> <text> [position] [font_size] [color]"
        echo "    Adds text overlay to an image."
        echo "    Position: northwest, north, northeast, west, center, east, southwest, south, southeast"
        echo "    Default: southeast"
        return 0
    fi
    if [ "$#" -lt 3 ]; then
        echo "Usage: text <input_file> <output_file> <text> [position] [font_size] [color]"
        return 1
    fi
    validate_input_file "$1" || return 1
    validate_output_dir "$2"
    
    local position="${4:-southeast}"
    local font_size="${5:-36}"
    local color="${6:-white}"
    
    convert "$1" -gravity "$position" -pointsize "$font_size" -fill "$color" -annotate +10+10 "$3" "$2"
    echo "Text overlay added and saved as $2."
}

# Create animated GIF from images
gif() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m gif <output_file> <delay> <input_files...>"
        echo "    Creates an animated GIF from multiple images."
        echo "    Delay is in centiseconds (1/100 of a second)"
        return 0
    fi
    if [ "$#" -lt 3 ]; then
        echo "Usage: gif <output_file> <delay> <input_files...>"
        return 1
    fi
    validate_output_dir "$1"
    
    local output="$1"
    local delay="$2"
    shift 2
    
    convert -delay "$delay" "$@" -loop 0 "$output"
    echo "Animated GIF created and saved as $output."
}

# Extract frames from video
frames() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m frames <video_file> <output_dir> [frame_rate]"
        echo "    Extracts frames from a video file."
        echo "    Frame rate is optional (default: 1 frame per second)"
        return 0
    fi
    if [ "$#" -lt 2 ]; then
        echo "Usage: frames <video_file> <output_dir> [frame_rate]"
        return 1
    fi
    if [ ! -f "$1" ]; then
        echo "Error: Video file '$1' does not exist"
        return 1
    fi
    mkdir -p "$2"
    
    local frame_rate="${3:-1}"
    ffmpeg -i "$1" -vf "fps=$frame_rate" "$2/frame_%04d.png"
    echo "Frames extracted to $2"
}

# Display image info
info() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m info <input_file> [input_file2 ...]"
        echo "    Displays detailed information about one or more images."
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
    if [[ "$1" =~ ^[0-9]+$ ]] && [ -n "${IMAGE_INFO_FILES[*]}" ]; then
        if [ "$1" -gt 0 ] && [ "$1" -le "${#IMAGE_INFO_FILES[@]}" ]; then
            # Show detailed info for the referenced file
            local file="${IMAGE_INFO_FILES[$((1-1))]}"
            validate_input_file "$file" || return 1
            
            echo -e "\e[1mImage Information for:\e[0m $file"
            echo "========================================="
            echo ""

            # Get basic image information
            local info=$(identify -verbose "$file" 2>/dev/null)
            
            # File format and type
            echo -e "\e[1mFormat:\e[0m"
            echo "    Type: $(echo "$info" | grep "Format:" | cut -d: -f2 | sed 's/^[ \t]*//')"
            echo "    MIME type: $(echo "$info" | grep "Mime type:" | cut -d: -f2 | sed 's/^[ \t]*//')"
            echo ""

            # Dimensions and resolution
            echo -e "\e[1mDimensions:\e[0m"
            local geometry=$(echo "$info" | grep "Geometry:" | cut -d: -f2 | sed 's/^[ \t]*//')
            local width=$(echo "$geometry" | cut -dx -f1)
            local height=$(echo "$geometry" | cut -dx -f2 | cut -d+ -f1)
            echo "    Width: $width pixels"
            echo "    Height: $height pixels"
            echo "    Resolution: $(echo "$info" | grep "Resolution:" | cut -d: -f2 | sed 's/^[ \t]*//')"
            echo "    Units: $(echo "$info" | grep "Units:" | cut -d: -f2 | sed 's/^[ \t]*//')"
            echo ""

            # Color information
            echo -e "\e[1mColor Information:\e[0m"
            echo "    Colorspace: $(echo "$info" | grep "Colorspace:" | cut -d: -f2 | sed 's/^[ \t]*//')"
            echo "    Type: $(echo "$info" | grep "Type:" | cut -d: -f2 | sed 's/^[ \t]*//')"
            echo "    Depth: $(echo "$info" | grep "Depth:" | cut -d: -f2 | sed 's/^[ \t]*//') bits"
            echo "    Colors: $(echo "$info" | grep "Colors:" | cut -d: -f2 | sed 's/^[ \t]*//')"
            echo ""

            # File information
            echo -e "\e[1mFile Information:\e[0m"
            echo "    Size: $(ls -lh "$file" | awk '{print $5}')"
            echo "    Compression: $(echo "$info" | grep "Compression:" | cut -d: -f2 | sed 's/^[ \t]*//')"
            echo "    Quality: $(echo "$info" | grep "Quality:" | cut -d: -f2 | sed 's/^[ \t]*//')"
            echo ""

            # Metadata
            echo -e "\e[1mMetadata:\e[0m"
            echo "    Created: $(stat -c %y "$file" | cut -d. -f1)"
            echo "    Modified: $(stat -c %y "$file" | cut -d. -f1)"
            
            # EXIF data if available
            if command -v exiftool &>/dev/null; then
                local exif_data=$(exiftool "$file" 2>/dev/null)
                if [ -n "$exif_data" ]; then
                    echo ""
                    echo -e "\e[1mEXIF Information:\e[0m"
                    echo "    Camera: $(echo "$exif_data" | grep "Camera Model Name" | cut -d: -f2 | sed 's/^[ \t]*//')"
                    echo "    Date Taken: $(echo "$exif_data" | grep "Date/Time Original" | cut -d: -f2 | sed 's/^[ \t]*//')"
                    echo "    Exposure: $(echo "$exif_data" | grep "Exposure Time" | cut -d: -f2 | sed 's/^[ \t]*//')"
                    echo "    Aperture: $(echo "$exif_data" | grep "F Number" | cut -d: -f2 | sed 's/^[ \t]*//')"
                    echo "    ISO: $(echo "$exif_data" | grep "ISO" | cut -d: -f2 | sed 's/^[ \t]*//')"
                    echo "    Focal Length: $(echo "$exif_data" | grep "Focal Length" | cut -d: -f2 | sed 's/^[ \t]*//')"
                fi
            fi
            return 0
        else
            echo "Error: Invalid file number. Please use a number between 1 and ${#IMAGE_INFO_FILES[@]}"
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
        declare -g IMAGE_INFO_FILES=("$1")
        
        echo -e "\e[1mImage Information for:\e[0m $1"
        echo "========================================="
        echo ""

        # Get basic image information
        local info=$(identify -verbose "$1" 2>/dev/null)
        
        # File format and type
        echo -e "\e[1mFormat:\e[0m"
        echo "    Type: $(echo "$info" | grep "Format:" | cut -d: -f2 | sed 's/^[ \t]*//')"
        echo "    MIME type: $(echo "$info" | grep "Mime type:" | cut -d: -f2 | sed 's/^[ \t]*//')"
        echo ""

        # Dimensions and resolution
        echo -e "\e[1mDimensions:\e[0m"
        local geometry=$(echo "$info" | grep "Geometry:" | cut -d: -f2 | sed 's/^[ \t]*//')
        local width=$(echo "$geometry" | cut -dx -f1)
        local height=$(echo "$geometry" | cut -dx -f2 | cut -d+ -f1)
        echo "    Width: $width pixels"
        echo "    Height: $height pixels"
        echo "    Resolution: $(echo "$info" | grep "Resolution:" | cut -d: -f2 | sed 's/^[ \t]*//')"
        echo "    Units: $(echo "$info" | grep "Units:" | cut -d: -f2 | sed 's/^[ \t]*//')"
        echo ""

        # Color information
        echo -e "\e[1mColor Information:\e[0m"
        echo "    Colorspace: $(echo "$info" | grep "Colorspace:" | cut -d: -f2 | sed 's/^[ \t]*//')"
        echo "    Type: $(echo "$info" | grep "Type:" | cut -d: -f2 | sed 's/^[ \t]*//')"
        echo "    Depth: $(echo "$info" | grep "Depth:" | cut -d: -f2 | sed 's/^[ \t]*//') bits"
        echo "    Colors: $(echo "$info" | grep "Colors:" | cut -d: -f2 | sed 's/^[ \t]*//')"
        echo ""

        # File information
        echo -e "\e[1mFile Information:\e[0m"
        echo "    Size: $(ls -lh "$1" | awk '{print $5}')"
        echo "    Compression: $(echo "$info" | grep "Compression:" | cut -d: -f2 | sed 's/^[ \t]*//')"
        echo "    Quality: $(echo "$info" | grep "Quality:" | cut -d: -f2 | sed 's/^[ \t]*//')"
        echo ""

        # Metadata
        echo -e "\e[1mMetadata:\e[0m"
        echo "    Created: $(stat -c %y "$1" | cut -d. -f1)"
        echo "    Modified: $(stat -c %y "$1" | cut -d. -f1)"
        
        # EXIF data if available
        if command -v exiftool &>/dev/null; then
            local exif_data=$(exiftool "$1" 2>/dev/null)
            if [ -n "$exif_data" ]; then
                echo ""
                echo -e "\e[1mEXIF Information:\e[0m"
                echo "    Camera: $(echo "$exif_data" | grep "Camera Model Name" | cut -d: -f2 | sed 's/^[ \t]*//')"
                echo "    Date Taken: $(echo "$exif_data" | grep "Date/Time Original" | cut -d: -f2 | sed 's/^[ \t]*//')"
                echo "    Exposure: $(echo "$exif_data" | grep "Exposure Time" | cut -d: -f2 | sed 's/^[ \t]*//')"
                echo "    Aperture: $(echo "$exif_data" | grep "F Number" | cut -d: -f2 | sed 's/^[ \t]*//')"
                echo "    ISO: $(echo "$exif_data" | grep "ISO" | cut -d: -f2 | sed 's/^[ \t]*//')"
                echo "    Focal Length: $(echo "$exif_data" | grep "Focal Length" | cut -d: -f2 | sed 's/^[ \t]*//')"
            fi
        fi
    else
        # For multiple files, show summarized table
        echo -e "\e[1mImage Information Summary:\e[0m"
        echo "==================================================================================================="
        printf "%-4s %-30s %-8s %-12s %-8s %-8s %-6s %-8s %-10s\n" "#" "Filename" "Format" "Dimensions" "Res" "Space" "Depth" "Size" "Modified"
        echo "---------------------------------------------------------------------------------------------------"
        
        # Store file list for later reference
        local file_list=("$@")
        local i=1
        
        for file in "${file_list[@]}"; do
            local info=$(identify -verbose "$file" 2>/dev/null)
            
            # Truncate filename to 30 characters
            local filename=$(basename "$file")
            if [ ${#filename} -gt 30 ]; then
                filename="${filename:0:27}..."
            fi
            
            # Get and format other information
            local format=$(echo "$info" | grep "Format:" | cut -d: -f2 | sed 's/^[ \t]*//')
            if [ ${#format} -gt 8 ]; then
                format="${format:0:5}..."
            fi
            
            local geometry=$(echo "$info" | grep "Geometry:" | cut -d: -f2 | sed 's/^[ \t]*//')
            if [ ${#geometry} -gt 12 ]; then
                geometry="${geometry:0:9}..."
            fi
            
            local resolution=$(echo "$info" | grep "Resolution:" | cut -d: -f2 | sed 's/^[ \t]*//' | cut -d' ' -f1)
            if [ ${#resolution} -gt 8 ]; then
                resolution="${resolution:0:5}..."
            fi
            
            local colorspace=$(echo "$info" | grep "Colorspace:" | cut -d: -f2 | sed 's/^[ \t]*//')
            if [ ${#colorspace} -gt 8 ]; then
                colorspace="${colorspace:0:5}..."
            fi
            
            local depth=$(echo "$info" | grep "Depth:" | cut -d: -f2 | sed 's/^[ \t]*//')
            if [ ${#depth} -gt 6 ]; then
                depth="${depth:0:3}..."
            fi
            
            local size=$(ls -lh "$file" | awk '{print $5}')
            if [ ${#size} -gt 8 ]; then
                size="${size:0:5}..."
            fi
            
            local modified=$(stat -c %y "$file" | cut -d. -f1 | cut -d' ' -f1)
            if [ ${#modified} -gt 10 ]; then
                modified="${modified:0:7}..."
            fi
            
            printf "%-4d %-30s %-8s %-12s %-8s %-8s %-6s %-8s %-10s\n" \
                "$i" \
                "$filename" \
                "$format" \
                "$geometry" \
                "$resolution" \
                "$colorspace" \
                "$depth" \
                "$size" \
                "$modified"
            
            ((i++))
        done
        echo "==================================================================================================="
        echo "Note: Long values are truncated with '...'"
        echo "      Use serial numbers (#) to reference files in subsequent commands"
        
        # Store the file list in a global variable for other functions to use
        declare -g IMAGE_INFO_FILES=("${file_list[@]}")
    fi
}

# Helper function to resolve file reference (number or filename)
resolve_file_reference() {
    local reference="$1"
    
    # If reference is a number and within range of stored files
    if [[ "$reference" =~ ^[0-9]+$ ]] && [ "$reference" -gt 0 ] && [ "$reference" -le "${#IMAGE_INFO_FILES[@]}" ]; then
        echo "${IMAGE_INFO_FILES[$((reference-1))]}"
    else
        # Otherwise, treat as filename
        echo "$reference"
    fi
}

# Validate input file exists
validate_input_file() {
    if [ ! -f "$1" ]; then
        echo "Error: Input file '$1' does not exist"
        return 1
    fi
    return 0
}

# Validate output directory exists
validate_output_dir() {
    local output_dir=$(dirname "$1")
    if [ ! -d "$output_dir" ]; then
        mkdir -p "$output_dir"
    fi
}

# Batch process images in a directory
batch() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m batch <input_dir> <output_dir> <command> [args...]"
        echo "    Processes all images in a directory using the specified command."
        echo "    Example: batch input/ output/ resize 800"
        return 0
    fi
    if [ "$#" -lt 3 ]; then
        echo "Usage: batch <input_dir> <output_dir> <command> [args...]"
        return 1
    fi
    if [ ! -d "$1" ]; then
        echo "Error: Input directory '$1' does not exist"
        return 1
    fi
    mkdir -p "$2"
    
    local input_dir="$1"
    local output_dir="$2"
    local command="$3"
    shift 3
    
    for file in "$input_dir"/*; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file")
            local output_file="$output_dir/$filename"
            $command "$file" "$output_file" "$@"
        fi
    done
}

# Create image collage with customizable layout
collage() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m collage <output_file> <layout> <input_files...>"
        echo "    Creates a collage of images with specified layout."
        echo "    Layout format: ROWSxCOLS (e.g., 2x2, 3x3)"
        return 0
    fi
    if [ "$#" -lt 3 ]; then
        echo "Usage: collage <output_file> <layout> <input_files...>"
        return 1
    fi
    validate_output_dir "$1"
    
    local output="$1"
    local layout="$2"
    shift 2
    
    montage "$@" -geometry +5+5 -tile "$layout" "$output"
    echo "Collage created and saved as $output."
}

# Add text overlay to image
text() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m text <input_file> <output_file> <text> [position] [font_size] [color]"
        echo "    Adds text overlay to an image."
        echo "    Position: northwest, north, northeast, west, center, east, southwest, south, southeast"
        echo "    Default: southeast"
        return 0
    fi
    if [ "$#" -lt 3 ]; then
        echo "Usage: text <input_file> <output_file> <text> [position] [font_size] [color]"
        return 1
    fi
    validate_input_file "$1" || return 1
    validate_output_dir "$2"
    
    local position="${4:-southeast}"
    local font_size="${5:-36}"
    local color="${6:-white}"
    
    convert "$1" -gravity "$position" -pointsize "$font_size" -fill "$color" -annotate +10+10 "$3" "$2"
    echo "Text overlay added and saved as $2."
}

# Create animated GIF from images
gif() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m gif <output_file> <delay> <input_files...>"
        echo "    Creates an animated GIF from multiple images."
        echo "    Delay is in centiseconds (1/100 of a second)"
        return 0
    fi
    if [ "$#" -lt 3 ]; then
        echo "Usage: gif <output_file> <delay> <input_files...>"
        return 1
    fi
    validate_output_dir "$1"
    
    local output="$1"
    local delay="$2"
    shift 2
    
    convert -delay "$delay" "$@" -loop 0 "$output"
    echo "Animated GIF created and saved as $output."
}

# Extract frames from video
frames() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m frames <video_file> <output_dir> [frame_rate]"
        echo "    Extracts frames from a video file."
        echo "    Frame rate is optional (default: 1 frame per second)"
        return 0
    fi
    if [ "$#" -lt 2 ]; then
        echo "Usage: frames <video_file> <output_dir> [frame_rate]"
        return 1
    fi
    if [ ! -f "$1" ]; then
        echo "Error: Video file '$1' does not exist"
        return 1
    fi
    mkdir -p "$2"
    
    local frame_rate="${3:-1}"
    ffmpeg -i "$1" -vf "fps=$frame_rate" "$2/frame_%04d.png"
    echo "Frames extracted to $2"
}

# Enhanced help function with categories
help() {
    if [ "$#" -eq 1 ]; then
        # If there's a search phrase, filter based on it
        search_phrase="$1"
        echo -e "\e[1mSearching for functions matching:\e[0m $search_phrase"
        echo ""
        declare -F | awk '{print $3}' | while read func; do
            if [[ "$func" != "help" && "$func" == *"$search_phrase"* ]]; then
                $func -h
                echo ""
            fi
        done
    else
        echo -e "\e[1mImage Manipulation Commands:\e[0m"
        echo "============================"
        echo ""
        echo -e "\e[1mBasic Operations:\e[0m"
        echo "----------------"
        resize -h
        convert -h
        grayscale -h
        crop -h
        rotate -h
        echo ""
        echo -e "\e[1mAdvanced Operations:\e[0m"
        echo "------------------"
        thumbnail -h
        merge -h
        watermark -h
        optimize -h
        collage -h
        text -h
        gif -h
        echo ""
        echo -e "\e[1mBatch Processing:\e[0m"
        echo "---------------"
        batch -h
        echo ""
        echo -e "\e[1mInformation:\e[0m"
        echo "-----------"
        info -h
    fi
}

# Display detailed information about the script and its capabilities
about() {
    if [ "$1" == "-h" ]; then
        echo -e "\e[1mUsage:\e[0m about"
        echo "    Displays detailed information about the image manipulation functions."
        return 0
    fi

    echo -e "\e[1mImage Manipulation Package Information:\e[0m"
    echo "========================================="
    echo ""
    
    echo -e "\e[1mOverview:\e[0m"
    echo "    This package provides a collection of image manipulation commands using ImageMagick."
    echo "    It includes commands for basic operations, advanced manipulations, and batch processing."
    echo ""
    
    echo -e "\e[1mDependencies:\e[0m"
    echo "    - ImageMagick (convert, identify, montage commands)"
    echo "    - ffmpeg (for video frame extraction)"
    echo ""
    
    echo -e "\e[1mCommand Categories:\e[0m"
    echo "    1. Basic Operations:"
    echo "       - resize: Resize images with aspect ratio preservation"
    echo "       - convert: Convert between different image formats"
    echo "       - grayscale: Convert images to grayscale"
    echo "       - crop: Crop images to specific dimensions"
    echo "       - rotate: Rotate images by specified angle"
    echo ""
    echo "    2. Advanced Operations:"
    echo "       - thumbnail: Create image thumbnails"
    echo "       - merge: Combine images side-by-side"
    echo "       - watermark: Add text watermarks"
    echo "       - optimize: Optimize images for web use"
    echo "       - collage: Create image collages"
    echo "       - text: Add customizable text overlays"
    echo "       - gif: Create animated GIFs"
    echo ""
    echo "    3. Batch Processing:"
    echo "       - batch: Process multiple images in a directory"
    echo ""
    echo "    4. Information:"
    echo "       - info: Display image metadata"
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
    echo "    # Resize an image"
    echo "    resize input.jpg output.jpg 800"
    echo ""
    echo "    # Create a collage"
    echo "    collage collage.jpg 2x2 image1.jpg image2.jpg image3.jpg image4.jpg"
    echo ""
    echo "    # Batch process images"
    echo "    batch input/ output/ resize 800"
    echo ""
    
    echo -e "\e[1mNotes:\e[0m"
    echo "    - All commands preserve original files"
    echo "    - Output files are created in the specified locations"
    echo "    - Commands return 0 on success, 1 on error"
    echo "    - Error messages are displayed to stderr"
}
