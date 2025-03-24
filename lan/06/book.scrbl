#lang scribble/manual

@require[scribble/core]

@title{Foundations on Programming Language - Lecture Notes}
@author{JPS}

@table-of-contents[]


This text book have a set of exercises and test to learn scheme and programming languages.


@section{Part II: Functions}

@subsection{Grammar}
Now we will support function calls to pre-defined functions.

@codeblock|{
#|
Grammar for expressions:
<expr> ::= <num>
         | {+ <expr> <expr>}
         | {- <expr> <expr>}
         | {if0 <expr> <expr> <expr>}
         | <symbol-id>
         | {with {<symbol-id> <expr>} <expr>}
         | {<symbol-fun-id> <expr>}
|#
}|

@codeblock|{
(define-type Exp
  [num  (n number?)]
  [plus (left Exp?) (right Exp?)]
  [minus (left Exp?) (right Exp?)]
  [if0 (cond Exp?) (etrue Exp?) (efalse Exp?)]
  [id  (s symbol?)]
  [with (symbol-id symbol?) (sexp Exp?) (bexp Exp?)]
  [call (symbol-fun-id symbol?) (aexp Exp?)])
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
    [(list 'with (list sym se) be) (with sym (parse se) (parse be))]
    [(list symbol-fun-id ae) (call symbol-fun-id (parse ae))]
    [else (error 'parse "syntax error")]))
}|
@subsection{Substituion Method}
Actualizamos la funcion de substitucion para que substituya el valor recursivamente en una expresion, llamada a función.
@codeblock|{
(define (subs sym value expr)
  (match expr
    [(num n) expr]
    [(id s) (if (symbol=? sym s)
                value
                expr)]
    [(plus l r) (plus (subs sym value l)
                      (subs sym value r)) ]
    [(minus l r) (minus (subs sym value l)
                        (subs sym value r)) ]
    [(if0 c t f) (if0 (subs sym value c)
                     (subs sym value t)
                     (subs sym value f))]
    [(with s se be) (if (symbol=? s sym)
                        (with s (subs sym value se) be)
                        (with s (subs sym value se) (subs sym value be)))]
    [(call fun-id ae) (call fun-id (subs sym value ae))]))
}|

@subsection{FunDef and utility functions}
Here we define a structure to store function definitions, to search a funtion in a list of functions, and apply a function
@codeblock|{
;; Soportaremos solo llamadas a funciones pre-definidas en el lenguaje
;; Una definicion de funcion tendra un solo argumento que sera un valor, nombre (un simbolo) y un body que sera una epxresion
(define-type FunDef
  [fundef  (fun-name symbol?) (arg-name symbol?) (body Exp?)])

}|
@codeblock|{
;; funcion para buscar una funcion en la lista
(define (lookup-fundef f funs)
  (match funs
    ['() (error 'lookup-fundef "function not found: ~a" f)]
    [(cons (fundef fn _ _) rest)
       (if (symbol=? fn f)
           (car funs)
           (lookup-fundef f rest))]))

;; applicar funcion
(define (apply-fundef fd arg-val funs)
  (match fd
    [(fundef _ arg-name fun-body)
     (interp (subs arg-name arg-val fun-body) funs)]))
}|


@subsection{Interpretation}
recibe como argumento la lista de funciones pre-definidas
@codeblock|{
(define (interp expr funs)
  (match expr
    [(num n) n]
    [(id s)  (error 'interp "free identifier")]
    [(plus l r) (+ (interp l funs) (interp r funs))]
    [(minus l r) (- (interp l funs) (interp r funs))]
    [(if0 c t f) (if (eq? (interp c funs) 0)
                      (interp t funs)
                      (interp f funs))]
    [(with s se be) (interp (subs s (num (interp se funs)) be) funs)]
    [(call fun-id ae) (apply-fundef (lookup-fundef fun-id funs)
                                    (num (interp ae funs))
                                    funs)]))

(define (run prog funs)
  (interp (parse prog) funs))
}|

@subsubsection{Testing}
@codeblock|{
(define pre-defined-funs (list (fundef 'add1 'n (parse '{+ n 1}))
                               (fundef 'sum 'n (parse '{if0 n 0 {+ n {sum {- n 1}}}}))))

(test (run '{+ {add1 2} 1} pre-defined-funs) 4)
(test (run '{sum 3} pre-defined-funs) 6)
}|