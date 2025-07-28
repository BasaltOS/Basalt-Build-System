# Basalt Build System Help

## Usage

```bash
./bbuild [init|build|clean|help|reconfigure|version]
```

## Commands

| Command       | Description                           |
| ------------- | ------------------------------------- |
| `init`        | Initialize the build system           |
| `build`       | Build the project                     |
| `clean`       | Clean the build artifacts             |
| `reconfigure` | Reconfigure the build system          |
| `version`     | Show the version of the Basalt system |
| `help`        | Show this help message                |

---

## Basalt Buildfile Format (`Basaltfile`)

### Syntax Notes

* Lines starting with `#` or `;` are comments.
* Statements are of the form `KEY = VALUE`.

### Variables

| Variable   | Description                                             |
| ---------- | ------------------------------------------------------- |
| `SOURCES`  | List of source files (e.g. `main.c util.c`)             |
| `CC`       | C compiler command (e.g. `gcc`), Default: gcc           |
| `CXX`      | C++ compiler command (e.g. `g++`), Default: g++         |
| `AS`       | Assembler command (e.g. `as`), Default: as              |
| `CFLAGS`   | Flags passed to the C compiler                          |
| `CXXFLAGS` | Flags passed to the C++ compiler                        |
| `ASFLAGS`  | Flags passed to the assembler                           |
| `LDFLAGS`  | Flags passed to the linker                              |
| `TYPE`     | Output type: `executable`, `shared`, `static`, `object` |
| `TARGET`   | Name of the resulting binary file (e.g. `myapp`)        |



---

Example:

```BasaltBuild
# This is comment
; This is comment also
SOURCES = main.c util.c

CC = gcc
CXX = g++
AS = as

# Flags
CFLAGS = -Wall -O2
CXXFLAGS = -Wall -O2
ASFLAGS =
LDFLAGS = -lm

TYPE = executable
TARGET = test
```
