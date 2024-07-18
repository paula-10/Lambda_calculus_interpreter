module Default where

import Lambda
import Binding

-- Variables (for convenience)
vx = Var "x"
vy = Var "y"
vz = Var "z"
vf = Var "f"
vg = Var "g"
vh = Var "h"
vm = Var "m"
vn = Var "n"
vp = Var "p"
vq = Var "q"
vu = Var "u"

-- Basic combinators
m = Abs "x" $ App vx vx
i = Abs "x" $ vx
k = Abs "x" $ Abs "y" $ vx
ki = Abs "x" $ Abs "y" $ vy
c = Abs "x" $ Abs "y" $ Abs "z" $ App (App vx vz) vy
y = Abs "f" $ App fix fix
  where fix = Abs "x" $ App vf (App vx vx)

-- 4.1. Boolean encodings
bTrue = Abs "x" $ Abs "y" $ vx
bFalse = Abs "x" $ Abs "y" $ vy

bAnd = Abs "p" $ Abs "q" $ App (App vp vq) vp
bOr = Abs "p" $ Abs "q" $ App (App vp vp) vq
bNot = Abs "p" $ App (App vp bFalse) bTrue
-- xor : λx.λy.((x (noty y)) y)
bXor = Abs "p" $ Abs "q" $ App (App vp (App bNot vq)) vq

-- 4.2. Pair encodings
pair = Abs "x" $ Abs "y" $ Abs "f" $ App (App vf vx) vy
first = Abs "p" $ App vp (Abs "x" $ Abs "y" $ vx)
second = Abs "p" $ App vp (Abs "x" $ Abs "y" $ vy)

-- 4.3. Natural number encodings
n0 = Abs "f" $ Abs "x" $ vx
n1 = Abs "f" $ Abs "x" $ App vf vx
n2 = Abs "f" $ Abs "x" $ App vf (App vf vx)

nSucc = Abs "n" $ Abs "f" $ Abs "x" $ App vf (App (App vn vf) vx)
nPred = Abs "n" $ Abs "f" $ Abs "x" $
        App (App (App vn (Abs "g" $ Abs "h" $ App vh (App vg vf)))
                 (Abs "m" vx))
            (Abs "m" vm)

nAdd = Abs "m" $ Abs "n" $ Abs "f" $ Abs "x" $ App (App vm vf) (App (App vn vf) vx)
nSub = Abs "m" $ Abs "n" $ App (App vn nPred) vm
nMult = Abs "m" $ Abs "n" $ Abs "f" $ App vm (App vn vf)

-- Default Context
defaultContext :: Context
defaultContext = 
    [ ("M", m)
    , ("I", i)
    , ("K", k)
    , ("KI", ki)
    , ("C", c)
    , ("Y", y)
    , ("TRUE", bTrue)
    , ("FALSE", bFalse)
    , ("AND", bAnd)
    , ("OR", bOr)
    , ("NOT", bNot)
    , ("XOR", bXor)
    , ("PAIR", pair)
    , ("FST", first)
    , ("SND", second)
    , ("N0", n0)
    , ("N1", n1)
    , ("N2", n2)
    , ("SUCC", nSucc)
    , ("PRED", nPred)
    ,("ADD", nAdd)
    , ("SUB", nSub)
    , ("MULT", nMult)
    ]
