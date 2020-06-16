#Paths

if [[ -z "$moodlebasepath" ]]; then 
  moodlebasepath=$HOME/contest/
fi
if [[ -z "$graderbasepath" ]]; then 
  graderbasepath=$moodlebasepath/grader/
fi

#path for benchmarker.c  Makefile ...
export contestfilespath=$moodlebasepath/files/
#path to save downloaded files. THIS MUST BE $(pwd)/submissions when calling timer.sh (getsubmissions.sh uses that dir)
export submissionspath=$moodlebasepath/submissions/
export lockfile=$moodlebasepath/lockfile
export moodletmppath=$moodlebasepath/tmp/

export gradingpath=$graderbasepath/grading/
export resultpath=$graderbasepath/result/
export pastsubmissionspath=$graderbasepath/pastsubmissions/


#Input

#assignment ids separated by commas (e.g. exercise=139207,139209,139211)

exercise=182294,182296,182298
#,140430,140435,140432,140434




#Output

#text field ids as json
#e.g. jsontaskresults='{"97429": "maximum_bench", "97427": "prefix_bench", "97431": "pj_bench", "97433": "sort_bench", "97435": "lenz_bench", "97437": "lr_bench"}'

jsontaskresults='{"139208": "maximum_bench", "139206": "prefix_bench", "139210": "pj_bench", "140436": "sort_bench", "140429": "median_bench", "140431": "lenz_bench", "140433": "lr_bench"}'

#text field id for error messages

failedresult=139215


