/*====================================================================
project:       Armonizacion actualización plataformas SCL
Author:        Data Ecosystem Working Group
Dependencies:  SCL/EDU/LMK/SPH/GDI/MIG - IDB 
----------------------------------------------------------------------
Creation Date:    Nov 2020
Modification Date:   
Do-file version:    01
References:          
Output:             Excel-DTA file
====================================================================*/

/*====================================================================
                        0: Program set up
====================================================================*/
version 16.0
drop _all 
set more off 
*ssc install quantiles inequal7
* cap ssc install estout
* cap ssc install inequal7


/**** if composition utility function ****************************
 scl_if_compose clase1 clase2 clase3 if ...
 will return
  if ... & `clase1'==1 & `clase2'==1 & `clase3'==1
 in s(xif) macro.
 Needs to clear s manually calling sreturn clear.
******************************************************************/
capture program drop scl_if_compose
program scl_if_compose, sclass
 syntax [if]
 /* paramaters of the current disaggregation (comes from $current_slice global macro) */
 local clase1 : word 4 of $current_slice
 local clase2 : word 5 of $current_slice
 local clase3 : word 6 of $current_slice
 
 if "`if'"!="" {
     /* most common case */
	 sreturn local xif `"`if' & `clase1'==1 & `clase2'==1 & `clase3'==1"'
  }
  else {
	 sreturn local xif `"if `clase1'==1 & `clase2'==1 & `clase3'==1"'
  }
  
end


/***** scl_pct ***************************************************
 Calculates percentage indicators using
 the given variable and given category.
 Accepts 'if'.

 E.g., scl_pct pmujer sexo_ci "Mujer" if ...
******************************************************************/
capture program drop scl_pct                                                        
program scl_pct
  syntax anything [if]
  /* parameters of the indicator */
  local indname : word 1 of `anything'
  local indvar : word 2 of `anything'
  local indcat : word 3 of `anything'
  /* paramaters of the current disaggregation (comes from $current_slice global macro) */
  local pais : word 1 of $current_slice
  local ano : word 2 of $current_slice
  local geografia_id : word 3 of $current_slice
  local clase1 : word 4 of $current_slice
  local clase2 : word 5 of $current_slice
  local clase3 : word 6 of $current_slice
  
  /* create the "if" part of the command
    combining with the "if" set when calling
	the program (if any) */
  scl_if_compose `if'
  local xif `"`s(xif)'"'
  sreturn clear
   
  
  display `"$tema - `indname'"' 
  capture quietly estpost tab `indvar' [w=round(factor_ch)] `xif', m
  
  if _rc == 0 {
    if `"`indcat'"'=="" local indcat "1"
	
    mat temp=e(pct)
    local valor = temp[1,colnumb(temp,`"`indcat'"')]
    
	post $output ("`ano'") ("`pais'")  ("`geografia_id'") ("`clase1'") ("`clase2'") ("`clase3'") ("$tema") ("`indname'") (`"% `indvar'==`indcat'"') (`valor')
	
  }
  else {
   /* generate a line with missing value */
	post $output ("`ano'") ("`pais'")  ("`geografia_id'") ("`clase1'") ("`clase2'") ("`clase3'") ("$tema") ("`indname'") (`"% `indvar'==`indcat'"') (.)
  }
  
end


/***** scl_nivel ***************************************************
 Calculates frequency indicators using
 the given variable and given category.
 Accepts 'if'.

 E.g., scl_nivel ncotizando cotizando_ci if ...
******************************************************************/
capture program drop scl_nivel                                                        
program scl_nivel
  syntax anything [if]
  /* parameters of the indicator */
  local indname : word 1 of `anything'
  local indvar : word 2 of `anything'
  /* paramaters of the current disaggregation (comes from $current_slice global macro) */
  local pais : word 1 of $current_slice
  local ano : word 2 of $current_slice
  local geografia_id : word 3 of $current_slice
  local clase1 : word 4 of $current_slice
  local clase2 : word 5 of $current_slice
  local clase3 : word 6 of $current_slice
  
  scl_if_compose `if'
  local xif `"`s(xif)'"'
  sreturn clear
 
  
  display `"$tema - `indname'"'
  capture quietly sum `indvar' [w=round(factor_ch)] `xif'
  
  if _rc == 0 {
    capture local valor = `r(sum_w)'
	
	post $output ("`ano'") ("`pais'")  ("`geografia_id'") ("`clase1'") ("`clase2'") ("`clase3'") ("$tema") ("`indname'") (`"sum of `indvar'"') (`valor')
	
  }
  else {
   /* generate a line with missing value */
	post $output ("`ano'") ("`pais'")  ("`geografia_id'") ("`clase1'") ("`clase2'") ("`clase3'") ("$tema") ("`indname'") (`"sum of `indvar'"') (.)
  }
  
end


/***** scl_mean **************************************************
 Calculates mean indicators using
 the given variable.
 Accepts 'if'.

 E.g., scl_mean ylmfem_ch shareylmfem_ch if jefe_ci==1
******************************************************************/
capture program drop scl_mean                                                        
program scl_mean
  syntax anything [if]
  /* parameters of the indicator */
  local indname : word 1 of `anything'
  local indvar : word 2 of `anything'
  /* paramaters of the current disaggregation (comes from $current_slice global macro) */
  local pais : word 1 of $current_slice
  local ano : word 2 of $current_slice
  local geografia_id : word 3 of $current_slice
  local clase1 : word 4 of $current_slice
  local clase2 : word 5 of $current_slice
  local clase3 : word 6 of $current_slice
  
  scl_if_compose `if'
  local xif `"`s(xif)'"'
  sreturn clear
 
  
  display `"$tema - `indname'"'
  capture quietly sum `indvar' [w=round(factor_ch)] `xif'
  
  if _rc == 0 {
    capture local valor = `r(mean)'
	
	if ""=="`valor'" local valor = .
	
	post $output ("`ano'") ("`pais'")  ("`geografia_id'") ("`clase1'") ("`clase2'") ("`clase3'") ("$tema") ("`indname'") (`"mean of `indvar'"') (`valor')
	
  }
  else {
   /* generate a line with missing value */
	post $output ("`ano'") ("`pais'")  ("`geografia_id'") ("`clase1'") ("`clase2'") ("`clase3'") ("$tema") ("`indname'") (`"mean of `indvar'"') (.)
  }
  
end


/***** scl_ratio ***************************************************
 Calculates ratio indicators using
 two variables (1st the numerator, 2nd the denominator).
 Accepts 'if'.
 Notice that each variable is calculated in a sum command,
 capturing the r(sum) result.

 E.g., scl_ratio tasa_asis_edad  asis_`sfix' age_`sfix' if ...
******************************************************************/
capture program drop scl_ratio                                                        
program scl_ratio
  syntax anything [if]
  /* parameters of the indicator */
  local indname : word 1 of `anything'
  local indvarnum : word 2 of `anything'
  local indvarden : word 3 of `anything'
  /* paramaters of the current disaggregation (comes from $current_slice global macro) */
  local pais : word 1 of $current_slice
  local ano : word 2 of $current_slice
  local geografia_id : word 3 of $current_slice
  local clase1 : word 4 of $current_slice
  local clase2 : word 5 of $current_slice
  local clase3 : word 6 of $current_slice
  
  /* create the "if" part of the command
    combining with the "if" set when calling
	the program (if any) */
  scl_if_compose `if'
  local xif `"`s(xif)'"'
  sreturn clear
   
  
  display `"$tema - `indname'"'
  capture quietly sum `indvarnum' [w=round(factor_ch)] `xif'
  
  if _rc == 0 {
    local numerator = `r(sum)'
	
	capture quietly sum `indvarden' [w=round(factor_ch)] `xif'
	if _rc==0 {
		capture local denominator = `r(sum)'
		local valor = (`numerator' / `denominator') * 100 
		
		post $output ("`ano'") ("`pais'")  ("`geografia_id'") ("`clase1'") ("`clase2'") ("`clase3'") ("$tema") ("`indname'") (`"`indvarnum'/`indvarden'"') (`valor')
	}
	else {
		/* generate a line with missing value */
		post $output ("`ano'") ("`pais'")  ("`geografia_id'") ("`clase1'") ("`clase2'") ("`clase3'") ("$tema") ("`indname'") (`"`indvarnum'/`indvarden'"') (.)
	}
	
  }
  else {
   /* generate a line with missing value */
	post $output ("`ano'") ("`pais'")  ("`geografia_id'") ("`clase1'") ("`clase2'") ("`clase3'") ("$tema") ("`indname'") (`"`indvarnum'/`indvarden'"') (.)
  }
  
end


/*********************************************************************/

/*
* Do files will be loaded relative to current directory. Set current directory to the GitHub folder
*  using command "cd" before running the code 
*/
local mydir = c(pwd) /* GitHub folder */

/*
* source = Location of the harmonized surveys databases.
*
* If you want to set a local folder instead, set this global macro before running the code.
* If $source is empty, then by default the shared folder will be used (must be at the IDB or
* connected to the VPN)
*/
if "${source}"=="" {
	global source  	 "\\Sdssrv03\surveys\harmonized" /*if you have a local copy of the .dta files, change here to use your local copy */
}

/*
* Location of the .do files to include
*/
global input	 "`mydir'\calculo_indicadores_encuestas_hogares_scl\Input"
global output 	 "`mydir'\calculo_indicadores_encuestas_hogares_scl\Onput"

/*
* Location for temporary files. This folder is on MS TEAMS.
* 
* NOTE: template.dta must be in this folder.
*/
global covidtmp  "C:\Users\\`= c(username)'\Inter-American Development Bank Group\Data Governance - SCL - General\Proyecto - Data management\Bases tmp"




/*====================================================================
                        1: Open dataset and Generate indicators
====================================================================*/

**** include "${input}\calculo_microdatos_scl.do"
						
tempfile tablas
tempname ptablas
global output `ptablas'

** Este postfile da estructura a la base:

* postfile `ptablas' str30(tiempo_id pais_id geografia_id clase1 clase2 nivel_id tema indicador valor muestra) using `tablas', replace
postfile `ptablas' str4 tiempo_id str3 pais_id str25(geografia_id clase1 clase2 clase3 tema indicador) str35 description valor /* muestra */ using `tablas', replace

** Creo locales principales:
						
local paises ARG BHS BOL BRB BLZ BRA CHL COL CRI ECU SLV GTM GUY HTI HND JAM MEX NIC PAN PRY PER DOM SUR TTO URY VEN 
local anos 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 

local geografia_id total_nacional


qui {
	foreach pais of local paises {
		foreach ano of local anos {
			
			* En este dofile de encuentra el diccionario de encuestas y rondas de la región
			 include "${input}\Directorio HS LAC.do" 
			 * Encuentra el archivo para este país/año
			 cap use "${source}\\`pais'\\`encuestas'\data_arm\\`pais'_`ano'`rondas'_BID.dta" , clear

			 
			 /* 
			   Alternatively, if you want to test a certain collection of .dta files,
			   uncomment the code below which will search for all .dta files in the $source
			   folder, that start with the name PAIS_ANO.
			   
			  *local files : dir "${source}" files "`pais'_`ano'*.dta"
			  *local foundfile : word 1 of `files'
			  *cap use "${source}\\`foundfile'", clear
			
			  */	
				if _rc == 0 { 
					//* Si esta base de datos existe, entonces haga: */
					noisily display "Calculando \\`pais'\\`encuestas'\data_arm\\`pais'_`ano'`rondas'_BID.dta..."		
														
						* variables de clase
							
					cap {
						gen Total  =  1
						gen Primaria  =  1
						gen Secundaria  =  1
						gen Superior  =  1
						gen Prescolar  =  1
						gen Hombre = (sexo_ci==1)  
						gen Mujer  = (sexo_ci==2)
						gen Urbano = (zona_c==1)
						gen Rural  = (zona_c==0)
					
						
						if "`pais'" == "HND" | ("`pais'" == "NIC" & "`ano'" == "2009")  {
							drop quintil 
						}
								
						* Generando Quintiles de acuerdo a SUMMA y toda la división 
						 destring idh_ch, replace			
						 egen    ytot_ci= rsum(ylm_ci ylnm_ci ynlm_ci ynlnm_ci) if miembros_ci==1
						replace ytot_ci= .   if ylm_ci==. & ylnm_ci==. & ynlm_ci==. & ynlnm_ci==.
						 bys		idh_ch: egen ytot_ch= sum(ytot_ci) if miembros_ci==1
						replace ytot_ch=. if ytot_ch<=0
						 gen 	pc_ytot_ch=ytot_ch/nmiembros_ch	
						sort 	pc_ytot_ch idh_ch idp_ci
						 gen 	suma1=sum(factor_ci) if ytot_ch>0 & ytot_ch!=.
						 qui su  suma1
						local 	ppquintil2 = r(max)/5 

						 gen quintil_1=1 if suma1>=0 & suma1<=1*`ppquintil2'
						 gen quintil_2=1 if suma1>1*`ppquintil2' & suma1<=2*`ppquintil2'
						 gen quintil_3=1 if suma1>2*`ppquintil2' & suma1<=3*`ppquintil2'
						 gen quintil_4=1 if suma1>3*`ppquintil2' & suma1<=4*`ppquintil2'
						 gen quintil_5=1 if suma1>4*`ppquintil2' & suma1<=5*`ppquintil2'						
			
					* Variables intermedias 
			
						* Educación: niveles y edades teóricas cutomizadas  
							include "${input}\var_tmp_EDU.do"
						* Mercado laboral 
							include "${input}\var_tmp_LMK.do"
						* Pobreza, vivienda, demograficas
							include "${input}\var_tmp_SOC.do"
						* Inclusion
						**	include "${input}\var_tmp_GDI.do"	
							
					* base de datos de microdatos con variables intermedias
					********** include "${input}\append_calculo_microdatos_scl.do"	
					
					} //end capture
				}
				else {
				
					/* IN the case the dta file DOES NOT EXIST for this country/year, we are going
					  to execute the rest of the code ANYWAY. The reason is: regardless if the 
					  file exists or not, all indicators will be generated in the same way, 
					  but with a "missing value" if the file does not exist. The programs are
					  already capturing it and will generate the missing values accordingly
					  whenever the indicator cannot be calculated.
					  */
					  *display "`pais'\\`encuesta'\data_arm\\`pais'_`ano'`ronda'_BID.dta - non existe. Generando missing values..."
					  noisily display "`pais'_`ano'`rondas'_BID.dta - no se encontró el archivo. Generando missing values..."
					  
					  /* use an empty file which contains all variables */
					  use "${covidtmp}\\template.dta", clear
					
				}
				
				
					
*****************************************************************************************************************************************
					* 1.2: Indicators for each topic		
*****************************************************************************************************************************************

						************************************************
						  global tema "demografia"
						************************************************
						// Division: SCL
						// Authors: ...
						************************************************
					
						local clases Total quintil_1 /*quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano*/
						local clases2 Total Rural Urbano
		
						foreach clase1 of local clases {
							foreach clase2 of local clases2 {								
								local clase3 Total // formerly called "nivel". If "no_aplica", use Total.
								
								
								/* Parameters of current disaggregation levels, used by all commands */
								global current_slice `pais' `ano' `geografia_id' `clase1' `clase2' `clase3'
								noisily display "$tema: $current_slice"
								
								//======== CALCULATE INDICATORS ================================================
								
										
								/* Porcentaje de hogares con jefatura femenina */
								scl_pct ///
									jefa_ch jefa_ch "1" if jefa_ch!=. & sexo_ci!=.
								
								
													/*if "`indicador'" == "jefa_ch" {
															
													capture estpost tabulate jefa_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1 & `clase2'==1 & jefa_ch!=. & sexo_ci!=.
													local valor= e(pct)[1,2]
													if _rc == 0 {
													
													estpost tabulate jefa_ch if `clase'==1 & `clase2'==1 & jefa_ch!=. & sexo_ci!=.
													local muestra=e(b)[1,2]	
																			
																			post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																			}
																			
																			else {
																			
																			post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																			}
															}  cierro indicador*/
										
								/* Porcentaje de hogares con jefatura económica femenina */
								scl_pct ///
									jefaecon_ch hhfem_ch "1" if jefe_ci==1 & hhfem_ch!=. & sexo_ci!=.
								
													/*
													if "`indicador'" == "jefaecon_ch" {
									
													capture estpost tabulate hhfem_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1 & `clase2'==1 & hhfem_ch!=. & sexo_ci!=.
													local valor= e(pct)[1,2]
													if _rc == 0 {
													
													estpost tabulate hhfem_ch if `clase'==1 & `clase2'==1 & hhfem_ch!=. & sexo_ci!=.
													local muestra=e(b)[1,2]	
																			
																			post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																			}
																			
																			else {
																			
																			post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																			}														
																			
															}  cierro indicador*/
										
								/* Porcentaje de población femenina*/
								scl_pct ///
									pobfem_ci pobfem_ci "1" if pobfem_ci!=. 
									
													/*if "`indicador'" == "pobfem_ci" {
														
													capture estpost tabulate pobfem_ci [w=round(factor_ci)] if  `clase'==1 & `clase2'==1 & pobfem_ci!=. 
													local valor= e(pct)[1,2]
													if _rc == 0 {
													
													estpost tabulate pobfem_ci if `clase'==1 & `clase2'==1 & pobfem_ci!=.
													local muestra=e(b)[1,2]	
																			
																			post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																			}
																			
																			else {
																			
																			post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																			}	
									
																		
															}  cierro indicador*/
										
								/* Porcentaje de hogares con al menos un miembro de 0-5 años*/
								scl_pct ///
									miembro6_ch miembro6_ch "1" if jefe_ci==1 & miembro6_ch!=.
								
														/* if "`indicador'" == "miembro6_ch" {
														
														capture estpost tabulate miembro6_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1 & `clase2'==1 & miembro6_ch!=.
														local valor= e(pct)[1,2]
														if _rc == 0 {
														
														estpost tabulate miembro6_ch if `clase'==1 & `clase2'==1 & miembro6_ch!=.
														local muestra=e(b)[1,2]	
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
										
																				
																}  *cierro indicador*/
										
								* Porcentaje de hogares con al menos un miembro entre 6-16 años*
								scl_pct ///
									miembro6y16_ch miembro6y16_ch "1" if jefe_ci==1 & miembro6y16_ch!=.
									
														/* if "`indicador'" == "miembro6y16_ch" {
														
														capture estpost tabulate miembro6y16_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1 & `clase2'==1 & miembro6y16_ch!=.
														local valor= e(pct)[1,2]
														if _rc == 0 {
														
														estpost tabulate miembro6y16_ch if `clase'==1 & `clase2'==1 & miembro6y16_ch!=.
														local muestra=e(b)[1,2]	
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
										
																			
																}  *cierro indicador*
																
								* Porcentaje de hogares con al menos un miembro de 65 años o más*
														*if "`indicador'" == "miembro65_ch" {
										
													   capture estpost tabulate miembro65_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1 & `clase2'==1 & miembro65_ch!=.
														local valor= e(pct)[1,2]
														if _rc == 0 {
														
														estpost tabulate miembro65_ch if `clase'==1 & `clase2'==1 & miembro65_ch!=.
														local muestra=e(b)[1,2]	
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																} * cierro indicador*
																
								* Porcentaje de hogares unipersonales*
														if "`indicador'" == "unip_ch" {
														
														capture estpost tabulate unip_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1 & `clase2'==1 & unip_ch!=.
														local valor= e(pct)[1,2]
														if _rc == 0 {
														
														estpost tabulate unip_ch if `clase'==1 & `clase2'==1 & unip_ch!=.
														local muestra=e(b)[1,2]	
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																} * cierro indicador*
																
								* Porcentaje de hogares nucleares*
														if "`indicador'" == "nucl_ch" {
														
														capture estpost tabulate nucl_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1 & `clase2'==1 & nucl_ch!=.
														local valor= e(pct)[1,2]
														if _rc == 0 {
														
														estpost tabulate nucl_ch if `clase'==1 & `clase2'==1 & nucl_ch!=.
														local muestra=e(b)[1,2]	
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																} * cierro indicador*
																
								* Porcentaje de hogares ampliados*
														if "`indicador'" == "ampl_ch" {
														
														capture estpost tabulate ampl_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1 & `clase2'==1 & ampl_ch!=.
														local valor= e(pct)[1,2]
														if _rc == 0 {
														
														estpost tabulate ampl_ch if `clase'==1 & `clase2'==1 & ampl_ch!=.
														local muestra=e(b)[1,2]	
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
										
																				
																} * cierro indicador*
																
								* Porcentaje de hogares compuestos*
														if "`indicador'" == "comp_ch" {
													
													   capture estpost tabulate comp_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1 & `clase2'==1 & comp_ch!=.
														local valor= e(pct)[1,2]
														if _rc == 0 {
														
														estpost tabulate comp_ch if `clase'==1 & `clase2'==1 & comp_ch!=.
														local muestra=e(b)[1,2]	
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																			
																} * cierro indicador*
																
								* Porcentaje de hogares corresidentes*
														if "`indicador'" == "corres_ch" {
										
														capture estpost tabulate corres_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1 & `clase2'==1 & corres_ch!=.
														local valor= e(pct)[1,2]
														if _rc == 0 {
														
														estpost tabulate corres_ch if `clase'==1 & `clase2'==1 & corres_ch!=.
														local muestra=e(b)[1,2]	
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																} * cierro indicador*/
								
								
								
								
								/*Razón de dependencia*/
								scl_mean ///
									depen_ch depen_ch if jefe_ci==1 & depen_ch!=.
									
														/*	
														if "`indicador'" == "depen_ch" {
																
														capture sum depen_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1 & `clase2'==1 & depen_ch!=. 
														capture local valor= `r(mean)'
														if _rc == 0 {
														
														capture sum depen_ch if jefe_ci==1 & `clase'==1 & `clase2'==1 & depen_ch!=. 
														capture local muestra= `r(N)'
																											
															
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}		
																} cierro indicador*/
										
								/* Número promedio de miembros del hogar*/
								scl_mean ///
									tamh_ch nmiembros_ch if jefe_ci==1 & nmiembros_ch!=. 
									
														/*if "`indicador'" == "tamh_ch" {
										
														capture sum nmiembros_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1 & `clase2'==1 & nmiembros_ch!=. 
														capture local valor= `r(mean)'
														if _rc == 0 {
														
														capture sum nmiembros_ch if jefe_ci==1 & `clase'==1 & `clase2'==1 & nmiembros_ch!=. 
														capture local muestra= `r(N)'
																											
															
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																		
																} * cierro indicador*
																
								* Porcentaje de población menor de 18 años*
														if "`indicador'" == "pob18_ci" {
														
														capture estpost tabulate pob18_ci [w=round(factor_ci)] if `clase'==1 & `clase2'==1 & pob18_ci!=.
														local valor= e(pct)[1,2]
														if _rc == 0 {
														
														estpost tabulate pob18_ci if `clase'==1 & `clase2'==1 & pob18_ci!=.
														local muestra=e(b)[1,2]	
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																} * cierro indicador*
																
								* Porcentaje de población de 65+ años*
														if "`indicador'" == "pob65_ci" {
										
														capture estpost tabulate pob65_ci [w=round(factor_ci)] if `clase'==1 & `clase2'==1 & pob65_ci!=.
														local valor= e(pct)[1,2]
														if _rc == 0 {
														
														estpost tabulate pob65_ci if `clase'==1 & `clase2'==1 & pob65_ci!=.
														local muestra=e(b)[1,2]	
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																} * cierro indicador*
																										
								* Porcentaje de individuos en union formal o informal*
														if "`indicador'" == "union_ci" {
										
														capture estpost tabulate union_ci [w=round(factor_ci)] if `clase'==1 & `clase2'==1 & union_ci!=.
														local valor= e(pct)[1,2]
														if _rc == 0 {
														
														estpost tabulate union_ci if `clase'==1 & `clase2'==1 & union_ci!=.
														local muestra=e(b)[1,2]	
							
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																} * cierro indicador*
																										
								* Edad mediana de la población en años *
														if "`indicador'" == "pobedad_ci" {
														
														capture sum edad_ci [w=round(factor_ci)] if  `clase'==1 & `clase2'==1 & edad_ci!=., detail
														capture local valor= `r(p50)'
														if _rc == 0 {
														
														capture sum edad_ci if jefe_ci==1 & `clase'==1 & `clase2'==1 & edad_ci!=. 
														capture local muestra= `r(N)'
																											
															
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																} * cierro indicador*/	
										
										
										
								}/*cierro clase2*/		
							} /*cierro clase*/
							
							local clases Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 
															
							foreach clase1 of local clases {
								local clase2 Total
								local clase3 Total							
								
								
								/* Parameters of current disaggregation levels, used by all commands */
								global current_slice `pais' `ano' `geografia_id' `clase1' `clase2' `clase3'
								noisily display "$tema: $current_slice"	
										
								//======== CALCULATE INDICATORS ================================================
								
								/* Porcentaje de población que reside en zonas urbanas*/
								scl_pct ///
									urbano_ci urbano_ci "1" if urbano_ci!=. 
									
													/*
													if "`indicador'" == "urbano_ci"  {
										
														capture estpost tabulate urbano_ci [w=round(factor_ci)] if `clase'==1 & urbano_ci!=. 
														local valor= e(pct)[1,2]
														if _rc == 0 {
														
														estpost tabulate urbano_ci if `clase'==1 & urbano_ci!=. 
														local muestra=e(b)[1,2]	
																			
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																} * cierro indicador*/
										
							} /*cierro clase*/			    
											
											
											
							************************************************
							  global tema "educacion"
							************************************************
							// Division: EDU
							// Authors: ...
							************************************************				
									
							local clases  Total Hombre Mujer quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
							local clases2 Total Hombre Mujer Rural Urbano
							
							
							foreach clase1 of local clases {	
								foreach clase2 of local clases2 {
								
								
									local clases3 Prescolar Primaria Secundaria Superior
								
									foreach clase3 of local clases3 {								
						
									
										/* Parameters of current disaggregation levels, used by all commands */
										global current_slice `pais' `ano' `geografia_id' `clase1' `clase2' `clase3'
										noisily display "$tema: $current_slice"

										//======== CALCULATE INDICATORS ================================================
										local sfix ""
										if `"`clase3'"'=="Prescolar" local sfix pres
										else if `"`clase3'"'=="Primaria" local sfix prim
										else if `"`clase3'"'=="Secundaria" local sfix seco
										else if `"`clase3'"'=="Superior" local sfix tert
										
										/* Tasa asistencia Bruta  */
										scl_ratio ///
											tasa_bruta_asis asis_`sfix' age_`sfix' if asiste_ci!=.
								    
										
																									 
															/* Prescolar   
																capture sum age_pres [w=round(factor_ci)]	 if `clase'==1 & asiste_ci!=. & `clase2' ==1
																if _rc == 0 {
																local pop_pres = `r(sum)'
																
																sum asis_pres [w=round(factor_ci)]	 if `clase'==1 & asiste_ci!=. & `clase2' ==1
																local numerador = `r(sum)'
																local valor = (`numerador' / `pop_pres') * 100 
																
																sum asis_pres 	 if `clase'==1 & asiste_ci!=. & `clase2' ==1
																local muestra = `r(sum)'
																
																post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Prescolar") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																}
												
												

															* Primaria   
																capture sum age_prim [w=round(factor_ci)] if asiste_ci!=. &  `clase'==1  & `clase2' ==1  
																if _rc == 0 {
																local pop_prim = `r(sum)'
																
																sum asis_prim [w=round(factor_ci)]	 if  edad_ci>=6 & asiste_ci!=. & `clase'==1 & `clase2' ==1
																local numerador = `r(sum)'
																local valor = (`numerador' / `pop_prim') * 100 
																
																sum asis_prim  if `clase'==1 & edad_ci>=6 & asiste_ci!=. & `clase2' ==1
																local muestra = `r(sum)'
																
																post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																}
												
															* Secundaria 
																capture sum age_seco [w=round(factor_ci)]	if `clase'==1 & asiste_ci!=. & `clase2' ==1
																if _rc == 0 {
																local pop_seco = `r(sum)'	
												
																sum asis_seco [w=round(factor_ci)]	 if `clase'==1 & edad_ci>=6 & asiste_ci!=. & `clase2' ==1
																local numerador = `r(sum)'
																local valor = (`numerador'/ `pop_seco') * 100 
																
																sum asis_seco  if `clase'==1 & edad_ci>=6 & asiste_ci!=. & `clase2' ==1
																local muestra = `r(sum)'
																
																post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Secundaria") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																}								
																
																*Terciaria
																capture sum age_tert [w=round(factor_ci)]	if `clase'==1 & asiste_ci!=. & `clase2' ==1
																if _rc == 0 {
																local pop_tert = `r(sum)'	
																
																sum asis_tert [w=round(factor_ci)]	 if `clase'==1 & edad_ci>=6 & asiste_ci!=. & `clase2' ==1
																local numerador = `r(sum)'
																local valor = (`numerador'/ `pop_tert') * 100 
																
																sum asis_tert  if `clase'==1 & edad_ci>=6 & asiste_ci!=. & `clase2' ==1
																local muestra = `r(sum)'
																
																post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Superior") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																
																*/
														
											/* Tasa asistencia Neta */
											scl_pct ///
												tasa_neta_asis asis_`sfix' "1" if age_`sfix' == 1 & asiste_ci!=.									
								    			
										

																/* Prescolar   						
																cap estpost tab asis_pres [w=round(factor_ci)] 	if age_pres == 1 & asiste_ci !=. & `clase'==1 & `clase2' ==1, m
																if _rc == 0 {
																	mat proporcion = e(pct)
																	local valor = proporcion[1,2]
																
																	estpost tab asis_pres				if age_pres == 1 & asiste_ci !=. & `clase'==1  & `clase2' ==1, m
																	mat nivel = e(b)
																	local muestra = nivel[1,2]
																											
																post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Prescolar") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																}
																
																else {
																
																post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") (".") (".")
																
																}
																* Primaria   
																cap estpost tab asis_prim [w=round(factor_ci)] 	if age_prim == 1 & asiste_ci !=. & `clase'==1 & `clase2' ==1, m
																if _rc == 0 {
																	mat proporcion = e(pct)
																	local valor = proporcion[1,1]
																
																	estpost tab asis_prim				if age_prim == 1 & asiste_ci !=. & `clase'==1  & `clase2' ==1, m
																	mat nivel = e(b)
																	local muestra = nivel[1,1]
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																}
																
																else {
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") (".") (".")
																
																}
																* Secundaria 
																cap estpost tab asis_seco [w=round(factor_ci)] 	if age_seco == 1 & asiste_ci !=. & `clase'==1 & `clase2' ==1, m
																if _rc == 0 {
																	mat proporcion = e(pct)
																	local valor = proporcion[1,1]
																	
																	estpost tab asis_seco				if age_seco == 1 & asiste_ci !=. & `clase'==1  & `clase2' ==1, m
																	mat nivel = e(b)
																	local muestra = nivel[1,1]							
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Secundaria") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																}
																
																else {
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") (".") (".")
																
																}
																
																*Superior						
																cap estpost tab asis_tert [w=round(factor_ci)] 	if age_tert == 1 & asiste_ci !=. & `clase'==1 & `clase2' ==1, m
																if _rc == 0 {
																	mat proporcion = e(pct)
																	local valor = proporcion[1,1]
											  
																	estpost tab asis_tert				if age_tert == 1 & asiste_ci !=. & `clase'==1  & `clase2' ==1, m
																	mat nivel = e(b)
																	local muestra = nivel[1,1]																	
																
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Superior") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																}
																
																else {
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") (".") (".")
																
																}
																
															*/
															
															
										} /* cierre clases3 */
											
										
										local clases3 age_4_5 age_6_11 age_12_14 age_15_17 age_18_23
									
										foreach clase3 of local clases3 {								
								
											
												/* Parameters of current disaggregation levels, used by all commands */
												global current_slice `pais' `ano' `geografia_id' `clase1' `clase2' `clase3'
												noisily display "$tema: $current_slice"

												//======== CALCULATE INDICATORS ================================================	
												
												/* Tasa asistencia grupo etario */
												scl_pct ///
													tasa_asis_edad asiste_ci "1"
												
																	/*
																	cap estpost tab asiste_ci [w=round(factor_ci)] if `nivel' ==1 & `clase'==1
																	if _rc == 0 {
																		mat proporcion = e(pct)
																		local valor = proporcion[1,2]
																		
																		estpost tab asiste_ci 				if `nivel' ==1 & `clase'==1
																		mat nivel = e(b)
																		local muestra = nivel[1,2]
																												
																		post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}
																	
																	else {
																			
																			post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") (".") (".")
														
																	}*/
														
												
												/* Tasa No Asistencia grupo etario */
												scl_pct ///
													tasa_no_asis_edad asiste_ci "0"
									 
																	/*cap estpost tab asiste_ci [w=round(factor_ci)] if `nivel' ==1 & `clase'==1
																	if _rc == 0 {
																	mat proporcion = e(pct)
																	local valor = proporcion[1,1]
																	
																	estpost tab asiste_ci 				if `nivel' ==1 & `clase'==1
																	mat nivel = e(b)
																	local muestra = nivel[1,1]
																		
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}
																	
																	else {
																			
																			post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") (".") (".")
																		
																	}*/
													
										} /*cierro clases3 */
										
												
										/* Años_Escolaridad y Años_Escuela
										if "`indicador'" == "Años_Escolaridad_25_mas" {	
												
											local niveles anos_0 anos_1_5 anos_6 anos_7_11 anos_12 anos_13_o_mas
											
												foreach nivel of local niveles {
																								
													cap estpost tab `nivel' [w=round(factor_ci)] if  age_25_mas==1 & `clase'==1 & `clase2'==1 & (aedu_ci !=. | edad_ci !=.), m
													if _rc == 0 {
													mat proporcion = e(pct)
													local valor = proporcion[1,1]

													estpost tab `nivel' 				if age_25_mas==1 & `clase'==1 & `clase2'==1 & (aedu_ci !=. | edad_ci !=.), m
													mat nivel = e(b)
													local muestra = nivel[1,1]
																								
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
													} /* cierro if */
													
													else {
															
															post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") (".") (".")
														
													} /* cierro else */
													
												} /* cierro nivel */		
										} /* cierro if indicador*/		
													
										* Ninis Inactivos no asisten
										if "`indicador'" == "Ninis_2" {									
											
											local niveles age_15_24 age_15_29
												
												foreach nivel of local niveles {
																								
													cap estpost tab nini [w=round(factor_ci)] 	if `nivel' == 1 & `clase'==1  & edad_ci !=. & `clase2' ==1, m
													if _rc == 0 {
														mat proporcion = e(pct)
														local valor = proporcion[1,1]
														
														estpost tab nini 				if `nivel' == 1 & `clase'==1 & edad_ci !=. & `clase2' ==1, m
														mat nivel = e(b)
														local muestra = nivel[1,1]
														
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
													} /* cierro if */
													
													else {
															
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") (".") (".")
														
													} /* cierro else */
													
													
												} /* cierro nivel*/			
										} /* cierro if indicador*/		

										* Tasa de terminación
										if "`indicador'" == "tasa_terminacion_c" {	
													
											*Primaria
										
													cap estpost tab tprimaria [w=round(factor_ci)] if age_term_p_c == 1 & tprimaria !=. & `clase'==1  & edad_ci !=. & `clase2' ==1, m
													if _rc == 0 {
													mat proporcion = e(pct)
													local valor = proporcion[1,2]
													
													estpost tab tprimaria  if age_term_p_c == 1 & tprimaria !=. & `clase'==1  & edad_ci !=. & `clase2' ==1, m
													mat nivel = e(b)
													local muestra = nivel[1,2]
											
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
													
													}/* cierro if */
													
													else {
															
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") (".") (".")
														
													} /* cierro else */
											
													
											*Secundaria		
										
													cap estpost tab tsecundaria [w=round(factor_ci)] 	if age_term_s_c == 1 & tprimaria !=. & `clase'==1  & edad_ci !=. & `clase2' ==1, m
													if _rc == 0 {
													mat proporcion = e(pct)
													local valor = proporcion[1,2]
													
													estpost tab tsecundaria  if age_term_s_c == 1 & tprimaria !=. & `clase'==1  & edad_ci !=. & `clase2' ==1, m
													mat nivel = e(b)
													local muestra = nivel[1,2]
														
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Secundaria") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
													
													}/* cierro if */
													
													else {
															
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Secundaria") ("`tema'") ("`indicador'") (".") (".")
														
													} /* cierro else */
													
										} /*cierro indicador 
																			
										* Tasa de abandono escolar temprano "Leavers"  */
										if "`indicador'" == "leavers" {
																									
													cap estpost tab leavers [w=round(factor_ci)] 	if age_18_24 == 1 & edad_ci !=. & `clase'==1 & `clase2' ==1, m
													if _rc == 0 {
													mat proporcion = e(pct)
													local valor = proporcion[1,1]
													
													estpost tab leavers 				if age_18_24 == 1 & edad_ci !=. & `clase'==1  & `clase2' ==1, m
													mat nivel = e(b)
													local muestra = nivel[1,1]
																							
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Total") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
													} /* cierro if */
													
													else {
															
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Total") ("`tema'") ("`indicador'") (".") (".")
														
													} /* cierro else */
													
										} /*cierro indicador 
												
										* Tasa de abandono sobreedad"  */
										if "`indicador'" == "tasa_sobre_edad" {								
											

											*Primaria
													
													cap estpost tab age_prim_sobre [w=round(factor_ci)] 	if asis_prim_c == 1 & asiste_ci !=. & `clase'==1 & `clase2' ==1, m
													if _rc == 0 {
													mat proporcion = e(pct)
													local valor = proporcion[1,1]
													
													estpost tab age_prim_sobre				if asis_prim_c == 1 & asiste_ci !=. & `clase'==1  & `clase2' ==1, m
													mat nivel = e(b)
													local muestra = nivel[1,1]

													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
													} /* cierro if */
													
													else {
															
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") (".") (".")
														
													} /* cierro else */
													
													
										} /* cierro if indicador*/ 
										
										*/
										
										
									} /* cierro clase2 */
								}	/* cierro clase */			
				
								
								
								
								************************************************
								  global tema "laboral"
								************************************************
								// Division: LMK
								// Authors: ...
								************************************************				
									
								
								local clases  Total Hombre Mujer quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
								local clases2 Total Hombre Mujer Rural Urbano
								local clases3 Total age_15_24 age_15_29 age_15_64 age_25_64 age_65_mas 
							
								foreach clase1 of local clases {
									foreach clase2 of local clases2 {
										foreach clase3 of local clases3 {
										
										
											/* Parameters of current disaggregation levels, used by all commands */
											global current_slice `pais' `ano' `geografia_id' `clase1' `clase2' `clase3'
											noisily display "$tema: $current_slice"	

											//======== CALCULATE INDICATORS ================================================
													
											scl_pct ///
												tasa_ocupacion condocup_ci "Ocupado"
								
																	/*if "`indicador'" == "tasa_ocupacion" {																						 
														  
																		cap estpost tab condocup_ci [w=round(factor_ci)] if `clase'==1 & `clase2' ==1 & `nivel' ==1
																		if _rc == 0 {
																		local valor=e(pct)[1,1]
																		tab condocup_ci if `clase'==1 & `clase2' ==1 & `nivel' ==1
																		local muestra= e(b)[1,1]

																		post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																		}
																		
																	} *cierro indicador*/
																	
										
											scl_pct ///
												tasa_desocupacion condocup_ci "Desocupado"
										
																/*if "`indicador'" == "tasa_desocupacion" {	
																
																	cap estpost tab condocup_ci [w=round(factor_ci)] if `clase'==1 & `clase2' ==1 & `nivel' ==1
																	if _rc == 0 {
																	local valor=e(pct)[1,2]
																	tab condocup_ci if `clase'==1 & `clase2' ==1 & `nivel' ==1
																	local muestra= e(b)[1,2]
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}				
																	
																} *cierro indicador*/
										
											scl_pct ///
												tasa_participacion pea "1" if pet==1
										
										
																/*if "`indicador'" == "tasa_participacion" {	
																
																	cap estpost tab pea [w=round(factor_ci)] if `clase'==1 & `clase2' ==1 & pet ==1
																	if _rc == 0 {
																	local valor=e(pct)[1,2]
																	tab condocup_ci if `clase'==1 & `clase2' ==1 & pet ==1
																	local muestra= e(b)[1,2]
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}
																	
																} *cierro indicador*/
																
																
											
										/*
																if "`indicador'" == "ocup_suf_salario" {	
																
																	cap estpost tab liv_wage [w=round(factor_ci)] if `clase'==1 & `clase2' ==1 & `nivel' ==1 & liv_wage!=. & condocup_ci==1
																	if _rc == 0 {
																	local valor=e(pct)[1,2]
																	tab liv_wage if `clase'==1 & `clase2' ==1 & `nivel' ==1 & liv_wage!=. & condocup_ci==1
																	local muestra= e(b)[1,2]
																											
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}
																	
																} /*cierro indicador*/
																
																if "`indicador'" == "ingreso_mens_prom" {	
																	
																	capture sum ylab_ppp [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & horastot_ci!=.
																	if _rc == 0 {
																	cap local valor = `r(mean)'												
																	
																	csum ylab_ppp if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & horastot_ci!=.
																	local muestra = `r(N)'
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}
																	
																} /*cierro indicador*/
																
																if "`indicador'" == "ingreso_hor_prom" {	
																
																	capture sum hwage_ppp [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & horastot_ci!=.
																	if _rc == 0 {
																	cap local valor = `r(mean)'												
																	
																	sum hwage_ppp if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & horastot_ci!=.
																	local muestra = `r(N)'
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}
																} /*cierro indicador*/
																
																if "`indicador'" == "horas_trabajadas" {	
																
																	capture sum horastot_ci [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & horastot_ci!=.
																	if _rc == 0 {
																	cap local valor = `r(mean)'												
																	
																	sum horastot_ci if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & horastot_ci!=.
																	local muestra = `r(N)'
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}
																} /*cierro indicador*/	

																if "`indicador'" == "dura_desempleo" {	
																
																	capture sum durades_ci [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==2 & durades_ci!=.
																	if _rc == 0 {
																	cap local valor = `r(mean)'												
																	
																	sum durades_ci if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==2  & durades_ci!=.
																	local muestra = `r(N)'
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}
																} /*cierro indicador*/	

																if "`indicador'" == "salminmes_ppp" {	
																
																	capture sum salmm_ppp [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & salmm_ppp!=.
																	if _rc == 0 {
																	cap local valor = `r(mean)'												
																	
																	sum salmm_ppp if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & salmm_ppp!=.
																	local muestra = `r(N)'
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}
																} /*cierro indicador*/
																
																if "`indicador'" == "sal_menor_salmin" {	
																
																	capture estpost tab menorwmin [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																	if _rc == 0 {
																	local valor=e(pct)[1,2]
																	
																	estpost tab menorwmin if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																	local muestra=e(b)[1,2]
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}
																} /*cierro indicador*/							
																							
																if "`indicador'" == "salminhora_ppp" {	
																
																	capture sum hsmin_ppp [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & hsmin_ppp!=.
																	if _rc == 0 {
																	cap local valor = `r(mean)'												
																	
																	sum hsmin_ppp if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & hsmin_ppp!=.
																	local muestra = `r(N)'
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}
																} /*cierro indicador*/	
																
																if "`indicador'" == "salmin_mes" {	
																
																	capture sum salmm_ci [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & salmm_ci!=.
																	if _rc == 0 {
																	cap local valor = `r(mean)'												
																	
																	sum salmm_ci if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & salmm_ci!=.
																	local muestra = `r(N)'
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}
																} /*cierro indicador*/
																
																if "`indicador'" == "salmin_hora" {	
																
																	capture sum hsmin_ci [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & hsmin_ci!=.
																	if _rc == 0 {
																	cap local valor = `r(mean)'												
																	
																	sum hsmin_ci if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & hsmin_ci!=.
																	local muestra = `r(N)'
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}
																} /*cierro indicador*/	

																if "`indicador'" == "tasa_asalariados" {	
																
																	capture estpost tab asalariado [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																	if _rc == 0 {
																	local valor=e(pct)[1,2]
																	
																	estpost tab asalariado if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																	local muestra=e(b)[1,2]
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}
																} /*cierro indicador*/	
																
																if "`indicador'" == "tasa_independientes" {	
																
																	capture estpost tab ctapropia [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																	if _rc == 0 {
																	local valor=e(pct)[1,2]
																	
																	estpost tab ctapropia if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																	local muestra=e(b)[1,2]
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}
																} /*cierro indicador*/	
																
																if "`indicador'" == "tasa_patrones" {	
																
																	capture estpost tab patron [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																	if _rc == 0 {
																	local valor=e(pct)[1,2]							
																	estpost tab patron if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1		
																	local muestra=e(b)[1,2]
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}
																} /*cierro indicador*/	
																
																if "`indicador'" == "tasa_sinremuneracion" {	
																
																	cap estpost tab sinremuner [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																	if _rc == 0 {
																	local valor=e(pct)[1,2]
																	
																	estpost tab sinremuner if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																	local muestra=e(b)[1,2]
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}
																} /*cierro indicador*/							
																
																if "`indicador'" == "subempleo" {	
																
																	capture estpost tab subemp_ci [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																	if _rc == 0 {
																	local valor=e(pct)[1,2]
																	
																	estpost tab subemp_ci if `clase'==1 & `nivel'==1 & `clase2'==1 & condocup_ci==1
																	local muestra=e(b)[1,2]
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}
																	
																} /*cierro indicador*/		
																
																if "`indicador'" == "inglaboral_ppp_formales" {	
																
																	cap sum ylab_ppp [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2'==1 & condocup_ci==1 & formal_ci==1
																	if _rc == 0 {
																	cap local valor = `r(mean)'												
																	
																	sum ylab_ppp if `clase'==1 & `nivel'==1 & `clase2'==1 & condocup_ci==1 & formal_ci==1
																	local muestra = `r(N)'
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}
																} /*cierro indicador*/
																
																if "`indicador'" == "inglaboral_ppp_informales" {	
																
																	capture sum ylab_ppp [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2'==1 & condocup_ci==1 & formal_ci==0
																	if _rc == 0 {
																	cap local valor = `r(mean)'												
																	
																	sum ylab_ppp if `clase'==1 & `nivel'==1 & `clase2'==1 & condocup_ci==1 & formal_ci==0
																	local muestra = `r(N)'
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}
																} /*cierro indicador*/
																
																if "`indicador'" == "inglaboral_formales" {	
																
																	capture sum ylab_ci [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2'==1 & condocup_ci==1 & formal_ci==1
																	if _rc == 0 {
																	cap local valor = `r(mean)'												
																	
																	sum ylab_ci if `clase'==1 & `nivel'==1 & `clase2'==1 & condocup_ci==1 & formal_ci==1
																	local muestra = `r(N)'
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}
																} /*cierro indicador*/
																
																if "`indicador'" == "inglaboral_informales" {	
																
																	capture sum ylab_ci [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2'==1 & condocup_ci==1 & formal_ci==0
																	if _rc == 0 {
																	cap local valor = `r(mean)'												
																	
																	sum ylab_ci if `clase'==1 & `nivel'==1 & `clase2'==1 & condocup_ci==1 & formal_ci==0
																	local muestra = `r(N)'
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}
																} /*cierro indicador*/
										*/
										
										
										
										/* Sum asalariado */
										scl_nivel ///
											nivel_asalariados asalariado if condocup_ci==1
						
																/*if "`indicador'" == "nivel_asalariados" {	
																
																	capture estpost tab asalariado [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																	if _rc == 0 {
																	local valor=e(b)[1,2]
																	
																	estpost tab asalariado if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																	local muestra=e(b)[1,2]
																	
																	post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	}
																} /*cierro indicador*/	
										
																			if "`indicador'" == "nivel_independientes" {	
																			
																				capture estpost tab ctapropia [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(b)[1,2]
																				
																				estpost tab ctapropia if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "nivel_patrones" {	
																			
																				capture estpost tab patron [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(b)[1,2]
																				
																				estpost tab patron if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	

																			if "`indicador'" == "nivel_sinremuneracion" {	
																				
																				cap estpost tab sinremuner [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(b)[1,2]
																				
																				estpost tab sinremuner if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																			} /*cierro indicador*/		
																			
																			if "`indicador'" == "nivel_subempleo" {	
																			
																				capture estpost tab subemp_ci [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(b)[1,2]
																				
																				estpost tab subemp_ci if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																			} /*cierro indicador*/	

																			if "`indicador'" == "tasa_agro" {	
																			
																				capture estpost tab agro [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(pct)[1,2]
																				
																				estpost tab agro if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "nivel_agro" {	
																			
																				capture estpost tab agro [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(b)[1,2]
																				
																				estpost tab agro if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "tasa_minas" {	
																			
																				capture estpost tab minas [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(pct)[1,2]
																				
																				estpost tab minas if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "nivel_minas" {	
																			
																				cap estpost tab minas [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(b)[1,2]
																				
																				estpost tab minas if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																			} /*cierro indicador*/			

																			if "`indicador'" == "tasa_industria" {	
																			
																				capture estpost tab industria [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(pct)[1,2]
																				
																				estpost tab industria if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "nivel_industria" {	
																			
																				/*cap estpost tab industria [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(b)[1,2]
																				
																				estpost tab industria if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")*/
																				
																				 scl_nivel ///
																					 nivel_industria industria `geografia_id' `clase' `clase2' `nivel' `pais' `ano'
																				
																				}
																			} /*cierro indicador*/								
																			
																			if "`indicador'" == "tasa_sspublicos" {	
																			
																				capture estpost tab sspublicos [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(pct)[1,2]
																				
																				estpost tab sspublicos if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "nivel_sspublicos" {	
																			
																				capture estpost tab sspublicos [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(b)[1,2]
																				
																				estpost tab sspublicos if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																			} /*cierro indicador*/						
																			
																			if "`indicador'" == "tasa_construccion" {	
																			
																				cap estpost tab construccion [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(pct)[1,2]
																				
																				estpost tab construccion if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "nivel_construccion" {	
																			
																				cap estpost tab construccion [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(b)[1,2]
																				
																				estpost tab construccion if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/		
																			
																			if "`indicador'" == "tasa_comercio" {	
																			
																				cap estpost tab comercio [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(pct)[1,2]
																				
																				estpost tab comercio if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "nivel_comercio" {	
																			
																				cap estpost tab comercio [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(b)[1,2]
																				
																				estpost tab comercio if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/								
																			
																			if "`indicador'" == "tasa_transporte" {	
																			
																				capture estpost tab transporte [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(pct)[1,2]
																				
																				estpost tab transporte if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "nivel_transporte" {	
																			
																				capture estpost tab transporte [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(b)[1,2]
																				
																				estpost tab transporte if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/								
																			
																			if "`indicador'" == "tasa_financiero" {	
																			
																				cap estpost tab financiero [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(pct)[1,2]
																				
																				estpost tab financiero if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "nivel_financiero" {	
																			
																				cap estpost tab financiero [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(b)[1,2]
																				
																				estpost tab financiero if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "tasa_servicios" {	
																			
																				cap estpost tab servicios [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(pct)[1,2]
																				
																				estpost tab servicios if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "nivel_servicios" {	
																			
																				capture estpost tab servicios [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(b)[1,2]
																				
																				estpost tab servicios if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/
																
																			if "`indicador'" == "tasa_profestecnico" {	
																			
																				cap estpost tab profestecnico [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(pct)[1,2]
																				
																				estpost tab profestecnico if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "nivel_profestecnico" {	
																			
																				cap estpost tab profestecnico [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(b)[1,2]
																				
																				estpost tab profestecnico if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "tasa_director" {	
																			
																				capture estpost tab director [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(pct)[1,2]
																				
																				estpost tab director if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "nivel_director" {	
																			
																				cap estpost tab director [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(b)[1,2]
																				
																				estpost tab director if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}				

																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "tasa_administrativo" {	
																			
																				capture estpost tab administrativo [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(pct)[1,2]
																				
																				estpost tab administrativo if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				} 
																				
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "nivel_administrativo" {	
																			
																				capture estpost tab administrativo [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(b)[1,2]
																				
																				estpost tab administrativo if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/								
																			
																			if "`indicador'" == "tasa_comerciantes" {	
																			
																				capture estpost tab comerciantes [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(pct)[1,2]
																				
																				estpost tab comerciantes if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "nivel_comerciantes" {	
																			
																				capture estpost tab comerciantes [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(b)[1,2]
																				
																				estpost tab comerciantes if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																			} /*cierro indicador*/							
																			
																			if "`indicador'" == "tasa_trabss" {	
																			
																				cap estpost tab trabss [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(pct)[1,2]
																				
																				estpost tab trabss if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "nivel_trabss" {	
																			
																				capture estpost tab trabss [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(b)[1,2]
																				
																				estpost tab trabss if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/			
																			
																			if "`indicador'" == "tasa_trabagricola" {	
																			
																				capture estpost tab trabagricola [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(pct)[1,2]
																				
																				estpost tab trabagricola if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "nivel_trabagricola" {	
																			
																				capture estpost tab trabagricola [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(b)[1,2]
																				
																				estpost tab trabagricola if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/								
																			
																			if "`indicador'" == "tasa_obreros" {	
																			
																				capture estpost tab obreros [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(pct)[1,2]
																				
																				estpost tab obreros if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "nivel_obreros" {	
																			
																				cap estpost tab obreros [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(b)[1,2]
																				
																				estpost tab obreros if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	

																			if "`indicador'" == "tasa_ffaa" {	
																			
																				cap estpost tab ffaa [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(pct)[1,2]
																				
																				estpost tab ffaa if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "nivel_ffaa" {	
																			
																				cap estpost tab ffaa [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(b)[1,2]
																				
																				estpost tab ffaa if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	

																			if "`indicador'" == "tasa_otrostrab" {	
																			
																				cap estpost tab otrostrab [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(pct)[1,2]
																				
																				estpost tab otrostrab if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "nivel_otrostrab" {	
																			
																				capture estpost tab otrostrab [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor=e(b)[1,2]
																				
																				estpost tab otrostrab if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "empleo_publico" {	
																			
																				cap estpost tab spublico_ci [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor= e(pct)[1,2]
																				
																				estpost tab spublico_ci if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "formalidad_2" {	
																			
																				cap estpost tab formal_ci [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor= e(pct)[1,2]
																				
																				tab formal_ci if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/
																			
																			if "`indicador'" == "formalidad_3" {	
																									
																				cap estpost tab formal_ci [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & categopri_ci==3
																				if _rc == 0 {
																				local valor= e(pct)[1,2]
																				
																				tab formal_ci if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & categopri_ci==3
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/
																			
																			if "`indicador'" == "formalidad_4" {	
																			
																				cap estpost tab formal_ci [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & categopri_ci==2
																				if _rc == 0 {
																				local valor= e(pct)[1,2]
																				
																				tab formal_ci if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & categopri_ci==2
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/
																			
																			if "`indicador'" == "ingreso_hor_prom" {	
																								
																				cap sum hwage_ppp [w=round(factor_ci)]	 if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				if _rc == 0 {
																				cap local valor = `r(mean)'												
																				
																				sum hwage_ppp if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																			} /*cierro indicador*/
																		} /*cierro niveles*/
																	
																			if "`indicador'" == "pensionista_65_mas" {	
																										
																				cap estpost tab pensiont_ci [w=round(factor_ci)] if `clase'==1 & `clase2' ==1 & age_65_mas==1
																				if _rc == 0 {
																				local valor= e(pct)[1,2]
																				
																				cap estpost tab pensiont_ci if `clase'==1 & `clase2' ==1 & age_65_mas==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("age_65_mas") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "num_pensionista_65_mas" {	
																			
																				cap sum age_65_mas [w=round(factor_ci)] if `clase'==1 & pensiont_ci==1 & `clase2' ==1
																				if _rc == 0 {
																				local valor = `r(sum)'

																				sum age_65_mas if `clase'==1 & pensiont_ci==1 & `clase2' ==1
																				local muestra = `r(sum)'

																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("age_65_mas") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/								
																			
																			if "`indicador'" == "pensionista_cont_65_mas" {	
																			
																				cap estpost tab pension_ci [w=round(factor_ci)] if `clase'==1 & `clase2' ==1 & age_65_mas==1
																				if _rc == 0 {
																				local valor= e(pct)[1,2]
																				
																				cap estpost tab pension_ci if `clase'==1 & `clase2' ==1 & age_65_mas==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("age_65_mas") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
																		
																			if "`indicador'" == "pensionista_nocont_65_mas" {	
																			
																				cap estpost tab pensionsub_ci [w=round(factor_ci)] if `clase'==1 & `clase2' ==1 & age_65_mas==1
																				if _rc == 0 {
																				local valor= e(pct)[1,2]
																				
																				cap estpost tab pensionsub_ci if `clase'==1 & `clase2' ==1 & age_65_mas==1
																				local muestra=e(b)[1,2]
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("age_65_mas") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "pensionista_ocup_65_mas" {	
																			
																				cap estpost tab pensiont_ci [w=round(factor_ci)] if `clase'==1 & `clase2' ==1 & age_65_mas==1 & condocup_ci==1
																				if _rc == 0 {
																				local valor= e(pct)[1,2]
																				
																				tab pensiont_ci if `clase'==1 & `clase2' ==1 & age_65_mas==1 & condocup_ci==1
																				local muestra=e(b)[1,2]
																												
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("age_65_mas") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
																																
																			if "`indicador'" == "y_pen_cont_ppp" {	
																										
																				capture sum ypen_ppp [w=round(factor_ci)] if `clase'==1 & ypen_ppp!=. & `clase2' ==1 & age_65_mas==1
																				if _rc == 0 {
																				cap local valor = `r(mean)'											
																				
																				sum ypen_ppp if `clase'==1 & ypen_ppp!=. & `clase2' ==1 & age_65_mas==1
																				cap local muestra = `r(N)'

																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("age_65_mas") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																			} /*cierro indicador*/
																			
																			if "`indicador'" == "y_pen_cont" {	
																			
																				capture sum ypen_ci [w=round(factor_ci)] if `clase'==1 & ypen_ci!=. & `clase2' ==1 & age_65_mas==1
																				if _rc == 0 {
																				cap local valor = `r(mean)'											
																				
																				sum ypen_ci if `clase'==1 & ypen_ci!=. & `clase2' ==1 & age_65_mas==1
																				cap local muestra = `r(N)'
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("age_65_mas") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
																			
																			if "`indicador'" == "y_pen_nocont" {	
																			
																				capture sum ypensub_ci [w=round(factor_ci)] if `clase'==1 & ypensub_ci!=. & `clase2' ==1 & age_65_mas==1
																				if _rc == 0 {
																				cap local valor = `r(mean)'											
																				
																				sum ypensub_ci if `clase'==1 & ypensub_ci!=. & `clase2' ==1 & age_65_mas==1
																				local muestra = `r(N)'
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("age_65_mas") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
																		
																			if "`indicador'" == "y_pen_total" {	
																			
																				capture sum ypent_ci [w=round(factor_ci)] if `clase'==1 & ypent_ci!=. & `clase2' ==1 & age_65_mas==1
																				if _rc == 0 {
																				cap local valor = `r(mean)'											
																				
																				sum ypent_ci if `clase'==1 & ypent_ci!=. & `clase2' ==1 & age_65_mas==1
																				local muestra = `r(N)'
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("age_65_mas") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																			} /*cierro indicador*/	
										*/
										
										
									} /* cierro clase3 */	
								}/*cierro clase2*/
							} /* cierro clase*/ 
					
				
				
				
							************************************************
							  global tema "pobreza"
							************************************************
							// Division: SPH
							// Authors: ...
							************************************************
								
								local clases 	Total Hombre Mujer Rural Urbano
								local clases2	Total Hombre Mujer
								local clases3	Total age_00_04 age_05_14 age_15_24 age_25_64 age_65_mas
								
								foreach clase1 of local clases {
									foreach clase2 of local clases2 {
										foreach clase3 of local clases3 {
											/* Parameters of current disaggregation levels, used by all commands */
											global current_slice `pais' `ano' `geografia_id' `clase1' `clase2' `clase3'
											noisily display "$tema: $current_slice"	
								
								
								/*
														/* Porcentaje poblacion que vive con menos de 3.1 USD diarios per capita*/
																if "`indicador'" == "pobreza31" {																						 
																 capture estpost tabulate poor31 [w=round(factor_ci)] if `clase'==1 & `clase2'==1 & `nivel'==1 & poor31!=. 
																 local valor= e(pct)[1,2]
																 if _rc == 0 {
																	
																 estpost tabulate poor31 if `clase'==1 & `clase2'==1 & `nivel'==1 & poor31!=.
																 local muestra=e(b)[1,2]	
															
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'")  ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'")  ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																							
																} /*cierro indicador*/		
																
																/* Porcentaje poblacion que vive con menos de 5 USD diarios per capita*/
																if "`indicador'" == "pobreza" {																						 
																 capture estpost tabulate poor [w=round(factor_ci)] if  `clase'==1 & `clase2'==1 & `nivel'==1 & poor!=.
																 local valor= e(pct)[1,2]
																 if _rc == 0 {
																	
																 estpost tabulate poor if `clase'==1 & `clase2'==1 & `nivel'==1 & poor!=.
																 local muestra=e(b)[1,2]	
															
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'")  ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'")  ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																	
																} /*cierro indicador*/
																
																/* Porcentaje de la población con ingresos entre 5 y 12.4 USD diarios per capita*/
																if "`indicador'" == "vulnerable" {                               
																
																capture estpost tabulate vulnerable [w=round(factor_ci)] if  `clase'==1 & `clase2'==1 & `nivel'==1 & vulnerable!=.
																 local valor= e(pct)[1,2]
																 if _rc == 0 {
																	
																 estpost tabulate vulnerable if `clase'==1 & `clase2'==1 & `nivel'==1 & vulnerable!=.
																 local muestra=e(b)[1,2]	
															
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'")  ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'")  ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																								
																} /*cierro indicador*/	
																
																/* Porcentaje de la población con ingresos entre 12.4 y 64 USD diarios per capita*/
																if "`indicador'" == "middle" {								
															
																 capture estpost tabulate middle [w=round(factor_ci)] if  `clase'==1 & `clase2'==1 & `nivel'==1 & middle!=.
																 local valor= e(pct)[1,2]
																 if _rc == 0 {
																	
																 estpost tabulate middle if `clase'==1 & `clase2'==1 & `nivel'==1 & middle!=.
																 local muestra=e(b)[1,2]	
															
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'")  ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'")  ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																									
																} /*cierro indicador*/	
																
																/* Porcentaje de la población con ingresos mayores 64 USD diarios per capita*/
																if "`indicador'" == "rich" {							
																
																 capture estpost tabulate rich [w=round(factor_ci)] if  `clase'==1 & `clase2'==1 & `nivel'==1 & rich!=.
																 local valor= e(pct)[1,2]
																 if _rc == 0 {
																	
																 estpost tabulate rich if `clase'==1 & `clase2'==1 & `nivel'==1 & rich!=.
																 local muestra=e(b)[1,2]	
															
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'")  ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'")  ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																					
																} /*cierro indicador*/	
							*/
								
								
							
				
										} /* cierro clase3 */	
									}/*cierro clase2*/
								} /* cierro clase*/ 
				
								local clases Total Urbano Rural
								local clases2 Total
								local clases3 Total 
								
								foreach clase1 of local clases {
									foreach clase2 of local clases2 {
										foreach clase3 of local clases3 {
											/* Parameters of current disaggregation levels, used by all commands */
													global current_slice `pais' `ano' `geografia_id' `clase1' `clase2' `clase3'
													noisily display "$tema: $current_slice"	
													
													
				/*
													
														/* Coeficiente de Gini para el ingreso per cápita del hogar*/			
														if "`indicador'" == "ginihh" {
														
														capture sum ginihh if `clase'==1 & ginihh!=.
														capture local valor= `r(mean)'
														if _rc == 0 {
															
														capture sum ginihh if `clase'==1 & ginihh!=. 
														capture local muestra= `r(N)'

															
																		post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																		}
															
																	   else {
															
																	   post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	   }
															
														} /*cierro indicador*/
														
														/* Coeficiente de Gini para salarios por hora*/
														if "`indicador'" == "gini" {
														
														capture sum gini if `clase'==1 & gini!=.
														capture local valor= `r(mean)'
														if _rc == 0 {
															
														capture sum gini if `clase'==1 & gini!=. 
														capture local muestra= `r(N)'

															
																	  post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	  }
															
																	  else {
															
																	  post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	  }
															
														} /*cierro indicador*/
														
														  /* Coeficiente de theil para el ingreso per cápita del hogar*/
														  if "`indicador'" == "theilhh" {
														
														capture sum theilhh if `clase'==1 & theilhh!=.
														capture local valor= `r(mean)'
														if _rc == 0 {
															
														capture sum theilhh if `clase'==1 & theilhh!=. 
														capture local muestra= `r(N)'

															
																	  post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	  }
															
																	  else {
															
																	  post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	  }
														} /*cierro indicador*/
														
														/* Coeficiente de theil para salarios por hora*/
														 if "`indicador'" == "theil" {
														
														capture sum theil if `clase'==1 & theil!=.
														capture local valor= `r(mean)'
														if _rc == 0 {
															
														capture sum theil if `clase'==1 & theil!=. 
														capture local muestra= `r(N)'

															
																	  post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	  }
															
																	  else {
															
																	  post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																	  }
														} /*cierro indicador*/
														
														/* Porcentaje del ingreso laboral del hogar contribuido por las mujeres */
														if "`indicador'" == "ylmfem_ch" {
								
														capture sum shareylmfem_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1 & shareylmfem_ch!=. 
														capture local valor= `r(mean)'
														if _rc == 0 {
															
														capture sum shareylmfem_ch if jefe_ci==1 & `clase'==1 & shareylmfem_ch!=. 
														capture local muestra= `r(N)'	

														
																		
																		post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																		}
																		
																		else {
																		
																		post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																		}
																		
														} /* cierro indicador*/
														} /*cierro clase*/	
														*/
														
														} /* cierro clase3 */	
									}/*cierro clase2*/
								} /* cierro clase*/ 
														
														
								
								local clases Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
								local clases2 Total
								local clases3 Total
			
								foreach clase1 of local clases {
									foreach clase2 of local clases2 {
										foreach clase3 of local clases3 {
											/* Parameters of current disaggregation levels, used by all commands */
													global current_slice `pais' `ano' `geografia_id' `clase1' `clase2' `clase3'
													noisily display "$tema: $current_slice"	
													
													
													/* Porcentaje de hogares que reciben remesas del exterior */
													scl_pct ///
														indexrem indexrem "1" if jefe_ci==1 & indexrem!=.
													
								/*
																  
																	if "`indicador'" == "indexrem" {
											
																		capture estpost tabulate indexrem [w=round(factor_ci)] if jefe_ci==1 & `clase'==1  & indexrem!=.
																		local valor= e(pct)[1,2]
																		if _rc == 0 {
																		
																		estpost tabulate indexrem if jefe_ci==1 & `clase'==1  & indexrem!=.
																		local muestra=e(b)[1,2]	

																	
																					
																					post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																					}
																					
																					else {
																					
																					post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																					}
																	} /* cierro indicador*/
							*/
							
							
												} /* cierro clase3 */	
										}/*cierro clase2*/
								} /* cierro clase*/ 					
			
		
								************************************************
								  global tema "vivienda"
								************************************************
								// Division: SCL
								// Authors: ...
								************************************************
								
								local clases 	Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
								local clases2 	Total Rural Urbano
								local clases3	Total
								
								foreach clase1 of local clases {
									foreach clase2 of local clases2 {
										foreach clase3 of local clases3 {
											/* Parameters of current disaggregation levels, used by all commands */
											global current_slice `pais' `ano' `geografia_id' `clase1' `clase2' `clase3'
											noisily display "$tema: $current_slice"	
								
					
							/*
																/* % de hogares con servicio de agua de acueducto*/
																if "`indicador'" == "aguared_ch" {
										
																				
																	capture estpost tabulate aguared_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1  & `clase2'==1 & aguared_ch!=.
																	local valor= e(pct)[1,2]
																	if _rc == 0 {
																	
																	estpost tabulate aguared_ch if jefe_ci==1 & `clase'==1  & `clase2'==1 & aguared_ch!=.
																	local muestra=e(b)[1,2]	

																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																																
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																							
																				
																} /* cierro indicador*/	
																
																/* % de hogares con acceso a servicios de saneamiento mejorados*/
																if "`indicador'" == "des2_ch" {
										
																	capture estpost tabulate des2_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1 & `clase2'==1  & des2_ch!=.
																	local valor= e(pct)[1,2]
																	if _rc == 0 {
																	
																	estpost tabulate des2_ch if jefe_ci==1 & `clase'==1 & `clase2'==1  & des2_ch!=.
																	local muestra=e(b)[1,2]	

																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																																
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																					
																				
																} /* cierro indicador*/	
																
																/* % de hogares con electricidad */
																if "`indicador'" == "luz_ch" {
										
																					
																	capture estpost tabulate luz_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1 & `clase2'==1 & luz_ch!=. 
																	local valor= e(pct)[1,2]
																	if _rc == 0 {
																	
																	estpost tabulate luz_ch if jefe_ci==1 & `clase'==1 & `clase2'==1 & luz_ch!=.
																	local muestra=e(b)[1,2]	

																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																																
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																} /* cierro indicador*/	
																
																/* % hogares con pisos de tierra */
																if "`indicador'" == "dirtf_ch" {
										
																	capture estpost tabulate dirtf_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1 & `clase2'==1 & dirtf_ch!=.
																	local valor= e(pct)[1,2]
																	if _rc == 0 {
																	
																	estpost tabulate dirtf_ch if jefe_ci==1 & `clase'==1 & `clase2'==1 & dirtf_ch!=.
																	local muestra=e(b)[1,2]	

																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																																
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																} /* cierro indicador*/
																
																/* % de hogares con refrigerador */
																if "`indicador'" == "refrig_ch" {
										

																	capture estpost tabulate freezer_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1 & `clase2'==1 & freezer_ch!=.
																	local valor= e(pct)[1,2]
																	if _rc == 0 {
																	
																	estpost tabulate freezer_ch if jefe_ci==1 & `clase'==1 & `clase2'==1 & freezer_ch!=.
																	local muestra=e(b)[1,2]	

																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																																
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																} /* cierro indicador*/
																
																/* % de hogares con carro particular */
																if "`indicador'" == "auto_ch" {
										
																	capture estpost tabulate auto_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1  & `clase2'==1 & auto_ch!=.
																	local valor= e(pct)[1,2]
																	if _rc == 0 {
																	
																	estpost tabulate auto_ch  if jefe_ci==1 & `clase'==1  & `clase2'==1 & auto_ch!=.
																	local muestra=e(b)[1,2]	

																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																																
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																} /* cierro indicador*/
																
																/* % de hogares con acceso a internet */
																if "`indicador'" == "internet_ch" {
										
																	capture estpost tabulate internet_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1  & `clase2'==1 & internet_ch!=.
																	local valor= e(pct)[1,2]
																	if _rc == 0 {
																	
																	estpost tabulate internet_ch if jefe_ci==1 & `clase'==1  & `clase2'==1 & internet_ch!=.
																	local muestra=e(b)[1,2]	

																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																																
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																} /* cierro indicador*/
																
																/* % de hogares con teléfono celular*/
																if "`indicador'" == "cel_ch" {
										
																	capture estpost tabulate cel_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1 & `clase2'==1 & cel_ch!=.
																	local valor= e(pct)[1,2]
																	if _rc == 0 {
																	
																	estpost tabulate cel_ch if jefe_ci==1 & `clase'==1 & `clase2'==1 & cel_ch!=.
																	local muestra=e(b)[1,2]	

																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																																
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																} /* cierro indicador*/
																/* % de hogares con techos de materiales no permanentes*/
																if "`indicador'" == "techonp_ch" {
										
																	capture estpost tabulate techonp_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1  & `clase2'==1 & techonp_ch!=.
																	local valor= e(pct)[1,2]
																	if _rc == 0 {
																	
																	estpost tabulate techonp_ch if jefe_ci==1 & `clase'==1  & `clase2'==1 & techonp_ch!=.
																	local muestra=e(b)[1,2]	

																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																																
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																} /* cierro indicador*/
																
																/* % de hogares con paredes de materiales no permanentes*/
																if "`indicador'" == "parednp_ch" {
										
																	capture estpost tabulate parednp_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1  & `clase2'==1 & parednp_ch!=.
																	local valor= e(pct)[1,2]
																	if _rc == 0 {
																	
																	estpost tabulate parednp_ch if jefe_ci==1 & `clase'==1  & `clase2'==1 & parednp_ch!=.
																	local muestra=e(b)[1,2]	

																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																																
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																} /* cierro indicador*/
																
																/* Número de miembros por cuarto*/
																if "`indicador'" == "hacinamiento_ch" {
										
																capture sum hacinamiento_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1 & `clase2'==1 & hacinamiento_ch!=. 
																capture local valor= `r(mean)'
																if _rc == 0 {
																	
																capture  sum hacinamiento_ch if jefe_ci==1 & `clase'==1 & `clase2'==1 & hacinamiento_ch!=. 
																capture local muestra= `r(N)'
																														
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																} /* cierro indicador*/
																
																/*% de hogares con estatus residencial estable */
																if "`indicador'" == "estable_ch" {
										
																	capture estpost tabulate estable_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1 & `clase2'==1 & estable_ch!=. 
																	local valor= e(pct)[1,2]
																	if _rc == 0 {
																	
																	estpost tabulate estable_ch if jefe_ci==1 & `clase'==1 & `clase2'==1 & estable_ch!=. 
																	local muestra=e(b)[1,2]	

																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																																
																				else {
																				
																				post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
																				}
																				
																} /* cierro indicador*/
														*/
																
																
											}/*cierro clases3*/		
										} /*cierro clases2*/
								} /*cierro clases*/

								
																									
								
								
								
								************************************************
								  global tema "diversidad"
								************************************************
								// Division: GDI
								// Authors: Nathalia Maya, Maria Antonella Pereira, Cesar Lins de Oliveira
								************************************************
								local clases 	Total Hombre Mujer
								local clases2 	Total Rural Urbano
								local clases3	Total
								
								foreach clase1 of local clases {
									foreach clase2 of local clases2 {
										foreach clase3 of local clases3 {
											/* Parameters of current disaggregation levels, used by all commands */
											global current_slice `pais' `ano' `geografia_id' `clase1' `clase2' `clase3'
											noisily display "$tema: $current_slice"	
								
												/* Porcentaje población afrodescendiente */
												scl_pct ///
													pafro_ci raza_ci "Afro-descendiente"
												
												
												
												
											}/*cierro clases3*/		
										} /*cierro clases2*/
								} /*cierro clases*/
								
								
								************************************************
								  global tema "migracion"
								************************************************
								// Division: MIG
								// Authors: Fernando Morales Velandia
								************************************************
								local clases 	Total Hombre Mujer
								local clases2 	Total Rural Urbano
								local clases3	Total
								
								foreach clase1 of local clases {
									foreach clase2 of local clases2 {
										foreach clase3 of local clases3 {
											/* Parameters of current disaggregation levels, used by all commands */
											global current_slice `pais' `ano' `geografia_id' `clase1' `clase2' `clase3'
											noisily display "$tema: $current_slice"	
											
								
											/* Indicadores Migración */
								
								
											}/*cierro clases3*/		
										} /*cierro clases2*/
								} /*cierro clases*/
								
								
								
	
	

	
							
					
					

				
				
						
					*} /* cierro rondas */		
				*} /* cierro encuestas */
			} /* cierro anos */
		} /* cierro paises */
} /* cierro quietly */
 

 
postclose `ptablas'

use `tablas', clear
* destring valor muestra, replace
recode valor 0=.
* recode muestra 0=.
save `tablas', replace 



/*====================================================================
                        2: Save and Export results
====================================================================*/



* guardo el archivo temporal
* (this file will be ignored by GitHub)
save "${output}\Indicadores_SCL.dta", replace

* Variables de formato 

***** include "${input}\var_formato.do"
***** order tiempo tiempo_id pais_id geografia_id clase clase_id clase2 clase2_id nivel nivel_id tema indicador tipo valor muestra


/*
export excel using "${output}\Indicadores_SCL.xlsx", first(var) sheet(Total_results) sheetreplace
export delimited using  "${output}\indicadores_encuestas_hogares_scl.csv", replace

unicode convertfile "${output}\indicadores_encuestas_hogares_scl.csv" "${output}\indicadores_encuestas_hogares_scl_converted.csv", dstencoding(latin1) replace */

*carpeta tmp

***** export delimited using  "${covidtmp}\indicadores_encuestas_hogares_scl.csv", replace
***** unicode convertfile "${covidtmp}\indicadores_encuestas_hogares_scl.csv" "${output}\indicadores_encuestas_hogares_scl_converted.csv", dstencoding(latin1) replace 
***** save "${covidtmp}\indicadores_encuestas_hogares_scl.dta", replace


/*


	g 		division = "soc" if tema == "demografia" | tema == "vivienda" | tema == "pobreza" 
	replace division = "lmk" if tema == "laboral" 													 
	replace division = "edu" if tema == "educacion" 
	replace division = "gdi" if tema == "inclusion"
	replace division = "mig" if tema == "migracion"

local divisiones soc lmk edu gdi mig											 

foreach div of local divisiones { 
	        
			preserve
			
			keep if (division == "`div'")
			drop division
		
			export delimited using "${output}\\indicadores_encuestas_hogares_`div'.csv", replace
			sleep 1000
			restore
						
} 
 */
 
 		
exit
/* End of do-file */



