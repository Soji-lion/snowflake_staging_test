This repo contains the code to automate the process to deploy a snowflake staging server. The security aspect of the Tor protocol is not fully respected and should only be used for testing.

#### TLDR

There is currently one running server with the following instance ID: `gn1seck75hgtcmta`

Example torrc:
```
UseBridges 1
DataDirectory datadir
Log info

ClientTransportPlugin snowflake exec ./snowflake-client -log snowflake.log -keep-local-addresses

Bridge snowflake 192.0.2.3:80 fingerprint=2B280B23E1107BB62ABFC40DDCC8824814F80A72 url=https://snowflake-broker-gn1seck75hgtcmta.vwyjlwqyoh3sqmycg6wmi5e732the58s3png-testing.v2fly.org:10443/ ice=stun:stun.antisip.com:3478,stun:stun.epygi.com:3478,stun:stun.uls.co.za:3478,stun:stun.voipgate.com:3478,stun:stun.mixvoip.com:3478,stun:stun.nextcloud.com:3478,stun:stun.bethesda.net:3478,stun:stun.nextcloud.com:443 utls-imitate=hellorandomizedalpn

SocksPort auto
```

If you couldn't connect, please check your NAT type. Currently proxies hosted on server are not full cone, but treated as so by broker.

To run a proxy: 
```
SNOWFLAKE_TEST_ASSUMEUNRESTRICTED=1 ./snowflake-proxy -broker https://snowflake-broker-gn1seck75hgtcmta.vwyjlwqyoh3sqmycg6wmi5e732the58s3png-testing.v2fly.org:10443/ -keep-local-addresses -verbose -allowed-relay-hostname-pattern "$"
```

To download compiled binary for client and proxy:
```
https://snowflake-fileserver-gn1seck75hgtcmta.vwyjlwqyoh3sqmycg6wmi5e732the58s3png-testing.v2fly.org:10443/snowflake-client
https://snowflake-fileserver-gn1seck75hgtcmta.vwyjlwqyoh3sqmycg6wmi5e732the58s3png-testing.v2fly.org:10443/snowflake-proxy
```

## Components
- Broker
- Server
- Proxy (Optional)
- File Server (Optional): download compiled binaries for snowflake

## Deploy custom instance

#### First time setup
Clone the repo,

Save the following file as `k3s.yaml` in `./terraform` folder(access to link is restricted):
https://vault.torproject.org/#/vault?collectionId=1658da7d-a7c6-45fb-bde5-62b8beef4d13&itemId=3c468ef5-bca8-4c15-879c-afbefbe96986

Download terraform's fork from https://github.com/opentofu/opentofu/releases/tag/v1.9.0 .


#### Deploy
```
## Download the necessary plugins, it will download file from internet and run them!
tofu init

## Deploy!
##   You might need to confirm deploy with a -> yes <- 
tofu apply

## Display the internal state of the deployment
tofu show
## The most important data are the domain name we will need to connect to
tofu show|grep 'host ='

## Teardown a deployment
##   You might need to confirm destroy with a -> yes <- 
tofu destroy
```
Remember that you can deploy as many instance of snowflake cluster as necessary, as each of them have an unique `deployment_id`, distinct Tor states(and fingerprints), and domain names.


## Deployment customization

There are some fields in `snowflake.tf` that can be adjusted and should just work:

Some settings will not work unless the instance is destroyed and applied again. (forcing them to apply on a running deployment is an advanced topic, and won't be covered here)

#### Image Names
We might wants to test a new version of snowflake image with this staging environment.

Search for `image = " `, and you will be able to find the snowflake related image urls. After each push to this repo, actions will be triggers to build all the images, and their location will be printed with something like `Pushing image to containers.torproject.org/shelikhoo/snowflakestaging:broker_2d330e2b_amd64 ` . Images for the same component are in theory interchangeable.

#### Whether to run proxy
We might wants to avoid running proxies on the server so that we can run them ourselves manually.

Search for `resource "kubernetes_deployment_v1" "snowflake_proxies" {`, go to `spec -> replicas` and change that to `0` or number of proxies process to run.


## Debug Deployment (Advanced)

#### First time setup
Download and install kubectl from https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/

```
# Verify configuration
kubectl --kubeconfig ./k3s.yaml cluster-info
```

<details><summary>Click to expand</summary>

```
Kubernetes control plane is running at https://vwyjlwqyoh3sqmycg6wmi5e732the58s3png-testing.v2fly.org:6443
CoreDNS is running at https://vwyjlwqyoh3sqmycg6wmi5e732the58s3png-testing.v2fly.org:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://vwyjlwqyoh3sqmycg6wmi5e732the58s3png-testing.v2fly.org:6443/api/v1/namespaces/kube-system/services/https:metrics-server:https/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

```


</details>

#### Useful commands

```
# List all namespaces
#   Snowflake's instance has a prefix of `snowflake` and a postfix of instance name
kubectl --kubeconfig ./k3s.yaml describe namespaces
```
<details><summary>Click to expand</summary>

```
Name:         default
Labels:       kubernetes.io/metadata.name=default
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.


Name:         kube-node-lease
Labels:       kubernetes.io/metadata.name=kube-node-lease
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.


Name:         kube-public
Labels:       kubernetes.io/metadata.name=kube-public
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.


Name:         kube-system
Labels:       kubernetes.io/metadata.name=kube-system
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.


Name:         snowflake-gn1seck75hgtcmta
Labels:       kubernetes.io/metadata.name=snowflake-gn1seck75hgtcmta
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.
```
</details>


```
# List all pods(containers) running under namespace $n
kubectl --kubeconfig ./k3s.yaml describe pod -n snowflake-gn1seck75hgtcmta
```

<details><summary>Click to expand</summary>

```
Name:             snowflake-broker-ss-gn1seck75hgtcmta-0
Namespace:        snowflake-gn1seck75hgtcmta
Priority:         0
Service Account:  default
Node:             snowflake-staging-01/10.41.0.100
Start Time:       Thu, 17 Apr 2025 14:36:24 +0100
Labels:           app=snowflake-broker
                  apps.kubernetes.io/pod-index=0
                  controller-revision-hash=snowflake-broker-ss-gn1seck75hgtcmta-8f9684fc8
                  instance=gn1seck75hgtcmta
                  statefulset.kubernetes.io/pod-name=snowflake-broker-ss-gn1seck75hgtcmta-0
Annotations:      <none>
Status:           Running
IP:               10.42.0.50
IPs:
  IP:           10.42.0.50
Controlled By:  StatefulSet/snowflake-broker-ss-gn1seck75hgtcmta
Containers:
  snowflake:
    Container ID:  containerd://a69dbb463621de5c8fe3e48a7db039bf1ca90314aa0176a294f0dda4b28279b2
    Image:         containers.torproject.org/shelikhoo/snowflakestaging:broker_5c3568df_amd64
    Image ID:      containers.torproject.org/shelikhoo/snowflakestaging@sha256:cc29447b3b6d4c58227b328f6c958e14e42fec63401e57e622e3b9976b7416f6
    Port:          <none>
    Host Port:     <none>
    Command:
      /snowflake-broker
    Args:
      -disable-tls
      -addr
      :80
      -disable-geoip
      -default-relay-pattern
      ^snowflake.torproject.net$
      -allowed-relay-pattern
      $
      -bridge-list-path
      /opt/snowflake-broker/bridgelist/bridgelist.jsonl
    State:          Running
      Started:      Thu, 17 Apr 2025 15:08:05 +0100
    Last State:     Terminated
      Reason:       Unknown
      Exit Code:    255
      Started:      Thu, 17 Apr 2025 14:36:25 +0100
      Finished:     Thu, 17 Apr 2025 15:07:56 +0100
    Ready:          True
    Restart Count:  1
    Environment:
      SNOWFLAKE_TEST_DEBUG:  1
    Mounts:
      /opt/snowflake-broker/bridgelist from bridgelist (ro)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-bjx6m (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  bridgelist:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      snowflake-broker-bridgelist-gn1seck75hgtcmta
    Optional:  false
  kube-api-access-bjx6m:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:                      <none>


Name:             snowflake-fileserver-gn1seck75hgtcmta-c684775f6-bkddd
Namespace:        snowflake-gn1seck75hgtcmta
Priority:         0
Service Account:  default
Node:             snowflake-staging-01/10.41.0.100
Start Time:       Tue, 22 Apr 2025 15:23:44 +0100
Labels:           app=snowflake-fileserver
                  instance=gn1seck75hgtcmta
                  pod-template-hash=c684775f6
Annotations:      <none>
Status:           Running
IP:               10.42.0.53
IPs:
  IP:           10.42.0.53
Controlled By:  ReplicaSet/snowflake-fileserver-gn1seck75hgtcmta-c684775f6
Containers:
  snowflake-fileserver:
    Container ID:   containerd://d4402cd1ef9f5c9ba1cd1d3b838cd19da99b7d95f582ed42af488b4cd3844d4d
    Image:          containers.torproject.org/shelikhoo/snowflakestaging:fileserver_b2b154b4_amd64
    Image ID:       containers.torproject.org/shelikhoo/snowflakestaging@sha256:f2b10e67ac9f4ffe22723b4c51f24b5667f3ab52aa7f1d56fd700ed0227b3e08
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Tue, 22 Apr 2025 15:23:50 +0100
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-sfsbs (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  kube-api-access-sfsbs:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:                      <none>


Name:             snowflake-fileserver-gn1seck75hgtcmta-c684775f6-n5gss
Namespace:        snowflake-gn1seck75hgtcmta
Priority:         0
Service Account:  default
Node:             snowflake-staging-01/10.41.0.100
Start Time:       Tue, 22 Apr 2025 15:23:44 +0100
Labels:           app=snowflake-fileserver
                  instance=gn1seck75hgtcmta
                  pod-template-hash=c684775f6
Annotations:      <none>
Status:           Running
IP:               10.42.0.52
IPs:
  IP:           10.42.0.52
Controlled By:  ReplicaSet/snowflake-fileserver-gn1seck75hgtcmta-c684775f6
Containers:
  snowflake-fileserver:
    Container ID:   containerd://2d1c63aaac892c3618fb51542cb6f154fa2dee288eafe2e98c45e09e1d684fe7
    Image:          containers.torproject.org/shelikhoo/snowflakestaging:fileserver_b2b154b4_amd64
    Image ID:       containers.torproject.org/shelikhoo/snowflakestaging@sha256:f2b10e67ac9f4ffe22723b4c51f24b5667f3ab52aa7f1d56fd700ed0227b3e08
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Tue, 22 Apr 2025 15:23:50 +0100
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-2zmvl (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  kube-api-access-2zmvl:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:                      <none>


Name:             snowflake-proxies-gn1seck75hgtcmta-645f6868d6-c7b2g
Namespace:        snowflake-gn1seck75hgtcmta
Priority:         0
Service Account:  default
Node:             snowflake-staging-01/10.41.0.100
Start Time:       Thu, 17 Apr 2025 14:36:23 +0100
Labels:           app=snowflake-proxies
                  instance=gn1seck75hgtcmta
                  pod-template-hash=645f6868d6
Annotations:      <none>
Status:           Running
IP:               10.41.0.100
IPs:
  IP:           10.41.0.100
Controlled By:  ReplicaSet/snowflake-proxies-gn1seck75hgtcmta-645f6868d6
Containers:
  snowflake:
    Container ID:  containerd://fd362cc56f6e819579a054aefd87b090e1a15e585c2e472602356584d02a09b0
    Image:         containers.torproject.org/shelikhoo/snowflakestaging:proxy_5c3568df_amd64
    Image ID:      containers.torproject.org/shelikhoo/snowflakestaging@sha256:bed17992caaeb4d388565769d2504df19823305d52494d1f350ea093c7ca39bf
    Port:          <none>
    Host Port:     <none>
    Command:
      /snowflake-proxy
    Args:
      -broker
      https://snowflake-broker-gn1seck75hgtcmta.vwyjlwqyoh3sqmycg6wmi5e732the58s3png-testing.v2fly.org:10443/
      -verbose
      -unsafe-logging
      -keep-local-addresses
      -allowed-relay-hostname-pattern
      $
    State:          Running
      Started:      Thu, 17 Apr 2025 15:08:05 +0100
    Last State:     Terminated
      Reason:       Unknown
      Exit Code:    255
      Started:      Thu, 17 Apr 2025 14:36:26 +0100
      Finished:     Thu, 17 Apr 2025 15:07:56 +0100
    Ready:          True
    Restart Count:  1
    Environment:
      SNOWFLAKE_TEST_PROXY_DEBUG:         1
      SNOWFLAKE_TEST_ASSUMEUNRESTRICTED:  1
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-slv6z (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  kube-api-access-slv6z:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:                      <none>


Name:             snowflake-proxies-gn1seck75hgtcmta-645f6868d6-msjjx
Namespace:        snowflake-gn1seck75hgtcmta
Priority:         0
Service Account:  default
Node:             snowflake-staging-01/10.41.0.100
Start Time:       Thu, 17 Apr 2025 14:36:23 +0100
Labels:           app=snowflake-proxies
                  instance=gn1seck75hgtcmta
                  pod-template-hash=645f6868d6
Annotations:      <none>
Status:           Running
IP:               10.41.0.100
IPs:
  IP:           10.41.0.100
Controlled By:  ReplicaSet/snowflake-proxies-gn1seck75hgtcmta-645f6868d6
Containers:
  snowflake:
    Container ID:  containerd://29fd3a942c94a4bc92f45570bf02d6846b815b223b638535a2371e4c0d0e97d2
    Image:         containers.torproject.org/shelikhoo/snowflakestaging:proxy_5c3568df_amd64
    Image ID:      containers.torproject.org/shelikhoo/snowflakestaging@sha256:bed17992caaeb4d388565769d2504df19823305d52494d1f350ea093c7ca39bf
    Port:          <none>
    Host Port:     <none>
    Command:
      /snowflake-proxy
    Args:
      -broker
      https://snowflake-broker-gn1seck75hgtcmta.vwyjlwqyoh3sqmycg6wmi5e732the58s3png-testing.v2fly.org:10443/
      -verbose
      -unsafe-logging
      -keep-local-addresses
      -allowed-relay-hostname-pattern
      $
    State:          Running
      Started:      Thu, 17 Apr 2025 15:08:05 +0100
    Last State:     Terminated
      Reason:       Unknown
      Exit Code:    255
      Started:      Thu, 17 Apr 2025 14:36:26 +0100
      Finished:     Thu, 17 Apr 2025 15:07:56 +0100
    Ready:          True
    Restart Count:  1
    Environment:
      SNOWFLAKE_TEST_PROXY_DEBUG:         1
      SNOWFLAKE_TEST_ASSUMEUNRESTRICTED:  1
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-prsg7 (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  kube-api-access-prsg7:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:                      <none>


Name:             snowflake-proxies-gn1seck75hgtcmta-645f6868d6-ptzxw
Namespace:        snowflake-gn1seck75hgtcmta
Priority:         0
Service Account:  default
Node:             snowflake-staging-01/10.41.0.100
Start Time:       Thu, 17 Apr 2025 14:36:23 +0100
Labels:           app=snowflake-proxies
                  instance=gn1seck75hgtcmta
                  pod-template-hash=645f6868d6
Annotations:      <none>
Status:           Running
IP:               10.41.0.100
IPs:
  IP:           10.41.0.100
Controlled By:  ReplicaSet/snowflake-proxies-gn1seck75hgtcmta-645f6868d6
Containers:
  snowflake:
    Container ID:  containerd://8b96dfd236ef0ef848b5fdaefe63981d6719c653d5d3fb4f4246aea96cabb817
    Image:         containers.torproject.org/shelikhoo/snowflakestaging:proxy_5c3568df_amd64
    Image ID:      containers.torproject.org/shelikhoo/snowflakestaging@sha256:bed17992caaeb4d388565769d2504df19823305d52494d1f350ea093c7ca39bf
    Port:          <none>
    Host Port:     <none>
    Command:
      /snowflake-proxy
    Args:
      -broker
      https://snowflake-broker-gn1seck75hgtcmta.vwyjlwqyoh3sqmycg6wmi5e732the58s3png-testing.v2fly.org:10443/
      -verbose
      -unsafe-logging
      -keep-local-addresses
      -allowed-relay-hostname-pattern
      $
    State:          Running
      Started:      Thu, 17 Apr 2025 15:08:04 +0100
    Last State:     Terminated
      Reason:       Unknown
      Exit Code:    255
      Started:      Thu, 17 Apr 2025 14:36:26 +0100
      Finished:     Thu, 17 Apr 2025 15:07:56 +0100
    Ready:          True
    Restart Count:  1
    Environment:
      SNOWFLAKE_TEST_PROXY_DEBUG:         1
      SNOWFLAKE_TEST_ASSUMEUNRESTRICTED:  1
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-2ng4l (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  kube-api-access-2ng4l:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:                      <none>


Name:             snowflake-proxies-gn1seck75hgtcmta-645f6868d6-wsdsd
Namespace:        snowflake-gn1seck75hgtcmta
Priority:         0
Service Account:  default
Node:             snowflake-staging-01/10.41.0.100
Start Time:       Thu, 17 Apr 2025 14:36:23 +0100
Labels:           app=snowflake-proxies
                  instance=gn1seck75hgtcmta
                  pod-template-hash=645f6868d6
Annotations:      <none>
Status:           Running
IP:               10.41.0.100
IPs:
  IP:           10.41.0.100
Controlled By:  ReplicaSet/snowflake-proxies-gn1seck75hgtcmta-645f6868d6
Containers:
  snowflake:
    Container ID:  containerd://338b32093e9b24e5627441aa3455820ab323858e2c2ca708cce9334a8a17ccd7
    Image:         containers.torproject.org/shelikhoo/snowflakestaging:proxy_5c3568df_amd64
    Image ID:      containers.torproject.org/shelikhoo/snowflakestaging@sha256:bed17992caaeb4d388565769d2504df19823305d52494d1f350ea093c7ca39bf
    Port:          <none>
    Host Port:     <none>
    Command:
      /snowflake-proxy
    Args:
      -broker
      https://snowflake-broker-gn1seck75hgtcmta.vwyjlwqyoh3sqmycg6wmi5e732the58s3png-testing.v2fly.org:10443/
      -verbose
      -unsafe-logging
      -keep-local-addresses
      -allowed-relay-hostname-pattern
      $
    State:          Running
      Started:      Thu, 17 Apr 2025 15:08:04 +0100
    Last State:     Terminated
      Reason:       Unknown
      Exit Code:    255
      Started:      Thu, 17 Apr 2025 14:36:26 +0100
      Finished:     Thu, 17 Apr 2025 15:07:56 +0100
    Ready:          True
    Restart Count:  1
    Environment:
      SNOWFLAKE_TEST_PROXY_DEBUG:         1
      SNOWFLAKE_TEST_ASSUMEUNRESTRICTED:  1
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-gbrsz (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  kube-api-access-gbrsz:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:                      <none>


Name:             snowflake-torserver-ss-gn1seck75hgtcmta-0
Namespace:        snowflake-gn1seck75hgtcmta
Priority:         0
Service Account:  default
Node:             snowflake-staging-01/10.41.0.100
Start Time:       Thu, 17 Apr 2025 14:36:27 +0100
Labels:           app=snowflake-torserver
                  apps.kubernetes.io/pod-index=0
                  controller-revision-hash=snowflake-torserver-ss-gn1seck75hgtcmta-59b6dd6799
                  instance=gn1seck75hgtcmta
                  statefulset.kubernetes.io/pod-name=snowflake-torserver-ss-gn1seck75hgtcmta-0
Annotations:      <none>
Status:           Running
IP:               10.42.0.47
IPs:
  IP:           10.42.0.47
Controlled By:  StatefulSet/snowflake-torserver-ss-gn1seck75hgtcmta
Containers:
  snowflake:
    Container ID:  containerd://5ce27fbcd9ca72ca6ea85e1166091ec27d70473ebb9571b06d4a564110b6ce7c
    Image:         containers.torproject.org/shelikhoo/snowflakestaging:tor-server_5c3568df_amd64
    Image ID:      containers.torproject.org/shelikhoo/snowflakestaging@sha256:c8d490f5cf304ee4f4d53067b21b1f155b16b6e785bc7870c1fb2b1a1461ddbe
    Port:          <none>
    Host Port:     <none>
    Command:
      /usr/bin/tor
    Args:
      -f
      /torrc
    State:          Running
      Started:      Thu, 17 Apr 2025 15:08:05 +0100
    Last State:     Terminated
      Reason:       Unknown
      Exit Code:    255
      Started:      Thu, 17 Apr 2025 14:36:28 +0100
      Finished:     Thu, 17 Apr 2025 15:07:56 +0100
    Ready:          True
    Restart Count:  1
    Environment:
      SNOWFLAKE_TEST_DEBUG:          1
      SNOWFLAKE_TEST_KCP_FAST3MODE:  1
    Mounts:
      /var/lib/torst01 from tor-data (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-pv26g (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  tor-data:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  tor-data-snowflake-torserver-ss-gn1seck75hgtcmta-0
    ReadOnly:   false
  kube-api-access-pv26g:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:                      <none>

```


</details>


```
# Inspect the log of a running container in namespace $n
kubectl --kubeconfig ./k3s.yaml logs -n snowflake-gn1seck75hgtcmta snowflake-torserver-ss-gn1seck75hgtcmta-0
```
<details><summary>Click to expand</summary>


```

Apr 18 08:08:17.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 18 09:08:17.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 18 10:08:17.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 18 11:08:18.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3600 seconds]
Apr 18 12:08:18.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 18 13:08:18.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 18 14:08:13.000 [notice] Heartbeat: Tor's uptime is 1 day 0:00 hours, with 20 circuits open. I've sent 15.83 MB and received 44.48 MB. I've received 6 connections on IPv4 and 0 on IPv6. I've made 143 connections with IPv4 and 0 with IPv6.
Apr 18 14:08:13.000 [notice] While bootstrapping, fetched this many bytes: 30611 (server descriptor fetch)
Apr 18 14:08:13.000 [notice] While not bootstrapping, fetched this many bytes: 31281722 (server descriptor fetch); 1563 (server descriptor upload); 2298886 (consensus network-status fetch); 1794 (authority cert fetch); 562269 (microdescriptor fetch)
Apr 18 14:08:13.000 [notice] Heartbeat: Since last heartbeat message, I have seen 0 unique clients.
Apr 18 14:08:18.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 18 15:03:20.000 [notice] No circuits are opened. Relaxed timeout for circuit 718 (a Testing circuit 3-hop circuit in state doing handshakes with channel state open) to 60000ms. However, it appears the circuit has timed out anyway. [1 similar message(s) suppressed in last 26700 seconds]
Apr 18 15:08:19.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3600 seconds]
Apr 18 16:08:19.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 18 17:08:19.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 18 18:08:19.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 18 19:08:19.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 18 20:08:13.000 [notice] Heartbeat: Tor's uptime is 1 day 6:00 hours, with 20 circuits open. I've sent 17.71 MB and received 56.48 MB. I've received 6 connections on IPv4 and 0 on IPv6. I've made 156 connections with IPv4 and 0 with IPv6.
Apr 18 20:08:13.000 [notice] While bootstrapping, fetched this many bytes: 30611 (server descriptor fetch)
Apr 18 20:08:13.000 [notice] While not bootstrapping, fetched this many bytes: 41127983 (server descriptor fetch); 1915 (server descriptor upload); 2555871 (consensus network-status fetch); 1794 (authority cert fetch); 781747 (microdescriptor fetch)
Apr 18 20:08:13.000 [notice] Heartbeat: Since last heartbeat message, I have seen 0 unique clients.
Apr 18 20:08:20.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3600 seconds]
Apr 18 20:37:23.000 [notice] No circuits are opened. Relaxed timeout for circuit 867 (a Testing circuit 3-hop circuit in state doing handshakes with channel state open) to 60000ms. However, it appears the circuit has timed out anyway. [1 similar message(s) suppressed in last 20100 seconds]
Apr 18 21:08:20.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 18 22:08:20.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 18 22:36:23.000 [notice] No circuits are opened. Relaxed timeout for circuit 906 (a Testing circuit 3-hop circuit in state doing handshakes with channel state open) to 60000ms. However, it appears the circuit has timed out anyway. [1 similar message(s) suppressed in last 7140 seconds]
Apr 18 23:08:20.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 19 00:08:21.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3600 seconds]
Apr 19 01:08:21.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 19 02:08:13.000 [notice] Heartbeat: Tor's uptime is 1 day 12:00 hours, with 22 circuits open. I've sent 19.61 MB and received 68.26 MB. I've received 6 connections on IPv4 and 0 on IPv6. I've made 167 connections with IPv4 and 0 with IPv6.
Apr 19 02:08:13.000 [notice] While bootstrapping, fetched this many bytes: 30611 (server descriptor fetch)
Apr 19 02:08:13.000 [notice] While not bootstrapping, fetched this many bytes: 50672300 (server descriptor fetch); 2277 (server descriptor upload); 2926753 (consensus network-status fetch); 1794 (authority cert fetch); 1009392 (microdescriptor fetch)
Apr 19 02:08:13.000 [notice] Heartbeat: Since last heartbeat message, I have seen 0 unique clients.
Apr 19 02:08:21.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 19 03:08:21.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 19 04:08:22.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3600 seconds]
Apr 19 05:08:22.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 19 06:08:22.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 19 07:08:22.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 19 08:08:13.000 [notice] Heartbeat: Tor's uptime is 1 day 18:00 hours, with 20 circuits open. I've sent 21.45 MB and received 78.00 MB. I've received 6 connections on IPv4 and 0 on IPv6. I've made 184 connections with IPv4 and 0 with IPv6.
Apr 19 08:08:13.000 [notice] While bootstrapping, fetched this many bytes: 30611 (server descriptor fetch)
Apr 19 08:08:13.000 [notice] While not bootstrapping, fetched this many bytes: 58406583 (server descriptor fetch); 2630 (server descriptor upload); 3166438 (consensus network-status fetch); 1794 (authority cert fetch); 1153269 (microdescriptor fetch)
Apr 19 08:08:13.000 [notice] Heartbeat: Since last heartbeat message, I have seen 0 unique clients.
Apr 19 08:08:22.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 19 09:05:24.000 [notice] No circuits are opened. Relaxed timeout for circuit 1218 (a Testing circuit 3-hop circuit in state doing handshakes with channel state open) to 60000ms. However, it appears the circuit has timed out anyway. [1 similar message(s) suppressed in last 37740 seconds]
Apr 19 09:08:23.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3600 seconds]
Apr 19 10:08:23.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 19 11:08:23.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 19 12:08:23.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 19 13:08:24.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3600 seconds]
Apr 19 14:08:13.000 [notice] Heartbeat: Tor's uptime is 2 days 0:00 hours, with 20 circuits open. I've sent 23.48 MB and received 87.23 MB. I've received 6 connections on IPv4 and 0 on IPv6. I've made 203 connections with IPv4 and 0 with IPv6.
Apr 19 14:08:13.000 [notice] While bootstrapping, fetched this many bytes: 30611 (server descriptor fetch)
Apr 19 14:08:13.000 [notice] While not bootstrapping, fetched this many bytes: 65529908 (server descriptor fetch); 2984 (server descriptor upload); 3408255 (consensus network-status fetch); 1794 (authority cert fetch); 1183477 (microdescriptor fetch)
Apr 19 14:08:13.000 [notice] Heartbeat: Since last heartbeat message, I have seen 0 unique clients.
Apr 19 14:08:24.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 19 15:08:24.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 19 16:08:24.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 19 17:08:25.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 19 18:08:25.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 19 19:08:25.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 19 19:32:27.000 [notice] No circuits are opened. Relaxed timeout for circuit 1501 (a Testing circuit 3-hop circuit in state doing handshakes with channel state open) to 60000ms. However, it appears the circuit has timed out anyway. [1 similar message(s) suppressed in last 37680 seconds]
Apr 19 20:08:13.000 [notice] Heartbeat: Tor's uptime is 2 days 6:00 hours, with 20 circuits open. I've sent 25.85 MB and received 99.33 MB. I've received 6 connections on IPv4 and 0 on IPv6. I've made 215 connections with IPv4 and 0 with IPv6.
Apr 19 20:08:13.000 [notice] While bootstrapping, fetched this many bytes: 30611 (server descriptor fetch)
Apr 19 20:08:13.000 [notice] While not bootstrapping, fetched this many bytes: 75212224 (server descriptor fetch); 3339 (server descriptor upload); 3748391 (consensus network-status fetch); 1794 (authority cert fetch); 1232353 (microdescriptor fetch)
Apr 19 20:08:13.000 [notice] Heartbeat: Since last heartbeat message, I have seen 0 unique clients.
Apr 19 20:08:25.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 19 21:03:26.000 [notice] No circuits are opened. Relaxed timeout for circuit 1547 (a Testing circuit 3-hop circuit in state doing handshakes with channel state open) to 60000ms. However, it appears the circuit has timed out anyway. [3 similar message(s) suppressed in last 5460 seconds]
Apr 19 21:08:25.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 19 22:08:26.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3600 seconds]
Apr 19 23:08:26.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 20 00:08:26.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 20 01:08:26.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 20 02:08:13.000 [notice] Heartbeat: Tor's uptime is 2 days 12:00 hours, with 20 circuits open. I've sent 27.62 MB and received 109.17 MB. I've received 6 connections on IPv4 and 0 on IPv6. I've made 226 connections with IPv4 and 0 with IPv6.
Apr 20 02:08:13.000 [notice] While bootstrapping, fetched this many bytes: 30611 (server descriptor fetch)
Apr 20 02:08:13.000 [notice] While not bootstrapping, fetched this many bytes: 83154293 (server descriptor fetch); 3693 (server descriptor upload); 3987298 (consensus network-status fetch); 1794 (authority cert fetch); 1258523 (microdescriptor fetch)
Apr 20 02:08:13.000 [notice] Heartbeat: Since last heartbeat message, I have seen 0 unique clients.
Apr 20 02:08:27.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3600 seconds]
Apr 20 03:08:27.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 20 04:08:27.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 20 05:08:27.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 20 06:08:28.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 20 07:08:28.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3600 seconds]
Apr 20 07:57:29.000 [notice] No circuits are opened. Relaxed timeout for circuit 1825 (a Testing circuit 3-hop circuit in state doing handshakes with channel state open) to 60000ms. However, it appears the circuit has timed out anyway. [1 similar message(s) suppressed in last 39300 seconds]
Apr 20 08:08:13.000 [notice] Heartbeat: Tor's uptime is 2 days 18:00 hours, with 21 circuits open. I've sent 29.70 MB and received 119.75 MB. I've received 6 connections on IPv4 and 0 on IPv6. I've made 242 connections with IPv4 and 0 with IPv6.
Apr 20 08:08:13.000 [notice] While bootstrapping, fetched this many bytes: 30611 (server descriptor fetch)
Apr 20 08:08:13.000 [notice] While not bootstrapping, fetched this many bytes: 91390149 (server descriptor fetch); 4056 (server descriptor upload); 4326828 (consensus network-status fetch); 1794 (authority cert fetch); 1368823 (microdescriptor fetch)
Apr 20 08:08:13.000 [notice] Heartbeat: Since last heartbeat message, I have seen 0 unique clients.
Apr 20 08:08:28.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 20 09:08:28.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 20 10:08:28.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 20 11:08:29.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3600 seconds]
Apr 20 12:08:29.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 20 13:08:29.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 20 14:01:31.000 [notice] No circuits are opened. Relaxed timeout for circuit 1992 (a Testing circuit 3-hop circuit in state doing handshakes with channel state open) to 60000ms. However, it appears the circuit has timed out anyway. [1 similar message(s) suppressed in last 21900 seconds]
Apr 20 14:08:13.000 [notice] Heartbeat: Tor's uptime is 3 days 0:00 hours, with 21 circuits open. I've sent 31.83 MB and received 132.01 MB. I've received 6 connections on IPv4 and 0 on IPv6. I've made 259 connections with IPv4 and 0 with IPv6.
Apr 20 14:08:13.000 [notice] While bootstrapping, fetched this many bytes: 30611 (server descriptor fetch)
Apr 20 14:08:13.000 [notice] While not bootstrapping, fetched this many bytes: 101363443 (server descriptor fetch); 4413 (server descriptor upload); 4655023 (consensus network-status fetch); 1794 (authority cert fetch); 1394552 (microdescriptor fetch)
Apr 20 14:08:13.000 [notice] Heartbeat: Since last heartbeat message, I have seen 0 unique clients.
Apr 20 14:08:29.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 20 15:08:30.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3600 seconds]
Apr 20 16:08:30.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 20 17:08:30.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 20 18:08:30.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 20 19:08:31.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3600 seconds]
Apr 20 19:50:31.000 [warn] Detected possible compression bomb with input size = 28963 and output size = 925821
Apr 20 19:50:31.000 [warn] Possible compression bomb; abandoning stream.
Apr 20 19:50:31.000 [warn] Unable to decompress HTTP body (tried Zstandard compressed, on Directory connection (client reading) with 185.220.100.241:9100).
Apr 20 19:52:32.000 [notice] No circuits are opened. Relaxed timeout for circuit 2132 (a Testing circuit 3-hop circuit in state doing handshakes with channel state open) to 60000ms. However, it appears the circuit has timed out anyway. [1 similar message(s) suppressed in last 21060 seconds]
Apr 20 20:08:13.000 [notice] Heartbeat: Tor's uptime is 3 days 6:00 hours, with 21 circuits open. I've sent 33.62 MB and received 140.48 MB. I've received 6 connections on IPv4 and 0 on IPv6. I've made 271 connections with IPv4 and 0 with IPv6.
Apr 20 20:08:13.000 [notice] While bootstrapping, fetched this many bytes: 30611 (server descriptor fetch)
Apr 20 20:08:13.000 [notice] While not bootstrapping, fetched this many bytes: 106750886 (server descriptor fetch); 4766 (server descriptor upload); 4859296 (consensus network-status fetch); 1794 (authority cert fetch); 2627391 (microdescriptor fetch)
Apr 20 20:08:13.000 [notice] Heartbeat: Since last heartbeat message, I have seen 0 unique clients.
Apr 20 20:08:31.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 20 21:08:31.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 20 22:08:31.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 20 23:08:31.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 21 00:08:32.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3660 seconds]
Apr 21 00:32:33.000 [notice] No circuits are opened. Relaxed timeout for circuit 2270 (a Testing circuit 3-hop circuit in state doing handshakes with channel state open) to 60000ms. However, it appears the circuit has timed out anyway. [1 similar message(s) suppressed in last 16800 seconds]
Apr 21 01:08:32.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 21 01:57:33.000 [notice] No circuits are opened. Relaxed timeout for circuit 2310 (a Testing circuit 3-hop circuit in state doing handshakes with channel state open) to 60000ms. However, it appears the circuit has timed out anyway. [1 similar message(s) suppressed in last 5100 seconds]
Apr 21 02:08:13.000 [notice] Heartbeat: Tor's uptime is 3 days 12:00 hours, with 0 circuits open. I've sent 35.92 MB and received 152.66 MB. I've received 6 connections on IPv4 and 0 on IPv6. I've made 280 connections with IPv4 and 0 with IPv6.
Apr 21 02:08:13.000 [notice] While bootstrapping, fetched this many bytes: 30611 (server descriptor fetch)
Apr 21 02:08:13.000 [notice] While not bootstrapping, fetched this many bytes: 116269248 (server descriptor fetch); 5061 (server descriptor upload); 5178608 (consensus network-status fetch); 1794 (authority cert fetch); 3157720 (microdescriptor fetch)
Apr 21 02:08:13.000 [notice] Heartbeat: Since last heartbeat message, I have seen 0 unique clients.
Apr 21 02:08:32.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 21 03:08:32.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 21 04:08:33.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3600 seconds]
Apr 21 05:08:33.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 21 06:08:33.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 21 06:21:35.000 [notice] No circuits are opened. Relaxed timeout for circuit 2438 (a Testing circuit 3-hop circuit in state doing handshakes with channel state open) to 60000ms. However, it appears the circuit has timed out anyway. [1 similar message(s) suppressed in last 15900 seconds]
Apr 21 07:08:33.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 21 08:08:13.000 [notice] Heartbeat: Tor's uptime is 3 days 18:00 hours, with 0 circuits open. I've sent 37.94 MB and received 162.65 MB. I've received 6 connections on IPv4 and 0 on IPv6. I've made 297 connections with IPv4 and 0 with IPv6.
Apr 21 08:08:13.000 [notice] While bootstrapping, fetched this many bytes: 30611 (server descriptor fetch)
Apr 21 08:08:13.000 [notice] While not bootstrapping, fetched this many bytes: 124051764 (server descriptor fetch); 5421 (server descriptor upload); 5466497 (consensus network-status fetch); 1794 (authority cert fetch); 3245134 (microdescriptor fetch)
Apr 21 08:08:13.000 [notice] Heartbeat: Since last heartbeat message, I have seen 0 unique clients.
Apr 21 08:08:34.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3600 seconds]
Apr 21 09:08:34.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 21 10:08:34.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 21 11:08:34.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 21 12:08:34.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 21 13:08:35.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3600 seconds]
Apr 21 14:08:13.000 [notice] Heartbeat: Tor's uptime is 4 days 0:00 hours, with 1 circuits open. I've sent 40.16 MB and received 176.47 MB. I've received 6 connections on IPv4 and 0 on IPv6. I've made 311 connections with IPv4 and 0 with IPv6.
Apr 21 14:08:13.000 [notice] While bootstrapping, fetched this many bytes: 30611 (server descriptor fetch)
Apr 21 14:08:13.000 [notice] While not bootstrapping, fetched this many bytes: 135091638 (server descriptor fetch); 5777 (server descriptor upload); 5831955 (consensus network-status fetch); 1794 (authority cert fetch); 3753113 (microdescriptor fetch)
Apr 21 14:08:13.000 [notice] Heartbeat: Since last heartbeat message, I have seen 0 unique clients.
Apr 21 14:08:35.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 21 15:08:35.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 21 16:08:35.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 21 17:08:36.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3600 seconds]
Apr 21 18:08:36.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 21 19:08:36.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 21 19:46:38.000 [notice] No circuits are opened. Relaxed timeout for circuit 2819 (a Testing circuit 3-hop circuit in state doing handshakes with channel state open) to 60000ms. However, it appears the circuit has timed out anyway. [1 similar message(s) suppressed in last 48360 seconds]
Apr 21 20:08:13.000 [notice] Heartbeat: Tor's uptime is 4 days 6:00 hours, with 0 circuits open. I've sent 42.12 MB and received 182.63 MB. I've received 6 connections on IPv4 and 0 on IPv6. I've made 327 connections with IPv4 and 0 with IPv6.
Apr 21 20:08:13.000 [notice] While bootstrapping, fetched this many bytes: 30611 (server descriptor fetch)
Apr 21 20:08:13.000 [notice] While not bootstrapping, fetched this many bytes: 139127528 (server descriptor fetch); 6130 (server descriptor upload); 6035370 (consensus network-status fetch); 1794 (authority cert fetch); 3782780 (microdescriptor fetch)
Apr 21 20:08:13.000 [notice] Heartbeat: Since last heartbeat message, I have seen 0 unique clients.
Apr 21 20:08:36.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 21 21:08:37.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3600 seconds]
Apr 21 22:08:37.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 21 22:51:39.000 [notice] No circuits are opened. Relaxed timeout for circuit 2900 (a Testing circuit 3-hop circuit in state doing handshakes with channel state open) to 60000ms. However, it appears the circuit has timed out anyway. [1 similar message(s) suppressed in last 11100 seconds]
Apr 21 23:08:37.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 22 00:08:37.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 22 00:31:38.000 [notice] No circuits are opened. Relaxed timeout for circuit 2944 (a Testing circuit 3-hop circuit in state doing handshakes with channel state open) to 60000ms. However, it appears the circuit has timed out anyway. [3 similar message(s) suppressed in last 6000 seconds]
Apr 22 01:08:37.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 22 02:08:13.000 [notice] Heartbeat: Tor's uptime is 4 days 12:00 hours, with 2 circuits open. I've sent 44.24 MB and received 193.63 MB. I've received 6 connections on IPv4 and 0 on IPv6. I've made 344 connections with IPv4 and 0 with IPv6.
Apr 22 02:08:13.000 [notice] While bootstrapping, fetched this many bytes: 30611 (server descriptor fetch)
Apr 22 02:08:13.000 [notice] While not bootstrapping, fetched this many bytes: 147282437 (server descriptor fetch); 6499 (server descriptor upload); 6950442 (consensus network-status fetch); 1794 (authority cert fetch); 3860957 (microdescriptor fetch)
Apr 22 02:08:13.000 [notice] Heartbeat: Since last heartbeat message, I have seen 0 unique clients.
Apr 22 02:08:38.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3600 seconds]
Apr 22 02:09:40.000 [notice] No circuits are opened. Relaxed timeout for circuit 2996 (a Testing circuit 3-hop circuit in state doing handshakes with channel state open) to 60000ms. However, it appears the circuit has timed out anyway. [5 similar message(s) suppressed in last 5940 seconds]
Apr 22 03:08:38.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 22 04:08:38.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 22 04:51:39.000 [warn] Detected possible compression bomb with input size = 38891 and output size = 1105022
Apr 22 04:51:39.000 [warn] Possible compression bomb; abandoning stream.
Apr 22 04:51:39.000 [warn] Unable to decompress HTTP body (tried Zstandard compressed, on Directory connection (client reading) with 185.220.100.241:9100).
Apr 22 04:51:39.000 [warn] Detected possible compression bomb with input size = 22245 and output size = 740176
Apr 22 04:51:39.000 [warn] Possible compression bomb; abandoning stream.
Apr 22 04:52:39.000 [notice] No circuits are opened. Relaxed timeout for circuit 3102 (a Measuring circuit timeout 3-hop circuit in state doing handshakes with channel state open) to 60000ms. However, it appears the circuit has timed out anyway. [1 similar message(s) suppressed in last 9780 seconds]
Apr 22 05:08:38.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 22 06:08:39.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3600 seconds]
Apr 22 07:08:39.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 22 08:08:13.000 [notice] Heartbeat: Tor's uptime is 4 days 18:00 hours, with 0 circuits open. I've sent 46.48 MB and received 207.69 MB. I've received 6 connections on IPv4 and 0 on IPv6. I've made 359 connections with IPv4 and 0 with IPv6.
Apr 22 08:08:13.000 [notice] While bootstrapping, fetched this many bytes: 30611 (server descriptor fetch)
Apr 22 08:08:13.000 [notice] While not bootstrapping, fetched this many bytes: 156313878 (server descriptor fetch); 6848 (server descriptor upload); 7750595 (consensus network-status fetch); 1794 (authority cert fetch); 6365774 (microdescriptor fetch)
Apr 22 08:08:13.000 [notice] Heartbeat: Since last heartbeat message, I have seen 0 unique clients.
Apr 22 08:08:39.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 22 09:08:39.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 22 10:08:40.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3600 seconds]
Apr 22 11:08:40.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 22 12:08:40.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 22 13:08:40.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3540 seconds]
Apr 22 14:08:13.000 [notice] Heartbeat: Tor's uptime is 5 days 0:00 hours, with 1 circuits open. I've sent 48.24 MB and received 213.83 MB. I've received 6 connections on IPv4 and 0 on IPv6. I've made 370 connections with IPv4 and 0 with IPv6.
Apr 22 14:08:13.000 [notice] While bootstrapping, fetched this many bytes: 30611 (server descriptor fetch)
Apr 22 14:08:13.000 [notice] While not bootstrapping, fetched this many bytes: 160448042 (server descriptor fetch); 7202 (server descriptor upload); 7976292 (consensus network-status fetch); 1794 (authority cert fetch); 6423393 (microdescriptor fetch)
Apr 22 14:08:13.000 [notice] Heartbeat: Since last heartbeat message, I have seen 0 unique clients.
Apr 22 14:08:40.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [59 similar message(s) suppressed in last 3540 seconds]
Apr 22 15:08:41.000 [notice] Unable to find IPv6 address for ORPort 9050. You might want to specify IPv4Only to it or set an explicit address or set Address. [60 similar message(s) suppressed in last 3600 seconds

```
</details>


```
# Run command in a running container in namespace $n
kubectl --kubeconfig ./k3s.yaml -n snowflake-gn1seck75hgtcmta exec snowflake-torserver-ss-gn1seck75hgtcmta-0 -- cat snowflake.log
```

<details><summary>Click to expand</summary>

```
2025/04/17 14:08:07 snowflake-server 2.10.1 (b9cb3c90*)
2025/04/17 14:08:07 starting
2025/04/17 14:08:07 listening with plain HTTP on [scrubbed]
2025/04/17 14:16:47 EOF
2025/04/17 15:00:43 error copying ORPort to WebSocket EOF
2025/04/17 15:00:43 EOF
2025/04/17 16:02:09 EOF
2025/04/17 17:19:57 EOF
2025/04/17 18:01:49 EOF
2025/04/17 20:02:21 EOF
2025/04/17 20:20:03 error copying ORPort to WebSocket EOF
2025/04/17 20:20:03 EOF
2025/04/18 14:08:07 in the past 86400 s, 6/6 connections had client_ip
2025/04/19 14:08:07 in the past 86400 s, 0/0 connections had client_ip
2025/04/20 14:08:07 in the past 86400 s, 0/0 connections had client_ip
2025/04/21 14:08:07 in the past 86400 s, 0/0 connections had client_ip
2025/04/22 14:08:07 in the past 86400 s, 0/0 connections had client_ip

```
</details>

```
# Check resource consumption under namespace $n
kubectl --kubeconfig ./k3s.yaml top pod -n snowflake-gn1seck75hgtcmta         
```

<details><summary>Click to expand</summary>

```
NAME                                                    CPU(cores)   MEMORY(bytes)   
snowflake-broker-ss-gn1seck75hgtcmta-0                  1m           13Mi            
snowflake-fileserver-gn1seck75hgtcmta-c684775f6-bkddd   0m           2Mi             
snowflake-fileserver-gn1seck75hgtcmta-c684775f6-n5gss   0m           1Mi             
snowflake-proxies-gn1seck75hgtcmta-645f6868d6-c7b2g     1m           14Mi            
snowflake-proxies-gn1seck75hgtcmta-645f6868d6-msjjx     1m           14Mi            
snowflake-proxies-gn1seck75hgtcmta-645f6868d6-ptzxw     1m           15Mi            
snowflake-proxies-gn1seck75hgtcmta-645f6868d6-wsdsd     1m           17Mi            
snowflake-torserver-ss-gn1seck75hgtcmta-0               1m           501Mi 
```
</details>
