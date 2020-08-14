/*==================================================
project:       Validar la calidad de los indicadores calulados con base en las encuestas a hogares armonizadas del sector
Author:        Angela Lopez 
E-email:       alop@iadb.org
url:           
Dependencies:  
----------------------------------------------------
Creation Date:    27 Jul 2020 - 09:26:09
Modification Date:   
Do-file version:    01
References:          
Output:             
==================================================*/

/*==================================================
              0: Program set up
==================================================*/
version 16.1
drop _all

global source  	 "C:\Users\ALOP\Inter-American Development Bank Group\Data Governance - SCL - General\Proyecto - Data management\Bases tmp"
global output 	 "C:\Users\alop\Desktop\GitRepositories\calculo_indicadores_encuestas_hogares_scl\Output"

global covidtmp  "C:\Users\ALOP\Inter-American Development Bank Group\Data Governance - SCL - General\Proyecto - Data management\Bases tmp"


/*==================================================
              1: Abre base a analizar 
==================================================*/

use "${source}\indicadores_encuestas_hogares_scl_converted_final.dta"


/*==================================================
              2: creación valores Z
==================================================*/

*preserve
 
*keep if tema == "educacion"
keep tiempo_id pais_id clase_id nivel_id tema indicador tipo valor muestra 

local paises ARG BHS BRB BLZ BOL BRA CHL COL CRI ECU SLV GTM GUY HTI HND JAM MEX NIC PAN PRY PER DOM SUR TTO URY VEN
local tiempo 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019
local indicadores tasa_bruta_asis tasa_neta_asis tasa_asis_edad tasa_no_asis_edad Años_Escolaridad_25_mas Ninis_1 Ninis_2 tasa_terminacion leavers
local clases Total Hombre Mujer quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
local clases2 Total Hombre Mujer Rural Urbano

cap drop desvest media Z
gen media =.
gen desvest=.
gen Z=.

foreach indicador of local indicadores {

		if "`indicador'" == "tasa_bruta_asis" 											local niveles Prescolar Primaria Secundaria Superior
		if "`indicador'" == "tasa_neta_asis" 										 	local niveles Prescolar Primaria Secundaria Superior 
		if "`indicador'" == "tasa_asis_edad" | "`indicador'" == "tasa_no_asis_edad"		local niveles 4-5_años 6-11_años 12-14_años 15-17_años 18-23_años  
		if "`indicador'" == "Años_Escolaridad_25_mas" 									local niveles 0_años 1-5_años 6_años 7-11_años 12_años 13__años_más
		if "`indicador'" == "Ninis_1" | "`indicador'" == "Ninis_2"						local niveles 15-24_años 15-29_años 
		if "`indicador'" == "tasa_terminacion" | "`indicador'" == "tasa_terminacion_c"	local niveles Primaria Secundaria 
		if "`indicador'" == "tasa_sobre_edad"											local niveles Primaria
		if "`indicador'" == "leavers" 													local niveles Total 
	
	foreach nivel of local niveles {
		foreach clase of local clases {
		    *foreach clase2 of local clases2 {
				foreach pais of local paises {
														
					sum valor if indicador == "`indicador'" & clase_id == "`clase'" & nivel_id=="`nivel'" & pais_id == "`pais'"
					cap local medi =`r(mean)' 
					cap local desves =`r(sd)' 
					
					cap replace media = `medi' if indicador== "`indicador'" & clase_id== "`clase'" & nivel_id=="`nivel'" & pais_id == "`pais'"
					cap replace desvest = `desves' if indicador== "`indicador'" & clase_id== "`clase'" & nivel_id=="`nivel'" & pais_id == "`pais'"
												
				} /*cierro paises*/
			*}/*cierro clases2*/
		} /*cierro clases*/
	} /*cierro niveles*/
} /*cierro indicadores*/	

replace Z= (valor-media)/desvest
sort tiempo_id indicador pais_id nivel_id 
order pais_id indicador clase_id nivel_id

tostring tiempo_id, replace	
duplicates drop tiempo_id indicador pais_id nivel_id clase_id tema tipo , force

reshape wide valor Z muestra, i(indicador pais_id nivel_id clase_id tema tipo) j(tiempo_id) s



/*==================================================
              3: Export results
==================================================*/


export excel using "${covidtmp}\validacion_indicadores_encuestas_hogares_scl_converted.xlsx", first(var) sheet(Total_results) sheetreplace
sleep 1000
restore




exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1.
2.
3.


Version Control:


