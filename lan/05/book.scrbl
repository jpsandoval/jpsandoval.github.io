#lang scribble/manual

@require[scribble/core]

@title{Foundations on Programming Language - Lecture Notes}
@author{JPS}

@table-of-contents[]


This text book have a set of exercises and test to learn scheme and programming languages.


@section{Part II: Identifiers}

@subsection{Grammar}
@codeblock|{
#|
Grammar for expressions:
<expr> ::= <num>
         | {+ <expr> <expr>}
         | {- <expr> <expr>}
         | {if0 <expr> <expr> <expr>}
         | {with {<symbol> <expr>} <expr>}
         | <id>
|#
}|

@codeblock|{
;;
(define-type Exp
  [num  (n number?)]
  [id (s symbol?)]
  [plus (left Exp?) (right Exp?)]
  [minus (left Exp?) (right Exp?)]
  [if0 (cond Exp?) (etrue Exp?) (efalse Exp?)]
  [with (id symbol?) (exp Exp?) (body Exp?)])
}|

@subsection{Parser}
@codeblock|{
(define (parse s-expr)
  (match s-expr
    [(? number?) (num s-expr)]
    [(? symbol?) (id s-expr)]
    [(list '+ l r) (plus (parse l) (parse r))]
    [(list '- l r) (minus (parse l) (parse r))]
    [(list 'if0 c t f) (if0 (parse c) (parse t) (parse f))]
    [(list 'with (list s e) b) (with s (parse e) (parse b))]
    [else (error 'parse "syntax error")]))
}|
@subsection{Substituion Method}

@codeblock|{
;; substitution
;; el algoritmo recibe una expresion y devuelve una expresion
;; la expresion que devuelve donde antes existia el simbolo a sustituir ahora existe la expresion con la cual se substituyo
;; recuerden que este algoritmo no interpreta el programa,
;; solo devuelve otro programa con el id substituido por otra expresion
(define (subs sub-id value expr)
  (match expr
    ;; si encontramos un numero nada que sustituir
    [(num n)     expr ]
    ;; si encontramos un symbolo vemos si hay que sustituirlo
    [(id s)      (if (symbol=? s sub-id)
                     value
                     expr)]
    ;; devuelve un nodo plus, con el sub-id substituido
    [(plus l r)  (plus (subs sub-id value l)
                       (subs sub-id value r))]
    ;; devuelve un nodo minus, con el sub-id substituido
    [(minus l r) (minus (subs sub-id value l)
                        (subs sub-id value r))]
    ;; devuelve un nodo if0, con el sub-id substituido
    [(if0 c t f) (if0 (subs sub-id value c)
                      (subs sub-id value t)
                      (subs sub-id value f))]
    ;; devuelve un nodo with con el sub-id substituido
    ;; note que solo sustituye recursivamente el body, si es que el nodo with define un id con nombre diferente
    ;; si el symbolo del with es igual al nodo a sustituar, no sustituye el mismo en el body
    ;; asume que se redefinio la variable
    [(with s e b) (with s
                        (subs sub-id value e)
                        (if (symbol=? s sub-id)
                            b
                            (subs sub-id value b)))]))
}|

@subsection{Calc}
It support eager evaluation, and use the substituion method defined before.
@codeblock|{
(define (calc expr)
  (match expr
    [(num n) n]
    [(id s) (error 'calc "~a was not defined/initialized" s)]
    [(plus l r) (+ (calc l) (calc r))]
    [(minus l r) (- (calc l) (calc r))]
    [(if0 c t f) (if (eq? (calc c) 0)
                      (calc t)
                      (calc f))]
    ;; evalua la expresion e, el resulado debe ser un numero
    ;; pq nuestro lenguaje solo soporta numeros de momento
    ;; manda a sustitur el simbolo s por el resultado de evaluar e en el body
    ;; luego evalua el body con el id substituido
    [(with s e b) (calc (subs s (num (calc e)) b)) ]))
}|
@subsubsection{Testing}
@codeblock|{
;; Function to evaluate s-expressions directly
(define (run prog)
  (calc (parse prog)))

;; Tests to validate the functionality
(test (run '{with {x 2} {+ x x}}) 4)
(test (run '{with {x 2} {with {y 3} {+ x y}}}) 5)
(test (run '{with {x 2} {with {y 2} {if0 {- x y} 5 7}}}) 5)

;; probando que se respete el ambito de la variable
(test (run '{with {x 2} {with {x 3} x}}) 3)
;; probando que y tome el valor de x antes de sustituir
(test (run '{with {x 2} {with {y {+ x 2}} y}}) 4)
;; probando que se se sustituya en el body del segundo with ya que no hay colision de identificadores
(test (run '{with {x 2} {with {y {+ x 2}} x}}) 2)
}|