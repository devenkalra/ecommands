#!/bin/bash

# File Manager Commands
# A collection of useful file management commands

# Helper function to check if a file exists
check_file() {
    if [ ! -e "$1" ]; then
        echo "Error: File or directory '$1' does not exist"
        return 1
    fi
    return 0
}

# Helper function to check if a directory exists
check_dir() {
    if [ ! -d "$1" ]; then
        echo "Error: Directory '$1' does not exist"
        return 1
    fi
    return 0
}

# Helper function to create directory if it doesn't exist
ensure_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
    fi
}

# Helper function to resolve file reference (number or path)
resolve_file() {
    local ref="$1"
    local dir="${2:-.}"
    
    # If it's a number, get the corresponding file from the list
    if [[ "$ref" =~ ^[0-9]+$ ]]; then
        # Get the file name without the number prefix
        local file=$(list -n "$dir" | sed -n "${ref}p" | sed 's/^[0-9]\+[[:space:]]\+//')
        if [ -z "$file" ]; then
            echo "Error: Invalid file number: $ref"
            return 1
        fi
        # If the file path is relative, prepend the directory
        if [[ "$file" != /* ]]; then
            echo "$dir/$file"
        else
            echo "$file"
        fi
    else
        echo "$ref"
    fi
}

# Copy files with progress bar
copy() {
    if [ "$1" = "-h" ]; then
        echo "Usage: copy <source> <destination>"
        echo "Copy files with progress bar"
        echo "Source can be a file number from 'list' command"
        return 0
    fi
    
    if [ $# -ne 2 ]; then
        echo "Error: Invalid number of arguments"
        echo "Usage: copy <source> <destination>"
        return 1
    fi
    
    local source=$(resolve_file "$1")
    [ $? -ne 0 ] && return 1
    
    check_file "$source" || return 1
    ensure_dir "$(dirname "$2")"
    
    if [ -d "$source" ]; then
        rsync -ah --progress "$source" "$2"
    else
        rsync -ah --progress "$source" "$2"
    fi
}

# Move files with progress bar
move() {
    if [ "$1" = "-h" ]; then
        echo "Usage: move <source> <destination>"
        echo "Move files with progress bar"
        echo "Source can be a file number from 'list' command"
        return 0
    fi
    
    if [ $# -ne 2 ]; then
        echo "Error: Invalid number of arguments"
        echo "Usage: move <source> <destination>"
        return 1
    fi
    
    local source=$(resolve_file "$1")
    [ $? -ne 0 ] && return 1
    
    check_file "$source" || return 1
    ensure_dir "$(dirname "$2")"
    
    if [ -d "$source" ]; then
        rsync -ah --progress --remove-source-files "$source" "$2" && rm -r "$source"
    else
        rsync -ah --progress --remove-source-files "$source" "$2" && rm "$source"
    fi
}

# Rename files with pattern matching
rename() {
    if [ "$1" = "-h" ]; then
        echo "Usage: rename <pattern> <replacement> [directory]"
        echo "Rename files matching pattern in directory"
        echo "Example: rename 'old_' 'new_' ./files"
        return 0
    fi
    
    if [ $# -lt 2 ]; then
        echo "Error: Invalid number of arguments"
        echo "Usage: rename <pattern> <replacement> [directory]"
        return 1
    fi
    
    local pattern="$1"
    local replacement="$2"
    local dir="${3:-.}"
    
    check_dir "$dir" || return 1
    
    find "$dir" -type f -name "*$pattern*" | while read -r file; do
        new_name="${file//$pattern/$replacement}"
        if [ "$file" != "$new_name" ]; then
            mv "$file" "$new_name"
        fi
    done
}

# Create backup of files
backup() {
    if [ "$1" = "-h" ]; then
        echo "Usage: backup <file/directory> [backup_directory]"
        echo "Create timestamped backup of files"
        return 0
    fi
    
    if [ $# -lt 1 ]; then
        echo "Error: Invalid number of arguments"
        echo "Usage: backup <file/directory> [backup_directory]"
        return 1
    fi
    
    check_file "$1" || return 1
    
    local source="$1"
    local backup_dir="${2:-./backups}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local name=$(basename "$source")
    
    ensure_dir "$backup_dir"
    
    if [ -d "$source" ]; then
        local backup_file="$backup_dir/${name}_${timestamp}.tar.gz"
        tar -czf "$backup_file" "$source" && echo "Backup created: $backup_file"
    else
        local backup_file="$backup_dir/${name}_${timestamp}"
        cp "$source" "$backup_file" && echo "Backup created: $backup_file"
    fi
}

# Organize files by extension
organize() {
    if [ "$1" = "-h" ]; then
        echo "Usage: organize [directory]"
        echo "Organize files by extension into subdirectories"
        return 0
    fi
    
    local dir="${1:-.}"
    
    check_dir "$dir" || return 1
    
    find "$dir" -maxdepth 1 -type f | while read -r file; do
        if [ -f "$file" ]; then
            local ext="${file##*.}"
            if [ "$ext" != "$file" ]; then
                ensure_dir "$dir/$ext"
                mv "$file" "$dir/$ext/"
            else
                ensure_dir "$dir/no_extension"
                mv "$file" "$dir/no_extension/"
            fi
        fi
    done
}

# Organize files by date
date_move() {
    if [ "$1" = "-h" ]; then
        echo "Usage: date_move [options] <pattern> <prefix>"
        echo "Move files matching pattern to date-based directories"
        echo "Options:"
        echo "  -n, --dry-run     Show what would be done without making changes"
        echo "  -h, --help        Show this help message"
        echo ""
        echo "Example: date_move '*.jpg' /backup/photos"
        echo "         This will move all .jpg files to /backup/photos/YYYY/MM/DD/"
        return 0
    fi
    
    local dry_run=false
    local pattern=""
    local prefix=""
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run)
                dry_run=true
                shift
                ;;
            -h|--help)
                date_move -h
                return 0
                ;;
            *)
                if [ -z "$pattern" ]; then
                    pattern="$1"
                elif [ -z "$prefix" ]; then
                    prefix="$1"
                else
                    echo "Error: Too many arguments"
                    date_move -h
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    if [ -z "$pattern" ] || [ -z "$prefix" ]; then
        echo "Error: Pattern and prefix are required"
        date_move -h
        return 1
    fi
    
    # Find all files matching the pattern
    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find . -type f -name "$pattern" -print0)
    
    if [ ${#files[@]} -eq 0 ]; then
        echo "No files found matching pattern: $pattern"
        return 0
    fi
    
    # Process each file
    for file in "${files[@]}"; do
        # Get modification date
        local mod_date=$(stat -c "%y" "$file" | cut -d' ' -f1)
        local year=$(echo "$mod_date" | cut -d'-' -f1)
        local month=$(echo "$mod_date" | cut -d'-' -f2)
        local day=$(echo "$mod_date" | cut -d'-' -f3)
        
        # Create destination path
        local dest_dir="$prefix/$year/$month/$day"
        local dest_file="$dest_dir/$(basename "$file")"
        
        if [ "$dry_run" = true ]; then
            echo "Would move: $file"
            echo "      to: $dest_file"
        else
            # Create destination directory if it doesn't exist
            mkdir -p "$dest_dir"
            
            # Move the file
            if mv "$file" "$dest_file"; then
                echo "Moved: $file -> $dest_file"
            else
                echo "Error: Failed to move $file"
            fi
        fi
    done
}

# Organize files by EXIF date
exif_move() {
    if [ "$1" = "-h" ]; then
        echo "Usage: exif_move [options] <pattern> <prefix>"
        echo "Move files matching pattern to date-based directories using EXIF date"
        echo "Options:"
        echo "  -n, --dry-run     Show what would be done without making changes"
        echo "  -h, --help        Show this help message"
        echo ""
        echo "Example: exif_move '*.jpg' /backup/photos"
        echo "         This will move all .jpg files to /backup/photos/YYYY/MM/DD/"
        echo "         using EXIF date if available, or modification date if not"
        return 0
    fi
    
    local dry_run=false
    local pattern=""
    local prefix=""
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run)
                dry_run=true
                shift
                ;;
            -h|--help)
                exif_move -h
                return 0
                ;;
            *)
                if [ -z "$pattern" ]; then
                    pattern="$1"
                elif [ -z "$prefix" ]; then
                    prefix="$1"
                else
                    echo "Error: Too many arguments"
                    exif_move -h
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    if [ -z "$pattern" ] || [ -z "$prefix" ]; then
        echo "Error: Pattern and prefix are required"
        exif_move -h
        return 1
    fi
    
    # Check if exiftool is installed
    if ! command -v exiftool &> /dev/null; then
        echo "Error: exiftool is required but not installed"
        echo "Please install exiftool first (e.g., 'sudo apt install exiftool')"
        return 1
    fi
    
    # Find all files matching the pattern
    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find . -type f -name "$pattern" -print0)
    
    if [ ${#files[@]} -eq 0 ]; then
        echo "No files found matching pattern: $pattern"
        return 0
    fi
    
    # Process each file
    for file in "${files[@]}"; do
        # Try to get EXIF date first
        local exif_date=$(exiftool -DateTimeOriginal -d "%Y-%m-%d" "$file" 2>/dev/null | cut -d: -f2- | tr -d ' ')
        
        # If no EXIF date, use modification date
        if [ -z "$exif_date" ]; then
            exif_date=$(stat -c "%y" "$file" | cut -d' ' -f1)
        fi
        
        local year=$(echo "$exif_date" | cut -d'-' -f1)
        local month=$(echo "$exif_date" | cut -d'-' -f2)
        local day=$(echo "$exif_date" | cut -d'-' -f3)
        
        # Create destination path
        local dest_dir="$prefix/$year/$month/$day"
        local dest_file="$dest_dir/$(basename "$file")"
        
        if [ "$dry_run" = true ]; then
            echo "Would move: $file"
            echo "      to: $dest_file"
            echo "      date: $exif_date"
        else
            # Create destination directory if it doesn't exist
            mkdir -p "$dest_dir"
            
            # Move the file
            if mv "$file" "$dest_file"; then
                echo "Moved: $file -> $dest_file (date: $exif_date)"
            else
                echo "Error: Failed to move $file"
            fi
        fi
    done
}

# Find duplicate files
find_duplicates() {
    if [ "$1" = "-h" ]; then
        echo "Usage: find_duplicates [directory]"
        echo "Find duplicate files by content"
        return 0
    fi
    
    local dir="${1:-.}"
    
    check_dir "$dir" || return 1
    
    find "$dir" -type f -exec md5sum {} + | sort | uniq -w32 -dD
}

# Clean empty directories
clean_empty() {
    if [ "$1" = "-h" ]; then
        echo "Usage: clean_empty [directory]"
        echo "Remove empty directories"
        return 0
    fi
    
    local dir="${1:-.}"
    
    check_dir "$dir" || return 1
    
    find "$dir" -type d -empty -delete
}

# Get file information
file_info() {
    if [ "$1" = "-h" ]; then
        echo "Usage: file_info <file>"
        echo "Display detailed file information"
        echo "File can be a file number from 'list' command"
        return 0
    fi
    
    if [ $# -ne 1 ]; then
        echo "Error: Invalid number of arguments"
        echo "Usage: file_info <file>"
        return 1
    fi
    
    local file=$(resolve_file "$1")
    [ $? -ne 0 ] && return 1
    
    check_file "$file" || return 1
    
    echo "File: $file"
    echo "Size: $(du -h "$file" | cut -f1)"
    echo "Type: $(file "$file" | cut -d: -f2-)"
    echo "Permissions: $(stat -c "%A" "$file")"
    echo "Owner: $(stat -c "%U" "$file")"
    echo "Group: $(stat -c "%G" "$file")"
    echo "Last modified: $(stat -c "%y" "$file")"
}

# Get detailed information about files and directories
info() {
    if [ "$1" = "-h" ]; then
        echo "Usage: info <file/directory> [file/directory...]"
        echo "Display detailed information about files and directories"
        echo "Options:"
        echo "  -h    Show this help message"
        echo ""
        echo "Files can be referenced by their number from 'list' command"
        return 0
    fi
    
    if [ $# -eq 0 ]; then
        echo "Error: No files or directories specified"
        echo "Usage: info <file/directory> [file/directory...]"
        return 1
    fi
    
    # If only one item, show detailed info
    if [ $# -eq 1 ]; then
        local item=$(resolve_file "$1")
        [ $? -ne 0 ] && return 1
        
        check_file "$item" || return 1
        
        if [ -d "$item" ]; then
            echo "Directory: $item"
            local size_human=$(du -sh "$item" | cut -f1)
            local size_bytes=$(du -sb "$item" | cut -f1)
            echo "Size: $size_human ($size_bytes bytes) | Files: $(find "$item" -type f | wc -l) | Dirs: $(find "$item" -type d | wc -l)"
            echo "Permissions: $(stat -c "%A" "$item") | Modified: $(stat -c "%y" "$item")"
            
            echo -e "\nLargest files:"
            find "$item" -type f -exec du -b {} + | sort -rn | head -n 5 | while read -r size file; do
                local human_size=$(numfmt --to=iec-i --suffix=B --format="%.1f" "$size")
                printf "%-20s %-15s %s\n" "$human_size" "($size bytes)" "${file#./}"
            done
            
            echo -e "\nFile types:"
            find "$item" -type f | sed 's/.*\.//' | sort | uniq -c | sort -nr | head -n 5 | while read -r count ext; do
                printf "%-5d %s\n" "$count" "$ext"
            done
        else
            echo "File: $item"
            local size_human=$(du -sh "$item" | cut -f1)
            local size_bytes=$(du -sb "$item" | cut -f1)
            echo "Size: $size_human ($size_bytes bytes) | Type: $(file "$item" | cut -d: -f2-)"
            echo "Permissions: $(stat -c "%A" "$item") | Modified: $(stat -c "%y" "$item")"
            
            if file "$item" | grep -q "text"; then
                echo -e "\nFirst 5 lines:"
                head -n 5 "$item"
            fi
        fi
    else
        # Multiple items, show summary table
        echo "File Information Summary:"
        echo "========================"
        printf "%-50s %-10s %-10s %-20s %-10s\n" "Path" "Type" "Size" "Modified" "Permissions"
        echo "----------------------------------------------------------------------------------------------------"
        
        for item in "$@"; do
            local resolved_item=$(resolve_file "$item")
            if [ $? -eq 0 ] && [ -e "$resolved_item" ]; then
                local type="File"
                [ -d "$resolved_item" ] && type="Directory"
                local size=$(du -sh "$resolved_item" 2>/dev/null | cut -f1)
                local modified=$(stat -c "%y" "$resolved_item" 2>/dev/null | cut -d' ' -f1)
                local perms=$(stat -c "%A" "$resolved_item" 2>/dev/null)
                local path="$resolved_item"
                if [ ${#path} -gt 47 ]; then
                    path="${path:0:44}..."
                fi
                printf "%-50s %-10s %-10s %-20s %-10s\n" "$path" "$type" "$size" "$modified" "$perms"
            fi
        done
    fi
}

# List files with various options
list() {
    if [ "$1" = "-h" ]; then
        echo "Usage: list [options] [directory]"
        echo "List files with various sorting and filtering options"
        echo "Options:"
        echo "  -s, --size        Sort by size"
        echo "  -t, --time        Sort by modification time"
        echo "  -n, --name        Sort by name (default)"
        echo "  -r, --reverse     Reverse sort order"
        echo "  -a, --all         Show hidden files"
        echo "  -d, --dirs        Show only directories"
        echo "  -f, --files       Show only files"
        echo "  -e, --ext <ext>   Show only files with extension"
        echo "  -p, --pattern <p> Show only files matching pattern in full path"
        echo "  -l, --long        Show detailed information"
        echo "  -R, --recursive   List files recursively"
        echo "  -h, --help        Show this help message"
        echo ""
        echo "Files can be referenced by their number in other commands"
        echo "Pattern can use glob syntax (e.g., '*.txt', 'file*', '*pattern*')"
        echo "Pattern matches against the full path, not just the filename"
        return 0
    fi
    
    local dir="."
    local sort_by="name"
    local reverse=false
    local show_hidden=false
    local show_dirs=true
    local show_files=true
    local extension=""
    local pattern=""
    local long_format=false
    local recursive=false
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--size)
                sort_by="size"
                shift
                ;;
            -t|--time)
                sort_by="time"
                shift
                ;;
            -n|--name)
                sort_by="name"
                shift
                ;;
            -r|--reverse)
                reverse=true
                shift
                ;;
            -a|--all)
                show_hidden=true
                shift
                ;;
            -d|--dirs)
                show_dirs=true
                show_files=false
                shift
                ;;
            -f|--files)
                show_dirs=false
                show_files=true
                shift
                ;;
            -e|--ext)
                extension="$2"
                shift 2
                ;;
            -p|--pattern)
                pattern="$2"
                shift 2
                ;;
            -l|--long)
                long_format=true
                shift
                ;;
            -R|--recursive)
                recursive=true
                shift
                ;;
            *)
                if [ -d "$1" ]; then
                    dir="$1"
                else
                    echo "Error: Invalid option or directory: $1"
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    check_dir "$dir" || return 1
    
    # Build find command
    local find_cmd="find \"$dir\""
    if [ "$recursive" = false ]; then
        find_cmd+=" -maxdepth 1"
    fi
    
    if [ "$show_hidden" = false ]; then
        find_cmd+=" -not -name '.*'"
    fi
    
    if [ "$show_dirs" = true ] && [ "$show_files" = true ]; then
        find_cmd+=" \( -type f -o -type d \)"
    elif [ "$show_dirs" = true ]; then
        find_cmd+=" -type d"
    elif [ "$show_files" = true ]; then
        find_cmd+=" -type f"
    fi
    
    if [ -n "$extension" ]; then
        find_cmd+=" -name \"*.$extension\""
    fi
    
    # Set up sort command based on sort_by
    local sort_cmd="sort"
    if [ "$reverse" = true ]; then
        sort_cmd+=" -r"
    fi
    
    # Execute command
    if [ "$long_format" = true ]; then
        echo "Listing files in $dir"$([ "$recursive" = true ] && echo " (recursively)")$([ -n "$pattern" ] && echo " matching pattern '$pattern'"):""
        echo "====================="
        printf "%-4s %-30s %-8s %-12s %-8s %s\n" "#" "Name" "Size" "Modified" "Type" "Path"
        echo "--------------------------------------------------------------------------------"
        
        # First collect all items
        local items=()
        while IFS= read -r item; do
            if [ "$item" != "$dir" ]; then
                # Apply pattern filter if specified
                if [ -n "$pattern" ]; then
                    if ! [[ "$item" == $pattern ]]; then
                        continue
                    fi
                fi
                local name=$(basename "$item")
                local size=$(du -sh "$item" 2>/dev/null | cut -f1)
                local modified=$(stat -c "%y" "$item" 2>/dev/null | cut -d' ' -f1)
                local type="File"
                [ -d "$item" ] && type="Dir"
                local path=$(dirname "$item")
                if [ "$path" = "." ]; then
                    path="."
                else
                    path="${path#$dir/}"
                fi
                # Trim name if too long
                if [ ${#name} -gt 27 ]; then
                    name="${name:0:24}..."
                fi
                # Trim path if too long
                if [ ${#path} -gt 17 ]; then
                    path="${path:0:14}..."
                fi
                # Store the full item path for sorting
                items+=("$name|$size|$modified|$type|$path")
            fi
        done < <(eval "$find_cmd")
        
        # Sort items
        case "$sort_by" in
            size)
                IFS=$'\n' sorted_items=($(printf "%s\n" "${items[@]}" | sort -t'|' -k2 -n))
                ;;
            time)
                IFS=$'\n' sorted_items=($(printf "%s\n" "${items[@]}" | sort -t'|' -k3 -r))
                ;;
            name)
                IFS=$'\n' sorted_items=($(printf "%s\n" "${items[@]}" | sort -t'|' -k1))
                ;;
        esac
        
        if [ "$reverse" = true ]; then
            sorted_items=($(printf "%s\n" "${sorted_items[@]}" | tac))
        fi
        
        # Display sorted items
        local count=1
        for item in "${sorted_items[@]}"; do
            # Extract fields using a more robust method
            local name=$(echo "$item" | cut -d'|' -f1)
            local size=$(echo "$item" | cut -d'|' -f2)
            local modified=$(echo "$item" | cut -d'|' -f3)
            local type=$(echo "$item" | cut -d'|' -f4)
            local path=$(echo "$item" | cut -d'|' -f5-)
            printf "%-4d %-30s %-8s %-12s %-8s %s\n" "$count" "$name" "$size" "$modified" "$type" "$path"
            ((count++))
        done
    else
        # First collect and sort all items
        local sorted_items=$(eval "$find_cmd" | while read -r item; do
            if [ "$item" != "$dir" ]; then
                # Apply pattern filter if specified
                if [ -n "$pattern" ]; then
                    if ! [[ "$item" == $pattern ]]; then
                        continue
                    fi
                fi
                local display_path
                if [ "$recursive" = true ]; then
                    local path=$(dirname "$item")
                    if [ "$path" = "." ]; then
                        display_path="$(basename "$item")"
                    else
                        display_path="${path#$dir/}/$(basename "$item")"
                    fi
                else
                    display_path="$(basename "$item")"
                fi
                # Trim path if too long (allow for 4 chars of number + 1 space + 3 dots)
                if [ ${#display_path} -gt 72 ]; then
                    display_path="${display_path:0:69}..."
                fi
                echo "$display_path"
            fi
        done | eval "$sort_cmd")
        
        # Then add numbers to the sorted output
        local count=1
        while IFS= read -r line; do
            printf "%-4d %s\n" "$count" "$line"
            ((count++))
        done <<< "$sorted_items"
    fi
}

# List all commands
commands() {
    if [ "$1" = "-h" ]; then
        echo "Usage: commands"
        echo "List all available file management commands"
        return 0
    fi
    
    echo "Available File Management Commands:"
    echo "=================================="
    echo "copy        - Copy files with progress bar"
    echo "move        - Move files with progress bar"
    echo "rename      - Rename files with pattern matching"
    echo "backup      - Create timestamped backup of files"
    echo "organize    - Organize files by extension"
    echo "date_move   - Move files to date-based directories"
    echo "exif_move   - Move files using EXIF date"
    echo "find_duplicates - Find duplicate files by content"
    echo "clean_empty - Remove empty directories"
    echo "file_info   - Display detailed file information"
    echo "info        - Display detailed information about files/directories"
    echo "list        - List files with various sorting and filtering options"
    echo ""
    echo "Use -h with any command for detailed help"
}

# Help command
help() {
    if [ $# -eq 0 ]; then
        commands
        return 0
    fi
    
    local cmd="$1"
    case "$cmd" in
        copy) copy -h ;;
        move) move -h ;;
        rename) rename -h ;;
        backup) backup -h ;;
        organize) organize -h ;;
        date_move) date_move -h ;;
        exif_move) exif_move -h ;;
        find_duplicates) find_duplicates -h ;;
        clean_empty) clean_empty -h ;;
        file_info) file_info -h ;;
        info) info -h ;;
        list) list -h ;;
        commands) commands -h ;;
        *) echo "Unknown command: $cmd" ;;
    esac
}

# About command
about() {
    if [ "$1" = "-h" ]; then
        echo "Usage: about"
        echo "Display information about the file manager"
        return 0
    fi
    
    echo "File Manager Commands"
    echo "===================="
    echo "Version: 1.0"
    echo "Description: A collection of useful file management commands"
    echo "Author: Your Name"
    echo "License: MIT"
    echo ""
    echo "Use 'commands' to see all available commands"
    echo "Use 'help <command>' for detailed help on a specific command"
} 