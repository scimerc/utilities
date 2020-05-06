gen_file="gen.sorted.perfect_yield.pub_risk.four"
risk_file="published_beta_no_LRRK2.txt"
# risk_file="published_beta.txt"
# lists="
#     ~/work/data/phenotypes/binary/Parkinson_Disease_09032012.txt
# "
lists="
    ~/work/data/phenotypes/binary/Parkinson_Disease_09032012.txt
    ~/work/data/phenotypes/binary/Parkinson_Familial_20032012.txt
    ~/work/data/phenotypes/binary/Parkinson_Sporadic_20032012.txt
    ../LRRK2_with_PD.txt
    ../LRRK2_without_PD_older70.txt
    ../control.yield.defsex.ceu.bb1940.without_PD.pns
"
for list_A in ${lists} ; do
    command="compute_cumulative_risk.Rscript -g ${gen_file} -a ${list_A} -r ${risk_file}"
    echo "${command}"
    $command > ttest_$(basename ${list_A} ".txt")
    for list_B in ${lists} ; do
        if [[ "${list_A}" < "${list_B}" ]] ; then
            command="compute_cumulative_risk.Rscript -g ${gen_file} -a ${list_A} -c ${list_B} -r ${risk_file}"
            echo "${command}"
            ${command} > ttest_$(basename ${list_A} ".txt")_vs_$(basename ${list_B} ".txt")
        fi
    done
done
# echo -e "test\tt\tdf\tp" > ttest.results.txt
# for ttfile in ttest_* ; do
#     echo -n "${ttfile} " ; grep -B 1 "alternative hypothesis" ${ttfile} | head -1
# done | tr -d , | mycols 1,4,7,10 >> ttest.results.txt
echo -e "test\testimate\terror\teffect\tp-value" > logistic_regression_results.txt
egrep "^cumulative_effect[[:space:]]" ttest_* | \
    sed 's/:cumulative_effect//g;' | tab >> logistic_regression_results.txt
for ttfile in ttest_* ; do
    echo -n "${ttfile} " ; grep -A 1 "mean of " ${ttfile} | tail -n 1 | mycols 1
done | tr -d , | grep -v "_vs_" > cumulative_risk_means.txt

