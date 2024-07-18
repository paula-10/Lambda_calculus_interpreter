module Lambda where

import Data.List (nub, (\\))

data Lambda = Var String
            | App Lambda Lambda
            | Abs String Lambda
            | Macro String

instance Show Lambda where
    show (Var x) = x
    show (App e1 e2) = "(" ++ show e1 ++ " " ++ show e2 ++ ")"
    show (Abs x e) = "λ" ++ x ++ "." ++ show e
    show (Macro x) = x

instance Eq Lambda where
    e1 == e2 = eq e1 e2 ([],[],[])
      where
        eq (Var x) (Var y) (env,xb,yb) = elem (x,y) env || (not $ elem x xb || elem y yb)
        eq (App e1 e2) (App f1 f2) env = eq e1 f1 env && eq e2 f2 env
        eq (Abs x e) (Abs y f) (env,xb,yb) = eq e f ((x,y):env,x:xb,y:yb)
        eq (Macro x) (Macro y) _ = x == y
        eq _ _ _ = False

-- 1.1.
-- functie care returneaza o lista cu toate variabilele dintr-o expresie lambda
vars :: Lambda -> [String]
-- pentru a variabila libera
vars (Var x) = [x]
-- daca expresia este o aplicatie, aplica recursiv functia vars pe fiecare subexpresie
vars (App e1 e2) = nub (vars e1 ++ vars e2)
-- daca expresia este o abstractie, adauga variabila la lista de variabile
-- se adauga variabila x la lista rezultata
-- se elimina duplicatele folosind nub
vars (Abs x e) = nub (x : vars e)
vars (Macro _) = []

-- 1.2.
-- functie care returneaza variabilele libere dintr-o expresie lambda
freeVars :: Lambda -> [String]
freeVars (Var x) = [x]
-- daca expresia este o aplicatie, aplica recursiv functia freeVars pe fiecare subexpresie
freeVars (App e1 e2) = nub (freeVars e1 ++ freeVars e2)
-- daca expresia este o abstractie, aplica revursiv functia freeVars pe subexpresie si filtreaza variabila x
freeVars (Abs x e) = filter (/=x) (freeVars e)
freeVars (Macro _) = []

-- 1.3.
-- functie care intoarce cel mai mic string lexicografic care nu apare in lista
newVar :: [String] -> String
-- stocheaza intr-o lista sirurile de caractere deja utilizate
newVar used = head (filter (`notElem` used) candidates)
  where
    alphabet = ['a'..'z']
    -- genereaza toate combinatiile de siruri de caractere de lungime de la 1 la 3
    -- concateneaza rezultatele intr-o lista
    candidates = concatMap generateCombinations [1..3]
    -- genereaaza toate combinatiile de litere din alfabet de lungime n
    generateCombinations n = sequence (replicate n alphabet)

-- 1.4.
-- functie care verifica daca o expresie este in forma normala
isNormalForm :: Lambda -> Bool
-- daca expresia este o variabila, atunci este in forma normala
isNormalForm (Var _) = True
-- daca expresia este o abstractie, aplica recursiv functia isNormalForm pe corpul abstractiei
isNormalForm (Abs _ e) = isNormalForm e
isNormalForm (App (Abs _ _) _) = False
isNormalForm (App e1 e2) = isNormalForm e1 && isNormalForm e2
-- macro-urile sunt in forma normala
isNormalForm (Macro _) = True

-- 1.5.
-- functie care reduce un redex
-- string -> numele variabilei care va fi inlocuita
-- lambda(1) -> o expresie in care va avea loc inlocuirea
-- lambda(2) -> o expresie care va inlocui
reduce :: String -> Lambda -> Lambda -> Lambda
-- caz 1
-- daca expresia este o variabila, verifica daca este cea care trebuie inlocuita
reduce x (Var y) e
  | x == y    = e
  | otherwise = Var y
-- caz 2
-- daca expresia este o aplicatie, aplica recursiv reduce pe ambele subexpresii
reduce x (App e1 e2) e = App (reduce x e1 e) (reduce x e2 e)
-- caz 3
-- daca expresia este o abstractie, am trei sub-cazuri
reduce x (Abs y e1) e
  | x == y    = Abs y e1
  | y `notElem` freeVars e = Abs y (reduce x e1 e)
  | otherwise = 
    let z = newVar (vars e1 ++ vars e ++ [x, y])
        e1' = rename y z e1
    in Abs z (reduce x e1' e)
  where
    rename old new (Var v)
      | v == old = Var new
      | otherwise = Var v
    rename old new (App l1 l2) = App (rename old new l1) (rename old new l2)
    rename old new (Abs v l)
      | v == old = Abs new (rename old new l)
      | otherwise = Abs v (rename old new l)
    rename _ _ (Macro m) = Macro m
reduce _ macro@(Macro _) _ = macro

-- 1.6.
-- functie care aplica un pas de reducere dupa strategia normala
normalStep :: Lambda -> Lambda
normalStep (App (Abs x e1) e2) = reduce x e1 e2
normalStep (App e1 e2)
  | not (isNormalForm e1) = App (normalStep e1) e2
  | not (isNormalForm e2) = App e1 (normalStep e2)
  | otherwise = App e1 e2
normalStep (Abs x e) = Abs x (normalStep e)
normalStep e = e

-- 1.7.
-- functie care aplica un pas de reducere dupa strategia aplicativa
applicativeStep :: Lambda -> Lambda
applicativeStep (App (Abs x e1) e2)
  | isNormalForm e2 = reduce x e1 e2
  | otherwise = App (Abs x e1) (applicativeStep e2)
applicativeStep (App e1 e2)
  | not (isNormalForm e1) = App (applicativeStep e1) e2
  | otherwise = App e1 (applicativeStep e2)
applicativeStep (Abs x e) = Abs x (applicativeStep e)
applicativeStep e = e

-- 1.8.
-- primeste o functie step si o aplica pana expresia ramane in forma normala
-- intoarce o lista cu toti pasii intermediari ai reducerii
simplify :: (Lambda -> Lambda) -> Lambda -> [Lambda]
simplify step e
  | isNormalForm e = [e]
  | otherwise = e : simplify step (step e)

normal :: Lambda -> [Lambda]
normal = simplify normalStep

applicative :: Lambda -> [Lambda]
applicative = simplify applicativeStep
