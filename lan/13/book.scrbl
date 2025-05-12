#lang scribble/manual

@require[scribble/core]

@title{Foundations on Programming Language - Lecture Notes}
@author{JPS}

@table-of-contents[]


This text book have a set of exercises and test to learn scheme and programming languages.


@section{Part II: Circular Intepreter}

@subsection{Enviroment}
Mantenemos la definición de enviroment que teniamos. En este caso, el modificamos nuestro código para que el valor del enviroment sea cualquier tipo.

@codeblock|{
(define (Any? v) #t)

(define-type Env
  [empty-env]
  [extended-env (id symbol?) (val Any?) (env Env?)])

(define (env-lookup x env)
  (match env
    [(empty-env) (error 'env-lookup "not found: ~a" x)]
    [(extended-env id val sub-env)
     (if (symbol=? id x)
         val
         (env-lookup x sub-env))]))
}|


@subsection{Gramatica}
Soportaremos la misma gramática, implementando with como azucar sintactico.
@codeblock|{
#|
<expr> ::= <num>
         | {+ <expr> <expr>}
         | {- <expr> <expr>}
         | {if0 <expr> <expr> <expr>}
         | <symbol-id>
         | {with {<symbol-id> <expr>} <expr>}
         | {fun {sym-arg} <expr>}
         | {<expr> <expr>}
|#
}|

@codeblock|{
(define-type Exp
  [num  (n number?)]
  [plus (left Exp?) (right Exp?)]
  [minus (left Exp?) (right Exp?)]
  [if0 (cond Exp?) (etrue Exp?) (efalse Exp?)]
  [id  (s symbol?)]
  [fun (sym-arg symbol?) (body Exp?)]
  [call (cls-exp Exp?) (arg-expr Exp?)])
}|

@subsection{Parser}
El parser es un mapeo directo.
@codeblock|{
(define (parse s-expr)
  (match s-expr
    [(? number?) (num s-expr)]
    [(? symbol?) (id s-expr)]
    [(list '+ l r) (plus (parse l) (parse r))]
    [(list '- l r) (minus (parse l) (parse r))]
    [(list 'if0 c t f) (if0 (parse c) (parse t) (parse f))]
    [(list 'with (list sym se) be)
     (call (fun sym (parse be))
           (parse se))]
    [(list 'fun (list sym-arg) be)
                (fun sym-arg (parse be))]
    [(list cls-exp arg-exp)
                (call (parse cls-exp) (parse arg-exp))]
    [else (error 'parse "syntax error")]))

}|
@subsection{Circular Interpreter}
En este ejemplo nuestro interprete recibira una expresion en nuestro lenguaje y devolvera un valor en scheme.
En este ejemplo, para representar las funciones, utilizaremos al lambda de scheme.


@subsection{Interpretation}

@codeblock|{
;; intepr (Exp x Env) --> Scheme Value
(define (interp expr env)
  (match expr
    [(num n) n]
    [(id s)  (env-lookup s env)]
    [(plus l r) (+ (interp l env) (interp r env))]
    [(minus l r) (- (interp l env) (interp r env))]
    [(if0 c t f) (if (zero? (interp c env)) (interp t env) (interp f env))]
    ;; Aqui en lugar de crear un closureV, creamos un lambda de scheme
    [(fun sym-arg fun-body)
                            (lambda (arg-val)
                              (interp fun-body
                                      (extended-env sym-arg arg-val env)))]
    ;; Aqui la llamada a función, la parte izquierda devuelve un labmda de scheme
    ;; Entonces tenemos que ejecutarlo directamente
    [(call cls-exp arg-exp) ((interp arg-exp env) (interp cls-exp env))]))
}|

@subsection{Testing}
Todo empieza con un enviroment vacio.
@codeblock|{
(define (run prog)
  (interp (parse prog) (empty-env)))
}|

@codeblock|{
(run '{with {add1 {fun {n} {+ n 2}}}
            {with {x 2}
                  {add1 x}}})

}|