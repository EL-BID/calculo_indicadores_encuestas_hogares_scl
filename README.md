# calculo_indicadores_encuestas_hogares_scl
Este código armoniza el cálculo de los indicadores de las plataformas del sector social del BID.

# Descripción

Este repositorio contiene los scripts para el cálculo de los indicadores de las plataformas del sector social del BID. Estos tienen como fuente de información las encuestas a hogares armonizadas del sector social. Los indicadores de estas bases de datos son construidas bajo un enfoque y estructura común, con nombres, definiciones y desagregaciones estandarizadas y almacenadas en objetos por anio y pais. Actualmente, se calculan 106 indicadores para 26 países de LAC de 2006 a 2020. 

# Ubicación
TBC

# Paquetes necesarios para su funcionamiento

estout
inequal7

# Estructura

El repositorio contiene dos subcarpetas: Input y Output, así como dos dofiles: Armonizacion -plataformas-SCL .

La subcarpeta Input contiene los scripts insumo para la creación de de la base de datos. Estos son: i) El directorio de cada encuesta (país, ronda, anio), ii) variables intermedias para el cálculo de los indicadores; se compone de varios scripts (uno por división) y iii) el script para el formato de la base final.
La subcarpeta Output contiene la versión final de la base de datos en formato dta. 

El srcipt principal del repositorio es Armonizacion -plataformas-SCL y para su uso y comprensión hemos creado la siguiente guía y recomendaciones:

A.	Reglas y gúia básica del código 

Nuestro do-file principal está compuesto por 3 secciones: 1) el program set up, 2) la sección de creación de variables e indicadores y la sección 3) exportar resultados. 

1.	Program set up: Comandos, ajustes y rutas necesarias para que el programa corra correctamente. 
Es en esta sección y solo en esta sección se incorpora cualquier comando adicional que necesitemos descargar para el funcionamiento del programa. Por ejemplo, el comando inequal7 que fue el utilizado para calcular el índice de GINI.
El programa trabaja con tres rutas principales: 

i)	source donde se encuentra las bases de datos armonizadas insumo para los indicadores.
ii)	input donde se encuentra la información adicional necesaria para crear nuestros indicadores. Acá se encuentran los do-files de creación de las variables intermedias de cada división, variables de formato de la base de datos. 
Esta sección no debe ser modificada a menos que exista la necesidad de descargar un comando o modificar alguna ruta en específico.
iii) output que usamos para exportar las bases y resultados de los cálculos.

2.	Creación de variables e indicadores
En esta sección van a interactuar todas las divisiones del Sector. Esto debe hacerse de forma ordenada, teniendo en cuenta la estructura del programa. 

El programa crea una base de datos desde muchas fuentes de información o diferentes contenidos en el proceso (las encuestas a hogares armonizadas de la región). El comando postfile permite hacer esto a través del uso de bases temporales que se van construyendo de forma simultánea. 
En nuestro programa, la estructura de esta base se hace evidente con la sentencia postfile `ptablas' donde se nombran 10 variables que se construyen desde las encuestas a hogares del sector para los países y años que se encuentren enunciados en las locales pais ano, y calcula los indicadores correspondientes a los temas de cada división enunciados en la local temas (líneas 39 – 41).  
Esta sección tiene 3 funciones principales con consideraciones específicas:
i)	Llamar cada una de las bases de datos por país – año – ronda

Esto tiene repercusión en la estructura del programa y aspectos que se deben tener en cuenta al crear los indicadores y sus desagregaciones. Si bien el programa llama a todos los países y años, no todos los países tienen encuesta alguna o para algunos años. Es por esto que existe la sentencia a) if _rc == 0 {} en la línea 57 y la sentencia b) if _rc != 0  {} en la 872 (a 4 de abril del 2020).
Estas sentencias dividen el programa en dos: a) cuando existe la base de datos y b) cuando no existe.

ii)	Llamar los do-files para la creación de variables intermedias

Cuando existe una base de datos para el año x del país y, lo primero que hace el programa es generar las variables necesarias para crear cada uno de los indicadores y sus desagregaciones. Las variables que compartimos todas las divisiones en común como sexo, área e ingreso se encuentran enunciadas en el programa. Las variables que son específicas para las desagregaciones o variables intermedias para crear los indicadores de cada división se encuentran en los archivos dentro de la ruta en la global temporal y son llamadas por la sentencia "${temporal}\var_tmp_DIV.do" siendo DIV = EDU LMK GDI MIG SPH SCL
Cada división esta encargada de incluir las variables que necesita para sus indicadores y desagregaciones en su propio do-file de una forma ordenada y teniendo en cuenta las especificaciones de la sección A.

A tener en cuenta: cada una las desagregaciones y variables intermedias deben ser variables dicótomas de 1 y 0. De esta forma si se quiere desagregar un indicador por sexo se crean dos variables hombre = (sexo_ci==1) y mujer =(sexo_ci ==2), esto facilita el calculo de los indicadores utilizando locales y loops.

iii)	Calcular los indicadores de cada sector
Debe tenerse en cuenta que se van a realizar procesos diferentes dependiendo si la base de datos existe o no existe (a) if _rc == 0 {} en la línea 57 y la sentencia b) if _rc != 0  {})

a)	Si la base de datos existe:
En la sección 1.2 del programa se comienzan a nombrar los indicadores por cada tema. Es importante poner el nombre de cada uno de los indicadores de acuerdo con su tema luego de la local indicadores. Esto sirve también de tablero de control, pues el programa sólo va a calcular aquellos indicadores que se nombren en esta sección. El nombre debe ser único, comprensible y corto en la medida de los posible. 

Luego de nombrar los indicadores, se procede a escribir su fórmula de cálculo. El programa se encuentra dividido por temas de forma tal que los indicadores de demografía, vivienda y pobreza son responsabilidad del front office, educación de EDU, laboral de LMK, diversidad de GDI y migración MIG.

Los temas se encuentran ya definidos dentro del programa, cada uno debe escribir el código de cada indicador. Lo primero que debe tener en cuenta son sus desagregaciones. El nombre del loop que se definió para crear las desagregaciones de los indicadores es clases. Las desagregaciones por clases conciernen a un filtro del indicador por variables adicionales que describen el indicador sin afectar su población objetivo. Pueden ser sexo (hombre, mujer) área (urban rural) ingreso (quintil1 quintil 2… quintil 5).
Otro tipo de variabilidad de los resultados de los indicadores se define en el loop niveles. Los niveles son filtros de los indicadores que cambian la población objetivo del indicador. Por ejemplo, para la tasa de ocupación de la población de 15 a 24 años o la tasa de ocupación para la población de 15 – 64, un nivel puede ser desagregado por clase. 
cada una de estas desagregaciones debe corresponder al nombre exacto de una variable creada y dicótoma que tome el valor de 1 cuando verdadera.

La mayoría de los indicadores son relaciones porcentuales o tasas 
para esto se define el numerador y denominador de cada indicador haciendo uso de sus valores en escalares a nivel expandido y teniendo en cuenta las desagregaciones deseadas.
También se deja una última línea donde se estima una local del numerador a nivel muestra llamado muestra. Esto se hace para poder llevar un control en la base de datos de la representatividad del indicador. 

Cada una de las locales creadas para el calculo de los indicadores van a ser guardadas en nuestro postfile teniendo en cuenta el orden en el cual definimos nuestras variables en la línea 35. 

b)	Si la base de datos no existe 

Si la base de datos no existe, se deben igual definir los nombres de los indicadores por tema luego de la local indicadores luego de if _rc != 0

Acá lo importante es mantener la sincronía en las locales que nombran las clases y los niveles para cada indicador, así como darle la instrucción al postfile que ponga missing value (.) en la variable de valor y muestra.

3.	Exportar resultados 

