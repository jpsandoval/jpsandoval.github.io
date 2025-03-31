#lang scribble/manual

@require[scribble/core]

@title{Foundations on Programming Language - Lecture Notes}
@author{JPS}

@table-of-contents[]


This text book have a set of exercises and test to learn scheme and programming languages.


@section{Part II: First Class Functions}

@subsection{Enviroment}
Definimos una estructura de datos environment.

@codeblock|{
;; Environment
(define-type Env
  [empty-env]
  [extended-env (id symbol?) (val Value?) (env Env?)])
}|

Funcion que permite buscar en el enviroment. Desde un punto de vista abstracto, funciona como un diccionario, entonces hay que buscar el valor correspodiente a un id.
@codeblock|{
;; Lookup x value in an env
(define (env-lookup x env)
  (match env
    ;; si llegamos a uno vacio el id no existe
    [(empty-env) (error 'env-lookup "not found: ~a" x)]
    ;; sino vemos si el id del env actual hace match
    ;; sino llamada recursiva al sub-env
    [(extended-env id val sub-env)
     (if (symbol=? id x)
         val
         (env-lookup x sub-env))]))
}|

@subsection{Gramatica}
@codeblock|{
#|
Grammar for expressions:
<expr> ::= <num>
         | <symbol-id>
         | {+ <expr> <expr>}
         | {- <expr> <expr>}
         | {if0 <expr> <expr> <expr>}
         | {with {sym <expr>} <expr>}
         | {call <exp> <expr>}
         | {fun (<symbol-id>) <expr>}
|#
}|
Ahora permitimos que el usuario cree una funcion, y llame una funcion.
@codeblock|{
(define-type Exp
  [num (n number?)]
  [plus (left Exp?) (right Exp?)]
  [minus (left Exp?) (right Exp?)]
  [with (id symbol?) (ae Exp?) (bw Exp?)]
  [if0 (cond Exp?) (etrue Exp?) (efalse Exp?)]
  [id (s symbol?)]
  [call (fexp Exp?) (aexp Exp?)]
  [fun (arg-id symbol?) (bexp Exp?)])
}|

@subsection{Parser}
El parser es un mapeo directo.
@codeblock|{
(define (parse s-expr)
  (match s-expr
    [(? number?) (num s-expr)]
    [(? symbol?) (id s-expr)]
    [(list 'fun (list sym) be) (fun sym (parse be))]
    [(list '+ l r) (plus (parse l) (parse r))]
    [(list '- l r) (minus (parse l) (parse r))]
    [(list 'if0 c t f) (if0 (parse c) (parse t) (parse f))]
    [(list 'with (list sym ae) bw) (with sym (parse ae) (parse bw))]
    [(list fe ae) (call (parse fe) (parse ae))]
    [else (error 'parse "syntax error")]))

}|
@subsection{Funcion como Valor}
En este interprete soportaremos dos tipos de valores, closures y numeros.
Recuerde que un closure es una función que encapsula el valor de las variables cuando esta se creo.
Los valores son encapsualdos en un enviroment. Por lo que la definicion de valores quedaria como sigue:


@codeblock|{
(define-type Value
  [numV (n number?)]
  [closureV (id symbol?) (body Exp?) (env Env?)])
}|
Note que ahora los valores del interpreter no son valores en scheme sino instancias de la structura Value.
Por lo que no podemos sumar o restar valores de forma directa. Creamos funciones que nos permitan sumar valores siendo estos numV.

@codeblock|{
;; sum values
(define (num+ n1 n2)
  (numV (+ (numV-n n1) (numV-n n2))))
;; subs values
(define (num- n1 n2)
  (numV (- (numV-n n1) (numV-n n2))))
;; num-zero? a value
(define (num-zero? n)
  (zero? (numV-n n)))
}|

@subsection{Interpretation}
Note que cuando se interpreta una funcion se devuelve un closure que tiene guardado en enviroment cuando se creo.
Luego si alguien aplica el closure, ejecutamos el body con el enviroment guardado y no con el actual.
@codeblock|{

;; interp devuelve un Value
(define (interp expr env)
  (match expr
    ;; devuelve un numV
    [(num n) (numV n)] 
    ;; devuelve un closureV
    [(fun arg-id body) (closureV arg-id body env)] 
    ;; devuelve un closureV o un numV
    [(id s) (env-lookup s env)] 
    ;; interpreta el body en un enviroment extendido con el identificado y su valor
    [(with sym ae wb) (interp wb
                              (extended-env sym
                                            (interp ae env)
                                            env))]
    ;; suma dos numV
    [(plus l r) (num+ (interp l env) (interp r env))]
    ;; resta dos numV
    [(minus l r) (num- (interp l env) (interp r env))]
    ;; verifica si un numV es zero
    [(if0 c t f) (if (num-zero? (interp c env))
                      (interp t env)
                      (interp f env))]
    
    [(call fe ae) (let ([arg-val (interp ae env)]  ;; debe devolver un value (numV o closureV)
                        [closure (interp fe env)]) ;; debe devolver un closureV o error
                       (match closure
                         [(closureV arg-id body fenv) ;; sacamos los datos de la closure
                          ;; interpretamos el body del la función
                          ;; extendemos el enviroment guardado en la closure
                          ;; con el argumento de la función
                          (interp body
                                  (extended-env arg-id
                                                (interp ae env)
                                                fenv))]))]))
}|

Todo empieza con un enviroment vacio.
@codeblock|{
(define (run prog)
  (match (interp (parse prog) (empty-env))
    [(numV n) n]
    [(and f (closureV id body env)) f]))
}|

@subsection{Testing}
@codeblock|{
Tara:
;;
(run '{with {add1 {fun {n} {+ n 1}}}
            {add1 2}})
}|