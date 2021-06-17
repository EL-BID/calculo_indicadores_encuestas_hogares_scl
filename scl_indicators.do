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

qui {
cap ssc install estout
cap ssc install inequal7
set max_memory 200g, permanently
set segmentsize  400m, permanently
set maxvar 120000, perm
clear all

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
    clear all
	drop _all 
	set more off 
	

	*****   Configure paths in this user's computer    ************
	qui include "`=c(sysdir_personal)'/`=c(username)'_`=c(os)'.doh"
	display "Configuraciones de `=c(username)'..."
	display "Carpeta Git: $gitFolder"
	display "Carpeta de datos: $source"

	***************************************************************

	
	* Github Repository (local path)
	local mydir "${gitFolder}/calculo_indicadores_encuestas_hogares_scl"

	*****   Custom commands for calculating indicators ************
	qui include "`mydir'/scl_programs.doh"
	***************************************************************
	
	* Directory containing do-Files used as input
	global input	"`mydir'/Input"
	* Directory where to save the output .dta
	global out 	 "`mydir'/Output"


	
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
		noisily display "Calculando //`pais'//$encuestas/data_arm//`pais'_`ano'$rondas_BID.dta..."	
		
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
	}
	else {
		/* IN the case the dta file DOES NOT EXIST for this country/year, we are going
		  to execute the rest of the code ANYWAY. The reason is: regardless if the 
		  file exists or not, all indicators will be generated in the same way, 
		  but with a "missing value" if the file does not exist. The programs are
		  already capturing it and will generate the missing values accordingly
		  whenever the indicator cannot be calculated.
		  */
		  noisily display "${source}/`pais'//$encuestas/data_arm//`pais'_`ano'${rondas}_BID.dta - no se encontró el archivo. Generando missing values..."
		  
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
	
		
		local areas Total Rural  
		local quintil_ingresos Total quintil_1 

		foreach quintil_ingreso of local quintil_ingresos {
			foreach area of local areas {								
				local nivel_educativo No_aplica // formerly called "nivel". If "no_aplica", use Total.
				local sexo No_aplica
				local grupo_etario No_aplica
				local etnicidad No_aplica 
				
				/* Parameters of current disaggregation levels, used by all commands */
				global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
				noisily display "$tema: $current_slice"
				
				//======== CALCULATE INDICATORS ================================================
				
					
				/* Porcentaje de hogares con jefatura femenina */
				scl_pct ///
				jefa_ch jefa_ch "1" if jefa_ch!=. & sexo_ci!=.												
						
					
				}/*cierro area*/		
			} /*cierro quintil*/
					    
							



			



	postclose `ptablas_`pais'_`ano''

	use `tablas_`pais'_`ano'', clear
	* destring valor muestra, replace
	recode valor 0=.
	* recode muestra 0=.
	save `tablas_`pais'_`ano'', replace 
	
	include "${input}/dataframe_format.do"
	save "${out}/indicadores_encuestas_hogares_scl_`pais'`ano'.dta", replace 
	export delimited using "${out}/csv/indicadores_encuestas_hogares_`pais'_$encuestas_`ano'.csv", replace
	clear
	
  }		
end
noi display ""
noi display "-------------------------------------------------------------------------------------------------------------"
noi display "    SCL DATA ECOSYSTEM WORKING GROUP"
noi display "-------------------------------------------------------------------------------------------------------------"
noi display "     Use: scl_indicators PAIS ANIO"
noi display "     Configuraciones buscadas en: `=c(sysdir_personal)'/`=c(username)'_`=c(os)'.doh"
noi display "     Este archivo debe definir las variables globales gitFolder y source"
noi display ""
capture confirm file "`=c(sysdir_personal)'/`=c(username)'_`=c(os)'.doh"
if _rc>0 {
  noi display " ** ATENCIÓN: el archivo de configuración no existe. Es necesario crearlo."
}
else {
  noi type "`=c(sysdir_personal)'/`=c(username)'_`=c(os)'.doh"
}
noi display "-------------------------------------------------------------------------------------------------------------"
}
