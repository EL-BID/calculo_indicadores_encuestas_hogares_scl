
/*====================================================================
project:       Imputación de la variable afroind_ci 
Author:        Maria Antonella Pereira y Nathalia Maya
Dependencies:  SCL/GDI - IDB 
----------------------------------------------------------------------
Creation Date:    22 Abril 2021 
Modification Date:   
Do-file version:    01
References:          
Output:             Excel-DTA file
====================================================================*/

/*=================================================================================
 Program description: imputando valores de afroind_ci del jefe del hogar a los hijos (en países con restricciones de edad) 
===================================================================================*/

replace afroind_ci=afroind_ch if afroind_ci==9 & relacion_ci==3 //se generaron missings por los jefes de hogar que tienen missings
replace afroind_ci=. if afroind_ci==9

