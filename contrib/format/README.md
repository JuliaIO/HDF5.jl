# JuliaFormatterTool

## Purpose

The purpose is this tool to aid in formatting the repository with JuliaFormatter.
Rather than starting a fresh Julia session each time you want to format, this will
run the formatter in a loop. Everytime you press enter, it will format the repository.
This avoids the initial delay when starting and loading the JuliaFormatter package.

The intended use of this program is to run in a separate terminal or be suspended
(e.g. via Control-Z) while you edit the repository. Resume the program (e.g. `fg`)
and press enter to format the repository before committing.

## Invocation

The format.jl script is meant to be executed directly.

On POSIX systems that understand shebang lines the format.jl can be invoked as follows.
```
./contrib/format/format.jl
```

Supplying the file as an argument to `julia` also works.

```
julia contrib/format/format.jl
```

The script will automatically install itself by resolving and instantiating its environment.
To bypass this install step, specify the project environment:

```
julia --project=contrib/format contrib/format.jl
```

## Example Usage

```
$ julia contrib/format/format.jl
  Activating project at `~/.julia/dev/HDF5/contrib/format`
  No Changes to `~/.julia/dev/HDF5/contrib/format/Project.toml`
  No Changes to `~/.julia/dev/HDF5/contrib/format/Manifest.toml`

Welcome to Julia Formatter Tool!
--------------------------------

Press enter to format the directory ~/.julia/dev/HDF5 or `q[enter]` to quit
format.jl>
Applying JuliaFormatter...
┌ Info: Is the current directory formatted?
│   target_dir = "~/.julia/dev/HDF5"
└   format(target_dir) = true

Press enter to format the directory ~/.julia/dev/HDF5 or `q[enter]` to quit
format.jl>
Applying JuliaFormatter...
┌ Info: Is the current directory formatted?
│   target_dir = "~/.julia/dev/HDF5"
└   format(target_dir) = true
```
