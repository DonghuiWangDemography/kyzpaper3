*2012
*updated on April 16th,2018
 **STEP 1: calcuate total size of hhd at oblast level and community level to prepare calculating migration networks;
clear
use "G:\RA\RAship Dr Chi\Community resiliency\paper3\LIK_10_13_stata\stata\data2012\control\cc_hh.dta"
sort cluster hhid12 
by cluster: gen thh=_N  //total hh within a community;
sort oblast hhid12
by oblast: gen ohh=_N // total hh within oblast;
rename hhid12 hhid
keep hhid cluster oblast thh ohh
save "G:\RA\RAship Dr Chi\Community resiliency\paper3\LIK_10_13_stata\stata\data2012\control\hh_cc_2012",replace




***STEP2: calculate hh level traits************

clear
cd "G:\RA\RAship Dr Chi\Community resiliency\paper3\LIK_10_13_stata\stata\data2012\household"
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
save hh1a_m_2012, replace


//land 
//100 sotka = 1 hectare = 2.4 acres. 
clear 
use hh2c.dta
gen land=h217*h220_g if h220_g !=. & h216==1  //hecter 
replace land=(h217*h220_s)/100 if h220_s !=. & h216==1
replace land=0 if  h216==0
la var land "own land (hectar)"
sort hhid
save hh2c_2012, replace



* any type of ah ag activity;
use hh3
gen agactivity = (h301 ==1) 
sort hhid
keep hhid ag 
duplicates drop
save hh3_m_2012, replace 

*food;
use hh4a.dta
*expenses on purchased food;
gen h401c_new=h401c
replace h401c_new=h401c*52 if h401d==1
replace h401c_new=h401c*12 if h401d==2
replace h401c_new=h401c*4 if h401d==3
replace h401c_new=0 if h401c==.

*g price=h401a_new/h401_b

egen foodexp = total(h401c_new), by (hhid)
duplicates drop
keep foodexp hhid 
duplicates drop
sort hhid
save hh4a_m_2012, replace


use hh4b.dta, clear
* usd 47.01 Eur 60.44  RUB 1.51
/* som, per month */
list  h403 h404 h405 in 1/40
gen  nonfoode=h403
replace  nonfoode=h403*12 if h404==1 & h405==1  
* used, per month */
replace nonfoode=h403*47.01*12 if h404==2 & h405==1  
*usd, per year 
replace nonfoode=h403*47.01 if h404==2 & h405==1
egen nonfood=total (nonfoode), by (hhid)

sum nonfood
*consumer goods  ;
egen cgoods= total (nonfoode) if n4b >=1 & n4b <5 , by(hhid)
egen cgoodsexp = max (cgoods) , by (hhid)

*med;
egen med =total (nonfoode) if n4b == 5 | n4b==6 , by (hhid) 
egen  medexp = max (med) , by (hhid)

* communication
egen comm= total (nonfoode) if n4b ==7 |  n4b == 8 , by(hhid)
egen commexp=max(comm), by (hhid)


*housing exp;
egen hhsevice=total (nonfoode) if  (n4b >8 & n4b <= 15) , by (hhid)
egen hhdurable=total (nonfoode) if n4b >19 & n4b <= 25 , by (hhid)
egen hhexp= rowtotal(hhsevice hhdurable) 
egen housing=max (hhexp), by (hhid)
sum hhexp housing 
list  nonfoode hhsevice hhdurable hhexp housing  in 1/30
*others 
*other goods;
egen other=total (nonfoode) if   ( n4b >= 16 & n4b <= 19 )| n4b==26 ,by (hhid)
egen otherexp=max(other),by (hhid)

keep nonfood cgoodsexp medexp commexp housing  otherexp hhid
duplicates  drop 
save hh4b_m_2012, replace

* expences on events ;
use hh4c.dta
egen expev=total (h415) , by (hhid)
sum (expev)
sort hhid
keep hhid expev
save hh4c_m_2012, replace 


* income
*source of income;
clear
use hh5.dta
egen ag=total (h502) if n5==1 | n5==2 , by(hhid)
gen ag_in=ag*12
egen other=total (h502) if n5 >2 &(n5 !=15& n5!=16), by(hhid)   // exclude remittance from this chunck. bx need to calculate rem separately;
gen other_in=other*12
egen income_labor = total (h502) , by (hhid)
gen annincome=income_labor *12 
keep  ag_in other_in annincome hhid
duplicates drop 
sort hhid
save hh5_m_2012, replace 


*current labor migration
*note : the questionaire is different from 2011;
use hh6.dta
sort hhid
gen mig= (h601>=1 & !missing (h601))
gen pastmig=(h600>=1 & !missing (h601))  // have ppl worked past 5yrs 
gen pmig=(mig==1 | pastmig==1) //at least one people migrated in last five years ; 
keep mig pmig hhid
duplicates drop


***********merge total hhsize within a community 
// create migration network : percentage of hh that has at least one migrants over the past 5 years in the community;
merge 1:m hhid using "G:\RA\RAship Dr Chi\Community resiliency\paper3\LIK_10_13_stata\stata\data2012\control\hh_cc_2012.dta"

egen tmig_com = sum(pmig), by(cluster)  // total number of migrations at community level 
egen tmig_obl = sum(pmig), by(oblast)  // total number of migrations at oblast level 

gen ptmcom=tmig_com/thh  //percentage of migration at community level; 
gen ptcobl=tmig_obl/ohh //percentage of migration at oblast level; 
tab ptmcom
tab ptcobl
la var ptmcom "migration network (community)"
la var ptcobl "migration network (oblast) "

keep hhid mig ptmcom ptcobl cluster
sort hhid
save hh6_m_2012, replace 


*migration destination;
use hh6a.dta
tab h605
gen destination=h605 
keep hhid destination
sort hhid
save hh6a_m_2012, replace 

/*  russia |        567       94.34       94.34
 kazakhstan |         25        4.16       98.50
      other |          9        1.50      100.00
*/

*remittances  ;
clear
use hh6b.dta

*  47.01   60.44   1.51 
*  USD	    EUR	    RUB	     
*year, sum
gen rem=h617_s if h617_c==1 & h617_t==3  
*used,month
replace rem=h617_s * 47.01 *12 if h617_c==2 & h617_t==1 
*used,year
replace rem=h617_s *47.01 if h617_c==2 & h617_t==2

*roble, month
replace rem=h617_s * 1.51 *12 if h617_c==3 & h617_t==1
 *roble, year
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

sort hhid
keep hhid rem_total rem rem_g
save hh6b_m_2012 , replace

*outside shocks;
use hh7.dta
sort hhid
save hh7_m_2012, replace 

*drop _merge
merge  hhid using  hh1a_m_2012 hh2c_2012 hh3_m_2012  hh4a_m_2012 hh4b_m_2012 hh4c_m_2012 hh5_m_2012 hh6_m_2012 hh6a_m_2012 hh6b_m_2012 hh7_m_2012
drop _merge*


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

* enviromental changes 
g drought = (h701_1 ==1)
g flood = ( h701_2 ==1 )
g coldwinter = (h701_3==1) 
g frosts = (h701_4==1) 

* geography
*gen rural = (residence ==2)

* DV food expences
gen totalexp=foodexp+nonfood
gen totalexp_2=foodexp+nonfood+expev
*summarize foodexp nonfood expev totalexp annincome
sum foodexp nonfood expev totalexp_2 housing

*gen food_1=foodexp/totalexp
gen food_2=foodexp/totalexp_2 
*gen food_3= foodexp/ (foodexp+nonfood)
*gen med_1=medexp/totalexp
gen med_2=medexp/totalexp_2
*gen med_3=medexp/ (foodexp+nonfood)
*gen housing_1=housingexp/totalexp
gen housing_2=housing/totalexp_2
*gen ed_1=edexp/income 
*gen event_1=expev/totalexp
gen event_2=expev/totalexp_2

*other expences;
g cgoods=cgoodsexp/totalexp_2
gen comm=commexp/totalexp_2
gen othercom=otherexp/totalexp_2

gen tconsum= food_2+cgoods+med_2+housing_2+event_2+comm+othercom
*list food_2 cgoods housing_2 med_2 event_2 comm othercom tconsum in 1/30

sum food_2 cgoods housing_2 med_2 event_2 comm othercom tconsum

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

drop if food_2 ==. | med_2==. | cgoods==. | event_2==. | housing_2==. |comm==. | othercom==.

*sum food_2 cgoods housing_2 med_2 event_2 comm othercom 

*****************************************
*****create of instruments***************
* (1) unexpected job creation in the destination countries  X age of hh head****
*generate percetage of pop work in russia
gen rus=(destination==1) 
*how many work in russia in the communiy ?
egen rus_com = sum(rus), by(cluster)  // total number of migrations in russian at community level 

gen iv1=0.70*rus_com*age 
*(2)community previous migration flow Xproportion of hh who have at least secondary level of ed
gen iv2=ptmcom*age


la var iv1"unexpected job creation "
la var iv2 "previous migration flow"

foreach x of var * { 
	rename `x' `x'2012
} 


*save hhmerged_2012, replace

*save G:\RA\RAship_Dr_Chi\Community_resiliency\paper3\LIK_10_13_stata\stata\panel\hhmerged_2012,replace 
duplicates drop  
sort hhid 
save G:\RA\KYZpanel\hhmerged_2012,replace 
*save G:\RA\RAship Dr Chi\Community resiliency paper3\LIK_10_13_stata\stata\panel\hhmerged_2012,replace
clear

