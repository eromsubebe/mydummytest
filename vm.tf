# A local value can only be accessed in expressions within the module where it was declared.
locals {
  ssh_user              = "eromski"
  private_key_path      = "/Users/eubebe/.ssh/gcp/runonproj-key"
}
# For creating a service account if one doesnt exist
# resource "google_service_account" "default" {
#   account_id   = "ukiauto-iac-poc-sa"
#   display_name = "ukiauto-iac-poc-sa"
# }
resource "google_compute_instance" "vm_instance_dev" {
  name          = "${var.app_name}-instance-dev"
  machine_type  = "f1-micro"
  hostname      = "${var.app_name}-vm-dev.${var.app_domain}"
  tags = ["webserver", "development"]

  labels = {
  env = "dev"
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  } 
  # metadata {
  #   ssh-keys = "${file("~/.ssh/gcp/gcp-runonproj-key.pub")}"
  # }
  # metadata_startup_script = "${file("./gcp_vm_startup_script.sh")}"

  network_interface {
    # A default network is created for all GCP projects
    # network = "default"
    # Linking the VM instance to a different VPC using the 'self_link' notation
    network = google_compute_network.vpc_network.self_link
    access_config  {
    }
  }
  provisioner "remote-exec" {  # Assumption is that public key is already uploaded to GCP
    inline = ["echo 'Wait until SSH is ready'"]
  
        connection {
            type            = "ssh"
            user            = "${var.user}"
            timeout         = "500s"
            private_key     = "${file("~/.ssh/gcp/runonproj-key")}"
            host            = self.network_interface[0].access_config[0].nat_ip
        }
    }

    provisioner "local-exec" {
        command = "ansible-playbook -i ${self.network_interface[0].access_config[0].nat_ip}, --private-key ${local.private_key_path} nginx.yaml"
    }
    # Ensure firewall rule is provisioned before server, so that SSH doesn't fail.
    depends_on = [google_compute_firewall.allow-ssh]

  # service_account {
  #   # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
  #   email  = google_service_account.default.email
  #   scopes = ["cloud-platform"]
  # }

}

