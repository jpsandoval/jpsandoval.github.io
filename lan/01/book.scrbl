#lang scribble/manual

@require[scribble/core]

@title{Foundations on Programming Language - Lecture Notes}
@author{Juan Pablo Sandoval}

@table-of-contents[]


This text book have a set of exercises and test to learn scheme and programming languages.


@section{Part I: Scheme Basics}

@subsection{Data Types, Functions and Lists}

@subsubsection{Primitive Data Types}
Exploring the use of numbers in Scheme, including integers, real numbers, and fractions:
@codeblock|{
3      ; Números
1.02   ; Reales
2/3    ; Fracciones
}|


Demonstrating boolean values and their use in logical expressions:
@codeblock|{
#t     ; Verdad
#f     ; Falso
(and (> 3 2) (equal? 1 1))  ; Componiendo Expresiones, and es otra función

}|

@subsubsection{Strings and Symbols}
Illustrating how strings and symbols are utilized in Scheme:
@codeblock|{
"hola" ; Strings
'hola  ; Symbols
}|

@subsubsection{Predefined Functions}
A look at some of the predefined functions available in Scheme:
@codeblock|{
(+ 1 2)    ; El + es una función con N argumentos
(* 1 2 3)  ; De igual forma el *
(sqrt 4)   ; Raiz Cuadrada
}|

@subsubsection{Console Printing}
Introducing how to print outputs to the console in Scheme:
@codeblock|{
(printf "Hello, World!\n")
}|

@subsubsection{Global Identifiers}
Defining and using global identifiers in Scheme:
@codeblock|{
(define MAX 100)
MAX
(define score 99)
(+ score 1)
}|

@subsubsection{Conditionals}
Using conditional expressions to control logic flow:
@codeblock|{
(define (grade score)
  (if (> score 90)
      "A"
      (if (> score 80)
          "B"
          (if (> score 70)
              "C"
              "D"))))
}|

@subsubsection{Local Identifiers}
Managing scope with local identifiers in Scheme:
@codeblock|{
(let ([precio 100]   ; Precio antes de impuestos
      [impuesto 0.19])  ; Tasa de impuesto del 19%
  (+ precio (* precio impuesto)))
}|

@subsubsection{Defining Functions}
How to define and use custom functions:
@codeblock|{
(define (max a b) (if (< a b) b a))
(define (factorial n)
  (if (= n 0)
      1
      (* n (factorial (- n 1)))))
}|

@subsection{Working with Lists and Pairs}
Understanding lists and pairs, the building blocks of complex data structures in Scheme:
@codeblock|{
(cons 1 2)
(car (cons 1 2)) ; extrae el primer elemento de un par
(cdr (cons 1 2)) ; extrae el segundo elemento de un par

(list 1 2 3)
(append (list 1 2 3) (list 4 5 6))
}|

@subsubsection{Recursive Functions}
Illustrating recursion through list processing exercises:
@codeblock|{
(define (sum lst)
  (if (empty? lst)
      0
      (+ (car lst) (sum (cdr lst)))))
}|
@codeblock|{
(define (exist? elem lst)
  (if (empty? lst)
      #f
      (if (equal? elem (car lst))
          #t
          (exist? elem (cdr lst)))))
}|