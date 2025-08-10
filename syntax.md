```eos

[[decorators]]
@compilation_tag
fn main: i32 {
    let foo: DArray<u8> = [8];
}

```

## Primitives

i8      or      char
i16     or      short
i32     or      int
i64     or      long

u8      or      unsigned char
u16     or      unsigned short
u32     or      unsigned int
u64     or      unsigned long

f32     or      float
f64     or      double

bool    or      true / false

voidptr

## Keywords

for:                can be used in a c style:
                        for(setup; exit condition; post loop execution) {}
                    can be used in a modern style:
                        for(idx in arr) {}
while:         can be used as:
                        while(condition) {}
                        {} while(condition)

if
else
else if

class:              structured data with implicitly related functions and private data fields
struct:             structured data without implicitly related functions
typealias:          alias a type to another name
fn:                 function
fnptr:              function pointer
let:                variable declarator

import:             import external functionality
enable:             enable a language feature, library ability, or compiler feature
disable:            disable a language feature, library ability, or compiler feature

trait:              define traits that a class must inherit
self (type):        referring to the type which inherits a trait
self (variable):    referring to the instance of the class which a function is being called from

## Operators
Mathematical:       + - * / = += -= *= /=
Incr / Decr:        ++ --
Bitwise:            & | ^ ~ << >> &= |= ^= <<= >>=
Comparison:         < > == <= >=
Logical Operators:  ! or and
Array:              [ ] { }
Scope:              { } ;
Type:               :
Pointer:            * &
String:             "
Character:          '
Generics:           < >
SL Comments:        //
ML Comments:        /* */
List separator:     ,
Access Modifier:    .
Target Tag:         @target
Trait Decorator:    [[trait]]

## Functions
All functions begin with the keyword 'fn' and have a return type specified after the parameters as such:
    fn function_name(param1: param1_type, param2: param2_type): return_type { }
Every parameter for a function must explicitly define its parameter type after each parameter
Function Pointer:   fnptr function_name(param1: param1_type, param2: param2_type): return_type;

## Mathematical Operators
All mathematical, increment, decrement, and bitwise operators work as they would in C on integer and floating
point data types

## Pointer / Memory address
Variables can hold pointers to data types (primitives, structs, and classes) using the syntax:
    let x: data_type* = &initialized_data
Here 'data_type*' refers to a pointer that points to data of type data_type and '&initialized_data'
refers to "take the address of the initialized variable 'initialized_data'"

## Target Tags
A target tag, defined by the syntax '@target' is a modifier that can be placed before a function, class,
struct, typealias, import statement, or scope to only define that item when being compiled for that target.
For example, a target tag such as:
    @linux
    import TimeSynchronization;
will only import 'TimeSynchronization' if linux is being targetted

If the target tag is on a scope such as:
    @windows {
        import WinLibrary;
        fn WindowsOnly(): void;
    }
then when compiling for windows everything will be moved to the parent scope as if it was:
    import WinLibrary;
    fn WindowsOnly(): void;

## Trait decorators
A trait decorator is a definition of a set of functionality that can be applied to a class. This is
similar to inheritance, but there can be no trait hierarchy. A trait decorator can be defined by:
    trait MyTrait {
        fn doSomething(x: self, y: int): void;
    }
Here, the trait named 'MyTrait' includes a function named 'doSomething', this function notably has a parameter
of type 'self' which is special to traits. When a trait function parameter has type 'self' then the class that
implements the trait must use that class type as the type for that parameter
