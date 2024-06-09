# My Compiler Project

Welcome to my compiler project repository. This project involves building a compiler using OCaml, capable of parsing, analyzing, and generating assembly code from a given input.

## Table of Contents

- [General Information](#general-information)
- [Project Structure](#project-structure)
- [Features](#features)

## General Information

This project aims to develop a fully functional compiler. The compiler is designed to handle Scheme source files, parse them into an intermediate representation, perform necessary analysis, and generate x86 assembly code. The project involves significant coding in both OCaml and Assembly languages.

## Project Structure

The repository contains the following files and directories:

- `compiler.ml`: The main file containing the core implementation of the compiler.
- `README.md`: This file, providing an overview and instructions for the project.
- `Makefile`: A makefile for building the project (if applicable).
- `examples/`: A directory containing example Scheme source files for testing.
- `tests/`: A directory containing test cases to verify the compiler's functionality.

## Features

- **Parsing**: Converts Scheme source code into an intermediate representation.
- **Analysis**: Performs semantic analysis and optimizations on the intermediate representation.
- **Code Generation**: Generates x86 assembly code from the intermediate representation.
- **Testing**: Includes a suite of test cases to ensure the correctness and robustness of the compiler.
