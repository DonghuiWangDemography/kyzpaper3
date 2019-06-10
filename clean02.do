*task merge panel 
*created on 05272019
*updated on 06032019


*ssc install cdfplot

global date "05272019"   // mmddyy
*global dir "E:\revise&resubmit\KYZpaper\paper3"  // office usb

global logs "${dir}\logs"
global tables "${dir}\tables"
global data "${dir}\LIK_10_13_stata\stata"



*=========merge panel===========
cd "${dir}\data_revise"
*convert into 2013 currency based on cpi

use hhmerged_2013, clear   //N=2,583, should have N=2522
rename hhid2013 hhid 
foreach var of varlist schexp2013 foodexp2013 cgoodsexp2013 medexp2013 commexp2013 housing2013 otherexp2013 expev2013  rem_total2013 totalexp2013 expp2013 {
 g ladj`var'=log(`var'+1) 
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

foreach var of varlist schexp2012 foodexp2012 cgoodsexp2012 medexp2012 commexp2012 housing2012 otherexp2012 expev2012  rem_total2012 totalexp2012 expp2012 {
 gen adj`var'=`var' * 2.3571429
 g ladj`var'=log(adj`var'+1)
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
foreach var of varlist schexp2011 foodexp2011 cgoodsexp2011 medexp2011 commexp2011 housing2011 otherexp2011 expev2011  rem_total2011 totalexp2011 expp2011{
 gen adj`var'=`var' * 0.39759036
  g ladj`var'=log(adj`var'+1)
}
rename hhid2011 hhid
rename oblast2011 oblast

merge 1:1 hhid using `hhmerged_2012.dta', keep(matched) nogen 
merge 1:1 hhid using `hhmerged_2013.dta', keep(matched) nogen
merge 1:1 hhid using "${dir}\data_revise\com10", keep(matched) nogen  // mached N=2857


*generate IV
/*	
				
	year	emp_rus	emp_kaz	
				
19.	2010	62.700001	67.400002	
20.	2011	63.900002	68	
21.	2012	64.900002	68.400002	
22.	2013	64.800003	68.699997	
				
2010	69934		0.013198158
2011	70857		0.009709697
2012	71545		-0.002152491

				
				
	Manufacturing	Construction	Wholesale and retail trade
2011	0.141681518	0.118552806	0.065576442
2012	0.125384509	0.095811165	0.103043899
2013	0.103337141	0.067434781	0.070906906
							
*/

g emp_rus2011=62.700001/100
g emp_rus2012=63.900002/100
g emp_rus2013=64.900002/100

g emp_kaz2011=67.400002/100
g emp_kaz2012=68/100
g emp_kaz2013=68.400002/100


g manu2011=0.141681518
g manu2012=0.125384509
g manu2013=0.103337141

g cons2011=0.118552806
g cons2012=0.095811165
g cons2013=0.067434781 


*IV1: employment rate change * % out-migration in 2010 
*batik instrument

g iv12011=emp_rus2011/rhhc+emp_kaz2011/rkazc
g iv12012=emp_rus2012/rhhc+emp_kaz2012/rkazc
g iv12013=emp_rus2013/rhhc+emp_kaz2013/rkazc

g iv22011=cons2011*hhage2011
g iv22012=cons2012*hhage2011
g iv22013=cons2013*hhage2011


g iv32011=rushhp*manu2011
g iv32012=rushhp*manu2012
g iv32013=rushhp*manu2013

drop no_pp
save hhpanel,replace 



*****************************
use hhpanel, clear

*always receive;
*remreceive2013 remreceive2011 remreceive2012
g       alreceive=0
replace alreceive=1 if remreceive2013==1 & remreceive2012==1  & remreceive2011==1
g onereceive=0
replace onereceive=1 if remreceive2013==1 | remreceive2012==1  | remreceive2011==1

g 		never=0
replace never=1 if remreceive2013==0 & remreceive2012==0  & remreceive2011==0

*hh with children under age 18
g chilr=(no_childr2011>=1 | no_childr2012>=1 |no_childr2013>=1 ) & !missing(no_childr2011,no_childr2012,no_childr2013)  // N=1932 has children under 18
g kid=(no_kid2011 !=0  | no_kid2012 !=0  |no_kid2013 !=0 ) & !missing(no_kid2011,no_kid2012,no_kid2013)

reshape long   no_pp no_childr no_kid no_old marstat  annincome adjannincome ladjannincome     						///
adjschexp adjfoodexp   adjcgoodsexp adjmedexp   adjcommexp adjhousing  adjotherexp  adjexpev  adjrem_total   adjtotalexp ladjexpp		///
ladjschexp ladjfoodexp ladjcgoodsexp ladjmedexp ladjcommexp ladjhousing ladjotherexp ladjexpev ladjrem_total ladjtotalexp 		///
schexp     foodexp     cgoodsexp      medexp     commexp    housing      otherexp    expev 	totalexp 						  ///
schexp_s   food_s      cgoods_s       med_s       comm_s     housing_s   otherexp_s  event_s      /// 
lincome agactivity mig rem_total lrem  	married		///
drought flood coldwinter frosts  stable volatile			///
remreceive  noremreceive remcat iv1 iv2 iv3 ptmcom	 ///
, i(hhid) j(year)

g lexp=log(totalexp)
tab year, gen (y)

drop annincome adjannincome ladjannincome

// collapse (mean) food_s cgoods_s  med_s comm_s housing_s otherexp_s event_s  remp_rus , by (year)
// twoway line food_s year || line remp_rus year
// twoway line cgoods_s year || line remp_rus year
// twoway line med_s year || line remp_rus year
// twoway line comm_s year || line remp_rus year

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


cdfplot ladjcgoodsexp, by(never) 
cdfplot ladjschexp, by(never) 

twoway kdensity food_s || kdensity cgoods_s || kdensity housing_s || kdensity med_s || kdensity comm_s || kdensity event_s ||kdensity otherexp_s

twoway kdensity food_s if never==1 || kdensity food_s if never==0
twoway kdensity schexp_s if never==1 || kdensity schexp_s if never==0
