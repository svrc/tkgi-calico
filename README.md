# Upgrade

(as of June 25, 2021)

Upgrading from Calico 3.11.2 to 3.19.1 assumes you have minimum TKGI 1.9.  It may work on PKS 1.8 but it's not supported.

1. clone this repo
1. please read the Calico [upgrade docs](https://docs.projectcalico.org/maintenance/kubernetes-upgrade) for **breaking changes** to Host Endpoints.  If you don't use Calico-specific features like Global network policies, this shouldn't apply to you.
1. `kubectl scale --replicas=2 -n kube-system deploy calico-typha` and scale down Typha to at least 1 less than the number of worker nodes you have, otherwise the rolling deployment won't have room to run, given these pods run on the node's host network and lock their ports.
1. `kubectl apply -f calico.yaml` will perform the daemonset upgrade in a rolling fashion, this will also scale Typha back up to 3 (you may want to bump it higher for a large cluster)

# Install (disruptive)

These steps show how one can configure Calico Network Policy working with Flannel on Tanzu Kubernetes Grid Integrated Edition (TKGI) 1.8+, formerly known as Enterprise PKS (tested on GCP and AWS and Azure).

1. clone this repo

1. obtain PKS cluster with priveleged containers support enabled
    - this is necessary for Calico to be installed on the nodes (otherwise you will receive `The DaemonSet "calico-node" is invalid: spec.template.spec.containers[0].securityContext.privileged: Forbidden: disallowed by cluster policy` error)
    - if you have Pod Security Policy enabled, this should include the `pks-privileged` PSP in its ClusterRole.   Prior versions to 12/15/2020 did not.

1. `kubectl apply -f cleanup.yaml` , as of PKS 1.7, this cleans up pods after Calico is ready on a given node, which can handle race conditions with flannel when we have two CNIs for a brief period

1. `kubectl apply -f calico.yaml`

1. `kubectl -n kube-system get pod` and see that `calico-node-*` pod is running for each node

1. run through [test_procedure.md](test_procedure.md)

# Install (non-disruptive)

1. clone this repo

1. obtain PKS cluster with priveleged containers support enabled

    - this is necessary for Calico to be installed on the nodes (otherwise you will receive `The DaemonSet "calico-node" is invalid: spec.template.spec.containers[0].securityContext.privileged: Forbidden: disallowed by cluster policy` error)
    - if you have Pod Security Policy enabled, this should include the `pks-privileged` PSP in its ClusterRole.   Prior versions to 12/15/2020 did not.

1. `kubectl apply -f cleanup.yaml` , as of PKS 1.7, this cleans up pods after Calico is ready on a given node, which can handle race conditions with flannel when we have two CNIs for a brief period

1. `kubectl apply -f calico-rolling-install.yaml`

1.  List your nodes `kubectl get nodes -o wide`

1.  For each node you want to swap your CNI from flannel to Calico+Flannel, run `kubectl label <node name> tanzu.vmware.com/calico="true"`.  

    This will delete all the pods on that node, and when they're recreated they'll be in recreated in the Calico veth setup.   Most importantly, *there still will be full Pod network connectivity across nodes* even though some are using Calico on Flannel, and others are just using Flannel.

1.  If you do not have [Persistent labels and taints](https://github.com/svrc/tkgi-persistent-taints-labels), once you've applied Calico everywhere, you should  `kubectl apply -f calico.yaml`.   

    This will swap the calico-node `nodeSelector` to just look for `kubernetes.io/os=linux` nodes which are always labelled even after upgrades.   

## Modifications

YAML was obtained from [Installing Calico for policy (advanced)](https://docs.projectcalico.org/v3.11/getting-started/kubernetes/installation/other). Copies were placed into `official/` directory.

- `calico.yaml` was modified (`diff calico.yaml official/calico-policy-only.yaml`)
  - use Flannel given MTU (Flannel specific)
  - use Flannel given pod CIDR (Flannel specific)
    - this change was necessary since Flannel does not update node objects' spec.podCIDR which is used by Calico's usePodCidr configuration
  - configure default Calico pod CIDR 
  - configure CNI binaries location (PKS specific)
    - we delegate to host-local IPAM and need to rename the node-local pod subnet from .1/24 to .0
- `cleanup.yml` deals with race conditions 
