# bf2kernel

## What's Kernel?

When you have some experience with Dart, you know that it's a multiplatform language which can
be interpreted, compiled to JS (with two different compilers!) and native code.
With that many backends, you don't want to write an end-to-end compiler for each of them. Some work, like
parsing, type checking and resolving methods is completely independent of the backend, so
why do that multiple times? In Dart, a package called `front_end` is responsible to compile Dart
into an intermediate format called `Kernel`.
All compilers then take a Kernel component to do their work. 
For instance, when you run `dart some/script.dart`, what's actually happening is that

- the `front_end` package will read `script.dart` and its depencies and compile them to Kernel
- the `vm` package (not published to pub) will apply some VM-specific optimizations and create bytecode
  only understood by the Dart VM
- the VM then runs that bytecode, JIT-compiling parts to native code on the way

Since all compilers work with Kernel components, we can make use of all Dart backends if we write a `front_end` equivalent for Brainfuck.

__Note__: You might have heard about the `analyzer` package, which is the base for static
analysis and Dart IDEs. It also shares some parts with the frontend (such as the parser),
but is entirely independent otherwise.

## What's Brainfuck?

Brainfuck is a very simple language, which makes it suitable to experiment with
compilers. At runtime, a brainfuck program state consists of two variables:

- an array of integers to store data. It's up to us to define how large this should be,
  we'll use an `Int16List` from `dart:typed_data` with a lenght of ten thousand. We'll
  call this array `data` from now on.
- a single pointer which refers to an index into the array.

With that, a Brainfuck program is just a sequence of these characters:
- `>` increments the pointer by one
- `<` decrements the pointer by one
- `+` increments `data[pointer]` by one
- `-` decrements `data[pointer]` by one
- `.` outputs `data[pointer]` to stdout
- `,` reads a byte from stdin and stores it at `data[pointer]`

Here's a simple BF program, can you guess what it's doing?

```brainfuck
,[.,]
```

The first `,` will read a char from stdin and write it to `data[0]`. As long as
`data[0]` is not zero, we'll output that char and read another one. So, this
program will simply output it's input and stop when it's fed a `\0` char.

## This compiler

The compiler mainly consists of three files:

- `lib/src/parser.dart`: Parse a Brainfuck
- `lib/src/instructions.dart`: Classes to represent a Brainfuck program
- `lib/src/codegen.dart`: Compiles a Brainfuck program into an existing
   Kernel file from the Dart SDK

Another file, `bin/main.dart` loads the platform Kernel from the Dart SDK
and glues the steps together.

### Usage

After cloning this repo, you can run
```
$ dart bin/main.dart path/to/file.bf
```

It will write a `out.dill` into the current directory. That file can be run
with `dart out.dill`.