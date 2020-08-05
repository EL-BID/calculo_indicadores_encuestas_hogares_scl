
/*====================================================================
project:       Edades teóricas simples y cotumizadas para plataforma CIMA
Author:        Angela Lopez 
Dependencies:  SCL/EDU - IDB 
----------------------------------------------------------------------
Creation Date:    07 Octubre 2019 - 11:47:53
Modification Date:   
Do-file version:    01
References:          
Output:             Excel-DTA file
====================================================================*/

/*=================================================================================
                        Program description: para incluir en el programa maestro  
===================================================================================*/


* 1. Edades teoricas CIMA
    * 1.1. Asistencia  

				gen age_pres   = inrange(edad_ci,4,5)
				gen age_prim   = inrange(edad_ci,6,11)
				gen age_seco   = inrange(edad_ci,12,17)
				gen age_seco_b = inrange(edad_ci,12,14)
				gen age_seco_a = inrange(edad_ci,15,17)
				gen age_tert   = inrange(edad_ci,18,23)
				gen age_terms  = inrange(edad_ci,18,20)
	
	*1.2. Terminación - se disutió la NECESIDAD de que sean necesariamente CUSTOMIZADAS las siguientes se usaban anteriormente:	
				
				gen age_term_p = inrange(edad_ci,16,18)
				gen age_term_s = inrange(edad_ci,21,22)		
				
	*1.3. Útiles para otos indicadores:			
				
				gen age_25_mas = edad_ci >=25          // Población mayor a 25
				gen age_15_24 = inrange(edad_ci,15,24) // Ninis1
				gen age_15_29 = inrange(edad_ci,15,29) // Ninis 2 
				gen age_18_24 = inrange(edad_ci,18,24) 
				
	* 1.4 útiles para optimizar el codigo maestro 		
				gen age_4_5   = inrange(edad_ci,4,5)
				gen age_6_11  = inrange(edad_ci,6,11)
				gen age_12_14 = inrange(edad_ci,12,14)
				gen age_15_17 = inrange(edad_ci,15,17)
				gen age_18_23 = inrange(edad_ci,18,23)
				
* 2. Niveles teóricos CIMA

	* 2.1. Asistencia 
	
				gen asis_pres   = asispre_ci
				gen asis_prim   = 1 if aedu_ci>=0  & aedu_ci<  6  & aedu_ci<. & asiste_ci==1 
				gen asis_seco   = 1 if aedu_ci>=6  & aedu_ci<  12 & aedu_ci<. & asiste_ci == 1
				gen asis_seco_b = 1 if aedu_ci>=6  & aedu_ci<= 8  & asiste_ci == 1
				gen asis_seco_a = 1 if aedu_ci>=9  & aedu_ci<= 11 & asiste_ci == 1
				gen asis_tert   = 1 if aedu_ci>=12 & aedu_ci<   . & asiste_ci == 1
				
	* leavers Jóvenes entre los 18-24 años que terminaron hasta que secundaria baja y no están asistiendo a ningún nivel de educación.
				g leavers=.
				replace leavers = 1 if age_18_24 == 1 & (aedu_ci > 0 & aedu_ci<=9) & asiste_ci == 0
				
	* Ninis 
	
				g nini=.
				replace nini = 1 if asiste_ci==0 & condocup_ci == 3

				
* 4. Nivel educativo de la poblacion  
 
				gen anos_0 			= 1 if  aedu_ci==0  & (aedu_ci !=. | edad_ci !=.)
				gen anos_1_5 		= 1 if (aedu_ci>=1  & aedu_ci <=5) & (aedu_ci !=. | edad_ci !=.)
				gen anos_6			= 1 if  aedu_ci==6  & (aedu_ci !=. | edad_ci !=.)
				gen anos_7_11 		= 1 if (aedu_ci>=7  & aedu_ci <=11) & (aedu_ci !=. | edad_ci !=.) 
				gen anos_12 		= 1	if  aedu_ci==12 & (aedu_ci !=. | edad_ci !=.)
				gen anos_13_o_mas	= 1 if  aedu_ci>=13 & (aedu_ci !=. | edad_ci !=.)
	
* ==========================================================================================================================================
*                                                                 Edades y niveles costumizados 
* ==========================================================================================================================================				

* 3. Edades teóricas Costumizadas por país y nivel 
	* 3.1 Primaria por grupo de pasises 
							
		* Edad teorica y asistencia   
			
			gen  age_prim_c = inrange(edad_ci,6,11)
		    gen asis_prim_c = 1 if aedu_ci>=0  & aedu_ci<  6  & aedu_ci<. & asiste_ci==1 	
			
		   
		   	if  "`pais'" == "COL" | "`pais'" == "BLZ"  { // Estos países la educación primaria va hasta quinto grado 
			drop age_prim_c asis_prim_c
			gen  age_prim_c   = inrange(edad_ci,6,10)
			gen  asis_prim_c = 1 if aedu_ci>=0  & aedu_ci<  5  & aedu_ci<. & asiste_ci==1 
			}
		
			if "`pais'" == "CHL" | "`pais'" == "DOM" | "`pais'" == "BRA"   { // Estos países la educación primaria va hasta octavo grado 
			drop age_prim_c asis_prim_c
			gen  age_prim_c   = inrange(edad_ci,6,13)
			gen  asis_prim_c = 1 if aedu_ci>=0  & aedu_ci<  8  & aedu_ci<. & asiste_ci==1 
			}
			
			if "`pais'" == "SLV" | "`pais'" == "GTM"  | "`pais'" == "PRY"   { // Estos países la educación primaria comienza a los 7 
			drop age_prim_c
			gen  age_prim_c   = inrange(edad_ci,7,12)
			}
				
		* Sobreedad 

			gen     age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 0 & edad_ci>=8 & asispre_ci != 1
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 1 & edad_ci>=9
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 2 & edad_ci>=10
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 3 & edad_ci>=11
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 4 & edad_ci>=12
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 5 & edad_ci>=13
		
		
		
			if "`pais'" == "BHS" | "`pais'" == "BRB"    {
			* Estos países comienzan la primaria a los 5 anios 
			replace age_prim_sobre = . 
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 0 & edad_ci>=7 & asis_pres !=1
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 1 & edad_ci>=8
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 2 & edad_ci>=9
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 3 & edad_ci>=10
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 4 & edad_ci>=11
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 5 & edad_ci>=12			
			}
			
			if "`pais'" == "GUY" {
			replace age_prim_sobre = . 
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 0 & edad_ci>=8 & asis_pres !=1
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 2 & edad_ci>=10
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 3 & edad_ci>=11
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 4 & edad_ci>=12
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 5 & edad_ci>=13
			}
		
			if  "`pais'" == "COL"   {
			* estos países la educación primaria va hasta quinto grado
			replace age_prim_sobre = . if aedu_ci > 4
			}
			
			if "`pais'" == "SLV" | "`pais'" == "GTM"  | "`pais'" == "PRY"   {
			* Estos países copmienzan la primaria desde los 7 anios y estudian 6 anios de primaria
			replace age_prim_sobre = . 
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 0 & edad_ci>=9 & asispre_ci != 1
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 1 & edad_ci>=10
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 2 & edad_ci>=11
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 3 & edad_ci>=12
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 4 & edad_ci>=13
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 5 & edad_ci>=14	
			* la asistencia costumizada es la misma del default
			}
			
			if "`pais'" == "DOM" | "`pais'" == "CHL" | "`pais'" == "BRA" {
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 6 & edad_ci>=14
			replace age_prim_sobre = 1 if asiste_ci == 1 & aedu_ci== 7 & edad_ci>=15
			}
					
		* Terminación 
		
		    gen age_term_p_c  	= inrange(edad_ci,15,17)
			
			if "`pais'" == "BHS" | "`pais'" == "BRB"   | "`pais'" == "COL" {
			drop age_term_p_c 
			gen age_term_p_c  	= inrange(edad_ci,14,16)
			}
						   
			if "`pais'" == "SLV" | "`pais'" == "GTM" | "`pais'" == "PRY"  {
			drop age_term_p_c 
			gen age_term_p_c    = inrange(edad_ci,16,18)
			}
			
			if "`pais'" == "DOM" | "`pais'" == "CHL" | "`pais'" == "BLZ" | "`pais'" == "BRA" {
			drop age_term_p_c 
			gen age_term_p_c    = inrange(edad_ci,17,19)
			}
	
		
	* 3.2 Secundaria por grupo de pasises 
	
	* Edad teórica y asistencia 
			
			gen  age_seco_c = inrange(edad_ci,12,17)
		    gen asis_seco_c = 1 if aedu_ci>=6 & aedu_ci<12 & aedu_ci<. & asiste_ci == 1 	
		   
		   	if "`pais'" == "BHS" | "`pais'" == "BLZ" | "`pais'" == "COL" | "`pais'" == "GUY" | "`pais'" == "JAM" | "`pais'" == "NIC" |"`pais'" == "BRA"  {  
			drop age_seco_c asis_seco_c
			gen  age_seco_c   = inrange(edad_ci,11,16)
			gen  asis_seco_c  = 1 if aedu_ci>=5 & aedu_ci<11 & aedu_ci<. & asiste_ci == 1  
			}
		
			if "`pais'" == "CHL" | "`pais'" == "DOM"   { // Estos países la educación primaria va hasta octavo grado 
			drop age_seco_c asis_seco_c
			gen  age_seco_c   = inrange(edad_ci,14,17)
			gen  asis_seco_c = 1 if aedu_ci>=8  & aedu_ci<  12  & aedu_ci<. & asiste_ci==1 
			}
			
			if "`pais'" == "SLV" | "`pais'" == "GTM"  | "`pais'" == "PRY"   { // Estos países la educación primaria comienza a los 7 
			drop age_seco_c 
			gen  age_seco_c = inrange(edad_ci,13,17)
			}		
		
	
	* Terminación 
	
			cap gen age_term_s_c    = inrange(edad_ci,21,23)
		
			if "`pais'" == "BHS" | "`pais'" == "BLZ" | "`pais'" == "COL" | "`pais'" == "GUY" | "`pais'" == "JAM" | "`pais'" == "NIC" |"`pais'" == "BRA"  {
			drop age_term_s_c 
			cap gen age_term_s_c    = inrange(edad_ci,20,22)
			}
			
			if "`pais'" == "SLV" | "`pais'" == "HTI" | "`pais'" == "PRY" | "`pais'" == "BRB" {
			drop age_term_s_c 
			gen age_term_s_c    = inrange(edad_ci,22,24)			
			}

				
		
		
	* 3.3 Terciaria por grupo de pasises
			

	* Edad teórica y asistencia 
			
			gen  age_tert_c = inrange(edad_ci,18,23)
		    gen asis_tert_c = 1 if aedu_ci>=12 & aedu_ci<. & asiste_ci == 1 	
		   
		   	if "`pais'" == "BHS" | "`pais'" == "BLZ" | "`pais'" == "COL" | "`pais'" == "GUY" | "`pais'" == "JAM" | "`pais'" == "NIC"  {  
			drop age_tert_c
			gen  age_tert_c   = inrange(edad_ci,17,22)
			}
		
			
			if "`pais'" == "SLV" | "`pais'" == "PRY"   { // Estos países la educación primaria comienza a los 7 
			drop age_tert_c 
			gen  age_tert_c = inrange(edad_ci,19,24)
			}			   
		   
					
			if "`pais'" == "GUY" | "`pais'" == "BHS" | "`pais'" == "BLZ" | "`pais'" == "COL" |  "`pais'" == "JAM" | "`pais'" == "NIC" | "`pais'" == "GTM" { 
			drop asis_tert_c
			gen asis_tert_c = 1 if aedu_ci>=11 & aedu_ci<. & asiste_ci == 1
			}



				
			
				
				* condición de ocupación de los leavers
		******** edupc_ci: Educación primaria completa
		******** edusi_ci: Educación secundaria incompleta
		******** edusc_ci: Educación secundaria completa
		******** eduui_ui: Educación superior incompleta
		******** eduuc_ui: Educación superior completa
		******** edus1c_ci: primer ciclo de secundaria completa
		
				gen tprimaria        = (edupc_ci  ==1 | edusi_ci==1 | edusc_ci==1 | eduui==1 | eduuc==1) 
				gen tsecundaria      = (edusc_ci  ==1 | eduui==1 | eduuc==1)
				gen no_tsecundaria   = (edusc_ci  ==0 | eduui==0 | eduuc==0)
				gen tsecundaria_baja = (edus1c_ci ==1 | edusc_ci  ==1 | eduui==1 | eduuc==1)
				
				gen tprimaria_cond    = tprimaria   if inrange(edad_ci,15,17)
				gen tsecundaria_cond  = tsecundaria if inrange(edad_ci,18,20)
