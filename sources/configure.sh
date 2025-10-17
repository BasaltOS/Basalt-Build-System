#!/bin/bash

build_directory="build"

# === BUILD AREA START ===/

# sources_file_preparation() {

# }

# Detect language based on file extension
detect_language() {
    local filename="$1"
    local ext="${filename##*.}"  # extract extension

    case "$ext" in
        c)
            echo "c"
            ;;
        cpp|cc|cxx|C)
            echo "cxx"
            ;;
        s|S|asm)
            echo "as"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

infer_type_from_target() {
    local filename="$1"
    local ext="${filename##*.}"  # extract extension

    case "$ext" in
        so)
            echo "shared"
            ;;
        a)
            echo "static"
            ;;
        o)
            echo "object"
            ;;
        *)
            echo "executable"
            ;;
    esac
}


configure_basalt() {
    md5_file="$build_directory/.config_md5sum"

    # Create build directory if it doesn't exist
    if [[ ! -d "$build_directory" ]]; then
        mkdir -p "$build_directory"
    fi

    # Compute md5 of build.basalt
    current_md5=$(md5sum "build.basalt" | cut -d ' ' -f1)
    old_md5=""

    if [[ -f "$md5_file" ]]; then
        old_md5=$(cat "$md5_file")
    fi

    cc_line=$(grep -E '^[[:space:]]*CC[[:space:]]*=' "build.basalt" | sed 's/[[:space:]]*#[^;]*//g')
    cc=$(echo "$cc_line" | cut -d '=' -f2 | tr -d '[:space:]')

    if [[ ! -z "$cc" ]]; then
        mkdir -p "$build_directory/.basalt_tools/"

        echo "$cc" > "$build_directory/.basalt_tools/cc" 

    fi

    cflags_line=$(grep -E '^[[:space:]]*CFLAGS[[:space:]]*=' "build.basalt" | sed 's/[[:space:]]*#[^;]*//g')
    cflags=$(echo "$cflags_line" | cut -d '=' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [[ ! -z "$cflags" ]]; then
        mkdir -p "$build_directory/.basalt_flags/"

        echo "$cflags" > "$build_directory/.basalt_flags/cflags" 

    fi

    cxx_line=$(grep -E '^[[:space:]]*CXX[[:space:]]*=' "build.basalt" | sed 's/[[:space:]]*#[^;]*//g')
    cxx=$(echo "$cxx_line" | cut -d '=' -f2 | tr -d '[:space:]')

    if [[ ! -z "$cxx" ]]; then
        mkdir -p "$build_directory/.basalt_tools/"

        echo "$cxx" > "$build_directory/.basalt_tools/cxx" 

    fi

    cxxflags_line=$(grep -E '^[[:space:]]*CXXFLAGS[[:space:]]*=' "build.basalt" | sed 's/[[:space:]]*#[^;]*//g')
    cxxflags=$(echo "$cxxflags_line" | cut -d '=' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [[ ! -z "$cxxflags" ]]; then
        mkdir -p "$build_directory/.basalt_flags/"

        echo "$cxxflags" > "$build_directory/.basalt_flags/cxxflags" 

    fi

    as_line=$(grep -E '^[[:space:]]*LD[[:space:]]*=' "build.basalt" | sed 's/[[:space:]]*#[^;]*//g')
    as=$(echo "$as_line" | cut -d '=' -f2 | tr -d '[:space:]')

    if [[ ! -z "$as" ]]; then
        mkdir -p "$build_directory/.basalt_tools/"

        echo "$as" > "$build_directory/.basalt_tools/as" 

    fi

    asflags_line=$(grep -E '^[[:space:]]*ASFLAGS[[:space:]]*=' "build.basalt" | sed 's/[[:space:]]*#[^;]*//g')
    asflags=$(echo "$asflags_line" | cut -d '=' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [[ ! -z "$asflags" ]]; then
        mkdir -p "$build_directory/.basalt_flags/"

        echo "$asflags" > "$build_directory/.basalt_flags/asflags" 

    fi

    ar_line=$(grep -E '^[[:space:]]*LD[[:space:]]*=' "build.basalt" | sed 's/[[:space:]]*#[^;]*//g')
    ar=$(echo "$ar_line" | cut -d '=' -f2 | tr -d '[:space:]')

    if [[ ! -z "$ar" ]]; then
        mkdir -p "$build_directory/.basalt_tools/"

        echo "$ar" > "$build_directory/.basalt_tools/ar" 

    fi

    ldflags_line=$(grep -E '^[[:space:]]*CFLAGS[[:space:]]*=' "build.basalt" | sed 's/[[:space:]]*#[^;]*//g')
    ldflags=$(echo "$ldflags_line" | cut -d '=' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [[ ! -z "$ldflags" ]]; then
        mkdir -p "$build_directory/.basalt_flags/"

        echo "$ldflags" > "$build_directory/.basalt_flags/ldflags" 

    fi

    target_line=$(grep -E '^[[:space:]]*TARGET[[:space:]]*=' "build.basalt" | sed 's/[[:space:]]*#[^;]*//g')
    target=$(echo "$target_line" | cut -d '=' -f2 | tr -d '[:space:]')

    if [[ ! -z "$target" ]]; then
        echo "$target" > "$build_directory/.basalt_target"
        echo "$(infer_type_from_target $target)" > "$build_directory/.basalt_type" 

    fi

    type_line=$(grep -E '^[[:space:]]*TYPE[[:space:]]*=' "build.basalt" | sed 's/[[:space:]]*#[^;]*//g')
    type=$(echo "$type_line" | cut -d '=' -f2 | tr -d '[:space:]')

    if [[ ! -z "$type" ]]; then

        if [[ "$type" == "executable" ]]; then
            echo "$type" > "$build_directory/.basalt_type"
        elif [[ "$type" == "staticlib" ]]; then
            echo "$type" > "$build_directory/.basalt_type"
        elif [[ "$type" == "sharedlib" ]]; then
            echo "$type" > "$build_directory/.basalt_type"
        elif [[ "$type" == "object" ]]; then
            echo "$type" > "$build_directory/.basalt_type"
        else
            echo "Bad type of project"
        fi

    fi

    # Re-parse if md5 changed or no previous md5
    if [[ "$current_md5" != "$old_md5" ]]; then
        echo "Build config changed. Re-parsing..."

        sources_line=$(grep -E '^[[:space:]]*SOURCES[[:space:]]*=' "build.basalt" | sed 's/[[:space:]]*#[^;]*//g')
        sources_raw=$(echo "$sources_line" | cut -d '=' -f2-)

        IFS=';' read -ra source_array <<< "$sources_raw"

        echo -n > "$build_directory/.basalt_sources"

        for src in "${source_array[@]}"; do
            src=$(echo "$src" | xargs)

            if [[ "$src" == \$\(*\) ]]; then
                glob_pattern=$(echo "$src" | sed -E 's/^\$\((.*)\)$/\1/')
                for file in $glob_pattern; do
                    if [[ -f "$file" ]]; then
                        timestamp=$(stat -c %Y "$file")
                        language=$(detect_language "$file")
                        echo "$timestamp $file $language" >> "$build_directory/.basalt_sources"
                    else
                        echo "WARNING: Globbed file '$file' does not exist." >&2
                    fi
                done
            elif [[ -f "$src" ]]; then
                timestamp=$(stat -c %Y "$src")
                language=$(detect_language "$src")
                echo "$timestamp $src $language" >> "$build_directory/.basalt_sources"
            else
                echo "WARNING: Source file '$src' does not exist." >&2
            fi
        done

        subdirs_line=$(grep -E '^[[:space:]]*SUBDIRECTORY[[:space:]]*=' "build.basalt" | sed 's/[[:space:]]*#[^;]*//g')
        subdirs_raw=$(echo "$subdirs_line" | cut -d '=' -f2-)
        IFS=';' read -ra subdir_array <<< "$subdirs_raw"

        echo -n > "$build_directory/.basalt_subdirectories"

        for dir in "${subdir_array[@]}"; do
            dir=$(echo "$dir" | xargs)
            if [[ -d "$dir" ]]; then
                realpath=$(realpath "$dir")
                echo "$realpath" >> "$build_directory/.basalt_subdirectories"
            else
                echo "WARNING: Subdirectory '$dir' does not exist." >&2
            fi
        done



        echo "$current_md5" > "$md5_file"

        if [[ ! -f "$build_directory/.basalt_target" ]]; then
            echo "ERROR: Target not set." 
        fi
    else
        echo "Build config unchanged."
    fi
}


# === BUILD AREA END ===/

configure_basalt