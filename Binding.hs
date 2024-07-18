module Binding where

import Lambda

type Context = [(String, Lambda)]

data Line = Eval Lambda 
          | Binding String Lambda deriving (Eq)

instance Show Line where
    show (Eval l) = show l
    show (Binding s l) = s ++ " = " ++ show l

expandMacro :: Context -> Lambda -> Either String Lambda
expandMacro ctx (Var x) = Right (Var x)
expandMacro ctx (App e1 e2) = do
    e1' <- expandMacro ctx e1
    e2' <- expandMacro ctx e2
    return (App e1' e2')
expandMacro ctx (Abs x e) = do
    e' <- expandMacro ctx e
    return (Abs x e')
expandMacro ctx (Macro m) = 
    case lookup m ctx of
        Just e  -> expandMacro ctx e
        Nothing -> Left $ "Macro " ++ m ++ " not found in context"

-- 3.1.
simplifyCtx :: Context -> (Lambda -> Lambda) -> Lambda -> Either String [Lambda]
simplifyCtx ctx step e = do
    expanded <- expandMacro ctx e
    return (simplify step expanded)

normalCtx :: Context -> Lambda -> Either String [Lambda]
normalCtx ctx = simplifyCtx ctx normalStep

applicativeCtx :: Context -> Lambda -> Either String [Lambda]
applicativeCtx ctx = simplifyCtx ctx applicativeStep
