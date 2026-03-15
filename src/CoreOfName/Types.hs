{-# LANGUAGE DeriveDataTypeable #-}
module CoreOfName.Types
  ( Target(..)
  , inspect
  ) where

import Data.Data (Data)
import Language.Haskell.TH (Name, AnnTarget(..), Pragma(..), Dec(..), Q)
import Language.Haskell.TH.Syntax (liftData)

-- | Annotation payload carrying the TH 'Name' of a binding whose
--   GHC Core representation we want to inspect.
data Target = MkTarget { tgName :: Name } deriving (Data)

-- | Template Haskell splice that attaches a module-level annotation
--   carrying the given 'Name'. Usage (in client module):
--
-- @
-- {-\# LANGUAGE TemplateHaskell \#-}
-- f :: Double -> Double -> Double
-- f = \\x y -> sqrt x + y
--
-- inspect \'f
-- @
inspect :: Name -> Q [Dec]
inspect n = do
  annExpr <- liftData (MkTarget n)
  pure [PragmaD (AnnP ModuleAnnotation annExpr)]
