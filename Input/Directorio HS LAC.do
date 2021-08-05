/*====================================================================
project:       Directorio de encuestas y paises LAC
Author:        Angela Lopez 
----------------------------------------------------------------------
Creation Date:    19 Jul 2018 - 11:14:13
====================================================================*/

/*====================================================================
                        0: Program set up
====================================================================*/

* Encuestas 

	if "`pais'" == "ARG"                       global encuestas EPHC
	if "`pais'" == "BHS" | "`pais'" == "BLZ" | "`pais'" == "JAM" | "`pais'" == "GUY" global encuestas LFS
	if "`pais'" == "BRB"                       global encuestas CLFS
	if "`pais'" == "BOL"                       global encuestas ECH
	
	if "`pais'" == "BRA" & ("`ano'" < "2016")  global encuestas PNAD
	if "`pais'" == "BRA" & ("`ano'" >= "2016") global encuestas PNADC
	
	if "`pais'" == "CHL"                       global encuestas CASEN
	if "`pais'" == "COL"                       global encuestas GEIH
	
	if "`pais'" == "CRI"  & ("`ano'" >= "2005" & "`ano'" <= "2009") global encuestas EHPM
	if "`pais'" == "CRI"  & ("`ano'" > "2009") global encuestas ENAHO
	
	if "`pais'" == "ECU"                       global encuestas ENEMDU
	if "`pais'" == "SLV"                       global encuestas EHPM
	if "`pais'" == "GTM"                       global encuestas ENEI
	
	if "`pais'" == "HND"                       global encuestas EPHPM
	if "`pais'" == "MEX"                       global encuestas ENIGH                      
	
	if "`pais'" == "NIC" & ("`ano'" == "2009" | "`ano'" == "2014") global encuestas EMNV
	if "`pais'" == "NIC" & ("`ano'" <  "2009" | ("`ano'" > "2009" & "`ano'" < "2014") | "`ano'" > "2014") global encuestas ECH
	
	if "`pais'" == "PAN" & ("`ano'" >= "2005" & "`ano'" <= "2010" ) global encuestas EH
	if "`pais'" == "PAN" & ("`ano'" >  "2010") global encuestas EHPM
	
	if "`pais'" == "PRY" & ("`ano'" <  "2018") global encuestas EPH
	if "`pais'" == "PRY" & ("`ano'" == "2018") global encuestas EPHC
	
	
	if "`pais'" == "PER"                       global encuestas ENAHO
	
	if "`pais'" == "DOM" & ("`ano'" >= "2017") global encuestas ENCFT
	if "`pais'" == "DOM"  & ("`ano'" < "2017") global encuestas ENFT
	
	if "`pais'" == "SUR"                       global encuestas SLC
	if "`pais'" == "TTO"                       global encuestas CSSP
	if "`pais'" == "URY"                       global encuestas ECH
	
	if "`pais'" == "VEN" & ("`ano'" <= "2015") global encuestas EHM
	if "`pais'" == "VEN" & ("`ano'" >  "2015") global encuestas ENCOVI

* Rondas

* Argentina 
	if "`pais'" == "ARG" &("`ano'" == "2015" )   global rondas s1
	if "`pais'" == "ARG" &("`ano'" >= "2005" & "`ano'" <= "2014") | "`ano'" >= "2016"  global rondas s2
* Bahamas
	if "`pais'" == "BHS" | "`pais'" == "BLZ" | "`pais'" == "BRB" | "`pais'" == "SLV" | "`pais'" == "PER" | "`pais'" == "TTO" | "`pais'" == "URY" global rondas a
* Bolivia
	if "`pais'" == "BOL" & ("`ano'" >= "2005" & "`ano'" <= "2011")  global rondas m11_m12
	if "`pais'" == "BOL" & ("`ano'" > "2011")  global rondas m11
* Brasil 
	if "`pais'" == "BRA" & ("`ano'" < "2016")   global rondas m9
	if "`pais'" == "BRA" & ("`ano'" >= "2016")  global rondas a
* Chile
	if "`pais'" == "CHL" & ("`ano'" == "2006" | "`ano'" == "2009" ) global rondas m11_m12
	if "`pais'" == "CHL" & ("`ano'" == "2008" | "`ano'" >= "2010" )  global rondas m11_m12_m1
* Colombia
	if "`pais'" == "COL"                       global rondas t3
* Costa Rica
	if "`pais'" == "CRI"                       global rondas m7
* Ecuador
	if "`pais'" == "ECU"                       global rondas m12
* Guatemala
	if "`pais'" == "GTM" & ("`ano'" == "2011" | "`ano'" == "2012" ) global rondas m6_m7    
	if "`pais'" == "GTM" & (("`ano'" >= "2005" & "`ano'" <= "2010") | ("`ano'" > "2012" & "`ano'" <= "2017")) global rondas m10
	if "`pais'" == "GTM" & ("`ano'" >= "2018" ) global rondas m6    
	
* Guyana
	if "`pais'" == "GUY"                       global rondas t4
* Honduras
	if "`pais'" == "HND" & ("`ano'" == "2006" | "`ano'" == "2007" ) global rondas m9
	if "`pais'" == "HND" & ("`ano'" >= "2008" & "`ano'" <= "2013" ) global rondas m5
	if "`pais'" == "HND" & ("`ano'" > "2013")  global rondas m6
* Jamaica
	if "`pais'" == "JAM"                       global rondas m4
* México
	if "`pais'" == "MEX" & ("`ano'" >= "2005" & "`ano'" <= "2011") global rondas m8_m11
	if "`pais'" == "MEX" & ("`ano'" >  "2011") global rondas m8_m12
* Nicaragua
	if "`pais'" == "NIC" & ("`ano'" == "2009") global rondas m7_m10
	if "`pais'" == "NIC" & ("`ano'" < "2009" | ("`ano'" > "2009" & "`ano'" < "2014") ) global rondas m7_m9
	if "`pais'" == "NIC" & ("`ano'" == "2014") global rondas m9_m12
* Panama
	if "`pais'" == "PAN" & ("`ano'" >= "2005" & "`ano'" <= "2010") global rondas m8
	if "`pais'" == "PAN" & ("`ano'" >  "2010") global rondas m3
* Paraguay
	if "`pais'" == "PRY" & ("`ano'" == "2006") global rondas m11_m12
	if "`pais'" == "PRY" & ("`ano'" >  "2006" & "`ano'" <=  "2017" ) global rondas m10_m12
	if "`pais'" == "PRY" & ("`ano'" > "2017") global rondas t4
* Republica Dominicana	
	if "`pais'" == "DOM" & ("`ano'" <  "2017") global rondas m10
	if "`pais'" == "DOM" & ("`ano'" >= "2017") global rondas t4
* Surinam 	
	if "`pais'" == "SUR"                       global rondas m10_m9
* Venezuela	
	if "`pais'" == "VEN" & ("`ano'" <= "2015") global rondas s2
	if "`pais'" == "VEN" & ("`ano'" >  "2015") global rondas a



/* End of do-file */


