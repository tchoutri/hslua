{-
Copyright © 2017-2018 Albert Krewinkel

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
-}
{-# LANGUAGE OverloadedStrings #-}
{-|
Module      :  Foreign.Lua.Types.PushableTest
Copyright   :  © 2017-2018 Albert Krewinkel
License     :  MIT

Maintainer  :  Albert Krewinkel <tarleb+hslua@zeitkraut.de>
Stability   :  stable
Portability :  portable

Test for the interoperability between haskell and lua.
-}
module Foreign.Lua.Types.PushableTest (tests) where

import Data.ByteString (ByteString)
import Foreign.Lua (Pushable (push), gettop, equal, nthFromTop)
import Foreign.StablePtr (castStablePtrToPtr, freeStablePtr, newStablePtr)

import Test.HsLua.Arbitrary ()
import Test.HsLua.Util (pushLuaExpr)
import Test.QuickCheck (Property)
import Test.QuickCheck.Instances ()
import Test.QuickCheck.Monadic (monadicIO, run, assert)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (Assertion, assertBool, testCase)
import Test.Tasty.QuickCheck (testProperty)

import qualified Foreign.Lua as Lua

-- | Specifications for Attributes parsing functions.
tests :: TestTree
tests = testGroup "Pushable"
  [ testGroup "pushing simple values to the stack"
    [ testCase "Boolean can be pushed correctly" $
      assertLuaEqual "true was not pushed"
        True
        "true"

    , testCase "Lua.Numbers can be pushed correctly" $
      assertLuaEqual "5::Lua.Number was not pushed"
        (5 :: Lua.Number)
        "5"

    , testCase "Lua.Integers can be pushed correctly" $
      assertLuaEqual "42::Lua.Integer was not pushed"
        (42 :: Lua.Integer)
        "42"

    , testCase "ByteStrings can be pushed correctly" $
      assertLuaEqual "string literal was not pushed"
        ("Hello!" :: ByteString)
        "\"Hello!\""

    , testCase "Unit is pushed as nil" $
      assertLuaEqual "() was not pushed as nil"
        ()
        "nil"

    , testCase "Pointer is pushed as light userdata" $
      let luaOp = do
            stblPtr <- Lua.liftIO $ newStablePtr (Just "5" :: Maybe String)
            push (castStablePtrToPtr stblPtr)
            res <- Lua.islightuserdata (-1)
            Lua.liftIO $ freeStablePtr stblPtr
            return res
      in assertBool "pointers must become light userdata" =<< Lua.run luaOp
    ]

  , testGroup "pushing a value increases stack size by one"
    [ testProperty "Lua.Integer"
      (prop_pushIncrStackSizeByOne :: Lua.Integer -> Property)
    , testProperty "Lua.Number"
      (prop_pushIncrStackSizeByOne :: Lua.Number -> Property)
    , testProperty "ByteString"
      (prop_pushIncrStackSizeByOne :: ByteString -> Property)
    , testProperty "String"
      (prop_pushIncrStackSizeByOne :: String -> Property)
    , testProperty "list of booleans"
      (prop_pushIncrStackSizeByOne :: [Bool] -> Property)
    ]
  ]

-- | Takes a message, haskell value, and a representation of that value as lua
-- string, assuming that the pushed values are equal within lua.
assertLuaEqual :: Pushable a => String -> a -> ByteString -> Assertion
assertLuaEqual msg x lit = assertBool msg =<< Lua.run
   (pushLuaExpr lit
   *> push x
   *> equal (nthFromTop 1) (nthFromTop 2))

prop_pushIncrStackSizeByOne :: Pushable a => a -> Property
prop_pushIncrStackSizeByOne x = monadicIO $ do
  (oldSize, newSize) <- run $ Lua.run ((,) <$> gettop <*> (push x *> gettop))
  assert (newSize == succ oldSize)