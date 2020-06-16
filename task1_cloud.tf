+provider  "aws"{
   region = "ap-south-1"
   profile = "rohhit" 
}

resource "aws_s3_bucket" "kkmhandball" {
  bucket = "kkmhandball"
  acl    = "public-read"
  force_destroy  = true
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST"]
    allowed_origins = ["https://kkmhandball"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_object" "s3object" {
  bucket = aws_s3_bucket.kkmhandball.id
  key    = "mylove.jpg"
  source = "C:/Users/rohit garud/Desktop/terraform/mylove.jpg"
  force_destroy = true

}


resource "aws_security_group" "sgtask1" {
  name        = "security_groups"
  description = "Allowing SSH and HTTP inbound traffic"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
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
    Name = "sg_for_task1"
  }
}

resource "aws_instance" "myinstance"{
   ami = "ami-0447a12f28fddb066"
   instance_type = "t2.micro"
   key_name = "task1"
   security_groups = ["security_groups"]

   tags = {
     Name= "webserver_for_task1" 
 }
 
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/rohit garud/Desktop/terraform/task1.pem")
    host     = aws_instance.myinstance.public_ip
  }


  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }
}

resource "aws_ebs_volume" "my_ebs" {
  availability_zone = aws_instance.myinstance.availability_zone
  size              = 1

  tags = {
    Name = "ebs_volume_for_linuxos"
  }
}
	
output "ebs_volume"  {
 value = aws_ebs_volume.my_ebs.id
}

output "instance_id" {
  value = aws_instance.myinstance.id
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.my_ebs.id
  instance_id = aws_instance.myinstance.id 
  force_detach = true

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/rohit garud/Desktop/terraform/task1.pem")
    host     = aws_instance.myinstance.public_ip
}
  provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4   /dev/xvdh",
      "sudo mount /dev/xvdh  /var/www/html",
     " sudo rmdir -f  /var/www/html/*",
      "sudo rm -f /var/www/html/* ",
     " sudo git clone https://github.com/rohitgarud60/cloudtask1.git   /var/www/html/"
    ]
  }
}

 
resource "aws_cloudfront_distribution" "distribution" {
    origin {
        domain_name = aws_s3_bucket.kkmhandball.bucket_regional_domain_name
        origin_id = "S3-${aws_s3_bucket.kkmhandball.bucket}"
 
        custom_origin_config {
            http_port = 80
            https_port = 443
            origin_protocol_policy = "match-viewer"
            origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
        }
    }
    enabled = true
    
    custom_error_response {
        error_caching_min_ttl = 3000
        error_code = 404
        response_code = 200
       
    }

    default_cache_behavior {
        allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = "S3-${aws_s3_bucket.kkmhandball.bucket}"

        forwarded_values {
            query_string = false
	    cookies {
		forward = "none"
	    }
            
        }

        viewer_protocol_policy = "redirect-to-https"
        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    }

   
    price_class = "PriceClass_All"


    restrictions {
        geo_restriction {
        
            restriction_type = "none"
        }
    }

    
    viewer_certificate {
        cloudfront_default_certificate = true
    }
}

output "cloudfront_address" {
  value = aws_cloudfront_distribution.distribution.domain_name

}

resource "null_resource" "nulllocal1123"  {
  provisioner "local-exec" {
	    command = "start chrome  ${aws_instance.myinstance.public_ip}"
  	}
}

