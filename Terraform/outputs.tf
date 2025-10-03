output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "enabled_services" {
  description = "List of enabled GCP services"
  value = [
    google_project_service.pubsub.service,
    google_project_service.dataflow.service,
    google_project_service.bigquery.service,
    google_project_service.cloudfunctions.service,
    google_project_service.cloudkms.service
  ]
}
