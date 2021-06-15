# openBalena - Helm
This openBalena - Helm Chart is an unofficial Kubernetes chart, but will allow you to run openBalena in a Kubernetes cluster.  

# Dependencies
- [HAProxy Ingress v0.13.0-snapshot.3](https://github.com/jcmoraisjr/haproxy-ingress)

# Installing the chart
First, you've to generate a new configuration of openBalena using the `quickstart`. This will generate the `docker-compose` values as well as a `kubernetes.yaml` file, which contains everything from the config but in the Chart format. Example of running the quickstart below.

> Keep in mind, all commands are from the repository's root directory

```bash
$ ./scripts/quickstart -U <email@address> -P <password> -d mydomain.com
```

Now that the configuration is generated, we can install the Helm chart, just like every other Helm chart. 

```bash
$ helm install openbalena ./kubernetes/helm -f ./config/kubernetes.yaml
```

The openBalena server will now be installed on your cluster on the `default` namespace.   
More options while installing can be found in the [Helm documentation](https://helm.sh/docs/).

# Upgrading the chart
If you've made any changes to the `kubernetes.yaml` chart, upgrading is as simple as installing, only changing the word 'install' with 'upgrade'.

```bash
$ helm upgrade openbalena ./kubernetes/helm -f ./config/kubernetes.yaml
```

# SSL Certificates
By default, SSL is used for every subdomain. The TLS rules are also added in the Kubernetes Chart. However, there's no certificate manager installed by default. This means, every SSL certificate is not signed and thus SSL errors occur. It is a well-considered decision to not include a cert manager, because of different needs per Kubernetes cluster and problems that may occur.    

It is, however, recommended to use signed certificates using a certificate manager. A widely used certificate manager is [cert-manager](https://cert-manager.io/docs/). Installation of cert-manager [can be found here](https://cert-manager.io/docs/installation/kubernetes/). Using regular manifests will suffice.  

After installing [cert-manager](https://cert-manager.io/docs/), a (cluster-)issuer should be installed ([more information](https://cert-manager.io/docs/concepts/issuer/)). Here's an example of such an issuer as a yaml file. Apply this file to your cluster after the needed changes.

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: openbalena-certificate-issuer
  namespace: default # Use same namespace as installation
spec:
  acme:
    email: <email@address> # Will notify you if something goes wrong with the certificates
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: openbalena-certificate-key
    solvers:
    - http01:
        ingress:
          class: openbalena-haproxy # HAProxy Ingress class of openbalena
```

Next, you've to instruct the Ingress resources that they've to use this issuer. Go to your `kubernetes.yaml` file in the `config/` directory, and add the following lines to the bottom of the file.

```yaml
ingress:
  annotations:
    cert-manager.io/issuer: openbalena-certificate-issuer
```

Apply the changes using the [upgrading the chart instructions](#Upgrading-the-chart), and if everything is configured right, you'll see some pods starting next to the openBalena pods. Those pods will wait for the HTTP01 challenge to complete.
