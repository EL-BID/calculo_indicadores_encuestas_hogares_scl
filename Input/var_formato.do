
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
	   gen tiempo = "anual"

** nivel 
		gen      nivel = "grupo_etario" 
		replace  nivel = "nivel_educativo" if indicador == "tasa_bruta_asis" | indicador == "tasa_neta_asis" | indicador == "tasa_terminacion_c"   | indicador == "tasa_sobre_edad" 
		replace  nivel = "anos_educacion"  if indicador == "Años_Escolaridad_25_mas" 
		replace  nivel = "no_aplica"	   if indicador == "leavers"   | indicador == "ginihh" 
		replace  nivel = "no_aplica"	   if tema == "vivienda" | tema == "demografia"
** tipo 		
		gen tipo = "porcentaje"
		replace tipo = "tasa" if  indicador == "tasa_bruta_asis" | indicador == "tasa_neta_asis" | indicador == "tasa_terminacion_c"   | indicador == "tasa_sobre_edad" | indicador == "tasa_ocupacion" | indicador == "tasa_desocupacion" | indicador=="tasa_participacion" | indicador == "formalidad_2" | indicador == "tasa_asis_edad"
		replace tipo = "nivel" if indicador == "ingreso_mens_prom" | indicador == "ingreso_hor_prom" | indicador == "ingreso_hor_prom" 
		replace tipo = "indice" if indicador == "ginihh"
		
		
