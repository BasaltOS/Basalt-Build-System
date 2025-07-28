#!/bin/bash

# === BUILD AREA START ===/

build_directory="build"
version=1
show_help() {
    echo "Usage: $0 [init|build|clean|help|reconfigure|version]"
    echo "Commands:"
    echo "  init        Initialize the build system"
    echo "  build       Build the project"
    echo "  clean       Clean the build artifacts"
    echo "  reconfigure Reconfigure the build system"
    echo "  version     Show the version of the Basalt build system"
    echo "  help        Show this help message"
}

case "${1:-}" in
    init)
        echo "Initializing the Basalt build system..."
        if [[ -e "build.basalt" ]]; then
            echo "Error: build.basalt already exists. Please remove it before initializing."
            exit 1
        fi
        echo "# Basalt build config" > build.basalt
        echo "build_system_version = $version" >> build.basalt
        echo "Initialization complete."
        ;;

    build)
        if [[ ! -f "build.basalt" ]]; then
            echo "build.basalt file not found. Please run 'init' first."
            exit 1
        fi

        configure_basalt && build_basalt && {
            echo "Build finished sucessfully!"
            exit 0
        } || {
            echo "Build failed"
            exit 1
        }
        ;;

    clean)
        echo "Cleaning the build artifacts..."
        if [[ ! -d $build_directory ]]; then
            echo "Build directory not found. Nothing to clean."
            exit 1
        fi
        rm -r "$build_directory"
        ;;

    reconfigure)
        echo "Reconfiguring the build system..."
        rm -r "$build_directory"
        configure_basalt
        ;;

    version)
        echo "Basalt Build System version $version"
        ;;

    help|*)
        show_help
        ;;
esac

# === BUILD AREA END ===/