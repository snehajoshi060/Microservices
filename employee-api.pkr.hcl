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
      "wget https://go.dev/dl/go1.23.0.linux-amd64.tar.gz",
      "sudo tar -C /usr/local -xzf go1.23.0.linux-amd64.tar.gz",
      "echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile",
      "export PATH=$PATH:/usr/local/go/bin",
      "sudo mkdir -p /opt/Microservices",
      "sudo chown -R ubuntu:ubuntu /opt/Microservices",
      "git clone -b main --single-branch https://github.com/snehajoshi060/Microservices.git /opt/Microservices/employee-api",
      "cd /opt/Microservices/employee-api || exit 1",
      "if [ ! -f go.mod ]; then /usr/local/go/bin/go mod init employee-api; fi",
      "/usr/local/go/bin/go build -mod=mod -o employee-api",
      "sudo chmod +x /opt/Microservices/employee-api/employee-api",
      "sudo bash -c 'cat > /etc/systemd/system/employee-api.service <<EOF\n[Unit]\nDescription=Employee API Service\nAfter=network.target\n\n[Service]\nWorkingDirectory=/opt/Microservices/employee-api\nExecStart=/opt/Microservices/employee-api/employee-api\nRestart=always\nUser=ubuntu\nEnvironment=PORT=8080\n\n[Install]\nWantedBy=multi-user.target\nEOF'",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable employee-api.service"
    ]
  }
}
