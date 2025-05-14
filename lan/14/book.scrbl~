#lang scribble/manual

@require[scribble/core]

@title{Foundations on Programming Language - Lecture Notes}
@author{JPS}

@table-of-contents[]


This text book have a set of exercises and test to learn scheme and programming languages.


@section{Part II: Implementing Recursion with Mutation}

@subsection{Enviroment}
Creamos un nuevo tipo de enviroment. El mismo estara diseñado para usarlo en funciones recursivas.
La diferencia es que en lugar de un value, tendra un box-value, un box que contiene un value.

@codeblock|{
(define-type Env
  [empty-env]
  [extended-env (id symbol?) (val Value?) (env Env?)]
  [rec-extended-env (id symbol?) (bval box?) (env Env?)])
}|

Funcion que permite buscar en el enviroment. Desde un punto de vista abstracto, funciona como un diccionario, entonces hay que buscar el valor correspodiente a un id.
@codeblock|{
(define (env-lookup x env)
  (match env
    [(empty-env) (error 'env-lookup "not found: ~a" x)]
    [(extended-env id val sub-env)
     (if (symbol=? id x)
         val
         (env-lookup x sub-env))]
    ;; creamos un nuevo tipo de nodo en el enviroment
    ;; en ves que tener un valor tendra un box que adentro tendra el valor
    ;; esto permitira inicializar el box vacio y luego agregar el valor
    [(rec-extended-env id bval sub-env)
     (if (symbol=? id x)
         (unbox bval)
         (env-lookup x sub-env))]))

}|

@subsection{Gramatica}
Se agrega en la gramatica el operador rec, que es identico al with, pero que sera utilizado solo para asignar identificadores de funciones recursivas.
Cuando alguien cree una funcion recursiva, necesitamos asociar el nombre de la closureV al environment.
Donde  el enviroment del closureV apunte a si mismo.
@codeblock|{
#|
Grammar for expressions:
<expr> ::= <num>
         | {+ <expr> <expr>}
         | {- <expr> <expr>}
         | {if0 <expr> <expr> <expr>}
         | <symbol-id>
         | {with {<symbol-id> <expr>} <expr>}
         | {rec {<sym> <expr>} <expr>}
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
  [with (symbol-id symbol?) (sexp Exp?) (bexp Exp?)]
  [fun (sym-arg symbol?) (body Exp?)]
  ;; rec funcionara igual que with, pero servira para definir expresiones recursivas
  ;; cuando alguien asigne un identificador usando rec
  ;; crearemos un enviroment recursivo
  ;; el named-expr es una expresion que devuelve una closure (funcion+env)
  [rec (id symbol?) (named-expr Exp?) (body Exp?)]
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
    [(list 'with (list sym se) be) (with sym (parse se) (parse be))]
    ;; note que es igual que with
    [(list 'rec (list id ne) be) (rec id (parse ne) (parse be))]
    [(list 'fun (list sym-arg) be) (fun sym-arg (parse be))]
    [(list cls-exp arg-exp) (call (parse cls-exp) (parse arg-exp))]
    [else (error 'parse "syntax error")]))

}|
@subsection{Funcion como Valor}
En nuestro interprete usaremos eager evaluation, y sooportaremos solo numbers y closures.
@codeblock|{
;;
(define-type Value
  [numV (n number?)]
  [closureV (id symbol?) (body Exp?) (env Env?)])
}|


@codeblock|{
;; sum values
(define (num+ numberV1 numberV2)
  (numV (+ (numV-n numberV1) (numV-n numberV2))))

;; subs values
(define (num- n1 n2)
  (numV (- (numV-n n1) (numV-n n2))))
;; num-zero? a value
(define (num-zero? n)
  (zero? (numV-n n)))
}|


@subsection{Interpretation}
La interpretacion de rec es identica a with, solo que interpreta el body en un enviroment recursivo.
@codeblock|{
;; intepr (Exp x Env) --> Value
(define (interp expr env)
  (match expr
    [(num n) (numV n)]
    [(id s)  (env-lookup s env)]
    [(plus l r) (num+ (interp l env) (interp r env))]
    [(minus l r) (num- (interp l env) (interp r env))]
    [(if0 c t f) (if (num-zero? (interp c env))
                      (interp t env)
                      (interp f env))]
    [(with s se be) (interp be (extended-env s (interp se env) env))]
    ;; el named-arg del rec se creara con un enviroment recursivo
    ;; es la unica diferencia con el with
    [(rec id named-expr body) (interp body (cyclic-env id named-expr env))]
    [(fun sym-arg fun-body) (closureV sym-arg fun-body env)]
    [(call cls-exp arg-exp)
                    (let ([arg-val (interp arg-exp env)]
                          [cls-val (interp cls-exp env)])
                          (match cls-val
                            [(closureV sym body fun-env)
                                  (interp body (extended-env sym
                                                             arg-val
                                                             fun-env))]))])) 
}|


@subsection{Creamos un enviroment recursivo}
@codeblock|{
;; si asumimos que el expr es una funcion
(define (cyclic-env id expr env)
  (let*
      ;; creamos un box vacio
      ([value-holder (box 'unspecified)]
      ;; creamos un nuevo enviroment donde asociamos el id al box vacio
       [new-env (rec-extended-env id value-holder env)]
      ;; interpretamos expr, y devuelve una closure
      ;; la closure retoranda tiene un enviroment donde el id de la función recursiva
      ;; esta asociada al box vacio
       [cls-val (interp expr new-env)])
      (begin
        ;; cambiamos el valor del box para que apunte a la misma funcion
        ;; entonces ahora tenemos un enviroment que donde la funcion tiene un enviroment que tiene
        ;; un ide que apunta a la misma funcion --- ciclicamente
        (set-box! value-holder fun-val)
        new-env)))
}|
@subsection{Testing}
Todo empieza con un enviroment vacio.
@codeblock|{
(define (run prog)
  (match (interp (parse prog) (empty-env))
    [(numV n) n]
    [(and f (closureV id body env)) f]))
}|

@codeblock|{
;;Tara:
(run '{rec {sum {fun {n} {if0 n
                              0
                              {+ n {sum {- n 1}}}
                              }}}
        {sum 4}})
}|