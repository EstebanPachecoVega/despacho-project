# EC2 MySQL
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "db" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.db.id]
  key_name               = var.key_pair_name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_size           = var.db_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    tags = {
      Name = "${var.project_name}-mysql-data"
    }
  }

  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail

    MYSQL_DATA_DIR="/var/lib/mysql"
    MYSQL_DEVICE=""

    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    until docker info > /dev/null 2>&1; do sleep 3; done

    for device in /dev/nvme1n1 /dev/xvdf /dev/sdf; do
      if [ -b "$device" ]; then
        MYSQL_DEVICE="$device"
        break
      fi
    done

    if [ -z "$MYSQL_DEVICE" ]; then
      echo "No se encontro el volumen persistente para MySQL" >&2
      exit 1
    fi

    if ! blkid "$MYSQL_DEVICE" > /dev/null 2>&1; then
      mkfs -t xfs "$MYSQL_DEVICE"
    fi

    mkdir -p "$MYSQL_DATA_DIR"
    if ! mountpoint -q "$MYSQL_DATA_DIR"; then
      mount "$MYSQL_DEVICE" "$MYSQL_DATA_DIR"
    fi

    MYSQL_DEVICE_UUID="$(blkid -s UUID -o value "$MYSQL_DEVICE")"
    if ! grep -q "$MYSQL_DEVICE_UUID" /etc/fstab; then
      echo "UUID=$MYSQL_DEVICE_UUID $MYSQL_DATA_DIR xfs defaults,nofail 0 2" >> /etc/fstab
    fi

    docker system prune -af
    docker rm -f mysql || true
    docker run -d \
    --name mysql \
    -e MYSQL_ROOT_PASSWORD=${var.db_root_password} \
    -e MYSQL_DATABASE=${var.db_name} \
    -e MYSQL_USER=${var.db_username} \
    -e MYSQL_PASSWORD=${var.db_password} \
    -e MYSQL_ROOT_HOST=% \
    -p 3306:3306 \
    -v /var/lib/mysql:/var/lib/mysql \
    --log-opt max-size=10m \
    --log-opt max-file=3 \
    mysql:8-oracle \
    --bind-address=0.0.0.0 \
    --performance-schema=OFF
  EOF

  tags = { Name = "${var.project_name}-mysql" }
}
