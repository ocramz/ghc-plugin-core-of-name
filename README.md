# core-of-name

[![CI](https://github.com/ocramz/ghc-plugin-core-of-name/actions/workflows/ci.yml/badge.svg)](https://github.com/ocramz/ghc-plugin-core-of-name/actions/workflows/ci.yml)

GHC plugin that prints the Core intermediate representation of annotated Haskell bindings during compilation.

Based on the technique described in
[Finding the Core of an expression using Template Haskell and a custom GHC Core plugin](https://ocramz.github.io/posts/2021-06-22-finding-core-th.html), which in turn was inspired by [`inspection-testing`](https://hackage.haskell.org/package/inspection-testing)

## Usage

In the module whose bindings you want to inspect, enable `TemplateHaskell` and the plugin, then call `coreOf` or `coreOfWith` after the binding:

### `coreOf` — print Core to stdout

```haskell
{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -fplugin=CoreOfName.Plugin #-}
module MyModule where

import CoreOfName.Types (coreOf)

f :: Double -> Double -> Double
f = \x y -> sqrt x + y

coreOf 'f
```

The Core representation of `f` will be printed interleaved with the normal compiler output during `stack build` / `cabal build`.

### `coreOfWith` — write Core to a file

Use `coreOfWith` to direct the output to a file instead of stdout with this shorthand:

```haskell
{-# LANGUAGE TemplateHaskell #-}
{-# language OverloadedStrings #-}
{-# OPTIONS_GHC -fplugin=CoreOfName.Plugin #-}
module MyModule where

import CoreOfName.Types (coreOfWith)

f :: Double -> Double -> Double
f = \x y -> sqrt x + y

coreOfWith "output.core" 'f
```

NB if two or more declarations use the same output file, the file will be _overwritten_. It is best to assign one Core output file per function.

The string literal is an `Options` value via the `IsString` instance and is equivalent to `OToFile "output.core"`.

### Explicit `Options`

You can also pass `Options` values directly:

```haskell
import CoreOfName.Types (coreOfWith, Options(..))

-- print to stdout (same as coreOf)
coreOfWith OPrintCore 'f

-- write to a file
coreOfWith (OToFile "output.core") 'f
```

## Building

```
stack clean && stack build
```
