resource "google_project_service" "pubsub" {
  service = "pubsub.googleapis.com"
  project = var.project_id
}

resource "google_project_service" "dataflow" {
  service = "dataflow.googleapis.com"
  project = var.project_id
}

resource "google_project_service" "bigquery" {
  service = "bigquery.googleapis.com"
  project = var.project_id
}

resource "google_project_service" "cloudfunctions" {
  service = "cloudfunctions.googleapis.com"
  project = var.project_id
}

resource "google_project_service" "cloudkms" {
  service = "cloudkms.googleapis.com"
  project = var.project_id
}

resource "google_compute_network" "vpc_network" {
  name                    = "healthcare-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
}

resource "google_compute_subnetwork" "private_subnet" {
  name                     = "private-subnet"
  ip_cidr_range            = var.private_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.vpc_network.self_link
  private_ip_google_access = true
  project                  = var.project_id
}

resource "google_compute_firewall" "allow_internal" {
  name         = "allow-internal"
  network      = google_compute_network.vpc_network.name
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  source_ranges = ["10.0.0.0/8"]
  project       = var.project_id
}

resource "google_kms_key_ring" "keyring" {
  name     = "healthcare-keyring"
  location = var.region
  project  = var.project_id
}

resource "google_kms_crypto_key" "key" {
  name            = "healthcare-key"
  key_ring        = google_kms_key_ring.keyring.id
  rotation_period = "100000s"
}

resource "google_pubsub_topic" "device_data_topic" {
  name    = "device-data"
  project = var.project_id
}

resource "google_service_account" "cloud_run_sa" {
  account_id   = "cloud-run-sa"
  display_name = "Cloud Run Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "cloud_run_pubsub" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_cloud_run_service" "validator_service" {
  name     = "device-data-validator"
  location = var.region

  template {
    spec {
      service_account_name = google_service_account.cloud_run_sa.email
      containers {
        image = "gcr.io/${var.project_id}/device-data-validator:latest"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_pubsub_subscription" "cloud_run_subscription" {
  name  = "cloud-run-device-data-sub"
  topic = google_pubsub_topic.device_data_topic.name

  push_config {
    push_endpoint = "${google_cloud_run_service.validator_service.status[0].url}/"
    
    oidc_token {
      service_account_email = google_service_account.cloud_run_sa.email
    }
  }
}

resource "google_storage_bucket" "raw_bucket" {
  name     = "${var.project_id}-raw"
  location = var.region

  encryption {
    default_kms_key_name = google_kms_crypto_key.key.id
  }

  retention_policy {
    retention_period = 5184000 # 60 days in seconds
  }
}

resource "google_storage_bucket" "staging_bucket" {
  name     = "${var.project_id}-staging"
  location = var.region

  encryption {
    default_kms_key_name = google_kms_crypto_key.key.id
  }

  retention_policy {
    retention_period = 2592000 # 30 days in seconds
  }
}

resource "google_storage_bucket" "logs_bucket" {
  name     = "${var.project_id}-logs"
  location = var.region

  encryption {
    default_kms_key_name = google_kms_crypto_key.key.id
  }

  retention_policy {
    retention_period = 7776000 # 90 days in seconds
  }
}
