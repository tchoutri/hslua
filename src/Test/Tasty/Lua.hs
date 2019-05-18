{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-|
Module      : Test.Tasty.Lua
Copyright   : © 2019 Albert Krewinkel
License     : MIT
Maintainer  : Albert Krewinkel <albert+hslua@zeitkraut.de>
Stability   : alpha
Portability : Requires TemplateHaskell

Convert Lua test results into a tasty test trees.
-}
module Test.Tasty.Lua
  ( -- * Lua module
    pushModule
    -- * Running tests
  , testLuaFile
  , translateResultsFromFile
    -- * Helpers
  , pathFailure
  )
where

import Control.Exception (SomeException, try)
import Data.List (intercalate)
import Foreign.Lua (Lua)
import Test.Tasty.Lua.Module (pushModule)
import Test.Tasty.Lua.Core (Outcome (..), ResultTree (..), UnnamedTree (..),
                            runTastyFile)
import Test.Tasty.Lua.Translate (pathFailure, translateResultsFromFile)
import qualified Test.Tasty as Tasty
import qualified Test.Tasty.Providers as Tasty

-- | Run the given file as a single test. It is possible to use
-- `tasty.lua` in the script. This test collects and summarizes all
-- errors, but shows generally no information on the successful tests.
testLuaFile :: (forall a . Lua a -> IO a)
             -> Tasty.TestName
             -> FilePath
             -> Tasty.TestTree
testLuaFile runLua name fp =
  let testAction = TestCase $ do
        result <- runLua (runTastyFile fp)
        return $ case result >>= failuresMessage of
          Left errMsg -> Failure errMsg
          Right ()    -> Success
  in Tasty.singleTest name testAction

-- | Lua test case action
newtype TestCase = TestCase (IO Outcome)

instance Tasty.IsTest TestCase where
  run _ (TestCase action) _ = do
    result <- try action
    return $ case result of
      Left (e :: SomeException) -> Tasty.testFailed (show e)
      Right (Failure msg)       -> Tasty.testFailed msg
      Right Success             -> Tasty.testPassed ""

  testOptions = return []

-- | Generate a single error message from all failures in a test tree.
failuresMessage :: [ResultTree] -> Either String ()
failuresMessage tree =
  let messages = concatMap collectFailureMessages tree
  in case messages of
    []   -> return ()
    errs -> Left $ concatMap stringifyFailureGist errs

-- | Failure message generated by tasty.lua
type LuaErrorMessage = String
-- | Info about a test failure
type FailureGist = ([Tasty.TestName], LuaErrorMessage)

-- | Convert a test failure, given as the pair of the test's path and
-- its error message, into an error string.
stringifyFailureGist :: FailureGist -> String
stringifyFailureGist (names, msg) =
  intercalate " // " names ++ ":\n" ++ msg ++ "\n\n"

-- | Extract all failures from a test result tree.
collectFailureMessages :: ResultTree -> [FailureGist]
collectFailureMessages (ResultTree name tree) =
  case tree of
    SingleTest Success       -> []
    SingleTest (Failure msg) -> [([name], msg)]
    TestGroup subtree        -> concatMap collectFailureMessages subtree
