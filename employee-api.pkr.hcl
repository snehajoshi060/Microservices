# employee-api.pkr.hcl

packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "employee_api" {
  region        = "ap-south-1"
  source_ami    = "ami-0f115dbaf1a9a8222"
  instance_type = "t2.micro"
  ssh_username  = "ubuntu"
  ami_name      = "employee-api-{{timestamp}}"
}

build {
  name    = "employee-api-build"
  sources = ["source.amazon-ebs.employee_api"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y git wget tar",

      # Install Go
      "wget https://go.dev/dl/go1.23.0.linux-amd64.tar.gz",
      "sudo tar -C /usr/local -xzf go1.23.0.linux-amd64.tar.gz",
      "echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile",
      "export PATH=$PATH:/usr/local/go/bin",

      # Create directory with sudo and set ownership
      "sudo mkdir -p /opt/Microservices",
      "sudo chown -R ubuntu:ubuntu /opt/Microservices",

      # Clone your repo
      "git clone https://github.com/snehajoshi060/Microservices.git /opt/Microservices",

      # Build the Go binary using Go modules
      "export GO111MODULE=on",
      "cd /opt/Microservices/employee-api && /usr/local/go/bin/go build -o employee-api .",
      "sudo chmod +x /opt/Microservices/employee-api/employee-api",

      # Create a systemd service
      "sudo bash -c 'cat > /etc/systemd/system/employee-api.service <<EOF\n[Unit]\nDescription=Employee API Service\nAfter=network.target\n\n[Service]\nWorkingDirectory=/opt/Microservices/employee-api\nExecStart=/opt/Microservices/employee-api/employee-api\nRestart=always\nUser=ubuntu\nEnvironment=PORT=8080\n\n[Install]\nWantedBy=multi-user.target\nEOF'",

      # Enable service
      "sudo systemctl daemon-reload",
      "sudo systemctl enable employee-api.service"
    ]
  }
}
