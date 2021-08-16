**SCL Data - Data Ecosystem Working Group**

[![IDB Logo](https://scldata.iadb.org/assets/iadb-7779368a000004449beca0d4fc6f116cc0617572d549edf2ae491e9a17f63778.png)](https://scldata.iadb.org)

# Cálculo de Indicadores de Encuestas de Hogares
Este código armoniza el cálculo de los indicadores de las plataformas del sector social del BID.


## Descripción

Este repositorio contiene los scripts para el cálculo de los indicadores de las plataformas del sector social del BID. Estos tienen como fuente de información las encuestas a hogares armonizadas del sector social. Los indicadores de estas bases de datos son construidas bajo un enfoque y estructura común, con nombres, definiciones y desagregaciones estandarizadas y almacenadas en objetos por anio y pais. Actualmente, se calculan más de **140 indicadores** para **26 países** de LAC desde 2006. 

## Requisitos

**Versión**

- STATA 16 o superior.

**Paquetes necesarios para su funcionamiento**

- estout
- inequal7

## Estructura

El repositorio contiene dos subcarpetas: **Input** y **Output**, así como dos dofiles principales: **scl_indicators.do** y **scl_programs.doh**. 

La subcarpeta *Input* contiene los scripts insumo para la creación de la base de datos. Estos son:

1. El directorio de cada encuesta (país, ronda, anio);
2. variables intermedias para el cálculo de los indicadores; se compone de varios scripts (uno por división);
3. el script para el formato de la base final.

La subcarpeta *Output* contiene la versión final de la base de datos en formato dta y CSV. 

El script principal del repositorio es `scl_indicators.do` y que se explica en la sección B. Este script incluye un conjunto de programas creados para ayudar a calcular los indicadores, que se encuentran en el script auxiliar `scl_programs.doh`, el cuál se explica a continuación.

**A. Programas auxiliares para el cálculo de indicadores**

El script `scl_programs.doh` define un conjunto de programas que se utilizan para calcular indicadores en el script principal. La extensión *.doh* se utiliza para indicar que este script es un *header*, o un archivo auxiliar que se incluye en el script principal. Los programas definidos se enumeran a continuación.

* **Porcentaje**: `scl_pct name varname indcat [if]` - calcula los porcentajes para las encuestas. Este comando se basa en el comando `svy:proporción` y calcula el porcentaje de la categoría `indcat` en la variable `varname`. En la mayoría de los casos de indicadores de encuestas de hogares, el valor de `indcat` es `"1" `. 
* **Nível**: `scl_nivel name varname [if]` - calcula indicadores de nivel. Se basa en el comando `svy:total` y calcula el valor de la suma de la variable `varname` dentro de la desagregación actual. 
* **Promedio**: `scl_mean name varname [if]` - calcula indicadores de promedio. Se basa en el comando `svy:mean` y calcula el valor promedio de la variable `varname` dentro de la desagregación actual. 
* **Mediana**: `scl_median name varname [if]` - calcula indicadores de mediana. Se basa en el comando `_pctile` con la opcción `p(50)` y calcula el valor de la mediana de la variable `varname` dentro de la desagregación actual. 
* **Razón**: `scl_ratio name var1 var2 [if]` - calcula indicadores formados por la relación entre dos variables. Se basa en el comando `svy:ratio var1/var2` y calcula la relación entre las dos variables.
* **Gini**: `scl_ratio name varname [if]` - calcula o indicadores de desigualdad. Se basa en el comando `svylorenz` y calcula el coeficiente de gini para la variable `varname` dentro de la desagregación actual.

En todos los comandos, el primer parámetro `nombre` indica el identificador de este indicador, el cuál se generará en el archivo de salida y de acuerdo con lo definido en el documento. [D.1.2.1 Diccionario - indicadores encuestas de hogares.xlsx](https://idbg.sharepoint.com/:x:/r/sites/DataGovernance-SCL/Shared%20Documents/General/Documentation/D.%20Collections/D.1-Household%20Socio-Economic%20Surveys/D.1.2%20c%C3%A1lculo_indicadores/D.1.2.1%20Diccionario%20-%20indicadores%20encuestas%20de%20hogares.xlsx?d=wc93240ed70b94a379f3f183978d1fa40&csf=1&web=1&e=nSL4hL), columna "indicator". La cláusula `[if]` debe utilizarse cuando sea necesario restringir el cálculo a muestras más específicas que el nivel actual de desagregación, pero no es necesario establecer el nivel de desagregación ya que este ya está identificado automáticamente por el programa principal.


Dado que los cálculos de los indicadores son muy similares entre sí, con solo algunos cambios, se decidió crear estos programas auxiliares como una forma de simplificar la programación de los indicadores. El uso de este conjunto estandarizado de comandos reduce la probabilidad de errores de codificación y aumenta la eficiencia de la escritura y el mantenimiento del código.

**B.	Gúia básica del código principal**


El script `scl_indicators.do` es el código principal para calcular indicadores. Este programa, una vez ejecutado, creará un nuevo comando en STATA:
```
. scl_indicators ISO AÑO
```
donde `ISO` debe ser reemplazado por el código ISO-Alpha3 del *país* y `AÑO` por el *año* que desea calcular.

El comando `scl_indicators` calcula todos los indicadores del país y del año pasado como parámetros y guarda el resultado en un archivo .dta (`Output/Indicadores_encuestas_hogares_scl_ISO20XX.dta`) y un archivo CSV (`Output/csv/indicadores_encuestas_hogares_ISO_ENCUESTA_20XX`). El nombre de la encuesta se incluye automáticamente en el nombre del archivo CSV.

***Preliminares***

Para que se ejecute el código del script, STATA debe poder encontrar el directorio GitHub y el directorio donde se encuentran las bases de datos armonizadas de las encuestas.

El script obtiene esta información en las variables globales `$gitFolder` y `$source`. Una vez que estas rutas son diferentes para cada usuario, estas variables no se crean en el código principal. Deberá inicializar estas variables en un archivo en su directorio personal. El directorio personal es donde STATA busca programas personales y su ubicación se puede encontrar usando el comando:
```
display "`=c(sysdir_personal)'"
```
Dentro de esta carpeta, cree un archivo con el nombre devuelto por el siguiente comando:
```
display "`=c(username)'_`=c(os)'.doh"
```
Inicialice las variables `global gitFolder` y `global source` en este archivo con la ruta apuntando a los directorios respectivos en su computadora. Este script será cargado automáticamente por el programa `scl_indicators`. Si este archivo no existe, el programa identificará este hecho y generará un mensaje indicando que es necesario crearlo.


***Carpeta Input***

Algunos indicadores necesitan variables intermedias para su cálculo. Cada división debe crear estas variables, según su necesidad, en el archivo designado para ella dentro de la carpeta *Inputs*, de la siguiente manera:
* `var_tmp_EDU.do`: Variables intermedias de EDU;
* `var_tmp_GDI.do`: variables intermedias de GDI;
* `var_tmp_LMK.do`: Variables intermedias LMK;
* `var_tmp_MIG.do`: variables intermedias MIG;
* `var_tmp_SOC.do`: Variables intermedias de SCL (pobreza y demografia).

También en este directorio, se encuentran el script `dataframe_format.do`, que hace ajustes al formato del archivo de salida, como se detallará más adelante, y el script `Directorio HS LAC.do` que identifica, para cada país y año, las siglas correspondientes a la investigación respectiva y la ronda utilizada para generar los indicadores. 


***Secciones del código principal***

La primera sección de código comprueba la existencia del script de configuración de las variables `$gitFolder` y `$source`. Si se encuentra el script, se ejecuta mediante el comando `include` y se presenta los valores de estas variables usando el comando `display`. Si no se encuentra el script, la ejecución finaliza con un mensaje de error.

A continuación, se crea el comando `scl_indicators`, especificando dos parámetros: `pais` y `ano`. El código se divide en las siguientes partes:

1. *Configuración del programa*: define rutas para los do-Files que se cargarán en todo el programa y define la variable global `geography_id`.


2. *Creación de la base de datos de salida*: utiliza los comandos `tempfile`, `tempname` y `postfile` para crear un archivo temporal que almacene los indicadores calculados por el programa.
Este arquivo se estrutura le la siguiente manera:
	* tiempo_id (str4)
	* pais_id (str3)
	* fuente (str25)
	* geografia_id (str25)
	* sexo (str25)
	* area (str25)
	* quintil_ingreso (str25)
	* nivel_educativo (str25)
	* grupo_etario (str25)
	* etnicidad (str25)
	* tema (str25)
	* indicador (str25)
	* description (str35)
	* valor
	* se
	* cv

	La estructura de este archivo debe seguir el modelo definido por SCL Data Governance, en el documento [M.232 Processed Schema Standard.xlsx](https://idbg.sharepoint.com/:x:/r/sites/DataGovernance-SCL/Shared%20Documents/General/Documentation/M.%20Manuals%20%26%20Standards/2.%20Standards,%20Methods%20and%20Processes/3.%20Standards/M.232%20Processed%20Schema%20Standard.xlsx?d=wc586af7d41c34c01917fc33d3d5cf302&csf=1&web=1&e=Ve5hqw). Para asegurar el cumplimiento del esquema definido, al final del programa se ejecuta el script `dataframe_format.do`, que realiza los ajustes de formato necesarios de acuerdo con este manual.

3. *Carga de archivos de datos*: El script carga el archivo de datos de país y año proporcionado como argumento en la llamada al programa. Si no se encuentra el archivo, se cargará un modelo de datos vacío (una base de datos sin muestras). En este caso, los indicadores para este país y año se generarán todos con el valor *"missing"*. El archivo de datos vacío se encuentra en la carpeta *Inputs* y se llama `template.dta`.

4. *Creación de variables de desagregación*: se crean variables auxiliares para controlar la desagregación de indicadores. Se trata de variables binarias que identifican, para cada individuo de la muestra, a qué grupo de desagregación pertenece. Por ejemplo, el grupo de desglose "Total" coincide con todos los individuos. Por lo tanto, la variable de pertenencia para esta desagregación simplemente asigna un valor de "1" a toda la base de datos. La variable que identifica al grupo "Mujer", en cambio, asigna un valor de "1" sólo a aquellos individuos identificados por el sexo femenino. A continuación se muestra un ejemplo de la creación de algunas variables de desagregación:
```
**** Desagregaciones *************
gen byte Total  =  1
gen Hombre = (sexo_ci==1)  
gen Mujer  = (sexo_ci==2)
gen Urbano = (zona_c==1)
gen Rural  = (zona_c==0)
```

5. *Inclusión de variables intermedias*: Inmediatamente después de la creación de las variables de desagregación, se ejecutan los scripts del directorio *Input* para crear las variables intermedias de cada división.

6. *Cálculo de indicadores*: luego, se inserta el código que calcula los indicadores para cada división. Esta sección del código se divide en *temas*, que se identifican estableciendo la variable global `tema`. Cada división debe incluir en el código principal aquellos indicadores que sean de su responsabilidad, dentro del respectivo apartado del código indicado por la variable temática. Los temas definidos son "demografia" (SCL), "educacion" (EDU), "trabajo" (LMK), "pobreza" (SCL), "vivienda" (SCL), "diversidad" (GDI), y "migracion" (MIG).

	Una vez definida la temática, se sigue con la selección de los desgloses que se aplicarán en el cálculo de los indicadores. Estas desagregaciones se definen en variables locales. Los indicadores se calculan dentro de un loop `foreach`, donde se aplica cada desagregación definida en las variables. A continuación se muestra un ejemplo de la estructura de indicadores para el tema de educación. Las desagregaciones definidas son "sexo" (Total, Hombre, Mujer), "área" (Total, Rural, Urbana), "quintiles de ingreso" (Total, Q1, Q2, Q3, Q4, Q5) y "etnicidad" (Total, Indi, Afro, Otro).
    
	También tenga en cuenta, en el ejemplo siguiente, que dentro del loop, antes de calcular cualquier indicador, debe actualizar la variable global `current_slice`. Esta variable le dice a los programas auxiliares qué desagregaciones se deben aplicar. De esta forma, ya no es necesario especificar desagregaciones en el código del indicador, ya que el programa captura automáticamente lo seleccionado en la variable `current_slice`. Se incluye un comando `display` para generar qué tema y qué desagregación está siendo calculado actualmente por el programa, con el fin de facilitar el seguimiento de la ejecución.

    Para el cálculo del indicador en el interior del loop, se puede utilizar cualquiera de los seis comandos de cálculo de indicadores de SCL que se definen en `scl_programs.doh` :warning: *Todos los indicadores deben calcularse utilizando uno de estos comandos*.

```
************************************************
  global tema "educacion"
************************************************
// Division: EDU
// Authors: Angela Lopez 
************************************************				
		
local sexos Total Hombre Mujer  
local areas Total Rural Urbano
local quintil_ingresos Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5
local etnicidades Total Indi Afro Otro	

foreach sexo of local sexos {	
	foreach area of local areas {
		foreach quintil_ingreso of local quintil_ingresos {
			foreach etnicidad of local etnicidades {
			
			/* Parameters of current disaggregation levels, used by all commands */
			global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
            
			noisily display "$tema: $current_slice"
            
            /*** CÓDIGO DE CÁLCULO DE LOS INDICADORES ***/
            
            }
        }
     }
}
```


Una vez finalizada la generación de indicadores para todos los temas, se usa el comando `postclose` para cerrar el archivo de salida temporal que fue generado por el script. Para hacer coincidir el formato de salida con el definido en los manuales de SCL, se ejecuta el script `Input/dataframe_format.do`. Este script se encarga de asegurarse de que el archivo generado al final seguirá el esquema definido en [M.232 Processed Schema Standard.xlsx](https://idbg.sharepoint.com/:x:/r/sites/DataGovernance-SCL/Shared%20Documents/General/Documentation/M.%20Manuals%20%26%20Standards/2.%20Standards,%20Methods%20and%20Processes/3.%20Standards/M.232%20Processed%20Schema%20Standard.xlsx?d=wc586af7d41c34c01917fc33d3d5cf302&csf=1&web=1&e=Ve5hqw).

Finalmente, los comandos `save` y `export` (con la opción de reemplazar) se ejecutan para guardar los archivos dta y CSV, respectivamente, en el directorio *Outuput*.