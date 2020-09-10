/*====================================================================
project:       Armonizacion microdatos SCL
Author:        Angela Lopez 
Dependencies:  SCL/EDU/LMK - IDB 
----------------------------------------------------------------------
Creation Date:    17 jul 2020 - 11:47:53
Modification Date:   
Do-file version:    01
References:          
Output:             Excel-DTA file
====================================================================*/

/*====================================================================
                        0: Program set up
====================================================================*/

* Variables actualizadas hasta el 7/20/2020

/*====================================================================
                        1: Create dummy dataset 
====================================================================*/

tempfile microdato
tempname pmicrodato


postfile `pmicrodato' str100(pais_c anio_c) using `microdato', replace

postclose `pmicrodato'
use `microdato', clear
destring anio_c, replace

save "${covidtmp}\microdatos_encuestas_hogares_scl.dta", replace 
 

 
 
 