#lang scribble/manual

@require[scribble/core]

@title{Foundations on Programming Language - Lecture Notes}
@author{JPS}

@table-of-contents[]


This text book have a set of exercises and test to learn scheme and programming languages.


@section{Part I: Scheme Basics}

@subsection{Filtering}
@subsubsection{Filter Even}
@codeblock|{
(define (filter-evens lst)
  (if (empty? lst)
      empty
      (if (even? (car lst))
          (cons (car lst) (filter-evens (cdr lst)))
          (filter-evens (cdr lst)))))

(test (filter-evens (list 1 2 3 4)) (list 2 4))
}|

@subsubsection{Filter Trues}
@codeblock|{
(define (filter-true lst)
  (if (empty? lst)
      empty
      (if (car lst)
          (cons (car lst) (filter-true (cdr lst)))
          (filter-true (cdr lst)))))

(test (filter-true (list #t #t #f)) (list #t #t))

}|
@subsubsection{Filter with a condition}

@codeblock|{
(define (filter condition lst)
  (if (empty? lst)
      empty
      (if (condition (car lst))
          (cons (car lst) (filter condition (cdr lst)))
          (filter condition (cdr lst)))))

(test (filter even? (list 1 2 3 4)) (list 2 4))
(define (is-true? value) value)
(test (filter is-true? (list #t #t #f)) (list #t #t))
}|

@subsection{The fold algorithm}
@subsubsection{Sum elements}
@codeblock|{
(define (sum lst)
  (if (empty? lst)
      0
      (+ (car lst) (sum (cdr lst)))))

(test (sum (list 1 2 3)) 6)

}|

@subsubsection{All Satisfy}

@codeblock|{
(define (all-true lst)
  (if (empty? lst)
      #t
      (and (car lst) (all-true (cdr lst)))))

(test (all-true (list #t #t #t)) #t)
(test (all-true (list #t #t #f)) #f)
}|

@subsubsection{Fold}

@codeblock|{
(define (fold func initial-value lst)
  (if (empty? lst)
      initial-value
      (func (car lst) (fold func initial-value (cdr lst)))))
; sum
(test (fold + 0 (list 1 2 3)) 6)
; all satisfy
(define (and-func a b) (and a b))
(test (fold and-func #t (list #t #t #t)) #t)
(test (fold and-func #t (list #t #t #f)) #f)
}|

@subsection{Map}

@subsubsection{Add two}
@codeblock|{
(define (add-two lst)
  (if (empty? lst)
      empty
      (cons (+ 2 (car lst)) (add-two (cdr lst)))))

(test (add-two (list 1 2 3)) (list 3 4 5))
}|

@subsubsection{Multiply by two}
@codeblock|{
(define (multiply-by-two lst)
  (if (empty? lst)
      empty
      (cons (* 2 (car lst)) (multiply-by-two (cdr lst)))))

(test (multiply-by-two (list 1 2 3)) (list 2 4 6))
}|
@subsubsection{Apply a function}

@codeblock|{
(define (collect function lst)
  (if (empty? lst)
      empty
      (cons (function (car lst)) (collect function (cdr lst)))))

(define (fun-add-two n) (+ n 2))
(test (collect fun-add-two (list 1 2 3)) (list 3 4 5))

;; Using anonymous function (lambda) for addition
(test (collect (λ (n) (+ n 2)) (list 1 2 3)) (list 3 4 5))

;; Using anonymous function (lambda) for multiplication
(test (collect (λ (n) (* n 2)) (list 1 2 3)) (list 2 4 6))
}|
@subsection{Functions that create Functions}

This function return a funtion that add k to the argument
@codeblock|{
(define (fun-add k)
  (lambda (n) (+ n k)))
}|
We use this function to create a function that add two to the value sent as argument.
@codeblock|{
(define add2 (fun-add 2))
(test (add2 1) 3) ; le suma dos a uno
}|
We use this function to create a function that add four to the value sent as argument.
@codeblock|{
(define add4 (fun-add 4))
(test (add4 1) 5) ; le suma cuatro a uno
}|


@subsection{Exercise}
Racket already have a functions like we implement before.
In the exercises we will use the function foldl of scheme, that operates similar that the function accumulate (see example above).


@subsubsection{Reverse}
Use the function foldl of Scheme to create a function that receive a list as argument and return a list with the elements in reverse order.

@codeblock|{
(define (max-element list)
  (foldl ... ... ...))

(test (max-element (list 1 2 3)) 3)
(test (max-element (list 1 1 1)) 1)
(test (max-element (list 1)) 1)
(test (max-element empty) 0)
(test (max-element (list 1 100 1)) 100)
}|

@subsubsection{Max}
Use the function foldl of Scheme to create a function that receive a list as argument and return the max value of the list.

@codeblock|{
(define (reverse list)
  (foldl ... ... ...))

(test (reverse (list 1 2 3)) (list 3 2 1))
(test (reverse empty) empty)
(test (reverse (list 1)) (list 1))
(test (reverse (list 1 1)) (list 1 1))
(test (reverse (list 2 1)) (list 1 2))
}|
