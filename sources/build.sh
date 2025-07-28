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
    for tool in cc cxx ld as ar; do
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

    for entry in "${changed_files[@]}"; do
        src_file="${entry%%:*}"  # część przed ':'
        lang="${entry##*:}"      # część po ':'
        obj_file="$build_directory/$(basename "${src_file%.*}").o"

        case "$lang" in
            c)
                c_files=$((c_files + 1))
                $CC -c $CFLAGS -o "$obj_file" "$src_file"
                ;;
            cxx)
                cxx_files=$((cxx_files + 1))
                $CXX -c $CXXFLAGS -o "$obj_file" "$src_file"
                ;;
            as)
                as_files=$((as_files + 1))
                $AS -c $ASFLAGS -o "$obj_file" "$src_file"
                ;;
            *)
                echo "Unknown language '$lang' for file $src_file"
                exit 1
                ;;
        esac
    done

    object_files=$(find "$build_directory" -type f -name '*.o')

    if [[ $APP_TYPE == "executable" ]]; then
        if (( cxx_files > 0 )); then
            $CXX -o "$build_directory/$target" $object_files
        else
            $CC -o "$build_directory/$target" $object_files
        fi
    elif [[ $APP_TYPE == "sharedlib" ]]; then
        if (( cxx_files > 0 )); then
            $CXX $LDFLAGS -shared -o "$build_directory/lib$target.so" $object_files
        else
            $CC $LDFLAGS -shared -o "$build_directory/lib$target.so" $object_files
        fi
    elif [[ $APP_TYPE == "staticlib" ]]; then
        $AR rcs "$build_directory/lib$target.a" $object_files
    else
        echo "Undefined app type: $APP_TYPE"
        exit 1
    fi
}

# === BUILD AREA END ===/
