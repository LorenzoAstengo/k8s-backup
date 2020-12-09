#!/bin/bash
#Caricamento alias
source /home/$USER/.bash_profile
shopt -s expand_aliases

clean=false
cmyaml=false

for i in "$@"; do
        case $i in
        -n=*)
                namespace="${i#*=}"
                shift
                ;;
        -clean)
                clean=true
                shift
                ;;
        --clean)
                clean=true
                shift
                ;;
        --cmyaml)
                cmyaml=true
                shift
                ;;
        -h*)
                echo "Arguments: -n=<namespace>"
                echo "Optionals: -clean or --clean (remove metadata informations) --cmyaml (backup cm as yaml file)"
                exit 1
                ;;
        *)
                echo "Wrong argument! Please use:"
                echo "Arguments: -n=<namespace>"
                echo "Optionals: -clean or --clean (remove metadata informations) --cmyaml (backup cm as yaml file)"
                exit 1
                ;;
        esac
done

if [[ -z $namespace ]]; then
        read -p "Namespace: " namespace
fi

echo Starting export...
if $clean; then
        if [[ -d ${namespace}-clean ]]; then
                mv ${namespace}-clean ${namespace}-clean-OLD
        fi
        mkdir ${namespace}-clean
        cd ${namespace}-clean
else
        if [[ -d ${namespace} ]]; then
                mv ${namespace} ${namespace}-OLD
        fi
        mkdir $namespace
        cd $namespace
fi

mkdir deployments
cd deployments
echo Storing deployments...
for deployment in $(kubectl -n $namespace get deployments | awk 'NR>1{print $1}'); do
        kubectl -n $namespace get deployment $deployment -oyaml >${deployment}.yaml
        echo "=> deployment $deployment stored."
done
cd ..

mkdir persistentVolumes
cd persistentVolumes
echo Storing persistentVolumes...
for pv in $(kubectl -n $namespace get pv | awk 'NR>1{print $1}'); do
        kubectl -n $namespace get pv $pv -oyaml >${pv}.yaml
        echo "=> persistenVolume $pv stored."
done
cd ..

mkdir persistentVolumeClaim
cd persistentVolumeClaim
echo Storing persistentVolumeClaim...
for pvc in $(kubectl -n $namespace get pvc | awk 'NR>1{print $1}'); do
        kubectl -n $namespace get pvc $pvc -oyaml >${pvc}.yaml
        echo "=> persistenVolumeClaim $pvc stored."
done
cd ..

mkdir services
cd services
echo Storing services...
for svc in $(kubectl -n $namespace get svc | awk 'NR>1{print $1}'); do
        kubectl -n $namespace get svc $svc -oyaml >${svc}.yaml
        echo "=> service $svc stored."
done
cd ..

mkdir configMaps
cd configMaps
echo "Storing configmaps.."
if ($cmyaml); then
        echo "ConfigMaps in yaml mode"
        for cm in $(kubectl -n $namespace get cm | awk 'NR>1{print $1}'); do
                kubectl -n $namespace get cm $cm -oyaml >${cm}.yaml
                echo "=> ConfigMap $cm stored."
        done
else
        for cm in $(kubectl -n $namespace get cm | awk 'NR>1{print $1}'); do
                mkdir $cm
                kubectl -n $namespace describe cm $cm >"$cm/$cm"
                echo "=> created folder of configmap $cm."
        done
        for dir in $(ls); do
                file="$dir/$dir"
                subfileName=$dir/tmpFile

                while IFS= read -r line; do
                        if [ "$line" == "----" ]; then
                                sed -i '$ d' $subfileName
                                subfileName=$dir/$(echo $previousLine | tr -d ':')
                                echo "==>storing file $subfileName..."
                        elif [ "$(echo $line | awk '{print $1}')" == "Events:" ]; then
                                break
                        else
                                echo "$line" >>"$subfileName"
                        fi

                        previousLine=$line
                done <"$file"

                rm $dir/$dir $dir/tmpFile
        done
fi
cd ..

mkdir ingress
cd ingress
echo Storing ingress...
for ingress in $(kubectl -n $namespace get ingress | awk 'NR>1{print $1}'); do
        kubectl -n $namespace get ingress $ingress -oyaml >${ingress}.yaml
        echo "=> ingress $ingress stored."
done
cd ..

mkdir gateways
cd gateways
echo Storing gateways...
for gw in $(kubectl -n $namespace get gw 2>/dev/null | awk 'NR>1{print $1}'); do
        kubectl -n $namespace get gw $gw -oyaml >${gw}.yaml
        echo "=> gateway $gw stored."
done
cd ..

mkdir virtualServices
cd virtualServices
echo Storing virtual services...
for vs in $(kubectl -n $namespace get vs 2>/dev/null | awk 'NR>1{print $1}'); do
        kubectl -n $namespace get vs $vs -oyaml >${vs}.yaml
        echo "=> virtual service $vs stored."
done
cd ..

mkdir serviceAccounts
cd serviceAccounts
echo Storing service accounts...
for sa in $(kubectl -n $namespace get serviceaccounts 2>/dev/null | awk 'NR>1{print $1}'); do
        kubectl -n $namespace get serviceaccounts $sa -oyaml >${sa}.yaml
        echo "=> virtual service $sa stored."
done
cd ..

if $clean; then
        echo Cleaning all meta information...
        declare -a personalParams=("annotations:" "revision:" "last-applied-configuration:" "creationTimestamp:" "generation:" "resourceVersion:" "selfLink:" "uid:" "progressDeadlineSeconds:" "{\"apiVersion" "clusterIP:" "pv.kubernetes.io\/bound-by-controller: \"yes\"" "bind-completed:" "kubectl.kubernetes.io\/restartedAt:" "meta.helm.sh")
        for par in "${personalParams[@]}"; do
                for file in $(find . -type f); do
                        sed -i "s/^.*$par.*$//g" $file
                done

        done

        find . -type f -exec sed -i '/^[[:space:]]*$/d' {} \;

        for file in $(find . -type f | grep -v configMaps | grep -v gateways | grep -v virtualServices); do
                line=$(grep -n '^status:' $file | cut -d ':' -f 1)
                sed -i ''"$line"',$d' $file
        done
        cd ..
fi
echo Done.
