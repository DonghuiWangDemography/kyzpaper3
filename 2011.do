 *2011
 *updated on March 25th 2018
 *task : created community-level variable on the percentage ppl who migranted out among total population ? 
* updaated on April 16th, 2018 
*task : 1. record income 2, retrieve land use information 

 **STEP 1: calcuate total size of hhd at oblast level and community level to prepare calculating migration networks;

 *updated on May 24, 2019
 *task :  add eduational expenditure 
 
 
clear
global dir "E:\revise&resubmit\KYZpaper\paper3"  // usb office

global logs "${dir}\logs"
global tables "${dir}\tables"
global data "${dir}\LIK_10_13_stata\stata"


use "${data}\data2011\control\cc_hh.dta", clear
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
save "${data}\data2011\control\hh_cc_2011.dta", replace 
*121 cluster 


***STEP2: calculate hh level traits************ 
clear
cd "${data}\data2011\household"
*gender age ethnicity maritalstatus totalpp no_kid no_old 
use hh1a.dta
egen no_pp= max (pid ) , by (hhid)
egen no_childr = sum(age < 18), by(hhid)
egen no_kid = sum(age < 2005), by(hhid) 
egen no_old= sum (age > 60 ), by (hhid)
*egen school_kid = sum ( h103a  60 )
sort hhid 
keep if h104==1
duplicates drop
save hh1a_m_2011, replace

//education expenditure 
use hh1b.dta, clear 
gen schexp_c=h121_4
bysort hhid: egen schexp=total(schexp_c)
keep hhid schexp
duplicates drop
save hh1b_m_2011, replace 


//land 
//100 sotka = 1 hectare = 2.4 acres. 
clear 
use hh2c.dta
gen land_i=h217*h220_g if h220_g !=. & h216==1  //hecter 
replace land_i=(h217*h220_s)/100 if h220_s !=. & h216==1
replace land_i=0 if  h216==0
bysort hhid: egen land=total(land_i)
keep hhid land 

duplicates drop
la var land "own land (hectar)"
save hh2c_2011, replace


*ag activity;
clear
use hh3
gen agactivity = (h301 ==1) 
sort hhid
keep hhid ag 
duplicates drop
save hh3_m_2011, replace 

*food;
clear
use hh4a.dta
*expenses on purchased food;
gen h401a_new=h401a
replace h401a_new=h401a*52 if h401b==1
replace h401a_new=h401a*12 if h401b==2
replace h401a_new=h401a*4 if h401b==3
replace h401a_new=0 if h401a==.
egen foodexp = total(h401a_new), by (hhid)
duplicates drop
keep foodexp hhid 
duplicates drop
sort hhid
save hh4a_m_2011, replace

//non-food expenses
* used 46.14
use hh4b.dta
gen nonfoode=h403
replace nonfoode=h403*12 if h404==1 & h405==1
replace nonfoode=h403*46.14*12 if h404==2 & h405==1
replace nonfoode=h403*46.14 if h404==2 & h405==2
egen nonfood=total (nonfoode), by (hhid)

*detailed non-food expenses 
*consumer goods  ;
egen cgoods= total (nonfoode) if nitem ==1 | nitem ==2  | nitem ==19, by(hhid)
egen cgoodsexp = max (cgoods) , by (hhid)

*med;
egen med =total (nonfoode) if nitem == 3 | nitem==4 , by (hhid) 
egen  medexp = max (med) , by (hhid)

* communication
egen comm= total (nonfoode) if nitem ==14 |nitem ==15 , by(hhid)
egen commexp=max(comm), by (hhid)

*housing exp;
egen hhexp=total (nonfoode) if  (nitem >4 & nitem <= 12) , by (hhid)
egen housing=max (hhexp), by (hhid)
*others 
*other goods;
egen other=total (nonfoode) if nitem==13 | ( nitem >= 16 & nitem <= 18 )| nitem==20 |  nitem==21 ,by (hhid)
egen otherexp=max(other),by (hhid)

keep nonfood cgoodsexp medexp commexp housing  otherexp hhid
duplicates  drop 
save hh4b_m_2011, replace

//expences on events ;
use hh4c.dta
egen expev=total (h415) , by (hhid)
sum (expev)
sort hhid
keep hhid expev
duplicates drop
save hh4c_m_2011, replace 


* income
*source of income;
clear
use hh5.dta
bysort hhid: egen income =total(h502) if n5 !=15 // exclude remmitances 
gen annincome=income *12 
keep  annincome hhid
duplicates drop 
sort hhid
save hh5_m_2011, replace 

*current labor migration
use hh6.dta, clear 
sort hhid
gen mig= (h601>=1 & !missing (h601)) // how many adult members currently live abroad 
gen pmig=(h600a==1)                  //at least one people migrated in last five years ; 
keep mig pmig  hhid
duplicates drop  //2863
sort hhid 

*merge total hhsize within a community 
// migration network : percentage of hh that has at least one migrants over the past 5 years in the community;
merge 1:1 hhid using "${data}\data2011\control\hh_cc_2011.dta", keep(matched)  //144 not matched. 

*list hhid cluster pmig thh ohh in 1/80

egen tmig_com = sum(pmig), by(cluster)  // total number of migrations at community level 
egen tmig_obl = sum(pmig), by(oblast)  // total number of migrations at oblast level 

gen ptmcom=tmig_com/thh  //percentage of migration at community level; 
gen ptcobl=tmig_obl/ohh


la var ptmcom "migration network (community)"
la var ptcobl "migration network (oblast) "

keep hhid mig ptmcom ptcobl cluster
sort hhid
save hh6_m_2011, replace 


*destination countries;
use hh6a.dta, clear
gen destination=h605 
tab destination,nolab // 1==russian 
keep hhid destination
duplicates drop  
sort hhid
save hh6a_m_2011, replace 

/*
in which country does 
currently live?	Freq.	Percent	Cum.
			
russia	524	91.77	91.77
kazakhstan	35	6.13	97.90
turkey	2	0.35	98.25
(other) european countries	6	1.05	99.30
other asian countries	2	0.35	99.65
other	2	0.35	100.00
			
Total	571	100.00

*/


*remittances  ;
clear
use hh6b.dta

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

sort hhid
keep hhid rem_total rem rem_g
save hh6b_m_2011 , replace


*outside shocks;
use hh7.dta
sort hhid
save hh7_m_2011, replace 

/*
use hh1a
sort hhid
save, replace 

use hh1b
sort hhid
save, replace 
*/

use hh1a_m_2011, clear 
merge 1:1 hhid using hh1b_m_2011, nogen  
merge 1:1 hhid using hh2c_2011,   nogen    
merge 1:1 hhid using hh3_m_2011,  nogen    
merge 1:1 hhid using hh4a_m_2011, nogen  
merge 1:1 hhid using hh4b_m_2011, nogen
merge 1:1 hhid using hh4c_m_2011, nogen
merge 1:1 hhid using hh5_m_2011,  nogen 
merge 1:1 hhid using hh6_m_2011,  nogen
merge 1:1 hhid using hh6a_m_2011, nogen
merge 1:1 hhid using hh6b_m_2011, nogen 
merge 1:1 hhid using hh7_m_2011,  nogen 




*****
*Controlls
*generate dependent variables ;
replace rem_total=0 if rem_total==.
g lrem=log( rem_total) 
/*
*demographics of the hh;
*gen female=(h102 == 2)
*gen age =h103a
*tab h105, gen (ethnicity)
rename ethnicity1 kyz
rename ethnicity2 uzb 
rename ethnicity3 rus
gen other= (h105 > 4)

*/
tab h108, gen(mar)
rename mar1 married
rename mar2 divorced 

*don't forget no_pp no_kid no_old

*household income;
*replace aincome_social=0 if aincome_social==.
*replace annincome=0 if annincome==.
*gen income=annincome + aincome_social 
g lincome=log(annincome)

* enviromental schocks  
g drought = (h701_1 ==1  )
g flood = ( h701_2 ==1 )
g coldwinter = (h701_3==1) 
g frosts = (h701_4==1) 

* geography
*gen rural = (residence ==2)

* DV food expences
gen totalexp=foodexp+nonfood
gen totalexp_2=foodexp+nonfood+expev+schexp
summarize foodexp nonfood expev schexp totalexp annincome

*gen food_1=foodexp/totalexp
gen food_2=foodexp/totalexp_2 
gen med_2=medexp/totalexp_2
gen housing_2=housing/totalexp_2
gen event_2=expev/totalexp_2
gen schexp_2=schexp/totalexp_2

*other expences;
g cgoods=cgoodsexp/totalexp_2
gen comm=commexp/totalexp_2
gen othercom=otherexp/totalexp_2


gen tconsum= food_2+cgoods+med_2+housing_2+event_2+comm+othercom+schexp_2
list food_2 cgoods housing_2 med_2 event_2 schexp_2 comm othercom tconsum in 1/30

sum food_2 cgoods housing_2 med_2 schexp_2 event_2 comm othercom 

*tab oblast, gen (oblast)

replace agactivity =0 if agactivity==.

replace mig=0 if mig==.
gen remreceive = (rem_total >0.1) // & rem >0.1 ;
gen noremreceive= (mig==1 & rem_total==0)

tab remreceive 
tab mig
tab noremreceive


gen remcat=1 if remreceive==1 
replace remcat=2 if noremreceive==1 
replace remcat=3 if mig==0
label define remcat 1 "Recieve Remettances"   2 "Receive no remittance"  3 "Non migrants"
tab remcat


drop if food_2 ==. | cgoods==. | event_2==. | housing_2==. |comm==. | othercom==.

*****************************************
*****create of instruments***************
* (1) unexpected job creation in the destination countries  X age of hh head****
*generate percetage of pop work in russia
gen rus=(destination==1) 
*how many work in russia in the communiy ?
egen rus_com = sum(rus), by(cluster)  // total number of migrations in russian at community level 

gen iv1=0.89*rus_com*age 
*(2)community previous migration flow Xproportion of hh who have at least secondary level of ed
gen iv2=ptmcom*age

la var iv1"unexpected job creation "
la var iv2 "previous migration flow"
foreach x of var * { 
	rename `x' `x'2011 
} 

*save hhmerged_2011, replace

duplicates drop
**IV share of the hh live abroad in community;


sort hhid 
*save G:\RA\KYZpanel\hhmerged_2011,replace 
save "E:\revise&resubmit\KYZpaper\paper3\data_revise\hhmerged_2011", replace 


***community-level migration networks*************************************
//total numbe of hosehold in the community 


**try ols
*use hhmerged_2011
//reg  food_2 lrem lincome agactivity  married  no_old no_kid drought flood coldwinter frosts  

*erase temporary files 
#delimit;
local data "hh1a_m_2011.dta hh1b_m_2011.dta hh2c_2011.dta  hh3_m_2011.dta  hh4a_m_2011.dta hh4b_m_2011.dta hh4c_m_2011.dta
            hh5_m_2011.dta hh6_m_2011.dta hh6a_m_2011.dta hh6b_m_2011.dta hh7_m_2011.dta" ;
#delimit cr

foreach x of local data {
erase `x'
}

