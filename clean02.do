*task merge panel 
*created on 05272019


global date "05272019"   // mmddyy
global dir "E:\revise&resubmit\KYZpaper\paper3"  // office usb

global logs "${dir}\logs"
global tables "${dir}\tables"
global data "${dir}\LIK_10_13_stata\stata"



*=========merge panel===========
cd "${dir}\data_revise"
*convert into 2013 currency based on cpi

use hhmerged_2013, clear   //N=2,583, should have N=2522
rename hhid2013 hhid 
foreach var of varlist schexp2013 foodexp2013 cgoodsexp2013 medexp2013 commexp2013 housing2013 otherexp2013 expev2013  rem_total2013 totalexp2013 {
 g ladj`var'=log(`var') 
 g adj`var'=`var'
}
tempfile hhmerged_2013
save `hhmerged_2013.dta'


use hhmerged_2012, clear   //N=2,814 should have N=2863 hh in second wave, based on Lik handbook 
/* CPI 
https://knoema.com/atlas/Kyrgyzstan/CPI-inflation
2013	6.6	
2012	2.8	
2011	16.6 */
*di 6.6	/2.8=2.3571429

foreach var of varlist schexp2012 foodexp2012 cgoodsexp2012 medexp2012 commexp2012 housing2012 otherexp2012 expev2012  rem_total2012 totalexp2012 {
 gen adj`var'=`var' * 2.3571429
 g ladj`var'=log(adj`var')
}

rename hhid2012 hhid
*duplicates list hhid
tempfile hhmerged_2012
save `hhmerged_2012.dta'


use hhmerged_2011, clear
/*2013	6.6	
2012	2.8	
2011	16.6 */
*di 6.6	/16.6 =.39759036
foreach var of varlist schexp2011 foodexp2011 cgoodsexp2011 medexp2011 commexp2011 housing2011 otherexp2011 expev2011  rem_total2011 totalexp2011  {
 gen adj`var'=`var' * 0.39759036
  g ladj`var'=log(adj`var')
}
rename hhid2011 hhid


merge 1:1 hhid using `hhmerged_2012.dta', keep(matched) nogen 
merge 1:1 hhid using `hhmerged_2013.dta', keep(matched) nogen
save hhpanel,replace 
//N=2446



*****************************
use hhpanel, clear

*always receive;
*remreceive2013 remreceive2011 remreceive2012
g alreceive=0
replace alreceive=1 if remreceive2013==1 & remreceive2012==1  & remreceive2013==1
g onereceive=0
replace onereceive=1 if remreceive2013==1 | remreceive2012==1  | remreceive2013==1


reshape long   no_pp no_childr no_kid no_old marstat  annincome adjannincome ladjannincome     						///
adjschexp adjfoodexp   adjcgoodsexp adjmedexp   adjcommexp adjhousing  adjotherexp  adjexpev  adjrem_total   adjtotalexp 		///
ladjschexp ladjfoodexp ladjcgoodsexp ladjmedexp ladjcommexp ladjhousing ladjotherexp ladjexpev ladjrem_total ladjtotalexp 		///
schexp     foodexp     cgoodsexp      medexp     commexp    housing      otherexp    expev 	totalexp 						  ///
schexp_s   food_s      cgoods_s       med_s       comm_s     housing_s   otherexp_s  event_s      /// 
lincome agactivity mig rem_total lrem  	married		///
drought flood coldwinter frosts 				///
remreceive  noremreceive remcat iv1 iv2 		///
, i(hhid) j(year)

g lexp=log(totalexp)
tab year, gen (y)


*****labels ******
la var remcat "Remittance receiving category "
la var mig "Househouds have migrants"

la var schexp_s "Education"
la var food_s "Food " 
la var cgoods_s "Consumer goods"
la var housing_s "Housing"
la var med_s  "Medical expenses"
la var comm_s  "Communication/Transportation"
la var event_s "Events"
la var otherexp_s "Other expenses"

la var lrem "Remittances (log transformed)"
*la var rem_all "Remittances (som)"
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

save hhpanel_long,replace 



