terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.36.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
  }
}

provider "kubernetes" {
  config_path    = "./k3s.yaml"
  config_context = "default"
  tls_server_name = "kubernetes"
}

resource "random_string" "deployment_id" {
  length  = 16
  special = false
  upper   = false
}

resource "kubernetes_namespace" "snowflake" {
  metadata {
    name = "snowflake-${random_string.deployment_id.id}"
  }
}

resource "kubernetes_ingress_v1" "snowflake_broker" {
  metadata {
    name      = "snowflake-broker-ign-${random_string.deployment_id.id}"
    namespace = kubernetes_namespace.snowflake.id
  }
  spec {
    rule {
      host = "snowflake-broker-${random_string.deployment_id.id}.vwyjlwqyoh3sqmycg6wmi5e732the58s3png-testing.v2fly.org"
      http {
        path {
          backend {
            service {
              name = kubernetes_service_v1.snowflake_broker.metadata.0.name
              port {
                number = "80"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "snowflake_broker" {
  metadata {
    name      = "snowflake-broker-srv-${random_string.deployment_id.id}"
    namespace = kubernetes_namespace.snowflake.id
  }
  spec {
    cluster_ip = "None"
    selector = {
      "app" : "snowflake-broker"
      "instance" : "${random_string.deployment_id.id}"
    }
    ip_family_policy = "SingleStack"
    ip_families      = ["IPv4"]

    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_stateful_set_v1" "snowflake_broker" {
  metadata {
    name      = "snowflake-broker-ss-${random_string.deployment_id.id}"
    namespace = kubernetes_namespace.snowflake.id
  }
  spec {
    service_name = kubernetes_service_v1.snowflake_broker.metadata.0.name
    selector {
      match_labels = {
        "app" : "snowflake-broker"
        "instance" : "${random_string.deployment_id.id}"
      }
    }
    template {
      metadata {
        name = "snowflake-broker-svc-${random_string.deployment_id.id}"
        labels = {
          "app" : "snowflake-broker"
          "instance" : "${random_string.deployment_id.id}"
        }
      }
      spec {
        container {
          name  = "snowflake"
          image = "containers.torproject.org/shelikhoo/snowflakestaging:broker_5c3568df_amd64"
          volume_mount {
            name       = "bridgelist"
            mount_path = "/opt/snowflake-broker/bridgelist"
            read_only  = true
          }
          env {
            name  = "SNOWFLAKE_TEST_DEBUG"
            value = "1"
          }

          command = [
            "/snowflake-broker"
          ]

          args = [
            "-disable-tls",
            "-addr",
            ":80",
            "-disable-geoip",
            "-default-relay-pattern",
            "^snowflake.torproject.net$",
            "-allowed-relay-pattern",
            "$",
            "-bridge-list-path",
            "/opt/snowflake-broker/bridgelist/bridgelist.jsonl"
          ]
        }
        volume {
          name = "bridgelist"
          config_map {
            name = kubernetes_config_map_v1.snowflake_broker_bridgelist.metadata.0.name
          }
        }
      }
    }
    pod_management_policy = "Parallel"
  }

}

resource "kubernetes_config_map_v1" "snowflake_broker_bridgelist" {
  metadata {
    name      = "snowflake-broker-bridgelist-${random_string.deployment_id.id}"
    namespace = kubernetes_namespace.snowflake.id
  }
  data = {
    "bridgelist.jsonl" = <<EOF
{"displayName":"default", "webSocketAddress":"wss://${kubernetes_ingress_v1.snowflake_torserver.spec.0.rule.0.host}:10443/", "fingerprint":"2B280B23E1107BB62ABFC40DDCC8824814F80A72"}
{"displayName":"TransientSnow1", "webSocketAddress":"wss://${kubernetes_ingress_v1.snowflake_torserver.spec.0.rule.0.host}:10443/", "fingerprint":"D74932202EDC2E0CDA47E5C500034CA015025C7E"}
EOF
  }
}



resource "kubernetes_ingress_v1" "snowflake_torserver" {
  metadata {
    name      = "snowflake-torserver-ign-${random_string.deployment_id.id}"
    namespace = kubernetes_namespace.snowflake.id
  }
  spec {
    rule {
      host = "snowflake-torserver-${random_string.deployment_id.id}.vwyjlwqyoh3sqmycg6wmi5e732the58s3png-testing.v2fly.org"
      http {
        path {
          backend {
            service {
              name = kubernetes_service_v1.snowflake_torserver.metadata.0.name
              port {
                number = "80"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "snowflake_torserver" {
  metadata {
    name      = "snowflake-torserver-srv-${random_string.deployment_id.id}"
    namespace = kubernetes_namespace.snowflake.id
  }
  spec {
    cluster_ip = "None"
    selector = {
      "app" : "snowflake-torserver"
      "instance" : "${random_string.deployment_id.id}"
    }
    ip_family_policy = "SingleStack"
    ip_families      = ["IPv4"]

    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_stateful_set_v1" "snowflake_torserver" {
  metadata {
    name      = "snowflake-torserver-ss-${random_string.deployment_id.id}"
    namespace = kubernetes_namespace.snowflake.id
  }
  spec {
    service_name = kubernetes_service_v1.snowflake_broker.metadata.0.name
    selector {
      match_labels = {
        "app" : "snowflake-torserver"
        "instance" : "${random_string.deployment_id.id}"
      }
    }
    template {
      metadata {
        name = "snowflake-torserver-svc-${random_string.deployment_id.id}"
        labels = {
          "app" : "snowflake-torserver"
          "instance" : "${random_string.deployment_id.id}"
        }
      }
      spec {
        container {
          name  = "snowflake"
          image = "containers.torproject.org/shelikhoo/snowflakestaging:tor-server_5c3568df_amd64"
          volume_mount {
            name       = "tor-data"
            mount_path = "/var/lib/torst01"
            read_only  = false
          }

          env {
            name  = "SNOWFLAKE_TEST_DEBUG"
            value = "1"
          }

          env {
            name  = "SNOWFLAKE_TEST_KCP_FAST3MODE"
            value = "1"
          }

          command = [
            "/usr/bin/tor"
          ]

          args = [
            "-f",
            "/torrc"
          ]
        }

      }
    }
    volume_claim_template {
      metadata {
        name = "tor-data"
      }
      spec {
        access_modes = ["ReadWriteOncePod"]
        resources {
          requests = {
            storage = "50Mi"
          }
        }
      }
    }
    pod_management_policy = "Parallel"
    persistent_volume_claim_retention_policy {
      when_deleted = "Delete"
      when_scaled  = "Retain"
    }
  }
}

resource "kubernetes_deployment_v1" "snowflake_proxies" {
  metadata {
    name      = "snowflake-proxies-${random_string.deployment_id.id}"
    namespace = kubernetes_namespace.snowflake.id
  }
  spec {
    replicas = 4
    selector {
      match_labels = {
        "app" : "snowflake-proxies"
        "instance" : "${random_string.deployment_id.id}"
      }
    }
    template {
      metadata {
        name = "snowflake-proxies-svc-${random_string.deployment_id.id}"
        labels = {
          "app" : "snowflake-proxies"
          "instance" : "${random_string.deployment_id.id}"
        }
      }
      spec {
        host_network = true
        container {
          name  = "snowflake"
          image = "containers.torproject.org/shelikhoo/snowflakestaging:proxy_5c3568df_amd64"
          env {
            name  = "SNOWFLAKE_TEST_PROXY_DEBUG"
            value = "1"
          }
          env {
            name  = "SNOWFLAKE_TEST_ASSUMEUNRESTRICTED"
            value = "1"
          }
          command = [
            "/snowflake-proxy"
          ]
          args = [
            "-broker",
            "https://snowflake-broker-${random_string.deployment_id.id}.vwyjlwqyoh3sqmycg6wmi5e732the58s3png-testing.v2fly.org:10443/",
            "-verbose",
            "-unsafe-logging",
            "-keep-local-addresses",
            "-allowed-relay-hostname-pattern",
            "$"
          ]
        }
      }
    }
  }
}

resource "kubernetes_deployment_v1" "snowflake_fileserver" {
  metadata {
    name      = "snowflake-fileserver-${random_string.deployment_id.id}"
    namespace = kubernetes_namespace.snowflake.id
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        "app" : "snowflake-fileserver"
        "instance" : "${random_string.deployment_id.id}"
      }
    }
    template {
      metadata {
        name = "snowflake-fileserver-svc-${random_string.deployment_id.id}"
        labels = {
          "app" : "snowflake-fileserver"
          "instance" : "${random_string.deployment_id.id}"
        }
      }
      spec {
        container {
          name  = "snowflake-fileserver"
          image = "containers.torproject.org/shelikhoo/snowflakestaging:fileserver_b2b154b4_amd64"
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "snowflake_fileserver" {
  metadata {
    name      = "snowflake-fileserver-ign-${random_string.deployment_id.id}"
    namespace = kubernetes_namespace.snowflake.id
  }
  spec {
    rule {
      host = "snowflake-fileserver-${random_string.deployment_id.id}.vwyjlwqyoh3sqmycg6wmi5e732the58s3png-testing.v2fly.org"
      http {
        path {
          backend {
            service {
              name = kubernetes_service_v1.snowflake_fileserver.metadata.0.name
              port {
                number = "80"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "snowflake_fileserver" {
  metadata {
    name      = "snowflake-fileserver-srv-${random_string.deployment_id.id}"
    namespace = kubernetes_namespace.snowflake.id
  }
  spec {
    cluster_ip = "None"
    selector = {
      "app" : "snowflake-fileserver"
      "instance" : "${random_string.deployment_id.id}"
    }
    ip_family_policy = "SingleStack"
    ip_families      = ["IPv4"]

    port {
      port        = 80
      target_port = 80
    }
  }
}