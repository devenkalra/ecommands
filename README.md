# Command Line Tools

A collection of useful command line tools for file management, media processing, and image manipulation.

## Files

- `filemanager.bashrc` - File management commands
- `ffmpeg.bashrc` - Media processing commands using ffmpeg
- `image.bashrc` - Image manipulation commands
- `test_filemanager.bash` - Test suite for file manager commands
- `filemanager.bashrc.old` - Backup of previous version of file manager script

## Installation

1. Clone this repository or download the script files
2. Add the following lines to your `~/.bashrc`:
   ```bash
   source /path/to/filemanager.bashrc
   source /path/to/ffmpeg.bashrc
   source /path/to/image.bashrc
   ```
3. Restart your terminal or run:
   ```bash
   source ~/.bashrc
   ```

## Testing

The test suite can be run to verify file manager commands are working correctly:

```bash
./test_filemanager.bash
```

The test suite includes tests for:
- Basic file operations (copy, move, rename)
- File information commands
- Directory operations
- Backup functionality
- File organization commands

## Available Commands

### File Management (filemanager.bashrc)

#### Basic File Operations

- `copy <source> <destination>` - Copy files with progress bar
  - Source can be a file number from 'list' command
  - Example: `copy file.txt /backup/` or `copy 1 /backup/`

- `move <source> <destination>` - Move files with progress bar
  - Source can be a file number from 'list' command
  - Example: `move file.txt /backup/` or `move 1 /backup/`

- `rename <pattern> <replacement> [directory]` - Rename files matching pattern
  - Example: `rename 'old_' 'new_' ./files`

- `backup <file/directory> [backup_directory]` - Create timestamped backup
  - Creates .tar.gz for directories
  - Creates timestamped copies for files
  - Prints the full path of created backup file
  - Example: `backup important.txt` or `backup photos/ ./backups/`

#### File Organization

- `organize [directory]` - Organize files by extension
  - Creates subdirectories for each file extension
  - Example: `organize ./downloads/`

- `date_move [options] <pattern> <prefix>` - Move files to date-based directories
  - Options:
    - `-n, --dry-run` - Show what would be done without making changes
  - Example: `date_move '*.jpg' /backup/photos`

- `exif_move [options] <pattern> <prefix>` - Move files using EXIF date
  - Uses EXIF date if available, falls back to modification date
  - Options:
    - `-n, --dry-run` - Show what would be done without making changes
  - Example: `exif_move '*.jpg' /backup/photos`

#### File Information

- `list [options] [directory]` - List files with various options
  - Options:
    - `-s, --size` - Sort by size
    - `-t, --time` - Sort by modification time
    - `-n, --name` - Sort by name (default)
    - `-r, --reverse` - Reverse sort order
    - `-a, --all` - Show hidden files
    - `-d, --dirs` - Show only directories
    - `-f, --files` - Show only files
    - `-e, --ext <ext>` - Show only files with extension
    - `-p, --pattern <p>` - Show only files matching pattern in full path
    - `-l, --long` - Show detailed information
    - `-R, --recursive` - List files recursively
  - Example: `list -l -p "*.txt"`

- `file_info <file>` - Display detailed file information
  - File can be a file number from 'list' command
  - Example: `file_info document.pdf` or `file_info 1`

- `info <file/directory> [file/directory...]` - Display detailed information
  - Shows comprehensive information about files and directories
  - Example: `info photos/` or `info file1.txt file2.txt`

#### Maintenance

- `find_duplicates [directory]` - Find duplicate files by content
  - Example: `find_duplicates ./downloads/`

- `clean_empty [directory]` - Remove empty directories
  - Example: `clean_empty ./temp/`

### Media Processing (ffmpeg.bashrc)

#### Video Operations

- `video_info <file>` - Display detailed video information
  - Example: `video_info movie.mp4`

- `convert_video <input> <output> [options]` - Convert video format
  - Options:
    - `-q <quality>` - Set video quality (1-31, lower is better)
    - `-r <fps>` - Set frame rate
    - `-s <width>x<height>` - Set resolution
  - Example: `convert_video input.mp4 output.mkv -q 18`

- `extract_audio <video> <output>` - Extract audio from video
  - Example: `extract_audio movie.mp4 audio.mp3`

- `merge_video_audio <video> <audio> <output>` - Merge video and audio
  - Example: `merge_video_audio video.mp4 audio.mp3 output.mp4`

#### Audio Operations

- `audio_info <file>` - Display detailed audio information
  - Example: `audio_info song.mp3`

- `convert_audio <input> <output> [options]` - Convert audio format
  - Options:
    - `-b <bitrate>` - Set audio bitrate
    - `-c <channels>` - Set number of channels
  - Example: `convert_audio input.wav output.mp3 -b 320k`

### Image Processing (image.bashrc)

#### Basic Operations

- `image_info <file>` - Display detailed image information
  - Example: `image_info photo.jpg`

- `convert_image <input> <output> [options]` - Convert image format
  - Options:
    - `-q <quality>` - Set image quality (1-100)
    - `-r <width>x<height>` - Resize image
  - Example: `convert_image input.png output.jpg -q 90`

- `resize_image <input> <output> <size>` - Resize image
  - Size can be percentage or dimensions
  - Example: `resize_image photo.jpg thumb.jpg 50%`

#### Advanced Operations

- `optimize_image <input> [output]` - Optimize image size
  - Example: `optimize_image photo.jpg`

- `watermark <input> <watermark> <output> [options]` - Add watermark
  - Options:
    - `-p <position>` - Set watermark position
    - `-o <opacity>` - Set watermark opacity
  - Example: `watermark photo.jpg logo.png output.jpg -p center`

- `create_thumbnail <input> <output> <size>` - Create thumbnail
  - Example: `create_thumbnail photo.jpg thumb.jpg 200x200`

## Features

### File Management
- Progress bars for file operations
- Support for file numbers from list command
- Pattern matching for file operations
- Detailed file information display
- Flexible sorting and filtering options
- Support for both files and directories
- Timestamped backups
- EXIF date support for photos
- Duplicate file detection
- Empty directory cleanup
- Comprehensive test suite
- Backup of previous versions

### Media Processing
- Video format conversion
- Audio extraction and conversion
- Quality control options
- Detailed media information
- Batch processing support

### Image Processing
- Image format conversion
- Resizing and optimization
- Watermarking
- Thumbnail generation
- EXIF data handling

## Requirements

- Bash shell
- Basic Unix utilities (ls, find, stat, etc.)
- ffmpeg (for media processing)
- ImageMagick (for image processing)
- For EXIF support: exiftool (optional)

## License

MIT License

## Author

Your Name

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.