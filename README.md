# kubackup
Kubackup is a useful script to make a backup of all the resources of a namespace on kubernetes.

The script exports:
..* deployments
..* services
..* configMaps
..* persistentVolumes
..* persistentVolumeClaim

The script creates in the current path a folder called as the namespace, all backup files are generated in it. All resources are saved in yaml files, those contained in the configMaps are instead saved separately from each other in special folders.

## How to
To allow the correct functioning of the script, it must be run with a user enabled to read all the resources of the indicated namespace.
For correct execution, indicate the namespace in one of the following four ways:
```
./kubackup.sh --namespace=<NAMESPACE>
./kubackup.sh -n=<NAMESPACE>
./kubackup.sh --namespace <NAMESPACE>
./kubackup.sh -n <NAMESPACE>
```
If you use arguments separated by '=', don't use spaces in them.
