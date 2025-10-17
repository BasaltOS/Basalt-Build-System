#!/bin/bash

build_directory="build"

# === BUILD AREA START ===/

build_basalt() {
    changed_files=()

    while read -r old_timestamp src_file lang; do
        obj_file="${build_directory}/$(basename "${src_file%.*}").o"

        if [[ ! -f "$src_file" ]]; then
            echo "File missing: $src_file"
            changed_files+=("$src_file:$lang")
            continue
        fi

        current_timestamp=$(stat -c %Y "$src_file")
        if [[ "$current_timestamp" != "$old_timestamp" ]] || [[ ! -f "$obj_file" ]]; then
            changed_files+=("$src_file:$lang")
        fi
    done < "$build_directory/.basalt_sources"

    if [[ ${#changed_files[@]} -eq 0 ]]; then
        exit 5
    fi

    target=$(<$build_directory/.basalt_target)

    # Domyślne narzędzia
    CC="gcc"
    CXX="g++"
    AS="as"
    AR="ar"

    # Przesłanianie narzędzi jeśli zdefiniowane
    for tool in cc cxx as ar; do
        tool_path="$build_directory/.basalt_tools/$tool"
        if [[ -f "$tool_path" ]]; then
            value="$(<"$tool_path")"
            eval "${tool^^}=\"\$value\""
        fi
    done

    # Typ aplikacji
    type_file="$build_directory/.basalt_type"
    if [[ -f "$type_file" ]]; then
        APP_TYPE="$(<"$type_file")"
    else
        echo "App type doesn't exist"
        return 1
    fi

    c_files=0
    cxx_files=0
    as_files=0
    if [[ -f "$build_directory/.basalt_flags/cflags" ]]; then
        read -r -a CFLAGS < "$build_directory/.basalt_flags/cflags"
    fi
    if [[ -f "$build_directory/.basalt_flags/cxxflags" ]]; then
        read -r -a CXXFLAGS < "$build_directory/.basalt_flags/cxxflags"
    fi    
    if [[ -f "$build_directory/.basalt_flags/asflags" ]]; then
        read -r -a ASFLAGS < "$build_directory/.basalt_flags/asflags"
    fi

    for entry in "${changed_files[@]}"; do
        src_file="${entry%%:*}"  # część przed ':'
        lang="${entry##*:}"      # część po ':'
        obj_file="$build_directory/$(basename "${src_file%.*}").o"

        case "$lang" in
            c)
                c_files=$((c_files + 1))
                $CC -c -o "$obj_file" "$src_file" $CFLAGS
                ;;
            cxx)
                cxx_files=$((cxx_files + 1))
                $CXX -c -o "$obj_file" "$src_file" $CXXFLAGS
                ;;
            as)
                as_files=$((as_files + 1))
                $AS -c -o "$obj_file" "$src_file" $ASFLAGS
                ;;
            *)
                echo "Unknown language '$lang' for file $src_file"
                exit 1
                ;;
        esac
    done

    object_files=$(find "$build_directory" -type f -name '*.o')

    read -r -a LDFLAGS < "$build_directory/.basalt_flags/ldflags"
    if [[ $APP_TYPE == "executable" ]]; then
        if (( cxx_files > 0 )); then
            $CXX -o "$build_directory/$target" $object_files $LDFLAGS
        else
            $CC -o "$build_directory/$target" $object_files $LDFLAGS
        fi
    elif [[ $APP_TYPE == "shared" ]]; then
        if (( cxx_files > 0 )); then
            $CXX -shared -o "$build_directory/$target.so" $object_files $LDFLAGS
        else
            $CC -shared -o "$build_directory/$target.so" $object_files $LDFLAGS
        fi
    elif [[ $APP_TYPE == "static" ]]; then
        $AR rcs "$build_directory/$target.a" $object_files
    elif [[ $APP_TYPE == "object" ]]; then
        :
    else
        echo "Undefined app type: $APP_TYPE"
        exit 1
    fi

    while IFS= read -r subdir; do
        if [[ -d "$subdir" ]]; then
            echo "Entering subdirectory: $subdir"
            cd "$subdir" || {
                echo "ERROR: Failed to cd into $subdir" >&2
                continue
            }

            script_name=$(basename "$0")
            script_dir=$(dirname "$0")

            if [[ "$script_dir" == "." ]]; then
                # uruchomiono jako ./build.sh
                cmd="../$script_name build"
            else
                # uruchomiono jako /usr/bin/build lub z PATH
                cmd="$script_name build"
            fi

            echo "-> Running: $cmd"
            $cmd || echo "WARNING: Subdirectory build failed in $subdir" >&2

            cd - > /dev/null || exit 1
        else
            echo "WARNING: Subdirectory '$subdir' is not a directory." >&2
        fi
    done < "$build_directory/.basalt_subdirectories"


    }

# === BUILD AREA END ===/
