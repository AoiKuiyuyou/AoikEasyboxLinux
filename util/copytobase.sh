#!/bin/bash

# Argument $1: copying's destination base directory.
# Argument $2: copying's source file path.

# Whether option "--ldd" is on
ldd_option_is_on=0

# Parse optional command line arguments
while true; do
    # If the argument starts with "-"
    if  [[ "$1" == -* ]] ; then
        # If the argument value is '--ldd'
        if [ "$1" = '--ldd' ]; then
            # Turn on the option
            ldd_option_is_on=1
        else
            # Message
            echo "Unknown argument: \"$1\"" >&2
        fi

        # Shift arguments
        shift

        # Continue to process next argument
        continue
    # Optional arguments are done.
    else
        break
    fi
done

# Get argument $1
base_dir_path="$1"

# If the argument is not given
if [ -z "$base_dir_path" ]; then
    # Message
    echo "Error: Argument \$1 (destination base directory) is not given.";

    # Exit
    exit 1
fi;

# Get argument $2
src_file_path="$2"

# If the file is not existing
if [ ! -e "$src_file_path" ]; then
    # Message
    echo "Error: Argument \$2 (source file path) is not existing: \"$src_file_path\"";

    # Exit
    exit 2
fi;

# Define file copying function
copy_file() {
    # $1: Source file path.

    # Get source file's dir path
    src_file_dir_path="`dirname "$1"`"

    # Make a new path, using the base directory as base

    # If the path starts with "/"
    if [[ "$src_file_dir_path" == /* ]] ; then
        dst_file_dir_path="${base_dir_path}${src_file_dir_path}"
    # If the path not starts with "/"
    else
        dst_file_dir_path="${base_dir_path}/${src_file_dir_path}"
    fi

    # If the directory is not existing
    if [ ! -d "$dst_file_dir_path" ]; then
        # Create the directory
        mkdir -pv "$dst_file_dir_path"

        # If return code is not ok
        if [ "$?" -ne 0 ]; then
            # Message
            echo "# Failed creating dir:  \"$src_file_dir_path\" -> \"$dst_file_dir_path\""

            # Exit
            exit 3
        fi
    fi

    # Get destination file path

    # If the path starts with "/"
    if [[ "$1" == /* ]] ; then
        dst_file_path="${base_dir_path}$1"
    # If the path not starts with "/"
    else
        dst_file_path="${base_dir_path}/$1"
    fi

    # Copy the file (recursively if it is a directory)
    cp -avfPT "$1" "$dst_file_path"
    #^ "-a": Copy directories recursively, preserve attributes.
    ## "-v": Verbose.
    ## "-f": Force.
    ## "-P": Copy symbolic files as-is, never dereference them.
    ## "-T": Treat destination file as if it is a normal file, not a directory to copy into.

    # If the source file is a symbolic link
    if [ -L "$1" ]; then
        # Get the link target path.
        # "ls" command's result is like:
        # /usr/bin/vim -> /etc/alternatives/vim'.
        link_target_path=$(ls -l "$1" | cut -d '>' -f 2 | cut -d ' ' -f 2)

        # If the link target path is an absolute path
        if [[ "$link_target_path" == /* ]] ; then
            # Use the absolute path as-is
            link_target_path_2="$link_target_path"
        # If the link target path is a relative path
        else
            # Resolve according to the source file path, not according to CWD.
            link_target_path_2="`dirname "$1"`/$link_target_path"
        fi
        #^ At this point, "link_target_path_2" is either absolute or relative
        ## to CWD.

        # Copy the link target file
        if [ -e "$link_target_path_2" ]; then
            copy_file "$link_target_path_2"
        else
            echo "WARNING: Invalid symbolic link: \"$1\" -> \"$link_target_path\""  >&2
        fi
    fi
}

# Define lib files copying function
copy_ldd_files() {
    # $1: Executable file path.

    #
    for lib_file_path in `ldd "$1" 2>/dev/null | grep -E -o '/[^ ]+'`; do
        # ldd /bin/bash
        # Result is like:
        # linux-vdso.so.1 =>  (0x00007ffd62a1c000)
        # libtinfo.so.5 => /lib/x86_64-linux-gnu/libtinfo.so.5 (0x00007f32abdcd000)
        # libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007f32abbc9000)
        # libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f32ab804000)
        # /lib64/ld-linux-x86-64.so.2 (0x00007f32abff6000)
        #
        # grep -E -o '/[^ ]+'
        # "-E": enable "extended regular expression" to support "+" syntax.
        # "-o": output only matched part.
        # '/[^ ]+': starting with a "/", followed by one or more non-space
        #           characters.
        # Result is:
        # /lib/x86_64-linux-gnu/libtinfo.so.5
        # /lib/x86_64-linux-gnu/libdl.so.2
        # /lib/x86_64-linux-gnu/libc.so.6
        # /lib64/ld-linux-x86-64.so.2
        #
        copy_file "$lib_file_path"
    done
}

# Copy the file
copy_file "$src_file_path"

# If option "--ldd" is on
if [ "$ldd_option_is_on" -eq 1 ]; then
    # If the file is a regular file (potentially an executable)
    if [ -f "$src_file_path" ]; then
        # Copy lib files detected by ldd
        copy_ldd_files "$src_file_path"
    fi
fi
