*created on 05282019
*most copied from panel_3,line 200 onward 

global dir "E:\revise&resubmit\KYZpaper\paper3"  // office usb

global logs "${dir}\logs"
global tables "${dir}\tables"
global data "${dir}\LIK_10_13_stata\stata"



*=========merge panel===========
cd "${dir}\data_revise"
use hhpanel_long, clear

bysort year: sum food_s cgoods_s housing_s med_s event_s comm_s othercom_s schexp_s ,fvlabel 

tabstat food_s cgoods_s housing_s med_s event_s comm_s othercom_s schexp_s, by (year) stat (mean sd) nototal
tabstat adjfoodexp adjcgoodsexp adjhousing  adjmedexp  adjexpev  adjcommexp adjotherexp adjschexp, by(year) stat(mean sd )  nototal



graph bar (mean) food_s cgoods_s housing_s med_s event_s comm_s othercom_s schexp_s, over(year)

*by year: summarize adjfoodexp adjmedexp adjhousing adjexpev adjcgoodsexp  adjcommexp  adjotherexp ,fvlabel 
by year: summarize no_old no_kid ,fvlabel 
by year: summarize iv1 iv2

