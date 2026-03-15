{-# LANGUAGE LambdaCase #-}
module CoreOfName.Plugin
  ( plugin
  ) where

import Control.Monad.IO.Class (liftIO)
import Data.Foldable (traverse_)

import GHC.Plugins
  ( Plugin(..), defaultPlugin, CommandLineOption
  , fromSerialized, deserializeWithData
  , ModGuts(..), Name, CoreExpr, Var
  , flattenBinds, getName, thNameToGhcName
  , PluginRecompile(..)
  )
import GHC.Core.Opt.Monad (CoreM, putMsgS, getDynFlags)
import GHC.Core.Opt.Pipeline.Types (CoreToDo(..))
import GHC.Driver.Ppr (showSDoc)
import GHC.Types.Annotations (Annotation(..))
import GHC.Utils.Outputable (ppr)
import qualified Language.Haskell.TH.Syntax as TH (Name)

import CoreOfName.Types (Target(..), Options(..))

-- | The GHC plugin entry point. Appends a Core-to-Core pass that
--   finds annotated bindings and prints their Core representation.
plugin :: Plugin
plugin = defaultPlugin
  { installCoreToDos = install
  , pluginRecompile  = \_ -> pure NoForceRecompile
  }

-- | Append our plugin pass at the end of the Core pipeline
install :: [CommandLineOption] -> [CoreToDo] -> CoreM [CoreToDo]
install cliOpts todos = pure (todos ++ [pass])
  where
    pass = CoreDoPluginPass "CoreOfName" $ \guts -> do
      let (guts', targets) = extractTargets guts
      liftIO $ putStrLn $ unwords ["CLI options:", show cliOpts, "| Found", show (length targets), "targets"]
      traverse_ (printCore guts') targets
      pure guts'


-- | Pretty-print the Core representation of the binding with the
--   given TH 'Name'.
printCore :: ModGuts -> Target -> CoreM ()
printCore guts target = do
  let 
    thn = tgName target
    thOpts = tgOptions target
  mn <- lookupTHName guts thn
  case mn of
    Just (_, coreExpr) -> do
      dflags <- getDynFlags
      case thOpts of
        OPrintCore -> putMsgS $ showSDoc dflags (ppr coreExpr)
        OToFile fp -> liftIO $ writeFile fp (showSDoc dflags (ppr coreExpr))
    Nothing ->
      putMsgS $ "CoreOfName: Cannot find name " ++ show thn

-- | Resolve a TH 'Name' to a GHC 'Name' and look it up in the
--   module's Core bindings.
lookupTHName :: ModGuts -> TH.Name -> CoreM (Maybe (Var, CoreExpr))
lookupTHName guts thn = thNameToGhcName thn >>= \case
  Nothing -> do
    putMsgS $ "CoreOfName: Could not resolve TH name " ++ show thn
    pure Nothing
  Just n -> pure $ lookupNameInGuts n
  where
    lookupNameInGuts :: Name -> Maybe (Var, CoreExpr)
    lookupNameInGuts n =
      case [ (v, e) | (v, e) <- flattenBinds (mg_binds guts), getName v == n ] of
        (hit:_) -> Just hit
        []      -> Nothing

-- | Decode 'Target' annotations from the module guts, returning
--   cleaned guts (annotations consumed) and the list of targets.
extractTargets :: ModGuts -> (ModGuts, [Target])
extractTargets guts = (guts', targets)
  where
    (anns_clean, targets) = partitionMaybe findTargetAnn (mg_anns guts)
    guts' = guts { mg_anns = anns_clean }
    findTargetAnn (Annotation _ payload) =
      fromSerialized deserializeWithData payload

-- | Partition a list using a function that returns 'Just' for
--   elements to collect and 'Nothing' for elements to keep.
partitionMaybe :: (a -> Maybe b) -> [a] -> ([a], [b])
partitionMaybe _ [] = ([], [])
partitionMaybe f (x:xs) = case f x of
  Nothing -> (x : as, bs)
  Just b  -> (as, b : bs)
  where (as, bs) = partitionMaybe f xs