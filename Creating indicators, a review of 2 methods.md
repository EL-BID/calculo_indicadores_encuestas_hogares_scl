# Métodos para la creación de indicadores armonizados de SCL

La creación de indicadores dentro del código armonizado puede seguir diversos métodos. Aquí se discuten dos usados actualmente, para calcular tanto tasas (%) como valores medios (#) y absolutos (#). El ejemplo a seguir construye la variable de "tasa de ocupación".

# Primer método
1. El primer método usa un esquema de ratios, es decir numerador/denominador, y está integrado por 3 componentes (que llamamos A, B, y C). En el ejemplo de tasa de ocupación, A ejecuta un sum para calcular el total de personas en el denominador (esencialmente aquellos individuos en edad de trabajar 'pet==1'). El denominador (B) suma el total de aquellos individuos que informaron estar trabajando la semana de referencia (condocup_ci==1), y genera el scalar de valor conteniendo la tasa de ocupación a partir de la fracción de los primeros dos valores bajo el local 'valor'. Finalmente C recoge el número de muestra (sin usar factores de expansión) de individuos ocupados, valor a ser usado posteriormente por el proceso de validación estadística de los indicadores a publicar (Dado que ambos métodos calculan este valor muestral con un solo comando, podemos obviarlo para esta discusión). 

Nota: aquí el 'capture' -> 'if_rc' se usa en ambos métodos para evitar quiebres en la ejecución del código para bases de hogares que no cuentan con alguna de las variables usadas en el cálculo del indicador.

							if "`indicador'" == "tasa_ocupacion" {																						 
	A							capture sum `nivel' [w=factor_ci] if `clase'==1 & pet==1 & `clase2' ==1
								if _rc == 0 {
								local denominador = `r(sum)'
                
	B							sum `nivel' [w=factor_ci]	 if `clase'==1 & condocup_ci==1  & `clase2' ==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') * 100 

	C							sum `nivel'  if `clase'==1 & condocup_ci==1  & `clase2' ==1
								local muestra = `r(sum)'
								}
								}
                
# Segundo método
2. El segundo método recoge los valores del porcentaje de ocupados directamente del 'tab' de la variable condocup_ci, a través la librería estpost. Esta librería guarda los resultados de varios comandos de stata en 'e()'. En nuestro caso, la columna de porcentajes del tab se guarda en el vector 'e(pct)'. Para más información usar: 'help estpost'. En síntesis, este método asigna los valores de los resultados de, por ejemplo, tabulaciones, a vectores matriciales (por ej. 'mat a = e(pct)') que luego se usan para definir el local 'valor' sin el paso intermedio de la razón numerador/denominador.
							
							if "`indicador'" == "tasa_ocupacion" {
								
								capture estpost tabulate condocup_ci [w=round(factor_ci)] if `clase'==1 & pet==1 & `clase2' ==1
								if _rc == 0 {
								mat a = e(pct)
								local valor=a[1,1]
								
								capture estpost tabulate condocup_ci if `clase'==1 & pet==1 & `clase2' ==1
								mat b = e(b)
								local muestra=b[1,1]
								}
								}	

# Discusión
Este tema es relevante y debe de resolverse para que el código siga un esquema único de generación de indicadores desde el inicio. El siguiente thread presenta algunos de los puntos en la discusión sobre la estrategia a seguir (incluyendo un log con los tiempos de ejecución de cada método):
https://github.com/BID-SCL/calculo_indicadores_encuestas_hogares_scl/pull/13
