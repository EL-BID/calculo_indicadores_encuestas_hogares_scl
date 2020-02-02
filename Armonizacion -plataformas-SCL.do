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


postfile `ptablas' str30(Ano Indicador Pais Nivel Clase Valor) using `tablas', replace

* Los indicadores se dividen por temas: 

local temas demografia pobreza educacion vivienda laboral

foreach tema of local temas {
						
	if "`tema'" == "demografia" local indicadores 
	if "`tema'" == "pobreza"    local indicadores 
	if "`tema'" == "educacion"  local indicadores tasa_bruta_asis tasa_neta_asis tasa_asis_edad Años_Escolaridad_25_mas tasa_no_asis_edad  Ninis_2 leavers tasa_terminacion_c tasa_sobre_edad
	if "`tema'" == "vivienda"   local indicadores  
	if "`tema'" == "laboral"    local indicadores 
	
} /* cierro temas */
							
							
local paises ARG BHS BRB BLZ BOL BRA CHL COL CRI ECU SLV GTM GUY HTI HND JAM MEX NIC PAN PRY PER DOM SUR  TTO URY VEN 
local anos 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018
local clases Total Hombre Mujer quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano




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
	
			
				
 ******************************************************************************************************************************
		* 1.2: Calculo de indicadores			
*******************************************************************************************************************************
				
				foreach indicador of local indicadores {
						foreach clase of local clases {
						
						noi di in y "Calculating numbers for country: `pais' - year : `ano' - indicator: `indicador'"
						
/*=========== Indicadores de cobertura ==========================================================================================*/	
				/*Tasa Bruta de Asistencia*/
						if "`indicador'" == "tasa_bruta_asis" {
								
				
				* Prescolar   
								capture sum age_pres [w=factor_ci]	 if `clase'==1 & asiste_ci!=.
								if _rc == 0 {
								local pop_pres = `r(sum)'
								
								sum asis_pres [w=factor_ci]	 if `clase'==1 & asiste_ci!=.
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_pres') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("Prescolar") ("`clase'") ("`valor'") ("`encuesta'") ("`year'") 
								}
				
				* Primaria   
								capture sum age_prim [w=factor_ci]	 if `clase'==1 & asiste_ci!=.
								if _rc == 0 {
								local pop_prim = `r(sum)'
								
								sum asis_prim [w=factor_ci]	 if `clase'==1 & edad_ci>=6 & asiste_ci!=.
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_prim') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("Primaria")  ("`clase'") ("`valor'") ("`encuesta'") ("`year'") 
								}
				
				* Secundaria 
								capture sum age_seco [w=factor_ci]	if `clase'==1 & asiste_ci!=.
								if _rc == 0 {
								local pop_seco = `r(sum)'	
				
								sum asis_seco [w=factor_ci]	 if `clase'==1 & edad_ci>=6 & asiste_ci!=.
								local numerador = `r(sum)'
								local valor = (`numerador'/ `pop_seco') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("Secundaria")  ("`clase'") ("`valor'") ("`encuesta'") ("`year'") 
								}
				
				*Secundaria Baja
								capture sum age_seco_b [w=factor_ci]	if `clase'==1 & asiste_ci!=.
								if _rc == 0 {
								local pop_seco_b = `r(sum)'	
								
						
								
								sum asis_seco_b [w=factor_ci]	 if `clase'==1 & edad_ci>=6 & asiste_ci!=.
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_seco_b') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("Secundaria_Baja")  ("`clase'") ("`valor'") ("`encuesta'") ("`year'")  
								}
				
				*Secundaria Alta
								capture sum age_seco_a [w=factor_ci]	if `clase'==1 & asiste_ci!=.
								if _rc == 0 {
								local pop_seco_a = `r(sum)'	
								
								sum asis_seco_a  if `clase'==1 & edad_ci>=6 & asiste_ci!=.
								local numerador_m = `r(sum)' 
								local propor_m = (`numerador_m' / `total') * 100
				
								sum asis_seco_a [w=factor_ci]	 if `clase'==1 & edad_ci>=6 & asiste_ci!=.
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_seco_a') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("Secundaria_Alta")  ("`clase'") ("`valor'") ("`encuesta'") 
								} cierro if*/
								
								
				*Terciaria
								capture sum age_tert [w=factor_ci]	if `clase'==1 & asiste_ci!=.
								if _rc == 0 {
								local pop_tert = `r(sum)'	
								
								sum asis_tert [w=factor_ci]	 if `clase'==1 & edad_ci>=6 & asiste_ci!=.
								local numerador = `r(sum)'
								local valor = (`numerador'/ `pop_tert') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("Superior")  ("`clase'") ("`valor'") ("`encuesta'") ("`year'") 
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
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("Prescolar") ("`clase'") ("`valor'") ("`encuesta'") ("`year'") 
								}

				* Primaria   
								capture sum age_prim [w=factor_ci]	 if `clase'==1 & asiste_ci!=.
								if _rc == 0 {
								local pop_prim = `r(sum)'
								
								sum asis_prim [w=factor_ci]	 if `clase'==1 & age_prim==1 & asiste_ci!=.
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_prim') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("Primaria") ("`clase'") ("`valor'") ("`encuesta'") ("`year'") 
								}
				
				* Secundaria 
								capture sum age_seco [w=factor_ci]	if `clase'==1 & asiste_ci!=.
								if _rc == 0 {
								local pop_seco = `r(sum)'	
								
								sum asis_seco [w=factor_ci]	 if `clase'==1 & age_seco == 1 & asiste_ci!=.
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_seco') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("Secundaria") ("`clase'") ("`valor'") ("`encuesta'") ("`year'") 
								}
				

								
				*Superior
				
								capture sum age_tert [w=factor_ci]	if `clase'==1 & asiste_ci!=.
								if _rc == 0 {
								local pop_tert = `r(sum)'	
								
								sum asis_tert [w=factor_ci]	 if `clase'==1 & age_tert == 1 & asiste_ci!=.
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_tert') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("Superior")  ("`clase'") ("`valor'") ("`encuesta'") ("`year'") 
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
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("4-5_Años") ("`clase'") ("`valor'") ("`encuesta'") ("`year'") 
								}

				* 6-11 años   
								capture sum age_prim [w=factor_ci]	 if `clase'==1 & asiste_ci!=.
								if _rc == 0 {
								local pop_6_11 = `r(sum)'
								
								sum age_prim [w=factor_ci]	 if `clase'==1 & asiste_ci==1 & asiste_ci!=.
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_6_11') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("6-11_Años") ("`clase'") ("`valor'") ("`encuesta'") ("`year'") 
								}
				
				* 12-14 años 
								capture sum age_seco_b [w=factor_ci]	if `clase'==1 & asiste_ci!=.
								if _rc == 0 {
								local pop_12_14 = `r(sum)'	
								
								sum age_seco_b [w=factor_ci]	 if `clase'==1 & asiste_ci==1 & asiste_ci!=.
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_12_14') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("12-14_Años") ("`clase'") ("`valor'") ("`encuesta'") ("`year'") 
								}
				
				* 15-17 años
								capture sum age_seco_a [w=factor_ci]	if `clase'==1 & asiste_ci!=.
								if _rc == 0 {
								local pop_15_17 = `r(sum)'	
								
								sum age_seco_a [w=factor_ci]	 if `clase'==1 & asiste_ci==1 & asiste_ci!=.
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_15_17') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("15-17_Años") ("`clase'") ("`valor'") ("`encuesta'") ("`year'") 
								}
				
				* 18-23 años
								capture sum age_tert [w=factor_ci]	if `clase'==1 & asiste_ci!=.
								if _rc == 0 {
								local pop_18_23 = `r(sum)'	
								
								
								sum age_tert [w=factor_ci]	 if `clase'==1 & asiste_ci==1 & asiste_ci!=.
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_18_23') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("18-23_Años")  ("`clase'") ("`valor'") ("`encuesta'") ("`year'") 						
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
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("4-5_Años") ("`clase'") ("`valor'") ("`encuesta'") ("`year'") 
								}

				* 6-11 años   
								capture sum age_prim [w=factor_ci]	 if `clase'==1 & asiste_ci!=.
								if _rc == 0 {
								local pop_6_11 = `r(sum)'
								
								sum age_prim [w=factor_ci]	 if `clase'==1 & asiste_ci==0 
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_6_11') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("6-11_Años") ("`clase'") ("`valor'") ("`encuesta'") ("`year'") 
								}
				
				* 12-14 años 
								capture sum age_seco_b [w=factor_ci]	if `clase'==1 & asiste_ci!=.
								if _rc == 0 {
								local pop_12_14 = `r(sum)'	
								
								sum age_seco_b [w=factor_ci]	 if `clase'==1 & asiste_ci==0 
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_12_14') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("12-14_Años") ("`clase'") ("`valor'") ("`encuesta'") ("`year'")  
								}
				
				* 15-17 años
								capture sum age_seco_a [w=factor_ci]	if `clase'==1 & asiste_ci!=.
								if _rc == 0 {
								local pop_15_17 = `r(sum)'	
				
								sum age_seco_a [w=factor_ci]	 if `clase'==1 & asiste_ci==0
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_15_17') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("15-17_Años") ("`clase'") ("`valor'") ("`encuesta'") ("`year'") 
								}
				
				* 18-23 años
								capture sum age_tert [w=factor_ci]	if `clase'==1 & asiste_ci!=.
								if _rc == 0 {
								local pop_18_23 = `r(sum)'	
								
								sum age_tert [w=factor_ci]	 if `clase'==1 & asiste_ci==0
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_18_23') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("18-23_Años")  ("`clase'") ("`valor'") ("`encuesta'") ("`year'") 						
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
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("0_Años") ("`clase'") ("`valor'") ("`encuesta'") ("`year'") 
								
				* 1-5 años   
								
								sum age_25_mas [w=factor_ci]	 if `clase'==1 & (aedu_ci>=1 & aedu_ci <=5) & (aedu_ci !=. | edad_ci !=.)
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_25_mas') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("1-5_Años") ("`clase'") ("`valor'") ("`encuesta'") ("`year'")  
												
				* 6 años 		
								
								sum age_25_mas [w=factor_ci]	 if `clase'==1 & aedu_ci==6 & (aedu_ci !=. | edad_ci !=.)
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_25_mas') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("6_Años") ("`clase'") ("`valor'") ("`encuesta'") ("`year'")  
								
								
				* 7-11 años 
				
								sum age_25_mas [w=factor_ci]	 if `clase'==1 & (aedu_ci>=7 & aedu_ci <=11) & (aedu_ci !=. | edad_ci !=.)
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_25_mas') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("7-11_Años") ("`clase'") ("`valor'") ("`encuesta'") ("`year'")  
												

								
				* 12 Años
								
								sum age_25_mas [w=factor_ci]	 if `clase'==1 & aedu_ci==12 & (aedu_ci !=. | edad_ci !=.)
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_25_mas') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("12_Años") ("`clase'") ("`valor'") ("`encuesta'") ("`year'") 
								
				* 13 Años o más
								
								sum age_25_mas [w=factor_ci]	 if `clase'==1 & aedu_ci>=13 & (aedu_ci !=. | edad_ci !=.)
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_25_mas') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("13_Años_o_más") ("`clase'") ("`valor'") ("`encuesta'") ("`year'") 
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
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("15-24_Años") ("`clase'") ("`valor'") ("`encuesta'") ("`year'") 
								}

				* 15-29   
								capture sum age_15_29 [w=factor_ci]	 if `clase'==1 & edad_ci !=.
								if _rc == 0 {
								local pop_15_29 = `r(sum)'
								
								sum age_15_29 [w=factor_ci]	 if `clase'==1 & asiste_ci==0 & condocup_ci == 3 & edad_ci !=.
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_15_29') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("15-29_Años") ("`clase'") ("`valor'") ("`encuesta'") ("`year'") 
								}						
							} /* cierro if indicador*/		

							
/*=========== Indicadores de Eficiencia ==========================================================================================*/							
							
							
						
* Tasa de terminación*/
						if "`indicador'" == "tasa_terminacion_c" {	
							
				*Primaria

								capture sum age_term_p_c [w=factor_ci]	 if `clase'==1 & tprimaria !=.
								if _rc == 0 {
								local pop_12_14 = `r(sum)'
															
								sum tprimaria [w=factor_ci]	 if `clase'==1 & age_term_p_c & tprimaria  !=.
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_12_14') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("Primaria") ("`clase'") ("`valor'") ("`encuesta'") ("`year'") 
								}
				
				*Secundaria		
				
								capture sum age_term_s_c [w=factor_ci]	 if `clase'==1 
								if _rc == 0 {
								local pop_18_20 = `r(sum)'
								
								sum tsecundaria [w=factor_ci]	 if `clase'==1 & age_term_s_c ==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `pop_18_20') * 100 
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("Secundaria") ("`clase'") ("`valor'") ("`encuesta'") ("`year'")
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
								
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("Total") ("`clase'") ("`valor'") ("`encuesta'") ("`year'")
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
								post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("Primaria") ("`clase'") ("`valor'") ("`encuesta'") ("`year'")
								}				
						} /* cierro if indicador*/ 
						
						} /* cierro clase*/
					}/*Cierro indicadores*/
				}/*Cierro if _rc*/ 
								
				 if _rc != 0  { /* Si esta base de datos no existe, entonces haga: */
					foreach clase of local clases {
						foreach indicador of local indicadores {
						
							if "`indicador'" == "tasa_neta_asis_c" | "`indicador'" == "tasa_bruta_asis_c"	local niveles Primaria Secundaria Superior
							if "`indicador'" == "tasa_neta_asis" | "`indicador'" == "tasa_bruta_asis"	 	local niveles Prescolar Primaria Secundaria Superior 
							if "`indicador'" == "tasa_asis_edad" | "`indicador'" == "tasa_no_asis_edad"		local niveles 4-5_Años 6-11_Años 12-14_Años 15-17_Años 18-23_Años  
							if "`indicador'" == "Años_Escolaridad_25_mas" 									local niveles 0_Años 1-5_Años 6_Años 7-11_Años 12_Años 13_Años_o_más 
							if "`indicador'" == "Ninis_1" | "`indicador'" == "Ninis_2"						local niveles 15-24_Años 15-29_Años 
							if "`indicador'" == "tasa_terminacion" | "`indicador'" == "tasa_terminacion_c"	local niveles Primaria Secundaria 
							if "`indicador'" == "tasa_sobre_edad"											local niveles Primaria
							if "`indicador'" == "leavers" 													local niveles Total 

							foreach nivel of local niveles {
							 post `ptablas' ("`ano'") ("`indicador'") ("`pais'") ("`nivel'") ("`clase'") (".") ("`encuesta'") ("`year'")
							} /* cierro niveles*/
							
							
						
						} /* cierro indicadores*/
					} /* cierro clase*/
				}/*Cierro if _rc*/
				
			}
			
		}
	}
}
}

postclose `ptablas'
use `tablas', clear
destring Valor, replace
recode Valor 0=.
save `tablas', replace 

* guardo el archivo temporal

save "\\hqpnas01\EDULAC\EDW\2. Indicators\Databases\Stata\temp_indicadores_cobertura.dta", replace
export excel using "${output}\Temp_total_indicadores_covertura.xlsx", first(var) sheet(Total_results) sheetreplace

/*====================================================================
                        2: Including Quality check considerations
====================================================================*/

* En este programa se incluyen las consideraciones de las revisiones de calidad de la base
*tostring Ano, replace
include "\\hqpnas01\EDULAC\EDW\2. Indicators\Do.files\Cobertura y Eficiencia\Complementos CIMA\Consideraciones actualizacion indicadores - QCHK.do" 

save `tablas', replace

/*====================================================================
                        3: Including ALC average
====================================================================*/

*Criterios:  el cálculo de los promedios se hacen con la información del último anios disponible de los países.
*En ese sentido, si México no tiene información del indicador y para 2012 y tiene información disponible para 2011 y 2013, el dato de 2012 para efectos del promedio será el dato de 2011.
*Si México no tiene información para 2012 ni 2013 pero sí para 2011 para efectos del promedio el indicador que se toma es el del anio 2011. Siempre mira el último anio disponible de izquierda a derecha.

tempfile tablas2
tempname ptablas2
postfile `ptablas2' str30(Ano Indicador Pais Nivel Clase Valor Fuente_Especifica Circa) using `tablas2', replace


local paises ARG BHS BRB BLZ BOL BRA CHL COL CRI ECU SLV GTM GUY HTI HND JAM MEX NIC PAN PRY PER DOM SUR TTO URY VEN 
local anos 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018
local indicadores tasa_bruta_asis tasa_neta_asis tasa_asis_edad tasa_no_asis_edad Años_Escolaridad_25_mas Ninis_2 leavers tasa_terminacion_c tasa_bruta_asis_c tasa_neta_asis_c tasa_sobre_edad
local clases Total Hombre Mujer quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano


cap drop Valor2
gen Valor2 =.
destring Ano, replace
*tostring Ano, replace
foreach ano of local anos {
	foreach clase of local clases {
		foreach indicador of local indicadores {
		
					if "`indicador'" == "tasa_neta_asis_c" | "`indicador'" == "tasa_bruta_asis_c"	local niveles Primaria Secundaria Superior
					if "`indicador'" == "tasa_neta_asis" | "`indicador'" == "tasa_bruta_asis"	 	local niveles Prescolar Primaria Secundaria Superior 
					if "`indicador'" == "tasa_asis_edad" | "`indicador'" == "tasa_no_asis_edad"		local niveles 4-5_Años 6-11_Años 12-14_Años 15-17_Años 18-23_Años  
					if "`indicador'" == "Años_Escolaridad_25_mas" 									local niveles 0_Años 1-5_Años 6_Años 7-11_Años 12_Años 13_Años_o_más 
					if "`indicador'" == "Ninis_1" | "`indicador'" == "Ninis_2"						local niveles 15-24_Años 15-29_Años 
					if "`indicador'" == "tasa_terminacion" | "`indicador'" == "tasa_terminacion_c"	local niveles Primaria Secundaria 
					if "`indicador'" == "tasa_sobre_edad"											local niveles Primaria
					if "`indicador'" == "leavers" 													local niveles Total 
		
			foreach nivel of local niveles {
				foreach pais  of local paises  {
					local iff "Indicador== "`indicador'" & Clase== "`clase'" & Nivel=="`nivel'" & Pais == "`pais'" "				
					
					include "\\hqpnas01\EDULAC\EDW\2. Indicators\Do.files\Cobertura y Eficiencia\Complementos CIMA\CIRCAS promedio ALC.do" /*se incluyen los circas de cada anio para el cálculo de los promedio ALC*/
                       
                      local n : word count `year' /* se hace el conteo de anios para reemplazar en el indicador faltante, si es uno*/
					  local f : word 1 of `year'
					  di `n'
                      if `n' > 1 {
						local f : word 1 of `year'
						sum Valor if `iff' & Ano == `f'
						local first = `r(sum)'
						local s : word 2 of `year'
						sum Valor if `iff' & Ano == `s'          
	   					local second = `r(sum)'   
						local promedio = (`first' + `second') / 2
						replace Valor2 = `promedio' if `iff' & Ano== `ano' 
                      }/*cierro If*/
					else {
						
						sum Valor if `iff' & Ano == `f'
						replace Valor2 = `r(sum)' if `iff' & Ano== `ano'
						}
																
				} /* cierro paises*/
				
				 recode Valor2 0=.
					sum Valor2 if Indicador== "`indicador'" & Clase== "`clase'" & Nivel=="`nivel'" & Ano== `ano' 
					local valor `r(mean)' 
					post `ptablas2' ("`ano'") ("`indicador'") ("Promedio_ALC") ("`nivel'") ("`clase'") ("`valor'") (".") (".") 
				
			} /* cierro clases*/
		} /* cierro indiadores*/
	} /*cierro clases*/
}/* cierro anos*/
	
postclose `ptablas2'
use `tablas2', clear

destring Valor, replace
recode Valor 0=.


save "\\hqpnas01\EDULAC\EDW\2. Indicators\Databases\Stata\temp_LACmean_indicadores_cobertura.dta", replace

append using `tablas'
*append using "\\hqpnas01\EDULAC\EDW\2. Indicators\Databases\Stata\temp_indicadores_cobertura.dta"

/*====================================================================
                        4: Quality check considerations
====================================================================*/

/*
* Este reshape se hace para el control de calidad de la información 

preserve

keep Ano Indicador Pais Nivel Clase Valor

local paises ARG BHS BRB BLZ BOL BRA CHL COL CRI ECU SLV GTM GUY HTI HND JAM MEX NIC PAN PRY PER DOM SUR TTO URY VEN Promedio_ALC 
local anos 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 
local indicadores tasa_bruta_asis tasa_neta_asis tasa_asis_edad tasa_no_asis_edad Años_Escolaridad_25_mas Ninis_1 Ninis_2 tasa_terminacion leavers
local clases Total Hombre Mujer quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano

cap drop desvest media Z
gen media =.
gen desvest=.
gen Z=.

foreach indicador of local indicadores {

		if "`indicador'" == "tasa_bruta_asis" 											local niveles Primaria Secundaria Superior
		if "`indicador'" == "tasa_neta_asis" 										 	local niveles Prescolar Primaria Secundaria Superior 
		if "`indicador'" == "tasa_asis_edad" | "`indicador'" == "tasa_no_asis_edad"		local niveles 4-5_Años 6-11_Años 12-14_Años 15-17_Años 18-23_Años  
		if "`indicador'" == "Años_Escolaridad_25_mas" 									local niveles 0_Años 1-5_Años 6_Años 7-11_Años 12_Años 13_Años_o_más
		if "`indicador'" == "Ninis_1" | "`indicador'" == "Ninis_2"						local niveles 15-24_Años 15-29_Años 
		if "`indicador'" == "tasa_terminacion" 											local niveles Primaria Secundaria 
		if "`indicador'" == "leavers" 													local niveles Total 
	
	foreach nivel of local niveles {
		foreach clase of local clases {
			foreach pais of local paises {
														
				sum Valor if Indicador == "`indicador'" & Clase == "`clase'" & Nivel=="`nivel'" & Pais == "`pais'"
				cap local medi =`r(mean)' 
				cap local desves =`r(sd)' 
				
				cap replace media = `medi' if Indicador== "`indicador'" & Clase== "`clase'" & Nivel=="`nivel'" & Pais == "`pais'"
				cap replace desvest = `desves' if Indicador== "`indicador'" & Clase== "`clase'" & Nivel=="`nivel'" & Pais == "`pais'"
												
			} /*cierro paises*/
		} /*cierro clases*/
	} /*cierro niveles*/
} /*cierro indicadores*/	

replace Z= (Valor-media)/desvest
sort Indicador Pais Nivel 
		
reshape wide Valor Z , i(Indicador Pais Nivel Clase ) j(Ano) s
export excel using "\\hqpnas01\EDULAC\EDW\6. Quality Check\Total_indicadores_cobertura_Qck_con_cambios.xlsx", first(var) sheet(Total_results) sheetreplace
sleep 1000
restore

*/

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


