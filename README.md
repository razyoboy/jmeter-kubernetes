# JMeter Kubernetes
An implementation of JMeter instances for remote testing on Kubernetes, forked and based on [kubernauts/jmeter-kubernetes](https://github.com/kubernauts/jmeter-kubernetes)

## Kubernetes Cluster Creation

The following features of Google Cloud Platform must be enabled first, namely: `Google Compute Engine`,`Google Kubernetes Engine` and `Cloud Load Balancing`

### Recommended Settings

The recommended settings are:
* Machine Configuration _not lower_ than E2 series `e2-small (2 vCPU, 2GB memory)` per node.
* Boot Disk Size _not higher_ than `50 GB` 
* Node Pool Size of `3 + <Number of Slaves> `

### Node Pool Size Explaination
This implementation requires at the very least 5 nodes, 
* JMeter Master
* JMeter Slaves (Min. 2)
* InfluxDB
* Grafana

Therefore, if it is desired to have 4 slaves, the number of the required nodes are 7 nodes.

### Get Credentials of the Created Cluster

Once the cluster is created and verified as healthy, run the following command to get credentials to the cluster


```
gcloud container clusters get-credentials <your cluster name> --project=<your_project> --region=<your_cluster_region>
```

Then verify that it is selected via the following command
```
kubectl config get-contexts
```

If it is not selected, run the following command to switch context
```
kubectl config set current-context <your_jmeter_context>
```

## Workload Creation
Note that this will only work on UNIX or UNIX-like system, as the script requires `bash` as a shell in running these scripts. 

Windows User could circumvent this problem by running the scripts within the Google's Cloud Shell and the Cloud Shell Editor

Clone this repository:
```
https://github.com/razyoboy/jmeter-kubernetes.git
cd jmeter-kubernetes
```

### Master and Slaves Creation

To change the number of slaves, modify the file ```jmeter_slave_deploy.yaml``` under the key ```specs/replicas```
```
spec:
  replicas: <number_of_slaves>
```
Note that the number of slaves _must_ abide the number of nodes as mentioned above (`No. of Nodes = 3 + <Number of Slaves> `)

Run the creation script:
```
./jmeter_cluster_create.sh
```
_Note however, that the script would store the namespace string within the file ```tenant_export``` within the repo's root, for further uses_

Once created, verify that the workload are all up and running by using:
```
kubectl get po -n <your_namespace>
```
and verify that all are ready.

### Dashboard Creation

This will link the JMeter Master pod with InfluxDB and Grafana for Load Test Data Visualization
```
./dashboard.sh
```
Once created, the expected results would be along the lines of this:
```
Creating Influxdb jmeter Database
Creating the Influxdb data source
{"datasource":{"id":1,"orgId":1,"name":"jmeterdb","type":"influxdb","typeLogoUrl":"","access":"proxy","url":"http://jmeter-influxdb:8086","password":"admin","user":"admin","database":"jmeter","basicAuth":false,"basicAuthUser":"","basicAuthPassword":"","withCredentials":false,"isDefault":true,"secureJsonFields":{},"version":1,"readOnly":false},"id":1,"message":"Datasource added","name":"jmeterdb"}
```
The creation of dashboard component is now completed. 

### Grafana Set Up

The script has been modified to use the Grafana Pod as a Load-Balancer, allowing access directly from a front-end IP address. 

Once the Master and Slaves Creation and the Dashboard Creation is completed, you can now access Grafana and configure a few things

1. Configure the DB source, select the InfluxDB's source as ```jmeterdb```
2. Configure or Import your JMeter Dashboard, alternatively you can copy & paste the following template [GrafanaJMeterTemplate.json](https://github.com/razyoboy/jmeter-kubernetes/blob/master/GrafanaJMeterTemplate.json)

## Running Load Test

Once all the above workloads are successfully created, a test plan can now be executed to the JMeter Master Pod, which can be run by using:
```
./start_test.sh <path_to_your_.jmx_test_plan>
```
The script has been modified from the oringinal to also include logging and exporting flags to the JMeter Master Pod, this allows the generation of HTML report, which shall be explained further below.

## Viewing Test Results

Once the test has been completed, the resulting `<test_plan>.csv` and `<test_plan>` folder will be created within the root directory of this repository (`jmeter-kubernetes/Output`)

## Stopping Load Test

To (force) stop the test, invoke Keyboard Interrupt (CTRL+C) and run the following script to send the termination request to all of the slaves connected to the master.

```
./jmeter_stop.sh
```

