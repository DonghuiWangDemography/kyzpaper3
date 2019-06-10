*created on 05282019
*most copied from panel_3,line 200 onward 

*global dir "E:\revise&resubmit\KYZpaper\paper3"  // office usb
*global dir "G:\revise&resubmit\KYZpaper\paper3"  // home desktop usb

global logs "${dir}\logs"
global tables "${dir}\tables"
global data "${dir}\LIK_10_13_stata\stata"



*=========merge panel===========
cd "${dir}\data_revise"
use hhpanel_long, clear



bysort year: sum food_s cgoods_s housing_s med_s event_s comm_s otherexp_s schexp_s ,fvlabel 

tabstat food_s cgoods_s housing_s med_s event_s comm_s otherexp_s schexp_s, by (year) stat (mean sd) nototal
tabstat adjfoodexp adjcgoodsexp adjhousing  adjmedexp  adjexpev  adjcommexp adjotherexp adjschexp, by(year) stat(mean sd )  nototal
// consistent with table1 
bysort year remreceive: sum adjfoodexp adjcgoodsexp adjhousing  adjmedexp  adjexpev  adjcommexp adjotherexp adjschexp 


*graph bar (mean) food_s cgoods_s housing_s med_s event_s comm_s otherexp_s schexp_s, over(year)



*******************
xtset hhid year
* v2: actual expenditure ;
*ladjfoodexp ladjmedexp ladjhousing  ladjexpev  ladjcgoodsexp ladjcommexp ladjotherexp
*local ctr "agactivity married no_pp no_old no_kid no_childr drought flood coldwinter frosts i.year "
local ctr " agactivity married  no_old no_kid no_childr ptmcom i.year" 
local iv "ladjexpp remreceive"
local dv "food_s cgoods_s housing_s med_s event_s comm_s otherexp_s"
foreach y of local dv {
xtreg `y' `iv' `ctr' if never==0 , fe robust
eststo m1_`y'
}
esttab m1_food_s m1_cgoods_s m1_housing_s  m1_med_s m1_event_s m1_comm_s m1_otherexp_s using panefixed.rtf, label se b(3) not r2(3) replace 



*=======Iv=======
xtset hhid year
local ctr " ladjexpp  agactivity married  no_old no_kid no_childr ptmcom drought flood coldwinter frosts y2 y3"
local dv "food_s cgoods_s housing_s med_s event_s comm_s otherexp_s"
foreach y of local dv {
*xtivreg2 `y' `ctr' (remreceive  =iv1) ,  fe first small cluster(cluster2011) //first
xtivreg `y' `ctr' (remreceive =iv1 iv2 ),  fe first small vce(r) //first

eststo iv_`y'
}

esttab iv_food_s iv_cgoods_s iv_housing_s  iv_med_s iv_event_s iv_comm_s iv_otherexp_s  ///
      using iv1.rtf, label se beta(3) not r2(3) replace 

// Sargan statistics pvalue (over identification test. Null insturment are valid instruments ) 


xtlogit remreceive  iv1 iv2 ladjexpp  agactivity married no_pp no_old  no_childr y1 y2 ptmcom ,fe
test iv1 iv2

xtlogit remreceive iv1 iv2  agactivity married no_pp no_old no_childr y1 y2 ptmcom


*======a sub sample with kids under age 18===================
*education 
preserve 
keep if chilr==1 

local control "agactivity married no_pp no_old  drought flood coldwinter frosts i.year "
local iv "lrem lexp "
*local dv "ladjfoodexp ladjmedexp ladjhousing ladjexpev ladjcgoodsexp ladjcommexp ladjotherexp"
local dv "food_s cgoods_s schexp_s housing_s med_s event_s comm_s otherexp_s "
foreach y of local dv {
xtreg `y' `iv' `control', fe robust
eststo m1_`y'
}
esttab m1_food_s m1_cgoods_s m1_schexp_s m1_housing_s m1_housing_s m1_med_s m1_event_s m1_comm_s m1_otherexp_s using panefixed_sch.rtf, label se b(3) not r2(3) replace 
*no effect on education input ? `
