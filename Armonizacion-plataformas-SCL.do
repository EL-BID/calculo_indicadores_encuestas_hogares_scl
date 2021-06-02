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
clear all
drop _all 
set more off 
set maxvar 120000, perm

*ssc install quantiles inequal7
 cap ssc install estout
 cap ssc install inequal7
 set max_memory 200g, permanently
set segmentsize  400m, permanently
 
 cd "C:\Users\ALOP\OneDrive - Inter-American Development Bank Group\Desktop\Git_repositories\calidad\calculo_indicadores_encuestas_hogares_scl/"
 
*qui {

/**** if composition utility function ****************************
 scl_if_compose sexo area nivel_educativo if ...
 will return
  if ... & `sexo'==1 & `area'==1 & `nivel_educativo'==1
 in s(xif) macro.
 Needs to clear s manually calling sreturn clear.
******************************************************************/
capture program drop scl_if_compose
program scl_if_compose, sclass
 syntax [if]
 /* paramaters of the current disaggregation (comes from $current_slice global macro) */
 local sexo : word 4 of $current_slice
 local area : word 5 of $current_slice
 local nivel_educativo : word 6 of $current_slice
 local quintil_ingreso : word 7 of $current_slice
 local grupo_etario : word 8 of $current_slice
 local etnicidad : word 9 of $current_slice
 
 if "`if'"!="" {
     /* most common case */
	 sreturn local xif `"`if' & `sexo'==1 & `area'==1 & `nivel_educativo'==1 & `quintil_ingreso'==1 & `grupo_etario'==1 "'
  }
  else {
	 sreturn local xif `"if `sexo'==1 & `area'==1 & `nivel_educativo'==1 & `quintil_ingreso'==1 & `grupo_etario'==1 "'
  }
  
end


/***** scl_pct ***************************************************
 Calculates percentage indicators using
 the given variable and given category.
 Accepts 'if'.

 E.g., scl_pct pmujer sexo_ci "Mujer" if ...
 
 Remark: if category is not provided, it is
  assumed to be "1"
******************************************************************/
capture program drop scl_pct                                                        
program scl_pct
  syntax anything [if]
  local indname : word 1 of `anything'
  local indvar : word 2 of `anything'
  local indcat : word 3 of `anything'
    /* paramaters of the current disaggregation (comes from $current_slice global macro) */
  local pais : word 1 of $current_slice
  local ano : word 2 of $current_slice
  local geografia_id : word 3 of $current_slice
  local sexo : word 4 of $current_slice
  local area : word 5 of $current_slice
  local nivel_educativo : word 6 of $current_slice
  local quintil_ingreso : word 7 of $current_slice
  local grupo_etario : word 8 of $current_slice
  local etnicidad : word 9 of $current_slice
     
	scl_if_compose `if'
	local xif `"`s(xif)'"'
	sreturn clear
	 
	cap svy:proportion `indvar' `xif'  
  
  if _rc == 0 {
	    
    mat valores=r(table)
	local valor =valores[1,`indcat'] *100
	
	estat cv
	mat error_standar=r(se)
	local se = error_standar[1,`indcat'] 
	
	mat cv=r(cv)
	local cv = cv[1,`indcat'] 
	
	estat size
	mat muestra=r(_N)
	local muestra = muestra[1,`indcat'] 
	di `muestra'
  	
	post $output ("`ano'") ("`pais'") ("`pais'-$encuestas") ("`geografia_id'") ("`sexo'") ("`area'") ("`quintil_ingreso'") ("`nivel_educativo'") ("`grupo_etario'") ("`etnicidad'") ("$tema") ("`indname'") (`"sum of `indvar'"') (`valor') (`se') (`cv') (`muestra')
	
  }
  if _rc != 0 {
   /* generate a line with missing value */
	post $output ("`ano'") ("`pais'") ("`pais'-$encuestas") ("`geografia_id'") ("`sexo'") ("`area'") ("`quintil_ingreso'") ("`nivel_educativo'") ("`grupo_etario'") ("`etnicidad'") ("$tema") ("`indname'") (`"sum of `indvar'"') (.) (.) (.) (.)
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
  local indcat : word 3 of `anything'
  /* paramaters of the current disaggregation (comes from $current_slice global macro) */
  local pais : word 1 of $current_slice
  local ano : word 2 of $current_slice
  local geografia_id : word 3 of $current_slice
  local sexo : word 4 of $current_slice
  local area : word 5 of $current_slice
  local nivel_educativo : word 6 of $current_slice
  local quintil_ingreso : word 7 of $current_slice
  local grupo_etario : word 8 of $current_slice
  local etnicidad : word 9 of $current_slice
  
  scl_if_compose `if'
  local xif `"`s(xif)'"'
  sreturn clear
 
  
  display `"$tema - `indname'"'
  
  cap svy:total `indvar' `xif'  
  
  if _rc == 0 {
	    
   mat temp=e(b)
   mat muestra = e(N)
   
	local valor = temp[1,`indcat']
	local muestra = `e(N)'
   
	estat cv 
	mat cova= r(cv)
	mat ste= r(se)

	local cv = cova[1,`indcat']
	local se = ste[1,`indcat']
  

	post $output ("`ano'") ("`pais'") ("`pais'-$encuestas") ("`geografia_id'") ("`sexo'") ("`area'") ("`quintil_ingreso'") ("`nivel_educativo'") ("`grupo_etario'") ("`etnicidad'") ("$tema") ("`indname'") (`"sum of `indvar'"') (`valor') (`se') (`cv') (`muestra')
	
  }
  else {
   /* generate a line with missing value */
	post $output ("`ano'") ("`pais'") ("`pais'-$encuestas") ("`geografia_id'") ("`sexo'") ("`area'") ("`quintil_ingreso'") ("`nivel_educativo'") ("`grupo_etario'") ("`etnicidad'") ("$tema") ("`indname'") (`"sum of `indvar'"') (.) (.) (.) (.)
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
  local sexo : word 4 of $current_slice
  local area : word 5 of $current_slice
  local nivel_educativo : word 6 of $current_slice
  local quintil_ingreso : word 7 of $current_slice
  local grupo_etario : word 8 of $current_slice
  local etnicidad : word 9 of $current_slice
  
  scl_if_compose `if'
  local xif `"`s(xif)'"'
  sreturn clear
 
  
  display `"$tema - `indname'"'
	
	cap svy:mean `indvar' `xif'  
  
  if _rc == 0 {
	    
    mat valores=r(table)
	local valor =valores[1,1] *100
	
	estat cv
	mat error_standar=r(se)
	local se = error_standar[1,1] *100
	
	mat cv=r(cv)
	local cv = cv[1,1] 
	
	estat size
	mat muestra=r(_N)
	local muestra = muestra[1,1] 
	
	post $output ("`ano'") ("`pais'") ("`pais'-$encuestas") ("`geografia_id'") ("`sexo'") ("`area'") ("`quintil_ingreso'") ("`nivel_educativo'") ("`grupo_etario'") ("`etnicidad'") ("$tema") ("`indname'") (`"mean of `indvar'"') (`valor') (`se') (`cv') (`muestra')
	
  }
  else {
   /* generate a line with missing value */
	post $output ("`ano'") ("`pais'") ("`pais'-$encuestas") ("`geografia_id'") ("`sexo'") ("`area'") ("`quintil_ingreso'") ("`nivel_educativo'") ("`grupo_etario'") ("`etnicidad'") ("$tema") ("`indname'") (`"mean of `indvar'"') (.) (.) (.) (.)
  }
  
end

/***** scl_median **************************************************
 Calculates mean indicators using
 the given variable.
 Accepts 'if'.
 E.g., scl_median pobedad_ci
******************************************************************/
capture program drop scl_median                                                       
program scl_median
  syntax anything [if]
  /* parameters of the indicator */
  local indname : word 1 of `anything'
  local indvar : word 2 of `anything'
  /* paramaters of the current disaggregation (comes from $current_slice global macro) */
  local pais : word 1 of $current_slice
  local ano : word 2 of $current_slice
  local geografia_id : word 3 of $current_slice
  local sexo : word 4 of $current_slice
  local area : word 5 of $current_slice
  local nivel_educativo : word 6 of $current_slice
  local quintil_ingreso : word 7 of $current_slice
  local grupo_etario : word 8 of $current_slice
  local etnicidad : word 9 of $current_slice
  
  scl_if_compose `if'
  local xif `"`s(xif)'"'
  sreturn clear
 
  
  display `"$tema - `indname'"'
  _pctile `indvar'  [pweight=factor_ch]  `xif', p(50) 
   
  if _rc == 0 {
   
	return list
	local valor = `r(r1)' 
	estat cv
	mat error_standar=r(se)
	local se = error_standar[1,1] 
	mat cv=r(cv)
	local cv = cv[1,1] 
	estat size
	mat muestra=r(_N)
	local muestra = muestra[1,1] 
	
	post $output ("`ano'") ("`pais'") ("`pais'-$encuestas") ("`geografia_id'") ("`sexo'") ("`area'") ("`quintil_ingreso'") ("`nivel_educativo'") ("`grupo_etario'") ("`etnicidad'") ("$tema") ("`indname'") (`"median of `indvar'"') (`valor') (`se') (`cv') (`muestra')
	
  }
  else {
   /* generate a line with missing value */
	post $output ("`ano'") ("`pais'") ("`pais'-$encuestas") ("`geografia_id'") ("`sexo'") ("`area'") ("`quintil_ingreso'") ("`nivel_educativo'") ("`grupo_etario'") ("`etnicidad'") ("$tema") ("`indname'") (`"median of `indvar'"') (.) (.) (.) (.)
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
  local sexo : word 4 of $current_slice
  local area : word 5 of $current_slice
  local nivel_educativo : word 6 of $current_slice
  local quintil_ingreso : word 7 of $current_slice
  local grupo_etario : word 8 of $current_slice
  local etnicidad : word 9 of $current_slice
  
  /* create the "if" part of the command
    combining with the "if" set when calling
	the program (if any) */
  scl_if_compose `if'
  local xif `"`s(xif)'"'
  sreturn clear
   
  
   display `"$tema - `indname'"'
   
   cap svy:ratio `indvarnum'/`indvarden' `xif'  
  
  if _rc == 0 {
	    
    mat valores=r(table)
	local valor =valores[1,1] *100
	
	estat cv
	mat error_standar=r(se)
	local se = error_standar[1,1] *100
	
	mat cv=r(cv)
	local cv = cv[1,1] 
	
	estat size
	mat muestra=r(_N)
	local muestra = muestra[1,1] 
	
   		
		post $output ("`ano'") ("`pais'") ("`pais'-$encuestas") ("`geografia_id'") ("`sexo'") ("`area'") ("`quintil_ingreso'") ("`nivel_educativo'") ("`grupo_etario'") ("`etnicidad'") ("$tema") ("`indname'") (`"`indvarnum'/`indvarden'"') (`valor') (`se') (`cv') (`muestra')
	}
		
	else {
		/* generate a line with missing value */
		post $output ("`ano'") ("`pais'") ("`pais'-$encuestas") ("`geografia_id'") ("`sexo'") ("`area'") ("`quintil_ingreso'") ("`nivel_educativo'") ("`grupo_etario'") ("`etnicidad'") ("$tema") ("`indname'") (`"`indvarnum'/`indvarden'"') (.) (.) (.) (.)
	}
  
  
  
end
	
/***** scl_ratio_2conds ********************************************
Calculates ratio indicators using
two variables (1st the numerator, 2nd the denominator).
Accepts two conditions as text (last two arguments, see example).
Both conditions must be provided, if either of the
conditions is unnecessary set “if 1” as the condition.
E.g., 
local numerator_condition `"if edad_ci>=6 & asiste_ci!=."'
local denominator_condition `"if asiste_ci!=."'
scl_ratio_2conds ///
   tasa_bruta_asis asis_prim age_prim `"`numerator_condition'"' `"`denominator_condition'"'
******************************************************************/
capture program drop scl_ratio_2conds                                                        
program scl_ratio_2conds
  syntax anything
  /* parameters of the indicator */
  local indname : word 1 of `anything'
  local indvarnum : word 2 of `anything'
  local indvarden : word 3 of `anything'
  local numcond : word 4 of `anything'
  local dencond : word 5 of `anything'
  /* paramaters of the current disaggregation (comes from $current_slice global macro) */
  local pais : word 1 of $current_slice
  local ano : word 2 of $current_slice
  local geografia_id : word 3 of $current_slice
  local sexo : word 4 of $current_slice
  local area : word 5 of $current_slice
  local nivel_educativo : word 6 of $current_slice
  local quintil_ingreso : word 7 of $current_slice
  local grupo_etario : word 8 of $current_slice
  local etnicidad : word 9 of $current_slice
    
  display `"$tema - `indname'"'
  
   cap svy:total `indvarnum' if `numcond' & `sexo'==1 & `area'==1 &  `quintil_ingreso'==1 
	mat temp=e(b)
	local numerador = temp[1,1]
  
   cap svy:total `indvarden' if `dencond' & `sexo'==1 & `area'==1 &  `quintil_ingreso'==1 
   mat temp2=e(b)
   local denominador = temp2[1,1]   

  
  cap svy:ratio `numerador'/`denominador'  
  
  if _rc == 0 {
	    
    mat valores=r(table)
	local valor =valores[1,1] *100
	
	estat cv
	mat error_standar=r(se)
	local se = error_standar[1,1] *100
	
	mat cv=r(cv)
	local cv = cv[1,1] 
	
	estat size
	mat muestra=r(_N)
	local muestra = muestra[1,1] 
  
           
           post $output ("`ano'") ("`pais'") ("`pais'-$encuestas") ("`geografia_id'") ("`sexo'") ("`area'") ("`quintil_ingreso'") ("`nivel_educativo'") ("`grupo_etario'") ("`etnicidad'") ("$tema") ("`indname'") (`"`indvarnum'/`indvarden'"') (`valor') (`se') (`cv') (`muestra')
     }
     else {
           /* generate a line with missing value */
           post $output ("`ano'") ("`pais'") ("`pais'-$encuestas") ("`geografia_id'") ("`sexo'") ("`area'") ("`quintil_ingreso'") ("`nivel_educativo'") ("`grupo_etario'") ("`etnicidad'") ("$tema") ("`indname'") (`"`indvarnum'/`indvarden'"') (.) (.) (.) (.)
     }
     

end


/***** scl_inequal **************************************************
 Calculates gini and theil indicators using
 the given variable.
 Accepts 'if'.
 E.g., scl_inequal ginihh pc_ytot_ch gini if pc_ytot_ch!=. & pc_ytot_ch>0
******************************************************************/
capture program drop scl_inequal                                                        
program scl_inequal
  syntax anything [if]
  /* parameters of the indicator */
  local indname : word 1 of `anything'
  local indvar : word 2 of `anything'
  local typeind : word 3 of `anything'
  /* paramaters of the current disaggregation (comes from $current_slice global macro) */
  local pais : word 1 of $current_slice
  local ano : word 2 of $current_slice
  local geografia_id : word 3 of $current_slice
  local sexo : word 4 of $current_slice
  local area : word 5 of $current_slice
  local nivel_educativo : word 6 of $current_slice
  local quintil_ingreso : word 7 of $current_slice
  local grupo_etario : word 8 of $current_slice
  local etnicidad : word 9 of $current_slice
  
   scl_if_compose `if'
  local xif `"`s(xif)'"'
  sreturn clear
 
  
  display `"$tema - `indname'"'
  						
	capture quietly inequal7 `indvar' [w=round(factor_ci)] `xif'
	if _rc == 0 {
    local valor =`r(`typeind')' * 100
		
	
	post $output ("`ano'") ("`pais'") ("`pais'-$encuestas") ("`geografia_id'") ("`sexo'") ("`area'") ("`quintil_ingreso'") ("`nivel_educativo'") ("`grupo_etario'") ("`etnicidad'") ("$tema") ("`indname'") (`"`typeind' of `indvar'"') (`valor') (`se') (`cv') (`muestra')
	
	}
	if _rc != 0 {
   /* generate a line with missing value */
	post $output ("`ano'") ("`pais'") ("`pais'-$encuestas") ("`geografia_id'") ("`sexo'") ("`area'") ("`quintil_ingreso'") ("`nivel_educativo'") ("`grupo_etario'") ("`etnicidad'") ("$tema") ("`indname'") (`"`typeind' of `indvar'"') (.) (.) (.) (.)
	}
  
 end 




/*********************************************************************/

/*
* Do files will be loaded relative to current directory. Set current directory to the GitHub folder
*  using command "cd" before running the code 
*/

local mydir = c(pwd) /* GitHub folder */
di c(pwd)
*
* If you want to set a local folder instead, set this global macro before running the code.
* If $source is empty, then by default the shared folder will be used (must be at the IDB or
* connected to the VPN)

*if "${source}"=="" {
	global source   "C:\Users\ALOP\OneDrive - Inter-American Development Bank Group\Desktop\harmonized" //if you have a local copy of the .dta files, change here to use your local copy 
*}

/*
 Location of the .do files to include
*/
	global input	"`mydir'\Input"
	global out 	 "`mydir'\Output"
/*
* Location for temporary files. This folder is on MS TEAMS.
* 
* NOTE: template.dta must be in this folder.
*/
	global covidtmp  "`mydir'\Output"

//alternatively, this folder might be under the following path
mata:st_numscalar("Found", direxists("$covidtmp"))
if scalar(Found)==0  {
	global covidtmp  "`mydir'\Output"
	//check if it was found now
	mata:st_numscalar("Found", direxists("$covidtmp"))
}
//if the folder wasn't found in either paths
if scalar(Found)==0 {
	noi display "DID NOT FIND THE TEAMS FOLDER - $covidtmp"
	noi display "template.dta should be in this folder. Missing this folder may result in execution errors."
	
}

/*====================================================================
                        1: Open dataset and Generate indicators
====================================================================*/

**** include "${input}/calculo_microdatos_scl.do"
						


** Creo locales principales:
						
*global paises  /*ARG BHS BOL BRB BRA  BLZ */ BRA CHL /*COL CRI ECU SLV GTM GUY HTI HND JAM MEX NIC PAN PRY PER DOM SUR TTO URY VEN */
local anos  2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 

global paises ARG
local anos 2018 

local geografia_id total_nacional
local etnicidad No_aplica

	noisily display "Empezando calculos..."

	foreach pais of global paises {
		    
			tempfile microdato_`pais'
			tempname pmicrodato_`pais'

			postfile `pmicrodato_`pais'' str4 tiempo_id str3 pais_id str25(fuente geografia_id sexo area quintil_ingreso nivel_educativo grupo_etario etnicidad tema indicador) str35 description valor se cv sample using `microdato_`pais'', replace
			postclose `pmicrodato_`pais''
			use `microdato_`pais'', clear


			save "${out}\indicadores_encuestas_hogares_scl_`pais'.dta", replace 
		
		
		foreach ano of local anos {	
			
			tempfile tablas_`pais'
			tempname ptablas_`pais'
			global output `ptablas_`pais''

			** Este postfile da estructura a la base:

			* postfile `ptablas' str30(tiempo_id pais_id geografia_id sexo area nivel_id tema indicador valor muestra) using `tablas', replace
			postfile `ptablas_`pais'' str4 tiempo_id str3 pais_id str25(fuente geografia_id sexo area quintil_ingreso nivel_educativo grupo_etario etnicidad tema indicador) str35 description valor se cv sample using `tablas_`pais'', replace
			
			
			
			* En este dofile de encuentra el diccionario de encuestas y rondas de la región
			 include "${input}\Directorio HS LAC.do" 
			 * Encuentra el archivo para este país/año
			 cap use "${source}\\`pais'\\$encuestas\data_arm\\`pais'_`ano'${rondas}_BID.dta" , clear
di `_rc'
			 *foreach encuesta of local encuestas {
			 /* 
			   Alternatively, if you want to test a certain collection of .dta files,
			   uncomment the code below which will search for all .dta files in the $source
			   folder, that start with the name PAIS_ANO. 
			   
			  local files : dir "${source}" files "`pais'_`ano'*.dta"
			  local foundfile : word 1 of `files'
			  cap use "${source}//`foundfile'", clear
			*/
			  	

				if _rc == 0 { 
					//* Si esta base de datos existe, entonces haga: */
					noisily display "Calculando \\`pais'\\$encuestas\data_arm\\`pais'_`ano'$rondas_BID.dta..."		
														
						
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
						
						
						* variables de clase
						
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
			
					* Variables intermedias 
			} //end capture
						* Educación: niveles y edades teóricas cutomizadas  
							include "${input}\var_tmp_EDU.do"
						* Mercado laboral 
							include "${input}\var_tmp_LMK.do"
						* Pobreza, vivienda, demograficas
							include "${input}\var_tmp_SOC.do"
						* Inclusion
						**	include "${input}/var_tmp_GDI.do"	
							
					* base de datos de microdatos con variables intermedias
					********** include "${input}/append_calculo_microdatos_scl.do"	
					
					
				}
				if _rc ~= 0  {
pause				
					/* IN the case the dta file DOES NOT EXIST for this country/year, we are going
					  to execute the rest of the code ANYWAY. The reason is: regardless if the 
					  file exists or not, all indicators will be generated in the same way, 
					  but with a "missing value" if the file does not exist. The programs are
					  already capturing it and will generate the missing values accordingly
					  whenever the indicator cannot be calculated.
					  */
					  *display "`pais'//`encuesta'/data_arm//`pais'_`ano'`ronda'_BID.dta - non existe. Generando missing values..."
					  noisily display "`pais'_`ano'`rondas'_BID.dta - no se encontró el archivo. Generando missing values..."
					  
					  /* use an empty file which contains all variables */

					  use "${input}\template.dta", clear

					
				}
				
				
*****************************************************************************************************************************************
					* 1.2: Indicators for each topic		
*****************************************************************************************************************************************
				
/*
						************************************************
						  global tema "demografia"
						************************************************
						// Division: SCL
						// Authors: Daniela Zuluaga
						************************************************
					
						
						local areas Total Rural Urbano  
						local quintil_ingresos Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 
		
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
								jefa_ch jefa_ch 2 if jefa_ch!=. & sexo_ci!=.												
										
								/* Porcentaje de hogares con jefatura económica femenina */
								scl_pct ///
								jefaecon_ch hhfem_ch 2 if hhfem_ch!=. & sexo_ci!=.											
										
								/* Porcentaje de población femenina*/
								scl_pct ///
								pobfem_ci pobfem_ci 2 if pobfem_ci!=. 
																						
								/* Porcentaje de hogares con al menos un miembro de 0-5 años*/
								scl_pct ///
								miembro6_ch miembro6_ch 2 if miembro6_ch !=. 
												
								* Porcentaje de hogares con al menos un miembro entre 6-16 años*
								scl_pct ///
								miembro6y16_ch miembro6y16_ch 2 if  miembro6y16_ch!=.
																													
								* Porcentaje de hogares con al menos un miembro de 65 años o más*
								cap scl_pct ///
								miembro65_ch miembro65_ch 2 
												
								* Porcentaje de hogares unipersonales*
								scl_pct ///
								unip_ch unip_ch 2 
																									
								* Porcentaje de hogares nucleares*
								scl_pct ///
								nucl_ch nucl_ch 2 
																
								* Porcentaje de hogares ampliados*
						        scl_pct ///
								ampl_ch ampl_ch 2 
																																
								* Porcentaje de hogares compuestos*
								scl_pct ///
								comp_ch comp_ch 2 
																	
								* Porcentaje de hogares corresidentes*
							    scl_pct ///
								corres_ch corres_ch 2 				

								*Razón de dependencia*
								scl_mean ///
								depen_ch depen_ch if jefe_ci==1 & depen_ch!=.				
										
								* Número promedio de miembros del hogar*
								scl_mean ///
								tamh_ch nmiembros_ch if jefe_ci==1 & nmiembros_ch!=. 
																
								* Porcentaje de población menor de 18 años*
								scl_pct ///
							    pob18_ci pob18_ci 2 if pob18_ci!=.
																									
								* Porcentaje de población de 65+ años*
								scl_pct ///
								pob65_ci pob65_ci 2 if pob65_ci!=.
																			
								* Porcentaje de individuos en union formal o informal*
								scl_pct ///
								union_ci union_ci 2 if union_ci!=.
																								
								* Edad mediana de la población en años *
								scl_median ///
								pobedad_ci edad_ci if edad_ci!=. 
									
								}/*cierro area*/		
							} /*cierro quintil*/
							
							local quintil_ingresos Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 
															
							foreach quintil_ingreso of local quintil_ingresos {
								local area No_aplica
								local nivel_educativo No_aplica							
								local sexo No_aplica
								local grupo_etario No_aplica
								local etnicidad No_aplica
								
								
								/* Parameters of current disaggregation levels, used by all commands */
								global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
								noisily display "$tema: $current_slice"	
										
								//======== CALCULATE INDICATORS ================================================
								
								/* Porcentaje de población que reside en zonas urbanas*/
								scl_pct ///
								urbano_ci urbano_ci 1 if urbano_ci!=. 
										
							} /*cierro clase*/			    
											
*/				
											
							************************************************
							  global tema "educacion"
							************************************************
							// Division: EDU
							// Authors: Angela Lopez 
							************************************************				
									
							local sexos Total Hombre Mujer  
							local areas Total Rural Urbano
							local quintil_ingresos Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5
							
							foreach sexo of local sexos {	
								foreach area of local areas {
									foreach quintil_ingreso of local quintil_ingresos {
									
										local etnicidad No_aplica
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
											
										
									local grupo_etarios age_4_5 age_6_11 age_12_14 age_15_17 age_18_23
									
									foreach grupo_etario of local grupo_etarios {								
									local nivel_educativo No_aplica
											
						* Parameters of current disaggregation levels, used by all commands 
								global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
								noisily display "$tema: $current_slice"

											
												
						* Tasa asistencia grupo etario *
									scl_pct ///
									tasa_asis_edad asiste_ci 2
																																				
						* Tasa No Asistencia grupo etario *
									scl_pct ///
									tasa_no_asis_edad asiste_ci 1
									 
													
									} /*cierro grupo etario */
									
						* Años_Escolaridad y Años_Escuela			
										
									local nivel_educativos anos_0 anos_1_5 anos_6 anos_7_11 anos_12 anos_13_o_mas
									
									foreach nivel_educativo of local nivel_educativos {
									local grupo_etario No_aplica
									
											global current_slice `pais' `ano' `geografia_id' `sexo' `area' `quintil_ingreso'  `grupo_etario' `etnicidad'
											noisily display "$tema: $current_slice"
																			
													scl_pct ///
													Años_Escolaridad_25_mas `nivel_educativo' 2 if (aedu_ci !=. | edad_ci !=.)
											
													
									} /* cierro nivel educativo 3 */		
										
										
						* Ninis_2	
								
									local grupo_etarios age_15_24 age_15_29
									
									foreach grupo_etario of local grupo_etarios {
									local nivel_educativo No_aplica
									
										global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
										noisily display "$tema: $current_slice"
											
										scl_pct ///
										Ninis_2 nini 2 & edad_ci !=.
										
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
											leavers leavers 2 if edad_ci !=.
										
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
																			
								}/*cierro quintil*/
							} /* cierro area */
						}	/* cierro sexo */			
				
										
	/*					
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
							
								foreach sexo of local sexos {
									foreach area of local areas {
										foreach quintil_ingreso of local quintil_ingresos {
											foreach grupo_etario of local grupo_etarios {
											
											
											local nivel_educativo No_aplica
											local etnicidad No_aplica
										
											/* Parameters of current disaggregation levels, used by all commands */
											global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
											noisily display "$tema: $current_slice"	

											//======== CALCULATE INDICATORS ================================================
												
											scl_pct ///
												tasa_ocupacion condocup_ci 1 if pet==1
										
											scl_pct ///
												tasa_desocupacion condocup_ci 2 if pea==1
										
											scl_pct ///
												tasa_participacion pea 1 if pet==1
										
											scl_pct ///
												ocup_suf_salario liv_wage 1 if liv_wage!=. & condocup_ci==1
										
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
												sal_menor_salmin menorwmin 1 if condocup_ci==1											

											scl_mean ///
												salmin_hora hsmin_ppp if condocup_ci==1 & hsmin_ppp!=.

											scl_mean ///
												salmin_mes salmm_ci if condocup_ci==1 & salmm_ci!=.

											scl_pct ///
												tasa_asalariados asalariado 1 if condocup_ci==1																	
											
											scl_pct ///
												tasa_independientes ctapropia 1 if condocup_ci==1																	

											scl_pct ///
												tasa_patrones patron 1 if condocup_ci==1																	

											scl_pct ///
												tasa_sinremuneracion sinremuner 1 if condocup_ci==1																	
											
											scl_pct ///
												subempleo subemp_ci 1 if condocup_ci==1																	
											
											scl_mean ///
												inglaboral_ppp_formales ylab_ppp if condocup_ci==1 & formal_ci==1
												
											scl_mean ///
												inglaboral_ppp_informales ylab_ppp if condocup_ci==1 & formal_ci==0

											scl_mean ///
												inglaboral_formales ylab_ci if condocup_ci==1 & formal_ci==1

											scl_mean ///
												inglaboral_informales ylab_ci if condocup_ci==1 & formal_ci==0
												
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
												tasa_agro agro 1 if condocup_ci==1																	
											
											scl_nivel ///
												nivel_agro agro 1 if condocup_ci==1
											
											scl_pct ///
												tasa_minas minas 1 if condocup_ci==1																	
	
											scl_nivel ///
												nivel_minas minas 1 if condocup_ci==1										
																			
											scl_pct ///
												tasa_industria industria 1 if condocup_ci==1		
												
											scl_nivel ///
												nivel_industria industria 1 if condocup_ci==1										

											scl_pct ///
												tasa_sspublicos sspublicos 1 if condocup_ci==1		

											scl_nivel ///
												nivel_sspublicos sspublicos 1 if condocup_ci==1										

											scl_pct ///
												tasa_construccion construccion 1 if condocup_ci==1		

											scl_nivel ///
												nivel_construccion construccion 1 if condocup_ci==1												

											scl_pct ///
												tasa_comercio comercio 1 if condocup_ci==1		

											scl_nivel ///
												nivel_comercio comercio 1 if condocup_ci==1	
												
											scl_pct ///
												tasa_transporte transporte 1 if condocup_ci==1		

											scl_nivel ///
												nivel_transporte transporte 1 if condocup_ci==1																			
																			
											scl_pct ///
												tasa_financiero financiero 1 if condocup_ci==1		

											scl_nivel ///
												nivel_financiero financiero 1 if condocup_ci==1																			
							
											scl_pct ///
												tasa_servicios servicios 1 if condocup_ci==1		

											scl_nivel ///
												nivel_servicios servicios 1 if condocup_ci==1																				
								
											scl_pct ///
												tasa_profestecnico profestecnico 1 if condocup_ci==1		

											scl_nivel ///
												nivel_profestecnico profestecnico 1 if condocup_ci==1																					

											scl_pct ///
												tasa_director director 1 if condocup_ci==1		

											scl_nivel ///
												nivel_director director 1 if condocup_ci==1																					
																
											scl_pct ///
												tasa_administrativo administrativo 1 if condocup_ci==1		

											scl_nivel ///
												nivel_administrativo administrativo 1 if condocup_ci==1																			
																																						
											scl_pct ///
												tasa_comerciantes comerciantes 1 if condocup_ci==1		

											scl_nivel ///
												nivel_comerciantes comerciantes 1 if condocup_ci==1																			

											scl_pct ///
												tasa_trabss trabss 1 if condocup_ci==1		

											scl_nivel ///
												nivel_trabss trabss 1 if condocup_ci==1	
												
											scl_pct ///
												tasa_trabagricola trabagricola 1 if condocup_ci==1		

											scl_nivel ///
												nivel_trabagricola trabagricola 1 if condocup_ci==1																									
									
											scl_pct ///
												tasa_obreros obreros 1 if condocup_ci==1		

											scl_nivel ///
												nivel_obreros obreros 1 if condocup_ci==1																									

											scl_pct ///
												tasa_ffaa ffaa 1 if condocup_ci==1		

											scl_nivel ///
												nivel_ffaa ffaa 1 if condocup_ci==1																									

											scl_pct ///
												tasa_otrostrab otrostrab 1 if condocup_ci==1		

											scl_nivel ///
												nivel_otrostrab otrostrab 1 if condocup_ci==1											

											scl_pct ///
												empleo_publico spublico_ci 1 if condocup_ci==1		

											scl_pct ///
												formalidad_2 formal_ci 1 if condocup_ci==1		
												
											scl_pct ///
												formalidad_3 formal_ci 1 if condocup_ci==1 & categopri_ci==3	

											scl_pct ///
												formalidad_4 formal_ci 1 if condocup_ci==1 & categopri_ci==2
																		
											scl_mean ///
											ingreso_hor_prom hwage if condocup_ci==1 
										
												
							} /* cierro grupo etario */	

											scl_pct ///
												pensionista_65_mas pensiont_ci 1 if age_65_mas==1	
																																					
											scl_nivel ///
												num_pensionista_65_mas age_65_mas 1 if pensiont_ci==1 								

											scl_pct ///
												pensionista_cont_65_mas pension_ci 1 if age_65_mas==1	
												
											scl_pct ///
												pensionista_nocont_65_mas pensionsub_ci 1 if age_65_mas==1	
																				
											scl_pct ///
												pensionista_ocup_65_mas pensiont_ci 1 if age_65_mas==1 & condocup_ci==1

											scl_mean ///
												y_pen_cont_ppp ypen_ppp "1" if ypen_ppp!=. & age_65_mas==1

											scl_mean ///
												y_pen_cont ypen_ci "1" if ypen_ci!=. & age_65_mas==1
												
											scl_mean ///
												y_pen_nocont ypensub_ci "1" if ypensub_ci!=. & age_65_mas==1
																			
											scl_mean ///
												y_pen_total ypent_ci "1" if ypent_ci!=. & age_65_mas==1
																			
										
										
									} /*cierro quintiles*/
								}/*cierro area*/
							} /* cierro sexo*/ 
					
	/*		
				
							************************************************
							  global tema "pobreza"
							************************************************
							// Division: SCL
							// Authors: Daniela Zuluaga
							************************************************
								
								local sexos Total Hombre Mujer 
								local areas	Total Rural Urbano
								local grupo_etarios	Total age_00_04 age_05_14 age_15_24 age_25_64 age_65_mas
								
								foreach sexo of local sexos {
									foreach area of local areas {
										foreach grupo_etario of local grupo_etarios {
											local quintil_ingreso No_aplica
											local nivel_educativo No_aplica
											local etnicidad No_aplica
											
											/* Parameters of current disaggregation levels, used by all commands */
											global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
											noisily display "$tema: $current_slice"	
								
								
								
												* Porcentaje poblacion que vive con menos de 3.1 USD diarios per capita*
												scl_pct ///
									            pobreza31 poor31 2 if poor31!=. 
															
												*Porcentaje poblacion que vive con menos de 5 USD diarios per capita
												scl_pct ///
									            pobreza poor 2 if poor!=. 
																
												* Porcentaje de la población con ingresos entre 5 y 12.4 USD diarios per capita*
												scl_pct ///
									            vulnerable vulnerable 2 if vulnerable!=. 
		
                                                 * Porcentaje de la población con ingresos entre 12.4 y 64 USD diarios per capita*
												scl_pct ///
									            middle middle 2 if middle!=. 
															
                                                 * Porcentaje de la población con ingresos mayores 64 USD diarios per capita*
												scl_pct ///
									            rich rich 2 if rich!=. 

			
										} /* cierro grupo_etario */	
									}/*cierro area*/
								} /* cierro sexo*/ 
				
								local areas  Total Urbano Rural
													
								
									foreach area of local areas {
										local sexo No_aplica
										local grupo_etario No_aplica
										local quintil_ingreso No_aplica
										local nivel_educativo No_aplica
										local etnicidad No_aplica
										
											/* Parameters of current disaggregation levels, used by all commands */
												global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
												noisily display "$tema: $current_slice"	
															
													
												 /* Coeficiente de Gini para el ingreso per cápita del hogar*/
												scl_inequal ///
												ginihh pc_ytot_ch gini 
							
												/* Coeficiente de Gini para salarios por hora*/
												scl_inequal ///
												gini ylmhopri_ci gini 
								
												/* Coeficiente de theil para el ingreso per cápita del hogar*/
												 scl_inequal ///
												theilhh pc_ytot_ch theil 
								
												/* Coeficiente de theil para salarios por hora*/
												scl_inequal ///
												theil ylmhopri_ci theil 
															
												* Porcentaje del ingreso laboral del hogar contribuido por las mujeres 
												scl_mean ///
												ylmfem_ch shareylmfem_ch if jefe_ci==1 & shareylmfem_ch!=. 
															 
															
									}/*cierro area*/
							
																										
								
								local quintil_ingresos Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 
								local areas Total Rural Urbano
										
								foreach quintil_ingreso of local quintil_ingresos {
									foreach area of local areas {
										local sexo No_aplica
										local nivel_educativo No_aplica
										local grupo_etario No_aplica
										local etnicidad No_aplica
										
										
											/* Parameters of current disaggregation levels, used by all commands */
													global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
													noisily display "$tema: $current_slice"	
													
													
													/* Porcentaje de hogares que reciben remesas del exterior */
													scl_pct ///
														indexrem indexrem 2 

							
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
						
								
								foreach quintil_ingreso of local quintil_ingresos {
									foreach area of local areas {
										local sexo No_aplica
										local nivel_educativo No_aplica
										local grupo_etario No_aplica
										local etnicidad No_aplica
										
											/* Parameters of current disaggregation levels, used by all commands */
											global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
											noisily display "$tema: $current_slice"	
								
					
						
											   * % de hogares con servicio de agua de acueducto*
											   scl_pct ///
									           aguared_ch aguared_ch 2 if jefe_ci==1 & aguared_ch!=. 
																
											   * % de hogares con acceso a servicios de saneamiento mejorados*
											   scl_pct ///
									           des2_ch des2_ch 2 if jefe_ci==1 & des2_ch!=. 							
																														
											   * % de hogares con electricidad *
											   scl_pct ///
									           luz_ch luz_ch 2 if jefe_ci==1 &  luz_ch!=. 
																												
										       * % hogares con pisos de tierra *
										        scl_pct ///
									            dirtf_ch dirtf_ch 2 if jefe_ci==1 &  dirtf_ch!=. 
														
											   * % de hogares con refrigerador *
											    scl_pct ///
									            refrig_ch freezer_ch 2 if jefe_ci==1 &  freezer_ch!=. 

												* % de hogares con carro particular*
												scl_pct ///
									            auto_ch auto_ch 2 if jefe_ci==1 &  auto_ch!=. 													
																
												* % de hogares con acceso a internet *
												scl_pct ///
									            internet_ch internet_ch 2 if jefe_ci==1 &  internet_ch!=. 
																			
												* % de hogares con teléfono celular*
												scl_pct ///
									            cel_ch cel_ch 2 if jefe_ci==1 &  cel_ch!=.
																
											    * % de hogares con techos de materiales no permanentes*
												scl_pct ///
									            techonp_ch techonp_ch 2 if jefe_ci==1 &  techonp_ch!=.

												* % de hogares con paredes de materiales no permanentes*
											    cap scl_pct ///
									            parednp_ch parednp_ch 2 if jefe_ci==1 &  parednp_ch!=.

												* Número de miembros por cuarto*
												scl_mean ///
								                hacinamiento_ch hacinamiento_ch if jefe_ci==1 & hacinamiento_ch!=. 
												
												*% de hogares con estatus residencial estable *
												scl_pct ///
									            estable_ch estable_ch 2 if jefe_ci==1 &  estable_ch!=.
												
			
											}/*cierro area*/		
										} /*cierro quintil_ingreso*/
								

								
		*/			
								
							    ************************************************
								  global tema "diversidad"
								************************************************
								// Division: GDI
								// Authors: Nathalia Maya, Maria Antonella Pereira, Cesar Lins de Oliveira
								************************************************
								local sexos 	Total Hombre Mujer
								local areas 	Total Rural Urbano
								
								
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
													pafro_ci afroind_ci "Afro-descendiente"
												/* Porcentaje población indígena */
												scl_pct ///
												    pindi_ci afroind_ci "Indígena" 
												/* Porcentaje población ni Afrodescendiente ni indígena*/
												scl_pct ///
												    pnoafronoindi_ci afroind_ci "Otros"
                                              	/* Porcentaje población Afro-indígena (Garífuna)*/
											    scl_pct ///
												   pafroindi_ci afroind_ci "Afro-indígena"
                                                /* Porcentaje de hogares con jefatura afrodescendiente */ 
										        scl_pct ///
												   pjefe_afro_ch afroind_ch "Afro-descendiente" 
												/* Porcentaje de hogares con jefatura indígena */ 
										        scl_pct ///												   
												   pjefe_indi_ch afroind_ch "Indígena" 
											    /* Porcentaje de hogares con jefatura ni afrodescendiente ni indígena*/ 
									            scl_pct ///												   
                                                   pjefe_noafronoindi_ch afroind_ch "Otros"
											    /* Porcentaje de hogares con jefatura Afro-indígena (Garífuna)*/ 
											    scl_pct ///												   
												   pjefe_afroindi_ch afroind_ch "Afro-indígena"
                                               /* Porcentaje de personas que reportan tener alguna dificultad en actividades de la vida diaria */
											    scl_pct ///												   
                                                   pdis_ci dis_ci "Con Discapacidad"
												/* Porcentaje de hogares con miembros que reportan tener alguna dificultad en realizar actividades de la vida diaria. */
                                                scl_pct ///
												   pdis_ch dis_ch "Con Discapacidad" 
																
												
											}/*cierro area*/		
										} /*cierro sexo*/
							
									
								
								************************************************
								  global tema "migracion"
								************************************************
								// Division: MIG
								// Authors: Fernando Morales Velandia
								************************************************
								local sexos 	Total /* Hombre Mujer */
								local areas 	Total /* Rural Urbano */
								
								
								foreach sexo of local clases {
									foreach area of local clases2 {
									
										local quintil_ingreso No_aplica
										local nivel_educativo No_aplica
										local grupo_etario No_aplica
										local etnicidad No_aplica
										
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
								
											}/*cierro clases3*/		
										} /*cierro clases2*/
								
							
						
								************************************************
								  global tema "programas sociales"
								************************************************
								// Division: SPH
								// Authors: Carolina Rivashe
								************************************************
								local sexos Total Hombre Mujer 
								local areas Total Rural Urbano 
								local quintil_ingresos	Total gpo_ingneto1 gpo_ingneto2 gpo_ingneto3 gpo_ingneto4 
								
								foreach sexo of local sexos {
									foreach area of local areas {
										foreach quintil_ingreso of local quintil_ingresos {

										local nivel_educativo No_aplica
										local grupo_etario No_aplica
										local etnicidad No_aplica
																					
											/* Parameters of current disaggregation levels, used by all commands */
											global current_slice `pais' `ano' `geografia_id' `sexo' `area' `nivel_educativo' `quintil_ingreso' `grupo_etario' `etnicidad'
											noisily display "$tema: $current_slice"	
									
											* Porcentaje de la población que beneficiario de PTMC *
												 scl_pct ///
													pmtc ptmc_ch "1" if ptmc!=. 
								
											* Porcentaje de la población en hogares con adultos mayores beneficiarios de PNC *
												 scl_pct ///
													pnc_ch	pension_ch "1" if pension_ch!=. & mayor64_ch==1
											* Porcentaje de adultos mayores beneficiarios de PNC *
												 scl_pct ///
													pnc	pension_ci "1" if pension_ch!=. & mayor64_ci==1
													
													
												}/*cierro quintil_ingreso*/		
										} /*cierro areas*/
								} /*cierro sexos*/
								
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
													
											* Porcentaje de beneficiaios PTMC en pobreza extrema (# PTMC en PE / Total PTMC)*
												scl_ratio ///
													ptmc_pe ptmc_ingneto1 ptmc_ch
													
											* Porcentaje de beneficiaios PTMC en pobreza moderada (# PTMC en PM / Total PTMC)*
												scl_ratio ///
													ptmc_pm ptmc_ingneto2 ptmc_ch
													
											* Porcentaje de beneficiaios PTMC en vulerabilidad (# PTMC en vulerabilidad / Total PTMC)*
												scl_ratio ///
													ptmc_v ptmc_ingneto3 ptmc_ch
													
											* Porcentaje de beneficiaios PTMC no pobres (# PTMC no pobres / Total PTMC)*
												scl_ratio ///
													ptmc_np ptmc_ingneto4 ptmc_ch													
											
									}/*cierro areas*/		
								} /*cierro sexos*/
							
						*/ 
			


 
			postclose `ptablas_`pais''

			use `tablas_`pais'', clear
			* destring valor muestra, replace
			recode valor 0=.
			* recode muestra 0=.
			save `tablas_`pais'', replace 
			
			use "${out}\indicadores_encuestas_hogares_scl_`pais'.dta"
			append using  `tablas_`pais''
		

			save "${out}\indicadores_encuestas_hogares_scl_`pais'.dta", replace 
			
			
			*}/*cierro encuestas*/
		} /* cierro anos */
	} /* cierro paises */
*} /* cierro quietly */

/*
/*====================================================================
                        2: Save and Export results
====================================================================*/
local paises  ARG BHS BOL  BRA  BLZ BRB CHL COL CRI ECU SLV GTM GUY HTI HND JAM MEX NIC PAN PRY PER DOM SUR TTO URY VEN 
foreach pais of local paises { 
	        
			
			use "${out}\indicadores_encuestas_hogares_scl_`pais'.dta"
			include "${input}\dataframe_format.do"
			export delimited using "${out}\\indicadores_encuestas_hogares_`pais'.csv", replace
			unicode convertfile "${out}\indicadores_encuestas_hogares_`pais'.csv" "${covidtmp}\indicadores_encuestas_hogares_`pais'.csv", dstencoding(latin1) replace 
						
} 

* guardo el archivo temporal
* (this file will be ignored by GitHub)


* Variables de formato 

***** include "${input}/var_formato.do"
***** order tiempo tiempo_id pais_id geografia_id clase clase_id area area_id nivel nivel_id tema indicador tipo valor muestra


*carpeta tmp

***** export delimited using  "${covidtmp}/indicadores_encuestas_hogares_scl.csv", replace
***** unicode convertfile "${covidtmp}/indicadores_encuestas_hogares_scl.csv" "${output}/indicadores_encuestas_hogares_scl_converted.csv", dstencoding(latin1) replace 
***** save "${covidtmp}/indicadores_encuestas_hogares_scl.dta", replace


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
		
			export delimited using "${covidtmp}//indicadores_encuestas_hogares_`div'.csv", replace
			sleep 1000
			restore
						
} 
 
 */
 		

/* End
