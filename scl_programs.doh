
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
	 sreturn local xif `"`if' & `sexo'==1 & `area'==1 & `nivel_educativo'==1 & `quintil_ingreso'==1 & `grupo_etario'==1 & `etnicidad'==1 "'
  }
  else {
	 sreturn local xif `"if `sexo'==1 & `area'==1 & `nivel_educativo'==1 & `quintil_ingreso'==1 & `grupo_etario'==1 & `etnicidad'==1 "'
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
	local valor = valores[1,colnumb(valores,`"`indcat'.`indvar'"')]*100
	
	estat cv
	mat error_standar=r(se)
	local se = error_standar[1,colnumb(error_standar,`"`indcat'.`indvar'"')]*100
	
	mat cv=r(cv)
	local cv = cv[1,colnumb(cv,`"`indcat'.`indvar'"')]
	
	estat size
	mat muestra=r(_N)
	local muestra = muestra[1,1]
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
	local valor =valores[1,1] 
	
	estat cv
	mat error_standar=r(se)
	local se = error_standar[1,1] 
	
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
  						
	capture quietly svylorenz `indvar'  `xif'
	if _rc == 0 {
    local valor =e(gini)
	local se = e(se_gini)
	local cv =.
	local muestra=.
	
	post $output ("`ano'") ("`pais'") ("`pais'-$encuestas") ("`geografia_id'") ("`sexo'") ("`area'") ("`quintil_ingreso'") ("`nivel_educativo'") ("`grupo_etario'") ("`etnicidad'") ("$tema") ("`indname'") (`"`typeind' of `indvar'"') (`valor') (`se') (`cv') (`muestra')
	
	}
	if _rc != 0 {
   /* generate a line with missing value */
	post $output ("`ano'") ("`pais'") ("`pais'-$encuestas") ("`geografia_id'") ("`sexo'") ("`area'") ("`quintil_ingreso'") ("`nivel_educativo'") ("`grupo_etario'") ("`etnicidad'") ("$tema") ("`indname'") (`"`typeind' of `indvar'"') (.) (.) (.) (.)
	}
  
 end 