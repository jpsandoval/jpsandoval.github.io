#lang scribble/manual

@require[scribble/core]

@title{Foundations on Programming Language - Lecture Notes}
@author{JPS}

@table-of-contents[]


This text book have a set of exercises and test to learn scheme and programming languages.


@section{Part II: Aritmetic Expresions}

@subsection{Data Types}
Grammar representation in types.
@subsubsection{Definition}
@codeblock|{
(define-type Exp
  [num  (n number?)]
  [plus (left Exp?) (right Exp?)])
}|

@subsubsection{Instantiation}
@codeblock|{
(define expr1 (num 100))
(define expr2 (plus (num 100) (plus (num 200) (num 200))))
}|
@subsubsection{Useful methods}
@codeblock|{
;; Example expressions
(define expr1 (num 100))
(define expr2 (plus (num 100) (plus (num 200) (num 200))))
;; Extract the value from the num type
(test (num-n expr1) 100)
;; Extract the right sub-expression from the plus type
(test (plus-right expr2) (plus (num 200) (num 200)))

;; Contract checking
(test (num? expr2) #f)
(test (num? expr1) #t)
(test (plus? expr1) #f)
(test (plus? expr2) #t)
}|

@subsection{Parsing}

@subsubsection{Parse Function}
The input is a string and the output is a intance of the type Exp
@codeblock|{
(define (parse s-expr)
  (match s-expr
    [(? number?) (num s-expr)]
    [(list '+ l r) (plus (parse l) (parse r))]))
}|
@subsubsection{Testing}
@codeblock|{
(test (parse '{+ 1 1}) (plus (num 1) (num 1)))
}|

@subsection{Calc}
This function receive a instance of Exp and return a value which is the result of evaluate the expresion
@codeblock|{
(define (calc expr)
  (match expr
    [(num n) n]
    [(plus l r) (+ (calc l) (calc r))]))
}|


@subsection{First Language}
@codeblock|{
;; Function to evaluate s-expressions directly
(define (run prog)
  (calc (parse prog)))

;; Tests to validate the functionality
(test (run `1) 1)
(test (run `2.3) 2.3)
(test (run `{+ 1 2}) 3)
(test (run `{+ {+ 1 2} 3}) 6)
(test (run `{+ 1 {+ 2 3}}) 6)
(test (run `{+ 1 {+ {+ 2 3} 4}}) 10)
}|

@subsection{Ejercicio}
Modificar el lenguaje anterior para soporte condicionales, considerando la siguiente gramatica. Si la primera expresion es 0 entonces devuelve el resultado de evaluar la segunda expresion. Si la primera expresion no es 0 entonces devuelve el resultado de evaluar la tercera expreesion.

@codeblock|{
#|
<expr> ::= <num>
         | {+ <expr> <expr>}
         | {if0 <expr> <expr> <expr>}
|#
}|

