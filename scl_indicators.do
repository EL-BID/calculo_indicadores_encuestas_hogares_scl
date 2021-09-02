/*====================================================================
                      Social Sector - SCL
----------------------------------------------------------------------
Project:       Armonizacion de Encuestas de Hogares
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
INSTRUCTIONS
----------------------------------------------------------------------

This code creates a program called "scl_indicators", which can be
used to calculate all the indicators for a single country/year.
The program receives two arguments: country (ISO Alpha-3) and year.

Before running this code, you need to set two global variables: "gitFolder"
and "source". The first points to the folder where git repositories are
stored in your computer. The second points to the folder where the
harmonized databases are found. Since these usually differ for each
user, these variables have a different value to each user.

To avoid having to create these variables again every time, the program
looks for a specific do-File in your PERSONAL folder and runs it. You
can create both global variables in that do-File.
The do-File should be named after your username and system, following the
pattern "username_system.doh". Replace "username" by the value of
the macro `=c(username)' and "system" by the value of the macho `=c(os)'.
Save this file into your PERSONAL folder (run the command "sysdir" to
find out where the PERSONAL folder is located in your machine).
E.g., The file for CLINS is saved as C:\Users\clins\ado\personal\CLINS_Windows.doh

Please, save a copy of the above file in the github repository,
in the "Config" folder.


Global Variables

- $gitFolder: variable pointing to the local path of your github folder
  (this global should be set in your config file at
  "PERSONAL/username_system.do").   
  
- $source: path to the folder where the harmonized data files
  are located (this global should be set in your config file at
  "PERSONAL/username_system.do".


- $output: name of the database used by the postfile command. This value
  is set automatically.
  
- $tema: current theme of the indicators that are being calculated.
  This variable must be set each time when the theme is changed.
  For example, set global tema "demogracia" on starting calculating 
  demographic indicators, next set global tema "educacion" when
  starting education indicators and so on.
  
- $current_slice: define the disaggregation being applied for the 
  indicators being calculated. At the start of the disaggregation
  loop, set this variable as follows
  global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
======================================================================*/
version 16.0


clear all

*cap ssc install estout
*cap ssc install inequal7
set max_memory 200g, permanently
set segmentsize  400m, permanently
set maxvar 120000, perm


qui {


capture confirm file "`=c(sysdir_personal)'/`=c(username)'_`=c(os)'.doh"
if _rc>0 {
  noi display ""
  noi display as txt "-------------------------------------------------------------------------------------------------------------"
  noi display as txt "    SCL DATA ECOSYSTEM WORKING GROUP"
  noi display as txt "-------------------------------------------------------------------------------------------------------------"
  noi display ""
  noi display as error " ** ATENCIÓN: el archivo de configuración no existe. Se necesita crearlo."
  noi display as txt " --> `=c(sysdir_personal)'/`=c(username)'_`=c(os)'.doh"
  noi display ""
  error _rc
}


*****   Configure paths in this user's computer    ************
qui include "`=c(sysdir_personal)'/`=c(username)'_`=c(os)'.doh"
noi display as txt "Configuraciones de `=c(username)'..."
noi display as txt "Carpeta Git: $gitFolder"
noi display as txt "Carpeta de datos: $source"

*****   Custom commands for calculating indicators ************
qui include "${gitFolder}/calculo_indicadores_encuestas_hogares_scl/scl_programs.doh"
***************************************************************


/* You can copy the list of country and years below to loop through countries/years.
 * This is provided only for convenience and is not used in the code.
 * global paises  ARG BHS BOL BRB BRA BLZ CHL COL CRI ECU SLV GTM GUY HTI HND JAM MEX NIC PAN PRY PER DOM SUR TTO URY VEN
 * local anos  2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020
 */


/***********************************
 scl_indicators PAIS AÑO
 -----------------------------------
 This is a program to compute all
 indicators for the given country/year
 (country given as alpha3 ISO code).
************************************/
capture program drop scl_indicators                                                        
program scl_indicators
  args pais ano
  
    
/*====================================================================
                        0: Program set up
====================================================================*/
    clear
	set more off 
	

	* Github Repository (local path)
	local mydir "${gitFolder}/calculo_indicadores_encuestas_hogares_scl"

	* Directory containing do-Files used as input
	global input	"`mydir'/Input"
	* Directory where to save the output .dta
	global out 	 "`mydir'/Output"

	local geografia_id country
		
/*====================================================================
                        1: Open dataset and Generate indicators
====================================================================*/
  qui {
    noisily display "Empezando calculos... `pais' `ano'"
  
    tempfile tablas_`pais'_`ano'
	tempname ptablas_`pais'_`ano'
	global output `ptablas_`pais'_`ano''

	** Este postfile da estructura a la base:
	postfile $output str4 tiempo_id str3 pais_id str25(fuente geografia_id sexo area quintil_ingreso nivel_educativo grupo_etario etnicidad tema indicador) str35 description valor se cv sample using `tablas_`pais'_`ano'', replace

	* En este dofile de encuentra el diccionario de encuestas y rondas de la región
	include "${input}/Directorio HS LAC.do" 
	* Encuentra el archivo para este país/año
	cap use "${source}/`pais'//$encuestas/data_arm//`pais'_`ano'${rondas}_BID.dta" , clear		
	
	if _rc == 0 { 
		//* Si esta base de datos existe, entonces haga: */
		noisily display as txt "Calculando //`pais'//$encuestas/data_arm//`pais'_`ano'$rondas_BID.dta..."	
		
		* setting up quality var
			cap sum upm_ci
			if _rc==0{
			
				if `r(N)' > 0 {
					cap sum estrato_ci
					if `r(N)' > 0 {
						svyset [w=factor_ch], psu(upm_ci) strata(estrato_ci)
					}
					if `r(N)' == 0{
						svyset [w=factor_ch], psu(upm_ci) 
					}
				}
				cap sum upm_ci
				if `r(N)' == 0 {
						svyset [w=factor_ch]
				}
			}
			if _rc ~= 0 {
						svyset [w=factor_ch]
			}
						
						
			**** Desagregaciones *************			
			cap {
				gen No_aplica  =  1
				gen byte Total  =  1
				gen Primaria  =  1
				gen Secundaria  =  1
				gen Superior  =  1
				gen Prescolar  =  1
				gen Hombre = (sexo_ci==1)  
				gen Mujer  = (sexo_ci==2)
				gen Urbano = (zona_c==1)
				gen Rural  = (zona_c==0)
				gen Indi = (afroind_ci==1)
				gen Afro = (afroind_ci==2)
				gen Otro = (afroind_ci==3)
				gen HogarIndi =(afroind_ch==1)
				gen HogarAfro = (afroind_ch==2) 
				gen HogarOtro = (afroind_ch==3)
			
				
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
					
			} //end capture
			
		* Variables intermedias 
		* Educación: niveles y edades teóricas cutomizadas  
			include "${input}/var_tmp_EDU.do"
		* Mercado laboral 
			include "${input}/var_tmp_LMK.do"
		* Pobreza, vivienda, demograficas
			include "${input}/var_tmp_SOC.do"
		* Inclusion
			include "${input}/var_tmp_GDI.do"	
		* Migración
			include "${input}/var_tmp_MIG.do"	
	}
	else {
		/* IN the case the dta file DOES NOT EXIST for this country/year, we are going
		  to execute the rest of the code ANYWAY. The reason is: regardless if the 
		  file exists or not, all indicators will be generated in the same way, 
		  but with a "missing value" if the file does not exist. The programs are
		  already capturing it and will generate the missing values accordingly
		  whenever the indicator cannot be calculated.
		  */
		  noisily display as error "${source}/`pais'//$encuestas/data_arm//`pais'_`ano'${rondas}_BID.dta - no se encontró el archivo. Generando missing values..."
		  
		  /* use an empty file which contains all variables */
		  use "${input}/template.dta", clear
	}
	
	
	
*****************************************************************************************************************************************
					* 1.2: Indicators for each topic		
*****************************************************************************************************************************************
				

		************************************************
						  global tema "demografia"
						************************************************
						// Division: SCL
						// Authors: Daniela Zuluaga
						************************************************
					
						
						local areas Total Rural Urbano  
						local quintil_ingresos Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 
						local etnicidades Total HogarIndi HogarAfro HogarOtro
		
						foreach quintil_ingreso of local quintil_ingresos {
							foreach area of local areas {	
								foreach etnicidad of local etnicidades {
							
								local nivel_educativo No_aplica // formerly called "nivel". If "no_aplica", use Total.
								local sexo No_aplica
								local grupo_etario No_aplica
								
								
								/* Parameters of current disaggregation levels, used by all commands */
								global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
								noisily display "$tema: $current_slice"
								
								//======== CALCULATE INDICATORS ================================================
								
									
								/* Porcentaje de hogares con jefatura femenina */
								scl_pct ///
								jefa_ch jefa_ch "1" if jefa_ch!=. & sexo_ci!=.												
										
								/* Porcentaje de hogares con jefatura económica femenina */
								scl_pct ///
								jefaecon_ch hhfem_ch "1" if hhfem_ch!=. & sexo_ci!=.											
										
								/* Porcentaje de población femenina*/
								scl_pct ///
								pobfem_ci pobfem_ci "1" if pobfem_ci!=. 
																						
								/* Porcentaje de hogares con al menos un miembro de 0-5 años*/
								scl_pct ///
								miembro6_ch miembro6_ch "1" if miembro6_ch !=. 
												
								* Porcentaje de hogares con al menos un miembro entre 6-16 años*
								scl_pct ///
								miembro6y16_ch miembro6y16_ch "1" if  miembro6y16_ch!=.
																													
								* Porcentaje de hogares con al menos un miembro de 65 años o más*
								cap scl_pct ///
								miembro65_ch miembro65_ch "1" 
												
								* Porcentaje de hogares unipersonales*
								scl_pct ///
								unip_ch unip_ch "1" 
																									
								* Porcentaje de hogares nucleares*
								scl_pct ///
								nucl_ch nucl_ch "1" 
																
								* Porcentaje de hogares ampliados*
						        scl_pct ///
								ampl_ch ampl_ch "1" 
																																
								* Porcentaje de hogares compuestos*
								scl_pct ///
								comp_ch comp_ch "1" 
																	
								* Porcentaje de hogares corresidentes*
							    scl_pct ///
								corres_ch corres_ch "1" 				

								*Razón de dependencia*
								scl_mean ///
								depen_ch depen_ch if jefe_ci==1 & depen_ch!=.				
										
								* Número promedio de miembros del hogar*
								scl_mean ///
								tamh_ch nmiembros_ch if jefe_ci==1 & nmiembros_ch!=. 
																
								* Porcentaje de población menor de 18 años*
								scl_pct ///
							    pob18_ci pob18_ci "1" if pob18_ci!=.
																									
								* Porcentaje de población de 65+ años*
								scl_pct ///
								pob65_ci pob65_ci "1" if pob65_ci!=.
																			
								* Porcentaje de individuos en union formal o informal*
								scl_pct ///
								union_ci union_ci "1" if union_ci!=.
																								
								* Edad mediana de la población en años *
								scl_median ///
								pobedad_ci edad_ci if edad_ci!=. 
								
								
									}/*cierro etnicidad*/	
								}/*cierro area*/		
							} /*cierro quintil*/
							
							local quintil_ingresos Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 
							local etnicidades Total Indi Afro Otro	
							
							foreach quintil_ingreso of local quintil_ingresos {
								foreach etnicidad of local etnicidades {
							
								local area No_aplica
								local nivel_educativo No_aplica							
								local sexo No_aplica
								local grupo_etario No_aplica
								
								
								
								/* Parameters of current disaggregation levels, used by all commands */
								global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
								noisily display "$tema: $current_slice"	
										
								//======== CALCULATE INDICATORS ================================================
								
								/* Porcentaje de población que reside en zonas urbanas*/
								scl_pct ///
								urbano_ci urbano_ci 1 if urbano_ci!=. 
								
								} /*cierro etnicidad*/		
							} /*cierro clase*/			    
											
			
											
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
										
										local nivel_educativos Prescolar Primaria Secundaria Superior
								
										foreach nivel_educativo of local nivel_educativos {								
										local grupo_etario No_aplica
									
										/* Parameters of current disaggregation levels, used by all commands */
										global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
										noisily display "$tema: $current_slice"

										//======== CALCULATE INDICATORS ================================================
										local sfix ""
										if `"`nivel_educativo'"'=="Prescolar"  local sfix pres
										else if `"`nivel_educativo'"'=="Primaria"   local sfix prim
										else if `"`nivel_educativo'"'=="Secundaria" local sfix seco
										else if `"`nivel_educativo'"'=="Superior"   local sfix tert
										
									
									
						 * Tasa asistencia Bruta  
											
										
										//the code for Prescolar uses a different program,
										// because the "if" condition for the numerator is different
										// of that of the denominator
												
											scl_ratio ///
												tasa_bruta_asis asis_`sfix' age_`sfix' & asiste_ci!=.
											
			
			
						 * Tasa asistencia Neta				
										// numerator and denominator				
						 
											scl_ratio /// 
												tasa_neta_asis asis_net_`sfix' age_`sfix' & asiste_ci!=.						
								    													
															
															
									} /* cierro nivel educativo */
											
										* Años_Escolaridad y Años_Escuela			
										
									local nivel_educativos anos_0 anos_1_5 anos_6 anos_7_11 anos_12 anos_13_o_mas
									
									foreach nivel_educativo of local nivel_educativos {
								
									cap svy:proportion `nivel_educativo' if age_25_mas==1 & `sexo'==1 & `area'==1 & `quintil_ingreso'==1 & `grupo_etario'==1 & `etnicidad'==1 
									if _rc == 0 {
										mat valores=r(table)
										local valor = valores[1,colnumb(valores,`"1.`nivel_educativo'"')]*100
	
										estat cv
										mat error_standar=r(se)
										local se = error_standar[1,colnumb(error_standar,`"1.`nivel_educativo'"')]*100
	
										mat cv=r(cv)
										local cv = cv[1,colnumb(cv,`"1.`nivel_educativo'"')]
	
										estat size
										mat muestra=r(_N)
										local muestra = muestra[1,1]
										di `muestra'
  	
										post $output ("`ano'") ("`pais'") ("`pais'-$encuestas") ("`geografia_id'") ("`sexo'") ("`area'") ("`quintil_ingreso'") ("`nivel_educativo'") ("`grupo_etario'") ("`etnicidad'") ("$tema") ("Anos_Escolaridad_25_mas") (`"sum of `indvar'"') (`valor') (`se') (`cv') (`muestra')
	
										}
									if _rc != 0 {
   /* generate a line with missing value */
										post $output ("`ano'") ("`pais'") ("`pais'-$encuestas") ("`geografia_id'") ("`sexo'") ("`area'") ("`quintil_ingreso'") ("`nivel_educativo'") ("`grupo_etario'") ("`etnicidad'") ("$tema") ("Anos_Escolaridad_25_mas") (`"sum of `indvar'"') (.) (.) (.) (.)
										}
														
													
										} /* cierro nivel educativo 3 */
										
									local grupo_etarios age_4_5 age_6_11 age_12_14 age_15_17 age_18_23
									
									foreach grupo_etario of local grupo_etarios {								
									local nivel_educativo No_aplica
											
						* Parameters of current disaggregation levels, used by all commands 
								global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
								noisily display "$tema: $current_slice"

											
												
						* Tasa asistencia grupo etario *
									scl_pct ///
									tasa_asis_edad asiste_ci "1"
																																				
						* Tasa No Asistencia grupo etario *
									scl_pct ///
									tasa_no_asis_edad asiste_ci "0"
									 
													
									} /*cierro grupo etario */
									
						* Ninis_2	
								
									local grupo_etarios age_15_24 age_15_29
									
									foreach grupo_etario of local grupo_etarios {
									local nivel_educativo No_aplica
									
										global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
										noisily display "$tema: $current_slice"
											
										scl_pct ///
										Ninis_2 nini "1" & edad_ci !=.
										
										} /*cierro grupo_etario */
										
								
						* Tasa_terminacion_c	
						
									local nivel_educativos Primaria Secundaria 
								
									foreach nivel_educativo of local nivel_educativos {								
									local grupo_etario No_aplica
									
										/* Parameters of current disaggregation levels, used by all commands */
										global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
										noisily display "$tema: $current_slice"
										
										
										
										local sfix ""
										    
											 if `"`nivel_educativo'"'=="Primaria"   local sfix primaria
										else if `"`nivel_educativo'"'=="Secundaria" local sfix secundaria
										
										local agetermfix ""
										    
										     if `"`nivel_educativo'"'=="Primaria"   local agetermfix p_c
										else if `"`nivel_educativo'"'=="Secundaria" local agetermfix s_c

										
										// numerator and denominator
				
						 
										scl_ratio ///
											tasa_terminacion_c t_cond_`sfix' age_term_`agetermfix' 		
									
										
										} /*cierro clases3 */
										
								
											
						 * Tasa de abandono escolar temprano "Leavers"
											
									local grupo_etarios age_18_24 
								
									foreach grupo_etario of local grupo_etarios {								
									local nivel_educativo No_aplica
									
										/* Parameters of current disaggregation levels, used by all commands */
										global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
										noisily display "$tema: $current_slice"

										
										/* Tasa asistencia Bruta  */
										scl_pct ///
											leavers leavers "1" if edad_ci !=.
										
										} /*cierro clases3 */	
										
									
												
						* Tasa de sobreedad  								
										
									local nivel_educativos Primaria 
								
									foreach nivel_educativo of local nivel_educativos {								
									local grupo_etario No_aplica
									
										/* Parameters of current disaggregation levels, used by all commands */
										global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
										noisily display "$tema: $current_slice"
									
										/* Tasa sobreedad */										
										// numerator and denominator				
						 
										scl_ratio ///
										tasa_sobre_edad age_prim_sobre asis_prim_c 		
										
										
									} /*cierro clases3 */	
									
									
									} /*cierro etnicidad*/	
								}/*cierro quintil*/
							} /* cierro area */
						}	/* cierro sexo */			
				
										
					
					
								***************************************************
								  global tema "laboral"
								***************************************************
								// Division: LMK
								// Authors: Alvaro Altamirano y Stephanie González
								***************************************************			
							
								local sexos Total Hombre Mujer 
								local area Total Rural Urbano
								local grupo_etarios Total age_15_24 age_15_29 age_15_64 age_25_64 age_65_mas 
								local quintil_ingresos Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 
								local etnicidades Total Indi Afro Otro
							
								foreach sexo of local sexos {
									foreach area of local areas {
										foreach quintil_ingreso of local quintil_ingresos {
											foreach etnicidad of local etnicidades {	
												foreach grupo_etario of local grupo_etarios {
											
											
											local nivel_educativo No_aplica
										
										
											/* Parameters of current disaggregation levels, used by all commands */
											global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
											noisily display "$tema: $current_slice"	

											//======== CALCULATE INDICATORS ================================================
												
											scl_pct ///
												tasa_ocupacion condocup_ci "1" if pet==1
										
											scl_pct ///
												tasa_desocupacion condocup_ci "2" if pea==1
										
											scl_ratio ///
												tasa_participacion pea pet
										
											scl_pct ///
												ocup_suf_salario liv_wage "1" if liv_wage!=. & condocup_ci==1
										
											scl_mean ///
												ingreso_mens_prom ylab_ppp if condocup_ci==1 & ylab_ppp!=.

											scl_mean ///
												ingreso_hor_prom_ppp hwage_ppp if condocup_ci==1 & hwage_ppp!=.
					
											scl_mean ///
												horas_trabajadas horastot_ci if condocup_ci==1 & horastot_ci!=.

											scl_mean ///
												dura_desempleo durades_ci if condocup_ci==2 & durades_ci!=.
																
											scl_mean ///
												salminmes_ppp salmm_ppp if condocup_ci==1 & salmm_ppp!=.

											scl_pct ///
												sal_menor_salmin menorwmin "1" if condocup_ci==1											

											scl_mean ///
												salmin_hora hsmin_ppp if condocup_ci==1 & hsmin_ppp!=.

											scl_mean ///
												salmin_mes salmm_ci if condocup_ci==1 & salmm_ci!=.

											scl_pct ///
												tasa_asalariados asalariado "1" if condocup_ci==1																	
											
											scl_pct ///
												tasa_independientes ctapropia "1" if condocup_ci==1																	

											scl_pct ///
												tasa_patrones patron "1" if condocup_ci==1																	

											scl_pct ///
												tasa_sinremuneracion sinremuner "1" if condocup_ci==1																	
											
											scl_pct ///
												subempleo subemp_ci "1" if condocup_ci==1																	
											
											scl_mean ///
												inglaboral_ppp_formales ylmpri_ppp if condocup_ci==1 & formal_ci==1
												
											scl_mean ///
												inglaboral_ppp_informales ylmpri_ppp if condocup_ci==1 & formal_ci==0

											scl_mean ///
												inglaboral_formales ylmpri_ci if condocup_ci==1 & formal_ci==1

											scl_mean ///
												inglaboral_informales ylmpri_ci if condocup_ci==1 & formal_ci==0
												
											scl_nivel ///
												nivel_asalariados asalariado 1 if condocup_ci==1
			
											scl_nivel ///
												nivel_independientes ctapropia 1 if condocup_ci==1
												
											scl_nivel ///
												nivel_patrones patron 1 if condocup_ci==1
																				
											scl_nivel ///
												nivel_sinremuneracion sinremuner 1 if condocup_ci==1

											scl_nivel ///
												nivel_subempleo subemp_ci 1 if condocup_ci==1

											scl_pct ///
												tasa_agro agro "1" if condocup_ci==1																	
											
											scl_nivel ///
												nivel_agro agro 1 if condocup_ci==1
											
											scl_pct ///
												tasa_minas minas "1" if condocup_ci==1																	
	
											scl_nivel ///
												nivel_minas minas 1 if condocup_ci==1										
																			
											scl_pct ///
												tasa_industria industria "1" if condocup_ci==1		
												
											scl_nivel ///
												nivel_industria industria 1 if condocup_ci==1										

											scl_pct ///
												tasa_sspublicos sspublicos "1" if condocup_ci==1		

											scl_nivel ///
												nivel_sspublicos sspublicos 1 if condocup_ci==1										

											scl_pct ///
												tasa_construccion construccion "1" if condocup_ci==1		

											scl_nivel ///
												nivel_construccion construccion 1 if condocup_ci==1												

											scl_pct ///
												tasa_comercio comercio "1" if condocup_ci==1		

											scl_nivel ///
												nivel_comercio comercio 1 if condocup_ci==1	
												
											scl_pct ///
												tasa_transporte transporte "1" if condocup_ci==1		

											scl_nivel ///
												nivel_transporte transporte 1 if condocup_ci==1																			
																			
											scl_pct ///
												tasa_financiero financiero "1" if condocup_ci==1		

											scl_nivel ///
												nivel_financiero financiero 1 if condocup_ci==1																			
							
											scl_pct ///
												tasa_servicios servicios "1" if condocup_ci==1		

											scl_nivel ///
												nivel_servicios servicios 1 if condocup_ci==1																				
								
											scl_pct ///
												tasa_profestecnico profestecnico "1" if condocup_ci==1		

											scl_nivel ///
												nivel_profestecnico profestecnico 1 if condocup_ci==1																					

											scl_pct ///
												tasa_director director "1" if condocup_ci==1		

											scl_nivel ///
												nivel_director director 1 if condocup_ci==1																					
																
											scl_pct ///
												tasa_administrativo administrativo "1" if condocup_ci==1		

											scl_nivel ///
												nivel_administrativo administrativo 1 if condocup_ci==1																			
																																						
											scl_pct ///
												tasa_comerciantes comerciantes "1" if condocup_ci==1		

											scl_nivel ///
												nivel_comerciantes comerciantes 1 if condocup_ci==1																			

											scl_pct ///
												tasa_trabss trabss "1" if condocup_ci==1		

											scl_nivel ///
												nivel_trabss trabss 1 if condocup_ci==1	
												
											scl_pct ///
												tasa_trabagricola trabagricola "1" if condocup_ci==1		

											scl_nivel ///
												nivel_trabagricola trabagricola 1 if condocup_ci==1																									
									
											scl_pct ///
												tasa_obreros obreros "1" if condocup_ci==1		

											scl_nivel ///
												nivel_obreros obreros 1 if condocup_ci==1																									

											scl_pct ///
												tasa_ffaa ffaa "1" if condocup_ci==1		

											scl_nivel ///
												nivel_ffaa ffaa 1 if condocup_ci==1																									

											scl_pct ///
												tasa_otrostrab otrostrab "1" if condocup_ci==1		

											scl_nivel ///
												nivel_otrostrab otrostrab 1 if condocup_ci==1											

											scl_pct ///
												empleo_publico spublico_ci "1" if condocup_ci==1		

											scl_pct ///
												formalidad_2 formal_ci "1" if condocup_ci==1		
												
											scl_pct ///
												formalidad_3 formal_ci "1" if condocup_ci==1 & categopri_ci==3	

											scl_pct ///
												formalidad_4 formal_ci "1" if condocup_ci==1 & categopri_ci==2
																		
											scl_mean ///
											ingreso_hor_prom hwage if condocup_ci==1 
										
												
							} /* cierro grupo etario */	

											scl_pct ///
												pensionista_65_mas pensiont_ci "1" if age_65_mas==1	
																																					
											scl_nivel ///
												num_pensionista_65_mas age_65_mas 1 if pensiont_ci==1 								

											scl_pct ///
												pensionista_cont_65_mas pension_ci "1" if age_65_mas==1	
												
											scl_pct ///
												pensionista_nocont_65_mas pensionsub_ci "1" if age_65_mas==1	
																				
											scl_pct ///
												pensionista_ocup_65_mas pensiont_ci "1" if age_65_mas==1 & condocup_ci==1

											scl_mean ///
												y_pen_cont_ppp ypen_ppp 1 if ypen_ppp!=. & age_65_mas==1

											scl_mean ///
												y_pen_cont ypen_ci 1 if ypen_ci!=. & age_65_mas==1
												
											scl_mean ///
												y_pen_nocont ypensub_ci 1 if ypensub_ci!=. & age_65_mas==1
																			
											scl_mean ///
												y_pen_total ypent_ci 1 if ypent_ci!=. & age_65_mas==1
																				
										
										}  /*cierro etnicidad*/
									} /*cierro quintiles*/
								}/*cierro area*/
							} /* cierro sexo*/ 
					
		
				
							************************************************
							  global tema "pobreza"
							************************************************
							// Division: SCL
							// Authors: Daniela Zuluaga
							************************************************
								
								local sexos Total Hombre Mujer 
								local areas	Total Rural Urbano
								local grupo_etarios	Total age_00_04 age_05_14 age_15_24 age_25_64 age_65_mas
								local etnicidades Total Indi Afro Otro
								
								foreach sexo of local sexos {
									foreach area of local areas {
										foreach grupo_etario of local grupo_etarios {
											foreach etnicidad of local etnicidades {
										
											local quintil_ingreso No_aplica
											local nivel_educativo No_aplica
											local etnicidad No_aplica
											
											/* Parameters of current disaggregation levels, used by all commands */
											global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
											noisily display "$tema: $current_slice"	
								
								
								
												* Porcentaje poblacion que vive con menos de 3.1 USD diarios per capita*
												scl_pct ///
									            pobreza31 poor31 "1" if poor31!=. 
															
												*Porcentaje poblacion que vive con menos de 5 USD diarios per capita
												scl_pct ///
									            pobreza poor "1" if poor!=. 
																
												* Porcentaje de la población con ingresos entre 5 y 12.4 USD diarios per capita*
												scl_pct ///
									            vulnerable vulnerable "1" if vulnerable!=. 
		
                                                 * Porcentaje de la población con ingresos entre 12.4 y 64 USD diarios per capita*
												scl_pct ///
									            middle middle "1" if middle!=. 
															
                                                 * Porcentaje de la población con ingresos mayores 64 USD diarios per capita*
												scl_pct ///
									            rich rich "1" if rich!=. 

											} /*cierro etnicidad*/
										} /* cierro grupo_etario */	
									}/*cierro area*/
								} /* cierro sexo*/ 
				
							local areas  Total Urbano Rural
							local etnicidades Total HogIndi HogAfro HogOtro						
								
									foreach area of local areas {
										foreach etnicidad of local etnicidades {
									
										local sexo No_aplica
										local grupo_etario No_aplica
										local quintil_ingreso No_aplica
										local nivel_educativo No_aplica
										
										
											/* Parameters of current disaggregation levels, used by all commands */
												global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
												noisily display "$tema: $current_slice"	
															
													
												 /* Coeficiente de Gini para el ingreso per cápita del hogar*/
												scl_inequal ///
												ginihh pc_ytot_ch 
							
												/* Coeficiente de Gini para salarios por hora*/
												scl_inequal ///
												gini ylmhopri_ci 
								
												/* Coeficiente de theil para el ingreso per cápita del hogar*/
												* scl_inequal ///
												*theilhh pc_ytot_ch theil 
								
												/* Coeficiente de theil para salarios por hora*/
												*scl_inequal ///
												*theil ylmhopri_ci theil 
															
												* Porcentaje del ingreso laboral del hogar contribuido por las mujeres 
												scl_mean ///
												ylmfem_ch shareylmfem_ch if jefe_ci==1 & shareylmfem_ch!=. 
															 
										} /*cierro etnicidad*/					
									}/*cierro area*/
							
																											
									
									local quintil_ingresos Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 
									local areas Total Rural Urbano
									local etnicidades Total HogIndi HogAfro HogOtro
									
									foreach quintil_ingreso of local quintil_ingresos {
										foreach area of local areas {
											foreach etnicidad of local etnicidades {
											
												local sexo No_aplica
												local nivel_educativo No_aplica
												local grupo_etario No_aplica
												
												
												
													/* Parameters of current disaggregation levels, used by all commands */
															global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
															noisily display "$tema: $current_slice"	
															
															
															/* Porcentaje de hogares que reciben remesas del exterior */
															scl_pct ///
																indexrem indexrem "1" 

											} /*cierro etnicidad*/
										} /* cierro area */	
									}/*cierro quintil_ingresos*/
											
			
		
								************************************************
								  global tema "vivienda"
								************************************************
								// Division: SCL
								// Authors: Daniela Zuluaga
								************************************************
								
								local quintil_ingresos 	Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 
								local areas Total Rural Urbano
								local etnicidades Total HogIndi HogAfro HogOtro
								
								foreach quintil_ingreso of local quintil_ingresos {
									foreach area of local areas {
										foreach etnicidad of local etnicidades {
										
											local sexo No_aplica
											local nivel_educativo No_aplica
											local grupo_etario No_aplica
										
											
												/* Parameters of current disaggregation levels, used by all commands */
												global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
												noisily display "$tema: $current_slice"	
									
						
							
												   * % de hogares con servicio de agua de acueducto*
												   scl_pct ///
												   aguared_ch aguared_ch "1" if jefe_ci==1 & aguared_ch!=. 
																	
												   * % de hogares con acceso a servicios de saneamiento mejorados*
												   scl_pct ///
												   des2_ch des2_ch "1" if jefe_ci==1 & des2_ch!=. 							
																															
												   * % de hogares con electricidad *
												   scl_pct ///
												   luz_ch luz_ch 2 if jefe_ci==1 &  luz_ch!=. 
																													
												   * % hogares con pisos de tierra *
													scl_pct ///
													dirtf_ch dirtf_ch "1" if jefe_ci==1 &  dirtf_ch!=. 
															
												   * % de hogares con refrigerador *
													scl_pct ///
													refrig_ch freezer_ch "1" if jefe_ci==1 &  freezer_ch!=. 

													* % de hogares con carro particular*
													scl_pct ///
													auto_ch auto_ch "1" if jefe_ci==1 &  auto_ch!=. 													
																	
													* % de hogares con acceso a internet *
													scl_pct ///
													internet_ch internet_ch "1" if jefe_ci==1 &  internet_ch!=. 
																				
													* % de hogares con teléfono celular*
													scl_pct ///
													cel_ch cel_ch "1" if jefe_ci==1 &  cel_ch!=.
																	
													* % de hogares con techos de materiales no permanentes*
													scl_pct ///
													techonp_ch techonp_ch "1" if jefe_ci==1 &  techonp_ch!=.

													* % de hogares con paredes de materiales no permanentes*
													cap scl_pct ///
													parednp_ch parednp_ch "1" if jefe_ci==1 &  parednp_ch!=.

													* Número de miembros por cuarto*
													scl_mean ///
													hacinamiento_ch hacinamiento_ch if jefe_ci==1 & hacinamiento_ch!=. 
													
													*% de hogares con estatus residencial estable *
													scl_pct ///
													estable_ch estable_ch "1" if jefe_ci==1 &  estable_ch!=.
												
												
												}/*cierro etnicidades*/
											}/*cierro area*/		
										} /*cierro quintil_ingreso*/
								

								
					
								
							    ************************************************
								  global tema "diversidad"
								************************************************
								// Division: GDI
								// Authors: Nathalia Maya, Maria Antonella Pereira, Cesar Lins de Oliveira
								************************************************
								local sexos Total Hombre Mujer
								local areas Total Rural Urbano
								
								
								foreach sexo of local sexos {
									foreach area of local areas {
										local quintil_ingreso No_aplica
										local nivel_educativo No_aplica
										local grupo_etario No_aplica
										local etnicidad No_aplica
										
										
											/* Parameters of current disaggregation levels, used by all commands */
											global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
											noisily display "$tema: $current_slice"	
								
												* Porcentaje población afrodescendiente 
												scl_pct ///
													pafro_ci afroind_ci "2"
												/* Porcentaje población indígena */
												scl_pct ///
												    pindi_ci afroind_ci "1" 
												/* Porcentaje población ni Afrodescendiente ni indígena*/
												scl_pct ///
												    pnoafronoindi_ci afroind_ci "3"

										/* Porcentaje de hogares con jefatura afrodescendiente */ 
										        scl_pct ///
											pjefe_afro_ch afroind_ch "2" 
										/* Porcentaje de hogares con jefatura indígena */ 
										        scl_pct ///												   
											pjefe_indi_ch afroind_ch "1" 
										/* Porcentaje de hogares con jefatura ni afrodescendiente ni indígena*/ 
											scl_pct ///												   
											pjefe_noafronoindi_ch afroind_ch "3"

										/* Porcentaje de personas que reportan tener alguna dificultad en actividades de la vida diaria */
											  scl_pct ///												   
											pdis_ci dis_ci "1"
										/* Porcentaje de hogares con miembros que reportan tener alguna dificultad en realizar actividades de la vida diaria. */
											scl_pct ///
											pdis_ch dis_ch "1" 
																
												
											}/*cierro area*/		
										} /*cierro sexo*/
							
									
								
								************************************************
								  global tema "migracion"
								************************************************
								// Division: MIG
								// Authors: Fernando Morales Velandia
								************************************************
								local sexos Total Hombre Mujer
								local areas Total Rural Urbano
								local etnicidades Total	Afro Indi Otro
								
								foreach sexo of local sexos {
									foreach area of local areas {
										foreach etnicidad of local etnicidades {
									
										local quintil_ingreso No_aplica
										local nivel_educativo No_aplica
										local grupo_etario No_aplica
										
											/* Parameters of current disaggregation levels, used by all commands */
											global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
											noisily display "$tema: $current_slice"	
											
								
											/* Porcentaje de migrantes en el pais */
											scl_pct ///
												migrante_ci migrante_ci "1"
																				
											/* Porcentaje de migrantes antiguos (5 años o mas) en el pais */
											scl_pct ///
												migantiguo5_ci migantiguo5_ci "1"
												
											/* Porcentaje de migrantes LAC en el pais */
											scl_pct ///
												migrantelac_ci migrantelac_ci "1"
										
										}/*cierro etnicidad*/
									}/*cierro clases3*/		
								} /*cierro clases2*/   
							



			



	postclose `ptablas_`pais'_`ano''

	use `tablas_`pais'_`ano'', clear
	* destring valor muestra, replace
	recode valor 0=.
	* recode muestra 0=.
	save `tablas_`pais'_`ano'', replace 
	
	include "${input}/dataframe_format.do"
	save "${out}/indicadores_encuestas_hogares_scl_`pais'`ano'.dta", replace 
	export delimited using "${out}/csv/indicadores_encuestas_hogares_`pais'_$encuestas_`ano'.csv", replace
	//clear
	
  }		
end
noi display ""
noi display as txt "-------------------------------------------------------------------------------------------------------------"
noi display as txt "    SCL DATA ECOSYSTEM WORKING GROUP"
noi display as txt "-------------------------------------------------------------------------------------------------------------"
noi display        "     Use command: scl_indicators PAIS ANIO"
noi display as txt "     Configuraciones buscadas en: `=c(sysdir_personal)'/`=c(username)'_`=c(os)'.doh"
noi display as txt "     Este archivo debe definir las variables globales gitFolder y source"
noi display ""
noi type "`=c(sysdir_personal)'/`=c(username)'_`=c(os)'.doh"

noi display as txt "-------------------------------------------------------------------------------------------------------------"
}
