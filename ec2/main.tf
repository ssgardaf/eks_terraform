resource "aws_security_group" "websocket_sg" {
  name        = "websocket-sg"
  description = "Allow inbound traffic for WebSocket"
  vpc_id      = var.vpc_id  # VPC ID를 변수로 참조

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "websocket-sg"
    Environment = "Production"
  }
}

resource "aws_eip" "websocket_eip" {
  domain = "vpc"
}

resource "aws_instance" "websocket_server" {
  ami           = "ami-01abb191f665c021f"
  instance_type = "t3.midium"
  subnet_id     = var.subnet_id  # 서브넷 ID를 변수로 참조
  vpc_security_group_ids = [aws_security_group.websocket_sg.id]
  key_name               = "eks-ec2-key"
  root_block_device {
    volume_size = 500
    volume_type = "gp2"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update
              sudo apt install -y mariadb-server python3-pip
              sudo systemctl start mariadb
              sudo mysql -e "CREATE DATABASE binance_data;"
              sudo mysql -e "CREATE USER 'binance_user'@'localhost' IDENTIFIED BY 'password';"
              sudo mysql -e "GRANT ALL PRIVILEGES ON binance_data.* TO 'binance_user'@'localhost';"
              sudo mysql -e "FLUSH PRIVILEGES;"
              pip3 install websocket-client mysql-connector-python

              cat << 'SCRIPT' > /home/ubuntu/binance_ws.py
                import websocket
                import json
                import mysql.connector

                # MariaDB 연결 설정
                try:
                    db = mysql.connector.connect(
                        host="localhost",
                        user="binance_user",
                        password="password",
                        database="binance_data"
                    )
                    cursor = db.cursor()
                except mysql.connector.Error as err:
                    print(f"Database connection error: {err}")

                def on_message(ws, message):
                    data = json.loads(message)
                    if 's' in data and data['s'] == 'LTCUSDT':  # LTCUSDT 데이터만 처리
                        print(data)
                        try:
                            # 거래 데이터를 데이터베이스에 삽입
                            cursor.execute("INSERT INTO trades (data) VALUES (%s)", (json.dumps(data),))
                            db.commit()
                        except mysql.connector.Error as e:
                            print(f"Database insert error: {e}")

                def on_open(ws):
                    subscribe_message = {
                        "method": "SUBSCRIBE",
                        "params": [
                            "btcusdt@trade"  # 비트코인 거래 데이터
                        ],
                        "id": 1
                    }
                    ws.send(json.dumps(subscribe_message))

                try:
                    print("Connecting to Binance WebSocket...")
                    ws = websocket.WebSocketApp("wss://fstream.binance.com/ws/ltcusdt@trade",
                                                  on_message=on_message,
                                                  on_open=on_open)
                    ws.run_forever()
                except Exception as e:
                    print(f"An error occurred: {e}")
                finally:
                    if db.is_connected():
                        cursor.close()
                        db.close()
              SCRIPT

              sudo mysql -u binance_user -ppassword -D binance_data -e "CREATE TABLE trades (id INT AUTO_INCREMENT PRIMARY KEY, data TEXT);"
              nohup python3 /home/ubuntu/binance_ws.py &
              EOF

  tags = {
    Name = "websocket-maria-server"
  }
}

resource "aws_eip_association" "websocket_associate" {
  instance_id   = aws_instance.websocket_server.id
  allocation_id = aws_eip.websocket_eip.id
}
