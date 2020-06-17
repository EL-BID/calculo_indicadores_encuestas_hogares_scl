
/*============================================================================
project:      Formatos base final 
Author:        Angela Lopez 
Dependencies:  SCL/EDU/LMK - IDB 
------------------------------------------------------------------------------
Creation Date:    25 Febrero 2020 - 11:38:53
Modification Date:   
Do-file version:    01
References:          
Output:             
===============================================================================*/

/*=================================================================================
                        Program description: para incluir en el programa maestro  
===================================================================================*/

** tiempo
	   cap gen tiempo = "anual" 

** nivel 
		cap gen      nivel = "grupo_etario" 
		replace  nivel = "nivel_educativo" if indicador == "tasa_bruta_asis" | indicador == "tasa_neta_asis" | indicador == "tasa_terminacion_c"   | indicador == "tasa_sobre_edad" 
		replace  nivel = "anos_educacion"  if indicador == "Años_Escolaridad_25_mas" 
		replace  nivel = "no_aplica"	   if indicador == "leavers"   | indicador == "ginihh" 
		replace  nivel = "no_aplica"	   if tema == "vivienda" | tema == "demografia"
		
** nivel_id 
		replace nivel_id = "0-4_años" 	if nivel_id == "age_00_04"
		replace nivel_id = "5-14_años" 	if nivel_id == "age_05_14"
		replace nivel_id = "12-14_años" if nivel_id == "age_12_14"
		replace nivel_id = "15-17_años" if nivel_id == "age_15_17"
		replace nivel_id = "15-24_años" if nivel_id == "age_15_24" |  nivel_id == "15-24_Años"
		replace nivel_id = "15-29_años" if nivel_id == "age_15_29"
		replace nivel_id = "15-64_años" if nivel_id == "age_15_64"
		replace nivel_id = "18-23_años" if nivel_id == "age_18_23"
		replace nivel_id = "25-64_años" if nivel_id == "age_25_64"
		replace nivel_id = "4-5_años" 	if nivel_id == "age_4_5"
		replace nivel_id = "65_años_más" if nivel_id == "age_65_mas"
		replace nivel_id = "6-11_años" 	if nivel_id == "age_6_11"
		
		replace nivel_id = "0_años" 	if nivel_id == "anos_0"
		replace nivel_id = "12_años" 	if nivel_id == "anos_12"                   
		replace nivel_id = "13_años_más" if nivel_id == "anos_13_o_mas"                   
		replace nivel_id = "1-5_años" 	if nivel_id == "anos_1_5"                   
		replace nivel_id = "6_años" 	if nivel_id == "anos_6"                   
		replace nivel_id = "7-11_años" 	if nivel_id == "anos_7_11"                   
		replace nivel_id = "12_años" 	if nivel_id == "anos_12"   
		
		rename clase clase_id
		rename clase2 clase2_id
		
 ** clase
 
		cap gen clase = clase_id 
		replace clase = "sexo" if clase_id == "Hombre" | clase_id == "Mujer"
		replace clase = "area" if clase_id == "Rural" | clase_id == "Urbano"
		replace clase = "quintil_ingreso" if clase_id == "quintil_1" | clase_id == "quintil_2" | clase_id == "quintil_3" | clase_id == "quintil_4" | clase_id == "quintil_5"
		
		cap gen clase2 = clase2_id 
		replace clase2 = "sexo" if clase2_id == "Hombre" | clase2_id == "Mujer"
		replace clase2 = "area" if clase2_id == "Rural" | clase2_id == "Urbano"
		replace clase2 = "quintil_ingreso" if clase2_id == "quintil_1" | clase2_id == "quintil_2" | clase2_id == "quintil_3" | clase2_id == "quintil_4" | clase2_id == "quintil_5"

		
		
** tipo 		
		cap gen tipo = "porcentaje"
		replace tipo = "tasa" if  indicador == "tasa_bruta_asis" | indicador == "tasa_neta_asis" | indicador == "tasa_terminacion_c"   | indicador == "tasa_sobre_edad" | indicador == "tasa_ocupacion" | indicador == "tasa_desocupacion" | indicador=="tasa_participacion" | indicador == "formalidad_2" | indicador == "tasa_asis_edad"
		replace tipo = "nivel" if indicador == "ingreso_mens_prom" | indicador == "ingreso_hor_prom" | indicador == "ingreso_hor_prom" 
		replace tipo = "indice" if indicador == "ginihh"
		
		
