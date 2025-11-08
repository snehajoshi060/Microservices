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
      # Update packages and install tools
      "sudo apt-get update -y",
      "sudo apt-get install -y git wget tar",

      # Install Go
      "wget https://go.dev/dl/go1.23.0.linux-amd64.tar.gz",
      "sudo tar -C /usr/local -xzf go1.23.0.linux-amd64.tar.gz",
      "echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile",
      "export PATH=$PATH:/usr/local/go/bin",

      # Create directory for Microservices
      "sudo mkdir -p /opt/Microservices",
      "sudo chown -R ubuntu:ubuntu /opt/Microservices",

      # Clone employee-api repo from GitHub
      "git clone -b main --single-branch https://github.com/snehajoshi060/employee-api.git /opt/Microservices/employee-api",
      "cd /opt/Microservices/employee-api || exit 1",

      # Set Go proxy and download all dependencies first
      "export GOPROXY=https://proxy.golang.org,direct",
      "/usr/local/go/bin/go mod tidy",
      "/usr/local/go/bin/go mod download",

      # Initialize Go module if missing and build binary
      "if [ ! -f go.mod ]; then /usr/local/go/bin/go mod init employee-api; fi",
      "/usr/local/go/bin/go build -mod=mod -o employee-api",

      # Make binary executable
      "sudo chmod +x /opt/Microservices/employee-api/employee-api",

      # Create systemd service for auto-start
      "sudo bash -c 'cat > /etc/systemd/system/employee-api.service <<EOF\n[Unit]\nDescription=Employee API Service\nAfter=network.target\n\n[Service]\nWorkingDirectory=/opt/Microservices/employee-api\nExecStart=/opt/Microservices/employee-api/employee-api\nRestart=always\nUser=ubuntu\nEnvironment=PORT=8080\n\n[Install]\nWantedBy=multi-user.target\nEOF'",

      # Enable and reload systemd
      "sudo systemctl daemon-reload",
      "sudo systemctl enable employee-api.service",

      # Cleanup
      "rm -f go1.23.0.linux-amd64.tar.gz"
    ]
  }
}
