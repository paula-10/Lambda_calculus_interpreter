In this assignment, I implemented a lambda expression interpreter in Haskell.

We will define a lambda expression using the following ADT:

haskell
Copy code
data Lambda = Var String
            | App Lambda Lambda
            | Abs String Lambda
Variables are declared as type String. For simplicity, we'll consider any string composed solely of lowercase English letters to be a variable.

1. Evaluation
Reminder:

redex: A reducible expression, i.e., of the form (λx.e1 e2)
normal-form: An expression that can no longer be reduced (contains no redex).
Evaluating a lambda expression involves performing β-reductions until we reach an equivalent expression in normal form. An implementation detail is that before performing β-reduction, we must resolve potential name collisions. Attempting to reduce a redex without making textual substitutions risks losing the original meaning of the expression. For example, the redex: (λx.λy.(x y) λx.y) would be reduced to: λy.(λx.y y). This unwanted effect is known as variable capture: The initially free variable y has become bound after reduction.

You can observe that the expression has lost its original meaning because the free y from λx.y is now bound by the λy from the expression it was substituted into. Thus, the correct reduction would be: λa.(λx.y a).

To detect and resolve variable capture, we will prepare some helper functions:

vars: Auxiliary function that returns a list of all Strings representing variables in an expression.
freeVars: Auxiliary function that returns a list of all Strings representing free variables in an expression. (Note: if a variable is free in the expression in multiple contexts, it will appear only once in the list).
newVars: Auxiliary function that takes a list of Strings and returns the smallest lexicographical String that does not appear in the list (e.g., newVars ["a", "b", "c"] will return "d").
isNormalForm: Function that checks if an expression is in normal form.
reduce: Function that performs β-reduction of a redex, considering name collisions. The function takes the deconstructed redex and returns the resulting expression.
haskell
Copy code
reduce :: String -> Lambda -> Lambda -> Lambda
reduce x e1 e2 = undefined
-- anywhere the variable x appears in e1, it is replaced with e2
Now that we can reduce a redex, we want to reduce an expression to its normal form. To do this, we need to implement a strategy for choosing the next redex to reduce and apply it until no redex remains. In this assignment, we will implement two strategies: Normal and Applicative.

Normal: Chooses the outermost, leftmost redex.
Applicative: Chooses the innermost, leftmost redex.
We will perform the reduction "step by step," implementing a function that reduces only the next redex according to a strategy. Then we apply these steps until the remaining expression is in normal form. The functions that will help us implement these two strategies are:

normalStep: Function that applies a reduction step following the Normal strategy.
applicativeStep: Function that applies a reduction step following the Applicative strategy.
simplify: Function that takes a step function and applies it until the expression is in normal form, returning a list of all intermediate steps of the reduction.
2. Parsing
Currently, we can evaluate expressions defined by us in the form of code. To have a functional interpreter, we need to take expressions in the form of strings and transform them into ADTs (this process is called parsing). A grammar for lambda expressions could be:

bnf
Copy code
<lambda> ::= <variable> | '\' <variable> '.' <lambda> | (<lambda> <lambda>)
<variable> ::= <variable><alpha> | <alpha>
<alpha> ::= 'a' | 'b' | 'c' | ... | 'z'
The parseLambda function parses a String and returns an expression.

The parser that you need to implement has the definition:

haskell
Copy code
newtype Parser a = Parser {
    parse :: String -> Maybe(a, String)
}
Note that the type returned by the parsing function is Maybe(a, String). It returns Nothing if it could not parse the expression, or Just (x, s) if it parsed x and the original string's suffix is s.

3. Steps towards a Programming Language
Using the previous parser and evaluator, we can evaluate any computable result, as lambda expressions are sufficiently expressive, but it is very difficult to write such expressions. To make it easier to use, we want to be able to name certain sub-expressions for later reuse. For this, we will use the concept of macros. The first step would be to extend the definition of an expression with a constructor Macro that accepts a String as a parameter (the macro's name). We will also introduce the syntax: any string composed solely of uppercase English letters and digits is considered a macro.

Some examples of expressions with macros are:

TRUE
λx.FALSE
λx(NOT λy.AND)
To use macros, we need to introduce the notion of a computational context. The context in which we evaluate an expression is simply a dictionary of macro names and the expressions these names replace. Thus, when we evaluate a macro, we simply perform textual substitution with the expression found in the dictionary.

If we do not find the macro in the context, we will not know how to evaluate the expression, so we would like to return an error. We will extend the returned data type to Either String [Lambda] and return Left in case of an error and Right if the evaluation completes successfully.

The simplifyCtx function takes a context and an expression that may contain macros, performs the macro substitutions (or returns an error if it fails), and evaluates the resulting expression using the given step strategy.

Working with Maybe or Either can become complicated if we use case statements on all variables. To ease working with them, there are monads defined for both Maybe and Either, and you can use do notation to simplify your work. The lookup function is very useful for working with dictionaries (lists of pairs).

The last step to use macros is to find a way to define them. For this, we will define the concept of a line of code:

haskell
Copy code
data Line = Eval Lambda
          | Binding String Lambda
A line of code can be either a lambda expression or a macro definition. Thus, if we evaluate multiple lines of code, we can use previously defined macros in expressions.

I modified the parser to also parse expressions containing macros. I implemented the parseLine function that parses a line of code and returns an error (in the form of a String) if it finds errors.

4. Default Library
Now that we have a functional interpreter for lambda calculus, let's define some common expressions to use as a default context for our interpreter (a kind of standard library).

In the Default.hs file, several combinators are already defined. Define the rest of the expressions.

I defined as lambda expressions some useful macros for working with Booleans (TRUE, FALSE, AND, OR, NOT, XOR).

I defined as lambda expressions some useful macros for working with pairs (PAIR, FIRST, SECOND).

I defined as lambda expressions some useful macros for working with natural numbers (N0, N1, N2, SUCC, PRED, ADD, SUB, MULT).
