*created on 05282019
*most copied from panel_3,line 200 onward 

global dir "E:\revise&resubmit\KYZpaper\paper3"  // office usb

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


*graph bar (mean) food_s cgoods_s housing_s med_s event_s comm_s otherexp_s schexp_s, over(year)




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
