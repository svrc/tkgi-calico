#Apply the changes
kubectl apply -f calico.yaml
#Create a test namespace
kubectl create ns policy-demo
# Run a sample workload
kubectl run --namespace=policy-demo nginx --replicas=1 --image=nginx
#Expose the workloads:
kubectl expose --namespace=policy-demo deployment nginx --port=80

