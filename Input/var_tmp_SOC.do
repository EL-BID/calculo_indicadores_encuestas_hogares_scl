/*=============================================================================================
project:       Edades niveles de desagregación indicadores de pobreza, demografia y vivienda
Author:        Angela Lopez 
Dependencies:  SCL/EDU/LMK - IDB 
-----------------------------------------------------------------------------------------------
Creation Date:    14 Febrero 2020 - 11:38:53
Modification Date:   
Do-file version:    01
References:          
Output:             Excel-DTA file
===============================================================================================*/

/*=============================================================================================
                        Program description: para incluir en el programa maestro  
===============================================================================================*/


	* 1.Edades niveles de desagregación indicadores de pobreza y desigualdad
			
				gen age_00_04  = inrange(edad_ci,0,4) 
				gen age_05_14  = inrange(edad_ci,5,14) 
					
	* 2. Pobreza 
		* 2.1 Menos de 3.1 dolares 		
				gen     poor31 =0 if pc_ytot_ch!=.
				replace poor31 =1 if pc_ytot_ch<lp31_ci
				
		* 2.2 Menos de 5 dolares
				gen      poor =0 if pc_ytot_ch!=.
				replace  poor =1 if pc_ytot_ch<lp5_ci
		* 2.3 Entre 5 - 12 USD
				gen vulnerable=0 if pc_ytot_ch!=.
                replace vulnerable=1 if ((pc_ytot_ch>=lp5_ci) & (pc_ytot_ch<lp31_ci*4))
		* 2.4 Entre 12.4 y 62
				gen middle=0 if pc_ytot_ch!=.
				replace middle=1 if ((pc_ytot_ch>=lp31_ci*4) & (pc_ytot_ch<lp31_ci*20))
				
		
		
		