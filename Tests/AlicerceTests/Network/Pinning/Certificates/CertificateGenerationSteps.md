# Create OpenSSL Certificates

## Links

- https://jamielinux.com/docs/openssl-certificate-authority/create-the-intermediate-pair.html
- https://devcentral.f5.com/articles/building-an-openssl-certificate-authority-creating-your-root-certificate-27721

## Create Root CA with EC public key

### Create folder structure

`mkdir root/ca`

`cd root/ca`

`mkdir certs crl newcerts private`

`chmod 700 private`

`touch index.txt`

`echo 1000 > serial`


### Create private Key

`openssl ecparam -genkey -name secp521r1 | openssl ec -aes256 -out private/root.key.pem`

`chmod 400 private/root.key.pem`

### Create Certificate

`openssl req -config openssl_root.cnf -new -x509 -sha384 -extensions v3_ca -key private/root.key.pem -out certs/root.cert.pem -days 3650`

`chmod 444 certs/root.cert.pem`

## Create Intermediate CA with EC public key

### Create folder structure

`mkdir root/ca/intermediate`

`cd root/ca/intermediate`

`mkdir certs crl csr newcerts private`

`chmod 700 private`

`touch index.txt`

`echo 1000 > serial`

`echo 1000 > crlnumber`

`cd ..`

### Create private Key

`openssl ecparam -genkey -name secp384r1 | openssl ec -aes256 -out intermediate/private/intermediate.key.pem`

`chmod 400 intermediate/private/intermediate.key.pem`

### Create Certificate Signing Request (CSR)

`openssl req -config intermediate/openssl_intermediate.cnf -new -sha256 -key intermediate/private/intermediate.key.pem -out intermediate/csr/intermediate.csr.pem`

### Sign the Intermediate Certificate's CSR with the Root CA

`openssl ca -config openssl_root.cnf -md sha256 -extensions v3_intermediate_ca -notext -in intermediate/csr/intermediate.csr.pem -out intermediate/certs/intermediate.cert.pem -days 3285`

`chmod 444 intermediate/certs/intermediate.cert.pem`

## Create Server and Client certificate

### Create private key

`openssl genrsa -aes256 -out intermediate/private/www.example.com.key.pem 2048`

or 

`openssl ecparam -genkey -name secp256r1 | openssl ec -aes256 -out intermediate/private/www.example.com.key.pem`

`chmod 400 intermediate/private/www.example.com.key.pem`

### Create Certificate Signing Request (CSR)

`openssl req -config intermediate/openssl_intermediate.cnf -key intermediate/private/www.example.com.key.pem -new -sha256 -out intermediate/csr/www.example.com.csr.pem`

### Sign the Intermediate Certificate's CSR with the Intermediate CA

`openssl ca -config intermediate/openssl_intermediate.cnf -md sha256 -extensions usr_cert -notext -in intermediate/csr/www.example.com.csr.pem -out intermediate/certs/www.example.com.cert.pem -days 2920`

`chmod 444 intermediate/certs/www.example.com.cert.pem`

## Inspect Key and Certificate

`openssl ecparam -in key.pem -text -noout`
`openssl x509 -in certificate.cer -inform der -text -noout`