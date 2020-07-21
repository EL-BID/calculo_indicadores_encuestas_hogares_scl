/*====================================================================
project:       Armonizacion actualización plataformas SCL
Author:        Angela Lopez 
Dependencies:  SCL/EDU/LMK - IDB 
----------------------------------------------------------------------
Creation Date:    01 feb 2020 - 11:47:53
Modification Date:   
Do-file version:    01
References:          
Output:             Excel-DTA file
====================================================================*/

/*====================================================================
                        0: Program set up
====================================================================*/
version 15.1
drop _all 
set more off 
*ssc install quantiles
* ssc install inequal7

* Directory Paths
global input  	"\\Sdssrv03\surveys\harmonized"
global output 	"\\Sdssrv03\surveys\Armonizacion-SCL-code\Output"
global temporal	"\\Sdssrv03\surveys\Armonizacion-SCL-code\Input"

/*====================================================================
                        1: Open dataset and Generate indicators
====================================================================*/
tempfile tablas
tempname ptablas

** Este postfile da estructura a la base:


postfile `ptablas' str30(tiempo_id pais_id geografia_id clase clase2 nivel_id tema indicador valor muestra) using `tablas', replace

** Creo locales principales:
 
local temas  educacion pobreza laboral vivienda demografia /*diversidad migracion  	*/									
local paises ARG /*BHS BOL BRB BLZ BOL BRA CHL COL CRI ECU SLV GTM GUY HTI HND JAM MEX NIC PAN PRY PER DOM SUR TTO URY VEN */
local anos 2006 /*2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018*/
local geografia_id total_nacional



qui {
	foreach pais of local paises {
		foreach ano of local anos {
			
			* En este dofile de encuentra el diccionario de encuestas y rondas de la región
			include "${temporal}\Directorio HS LAC.do" 

			foreach encuesta of local encuestas {					
				foreach ronda of local rondas {					
							
					cap use "${input}\\`pais'\\`encuesta'\data_arm\\`pais'_`ano'`ronda'_BID.dta" , clear
					
					if _rc == 0 { //* Si esta base de datos existe, entonces haga: */
										
							* variables de clase
							
								cap gen Total  =  1
								cap gen Hombre = (sexo_ci==1)  
								cap gen Mujer  = (sexo_ci==2)
								cap gen Urbano = (zona_c==1)
								cap gen Rural  = (zona_c==0)
							
								if "`pais'" == "HND" | ("`pais'" == "NIC" & "`ano'" == "2009")  {
								drop quintil 
								}
										
								* Generando Quintiles de acuerdo a SUMMA y toda la división 
												
								cap egen    ytot_ci= rsum(ylm_ci ylnm_ci ynlm_ci ynlnm_ci) if miembros_ci==1
								replace ytot_ci= .   if ylm_ci==. & ylnm_ci==. & ynlm_ci==. & ynlnm_ci==.
								cap bys		idh_ch: egen ytot_ch= sum(ytot_ci) if miembros_ci==1
								replace ytot_ch=. if ytot_ch<=0
								cap gen 	pc_ytot_ch=ytot_ch/nmiembros_ch	
								sort 	pc_ytot_ch idh_ch idp_ci
								cap gen 	suma1=sum(factor_ci) if ytot_ch>0 & ytot_ch!=.
								cap qui su  suma1
								local 	ppquintil2 = r(max)/5 

								cap gen quintil_1=1 if suma1>=0 & suma1<=1*`ppquintil2'
								cap gen quintil_2=1 if suma1>1*`ppquintil2' & suma1<=2*`ppquintil2'
								cap gen quintil_3=1 if suma1>2*`ppquintil2' & suma1<=3*`ppquintil2'
								cap gen quintil_4=1 if suma1>3*`ppquintil2' & suma1<=4*`ppquintil2'
								cap gen quintil_5=1 if suma1>4*`ppquintil2' & suma1<=5*`ppquintil2'						
					
							* Variables intermedias 
					
								* Educación: niveles y edades teóricas cutomizadas  
									include "${temporal}\var_tmp_EDU.do"
								* Mercado laboral 
									include "${temporal}\var_tmp_LMK.do"
								* Pobreza, vivienda, demograficas
									include "${temporal}\var_tmp_SOC.do"

								* Inclusion
									include "${temporal}\var_tmp_GDI.do"

							
							
*****************************************************************************************************************************************
					* 1.2: Indicators for each topic		
*****************************************************************************************************************************************
						foreach tema of local temas {
											
							if "`tema'" == "demografia" local indicadores jefa_ch 
							if "`tema'" == "pobreza"    local indicadores pobreza31 pobreza vulnerable middle ginihh
							if "`tema'" == "educacion"  local indicadores tasa_neta_asis tasa_asis_edad Años_Escolaridad_25_mas Ninis_2 leavers tasa_terminacion_c tasa_sobre_edad
							if "`tema'" == "vivienda"   local indicadores aguared_ch des2_ch luz_ch dirtf 
							if "`tema'" == "laboral"    local indicadores tasa_ocupacion tasa_desocupacion tasa_participacion ocup_suf_salario ingreso_mens_prom ingreso_hor_prom formalidad_2 pensionista_65_mas ingreso_pension_65_mas 
							if "`tema'" == "diversidad" local indicadores pdis_ci
	
							foreach indicador of local indicadores {
							noi di in y "Calculating numbers for country: `pais' - year : `ano' - tema: `tema' - indicator: `indicador'"
								
														
		if "`tema'"	== "demografia" {
							
							/* Porcentaje de hogares con jefatura femenina */
							if "`indicador'" == "jefa_ch" {
	
											capture sum Total [w=factor_ci]	 if jefe_ci ==1 & sexo_ci!=.
											if _rc == 0 {
											local num_hog = `r(sum)'
											
											sum Total [w=factor_ci]	 if jefe_ci==1 & sexo_ci ==2 
											local numerador = `r(sum)'
											local valor = (`numerador' / `num_hog') * 100 
											
											sum Total  if jefe_ci==1 & sexo_ci ==2 
											local muestra = `r(sum)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("no_aplica") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

											}
							} /* cierro indicador*/
		} /*cierro demografia */		
									
		if "`tema'" == "educacion" 	{
			
			local clases  Total Hombre Mujer quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
			local clases2 Total Hombre Mujer Rural Urbano
			
			foreach clase of local clases {	
				foreach clase2 of local clases2{
					
							* Tasa Bruta de Asistencia
							if "`indicador'" == "tasa_bruta_asis" {
																						 
							* Prescolar   
											capture sum age_pres [w=factor_ci]	 if `clase'==1 & asiste_ci!=. & `clase2' ==1
											if _rc == 0 {
											local pop_pres = `r(sum)'
											
											sum asis_pres [w=factor_ci]	 if `clase'==1 & asiste_ci!=. & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_pres') * 100 
											
											sum asis_pres 	 if `clase'==1 & asiste_ci!=. & `clase2' ==1
											local muestra = `r(sum)'
											
  										post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Prescolar") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

											}
							
							* Primaria   
											capture sum age_prim [w=factor_ci]	 if `clase'==1 & asiste_ci!=. & `clase2' ==1
											if _rc == 0 {
											local pop_prim = `r(sum)'
											
											sum asis_prim [w=factor_ci]	 if `clase'==1 & edad_ci>=6 & asiste_ci!=. & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_prim') * 100 
											
											sum asis_prim  if `clase'==1 & edad_ci>=6 & asiste_ci!=. & `clase2' ==1
											local muestra = `r(sum)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

											}
							
							* Secundaria 
											capture sum age_seco [w=factor_ci]	if `clase'==1 & asiste_ci!=. & `clase2' ==1
											if _rc == 0 {
											local pop_seco = `r(sum)'	
							
											sum asis_seco [w=factor_ci]	 if `clase'==1 & edad_ci>=6 & asiste_ci!=. & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador'/ `pop_seco') * 100 
											
											sum asis_seco  if `clase'==1 & edad_ci>=6 & asiste_ci!=. & `clase2' ==1
											local muestra = `r(sum)'
											

											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Secundaria") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

											}								
											
							*Terciaria
											capture sum age_tert [w=factor_ci]	if `clase'==1 & asiste_ci!=. & `clase2' ==1
											if _rc == 0 {
											local pop_tert = `r(sum)'	
											
											sum asis_tert [w=factor_ci]	 if `clase'==1 & edad_ci>=6 & asiste_ci!=. & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador'/ `pop_tert') * 100 
											
											sum asis_tert  if `clase'==1 & edad_ci>=6 & asiste_ci!=. & `clase2' ==1
											local muestra = `r(sum)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Superior") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

											
											} /*cierro if*/
											
							} /*cierro if de indicador*/
										
							* Tasa de Asistencia Neta
							if "`indicador'" == "tasa_neta_asis" {	

							* Prescolar   
											capture sum age_pres [w=factor_ci]	 if `clase'==1 & asiste_ci!=. & `clase2' ==1
											if _rc == 0 {
											local pop_pres = `r(sum)'
											
											sum asis_pres [w=factor_ci]	 if `clase'==1 & age_pres==1 & asiste_ci!=. & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_pres') * 100 
											
											sum asis_pres  if `clase'==1 & age_pres==1 & asiste_ci!=. & `clase2' ==1
											local muestra = `r(sum)'
											

											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Prescolar") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

											}

							* Primaria   
											capture sum age_prim [w=factor_ci]	 if `clase'==1 & asiste_ci!=. & `clase2' ==1 
											if _rc == 0 {
											local pop_prim = `r(sum)'
											
											sum asis_prim [w=factor_ci]	 if `clase'==1 & age_prim==1 & asiste_ci!=. & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_prim') * 100 
											
											sum asis_prim  if `clase'==1 & age_prim==1 & asiste_ci!=. & `clase2' ==1
											local muestra = `r(sum)'
											

											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

											}
							
							* Secundaria 
											capture sum age_seco [w=factor_ci]	if `clase'==1 & asiste_ci!=. & `clase2' ==1
											if _rc == 0 {
											local pop_seco = `r(sum)'	
											
											sum asis_seco [w=factor_ci]	 if `clase'==1 & age_seco == 1 & asiste_ci!=. & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_seco') * 100 
											
											sum asis_seco  if `clase'==1 & age_seco == 1 & asiste_ci!=. & `clase2' ==1
											local muestra = `r(sum)'

											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Secundaria") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

											}
														
							*Superior
											capture sum age_tert [w=factor_ci]	if `clase'==1 & asiste_ci!=. & `clase2' ==1
											if _rc == 0 {
											local pop_tert = `r(sum)'	
											
											sum asis_tert [w=factor_ci]	 if `clase'==1 & age_tert == 1 & asiste_ci!=. & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_tert') * 100 
											
											sum asis_tert  if `clase'==1 & age_tert == 1 & asiste_ci!=. & `clase2' ==1
											local muestra = `r(sum)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Superior") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

											} /*cierro if*/
							} /* cierro if indicador*/
																								
							* Tasa Asistencia grupo etario							
							if "`indicador'" == "tasa_asis_edad" {	
								
								local niveles age_4_5 age_6_11 age_12_14 age_15_17 age_18_23
								
									foreach nivel of local niveles {								

											capture sum `nivel'  [w=factor_ci]	if `clase'==1 & asiste_ci!=. & `clase2' ==1
											if _rc == 0 {
											local denominador = `r(sum)'	
																						
											sum `nivel'  [w=factor_ci]	 if `clase'==1 & asiste_ci==1 & asiste_ci!=. & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `denominador') * 100 
											
											sum `nivel'  if `clase'==1 & asiste_ci==1 & asiste_ci!=. & `clase2' ==1
											local muestra = `r(sum)'
											

											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

											}
											
									} /*cierro niveles*/
							} /* cierro if indicador*/

							* Tasa No Asistencia grupo etario
							if "`indicador'" == "tasa_no_asis_edad" {	
								
								local niveles age_4_5 age_6_11 age_12_14 age_15_17 age_18_23
								
									foreach nivel of local niveles {
						 
											capture sum `nivel' [w=factor_ci] if `clase'==1 & asiste_ci!=. & `clase2' ==1
											if _rc == 0 {
											local denominador = `r(sum)'
											
											sum `nivel' [w=factor_ci]	 if `clase'==1 & asiste_ci==0  & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `denominador') * 100 
											
											sum `nivel' if `clase'==1 & asiste_ci==0  & `clase2' ==1
											local muestra = `r(sum)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

											}


								} /*cierro niveles*/
							} /* cierro if indicador*/
									
							* Años_Escolaridad y Años_Escuela
							if "`indicador'" == "Años_Escolaridad_25_mas" {	
									
								local niveles anos_0 anos_1_5 anos_6 anos_7_11 anos_12 anos_13_o_mas
								
									foreach nivel of local niveles {
										
											sum age_25_mas [w=factor_ci] if `clase'==1 & (aedu_ci !=. | edad_ci !=.) & `clase2' ==1
											if _rc == 0 {
											local pop_25_mas = `r(sum)'
											
											sum `nivel' [w=factor_ci]	if `clase'==1 & age_25_mas==1 & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_25_mas') * 100 
											
											sum `nivel' if `clase'==1 & age_25_mas==1 & `clase2' == 1
											local muestra = `r(sum)'
											

											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

											}
											
									} /* cierro nivel */		
							} /* cierro if indicador*/		
										
							* Ninis Inactivos no asisten
							if "`indicador'" == "Ninis_2" {									
								
								local niveles age_15_24 age_15_29
									
									foreach nivel of local niveles {
											
											sum `nivel' [w=factor_ci]	 if `clase'==1 & edad_ci !=. & `clase2' ==1
											if _rc == 0 {
											local pop_15_24 = `r(sum)'
											
											sum `nivel' [w=factor_ci]	 if `clase'==1 & asiste_ci==0 & condocup_ci == 3 & edad_ci !=. & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_15_24') * 100 
											
											sum `nivel'  if `clase'==1 & asiste_ci==0 & condocup_ci == 3 & edad_ci !=. & `clase2' ==1
											local muestra = `r(sum)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("15-24_Años") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

											}
									} /* cierro nivel*/			
							} /* cierro if indicador*/		

							* Tasa de terminación
							if "`indicador'" == "tasa_terminacion_c" {	
										
							*Primaria

											capture sum age_term_p_c [w=factor_ci]	 if `clase'==1 & tprimaria !=. & `clase2' ==1
											if _rc == 0 {
											local pop_12_14 = `r(sum)'
																		
											sum tprimaria [w=factor_ci]	 if `clase'==1 & age_term_p_c & tprimaria  !=. & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_12_14') * 100 
											
											sum tprimaria if `clase'==1 & age_term_p_c & tprimaria  !=. & `clase2' ==1
											local muestra = `r(sum)'

											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

											}
							
							*Secundaria		
							
											capture sum age_term_s_c [w=factor_ci]	 if `clase'==1  & `clase2' ==1
											if _rc == 0 {
											local pop_18_20 = `r(sum)'
											
											sum tsecundaria [w=factor_ci]	 if `clase'==1 & age_term_s_c ==1 & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_18_20') * 100 
											
											sum tsecundaria if `clase'==1 & age_term_s_c ==1 & `clase2' ==1
											local muestra = `r(sum)'
											

											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Secundaria") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

											}							
							} /*cierro indicador 
																
							* Tasa de abandono escolar temprano "Leavers"  */
							if "`indicador'" == "leavers" {
																						
								cap sum age_18_24 [w=factor_ci]	 if `clase'==1  & `clase2' ==1
								if _rc == 0 {
								local pop_18_24 = `r(sum)' 
											
								sum leavers [w=factor_ci] if `clase'==1 & edad_ci>=18 & edad_ci<=24 & `clase2' ==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_18_24') * 100
								
								sum leavers if `clase'==1 & edad_ci>=18 & edad_ci<=24 & `clase2' ==1
								local muestra = `r(sum)'
											

								post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Total") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

											}					
							} /*cierro indicador 
									
							* Tasa de abandono sobreedad"  */
							if "`indicador'" == "tasa_sobre_edad" {								
				*Primaria

								capture sum asis_prim_c [w=factor_ci]	 if `clase'==1 & asiste_ci!=. & `clase2' ==1
								if _rc == 0 {
								local pop_prim = `r(sum)'
															
								sum asis_prim_c [w=factor_ci]	 if `clase'==1 & age_prim_sobre==1 & asiste_ci!=. & `clase2' ==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_prim') * 100 
								
								sum asis_prim_c  if `clase'==1 & age_prim_sobre==1 & asiste_ci!=. & `clase2' ==1
								local muestra = `r(sum)'
								

								post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

								}				
							} /* cierro if indicador*/ 
				} /* cierro clase2 */
			}	/* cierro clase */			
	
		} /*cierro educacion*/
	
		if "`tema'" == "laboral" 	{
			
			local clases  Total Hombre Mujer quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
			local clases2 Total Hombre Mujer Rural Urbano
			local niveles Total age_15_24 age_15_29 age_15_64 age_25_64 age_65_mas 
				
				foreach clase of local clases {
					foreach clase2 of local clases2 {
						foreach nivel of local niveles {
					
							if "`indicador'" == "tasa_ocupacion" {																						 
				  
								capture sum `nivel' [w=factor_ci] if `clase'==1 & pet==1 & `clase2' ==1
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum `nivel' [w=factor_ci]	 if `clase'==1 & condocup_ci==1  & `clase2' ==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') * 100 
								
								sum `nivel'  if `clase'==1 & condocup_ci==1  & `clase2' ==1
								local muestra = `r(sum)'
								

								post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

								}				
							} /*cierro indicador*/
							
							if "`indicador'" == "tasa_desocupacion" {	
							
								capture sum `nivel' [w=factor_ci] if `clase'==1 & pea==1 & `clase2' ==1
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum `nivel' [w=factor_ci]	 if `clase'==1 & condocup_ci==2 & `clase2' ==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') * 100 
								
								sum `nivel' if `clase'==1 & condocup_ci==2 & `clase2' ==1
								local muestra = `r(sum)'
								

								post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

								}				
								
							} /*cierro indicador*/
							
							if "`indicador'" == "tasa_participacion" {	
							
								capture sum `nivel' [w=factor_ci] if `clase'==1 & pet==1 & `clase2' ==1
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum `nivel' [w=factor_ci]	 if `clase'==1 & pea==1 & `clase2' ==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') * 100 
								
								sum `nivel' if `clase'==1 & pea==1 & `clase2' ==1
								local muestra = `r(sum)'
								

								post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

								}
							} /*cierro indicador*/
								
							if "`indicador'" == "ocup_suf_salario" {	
							
								capture sum `nivel' [w=factor_ci] if `clase'==1 & liv_wage !=. & `clase2' ==1
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum `nivel' [w=factor_ci]	 if `clase'==1 & liv_wage ==1 & `clase2' ==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') * 100 
								
								sum `nivel' if `clase'==1 & liv_wage ==1 & `clase2' ==1
								local muestra = `r(sum)'
								

								post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

								}
							} /*cierro indicador*/
							
							if "`indicador'" == "ingreso_mens_prom" {	
							
								capture sum `nivel' [w=factor_ci] if `clase'==1 & ylab_ppp!=. & `clase2' ==1
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum ylab_ppp [w=factor_ci]	 if `clase'==1 & `nivel'==1 & `clase2' ==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') 												
								
								sum ylab_ppp [w=factor_ci]	 if `clase'==1 & `nivel'==1 & `clase2' ==1
								local muestra = `r(sum)'
								
								post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

								}
							} /*cierro indicador*/
							
							if "`indicador'" == "ingreso_hor_prom" {	
							
								capture sum `nivel' [w=factor_ci] if `clase'==1 & hwage_ppp!=. & `clase2' ==1
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum hwage_ppp [w=factor_ci]	 if `clase'==1 & `nivel'==1 & `clase2' ==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') 												
								
								sum hwage_ppp if `clase'==1 & `nivel'==1 & `clase2' ==1
								local muestra = `r(sum)'
								

								post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

								}
							} /*cierro indicador*/
							
							if "`indicador'" == "formalidad_2" {	
							
								capture sum `nivel' [w=factor_ci] if `clase'==1 & condocup_ci==1 & `clase2' ==1
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum `nivel' [w=factor_ci]	 if `clase'==1 & formal_ci==1 & condocup_ci==1 & `clase2' ==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') * 100												
								
								sum `nivel' if `clase'==1 & formal_ci==1 & condocup_ci==1 & `clase2' ==1
								local muestra = `r(sum)'
								

								post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

								}
							} /*cierro indicador*/
						} /*cierro niveles*/
						
					
							if "`indicador'" == "pensionista_65_mas" {	
							
								capture sum age_65_mas [w=factor_ci] if `clase'==1 & `clase2' ==1
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum age_65_mas [w=factor_ci]	 if `clase'==1 & pensiont_ci==1 & `clase2' ==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') * 100												
								
								sum age_65_mas if `clase'==1 & pensiont_ci==1 & `clase2' ==1
								local muestra = `r(sum)'

								post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("age_65_mas") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

								}
							} /*cierro indicador*/	
							
							if "`indicador'" == "ingreso_pension_65_mas" {	
							
								capture sum age_65_mas [w=factor_ci] if `clase'==1 & ypen_ppp!=. & `clase2' ==1
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum ypen_ppp [w=factor_ci]	 if `clase'==1 & age_65_mas==1 & `clase2' ==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') 											
								
								sum ypen_ppp if `clase'==1 & age_65_mas==1 & `clase2' ==1
								local muestra = `r(sum)'
								

								post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("age_65_mas") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

								}
							} /*cierro indicador*/	
					}/*cierro clase2*/
				} /* cierro clase*/ 
		} /*cierro laboral*/
		
		if "`tema'" == "pobreza" 	{
		
			local niveles Total age_00_04 age_05_14 age_15_24 age_25_64 age_65_mas
			local clases  Total Hombre Mujer Rural Urbano
			local clases2 Hombre Mujer 
				
				foreach clase of local clases{
				foreach clase2 of local clases2 {
					foreach nivel of local niveles {
									
							if "`indicador'" == "pobreza31" {																						 
				  
								capture sum `nivel' [w=factor_ci] if `clase'==1 & `clase2' ==1
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum `nivel' [w=factor_ci]	 if `clase'==1 & poor31==1 & `clase2' ==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') * 100 
								

								post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

								}				
							} /*cierro indicador*/		
							
							if "`indicador'" == "pobreza" {																						 
				  
								capture sum `nivel' [w=factor_ci] if `clase'==1  & `clase2' ==1
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum `nivel' [w=factor_ci]	 if `clase'==1 & poor==1 & `clase2' ==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') * 100 
								

								post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

								}				
							} /*cierro indicador*/
							
							if "`indicador'" == "vulnerable" {																						 
				  
								capture sum `nivel' [w=factor_ci] if `clase'==1 & `clase2' ==1
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum `nivel' [w=factor_ci]	 if `clase'==1 & vulnerable==1 & `clase2' ==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') * 100 
								

								post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

								}				
							} /*cierro indicador*/	
							
							if "`indicador'" == "middle" {																						 
				  
								capture sum `nivel' [w=factor_ci] if `clase'==1 & `clase2' ==1
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum `nivel' [w=factor_ci]	 if `clase'==1 & middle==1 & `clase2' ==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') * 100 
								

								post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

								}				
							} /*cierro indicador*/		

					} /*cierro nivel*/	
				}/*cierro clases2*/
			} /*cierro clase*/
			
			local clases Total Urbano Rural
			
				foreach clase of local clases {
							
							if "`indicador'" == "ginihh" {
							
								cap inequal7 pc_ytot_ch [w=factor_ci] if `clase'==1 & pc_ytot_ch !=. 
								if _rc == 0 {
								local valor =`r(gini)'
								
								cap inequal7 pc_ytot_ch [w=factor_ci] if `clase'==1 & pc_ytot_ch !=. 
								local muestra = `r(gini)'
								

								post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

								}
							} /*cierro indicador*/
							
			} /*cierro clase*/
			
		} /*cierro pobreza*/
		
		if "`tema'" == "vivienda" 	{
		
			local clases Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
			local clases2 Total Rural Urbano
		
				foreach clase of local clases{
					foreach clase2 of local clases2 {
			
							if "`indicador'" == "aguared_ch" {
	
											capture sum Total [w=factor_ci]	if jefe_ci ==1 & `clase'==1 & aguared_ch!=. & `clase2' ==1
											if _rc == 0 {
											local num_hog = `r(sum)'
											
											sum Total [w=factor_ci]	 if jefe_ci==1 & `clase'==1 & aguared_ch==1 & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `num_hog') * 100 
											
											sum Total if jefe_ci==1 & `clase'==1 & aguared_ch==1 & `clase2' ==1
											local muestra = `r(sum)'
											

											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

											}
							} /* cierro indicador*/	
							
							if "`indicador'" == "des2_ch" {
	
											capture sum Total [w=factor_ci]	if jefe_ci ==1 & `clase'==1  & des2_ch!=. & `clase2' ==1
											if _rc == 0 {
											local num_hog = `r(sum)'
											
											sum Total [w=factor_ci]	 if jefe_ci==1 & des2_ch==1 & `clase'==1 & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `num_hog') * 100 
											
											sum Total if jefe_ci==1 & des2_ch==1 & `clase'==1 & `clase2' ==1
											local muestra = `r(sum)'
											

											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

											}
							} /* cierro indicador*/	
							
							if "`indicador'" == "luz_ch" {
	
											capture sum Total [w=factor_ci]	if jefe_ci ==1 & `clase'==1 & luz_ch!=. & `clase2' ==1
											if _rc == 0 {
											local num_hog = `r(sum)'
											
											sum Total [w=factor_ci]	 if jefe_ci==1 & `clase'==1 & luz_ch==1 & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `num_hog') * 100 
											
											sum Total if jefe_ci==1 & `clase'==1 & luz_ch==1 & `clase2' ==1
											local muestra = `r(sum)'
											

											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

											}
							} /* cierro indicador*/	
							
							if "`indicador'" == "dirtf" {
	
											capture sum Total [w=factor_ci]	if jefe_ci ==1 & `clase'==1 & dirtf!=. & `clase2' ==1
											if _rc == 0 {
											local num_hog = `r(sum)'
											
											sum Total [w=factor_ci]	 if jefe_ci==1 & `clase'==1 & dirtf==1 & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `num_hog') * 100 
											
											sum Total if jefe_ci==1 & `clase'==1 & dirtf==1 & `clase2' ==1
											local muestra = `r(sum)'

											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

											}
											
							} /* cierro indicador*/
					}/*cierro clase2*/		
				} /*cierro clase*/
		} /*cierro vivienda*/
								
														
		if "`tema'"	== "inclusion" {
							
							/* [inserte nombre extrendidpo del indicador] */
							if "`indicador'" == "[inserte nombre corto indicador]" {
	
											capture sum Total [w=factor_ci]	 if `clase'==1 & `clase2' ==1
											local denominador = `r(sum)'
											
											sum Total [w=factor_ci]	 if raza==1 & `clase'==1 & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `denominador') * 100 
											
											sum Total if raza==1 & `clase'==1 & `clase2' ==1
											local muestra = `r(sum)'
											

											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

											
							} /* cierro indicador*/
		} /*cierro demografia */
		
																
		if "`tema'"	== "migracion" {
							
							/* [inserte nombre del indicador extendido] 
							
							if "`indicador'" == "[inserte nombre indicador corto]" {

							} /* cierro indicador*/
							
							*/ 
		} /*cierro migracion */
		
								}  /*cierro indicadores*/
						}/*Cierro temas*/
						
					}/*Cierro if _rc*/ 
										
					if _rc != 0  { /* Si esta base de datos no existe, entonces haga: */

						foreach tema of local temas {
											
							if "`tema'" == "demografia" local indicadores jefa_ch
							if "`tema'" == "pobreza"    local indicadores pobreza31 pobreza vulnerable middle ginihh
							if "`tema'" == "educacion"  local indicadores tasa_neta_asis tasa_asis_edad Años_Escolaridad_25_mas Ninis_2 leavers tasa_terminacion_c tasa_sobre_edad
							if "`tema'" == "vivienda"   local indicadores aguared_ch des2_ch luz_ch dirtf
							if "`tema'" == "laboral"    local indicadores tasa_ocupacion tasa_desocupacion tasa_participacion ocup_suf_salario ingreso_mens_prom ingreso_hor_prom formalidad_2 pensionista_65_mas ingreso_pension_65_mas 
							if "`tema'" == "inclusion"  local indicadores 
							if "`tema'" == "migracion"  local indicadores 
							
							foreach indicador of local indicadores {
									noi di in y "Calculating numbers for country: `pais' - year : `ano' - tema: `tema' - indicator: `indicador'"
									
									if "`tema'"	== "demografia"  {

										post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("no_aplica") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") (".") (".")

									} /*cierro demografia*/
										
									if "`tema'" == "educacion" {
										
										local clases  Total Hombre Mujer quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
										local clases2 Hombre Mujer Rural Urbano
										
										foreach clase of local clases {
											foreach clase2 of local clases2 {
											
												if "`indicador'" == "tasa_neta_asis_c" | "`indicador'" == "tasa_bruta_asis_c"	local niveles Primaria Secundaria Superior
												if "`indicador'" == "tasa_neta_asis" | "`indicador'" == "tasa_bruta_asis"	 	local niveles Prescolar Primaria Secundaria Superior 
												if "`indicador'" == "tasa_asis_edad" | "`indicador'" == "tasa_no_asis_edad"		local niveles age_4_5 age_6_11 age_12_14 age_15_17 age_18_23  
												if "`indicador'" == "Años_Escolaridad_25_mas" 									local niveles anos_0 anos_1_5 anos_6 anos_7_11 anos_12 anos_13_o_mas 
												if "`indicador'" == "Ninis_1" | "`indicador'" == "Ninis_2"						local niveles age_15_24 age_15_29 
												if "`indicador'" == "tasa_terminacion" | "`indicador'" == "tasa_terminacion_c"	local niveles Primaria Secundaria 
												if "`indicador'" == "tasa_sobre_edad"											local niveles Primaria
												if "`indicador'" == "leavers" 													local niveles Total 
									  
												foreach nivel of local niveles {

													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") (".") (".")

												} /* cierro niveles*/
											} /*cierro clases2*/
										} /*cierro clases*/
									} /*cierro educacion*/
									
									if "`tema'" == "laboral" {
									

										 local niveles Total age_15_24 age_15_29 age_15_64 age_25_64 age_65_mas 
										 local clases Total Hombre Mujer quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
										 local clases2 Total Hombre Mujer Rural Urbano
										 

										foreach clase of local clases {
											foreach clase2 of local clases2 {
												
												if "`indicador'" == "pensionista_65_mas" | "`indicador'" == "ingreso_pension_65_mas"	local niveles age_65_mas
									  
												foreach nivel of local niveles {

													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") (".") (".")

												} /* cierro niveles*/
											} /*cierro clases2*/
										} /*cierro clases*/
									} /*cierro laboral*/
									
									if "`tema'" == "pobreza" {	
										
										local niveles Total age_00_04 age_05_14 age_15_24 age_25_64 age_65_mas

										local clases  Total Hombre Mujer Rural Urbano
										local clases2 Total Hombre Mujer

										
										if "`indicador'" == "ginihh" local niveles no_aplica
										if "`indicador'" == "ginihh" local clases Total Rural Urbano
										
										foreach clase of local clases {	
											foreach clase2 of local clases2 {	
												foreach nivel of local niveles {

													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") (".") (".")

												} /* cierro niveles*/
											} /*cierro clases2*/
										} /*cierro clases*/
									} /*cierro pobreza*/
									
									if "`tema'" == "vivienda" 	{
		
										local clases Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
										local clases2 Rural Urbano
										
										foreach clase of local clases {									  
											foreach clase2 of local clases2 {	

													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") (".") (".")

													
											} /*cierro clases2*/
										} /*cierro clases*/
									} /*cierro vivienda*/
																		
									if "`tema'" == "inclusion" {

									
										local clases Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
										local clases2 Total
									
										foreach clase of local clases {									  
											foreach clase2 of local clases2 {	
												
												post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") (".") (".")
											
									

											} /*cierro clases2*/
										} /*cierro clases*/
									} /*cierro inclusion*/
																			
							} /*cierro indicadores*/
						} /* cierro temas */
					
					}/*cierro if _rc*/
				
				
				
						
					} /* cierro rondas */		
				} /* cierro encuestas */
			} /* cierro anos */
		} /* cierro paises */
	} /* cierro quietly */
 

postclose `ptablas'
use `tablas', clear
destring valor muestra, replace
recode valor 0=.
recode muestra 0=.
save `tablas', replace 

* guardo el archivo temporal
save "\\hqpnas01\EDULAC\EDW\2. Indicators\Databases\Stata\Indicadores_SCL.dta", replace

* Variables de formato 

include "${temporal}\var_formato.do"

order tiempo tiempo_id pais_id geografia_id clase clase_id clase2 clase2_id nivel nivel_id tema indicador tipo valor muestra



/*====================================================================
                        5: Save and Export results
====================================================================*/


*export excel using "${output}\Indicadores_SCL.xlsx", first(var) sheet(Total_results) sheetreplace
export delimited using  "${output}\indicadores_encuestas_hogares_scl.csv", replace


	g 		division = "soc" if tema == "demografia" | tema == "vivienda" | tema == "pobreza" 
	replace division = "lmk" if tema == "laboral" 													 
	replace division = "edu" if tema == "educacion" 
	replace division = "gdi" if tema == "inclusion"
	replace division = "mig" if tema == "migracion"


local divisiones SOC LMK EDU GDI MIG											 

foreach div of local divisiones { 
	        
			preserve
			
			keep if (division == "`div'")
			drop division
		
			export delimited using "${output}\\indicadores_encuestas_hogares_`div'.csv", replace
			sleep 1000
			restore
						
 }
		
exit
/* End of do-file */



