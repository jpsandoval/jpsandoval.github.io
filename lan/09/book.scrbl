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

Note que ahora implementamos el with con azucar sintactico, por eso ya no esta en el define-type
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
El parser es un mapeo directo. El with esta implementado con azucar sintactico.
Es representado por una aplicación de función.
@codeblock|{
(define (parse s-expr)
  (match s-expr
    [(? number?) (num s-expr)]
    [(? symbol?) (id s-expr)]
    [(list '+ l r) (plus (parse l) (parse r))]
    [(list '- l r) (minus (parse l) (parse r))]
    [(list 'if0 c t f) (if0 (parse c) (parse t) (parse f))]
    ;; implementamos el with con azucar sintactico
    [(list 'with (list sym se) be) (call (fun sym (parse be)) (parse se))]
    [(list 'fun (list sym-arg) be) (fun sym-arg (parse be))]
    [(list cls-exp arg-exp)
                (call (parse cls-exp) (parse arg-exp))]
    [else (error 'parse "syntax error")]))

}|
@subsection{Funcion como Valor}
Modificamos el interprete para que pueda "manejar" expresiones como valor.
Entonces al momento de aplicar una función ya no evaluaremos su argumento, sino retrasaremos su evaluación encapsulandolo en un exprV.
El mismo que se evaluara cuando se necesite.
Note que es necesario guardarse el enviroment, porque la expresion puede tener identificadores, y queremos mantener el scope statico.
Note también que agregamos un atributo cache, que guardara el resultado de evaluar la expresion para no evaluarla dos veces.



@codeblock|{
(define-type Value
  [noneV]
  [numV (n number?)]
  [closureV (id symbol?) (body Exp?) (env Env?)]
  ;; la expresion que no se evalua sabe en que enviroment se tenia q evaluar
  [exprV (exp Exp?) (env Env?) (cache box?)]) 
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

@subsection{Strict: Forzando la evaluación de un exprV}
@codeblock|{
;; dado un valor vemos si es un exprV
;; si es forzamos la evaluación
(define (strict e)
  (match e
    [(exprV expr env (box (noneV))) ;; si nunca fue evaluado
               (let ([val  (strict (interp expr env))]) ;; lo evaluamos
                    (begin
                      (printf "Forcing exprV to ~v~n" val)
                      (set-box! (exprV-cache e) val) ;; guardamos el dato en el cache
                      val))] ;; devolvemos el valor
    [(exprV expr env (box cached-value)) cached-value] ;; si ya fue evaluado devolvemos el valor de la cache
    [else e])) ;; si no es un exprV entonces es un valor ya evaluado

}|
@subsection{Interpretation}
Note que cuando se interpreta una funcion se devuelve un closure que tiene guardado en enviroment cuando se creo.
Luego si alguien aplica el closure, ejecutamos el body con el enviroment guardado y no con el actual.
@codeblock|{
(define (interp expr env)
  (match expr
    [(num n) (numV n)]
    [(id s)  (env-lookup s env)]
    [(plus l r) (num+ (strict (interp l env)) ;; la suma fuerza la evaluación
                      (strict (interp r env)))] 
    [(minus l r) (num- (strict (interp l env))
                       (strict (interp r env)))] ;; la resta fuerza la evaluación
    [(if0 c t f) (if (num-zero? (strict (interp c env))) ;; solo forzamos la evaluacion de la condición
                      (interp t env)
                      (interp f env))]
    [(fun sym-arg fun-body) (closureV sym-arg fun-body env)]
    [(call cls-exp arg-exp)
                    (let ([arg-val (exprV arg-exp env (box (noneV)))] ;; no evaluamos el argumento, retrazamos su evaluación
                          [cls-val (strict (interp cls-exp env))]) ;; forzamos la evaluación de la closure
                          (match cls-val
                            [(closureV sym body fun-env) 
                                  (interp body (extended-env sym
                                                             arg-val
                                                             fun-env))]))])) 
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
;;Tara:
(run '{with {add1 {fun {n} {+ n n}}}
            {+ 1 1}})
}|