#lang scribble/manual

@require[scribble/core]

@title{Foundations on Programming Language - Lecture Notes}
@author{JPS}

@table-of-contents[]

This text book have a set of exercises and test to learn scheme and programming languages.

@section{Macros en Racket: Teoría y Ejemplos}

Las macros en Racket son una herramienta poderosa que permite definir nuevas construcciones de lenguaje, controlar el flujo de evaluación, y evitar la repetición de patrones de código. A diferencia de las funciones, las macros operan en el código fuente antes de su evaluación, lo que permite modificar y generar código dinámicamente.

@subsection{¿Por qué macros?}

Imagina que quieres ejecutar un bloque de código sólo si se cumple una condición. Puedes usar una función como esta:

@racketblock[
(define (when1 condition body)
  (cond [condition (begin body)]))
(when1 (< 1 0) (displayln "Esto NO debería imprimirse"))
]

Este ejemplo falla porque @racket[body] se evalúa antes de entrar a la función, lo que puede provocar efectos secundarios no deseados.

@subsection{Usando macros correctamente}

Con macros, podemos controlar exactamente cuándo y si se evalúa el cuerpo:

@racketblock[
(define-syntax when2
  (syntax-rules ()
    [(when condition body)
     (cond [condition body])]))
(when2 (< 1 0) (displayln "Esto NO debería imprimirse"))
]


@subsection{Intercambio de variables: @racket[swap!]}

Cuando intentamos intercambiar dos variables usando una función, no funciona como esperamos porque las funciones en Racket no pueden modificar variables externas directamente.

@bold{Versión incorrecta con función:}
@racketblock[
(define (swap-fn x y)
  (let ([tmp x])
    (set! x y)
    (set! y tmp)))

(define a 1)
(define b 2)
(swap-fn a b)
(displayln a) ; → sigue siendo 1
(displayln b) ; → sigue siendo 2
]

@italic{La función no modifica los valores originales de @racket[a] y @racket[b], solo modifica copias locales.}

@bold{Versión correcta con macro:}
@racketblock[
(define-syntax swap!
  (syntax-rules ()
    [(swap! x y)
     (let ([tmp x])
       (set! x y)
       (set! y tmp))]))

(define x 1)
(define y 2)
(swap! x y)
(displayln x) ; → 2
(displayln y) ; → 1
]

@italic{La macro reescribe el código para operar directamente sobre las variables originales.}


@bold{Versión incorrecta con función:}
@racketblock[
(define (swap-fn x y)
  (let ([tmp x])
    (set! x y)
    (set! y tmp)))
]

Esto no intercambia los valores reales de @racket[x] y @racket[y].

@bold{Versión correcta con macro:}
@racketblock[
(define-syntax swap!
  (syntax-rules ()
    [(swap! x y)
     (let ([tmp x])
       (set! x y)
       (set! y tmp))]))
]

@subsection{Bucles con macros: @racket[do-times]}

@racketblock[
(define-syntax do-times
  (syntax-rules ()
    [(do-times n body ...)
     (let loop ([i 0])
       (when (< i n)
         body ...
         (loop (+ i 1))))]))
(do-times 3
  (displayln "Hola"))
]

@subsection{Control de flujo y verificación: @racket[assert]}

@racketblock[
(define-syntax assert
  (syntax-rules ()
    [(assert test)
     (unless test
       (display "Fallo en la aserción"))]))
(assert (= 5 5)) ; OK
(assert (= 5 0)) ; Muestra: "Fallo en la aserción"
]

@subsection{Bucles tipo @racket[for]: inyección de variables}

Una macro que inyecta una variable implícita @racket[it]:

@racketblock[
(define-syntax (for2 stx)
  (syntax-case stx (from to in)
    [(for2 from low to high in body ...)
     (with-syntax ([it (datum->syntax stx 'it)])
       #'(let ([low-val low]
               [high-val high])
           (let loop ([it low-val])
             (when (<= it high-val)
               body ...
               (loop (add1 it))))))]))
(for2 from 2 to 5 in (displayln it))
]

Este tipo de macros ilustran cómo se puede romper o controlar la higiene de variables de forma intencional.


@subsection{Macros de Bucle: @racket[for0] y @racket[for1]}

Crear estructuras de bucle personalizadas en Racket es un uso típico de las macros. Aquí veremos dos versiones: una que deja que el usuario nombre la variable del bucle, y otra que intenta inyectar una variable por defecto (@racket[it]).

@bold{Versión @racket[for0] — El usuario nombra la variable}

@racketblock[
(define-syntax for0
  (syntax-rules (from to in)
    [(for0 var from low to high in body ...)
     (let ([low-val low]
           [high-val high])
       (let loop ([var low-val])
         (when (<= var high-val)
           body ...
           (loop (add1 var)))))]))

(for0 i from 2 to 5 in 
  (for0 j from 1 to 3 in  
    (printf "~a ~a~n" i j)))
]

@italic{Ventaja:} El usuario elige el nombre de la variable, lo cual es claro y flexible.  
@italic{Desventaja:} La sintaxis es un poco más cargada.

@bold{Versión @racket[for1] — Intenta inyectar @racket[it] automáticamente (pero falla)}

(define-syntax for1
  (syntax-rules (from to in)
    [(for1 from low to high in body ...)
     (let ([low-val low]
           [high-val high])
       (let loop ([var low-val])
         (when (<= var high-val)
           body ...
           (loop (add1 var)))))]))

;; Esto genera error:
;; (for1 from 2 to 5 in (displayln it))
]

@italic{Problema:} Aunque la macro define una variable llamada @racket[it], el código del usuario no puede verla debido a las reglas de higiene léxica.

@bold{Solución mejorada:} Si realmente queremos inyectar @racket[it], debemos usar el alcance correcto:

@racketblock[
(define-syntax (for2 stx)
  (syntax-case stx (from to in)
    [(for2 from low to high in body ...)
     (with-syntax ([it (datum->syntax stx 'it)])
       #'(let ([low-val low]
               [high-val high])
           (let loop ([it low-val])
             (when (<= it high-val)
               body ...
               (loop (add1 it))))))]))

(for2 from 2 to 4 in (displayln it))
]

@italic{Conclusión:} Aunque es tentador inyectar nombres mágicos como @racket[it], en general es mejor permitir que el usuario elija los nombres. Esto mantiene el código más claro, flexible y menos propenso a errores de higiene.


@subsection{Resumen}

Las macros te permiten:
@itemlist[
@item{Crear nuevas formas de control de flujo}
@item{Evitar evaluación innecesaria}
@item{Modificar el lenguaje a tus necesidades}
@item{Generar estructuras repetitivas de forma segura y expresiva}
]
