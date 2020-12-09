# k8s-backup
k8s-backup is a useful script to make a backup of all the resources of a namespace on kubernetes.

The script exports:
* deployments
* services
* configMaps
* persistentVolumes
* persistentVolumeClaim
* ingress
* gateways
* virtualServices
* serviceAccounts

The script creates in the current path a folder called as the namespace, all backup files are generated in it. All resources are saved in yaml files, those contained in the configMaps are instead saved separately from each other in special folders.
It also has a clean mode that **does not save** the cluster resource information in all generated files.



## How to
To allow the correct functioning of the script, it must be run with a user enabled to read all the resources of the indicated namespace.
For correct execution, indicate the namespace in one of the following four ways:
```
./k8s-backup.sh -n=<NAMESPACE>
./k8s-backup.sh -n=<NAMESPACE> -clean (to remove metadata informations)
./k8s-backup.sh -h (script help)
```
If you use arguments separated by '=', don't use spaces in them.
