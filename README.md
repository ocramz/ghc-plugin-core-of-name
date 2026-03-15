# core-of-name

A GHC plugin that prints the Core intermediate representation of annotated Haskell bindings during compilation.

Based on the technique described in
[Finding the Core of an expression using Template Haskell and a custom GHC Core plugin](https://ocramz.github.io/posts/2021-06-22-finding-core-th.html)

## Usage

1. Add `core-of-name` to your `build-depends`.
2. In the module whose bindings you want to inspect:

```haskell
{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -fplugin=CoreOfName.Plugin #-}
module MyModule where

import CoreOfName.Types (inspect)

f :: Double -> Double -> Double
f = \x y -> sqrt x + y

inspect 'f
```

3. Build (`stack build` or `cabal build`). The Core representation of `f`
   will be printed interleaved with the normal compiler output.

## Building

```
stack clean && stack build
```
