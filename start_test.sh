#!/usr/bin/env bash
#Script created to launch Jmeter tests directly from the current terminal without accessing the jmeter master pod.
#It requires that you supply the path to the jmx file
#After execution, test script jmx file may be deleted from the pod itself but not locally.

working_dir="`pwd`"

#Get namesapce variable
tenant=`awk '{print $NF}' "$working_dir/tenant_export"`

jmx="$1"
[ -n "$jmx" ] || read -p 'Enter path to the jmx file ' jmx

if [ ! -f "$jmx" ];
then
    echo "Test script file was not found in PATH"
    echo "Kindly check and input the correct file path"
    exit
fi

FILE=${jmx/.jmx/}
test_name="$(basename "$jmx")"

#Get Master pod details

master_pod=`kubectl get po -n $tenant | grep jmeter-master | awk '{print $1}'`

kubectl cp "$jmx" -n $tenant "$master_pod:/$test_name"

## Echo Starting Jmeter load test
echo "Passing test file as: $jmx"
kubectl exec -ti -n $tenant $master_pod -- /bin/bash /load_test "$test_name"

## Copy the log .csv file and report back to local machine

# echo "Tenant var: $tenant"
# echo "Master_Pod var: $master_pod"

if [ -f "Output/$FILE.csv" ]; then
    echo "Found existing Local Test File: [$FILE.csv], removing..."
    rm "Output/$FILE.csv"
fi

if [ -d "Output/$FILE" ]; then
    echo "Found exisiting Local Test Output folder [/$FILE], removing..."
    rm -r "Output/$FILE"
fi

kubectl cp --retries=-1 "$tenant/$master_pod:$FILE.csv" "Output/$FILE.csv"
kubectl cp --retries=-1 "$tenant/$master_pod:$FILE" "Output/$FILE"
