{-# LANGUAGE PatternSynonyms #-}
{-|
Module      : Foreign.Lua.Constants
Copyright   : © 2007–2012 Gracjan Polak;
              © 2012–2016 Ömer Sinan Ağacan;
              © 2017-2021 Albert Krewinkel
License     : MIT
Maintainer  : Albert Krewinkel <tarleb+hslua@zeitkraut.de>
Stability   : beta
Portability : ForeignFunctionInterface

Lua constants
-}
module Foreign.Lua.Constants
  ( multret
  , registryindex
  , refnil
  , noref
    -- * Garbage-collection options
  , pattern LUA_GCSTOP
  , pattern LUA_GCRESTART
  , pattern LUA_GCCOLLECT
  , pattern LUA_GCCOUNT
  , pattern LUA_GCCOUNTB
  , pattern LUA_GCSTEP
  , pattern LUA_GCSETPAUSE
  , pattern LUA_GCSETSTEPMUL
  , pattern LUA_GCISRUNNING
  ) where

#include "lua.h"

import Foreign.C (CInt (..))
import Foreign.Lua.Types

-- | Alias for C constant @LUA_MULTRET@. See
-- <https://www.lua.org/manual/5.3/#lua_call lua_call>.
foreign import capi unsafe "lua.h value LUA_MULTRET"
  multret :: NumResults

-- | Alias for C constant @LUA_REGISTRYINDEX@. See
-- <https://www.lua.org/manual/5.3/#3.5 Lua registry>.
foreign import capi unsafe "lua.h value LUA_REGISTRYINDEX"
  registryindex :: StackIndex

-- | Value signaling that no reference was created.
foreign import capi unsafe "lauxlib.h value LUA_REFNIL"
  refnil :: Int

-- | Value signaling that no reference was found.
foreign import capi unsafe "lauxlib.h value LUA_NOREF"
  noref :: Int

--
-- Garbage-collection options
--

-- | Stops the garbage collector.
pattern LUA_GCSTOP :: GCCode
pattern LUA_GCSTOP = GCCode #{const LUA_GCSTOP}

-- | Restarts the garbage collector.
pattern LUA_GCRESTART :: GCCode
pattern LUA_GCRESTART = GCCode #{const LUA_GCRESTART}

-- | Performs a full garbage-collection cycle.
pattern LUA_GCCOLLECT :: GCCode
pattern LUA_GCCOLLECT = GCCode #{const LUA_GCCOLLECT}

-- | Returns the current amount of memory (in Kbytes) in use by Lua.
pattern LUA_GCCOUNT :: GCCode
pattern LUA_GCCOUNT = GCCode #{const LUA_GCCOUNT}

-- | Returns the remainder of dividing the current amount of bytes of
-- memory in use by Lua by 1024.
pattern LUA_GCCOUNTB :: GCCode
pattern LUA_GCCOUNTB = GCCode #{const LUA_GCCOUNTB}

-- | Performs an incremental step of garbage collection.
pattern LUA_GCSTEP :: GCCode
pattern LUA_GCSTEP = GCCode #{const LUA_GCSTEP}

-- | Sets data as the new value for the pause of the collector (see
-- §2.5) and returns the previous value of the pause.
pattern LUA_GCSETPAUSE :: GCCode
pattern LUA_GCSETPAUSE = GCCode #{const LUA_GCSETPAUSE}

-- | Sets data as the new value for the step multiplier of the collector
-- (see §2.5) and returns the previous value of the step multiplier.
pattern LUA_GCSETSTEPMUL :: GCCode
pattern LUA_GCSETSTEPMUL = GCCode #{const LUA_GCSETSTEPMUL}

-- | Returns a boolean that tells whether the collector is running
-- (i.e., not stopped).
pattern LUA_GCISRUNNING :: GCCode
pattern LUA_GCISRUNNING = GCCode #{const LUA_GCISRUNNING}