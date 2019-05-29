
*panel 
*step 1 merge three waves ;
*updated on Apirl 16th, 2018
*updated on April 22th, 2018
*updated on May27, 2019 
* task FE-IV method
set more off 
clear
*cd "G:\RA\KYZpanel"
*cd "E:\revise&resubmit\KYZpaper\paper3\LIK_10_13_stata\stata\panel"
cd "E:\revise&resubmit\KYZpaper\paper3\LIK_10_13_stata\stata\data2013\household"


use hhmerged_2013, clear
*rename hhid2013 hhid
rename hhid_2013 hhid 
foreach var of varlist foodexp2013 cgoodsexp2013 medexp2013 commexp2013 housing2013 otherexp2013 expev2013 annincome2013 rem_total2013 totalexp_22013 {
 g ladj`var'=log(`var') 
 g adj`var'=`var'
}

//duplicates list hhid  // why hhid has duplicates ?
//duplicates report hhid
//duplicates tag hhid, generate(dup)
sort hhid
save hhmerged_2013_m, replace

use hhmerged_2012, clear
/* CPI 
https://knoema.com/atlas/Kyrgyzstan/CPI-inflation
2013	6.6	
2012	2.8	
2011	16.6 */
*di 6.6	/2.8=2.3571429

foreach var of varlist foodexp2012 cgoodsexp2012 medexp2012 commexp2012 housing2012 otherexp2012 expev2012 annincome2012 rem_total2012 totalexp_22012 {
 gen adj`var'=`var' * 2.3571429
 g ladj`var'=log(adj`var')
}

rename hhid2012 hhid
*duplicates list hhid
duplicates drop
sort hhid
save hhmerged_2012_m, replace

use hhmerged_2011, clear
*rename totalexp_22011 totalexp2011 

/*2013	6.6	
2012	2.8	
2011	16.6 */
*di 6.6	/16.6 =.39759036
foreach var of varlist foodexp2011 cgoodsexp2011 medexp2011 commexp2011 housing2011 otherexp2011 expev2011 annincome2011 rem_total2011 totalexp_22011  {
 gen adj`var'=`var' * 0.39759036
  g ladj`var'=log(adj`var')
}

rename hhid2011 hhid
*duplicates list hhid
sort hhid
save hhmerged_2011_m, replace


merge hhid  using hhmerged_2011_m hhmerged_2012_m  hhmerged_2013_m

save hhpanel,replace 
*****************************
clear
use hhpanel
drop _merge*
*duplicates drop

*duplicates list hhid
* attrition 

*365 household missing 2011; 
*misschk foodexp_2011 nonfood_2011 cgoodsexp_2011 medexp_2011 commexp_2011 housing_2011 otherexp_2011

*284 missing 2012;
*misschk foodexp_2012 nonfood_2012 cgoodsexp_2012 medexp_2012 commexp_2012 housing_2012 otherexp_2012

*546 missing 2013; 
*misschk foodexp_2013 nonfood_2013 cgoodsexp_2013 medexp_2013 commexp_2013 housing_2013 otherexp_2013

*
*always receive;
*remreceive2013 remreceive2011 remreceive2012
g alreceive=0
replace alreceive=1 if remreceive2013==1 & remreceive2012==1  & remreceive2013==1
g onereceive=0
replace onereceive=1 if remreceive2013==1 | remreceive2012==1  | remreceive2013==1

tab onereceive

*fixed hh charactheristics 
gen sex=h1022011
gen age=age2011
gen ethnicity=h1052011 
gen rural=rural2013

duplicates drop


*rename hhid12_2013 hhid
*save hhmerged_2013, replace


keep  sex hhid age ethnicity rural oblast*2013 ///
adjfoodexp* adjcgoodsexp* adjmedexp* adjcommexp* adjhousing* adjotherexp* adjexpev* adjannincome*  adjrem_total*  adjtotalexp_2* ///
ladjfoodexp* ladjcgoodsexp* ladjmedexp* ladjcommexp* ladjhousing* ladjotherexp* ladjexpev* ladjannincome*  ladjrem_total*  ladjtotalexp_2* ///
foodexp* cgoodsexp* medexp* commexp* housing* otherexp* expev* ///
no_pp* no_childr* no_kid* no_old* married* divorced* agactivity*  ///
annincome* lincome* agactivity*  mig* rem_total* lrem* totalexp_2* ///
drought* flood* coldwinter* frosts* ///
totalexp_2* food_2* med_2* housing_2* event_2* cgoods* comm* othercom* ///
remreceive* noremreceive* remcat*  iv1* iv2*

//duplicates tag hhid, gen(dup)
duplicates drop
*list in 1/20
save hhpanel_cleaned,replace 




set trace on 
clear 
use hhpanel_cleaned, clear
reshape long  no_pp no_childr no_kid no_old married divorced annincome ///
adjfoodexp adjcgoodsexp adjmedexp adjcommexp adjhousing adjotherexp adjexpev adjannincome adjrem_total adjtotalexp_2 ///
ladjfoodexp ladjcgoodsexp ladjmedexp ladjcommexp ladjhousing ladjotherexp ladjexpev ladjannincome ladjrem_total ladjtotalexp_2 ///
foodexp cgoodsexp medexp commexp housing otherexp expev ///
lincome agactivity mig rem_total lrem ///
drought flood coldwinter frosts ///
totalexp_2 food_2 med_2 housing_2 event_2 cgoods comm othercom /// 
remreceive  noremreceive remcat iv1 iv2 ///
, i(hhid) j(year)

save hhpanel_long,replace 
*reshape long rem_total, i(hhid) j(year)



*****final dataset***************

use hhpanel_long,clear

g lexp=log(totalexp_2)
g female= (sex==2)  /*what happend on the missing values? */
tab year, gen (y)

*g foodexp=totalexp8*food_2

replace lrem=0 if lrem==.
*replace med_2=0 if med_2==.
replace remreceive=0 if lrem==0

g rem_all=rem_total  
replace rem_all=0 if rem_total==.

*****labels ******

la var remcat "Remittance receiving category "
la var mig "Househouds have migrants "
la var food_2 "Food " 
la var cgoods "Consumer goods"
la var housing_2 "Housing"
la var med_2  "Medical expenses"
la var comm "Communication/Transportation"
la var event_2"Events"
la var othercom "Other expenses"
la var lrem "Remittances (log transformed)"
la var lincome "Income (log transformed)"
la var rem_all "Remittances (som)"
la var rem_total "Remittances among those who revieved (som)"

la var lexp "Total expenses (log transformed)"
la var agactivity "Agricultural activity"
la var married "married"
la var no_pp "Hosehold size "
la var no_old " Number of old people (>60)"
la var no_kid "Number of kids (<6)"
la var drought "Sever drought"
la var flood "Flood"
la var coldwinter "Cold winter"
la var frosts "Frosts"
*la var y1 "2011"
*la var y2 "2012"
la var adjfoodexp "Food expenses(inflation adjusted)"
la var adjmedexp "Medical expenses(inflation adjusted)"
la var adjhousing "Housing expenses(inflation adjusted)"
la var adjexpev "Events expenses(inflation adjusted)"
la var adjcgoodsexp "Comsumer goods expenses(inflation adjusted)"
la var adjcommexp "Communication/transportation expenses(inflation adjusted)"
la var adjotherexp "Other expenses(inflation adjusted)"


********************
* time invariant variables ;
tab sex if year==2013
tab ethnicity if  year==2013
tab rural

sum food_2 med_2 housing_2 event_2 cgoods comm othercom ,fvlabel 
sum adjfoodexp adjmedexp adjhousing adjexpev adjcgoodsexp  adjcommexp  adjotherexp ,fvlabel 

sort year
*by year: summarize adjfoodexp adjmedexp adjhousing adjexpev adjcgoodsexp  adjcommexp  adjotherexp ,fvlabel 
by year: summarize no_old no_kid ,fvlabel 
by year: summarize iv1 iv2


sort year remreceive remreceive 
by year remreceive: summarize food_2 med_2 housing_2 event_2 cgoods comm othercom 

*tabout adjfoodexp adjmedexp adjhousing adjexpev adjcgoodsexp  adjcommexp  adjotherexp year using tabletry.rtf, ///
*cells(mean adjfoodexp se ) format(2 2) sum svy replace 
tabstat adjfoodexp adjmedexp adjhousing adjexpev adjcgoodsexp  adjcommexp  adjotherexp, by(year) stat(mean sd )  nototal
tabstat food_2 med_2 housing_2 event_2 cgoods comm othercom , by (year) stat (mean sd) nototal
*esttab, cells("mean " )
*eststo clear 
 
tab remcat year
tab remreceive year, col
tab mig year
tab female
*Breakdown  by oblsat;
sort year 
by year: tab  oblast2013 remreceive, col

* 1 keep receiving remittances;

*consumption pattern breaking down by remittance receiving status ;

*ttest
foreach var of varlist food_2 med_2 housing_2 event_2 cgoods comm othercom {
display "variable==`var'"
ttest `var', by (remreceive)
}
sort year remreceive
by year remreceive: summarize food_2 med_2 housing_2 event_2 cgoods comm othercom

sort year 
by year: ttest food_2, by(remreceive)
by year: ttest med_2, by(remreceive)
by year: ttest housing_2, by(remreceive)
by year: ttest event_2, by(remreceive)
by year: ttest cgoods, by(remreceive)
by year: ttest comm, by(remreceive)
by year: ttest othercom, by(remreceive)



* other characheristics;
sort year
*by year : summarize food_2 med_2 housing_2 event_2 cgoods comm othercom ,fvlabel 
*by year : summarize lrem lincome agactivity married  no_pp no_old no_kid drought flood coldwinter frosts
by year: summarize  annincome rem_total lrem lincome rem_all

tabstat annincome rem_total lrem lincome rem_all, by (year) stat(mean sd) long  format(%9.2f) save 



*check change ;
foreach v of varlist adjfoodexp adjmedexp adjhousing adjexpev adjcgoodsexp adjcommexp adjotherexp adjrem_total  annincome rem_total rem_all  { 
 display "==> `v'"
  anova `v' year
}

* relationships between remittance receiving and income 

* consumption pattern breakdown by remittance receiving or not 

*discriptivies 
*table 1: consumption patterns by year, 

*panel trial;
*xtset hhid year
*xtline y



* try non-fixed effects;
reg  food_2 lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts age ethnicity rural female y1 y2
estimates store m1_food

reg  cgoods lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts age ethnicity rural female y1 y2 
estimates store m1_cgoods

reg  housing_2 lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts age ethnicity rural female y1 y2
estimates store m1_housing

reg med_2 lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts age ethnicity rural female y1 y2 
estimates store m1_med

reg comm lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts age ethnicity rural female y1 y2 
estimates store m1_comm

reg  event_2 lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts age ethnicity rural female y1 y2 
estimates store m1_event

reg  othercom lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts age ethnicity rural female y1 y2 
estimates store m1_other

esttab m1_food m1_cgoods  m1_housing m1_med m1_comm  m1_event m1_other using model2_crosssection.rtf, label se b(3) not r2(3) replace 



*SUR
/*sureg (food_2 lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts age ethnicity rural female y1 y2)   ///
      (cgoods lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts age ethnicity rural female y1 y2)   ///
	  ( housing_2 lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts age ethnicity rural female y1 y2 ) ///
	  (med_2 lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts age ethnicity rural female y1 y2) ///
	 (comm lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts age ethnicity rural female y1 y2) ///
	 ( event_2 lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts age ethnicity rural female y1 y2) ///
	 ( othercom lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts age ethnicity rural female y1 y2) , corr 
estimates store sur

esttab sur using model3_sur.rtf, label se b(3) not aic replace  */
*model1

sureg (food_2 lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe)   ///
      (cgoods lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe)   ///
	  (housing_2 lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts y1 y2, fe ) ///
	  (med_2 lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts   y1 y2, fe) ///
	 (comm lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2, fe) ///
	 ( event_2 lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts y1 y2, fe) ///
	 ( othercom lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe) , corr 
estimates store sur_2
esttab sur_2 using model4_sur.rtf, label se b(3) not aic replace 

*DV: actual dollar amount;
* adjfoodexp adjmedexp adjhousing adjexpev adjcgoodsexp  adjcommexp  adjotherexp ,fvlabel 

sureg (adjfoodexp lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe)   ///
      (adjmedexp lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe)   ///
	  ( adjhousing lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts y1 y2, fe ) ///
	  (adjexpev lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts   y1 y2, fe) ///
	 (adjcgoodsexp lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2, fe) ///
	 ( adjcommexp lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts y1 y2, fe) ///
	 ( adjotherexp lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe) , corr 
estimates store sur_3
esttab sur_3 using modeldollar_sur.rtf, label se b(3) not aic replace 

*DV: log actual dollar amount;
* adjfoodexp adjmedexp adjhousing adjexpev adjcgoodsexp  adjcommexp  adjotherexp ,fvlabel 
 
sureg (ladjfoodexp lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe)   ///
      (ladjmedexp lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe)   ///
	  (ladjhousing lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts y1 y2, fe ) ///
	  (ladjexpev lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts   y1 y2, fe) ///
	 (ladjcgoodsexp lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2, fe) ///
	 ( ladjcommexp lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts y1 y2, fe) ///
	 ( ladjotherexp lrem lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe) , corr 
estimates store sur_3
esttab sur_3 using modeldollar_sur.rtf, label se b(3) not aic replace 

*log both adjusted ;
 *ladjannincome ladjrem_total ladjtotalexp_2
sureg (ladjfoodexp ladjrem_total ladjannincome ladjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe)   ///
      (ladjmedexp ladjrem_total ladjannincome ladjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe)   ///
	  (ladjhousing ladjrem_total ladjannincome ladjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts y1 y2, fe ) ///
	  (ladjexpev ladjrem_total ladjannincome ladjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts   y1 y2, fe) ///
	 (ladjcgoodsexp ladjrem_total ladjannincome ladjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2, fe) ///
	 ( ladjcommexp ladjrem_total ladjannincome ladjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts y1 y2, fe) ///
	 ( ladjotherexp ladjrem_total ladjannincome ladjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe) , corr 
estimates store sur_3
esttab sur_3 using logbothadjusted_sur.rtf, label se b(3) not  replace 

*pure dollar amount;
sureg (adjfoodexp adjrem_total adjannincome adjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe)   ///
      (adjmedexp adjrem_total adjannincome adjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe)   ///
	  (adjhousing adjrem_total adjannincome adjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts y1 y2, fe ) ///
	  (adjexpev adjrem_total adjannincome adjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts   y1 y2, fe) ///
	 (adjcgoodsexp adjrem_total adjannincome adjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2, fe) ///
	 (adjcommexp adjrem_total adjannincome adjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts y1 y2, fe) ///
	 ( adjotherexp adjrem_total adjannincome adjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe) , corr 
estimates store sur_3
esttab sur_3 using dollarboth_sur.rtf, label se b(3) not aic replace 

sureg (adjfoodexp ladjrem_total ladjannincome ladjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe)   ///
      (adjmedexp ladjrem_total ladjannincome ladjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe)   ///
	  (adjhousing ladjrem_total ladjannincome ladjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts y1 y2, fe ) ///
	  (adjexpev ladjrem_total ladjannincome ladjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts   y1 y2, fe) ///
	 (adjcgoodsexp ladjrem_total ladjannincome ladjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2, fe) ///
	 (adjcommexp ladjrem_total ladjannincome ladjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts y1 y2, fe) ///
	 ( adjotherexp ladjrem_total ladjannincome ladjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe) , corr 
estimates store sur_3
esttab sur_3 using dollarivonly_sur.rtf, label se b(3) not aic replace 


* remittance recevie or not, instead of amount;
sureg (food_2 remreceive lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe)   ///
      (cgoods remreceive lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe)   ///
	  (housing_2 remreceive lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts y1 y2, fe ) ///
	  (med_2 remreceive lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts   y1 y2, fe) ///
	 (comm remreceive lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2, fe) ///
	 ( event_2 remreceive lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts y1 y2, fe) ///
	 ( othercom remreceive lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe) , corr 
estimates store sur_2
esttab sur_2 using remreceive_1.rtf, label se b(3) not r2 replace 



*remittance receive or not, Som amount;
*foodexp cgoodsexp medexp commexp housing otherexp expev ///

sureg (foodexp remreceive annincome  agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe)   ///
      (cgoodsexp remreceive annincome  agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe)   ///
	  (medexp remreceive annincome  agactivity married no_pp no_old no_kid drought flood coldwinter frosts y1 y2, fe ) ///
	  (housing remreceive annincome  agactivity married no_pp no_old no_kid drought flood coldwinter frosts   y1 y2, fe) ///
	 (commexp remreceive annincome  agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2, fe) ///
	 ( expev remreceive annincome  agactivity married no_pp no_old no_kid drought flood coldwinter frosts y1 y2, fe) ///
	 ( otherexp remreceive annincome  agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe) , corr 
estimates store sur_2
esttab sur_2 using remreceive_2.rtf, label se b(3) not r2 replace 



*fixed effects 
*V1: DV expenditure share ;
xtset hhid year

local iv "lrem lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts y1 y2 "
local dv " food_2 cgoods housing_2 med_2 comm event_2 othercom "
foreach y of local dv {
qui: xtreg `y' `iv', fe 
eststo m4_`y'
}
esttab m4_food_2 m4_cgoods m4_housing_2 m4_med_2  m4_event_2 m4_comm m4_othercom using pane2.rtf, label se b(3) not r2(3) replace 



*******************
*Instrumental varible
****************
xtset hhid year
local ex "lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts y1 y2"

local dv "food_2 cgoods housing_2 med_2 comm event_2 othercom"
foreach y of local dv {
xtivreg2 `y' `ex' (lrem=iv1 iv2), fe    //first
eststo iv_`y'
}

esttab iv_food_2 iv_cgoods iv_housing_2 iv_med_2 iv_comm iv_event_2 iv_othercom using iv.rtf, label se b(3) not r2(3) replace 
// Sargan statistics pvalue (over identification test. Null insturment are valid instruments ) 


la var iv1"unexpected job creation "
la var iv2 "previous migration flow"
*******************
*******************
xtset hhid year
* v2: actual expenditure ;
*ladjfoodexp ladjmedexp ladjhousing  ladjexpev  ladjcgoodsexp ladjcommexp ladjotherexp
local control "agactivity married no_pp no_old no_kid drought flood coldwinter frosts y1 y2 "
local ty1 " lrem  lincome lexp "
local ty2 " ladjrem_total ladjannincome ladjtotalexp_2  "
local dv "ladjfoodexp ladjmedexp ladjhousing ladjexpev ladjcgoodsexp ladjcommexp ladjotherexp"
foreach y of local dv {
xtreg `y' `ty1' `control', fe
eststo m4_`y'
}

esttab m4_ladjfoodexp m4_ladjcgoodsexp m4_ladjhousing m4_ladjmedexp  m4_ladjexpev  m4_ladjcommexp m4_ladjotherexp using panefixed_2.rtf, label se b(3) not r2(3) replace 


*************
*IV
**************
local ex "lincome lexp agactivity married no_pp no_old no_kid drought flood coldwinter frosts y1 y2 "
local dv "ladjfoodexp ladjmedexp ladjhousing ladjexpev ladjcgoodsexp ladjcommexp ladjotherexp"
//local dv2 "adjfoodexp adjmedexp adjhousing adjexpev adjcgoodsexp adjcommexp adjotherexp"

foreach y of local dv {
xtivreg2 `y' `ex' (lrem= iv1 iv2), first fe    //first
eststo iv2_`y'
}

esttab iv2_ladjfoodexp iv2_ladjcgoodsexp iv2_ladjhousing iv2_ladjmedexp iv2_ladjexpev iv2_ladjcommexp iv2_ladjotherexp using iv2.rtf, la se b(3) not r2(3) replace

* try hybrid method : Alison's little green book;

/* egen mself=mean(self), by(id) 
egen mpov=mean(pov), by(id)
gen dself=self-mself gen dpov=pov-mpov

xi: xtreg anti dself dpov mself mpov black /// hispanic childage married /// gender momage momwork i.time test (dself=mself) (dpov=mpov)

xi: xtmixed anti dself dpov mself mpov black /// hispanic childage married /// gender momage momwork i.time ||id: dself

*/

/*exemplar codes 
xtreg y x1 x2 x3, fe
estimates store fixed
xi: regress y x1 x2 x3 i.country
estimates store ols
areg y x1 x2 x3, absorb(country)
estimates store areg
estimates table fixed ols areg, star stats(N r2 r2_a)

*/

xtset hhid year
xtreg  adjfoodexp adjrem_total adjannincome adjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe   
eststo m5_food
xtreg adjmedexp adjrem_total adjannincome adjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe
eststo m5_med
xtreg adjhousing adjrem_total adjannincome adjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts y1 y2, fe 
eststo m5_housing
xtreg adjexpev adjrem_total adjannincome adjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts   y1 y2, fe
eststo m5_event
xtreg adjcgoodsexp adjrem_total adjannincome adjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2, fe
eststo m5_cgoods
xtreg adjcommexp adjrem_total adjannincome adjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts y1 y2, fe
eststo m5_comm
xtreg adjotherexp adjrem_total adjannincome adjtotalexp_2 agactivity married no_pp no_old no_kid drought flood coldwinter frosts  y1 y2 , fe
eststo m5_other

esttab m5_food m5_cgoods m5_housing m5_med  m5_event m5_comm m5_other using pane_3.rtf, label se b(3) not r2(3) replace 

*appendix
*remittances only
xtset hhid year
xtreg food_2 lrem  , fe
*estimates store m4_food 
eststo m6_food

xtreg  cgoods lrem   , fe 
*estimates store m4_cgoods
eststo m6_cgoods

xtreg  housing_2 lrem   , fe 
*estimates store m4_housing
eststo m6_housing

xtreg med_2 lrem  ,fe 
*estimates store m4_med 
eststo m6_med

xtreg  comm lrem  , fe 
*estimates store m4_event
eststo m6_comm

xtreg  event_2 lrem   , fe 
*estimates store m4_event
eststo m6_event


xtreg  othercom  lrem  , fe 
*estimates store m4_event
eststo m6_other


*estimates table m4_food m4_med  m4_housing m4_cgoods m4_event, se b  stats(N r2 r2_a)

esttab m6_food m6_cgoods m6_housing m6_med  m6_event m6_comm m6_other using pane3_app.rtf, label se b(3) not r2(3) replace 

*income and rem
xtset hhid year
xtreg food_2 lrem lincome  , fe
*estimates store m4_food 
eststo m7_food

xtreg  cgoods lrem  lincome , fe 
*estimates store m4_cgoods
eststo m7_cgoods

xtreg  housing_2 lrem  lincome  , fe 
*estimates store m4_housing
eststo m7_housing

xtreg med_2 lrem lincome ,fe 
*estimates store m4_med 
eststo m7_med

xtreg  comm lrem  lincome  , fe 
*estimates store m4_event
eststo m7_comm

xtreg  event_2 lrem  lincome  , fe 
*estimates store m4_event
eststo m7_event

xtreg  othercom  lrem  lincome , fe 
*estimates store m4_event
eststo m7_other
*estimates table m4_food m4_med  m4_housing m4_cgoods m4_event, se b  stats(N r2 r2_a)
esttab m7_food m7_cgoods m7_housing m7_med  m7_event m7_comm m7_other using pane4.rtf, label se b(3) not r2(3) replace 
