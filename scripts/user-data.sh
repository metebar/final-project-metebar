#!/bin/bash
set -e

DB_HOST="${db_host}"
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASS="${db_password}"
S3_BUCKET="${s3_bucket}"
AWS_REGION="${aws_region}"

# ─── System update ───────────────────────────────────────
yum update -y

# ─── Install packages ────────────────────────────────────
amazon-linux-extras enable php8.0
yum clean metadata
yum install -y httpd php php-mysqlnd php-fpm php-json php-xml php-mbstring php-curl wget unzip mysql

# ─── Start Apache ────────────────────────────────────────
systemctl start httpd
systemctl enable httpd

# ─── Download WordPress ──────────────────────────────────
cd /tmp
wget -q https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp -r wordpress/* /var/www/html/

# ─── WordPress config ────────────────────────────────────
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

sed -i "s/database_name_here/$DB_NAME/" /var/www/html/wp-config.php
sed -i "s/username_here/$DB_USER/"      /var/www/html/wp-config.php
sed -i "s/password_here/$DB_PASS/"      /var/www/html/wp-config.php
sed -i "s/localhost/$DB_HOST/"          /var/www/html/wp-config.php

# ─── S3 media offload config ─────────────────────────────
cat >> /var/www/html/wp-config.php <<EOF

/** S3 Media Offload */
define('AS3CF_SETTINGS', serialize(array(
    'provider' => 'aws',
    'region'   => '$AWS_REGION',
    'bucket'   => '$S3_BUCKET',
)));
EOF

# ─── Permissions ─────────────────────────────────────────
chown -R apache:apache /var/www/html/
chmod -R 755 /var/www/html/

# ─── Apache config ───────────────────────────────────────
cat > /etc/httpd/conf.d/wordpress.conf <<EOF
<Directory /var/www/html>
    AllowOverride All
    Require all granted
</Directory>
EOF

systemctl restart httpd