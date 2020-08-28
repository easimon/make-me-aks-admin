# Make me AKS Cluster-Admin

If you rolled out RBAC for Kubernetes on AKS, and a number of users having read-access to it, your cluster is probably vulnerable to privilege escalation by any one of these users.

This issue has been found by fellows from [Secure Systems Engineering](https://securesystems.de/), published on their blog on [Medium](https://medium.com/sse-blog/privilege-escalation-in-aks-clusters-18222ab53f28) -- and also reported to [secure@microsoft.com](mailto:secure@microsoft.com).

TL;DR: This escalation is available to every user that is able to read `ConfigMap`s (since nobody ever would store a secret in a `ConfigMap`, would you?). But AKS would. AKS stores cluster-admin-credentials in a `ConfigMap` `kube-system/tunnelfront-kubecfg`. So whoever is able to read this `ConfigMap`, can make himself a cluster administrator.

So if you want to know the nitty gritty details and whereabouts of this, read the blog article. It covers it all. If you are like "TL;DR! Give me a one-click demo.", and happen to have access to an AKS cluster with RBAC, read on here.

## Requirements

- An AKS Kubernetes cluster
- A user allowed to read `ConfigMaps` (not an admin, this would be too boring)
- `kubectl`, `jq`, `sed`, `grep`

## How to use

- Check out this repository
- Log in to AKS cluster as a user that can read `ConfigMaps` in `kube-system` (`az aks get-credentials ...`, you most probably have that already)
- Change `boohoo@example.com` in [./make-me-clusteradmin.yaml](./make-me-clusteradmin.yaml) to your user name (Your e-mail address usually, the one you're using to log in to Azure).
- Execute `./make-me-clusteradmin.sh`

Done. You now bound your own user to the `cluster-admin` `ClusterRole`.

Creating that additional `ClusterRoleBinding` mainly serves as a proof that the tunnelfront-kubeconfig comes with the required privileges (it is indeed bound to `cluster-admin` as well). An attacker would most probably not do so, but instead just use the sneaky `./tunnelfront/kubeconfig` created by this script, making it even harder to track down the attacker, or to lock him out without shutting down the AKS cluster (Or do you know how to rotate the tunnelfront credentials properly?)

## Cleaning up

To revert the changes made by this script, just execute

```bash
$ kubectl delete clusterrolebinding boohoo-admin
```

## Why is this a thing? Just don't give bad people access!

If you want your devs to do dev-ops, you need to give them the access to do so. So, handing out user accounts (even to to production) should be an easy thing. Having (read) access to to the apps they own and their configuration is often crucial for diagnosis. But you probably would not want all of them to be "root" on the cluster, no matter how nice they are. That's what RBAC is made for.

Kubernetes explicitly distinguishes between `ConfigMap` and `Secret`. So, if you just put all sensitive configuration in a `Secret` (so you do not expose production database passwords to users), and the non-sensitive items in a `ConfigMap`, you could just allow your users to read all `ConfigMaps`, globally. The existence of this single AKS-provided `ConfigMap` forbids this, and puts unaware cluster owners at risk. And since it's an AKS-managed component, you can't change it.

Plus, there is no obvious reason why tunnelfront needs this in a `ConfigMap`. Not. at. all.

## What are the mitigations? How do I secure my cluster?

Until AKS fixes this, I see the following options:

1. Don't give out access to non-admins at all

   Easy to set up, but painful to use. And makes me wonder why we have RBAC in the first place.

2. Restrict access to all `ConfigMap`s and treat them as confidential

   Easy to set up, but painful to use. And makes me wonder why we have `Secret`s in the first place.

3. Restrict access to this specific `ConfigMap`

   Easy to use, but painful to set up. Kubernetes RBAC is purely additive. So restricting access to this specific `ConfigMap`, while opening all others, requires explicit allow rules for all other `ConfigMaps`, or at least all allowable `Namespaces`, and you always need to keep that up-to-date with all the services you're running. Explicitly. Have fun maintaining this one.
