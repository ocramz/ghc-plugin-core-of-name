{-# LANGUAGE TemplateHaskell #-}
{-# language OverloadedStrings #-}
{-# OPTIONS_GHC -fplugin=CoreOfName.Plugin #-}
module Main (main) where

import CoreOfName.Types (coreOf, coreOfWith, Options(..))

-- Try building with either type signature for different Core output:
-- f :: Double -> Double -> Double   -- gives unboxed primops
f :: Floating a => a -> a -> a    -- gives dictionary-passing style
f = \x y -> sqrt x + y

coreOfWith "test.core" 'f
-- coreOf 'f

main :: IO ()
main = putStrLn "Plugin ran at compile time — see build output for Core of 'f'"
