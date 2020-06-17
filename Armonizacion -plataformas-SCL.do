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

postfile `ptablas' str30(tiempo_id country_id geography_id clase nivel_id tema indicador valor) using `tablas', replace

** Creo locales principales:
 
local temas  educacion pobreza laboral vivienda demografia  										
local paises ARG BHS BOL BRB BLZ BOL BRA CHL COL CRI ECU SLV GTM GUY HTI HND JAM MEX NIC PAN PRY PER DOM SUR TTO URY VEN 
local anos 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018
*local clases Total Hombre Mujer quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano // hasta que se definan las clases finales
local geography_id total_nacional


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
<<<<<<< Updated upstream
=======
								* Inclusion
									include "${temporal}\var_tmp_GDI.do"
>>>>>>> Stashed changes
							
							
*****************************************************************************************************************************************
					* 1.2: Indicators for each topic		
*****************************************************************************************************************************************
					foreach tema of local temas {
											
							if "`tema'" == "demografia" local indicadores jefa_ch 
							if "`tema'" == "pobreza"    local indicadores pobreza31 pobreza vulnerable middle ginihh
							if "`tema'" == "educacion"  local indicadores tasa_neta_asis tasa_asis_edad Años_Escolaridad_25_mas Ninis_2 leavers tasa_terminacion_c tasa_sobre_edad
							if "`tema'" == "vivienda"   local indicadores aguared_ch des2_ch luz_ch dirtf 
							if "`tema'" == "laboral"    local indicadores tasa_ocupacion tasa_desocupacion tasa_participacion ocup_suf_salario ingreso_mens_prom ingreso_hor_prom formalidad_2 pensionista_65_mas ingreso_pension_65_mas 
	
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
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'")
											}
							} /* cierro indicador*/
		} /*cierro demografia */		
									
		if "`tema'" == "educacion" 	{
			
			local clases Total Hombre Mujer quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
			
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
	
		if "`tema'" == "laboral" 	{
			
			local clases Total Hombre Mujer quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
			local niveles Total age_15_24 age_15_29 age_15_64 age_25_64 age_65_mas 
				
				foreach clase of local clases {
					foreach nivel of local niveles {
					
							if "`indicador'" == "tasa_ocupacion" {																						 
				  
								capture sum `nivel' [w=factor_ci] if `clase'==1 & pet==1
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum `nivel' [w=factor_ci]	 if `clase'==1 & condocup_ci==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') * 100 
								post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'")
								}				
							} /*cierro indicador*/
							
							if "`indicador'" == "tasa_desocupacion" {	
							
								capture sum `nivel' [w=factor_ci] if `clase'==1 & pea==1
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum `nivel' [w=factor_ci]	 if `clase'==1 & condocup_ci==2
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') * 100 
								post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'")
								}				
								
							} /*cierro indicador*/
							
							if "`indicador'" == "tasa_participacion" {	
							
								capture sum `nivel' [w=factor_ci] if `clase'==1 & pet==1
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum `nivel' [w=factor_ci]	 if `clase'==1 & pea==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') * 100 
								post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'")
								}
							} /*cierro indicador*/
								
							if "`indicador'" == "ocup_suf_salario" {	
							
								capture sum `nivel' [w=factor_ci] if `clase'==1 & liv_wage !=.
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum `nivel' [w=factor_ci]	 if `clase'==1 & liv_wage ==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') * 100 
								post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'")
								}
							} /*cierro indicador*/
							
							if "`indicador'" == "ingreso_mens_prom" {	
							
								capture sum `nivel' [w=factor_ci] if `clase'==1 & ylab_ppp!=.
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum ylab_ppp [w=factor_ci]	 if `clase'==1 & `nivel'==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') 												
								
								post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'")
								}
							} /*cierro indicador*/
							
							if "`indicador'" == "ingreso_hor_prom" {	
							
								capture sum `nivel' [w=factor_ci] if `clase'==1 & hwage_ppp!=. 
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum hwage_ppp [w=factor_ci]	 if `clase'==1 & `nivel'==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') 												
								
								post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'")
								}
							} /*cierro indicador*/
							
							if "`indicador'" == "formalidad_2" {	
							
								capture sum `nivel' [w=factor_ci] if `clase'==1 & condocup_ci==1
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum `nivel' [w=factor_ci]	 if `clase'==1 & formal_ci==1 & condocup_ci==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') * 100												
								
								post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'")
								}
							} /*cierro indicador*/
					} /*cierro niveles*/		
					
							if "`indicador'" == "pensionista_65_mas" {	
							
								capture sum age_65_mas [w=factor_ci] if `clase'==1 
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum age_65_mas [w=factor_ci]	 if `clase'==1 & pensiont_ci==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') * 100												
								
								post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("age_65_mas") ("`tema'") ("`indicador'") ("`valor'")
								}
							} /*cierro indicador*/	
							
							if "`indicador'" == "ingreso_pension_65_mas" {	
							
								capture sum age_65_mas [w=factor_ci] if `clase'==1 & ypen_ppp!=. 
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum ypen_ppp [w=factor_ci]	 if `clase'==1 & age_65_mas==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') 											
								
								post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("age_65_mas") ("`tema'") ("`indicador'") ("`valor'")
								}
							} /*cierro indicador*/									
				} /* cierro clase*/ 
		} /*cierro laboral*/
		
		if "`tema'" == "pobreza" 	{
		
			local niveles Total age_00_04 age_05_14 age_15_24 age_25_64 age_65_mas
			local clases  Total Hombre Mujer Rural Urbano
				
			foreach clase of local clases{
				foreach nivel of local niveles {
									
							if "`indicador'" == "pobreza31" {																						 
				  
								capture sum `nivel' [w=factor_ci] if `clase'==1 
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum `nivel' [w=factor_ci]	 if `clase'==1 & poor31==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') * 100 
								
								post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'")
								}				
							} /*cierro indicador*/		
							
							if "`indicador'" == "pobreza" {																						 
				  
								capture sum `nivel' [w=factor_ci] if `clase'==1 
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum `nivel' [w=factor_ci]	 if `clase'==1 & poor==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') * 100 
								
								post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'")
								}				
							} /*cierro indicador*/
							
							if "`indicador'" == "vulnerable" {																						 
				  
								capture sum `nivel' [w=factor_ci] if `clase'==1 
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum `nivel' [w=factor_ci]	 if `clase'==1 & vulnerable==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') * 100 
								
								post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'")
								}				
							} /*cierro indicador*/	
							
							if "`indicador'" == "middle" {																						 
				  
								capture sum `nivel' [w=factor_ci] if `clase'==1 
								if _rc == 0 {
								local denominador = `r(sum)'
												
								sum `nivel' [w=factor_ci]	 if `clase'==1 & middle==1
								local numerador = `r(sum)'
								local valor = (`numerador' / `denominador') * 100 
								
								post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'")
								}				
							} /*cierro indicador*/		

				} /*cierro nivel*/	
			} /*cierro clase*/
			
			local clases Total Urbano Rural
			
				foreach clase of local clases {
							
							if "`indicador'" == "ginihh" {
							
								cap inequal7 pc_ytot_ch [w=factor_ci] if `clase'==1 & pc_ytot_ch !=.
								if _rc == 0 {
								local valor =`r(gini)'
								post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'")
								}
							} /*cierro indicador*/
							
			} /*cierro clase*/
			
		} /*cierro pobreza*/
		
		if "`tema'" == "vivienda" 	{
		
			local clases Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
		
				foreach clase of local clases{
			
							if "`indicador'" == "aguared_ch" {
	
											capture sum Total [w=factor_ci]	if jefe_ci ==1 & `clase'==1 & aguared_ch!=.
											if _rc == 0 {
											local num_hog = `r(sum)'
											
											sum Total [w=factor_ci]	 if jefe_ci==1 & `clase'==1 & aguared_ch==1 
											local numerador = `r(sum)'
											local valor = (`numerador' / `num_hog') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'")
											}
							} /* cierro indicador*/	
							
							if "`indicador'" == "des2_ch" {
	
											capture sum Total [w=factor_ci]	if jefe_ci ==1 & `clase'==1  & des2_ch!=.
											if _rc == 0 {
											local num_hog = `r(sum)'
											
											sum Total [w=factor_ci]	 if jefe_ci==1 & des2_ch==1 & `clase'==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `num_hog') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'")
											}
							} /* cierro indicador*/	
							
							if "`indicador'" == "luz_ch" {
	
											capture sum Total [w=factor_ci]	if jefe_ci ==1 & `clase'==1 & luz_ch!=.
											if _rc == 0 {
											local num_hog = `r(sum)'
											
											sum Total [w=factor_ci]	 if jefe_ci==1 & `clase'==1 & luz_ch==1 
											local numerador = `r(sum)'
											local valor = (`numerador' / `num_hog') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'")
											}
							} /* cierro indicador*/	
							
							if "`indicador'" == "dirtf" {
	
											capture sum Total [w=factor_ci]	if jefe_ci ==1 & `clase'==1 & dirtf!=.
											if _rc == 0 {
											local num_hog = `r(sum)'
											
											sum Total [w=factor_ci]	 if jefe_ci==1 & `clase'==1 & dirtf==1 
											local numerador = `r(sum)'
											local valor = (`numerador' / `num_hog') * 100 
											post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'")
											}
							} /* cierro indicador*/
							
				} /*cierro clase*/
		} /*cierro vivienda*/
								

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
							foreach indicador of local indicadores {
									noi di in y "Calculating numbers for country: `pais' - year : `ano' - tema: `tema' - indicator: `indicador'"
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
									
									if "`tema'" == "laboral" {
									
<<<<<<< Updated upstream
									 local niveles Total age_15_24 age_15_29 age_15_64 age_25_64 age_65_mas 
									 local clases Total Hombre Mujer quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
									 
=======
										 local niveles Total age_15_24 age_15_29 age_15_64 age_25_64 age_65_mas 
										 local clases Total Hombre Mujer quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
										 local clases2 Total Hombre Mujer Rural Urbano
										 
>>>>>>> Stashed changes
										foreach clase of local clases {
										
											if "`indicador'" == "pensionista_65_mas" | "`indicador'" == "ingreso_pension_65_mas"	local niveles age_65_mas
									  
												foreach nivel of local niveles {
													post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("`nivel'") ("`tema'") ("`indicador'") (".")
												} /* cierro niveles*/
										} /*cierro clases*/
									} /*cierro laboral*/
									
									if "`tema'" == "pobreza" {	
										
										local niveles Total age_00_04 age_05_14 age_15_24 age_25_64 age_65_mas
<<<<<<< Updated upstream
										local clasess  Total Hombre Mujer Rural Urbano
=======
										local clases  Total Hombre Mujer Rural Urbano
										local clases2 Total Hombre Mujer
>>>>>>> Stashed changes
										
										if "`indicador'" == "ginihh" local niveles no_aplica
										if "`indicador'" == "ginihh" local clases Total Rural Urbano
										
										foreach clase of local clasess {									  
												foreach nivel of local niveles {
													post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("`nivel'") ("`tema'") ("`indicador'") (".")
												} /* cierro niveles*/
										} /*cierro clasess*/
									} /*cierro pobreza*/
									
									if "`tema'" == "vivienda" 	{
		
										local clases Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
										
										foreach clase of local clasess {									  
												
													post `ptablas' ("`ano'") ("`pais'") ("`geography_id'") ("`clase'") ("no_aplica") ("`tema'") ("`indicador'") (".")
												
										} /*cierro clasess*/
									} /*cierro vivienda*/
										
										
									
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
destring valor, replace
recode valor 0=.
save `tablas', replace 

* guardo el archivo temporal
save "\\hqpnas01\EDULAC\EDW\2. Indicators\Databases\Stata\Indicadores_SCL.dta", replace

* Variables de formato 

include "${temporal}\var_formato.do"
<<<<<<< Updated upstream
order tiempo tiempo_id country_id geography_id clase nivel nivel_id tema indicador tipo valor
=======
order tiempo tiempo_id id_country_code geography_id clase clase2 nivel nivel_id tema indicador tipo valor muestra
>>>>>>> Stashed changes


/*====================================================================
                        5: Save and Export results
====================================================================*/


*export excel using "${output}\Indicadores_SCL.xlsx", first(var) sheet(Total_results) sheetreplace
save "${output}\indicadores_encuestas_hogares_scl.csv", replace

<<<<<<< Updated upstream
	g 		division = "SOC" if tema == "demografia" | tema == "vivienda" | tema == "pobreza" 
	replace division = "LMK" if tema == "laboral" 													 
	replace division = "EDU" if tema == "educacion" 		
=======
	g 		division = "soc" if tema == "demografia" | tema == "vivienda" | tema == "pobreza" 
	replace division = "lmk" if tema == "laboral" 													 
	replace division = "edu" if tema == "educacion" 
	replace division = "gdi" if tema == "inclusion"
	replace division = "mig" if tema == "migracion"
>>>>>>> Stashed changes

local divisiones SOC LMK EDU											 

foreach div of local divisiones { 
	        
			preserve
			
			keep if (division == "`div'")
			drop division
		
			save "${output}\\indicadores_encuestas_hogares_`div'.csv", replace
			sleep 1000
			restore
						
 }
		
exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1. 



Version Control:


