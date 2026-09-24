terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "paas_vpc" {
  name                    = "paas-hybrid-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "paas_subnet" {
  name          = "paas-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.paas_vpc.id
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.paas_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "paas_vm" {
  name         = "paas-gce-vm"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.paas_subnet.id

    access_config {}
  }

  tags = ["ssh"]
}

output "vm_public_ip" {
  value = google_compute_instance.paas_vm.network_interface[0].access_config[0].nat_ip
}

output "vpc_name" {
  value = google_compute_network.paas_vpc.name
}

output "subnet_name" {
  value = google_compute_subnetwork.paas_subnet.name
}

resource "google_container_cluster" "paas_gke" {
  name     = "paas-gke-cluster"
  location = var.region

  deletion_protection = false

  initial_node_count = 1

  network    = google_compute_network.paas_vpc.name
  subnetwork = google_compute_subnetwork.paas_subnet.name

  remove_default_node_pool = false
}
