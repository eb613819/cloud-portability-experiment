resource "null_resource" "namecheap_dns" {
  triggers = {
    platform = var.platform
    web_ip   = local.web_public_ip
  }

  provisioner "local-exec" {
    command = <<EOT
curl -s "https://api.namecheap.com/xml.response\
?ApiUser=${var.namecheap_username}\
&ApiKey=${var.namecheap_api_key}\
&UserName=${var.namecheap_username}\
&ClientIp=${var.namecheap_client_ip}\
&Command=namecheap.domains.dns.setHosts\
&SLD=evanbrooks\
&TLD=me\
&HostName1=@&RecordType1=A&Address1=185.199.108.153&TTL1=300\
&HostName2=@&RecordType2=A&Address2=185.199.109.153&TTL2=300\
&HostName3=@&RecordType3=A&Address3=185.199.110.153&TTL3=300\
&HostName4=@&RecordType4=A&Address4=185.199.111.153&TTL4=300\
&HostName5=www&RecordType5=CNAME&Address5=eb613819.github.io.&TTL5=300\
&HostName6=${split(".", var.wordpress_domain)[0]}&RecordType6=A&Address6=${local.web_public_ip}&TTL6=300"
EOT
  }

  depends_on = [local_file.ansible_inventory]
}