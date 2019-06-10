*2010 community 

clear
*global dir "E:\revise&resubmit\KYZpaper\paper3"  // usb office

global logs "${dir}\logs"
global tables "${dir}\tables"
global data "${dir}\LIK_10_13_stata\stata"

cd "${data}\data2010\community"
use cm1.dta,clear
clonevar npp=c102
replace c103=0 if c103==.
g pctmig=c103/100
g nmig=int(c102*pctmig)

clonevar post=c105_12
clonevar bank=c105_13
clonevar credit=c105_14
clonevar mta=c105_15

g agency=(post==1 | bank==1 | mta==1 | credit==1 ) 
egen nagency=anycount(post bank credit mta), values(1)
keep cluster obl post bank credit mta agency nagency npp pctmig nmig
tempfile cm
save `cm.dta',replace 
* how to leverage this information ?


use "${data}\data2010\control\hhcontrol.dta",clear
keep hhid oblast cluster soate location 
duplicates drop 
save "${data}\data2010\household\ctr.dta", replace


*calculate migration network
clear
cd "${data}\data2010\household"
use hh1a,clear
by hhid: g no_pp=_N  // household size 
keep hhid no_pp 
duplicates drop 
tempfile hh
save `hh',replace 

use hh6a1,clear  //N=363
g nmig=h601
keep hhid nmig  // 92 % have one or two mirgants 
tempfile a1
save `a1.dta',replace 


use hh6a2,clear  // N=363
*destination 
g rus=(h605==1)
g kaz=(h605==2)
g oth=(h605>=4 & h605<=10)

bysort hhid: egen rushh=max(rus)  // household has people migrated in russian 
bysort hhid: egen kazhh=max(kaz)  // household has people migrated in kaz 


bysort hhid: egen nrus=total(rus)
bysort hhid: egen nkaz=total(kaz) 
bysort hhid: egen noth=total(oth)
keep hhid nrus nkaz noth rushh kazhh
duplicates drop

merge 1:1 hhid using `a1.dta',nogen
merge 1:1 hhid using `hh.dta', nogen 
merge 1:1 hhid using "${data}\data2010\household\ctr.dta",nogen

merge m:1 cluster using `cm.dta' , nogen

bysort cluster : egen crus10=total(nrus)
bysort cluster : egen ckaz10=total(nkaz)
bysort cluster : egen cnmig10=total(nmig)
bysort cluster : egen npp10=total(no_pp)

*percentage of households that has migrants in Russian 
bysort cluster : gen thh=_N
bysort cluster : egen  rhhc=total(rushh)
bysort cluster : egen  rkazc=total(kazhh)
g mignet=cnmig10/npp10

replace rushh=0 if rushh==.
replace kazhh=0 if kazhh==.


gen rushhp=rhhc/thh
gen kazhhp=rkazc/thh

bysort oblast : egen  obcrus10=total(nrus)
bysort oblast : egen  obpp=total(no_pp)
g obrus10=obcrus10/obpp

*keep hhid cluster oblast cnmig10 cprus10 cpkaz10  
*merge m:1 cluster using `cm.dta' , nogen

g cprus10=crus10/npp10
g cpkaz10=ckaz10/npp10  



save "${dir}\data_revise\com10", replace 
