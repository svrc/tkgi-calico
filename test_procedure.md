
# Get Ready

# Run a sample workload
```bash
kubectl create ns policy-demo
kubectl run --generator=run-pod/v1 --namespace=policy-demo nginx --replicas=1 --image=nginx
kubectl get pod -n policy-demo nginx --template={{.status.podIP}}
```

Then try to access:
Execute:
```bash
kubectl run --generator=run-pod/v1 --namespace=policy-demo access --rm -ti --image busybox /bin/sh
```

Then in that container:
```bash
ping <PodIP>
```

Should see a standard response
```shell
/ # ping 10.200.85.3
PING 10.200.85.3 (10.200.85.3): 56 data bytes
64 bytes from 10.200.85.3: seq=28 ttl=63 time=0.172 ms
64 bytes from 10.200.85.3: seq=29 ttl=63 time=0.107 ms
64 bytes from 10.200.85.3: seq=30 ttl=63 time=0.096 ms
```

---

 # Test Isolation


apply the following to deny Pod<->Pod communication by default in that namespace.
```yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: default-deny
  namespace: policy-demo
spec:
  podSelector:
    matchLabels: {}
```

Then retry test:
```bash
# Run a Pod and try to access the `nginx` Service.
kubectl run --generator=run-pod/v1 --namespace=policy-demo access --rm -ti --image busybox /bin/sh

Waiting for pod policy-demo/access-472357175-y0m47 to be running, status is Pending, pod ready: false

/ # ping <PodIP>
```

Should get a timeout:
```bash
If you don't see a command prompt, try pressing enter.
/ # ping 10.200.85.3
PING 10.200.85.3 (10.200.85.3): 56 data bytes
^C
```

---

# Test Allow

apply this to allow these specific Pods to talk
```yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: access-nginx
  namespace: policy-demo
spec:
  podSelector:
    matchLabels:
      run: nginx
  ingress:
    - from:
      - podSelector:
          matchLabels:
            run: access
```

Then retry test:
```bash
# Run a Pod and try to access the `nginx` Service.
$ kubectl run --generator=run-pod/v1 --namespace=policy-demo access --rm -ti --image busybox /bin/sh

Waiting for pod policy-demo/access-472357175-y0m47 to be running, status is Pending, pod ready: false

/ # ping <PodIP>
```

Should not get a timeout:
```bash
If you don't see a command prompt, try pressing enter.
/ # ping 10.200.85.3
PING 10.200.85.3 (10.200.85.3): 56 data bytes
64 bytes from 10.200.85.3: seq=28 ttl=63 time=0.172 ms
64 bytes from 10.200.85.3: seq=29 ttl=63 time=0.107 ms
64 bytes from 10.200.85.3: seq=30 ttl=63 time=0.096 ms
64 bytes from 10.200.85.3: seq=31 ttl=63 time=0.100 ms
64 bytes from 10.200.85.3: seq=32 ttl=63 time=0.091 ms
64 bytes from 10.200.85.3: seq=33 ttl=63 time=0.180 ms
^C
```

