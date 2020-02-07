/*====================================================================
project:       Armonizacion actualización plataformas SCL
Author:        Angela Lopez 
Dependencies:  SCL/EDU - IDB 
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

* Directory Paths
global input  "\\Sdssrv03\surveys\harmonized"
global output "\\hqpnas01\EDULAC\EDW\2. Indicators\Tablas\FINALES\FINAL Cobertura"

/*====================================================================
                        1: Open dataset and Generate indicators
====================================================================*/
tempfile tablas
tempname ptablas


postfile `ptablas' str30(tiempo_id country_id geography_id clase nivel_id tema indicador valor) using `tablas', replace


** Creo locales base 

* Los indicadores se dividen por temas: 

local temas demografia educacion /*pobreza vivienda laboral*/  




* Cada indicador tiene niveles de desagregación particulares:
									
							
local paises ARG BHS BRB BLZ BOL BRA /*CHL COL CRI ECU SLV GTM GUY HTI HND JAM MEX NIC PAN PRY PER DOM SUR TTO URY VEN */
local anos /*2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016*/ 2017 2018
local clases Total Hombre Mujer quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
local geography_id total_nacional

qui {
		foreach pais of local paises {
			foreach ano of local anos {
				
			* En este dofile de encuentra el diccionario de encuestas y rondas de la región
			include "\\hqpnas01\EDULAC\EDW\2. Indicators\Do.files\Directorio HS LAC.do" 
			include "\\hqpnas01\EDULAC\EDW\2. Indicators\Do.files\Cobertura y Eficiencia\Complementos CIMA\CIRCAS promedio ALC.do"
				foreach encuesta of local encuestas {
					
					foreach ronda of local rondas {
					capture use "${input}\\`pais'\\`encuesta'\data_arm\\`pais'_`ano'`ronda'_BID.dta" , clear
						if _rc == 0 { //* Si esta base de datos existe, entonces haga: */
						
					* variables de clase
							gen Total  =  1
							gen Hombre = (sexo_ci==1)  
							gen Mujer  = (sexo_ci==2)
							gen Urbano = (zona_c==1)
							gen Rural  = (zona_c==0)
						
							if "`pais'" == "HND" | ("`pais'" == "NIC" & "`ano'" == "2009")  {
							drop quintil 
							}
									
							* Generando Quintiles de acuerdo a SUMMA y toda la división 
						
							egen    ytot_ci= rsum(ylm_ci ylnm_ci ynlm_ci ynlnm_ci) if miembros_ci==1
							replace ytot_ci= .   if ylm_ci==. & ylnm_ci==. & ynlm_ci==. & ynlnm_ci==.
							bys idh_ch: egen ytot_ch= sum(ytot_ci) if miembros_ci==1
							replace ytot_ch=. if ytot_ch<=0
							gen pc_ytot_ch=ytot_ch/nmiembros_ch	
							sort pc_ytot_ch idh_ch idp_ci
							gen suma1=sum(factor_ci) if ytot_ch>0 & ytot_ch!=.
							qui su suma1
							local ppquintil2 = r(max)/5 

							gen quintil_1=1 if suma1>=0 & suma1<=1*`ppquintil2'
							gen quintil_2=1 if suma1>1*`ppquintil2' & suma1<=2*`ppquintil2'
							gen quintil_3=1 if suma1>2*`ppquintil2' & suma1<=3*`ppquintil2'
							gen quintil_4=1 if suma1>3*`ppquintil2' & suma1<=4*`ppquintil2'
							gen quintil_5=1 if suma1>4*`ppquintil2' & suma1<=5*`ppquintil2'
						
						
						
					* incluyo edades teóricas  CIMA y customizadas 
					include "\\hqpnas01\EDULAC\EDW\2. Indicators\Do.files\Cobertura y Eficiencia\Complementos CIMA\Edades teoricas CIMA.do"
				
						
							
*****************************************************************************************************************************************
					* 1.2: Calculo de indicadores por tema		
*****************************************************************************************************************************************
						foreach tema of local temas {
											
							if "`tema'" == "demografia" local indicadores hog_jef_mujer
							if "`tema'" == "pobreza"    local indicadores 
							if "`tema'" == "educacion"  local indicadores /*tasa_bruta_asis tasa_neta_asis tasa_asis_edad Años_Escolaridad_25_mas tasa_no_asis_edad  Ninis_2 leavers tasa_terminacion_c */ tasa_sobre_edad
							if "`tema'" == "vivienda"   local indicadores  
							if "`tema'" == "laboral"    local indicadores 
	
							foreach indicador of local indicadores {
								
								
								
		if "`tema'"	== "demografia"  {
							
							/* Porcentaje de hogares con jefatura femenina */
							if "`indicador'" == "hog_jef_mujer" {
	
											capture sum jefe_ci [w=factor_ci]	 
											if _rc == 0 {
											local num_hog = `r(sum)'
											
											sum jefe_ci [w=factor_ci]	 if Mujer==1 
											local numerador = `r(sum)'
											local valor = (`numerador' / `num_hog') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'")
											}
							} /* cierro indicador*/
		} /*cierro demografia */		
								
									
							
	
		if "`tema'" == "educacion" {
			foreach clase of local clases {	
		/*============ Indicadores de cobertura ==========================================================================================*/	
					
							/*Tasa Bruta de Asistencia*/
							if "`indicador'" == "tasa_bruta_asis" {
																						 
							* Prescolar   
											capture sum age_pres [w=factor_ci]	 if `clase'==1 & asiste_ci!=.
											if _rc == 0 {
											local pop_pres = `r(sum)'
											
											sum asis_pres [w=factor_ci]	 if `clase'==1 & asiste_ci!=.
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_pres') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("Prescolar") ("`tema'") ("`indicador'") ("`valor'")
											}
							
							* Primaria   
											capture sum age_prim [w=factor_ci]	 if `clase'==1 & asiste_ci!=.
											if _rc == 0 {
											local pop_prim = `r(sum)'
											
											sum asis_prim [w=factor_ci]	 if `clase'==1 & edad_ci>=6 & asiste_ci!=.
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_prim') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("Primaria") ("`tema'") ("`indicador'") ("`valor'")
											}
							
							* Secundaria 
											capture sum age_seco [w=factor_ci]	if `clase'==1 & asiste_ci!=.
											if _rc == 0 {
											local pop_seco = `r(sum)'	
							
											sum asis_seco [w=factor_ci]	 if `clase'==1 & edad_ci>=6 & asiste_ci!=.
											local numerador = `r(sum)'
											local valor = (`numerador'/ `pop_seco') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("Secundaria") ("`tema'") ("`indicador'") ("`valor'") 
											}								
											
							*Terciaria
											capture sum age_tert [w=factor_ci]	if `clase'==1 & asiste_ci!=.
											if _rc == 0 {
											local pop_tert = `r(sum)'	
											
											sum asis_tert [w=factor_ci]	 if `clase'==1 & edad_ci>=6 & asiste_ci!=.
											local numerador = `r(sum)'
											local valor = (`numerador'/ `pop_tert') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("Superior") ("`tema'") ("`indicador'") ("`valor'")
											
											} /*cierro if*/
											
							} /*cierro if de indicador*/
										
							/*Tasa de Asistencia Neta*/
							if "`indicador'" == "tasa_neta_asis" {	

							* Prescolar   
											capture sum age_pres [w=factor_ci]	 if `clase'==1 & asiste_ci!=.
											if _rc == 0 {
											local pop_pres = `r(sum)'
											
											sum asis_pres [w=factor_ci]	 if `clase'==1 & age_pres==1 & asiste_ci!=.
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_pres') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("Prescolar") ("`tema'") ("`indicador'") ("`valor'")
											}

							* Primaria   
											capture sum age_prim [w=factor_ci]	 if `clase'==1 & asiste_ci!=.
											if _rc == 0 {
											local pop_prim = `r(sum)'
											
											sum asis_prim [w=factor_ci]	 if `clase'==1 & age_prim==1 & asiste_ci!=.
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_prim') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("Primaria") ("`tema'") ("`indicador'") ("`valor'")
											}
							
							* Secundaria 
											capture sum age_seco [w=factor_ci]	if `clase'==1 & asiste_ci!=.
											if _rc == 0 {
											local pop_seco = `r(sum)'	
											
											sum asis_seco [w=factor_ci]	 if `clase'==1 & age_seco == 1 & asiste_ci!=.
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_seco') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("Secundaria") ("`tema'") ("`indicador'") ("`valor'")
											}
														
							*Superior
											capture sum age_tert [w=factor_ci]	if `clase'==1 & asiste_ci!=.
											if _rc == 0 {
											local pop_tert = `r(sum)'	
											
											sum asis_tert [w=factor_ci]	 if `clase'==1 & age_tert == 1 & asiste_ci!=.
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_tert') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("Superior") ("`tema'") ("`indicador'") ("`valor'")
											} /*cierro if*/
							} /* cierro if indicador*/
																								
							/*Tasa Asistencia grupo etario*/							
							if "`indicador'" == "tasa_asis_edad" {	
											
							* 4-5 años   
											capture sum age_pres [w=factor_ci]	 if `clase'==1 & asiste_ci!=.
											if _rc == 0 {
											local pop_4_5 = `r(sum)'
											
											sum age_pres [w=factor_ci]	 if `clase'==1 & asiste_ci==1 & asiste_ci!=.
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_4_5') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("4-5_Años") ("`tema'") ("`indicador'") ("`valor'")
											}

							* 6-11 años   
											capture sum age_prim [w=factor_ci]	 if `clase'==1 & asiste_ci!=.
											if _rc == 0 {
											local pop_6_11 = `r(sum)'
											
											sum age_prim [w=factor_ci]	 if `clase'==1 & asiste_ci==1 & asiste_ci!=.
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_6_11') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("6-11_Años") ("`tema'") ("`indicador'") ("`valor'")
											}
							
							* 12-14 años 
											capture sum age_seco_b [w=factor_ci]	if `clase'==1 & asiste_ci!=.
											if _rc == 0 {
											local pop_12_14 = `r(sum)'	
											
											sum age_seco_b [w=factor_ci]	 if `clase'==1 & asiste_ci==1 & asiste_ci!=.
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_12_14') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("12-14_Años") ("`tema'") ("`indicador'") ("`valor'")
											}
							
							* 15-17 años
											capture sum age_seco_a [w=factor_ci]	if `clase'==1 & asiste_ci!=.
											if _rc == 0 {
											local pop_15_17 = `r(sum)'	
											
											sum age_seco_a [w=factor_ci]	 if `clase'==1 & asiste_ci==1 & asiste_ci!=.
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_15_17') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("15-17_Años") ("`tema'") ("`indicador'") ("`valor'")
											}
							
							* 18-23 años
											capture sum age_tert [w=factor_ci]	if `clase'==1 & asiste_ci!=.
											if _rc == 0 {
											local pop_18_23 = `r(sum)'	
											
											
											sum age_tert [w=factor_ci]	 if `clase'==1 & asiste_ci==1 & asiste_ci!=.
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_18_23') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("18-23_Años") ("`tema'") ("`indicador'") ("`valor'")
											}
							} /* cierro if indicador*/

							/*Tasa No Asistencia grupo etario*/
							if "`indicador'" == "tasa_no_asis_edad" {	
											
							* 4-5 años   
											capture sum age_pres [w=factor_ci]	 if `clase'==1 & asiste_ci!=.
											if _rc == 0 {
											local pop_4_5 = `r(sum)'
											
											sum age_pres [w=factor_ci]	 if `clase'==1 & asiste_ci==0 
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_4_5') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("4-5_Años") ("`tema'") ("`indicador'") ("`valor'") 
											}

							* 6-11 años   
											capture sum age_prim [w=factor_ci]	 if `clase'==1 & asiste_ci!=.
											if _rc == 0 {
											local pop_6_11 = `r(sum)'
											
											sum age_prim [w=factor_ci]	 if `clase'==1 & asiste_ci==0 
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_6_11') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("6-11_Años") ("`tema'") ("`indicador'") ("`valor'")
											}
							
							* 12-14 años 
											capture sum age_seco_b [w=factor_ci]	if `clase'==1 & asiste_ci!=.
											if _rc == 0 {
											local pop_12_14 = `r(sum)'	
											
											sum age_seco_b [w=factor_ci]	 if `clase'==1 & asiste_ci==0 
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_12_14') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("12-14_Años") ("`tema'") ("`indicador'") ("`valor'")
											}
							
							* 15-17 años
											capture sum age_seco_a [w=factor_ci]	if `clase'==1 & asiste_ci!=.
											if _rc == 0 {
											local pop_15_17 = `r(sum)'	
							
											sum age_seco_a [w=factor_ci]	 if `clase'==1 & asiste_ci==0
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_15_17') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("15-17_Años") ("`tema'") ("`indicador'") ("`valor'")
											}
							
							* 18-23 años
											capture sum age_tert [w=factor_ci]	if `clase'==1 & asiste_ci!=.
											if _rc == 0 {
											local pop_18_23 = `r(sum)'	
											
											sum age_tert [w=factor_ci]	 if `clase'==1 & asiste_ci==0
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_18_23') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("18-23_Años") ("`tema'") ("`indicador'") ("`valor'")
											}
							} /* cierro if indicador*/
									
							*Años_Escolaridad y Años_Escuela*/
							if "`indicador'" == "Años_Escolaridad_25_mas" {	
																																		
											capture sum age_25_mas [w=factor_ci]	 if `clase'==1 & (aedu_ci !=. | edad_ci !=.)
											if _rc == 0 {
											local pop_25_mas = `r(sum)'
											
							* 0 años
											
											sum age_25_mas [w=factor_ci]	 if `clase'==1 & aedu_ci==0 & (aedu_ci !=. | edad_ci !=.)
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_25_mas') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("0_Años") ("`tema'") ("`indicador'") ("`valor'")
											
							* 1-5 años   
											
											sum age_25_mas [w=factor_ci]	 if `clase'==1 & (aedu_ci>=1 & aedu_ci <=5) & (aedu_ci !=. | edad_ci !=.)
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_25_mas') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("1-5_Años") ("`tema'") ("`indicador'") ("`valor'")
															
							* 6 años 		
											
											sum age_25_mas [w=factor_ci]	 if `clase'==1 & aedu_ci==6 & (aedu_ci !=. | edad_ci !=.)
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_25_mas') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("6_Años") ("`tema'") ("`indicador'") ("`valor'")
											
											
							* 7-11 años 
							
											sum age_25_mas [w=factor_ci]	 if `clase'==1 & (aedu_ci>=7 & aedu_ci <=11) & (aedu_ci !=. | edad_ci !=.)
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_25_mas') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("7-11_Años") ("`tema'") ("`indicador'") ("`valor'")
															
						
							* 12 Años
											
											sum age_25_mas [w=factor_ci]	 if `clase'==1 & aedu_ci==12 & (aedu_ci !=. | edad_ci !=.)
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_25_mas') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("12_Años") ("`tema'") ("`indicador'") ("`valor'")
											
							* 13 Años o más
											
											sum age_25_mas [w=factor_ci]	 if `clase'==1 & aedu_ci>=13 & (aedu_ci !=. | edad_ci !=.)
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_25_mas') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("13_Años_o_más") ("`tema'") ("`indicador'") ("`valor'")
											}
							} /* cierro if indicador*/		
										
							*Ninis Inactivos no asisten*/
							if "`indicador'" == "Ninis_2" {									
							* 15-24    
											capture sum age_15_24 [w=factor_ci]	 if `clase'==1 & edad_ci !=.
											if _rc == 0 {
											local pop_15_24 = `r(sum)'
											
											sum age_15_24 [w=factor_ci]	 if `clase'==1 & asiste_ci==0 & condocup_ci == 3 & edad_ci !=.
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_15_24') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("15-24_Años") ("`tema'") ("`indicador'") ("`valor'")
											}

							* 15-29   
											capture sum age_15_29 [w=factor_ci]	 if `clase'==1 & edad_ci !=.
											if _rc == 0 {
											local pop_15_29 = `r(sum)'
											
											sum age_15_29 [w=factor_ci]	 if `clase'==1 & asiste_ci==0 & condocup_ci == 3 & edad_ci !=.
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_15_29') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("15-29_Años") ("`tema'") ("`indicador'") ("`valor'")
											}						
							} /* cierro if indicador*/		

										
		/*=========== Indicadores de Eficiencia ============================================================================================*/																
									
							* Tasa de terminación*/
							if "`indicador'" == "tasa_terminacion_c" {	
										
							*Primaria

											capture sum age_term_p_c [w=factor_ci]	 if `clase'==1 & tprimaria !=.
											if _rc == 0 {
											local pop_12_14 = `r(sum)'
																		
											sum tprimaria [w=factor_ci]	 if `clase'==1 & age_term_p_c & tprimaria  !=.
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_12_14') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("Primaria") ("`tema'") ("`indicador'") ("`valor'")
											}
							
							*Secundaria		
							
											capture sum age_term_s_c [w=factor_ci]	 if `clase'==1 
											if _rc == 0 {
											local pop_18_20 = `r(sum)'
											
											sum tsecundaria [w=factor_ci]	 if `clase'==1 & age_term_s_c ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_18_20') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("Secundaria") ("`tema'") ("`indicador'") ("`valor'")
											}							
							} /*cierro indicador 
																
							* Tasa de abandono escolar temprano "Leavers"  */
							if "`indicador'" == "leavers" {
											
											
											cap sum age_18_24 [w=factor_ci]	 if `clase'==1 
											if _rc == 0 {
											local pop_18_24 = `r(sum)' 
											
											sum leavers [w=factor_ci] if `clase'==1 & edad_ci>=18 & edad_ci<=24
											local numerador = `r(sum)'
											local valor = (`numerador' / `pop_18_24') * 100
											
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("Total") ("`tema'") ("`indicador'") ("`valor'") 
											}					
							} /*cierro indicador 
									
							* Tasa de abandono sobreedad"  */
							if "`indicador'" == "tasa_sobre_edad" {	
							
				*Primaria

								capture sum asis_prim_c [w=factor_ci]	 if `clase'==1 & asiste_ci!=.
								if _rc == 0 {
								local pop_prim = `r(sum)'
															
								sum asis_prim_c [w=factor_ci]	 if `clase'==1 & age_prim_sobre==1 & asiste_ci!=. 
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_prim') * 100 
								post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("Primaria") ("`tema'") ("`indicador'") ("`valor'")
								}				
							} /* cierro if indicador*/ 
			}	/* cierro clase */			
	
		} /*cierro educacion*/
	
				
						
								
								noi di in y "Calculating numbers for country: `pais' - year : `ano' - tema: `tema' - indicator: `indicador'"
								
								}  /*cierro indicadores*/
						}/*Cierro temas*/
					}/*Cierro if _rc*/ 
										
					 if _rc != 0  { /* Si esta base de datos no existe, entonces haga: */
						foreach tema of local temas {
								
							if "`tema'" == "demografia" local indicadores hog_jef_mujer
							if "`tema'" == "pobreza"    local indicadores 
							if "`tema'" == "educacion"  local indicadores /*tasa_bruta_asis tasa_neta_asis tasa_asis_edad Años_Escolaridad_25_mas tasa_no_asis_edad  Ninis_2 leavers tasa_terminacion_c */ tasa_sobre_edad
							if "`tema'" == "vivienda"   local indicadores  
							if "`tema'" == "laboral"    local indicadores 
																
							foreach indicador of local indicadores {
									if "`tema'"	== "demografia"  {
										post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") (".")
									} /*cierro demografia*/
										
									if "`tema'" == "educacion" {	
										foreach clase of local clases {
						
											if "`indicador'" == "tasa_neta_asis_c" | "`indicador'" == "tasa_bruta_asis_c"	local niveles Primaria Secundaria Superior
											if "`indicador'" == "tasa_neta_asis" | "`indicador'" == "tasa_bruta_asis"	 	local niveles Prescolar Primaria Secundaria Superior 
											if "`indicador'" == "tasa_asis_edad" | "`indicador'" == "tasa_no_asis_edad"		local niveles 4-5_Años 6-11_Años 12-14_Años 15-17_Años 18-23_Años  
											if "`indicador'" == "Años_Escolaridad_25_mas" 									local niveles 0_Años 1-5_Años 6_Años 7-11_Años 12_Años 13_Años_o_más 
											if "`indicador'" == "Ninis_1" | "`indicador'" == "Ninis_2"						local niveles 15-24_Años 15-29_Años 
											if "`indicador'" == "tasa_terminacion" | "`indicador'" == "tasa_terminacion_c"	local niveles Primaria Secundaria 
											if "`indicador'" == "tasa_sobre_edad"											local niveles Primaria
											if "`indicador'" == "leavers" 													local niveles Total 
									  
												foreach nivel of local niveles {
													post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("`nivel'") ("`tema'") ("`indicador'") (".")
												} /* cierro niveles*/
										} /*cierro clases*/
									} /*cierro educacion*/	
							} /*cierro indicadores*/
						} /* cierro tema*/
					}/*cierro if _rc*/
				
				
				
					} /* cierro rondas */		
				} /* cierro encuestas */
			} /* cierro anos */
		} /* cierro paises */
	} /* cierro quietly */
 

postclose `ptablas'
use `tablas', clear
destring valor, replace
recode valor 0=.
save `tablas', replace 

* guardo el archivo temporal

save "\\hqpnas01\EDULAC\EDW\2. Indicators\Databases\Stata\temp_indicadores_cobertura.dta", replace
export excel using "${output}\Temp_total_indicadores_covertura.xlsx", first(var) sheet(Total_results) sheetreplace


/*====================================================================
                        5: Save and Export results
====================================================================*/

** Con esta exportación se sacan las BASES para subir a la plataforma 
preserve 
cap keep Ano Indicador Pais Nivel Clase Valor Fuente_Especifica

*Con este dofile se incluye y se preserva la estructura de las bases de datos que se venian trabajando por Ivan:	
		
include "\\hqpnas01\EDULAC\EDW\2. Indicators\Do.files\Cobertura y Eficiencia\Complementos CIMA\Variables adicionales bases de datos prov.do" 	
export excel using "${output}\Total_indicadores_covertura_prom.xlsx", first(var) sheet(Total_results) sheetreplace

save "\\hqpnas01\EDULAC\EDW\2. Indicators\Databases\Stata\Indicadores_cobertura_y_Eficiencia.dta", replace
save "\\hqpnas01\EDULAC\EDW\2. Indicators\Databases\Stata\Indicadores_cobertura_y_Eficiencia.cvs", replace
save "\\hqpnas01\EDULAC\EDW\2. Indicators\Databases\Stata\Indicadores_cobertura_y_Eficiencia.xlsx", replace

cd "\\hqpnas01\EDULAC\EDW\2. Indicators\Databases\Excel\"
outsheet using Indicadores_cobertura_y_Eficiencia.csv, delimiter(";") replace

restore

***********************************************************************
*  De esta exportación se alimentan las TABLAS de la plataforma
***********************************************************************

local indicadores tasa_bruta_asis tasa_neta_asis tasa_asis_edad tasa_no_asis_edad Años_Escolaridad_25_mas Ninis_1 Ninis_2 leavers tasa_terminacion tasa_terminacion_c tasa_bruta_asis_c tasa_neta_asis_c tasa_sobre_edad

foreach ind of local indicadores { 
	        
			preserve
			
			
			keep if (Indicador == "`ind'")
			keep Ano Indicador Pais Nivel Clase Valor Circa
			destring Circa, replace 
			
			replace Pais= "Argentina" 	if Pais== "ARG"
			replace Pais= "Bahamas"  	if Pais== "BHS"
			replace Pais= "Barbados"  	if Pais== "BRB"
			replace Pais= "Belice"  	if Pais== "BLZ"
			replace Pais= "Bolivia"   	if Pais== "BOL"
			replace Pais= "Brasil"    	if Pais== "BRA"
			replace Pais= "Chile"     	if Pais== "CHL"
			replace Pais= "Colombia"    if Pais== "COL"
			replace Pais= "Costa Rica"  if Pais== "CRI"
			replace Pais= "Ecuador"  	if Pais== "ECU"
			replace Pais= "El Salvador" if Pais== "SLV"
			replace Pais= "Guatemala"  	if Pais== "GTM"
			replace Pais= "Guyana"  	if Pais== "GUY"
			replace Pais= "Haití"	  	if Pais== "HTI"
			replace Pais= "Honduras"  	if Pais== "HND"
			replace Pais= "Jamaica"  	if Pais== "JAM"
			replace Pais= "México"  	if Pais== "MEX"
			replace Pais= "Nicaragua"  	if Pais== "NIC"
			replace Pais= "Panamá"  	if Pais== "PAN"
			replace Pais= "Paraguay"  	if Pais== "PRY"
			replace Pais= "Perú"  		if Pais== "PER"
			replace Pais= "Republica Dominicana"  if Pais== "DOM"
			replace Pais= "Surinam" 	if Pais== "SUR"
			replace Pais= "Trinidad y Tobago" if Pais== "TTO"
			replace Pais= "Uruguay" 	if Pais== "URY"
			replace Pais= "Venezuela" 	if Pais== "VEN"
			
			rename Ano Año
			cap replace Pais = "ALC" if Pais == "Promedio_ALC" 
			
			export excel using "${output}\\`ind'_input.xlsx", first(var) sheet(Total_results) sheetreplace
			sleep 1000
			restore
			
			
		    }
		

exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1. Los resultados de este do file alimentan una tabla dinámica ubicada en la ruta del output segunda pestaña
2. Cambian los niveles para la tasa bruta, tasa neta y nivel educativo de la poblaci'on de 25 y mas. Se sacan los indicadores para secundaria alta y baja.



Version Control:


