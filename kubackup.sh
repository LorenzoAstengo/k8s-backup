#!/bin/bash

if [[ $1 == -n=* ]] || [[ $1 == --namespace=* ]]
then
        namespace=${1#*=}
elif [[ $1 == -n ]] || [[ $1 == --namespace ]] || [[ -z $2 ]]
then
        namespace=$2
fi

echo Starting export...
mkdir $namespace
cd $namespace

mkdir deployments
cd deployments
echo Storing deployments...
for deployment in $(kubectl -n $namespace get deployments | awk 'NR>1{print $1}')
do
        kubectl -n $namespace get deployment $deployment -oyaml > ${deployment}.yaml
        echo "=> deployment $deployment stored."
done
cd ..

mkdir persistentVolumes
cd persistentVolumes
echo Storing persistentVolumes...
for pv in $(kubectl -n $namespace get pv | awk 'NR>1{print $1}')
do
        kubectl -n $namespace get pv $pv -oyaml > ${pv}.yaml
        echo "=> persistenVolume $pv stored."
done
cd ..

mkdir persistentVolumeClaim
cd persistentVolumeClaim
echo Storing persistentVolumeClaim...
for pvc in $(kubectl -n $namespace get pvc | awk 'NR>1{print $1}')
do
        kubectl -n $namespace get pvc $pvc -oyaml > ${pvc}.yaml
        echo "=> persistenVolumeClaim $pvc stored."
done
cd ..

mkdir services
cd services
echo Storing services...
for svc in $(kubectl -n $namespace get svc | awk 'NR>1{print $1}')
do
        kubectl -n $namespace get svc $svc -oyaml > ${svc}.yaml
        echo "=> service $svc stored."
done
cd ..

mkdir configMaps
cd configMaps
echo "Storing configmaps.."
for cm in $(kubectl -n $namespace get cm | awk 'NR>1{print $1}')
do
        mkdir $cm
        kubectl -n $namespace describe cm $cm > "$cm/$cm"
        echo "=> created folder of configmap $cm."
done

for dir in $(ls)
        do
                file="$dir/$dir"
                subfileName=$dir/tmpFile

                while IFS= read -r line
                do
                        if [ "$line" == "----" ]
                        then
                                sed -i '$ d' $subfileName
                                subfileName=$dir/$(echo $previousLine | tr -d ':')
                                echo "==>storing file $subfileName..."
                        elif [ "$(echo $line | awk '{print $1}')" == "Events:"  ]
                        then
                                break
                        else
                                echo "$line" >> "$subfileName"
                        fi

                        previousLine=$line
                done < "$file"

                rm $dir/$dir $dir/tmpFile
done
cd ..

mkdir ingress
cd ingress
echo Storing ingress...
for ingress in $(kubectl -n $namespace get ingress | awk 'NR>1{print $1}')
do
        kubectl -n $namespace get ingress $ingress -oyaml > ${ingress}.yaml
        echo "=> ingress $ingress stored."
done
cd ..

echo Cleaning all meta information...
declare -a personalParams=("annotations" "revision" "last-applied-configuration" "creationTimestamp" "generation" "resourceVersion" "selfLink" "uid" "progressDeadlineSeconds" "{\"apiVersion" "clusterIP:")
for par in "${personalParams[@]}"
do
        find ./ -type f -exec sed -i "s/^.*$par.*$//g" {} \;
done

find ./ -type f -exec sed -i '/^[[:space:]]*$/d' {} \;

for file in $(find ./ -type f | grep -v configMaps)
do
        line=$(grep -n '^status:' $file | cut -d ':' -f 1)
        tmpFile=$(mktemp $(pwd)/tmp.XXXX)
        cp $file $tmpFile
        awk -v "statusLine=$line" "NR<statusLine {print}" $tmpFile > $file
        rm $tmpFile
done


cd ..
echo Done.
