#lang scribble/manual

@require[scribble/core]

@title{Foundations on Programming Language - Lecture Notes}
@author{JPS}

@table-of-contents[]


This text book have a set of exercises and test to learn scheme and programming languages.


@section{Part II: Mutable Data Structures}

@subsection{Enviroment, Store, and Utility Functions}


@codeblock|{

;; Values
(define-type Value
  [numV (n number?)]
  [closureV (id symbol?) (body Exp?) (env Env?)]
  [boxV (location number?)])

;; Environment
(define (Any? v) #t)
(define-type Env
  [empty-env]
  [extended-env (id symbol?) (val number?) (env Env?)])

(define (env-lookup x env)
  (match env
    [(empty-env) (error 'env-lookup "not found: ~a" x)]
    [(extended-env id val sub-env)
     (if (symbol=? id x)
         val
         (env-lookup x sub-env))]))
;; Store
(define-type Store
  [empty-str]
  [extended-str (id number?) (val Value?) (env Store?)])

(define (str-lookup x env)
  (match env
    [(empty-str) (error 'env-lookup "not found: ~a" x)]
    [(extended-str id val sub-str)
     (if (= id x)
         val
         (str-lookup x sub-str))]))

(define (next-location str)
  (match str
    [(empty-str) 0]
    [(extended-str _ _ sub-str) (add1 (next-location sub-str))]))

;; Value*Store
(define-type Value*Store
  [value-store (val Value?) (str Store?)])

}|


@subsection{Gramatica}
Soportaremos la misma gramática, implementando with como azucar sintactico.
@codeblock|{
#|
Grammar for expressions:
  <s-expr> ::= <num>
              | <sym>
              | (list '+ <s-expr> <s-expr>)
              | (list '- <s-expr> <s-expr>)
              | (list 'if0 <s-expr> <s-expr> <s-expr>)
              | (list 'with (list <sym> <s-expr>) <s-expr>)
              | (list 'fun (list <sym>) <s-expr>)
              | (list 'newbox <s-expr>)
              | (list 'openbox <s-expr>)
              | (list 'setbox <s-expr> <s-expr>)
              | (list 'seqn <s-expr> <s-expr>)
              | (list <s-expr> <s-expr>)
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
  [call (cls-exp Exp?) (arg-expr Exp?)]
  [newbox (val Exp?)]
  [openbox (box Exp?)]
  [setbox (box Exp?) (val Exp?)]
  [seqn (e1 Exp?) (e2 Exp?)])
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
    [(list 'newbox e) (newbox (parse e))]
    [(list 'openbox e) (openbox (parse e))]
    [(list 'setbox e1 e2) (setbox (parse e1) (parse e2))]
    [(list 'begin e1 e2) (seqn (parse e1) (parse e2))]
    [(list 'with (list sym se) be) (call (fun sym (parse be)) (parse se))]
    [(list 'fun (list sym-arg) be) (fun sym-arg (parse be))]
    [(list cls-exp arg-exp) (call (parse cls-exp) (parse arg-exp))]
    [else (error 'parse "syntax error")]))

}|
@subsection{Circular Interpreter}
En este ejemplo nuestro interprete recibira una expresion en nuestro lenguaje y devolvera un valor en scheme.
En este ejemplo, para representar las funciones, utilizaremos al lambda de scheme.


@subsection{Interpretation}

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
@codeblock|{
;; intepr (Exp x Env) --> Value*Store
(define (interp expr env str)
  (match expr
    [(num n) (value-store (numV n) str)]
    [(id s)  (value-store (str-lookup (env-lookup s env) str) str)]
    [(fun sym-arg fun-body) (value-store (closureV sym-arg fun-body env) str)]
    
    [(plus l r)
     (match (interp l env str)
       [(value-store l-val l-str)
        (match (interp r env l-str)
          [(value-store r-val r-str)
           (value-store (num+ l-val r-val) r-str)])])]
    
    [(minus l r)
     (match (interp l env str)
       [(value-store l-val l-str)
        (match (interp r env l-str)
          [(value-store r-val r-str)
           (value-store (num- l-val r-val) r-str)])])]
    
    [(if0 c t f)
     (match (interp c env str)
       [(value-store c-val c-str)
        (if (num-zero? c-val)
            (interp t env c-str)
            (interp f env c-str))])]

    [(call cls-exp arg-exp)
     (match (interp arg-exp env str)
       [(value-store arg-val arg-str)
        (match (interp cls-exp env arg-str)
          [(value-store (closureV param body fenv) fun-str)
           (define new-loc (next-location fun-str))
           (interp body
                   (extended-env param new-loc fenv)
                   (extended-str new-loc arg-val fun-str))])])]
    
    [(newbox val-expr)
     (match (interp val-expr env str)
       [(value-store val-val val-str)
        (define new-loc (next-location val-str))
        (value-store (boxV new-loc)
                     (extended-str new-loc val-val val-str))])]

    [(openbox box-expr)
     (match (interp box-expr env str)
       [(value-store (boxV loc) b-str)
        (value-store (str-lookup loc b-str) b-str)])]

    [(setbox box-expr val-expr)
     (match (interp box-expr env str)
       [(value-store (boxV loc) b-str)
        (match (interp val-expr env b-str)
          [(value-store val-val val-str)
           (value-store val-val
                        (extended-str loc val-val val-str))])])]

    [(seqn e1 e2)
     (match (interp e1 env str)
       [(value-store _ s1)
        (interp e2 env s1)])]))
}|

@subsection{Testing}
Todo empieza con un enviroment vacio.
@codeblock|{
(define (run prog)
  (match (interp (parse prog) (empty-env) (empty-str))
    [(value-store (numV n) s) n]
    [(value-store (and b (boxV _)) s) b]
    [(value-store (and f (closureV id body env)) s) f]))
}|

@codeblock|{
(run '{with {x {newbox 2}}
        {begin
          {setbox x 3}
          {openbox x}}})
}|