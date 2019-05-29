*task: combine 2011-2013 code
*created 03142019
*updated 05272019

clear all 
clear matrix 
set more off 
capture log close 

global date "01022019"   // mmddyy
global dir "E:\revise&resubmit\KYZpaper\paper3"  // usb office
*global dir "G:\revise&resubmit\KYZpaper\paper3"  // usb home

*global dir "W:\Marriage"                         // pri 
*global dir "C:\Users\wdhec\Desktop\Marriage"     // home  

global logs "${dir}\logs"
global tables "${dir}\tables"
global data "${dir}\LIK_10_13_stata\stata"



*==============2011==============
// work on community level char
use "${data}\data2011\control\cc_hh.dta", clear
drop if particip==2 
sort cluster hhid 
by cluster: gen thh=_N  //total hh within a community;
sort oblast hhid
by oblast: gen ohh=_N // total hh within oblast;
keep hhid cluster oblast thh ohh
duplicates drop 
drop if cluster==.
unique hhid 
duplicates list hhid  
// add another hhid(6482) mannually for the ease to merge later on 
expand 2 if hhid==6483
bysort hhid: replace hhid=6482 if hhid==6483 & _n==2
save "${data}\data2011\control\hh_cc_2011.dta", replace // Nhhid=2,862


// merge all the hh data together first 
cd "${data}\data2011\household" 
use hh1a,clear

merge m:m hhid using hh1b, nogen 
merge m:m hhid using hh2c, nogen 
merge m:m hhid using hh3,nogen 
merge m:m hhid using hh4a,nogen 
merge m:m hhid using hh4b, nogen
merge m:m hhid using hh4c, nogen
merge m:m hhid using hh5, nogen
merge m:m hhid using hh6, nogen
merge m:m hhid using hh6a, nogen
merge m:m hhid using hh6b, nogen
merge m:m hhid using hh7, nogen

*==========
*1.gender age ethnicity maritalstatus totalpp no_kid no_old 
egen no_pp= max (pid ) , by (hhid)
egen no_childr = sum(age < 18), by(hhid)
egen no_kid = sum(age < 2005), by(hhid) 
egen no_old= sum (age > 60 ), by (hhid)
clonevar marstat_h=h108 if h104==1 // hh head's marital stataus 
bysort hhid: egen marstat=max(marstat_h)

clonevar age_h=age if h104==1 // hh head's age
bysort hhid: egen hhage=max(age_h)

*gender 
gen female=(h102==2) if  h104==1
bysort hhid: egen hhfemale=max(female) 

clonevar ethn=h105 if h104==1
bysort hhid: egen ethnicity=max(ethn)


*2.education expenditure 
gen schexp_c=h121_4
bysort hhid: egen schexp=total(schexp_c)

 
*3. land
//100 sotka = 1 hectare = 2.4 acres. 
gen land_i=h217*h220_g if h220_g !=. & h216==1  //hecter 
replace land_i=(h217*h220_s)/100 if h220_s !=. & h216==1
replace land_i=0 if  h216==0
bysort hhid: egen land=total(land_i)
la var land "own land (hectar)"

*4.ag activity;
gen agact = (h301 ==1) 
bysort hhid: egen agactivity=max(agact)


replace h401a=0 if h401a==.
replace h403=0 if h403==.
*5.food expenses;
gen h401a_new=h401a
replace h401a_new=h401a*52 if h401b==1
replace h401a_new=h401a*12 if h401b==2
replace h401a_new=h401a*4 if h401b==3
replace h401a_new=0 if h401a==.   			// treat missing as zero 
bysort hhid: egen foodexp = total(h401a_new)

*6.non-food expenses
* used 46.14
gen nonfoode=h403
replace nonfoode=h403*12       if h404==1 & h405==1
replace nonfoode=h403*46.14*12 if h404==2 & h405==1
replace nonfoode=h403*46.14    if h404==2 & h405==2
bysort hhid: egen nonfood=total(nonfoode)

*detailed non-food expenses 
*consumer goods ;
bysort hhid: egen cgoods= total (nonfoode) if nitem ==1 | nitem ==2  | nitem ==19
bysort hhid: egen cgoodsexp = max(cgoods) 

*med;
bysort hhid: egen med =total (nonfoode) if nitem == 3 | nitem==4 
bysort hhid: egen medexp = max(med) 

*communication
bysort hhid: egen comm= total (nonfoode) if nitem ==14 |nitem ==15 
bysort hhid: egen commexp=max(comm)

*housing exp;
bysort hhid: egen hhexp=total (nonfoode) if  (nitem >4 & nitem <= 12) 
bysort hhid: egen housing=max (hhexp)

*others 
*other goods;
bysort hhid: egen other=total (nonfoode) if nitem==13 | ( nitem >= 16 & nitem <= 18 )| nitem==20 |  nitem==21 
bysort hhid: egen otherexp=max(other)

*7. expences on events ;
bysort hhid:egen expev=total(h415) 


*8. income
bysort hhid: egen income =total(h502) if n5 ~=15    // exclude remmitances 
gen annincome_c=income *12 
bysort hhid : egen annincome=total(annincome_c) 

*9.current labor migration
gen mig_c= (h601>=1 & !missing (h601)) // how many adult members currently live abroad 
gen pmig_c=(h600a==1)                  //at least one people migrated in last five years ; 
bysort hhid : egen mig=max(mig_c)
bysort hhid : egen pmig=max(pmig_c)


*10.remittances  
*  46.14   64.28   1.57 
*  USD	    EUR	    RUB	     
*year, sum
gen rem=h617_s if h617_c==1 & h617_t==3  
*used,month
replace rem=h617_s * 46.14 *12 if h617_c==2 & h617_t==1 
*used,year
replace rem=h617_s * 46.14 if h617_c==2 & h617_t==2

*roble, month
replace rem=h617_s * 1.57 *12 if h617_c==3 & h617_t==1
 *roble, year
replace rem=h617_s * 1.57 if h617_c==3 & h617_t==2
*euro, month 
replace rem=h617_s * 64.28*12  if h617_c==4 & h617_t==1
*euro, year 
replace rem=h617_s *  64.28  if h617_c==4 & h617_t==2

gen rem_g =h625s if h625c==1
replace rem_g=h625s * 46.14 if h625c==2
replace rem_g=h625s * 1.57 if h625c==3
replace rem_g= h625s * 64.28  if h625c==4
replace rem_g =0 if rem_g ==. 

gen rem_total=rem + rem_g
summarize rem_total rem rem_g
replace rem_total=0 if rem_total==.


*11.mig destinations 
gen dest=h605 
bysort hhid: egen destination=max(dest)

*12. enviromental schocks  
g drought = (h701_1 ==1  )
g flood = ( h701_2 ==1 )
g coldwinter = (h701_3==1) 
g frosts = (h701_4==1) 

local exp "schexp foodexp nonfood cgoodsexp medexp commexp housing otherexp expev"
keep hhid hhage no_pp no_childr no_kid no_old marstat  land agactivity  annincome `exp' ///
	mig pmig  rem_total  rem rem_g destination drought flood coldwinter frosts hhfemale ethnicity

duplicates drop
//N=2863
foreach x of local exp {
replace `x'=0 if `x'==.
}


 
*merge household data within community data 
// migration network : percentage of hh that has at least one migrants over the past 5 years in the community;
merge 1:m hhid using "${data}\data2011\control\hh_cc_2011.dta", keep(match)

egen tmig_com = sum(pmig), by(cluster)  // total number of migrations at community level 
egen tmig_obl = sum(pmig), by(oblast)  // total number of migrations at oblast level 

gen ptmcom=tmig_com/thh  //percentage of migration at community level; 
gen ptcobl=tmig_obl/ohh

la var ptmcom "migration network (community)"
la var ptcobl "migration network (oblast) "

local exp "schexp foodexp nonfood cgoodsexp medexp commexp housing otherexp expev"
keep hhid cluster hhage no_pp no_childr no_kid no_old marstat land agactivity  annincome `exp' ///
	mig pmig  rem_total  rem rem_g destination ptmcom ptcobl drought  flood coldwinter frosts hhfemale ethnicity

	
*further revise vars
replace rem_total=0 if rem_total==.
g lrem=log( rem_total) 
g lincome=log(annincome)


* DV food expences
gen totalexp=foodexp+nonfood+expev+schexp
summarize foodexp nonfood expev schexp totalexp annincome

gen food_s=foodexp/totalexp 
gen med_s=medexp/totalexp
gen housing_s=housing/totalexp
gen event_s=expev/totalexp
gen schexp_s=schexp/totalexp

*other expences;
gen cgoods_s=cgoodsexp/totalexp
gen comm_s=commexp/totalexp
gen othercom_s=otherexp/totalexp

egen tconsum_s=rowtotal(food_s med_s housing_s event_s schexp_s cgoods_s comm_s othercom_s)  // very close to one 

sum food_s med_s housing_s event_s schexp_s cgoods_s comm_s othercom_s, detail


*tab oblast, gen (oblast)

replace agactivity =0 if agactivity==.

replace mig=0 if mig==.
gen remreceive = (rem_total >0.1) // & rem >0.1 ;
gen noremreceive= (mig==1 & rem_total==0)

gen remcat=1 if remreceive==1 
replace remcat=2 if noremreceive==1 
replace remcat=3 if mig==0
label define remcat 1 "Recieve Remettances"   2 "Receive no remittance"  3 "Non migrants"


*=======instruments===================
* (1) unexpected job creation in the destination countries  X age of hh head****
*generate percetage of pop work in russia
gen rus=(destination==1) 
*how many work in russia in the communiy ?
egen rus_com = sum(rus), by(cluster)  // total number of migrations in russian at community level 

gen iv1=0.89*rus_com*hhage 
*(2)community previous migration flow Xproportion of hh who have at least secondary level of ed
gen iv2=ptmcom*hhage

la var iv1"unexpected job creation "
la var iv2 "previous migration flow"
foreach x of var * { 
	rename `x' `x'2011 
} 

local share "food_s med_s housing_s event_s schexp_s cgoods_s comm_s othercom_s"
misschk `share', gen(m)
drop if mnumber>0    //N=2860

save "${dir}\data_revise\hhmerged_2011", replace 
	 
	 

*==============2012==============
use "${data}\data2012\control\cc_hh.dta", clear  //N=97 who did not participate 
drop if particip==0
sort cluster hhid12 
by cluster: gen thh=_N  //total hh within a community;
sort oblast hhid12
by oblast: gen ohh=_N // total hh within oblast;
rename hhid12 hhid
keep hhid cluster oblast thh ohh
*save "G:\RA\RAship Dr Chi\Community resiliency\paper3\LIK_10_13_stata\stata\data2012\control\hh_cc_2012",replace
save "${data}\data2012\control\hh_cc_2012.dta" , replace 


// merge all the hh data together  
cd "${data}\data2012\household"   //N=2816
use hh1a,clear

merge m:m hhid using hh1b, nogen 
merge m:m hhid using hh2c, nogen 
merge m:m hhid using hh3,nogen 
merge m:m hhid using hh4a,nogen 
merge m:m hhid using hh4b, nogen
merge m:m hhid using hh4c, nogen
merge m:m hhid using hh5, nogen
merge m:m hhid using hh6, nogen
merge m:m hhid using hh6a, nogen
merge m:m hhid using hh6b, nogen
merge m:m hhid using hh7, nogen


*==========
*1.gender age ethnicity maritalstatus totalpp no_kid no_old 
egen no_pp= max (pid ) , by (hhid)
egen no_childr = sum(age < 18), by(hhid)
egen no_kid = sum(age < 2005), by(hhid) 
egen no_old= sum (age > 60 ), by (hhid)
clonevar marstat_h=h108 if h104==1 // hh head's marital stataus 
bysort hhid: egen marstat=max(marstat_h)

clonevar age_h=age if h104==1 // hh head's age
bysort hhid: egen hhage=max(age_h)


*2.education expenditure 
gen schexp_c=h121_4
bysort hhid: egen schexp=total(schexp_c)
 
 
*3. land
//100 sotka = 1 hectare = 2.4 acres. 
gen land_i=h217*h220_g if h220_g !=. & h216==1  //hecter 
replace land_i=(h217*h220_s)/100 if h220_s !=. & h216==1
replace land_i=0 if  h216==0
bysort hhid: egen land=total(land_i)
la var land "own land (hectar)"

*4.ag activity;
gen agact = (h301 ==1) 
bysort hhid: egen agactivity=max(agact)


replace h401c=0 if h401a==.
replace h403=0 if h403==.

*5.food expenses;
gen h401c_new=h401c
replace h401c_new=h401c*52 if h401d==1
replace h401c_new=h401c*12 if h401d==2
replace h401c_new=h401c*4 if h401d==3
replace h401c_new=0 if h401c==.

bysort hhid: egen foodexp = total(h401c_new)


*6.non-food expenses
*non-food expenses : consumer goods, household services transportation, medical care  ;
gen  nonfoode=h403
replace  nonfoode=h403*12 if h404==1 & h405==1  
replace nonfoode=h403*47.01*12 if h404==2 & h405==1  
*usd, per year 
replace nonfoode=h403*47.01 if h404==2 & h405==1
egen nonfood=total (nonfoode), by (hhid)

*consumer goods  ;
egen cgoods= total  (nonfoode) if n4b >=1 & n4b <6 , by(hhid)
egen cgoodsexp = max (cgoods) , by (hhid)
*list cgoodsexp in 1/50

*med;
egen med =total (nonfoode) if n4b == 6 | n4b==7  , by (hhid) 
egen  medexp = max (med) , by (hhid)

*communitcation/transportation;
egen comm= total (nonfoode) if (n4b >=8 & n4b <= 10 ), by(hhid)
egen commexp=max(comm), by (hhid)

*housing exp;

egen hhservice=total (nonfoode) if  (n4b >10 & n4b <= 17) | n4b==23 |n4b==24 |n4b==27 , by (hhid)
*egen hhserviceexp=max(hhservice), by (hhid)
egen hhdurable=total (nonfoode) if n4b==22 |n4b==26 | (n4b >= 28 & n4b <= 32), by (hhid)
*egen hhdurableexp=max ( hhdurable ), by (hhid)
egen hhexp= rowtotal(hhservice hhdurable) 
*list hhservice hhdurable  hhexp in 1/40
egen housing=max (hhexp), by (hhid) 

*other goods;
egen other=total (nonfoode) if  ( n4b >= 18 & n4b <= 21 )| n4b==25 | n4b==33 ,by (hhid)
egen otherexp=max(other),by (hhid) 

*7 other events
egen expev=total (h415) , by (hhid)


*8. income
bysort hhid: egen income =total(h502) if n5 ~=15    // exclude remmitances 
gen annincome_c=income *12 
bysort hhid : egen annincome=total(annincome_c) 

*9.current labor migration
gen mig_c= (h601>=1 & !missing (h601))   // how many adult members currently live abroad 
gen pastmig=(h600>=1 & !missing (h600))                //at least one people migrated in last five years ; 
gen pmig_c=(mig==1 | pastmig==1) //at least one people migrated in last five years ; 

bysort hhid : egen mig=max(mig_c)
bysort hhid : egen pmig=max(pmig_c)

*10.remittances  ;

*  47.01   60.44   1.51 
*  USD	    EUR	    RUB	     
*year, sum
gen rem=h617_s if h617_c==1 & h617_t==3  
*used,month
replace rem=h617_s * 47.01 *12 if h617_c==2 & h617_t==1 
*used,year
replace rem=h617_s *47.01 if h617_c==2 & h617_t==2

*rube, month
replace rem=h617_s * 1.51 *12 if h617_c==3 & h617_t==1
*rube, year
replace rem=h617_s * 1.51 if h617_c==3 & h617_t==2
*euro, month 
replace rem=h617_s *  60.44 *12  if h617_c==4 & h617_t==1
*euro, year 
replace rem=h617_s *   60.44 if h617_c==4 & h617_t==2

gen rem_g =h625_s if h625_c==1
replace rem_g=h625_s * 47.01 if h625_c==2
replace rem_g=h625_s * 1.51 if h625_c==3
replace rem_g= h625_s * 60.44 if h625_c==4
replace rem_g =0 if rem_g ==. 

gen rem_total=rem + rem_g
summarize rem_total rem rem_g
replace rem_total=0 if rem_total==.


*11.mig destinations 
gen dest=h605 
bysort hhid: egen destination=max(dest)

*12. enviromental schocks  
g drought = (h701_1 ==1  )
g flood = ( h701_2 ==1 )
g coldwinter = (h701_3==1) 
g frosts = (h701_4==1) 

local exp "schexp foodexp nonfood cgoodsexp medexp commexp housing otherexp expev"
keep hhid hhage no_pp no_childr no_kid no_old marstat  land agactivity  annincome `exp' ///
	mig pmig  rem_total  rem rem_g destination drought flood coldwinter frosts
duplicates drop
foreach x of local exp {
replace `x'=0 if `x'==.
}
//N=2816

*merge household data within community data 
// migration network : percentage of hh that has at least one migrants over the past 5 years in the community;
merge 1:m hhid using "${data}\data2012\control\hh_cc_2012.dta", keep(matched)  //144 not matched. 

egen tmig_com = sum(pmig), by(cluster)  // total number of migrations at community level 
egen tmig_obl = sum(pmig), by(oblast)  // total number of migrations at oblast level 

gen ptmcom=tmig_com/thh  //percentage of migration at community level; 
gen ptcobl=tmig_obl/ohh

la var ptmcom "migration network (community)"
la var ptcobl "migration network (oblast) "

local exp "schexp foodexp nonfood cgoodsexp medexp commexp housing otherexp expev"
keep hhid cluster hhage no_pp no_childr no_kid no_old marstat land agactivity  annincome `exp' ///
	mig pmig  rem_total  rem rem_g destination ptmcom ptcobl drought  flood coldwinter frosts

	
*further revise vars
replace rem_total=0 if rem_total==.
g lrem=log( rem_total) 
g lincome=log(annincome)


* DV food expences
gen totalexp=foodexp+nonfood+expev+schexp
summarize foodexp nonfood expev schexp totalexp annincome

gen food_s=foodexp/totalexp 
gen med_s=medexp/totalexp
gen housing_s=housing/totalexp
gen event_s=expev/totalexp
gen schexp_s=schexp/totalexp

*other expences;
gen cgoods_s=cgoodsexp/totalexp
gen comm_s=commexp/totalexp
gen othercom_s=otherexp/totalexp

egen tconsum_s=rowtotal(food_s med_s housing_s event_s schexp_s cgoods_s comm_s othercom_s)  // very close to one 

sum food_s med_s housing_s event_s schexp_s cgoods_s comm_s othercom_s, detail
*tab oblast, gen (oblast)

replace agactivity =0 if agactivity==.

replace mig=0 if mig==.
gen remreceive = (rem_total >0.1) // & rem >0.1 ;
gen noremreceive= (mig==1 & rem_total==0)


gen remcat=1 if remreceive==1 
replace remcat=2 if noremreceive==1 
replace remcat=3 if mig==0
label define remcat 1 "Recieve Remettances"   2 "Receive no remittance"  3 "Non migrants"


*drop if food_2 ==. | cgoods==. | event_2==. | housing_2==. |comm==. | othercom==.

*****create of instruments***************
* (1) unexpected job creation in the destination countries  X age of hh head****
*generate percetage of pop work in russia
gen rus=(destination==1) 
*how many work in russia in the communiy ?
egen rus_com = sum(rus), by(cluster)  // total number of migrations in russian at community level 

gen iv1=0.70*rus_com*hhage 
*(2)community previous migration flow Xproportion of hh who have at least secondary level of ed
gen iv2=ptmcom*hhage


la var iv1"unexpected job creation "
la var iv2 "previous migration flow"

local share "food_s med_s housing_s event_s schexp_s cgoods_s comm_s othercom_s"
misschk `share', gen(m)
drop if mnumber>0    //N=2860

foreach x of var * { 
	rename `x' `x'2012
} 
// N=4814
save "${dir}\data_revise\hhmerged_2012", replace 




*==============2013==============
use "${data}\data2013\control\cc_hh.dta",clear
drop if particip==0

sort psu hhid13 
by psu: gen thh=_N  //total hh within a community;
sort oblast hhid13
by oblast: gen ohh=_N // total hh within oblast;
rename hhid13 hhid
rename psu cluster
keep hhid cluster oblast thh ohh
save "${data}\data2013\control\hh_cc_2013.dta" , replace 


// merge all the hh data together first 
cd "${data}\data2013\household" 
use hh1a,clear

merge m:m hhid using hh1b, nogen 
merge m:m hhid using hh2c, nogen 
merge m:m hhid using hh3,nogen 
merge m:m hhid using hh4a,nogen 
merge m:m hhid using hh4b, nogen
merge m:m hhid using hh4c, nogen
merge m:m hhid using hh5a, nogen
merge m:m hhid using hh5b, nogen
merge m:m hhid using hh6a, nogen
merge m:m hhid using hh6b, nogen
merge m:m hhid using hh7, nogen



*==========
*1.gender age ethnicity maritalstatus totalpp no_kid no_old 
egen no_pp= max (pid ) , by (hhid)
egen no_childr = sum(age < 18), by(hhid)
egen no_kid = sum(age < 2005), by(hhid) 
egen no_old= sum (age > 60 ), by (hhid)
clonevar marstat_h=h108 if h104==1 // hh head's marital stataus 
bysort hhid: egen marstat=max(marstat_h)

clonevar age_h=age if h104==1 // hh head's age
bysort hhid: egen hhage=max(age_h)

*2.education expenditure 
gen schexp_c=h121_5
bysort hhid: egen schexp=total(schexp_c)

*3. land
gen land_i=h224*h227_g if h227_g !=. & h224==1  //hecter 
replace land_i=(h224*h227_s)/100 if h227_s !=. & h224==1
replace land_i=0 if  h224==0
bysort hhid: egen land=total(land_i)
la var land "own land (hectar)"

*4.ag activity;
gen agact = (h301 ==1) 
bysort hhid: egen agactivity=max(agact)

replace h401a=0 if h401a==.
replace h403=0 if h403==.


*5.food expenses;
gen h401c_new=h401c*52 if h401d==1
replace h401c_new=h401c*12 if h401d==2
replace h401c_new=0 if h401c==.
g price=h401c_new/h401b
bysort hhid: egen foodexp = total(h401c_new)

*6.non-food expenses
gen h403_new= h403*12 if h404==1
replace h403_new=h403 if h404==2
bysort hhid: egen nonfood = total (h403_new)

*consumer goods  ;
bysort hhid: egen cgoods= total(h403_new) if n4b >=1 & n4b <6 
bysort hhid: egen cgoodsexp = max(cgoods)

*med;
bysort hhid: egen med =total (h403_new) if n4b == 6 | n4b==7  
bysort hhid: egen  medexp = max(med) 

*communitcation/transportation;
bysort hhid: egen comm= total (h403_new) if (n4b >=8 & n4b <= 10 )
bysort hhid: egen commexp=max(comm)

*housing exp;
bysort hhid: egen hhservice=total (h403_new) if  (n4b >10 & n4b <= 17) | n4b==23 |n4b==24 |n4b==27 
bysort hhid: egen hhdurable=total (h403_new) if n4b==22 |n4b==26 | (n4b >= 28 & n4b <= 32)
egen hhexp= rowtotal(hhservice hhdurable) 
bysort hhid: egen housing=max(hhexp)

bysort hhid: egen expev=total (h415)   //expences on events ;

*other goods;
bysort hhid: egen other=total (h403_new) if  ( n4b >= 18 & n4b <= 21 )| n4b==25 | n4b==33 
bysort hhid: egen otherexp=max(other)


*8. income
bysort hhid: egen income = total (h502) if source ~=9
gen annincome_c=income *12 
bysort hhid : egen annincome=total(annincome_c) 

*9.current labor migration
gen mig_c= (h601>=1 & !missing (h601))   // how many adult members currently live abroad 
gen pastmig=(h600>=1 & !missing (h600))                //at least one people migrated in last five years ; 
gen pmig_c=(mig==1 | pastmig==1) //at least one people migrated in last five years ; 

bysort hhid : egen mig=max(mig_c)
bysort hhid : egen pmig=max(pmig_c)


*10.remittances  ;
*  48.4386 64.3536  1.5223 0.3184
*  USD	EUR	RUB	KZT 

gen rem=h617_s if h617_c==1
replace rem=h617_s * 48.4386 if h617_c==2
replace rem=h617_s * 1.5223 if h617_c==3
replace rem= h617_s * 64.3536  if  h617_c==4
replace rem = 0 if rem ==.
gen rem_g =h625_s if h625_c==1
replace rem_g=h625_s * 48.4386 if h625_c==2
replace rem_g=h625_s * 1.5223 if h625_c==3
replace rem_g=h625_s * 64.3536 if  h625_c==4
replace rem_g =0 if rem_g ==. 
gen rem_total=rem + rem_g

*11.destination
gen dest=h605 
bysort hhid: egen destination=max(dest)


*12. enviromental schocks  
g drought = (h701_1 ==1  )
g flood = ( h701_2 ==1 )
g coldwinter = (h701_3==1) 
g frosts = (h701_4==1) 


local exp "schexp foodexp nonfood cgoodsexp medexp commexp housing otherexp expev"
keep hhid hhage no_pp no_childr no_kid no_old marstat  land agactivity  annincome `exp' ///
	mig pmig  rem_total  rem rem_g destination drought flood coldwinter frosts
duplicates drop
foreach x of local exp {
replace `x'=0 if `x'==.
}
// N=2586


*merge household data within community data 
merge 1:m hhid using "${data}\data2013\control\hh_cc_2013.dta", keep(matched)  //144 not matched. 

egen tmig_com = sum(pmig), by(cluster)  // total number of migrations at community level 
egen tmig_obl = sum(pmig), by(oblast)  // total number of migrations at oblast level 

gen ptmcom=tmig_com/thh  //percentage of migration at community level; 
gen ptcobl=tmig_obl/ohh

la var ptmcom "migration network (community)"
la var ptcobl "migration network (oblast) "

local exp "schexp foodexp nonfood cgoodsexp medexp commexp housing otherexp expev"
keep hhid cluster hhage no_pp no_childr no_kid no_old marstat land agactivity  annincome `exp' ///
	mig pmig  rem_total  rem rem_g destination ptmcom ptcobl drought  flood coldwinter frosts

	
*further revise vars
replace rem_total=0 if rem_total==.
g lrem=log( rem_total) 
g lincome=log(annincome)

gen totalexp=foodexp+nonfood+expev+schexp
summarize foodexp nonfood expev schexp totalexp annincome

* DV food expences
gen food_s=foodexp/totalexp 
gen med_s=medexp/totalexp
gen housing_s=housing/totalexp
gen event_s=expev/totalexp
gen schexp_s=schexp/totalexp

*other expences;
gen cgoods_s=cgoodsexp/totalexp
gen comm_s=commexp/totalexp
gen othercom_s=otherexp/totalexp

egen tconsum_s=rowtotal(food_s med_s housing_s event_s schexp_s cgoods_s comm_s othercom_s)  // very close to one 

sum food_s med_s housing_s event_s schexp_s cgoods_s comm_s othercom_s, detail


*tab oblast, gen (oblast)

replace agactivity =0 if agactivity==.

replace mig=0 if mig==.
gen remreceive = (rem_total >0.1) // & rem >0.1 ;
gen noremreceive= (mig==1 & rem_total==0)


gen remcat=1 if remreceive==1 
replace remcat=2 if noremreceive==1 
replace remcat=3 if mig==0
label define remcat 1 "Recieve Remettances"   2 "Receive no remittance"  3 "Non migrants"
tab remcat


*****create of instruments***************
* (1) unexpected job creation in the destination countries  X age of hh head****
*generate percetage of pop work in russia
gen rus=(destination==1) 
*how many work in russia in the communiy ?
egen rus_com = sum(rus), by(cluster)  // total number of migrations in russian at community level 

gen iv1=0.70*rus_com*hhage 
*(2)community previous migration flow Xproportion of hh who have at least secondary level of ed
gen iv2=ptmcom*hhage


la var iv1"unexpected job creation "
la var iv2 "previous migration flow"


local share "food_s med_s housing_s event_s schexp_s cgoods_s comm_s othercom_s"
misschk `share', gen(m)
drop if mnumber>0    //N=2860

foreach x of var * { 
	rename `x' `x'2013
} 

save "${dir}\data_revise\hhmerged_2013", replace 
	
