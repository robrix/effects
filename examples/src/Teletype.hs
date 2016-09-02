{-# LANGUAGE GADTs #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DataKinds #-}
module Teletype where

import Control.Monad.Freer
import Control.Monad.Freer.Internal as I
import System.Exit hiding (ExitSuccess)

data Teletype s where
  PutStrLn    :: String -> Teletype ()
  GetLine     :: Teletype String
  ExitSuccess :: Teletype ()

-- Takes a string and returns a teletype effect.
putStrLn' :: (Teletype :< effs) => String -> Eff effs ()
putStrLn' = send . PutStrLn

-- Gets a line from a Teletype.
getLine'  :: (Teletype :< effs) => Eff effs String
getLine' = send GetLine

-- An exit success effect that returns ().
exitSuccess' :: (Teletype :< effs) => Eff effs ()
exitSuccess' = send ExitSuccess

-- Runs a Teletype effect b and returns IO b.
run :: Eff '[Teletype] a -> IO a
run (Val x) = return x
run (E u q) = case decomp u of
  Right (PutStrLn msg) -> putStrLn msg  >> Teletype.run (applyEffs q ())
  Right GetLine        -> getLine      >>= \s -> Teletype.run (applyEffs q s)
  Right ExitSuccess    -> exitSuccess
  Left  _              -> error "This cannot happen"

-- Takes a list of strings and a teletype effect to run and
-- returns the list of strings printed in that effect.
runPure :: [String] -> Eff '[Teletype] a -> [String]
runPure inputs req = reverse (go inputs req [])
  where go :: [String] -> Eff '[Teletype] w -> [String] -> [String]
        go _  (Val _) acc = acc
        go xs (E u q) acc = case xs of
          (x:xs') -> case decomp u of
            Right (PutStrLn msg) -> go (x:xs') (applyEffs q ()) (msg:acc)
            Right GetLine        -> go xs'     (applyEffs q x) acc
            Right ExitSuccess    -> go xs'     (Val ())   acc
            Left _               -> go xs'     (Val ())   acc
          _      -> case decomp u of
            Right (PutStrLn msg) -> go xs (applyEffs q ()) (msg:acc)
            _                    -> go xs     (Val ())   acc
