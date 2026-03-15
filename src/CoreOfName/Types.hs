{-# LANGUAGE DeriveDataTypeable #-}
module CoreOfName.Types
  ( Target(..)
  , coreOf
  , Options(..)
  , defaultOptions
  , coreOfWith
  ) where

import Data.Data (Data)
import Data.String (IsString(..))
import Language.Haskell.TH (Name, AnnTarget(..), Pragma(..), Dec(..), Q)
import Language.Haskell.TH.Syntax (liftData)

-- | Annotation payload carrying the TH 'Name' of a binding whose
--   GHC Core representation we want to inspect.
data Target = MkTarget { 
  tgOptions :: Options
, tgName :: Name
} deriving (Data)

data Options = OPrintCore 
             | OToFile FilePath 
             deriving (Data)
instance IsString Options where
  fromString s = OToFile s

defaultOptions :: Options
defaultOptions = OPrintCore

-- | Template Haskell splice that attaches a module-level annotation
--   carrying the given 'Name'. Usage (in client module):
--
-- @
-- {-\# LANGUAGE TemplateHaskell \#-}
-- f :: Double -> Double -> Double
-- f = \\x y -> sqrt x + y
--
-- coreOf \'f
-- @
coreOf :: Name -> Q [Dec]
coreOf = coreOfWith defaultOptions

coreOfWith :: Options -> Name -> Q [Dec]
coreOfWith opts n = do
  annExpr <- liftData (MkTarget opts n)
  pure [PragmaD (AnnP ModuleAnnotation annExpr)]



