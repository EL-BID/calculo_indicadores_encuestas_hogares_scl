/*====================================================================
project:       Armonizacion actualización plataformas SCL
- Test of loop structure with programs
====================================================================*/

version 16.0
* cap ssc install estout 


/**** if composition utility function ****************************
 scl_if_compose pais ano if ...
 will return
  if ... & pais_c=="pais" & anio_c==ano
 in s(xif) macro.
 Needs to clear manually calling sreturn clear
******************************************************************/
capture program drop scl_if_compose
program scl_if_compose, sclass
 syntax anything [if]
 local pais : word 1 of `anything'
 local ano : word 2 of `anything'
 
 if "`if'"=="" {
     sreturn local xif `"if pais_c=="`pais'" & anio_c==`ano'"'
  }
  else {
	 sreturn local xif `"`if' & pais_c=="`pais'" & anio_c==`ano'"'
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
  local indname : word 1 of `anything'
  local indvar : word 2 of `anything'
  local indcat : word 3 of `anything'
  local pais : word 4 of `anything'
  local ano : word 5 of `anything'
  
  scl_if_compose `pais' `ano' `if'
  local xif `"`s(xif)'"'
   
  capture quietly estpost tab `indvar' [w=round(factor_ch)] `xif'
  
  if _rc == 0 {
    mat temp=e(pct)
    local valor = temp[1,colnumb(e(pct),`"`indcat'"')]
    /* display `" `indname' - Percentage of `indcat' : `valor' (`indvar')"' */
	post $output ("`ano'") ("`pais'")  ("$tema") ("`indname'") (`"% `indvar'==`indcat'"') (`valor')
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
  local indname : word 1 of `anything'
  local indvar : word 2 of `anything'
  local pais : word 3 of `anything'
  local ano : word 4 of `anything'
  
  scl_if_compose `pais' `ano' `if'
  local xif `"`s(xif)'"'
 
  capture quietly sum `indvar' [w=round(factor_ch)] `xif'
  
  capture local valor = `r(sum_w)'
  if _rc == 0 {
	/* display `" `indname' - Mean of `indcat' : `valor' (`indvar')"' */
	post $output ("`ano'") ("`pais'") ("$tema") ("`indname'") ("sum of `indvar'") (`valor') 
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
  local indname : word 1 of `anything'
  local indvar : word 2 of `anything'
  local pais : word 3 of `anything'
  local ano : word 4 of `anything'
  
  scl_if_compose `pais' `ano' `if'
  local xif `"`s(xif)'"'
 
  capture quietly sum `indvar' [w=round(factor_ch)] `xif'
  
  capture local valor = `r(mean)'
  if _rc == 0 {
	/* display `" `indname' - Mean of `indcat' : `valor' (`indvar')"' */
	post $output ("`ano'") ("`pais'") ("$tema") ("`indname'") ("mean of `indvar'") (`valor') 
  }
end


/*====================================================================
                        1: Set Up
====================================================================*/

local mydir = c(pwd)

tempfile tablas
tempname ptablas

postfile `ptablas' str4 tiempo_id str3 pais_id str20 tema str10 indicador str20 description valor using "`tablas'", replace

local paises PRY URY
local anos 2017 2018

global output `ptablas'

display "`mydir'\calculo_indicadores_encuestas_hogares_scl\Input"



/*====================================================================
                        2: Main Loop
====================================================================*/
foreach pais of local paises {
	foreach ano of local anos {
		
		 // use survey of current country / year
		
		  display "Calculating country: `pais' - year : `ano'"
		  	
			
			****************************
			global tema "demografia"
			****************************
			
			/* Porcentaje de población femenina*/
			scl_pct ///
			    pmujer sexo_ci "Mujer" `pais' `ano'
			
			
						
			****************************
			global tema "laboral"
			****************************
			
			/* Ingreso mensal promedio de las mujeres */
			scl_mean  ///
				ylmfem ylm_ci `pais' `ano' if sexo_ci==2
				
			/* Ingreso mensal promedio de los hombres */
			scl_mean ///
				ylmmal ylm_ci `pais' `ano' if sexo_ci==1
				
			/* Nivel de cotizantes */
			scl_nivel ///
				ncot cotizando_ci `pais' `ano'
				
			
			
			****************************
			global tema "diversidad"	
			****************************
			
			/* Porcentaje de población indigena */
			scl_pct ///
			    pindi raza_ci "Indigena" `pais' `ano'
			
			
		
	}
}



/*====================================================================
                        3: Finish
====================================================================*/
sreturn clear

postclose `ptablas'
use "`tablas'", clear




