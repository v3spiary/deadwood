output "cpu_server_ip" {
  value       = openstack_compute_instance_v2.cpu_server.access_ip_v4
  description = "Public IP of CPU server (if assigned)"
}

output "shared_s3_bucket" {
  value       = selectel_objectstorage_bucket_v1.shared_s3.name
  description = "Shared S3 bucket name"
}

