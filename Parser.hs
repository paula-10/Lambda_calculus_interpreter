module Parser (parseLambda, parseLine) where

import Control.Monad
import Control.Applicative
import Data.Char (isAlpha, isUpper, isDigit)

import Lambda
import Binding

newtype Parser a = Parser { parse :: String -> Maybe (a, String) }

instance Functor Parser where
    fmap f (Parser p) = Parser $ \input -> do
        (x, rest) <- p input
        return (f x, rest)

instance Applicative Parser where
    pure x = Parser $ \input -> Just (x, input)
    (Parser pf) <*> (Parser px) = Parser $ \input -> do
        (f, rest1) <- pf input
        (x, rest2) <- px rest1
        return (f x, rest2)

instance Monad Parser where
    (Parser p) >>= f = Parser $ \input -> do
        (x, rest1) <- p input
        let (Parser p2) = f x
        p2 rest1

instance Alternative Parser where
    empty = Parser $ const Nothing
    (Parser p1) <|> (Parser p2) = Parser $ \input -> p1 input <|> p2 input

satisfy :: (Char -> Bool) -> Parser Char
satisfy predicate = Parser $ \input -> case input of
    (x:xs) | predicate x -> Just (x, xs)
    _ -> Nothing

char :: Char -> Parser Char
char c = satisfy (== c)

string :: String -> Parser String
string = traverse char

spaces :: Parser String
spaces = many (satisfy (== ' '))

variable :: Parser Lambda
variable = do
    first <- satisfy (`elem` ['a'..'z'])
    rest <- many (satisfy (`elem` ['a'..'z']))
    return $ Var (first:rest)

macro :: Parser Lambda
macro = do
    name <- some (satisfy (\c -> c `elem` ['A'..'Z'] || c `elem` ['0'..'9']))
    return $ Macro name

abstraction :: Parser Lambda
abstraction = do
    char '\\'
    spaces
    var <- some (satisfy (`elem` ['a'..'z']))
    spaces
    char '.'
    spaces
    body <- lambdaExpr
    return $ Abs var body

application :: Parser Lambda
application = do
    char '('
    spaces
    e1 <- lambdaExpr
    spaces
    e2 <- lambdaExpr
    spaces
    char ')'
    return $ App e1 e2

lambdaExpr :: Parser Lambda
lambdaExpr = abstraction <|> application <|> macro <|> variable

-- 2.1. / 3.2.
parseLambda :: String -> Lambda
parseLambda input = case parse lambdaExpr input of
    Just (expr, "") -> expr
    _ -> error "Parse error"

parseBinding :: Parser Line
parseBinding = do
    name <- some (satisfy (\c -> isUpper c || isDigit c))
    spaces
    char '='
    spaces
    expr <- lambdaExpr
    return $ Binding name expr

parseEval :: Parser Line
parseEval = do
    expr <- lambdaExpr
    return $ Eval expr

parseLineExpr :: Parser Line
parseLineExpr = parseBinding <|> parseEval
        
-- 3.3.
parseLine :: String -> Either String Line
parseLine input = case parse parseLineExpr input of
    Just (line, "") -> Right line
    _ -> Left "Parse error"
