{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeOperators #-}
module NonDetEff where

import Control.Applicative
import Control.Monad
import Control.Monad.Effect
import Control.Monad.Effect.NonDetEff

ifte :: (NonDetEff :< r)
     => Eff r a -> (a -> Eff r b) -> Eff r b -> Eff r b
ifte t th el = (t >>= th) <|> el

testIfte :: (NonDetEff :< r) => Eff r Int
testIfte = do
  n <- gen
  ifte (do d <- gen
           guard $ d < n && n `mod` d == 0)
       (const mzero)
       (return n)
  where gen = msum . fmap return $ [2..30]

testIfteRun :: [Int]
testIfteRun = run . makeChoiceA $ testIfte
