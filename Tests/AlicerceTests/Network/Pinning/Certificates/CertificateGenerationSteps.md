# Create OpenSSL Certificates

## Links

- https://jamielinux.com/docs/openssl-certificate-authority/create-the-intermediate-pair.html
- https://devcentral.f5.com/articles/building-an-openssl-certificate-authority-creating-your-root-certificate-27721

## Create Root CA with EC public key

### Create folder structure

```
mkdir -p ca/root
cd ca/root
mkdir certs crl newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial
cp ../../openssl_root.cnf openssl_root.cnf
```

### Create private Key

```
openssl ecparam -genkey -name secp521r1 | openssl ec -aes256 -out private/root.key.pem
chmod 400 private/root.key.pem
```

### Create Certificate

```
openssl req -config openssl_root.cnf -new -x509 -sha384 -extensions v3_ca -key private/root.key.pem -out certs/root.cert.pem -days 3650
chmod 444 certs/root.cert.pem
cd ../..
```

## Create Intermediate CA with EC public key

### Create folder structure

```
mkdir -p ca/intermediate
cd ca/intermediate
mkdir certs crl csr newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial
echo 1000 > crlnumber
cp ../../openssl_intermediate.cnf openssl_intermediate.cnf
cd ..
```

### Create private Key

```
openssl ecparam -genkey -name secp384r1 | openssl ec -aes256 -out intermediate/private/intermediate.key.pem
chmod 400 intermediate/private/intermediate.key.pem
```

### Create Certificate Signing Request (CSR)

```
openssl req -config intermediate/openssl_intermediate.cnf -new -sha256 -key intermediate/private/intermediate.key.pem -out intermediate/csr/intermediate.csr.pem
```

### Sign the Intermediate Certificate's CSR with the Root CA

```
openssl ca -config intermediate/openssl_intermediate.cnf -md sha256 -extensions v3_intermediate_ca -notext -in intermediate/csr/intermediate.csr.pem -out intermediate/certs/intermediate.cert.pem -days 3285
chmod 444 intermediate/certs/intermediate.cert.pem
cd ..
```

## Create Leaf Server certificate

### Create folder structure

```
mkdir leaf
cd leaf
mkdir certs crl csr newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial
echo 1000 > crlnumber
cp ../openssl_leaf.cnf openssl_leaf.cnf
cd ..
```

### Create private key

```
openssl genrsa -aes256 -out leaf/private/alicerce.mindera.com.key.pem 2048
```

or 

```
openssl ecparam -genkey -name secp256r1 | openssl ec -aes256 -out leaf/private/alicerce.mindera.com.key.pem
chmod 400 leaf/private/alicerce.mindera.com.key.pem
```

### Edit `alt_names` section in openssl_leaf to add DNS entries

```
vi leaf/openssl_leaf.cnf
```

update/add `DNS.x` entries

### Create Certificate Signing Request (CSR)

```
openssl req -config leaf/openssl_leaf.cnf -key leaf/private/alicerce.mindera.com.key.pem -new -sha256 -out leaf/csr/alicerce.mindera.com.csr.pem
```

Set Common Name as the base hostname, to be used as a fallback

### Sign the Intermediate Certificate's CSR with the Intermediate CA

NOTE: maximum 2 years validity

```
openssl ca -config leaf/openssl_leaf.cnf -md sha256 -extensions server_cert -notext -in leaf/csr/alicerce.mindera.com.csr.pem -out leaf/certs/alicerce.mindera.com.cert.pem -days 730
chmod 444 leaf/certs/alicerce.mindera.com.cert.pem
```

## Create Wildcard Leaf Server certificate

same as leaf, but:
- replace `alicerce.mindera.com` with `*.alicerce.mindera.com` in commands and `openssl_leaf.cnf` 
- possibly add `""` around paths because of `*`

## Inspect Key and Certificate

```
openssl ecparam -in key.pem -text -noout
openssl x509 -in certificate.cer -inform der -text -noout
```

## Convert Certificate from PEM to DER

```
openssl x509 -outform der -in <certificate>.pem -out <certificate>.cer
```
## Get public key from Certificate

```
openssl x509 -inform der -in  <certificate>.cer -pubkey -noout | openssl pkey -pubin -outform der -out <certificate>.pub
```

## Get RAW public key data from DER public key (for `SecKeyCreateWithData`)

## RSA Keys (work with plain ASN.1 encoded DER data):

you're done, simply load the <keyfile>'s bytes from disk and the above `SecKey` calls should work

## EC Keys (require raw key data, because reasons ¯\_(ツ)_/¯):

1. get dumpasn1 (and dumpasn1.cfg) from https://www.cs.auckland.ac.nz/~pgut001
2. compile it if needed `cc dumpasn1.c -o dumpasn1`
3. run `dumpasn1 <keyfile>`, check the offset of the BIT STRING components and its bytes (the key)

e.g. `./dumpasn1 MinderaAlicerceRootCA.pub`

```
  0 155: SEQUENCE {
  3  16:   SEQUENCE {
  5   7:     OBJECT IDENTIFIER ecPublicKey (1 2 840 10045 2 1)
 14   5:     OBJECT IDENTIFIER secp521r1 (1 3 132 0 35)
       :     }
 21 134:   BIT STRING
       :     04 01 57 90 8B 40 1A 49 C8 0E 5D 0D 7C 2E 59 D5
       :     B0 6B 4A CB 68 A8 E9 D8 C6 4F 72 AE 16 04 C0 1C
       :     3D CE 73 29 8A CE EB 3F 38 01 59 8C FA 03 F8 24
       :     29 91 39 34 6C F6 2F B2 64 F1 3A 2D 97 14 3F 51
       :     EB 4B A7 00 C3 74 3E B6 B7 2F 08 6A 0A 9D 7A 36
       :     A5 90 61 70 9A 8A 24 30 37 E1 11 31 A7 C4 36 55
       :     4E C3 04 2A F0 B0 D3 46 76 22 25 A8 87 55 03 5D
       :     9A 81 25 18 1C F2 87 C1 BE 29 06 FF 70 A4 A4 26
       :     2C 1A 29 99 98
       :   }

0 warnings, 0 errors.
```

4. run `dumpasn1 -<offset> -f<bitstringkeyfile> <keyfile>`, 
 
e.g. `./dumpasn1 -21 -fMinderaAlicerceRootCA.rawpub MinderaAlicerceRootCA.bitstring`

```
  3 134: BIT STRING
       :   04 01 57 90 8B 40 1A 49 C8 0E 5D 0D 7C 2E 59 D5
       :   B0 6B 4A CB 68 A8 E9 D8 C6 4F 72 AE 16 04 C0 1C
       :   3D CE 73 29 8A CE EB 3F 38 01 59 8C FA 03 F8 24
       :   29 91 39 34 6C F6 2F B2 64 F1 3A 2D 97 14 3F 51
       :   EB 4B A7 00 C3 74 3E B6 B7 2F 08 6A 0A 9D 7A 36
       :   A5 90 61 70 9A 8A 24 30 37 E1 11 31 A7 C4 36 55
       :   4E C3 04 2A F0 B0 D3 46 76 22 25 A8 87 55 03 5D
       :   9A 81 25 18 1C F2 87 C1 BE 29 06 FF 70 A4 A4 26
       :   2C 1A 29 99 98

0 warnings, 0 errors.
```

5. run `hexdump -Cv <bitstringkeyfile>`, check how many extra bytes are on the file before the key begins

e.g. `hexdump -Cv MinderaAlicerceRootCA.bitstring`

```
00000000  03 81 86 00 04 01 57 90  8b 40 1a 49 c8 0e 5d 0d  |......W..@.I�.].|
00000010  7c 2e 59 d5 b0 6b 4a cb  68 a8 e9 d8 c6 4f 72 ae  ||.YհkJ�h����Or�|
00000020  16 04 c0 1c 3d ce 73 29  8a ce eb 3f 38 01 59 8c  |..�.=�s).��?8.Y.|
00000030  fa 03 f8 24 29 91 39 34  6c f6 2f b2 64 f1 3a 2d  |�.�$).94l�/�d�:-|
00000040  97 14 3f 51 eb 4b a7 00  c3 74 3e b6 b7 2f 08 6a  |..?Q�K�.�t>��/.j|
00000050  0a 9d 7a 36 a5 90 61 70  9a 8a 24 30 37 e1 11 31  |..z6�.ap..$07�.1|
00000060  a7 c4 36 55 4e c3 04 2a  f0 b0 d3 46 76 22 25 a8  |��6UN�.*��Fv"%�|
00000070  87 55 03 5d 9a 81 25 18  1c f2 87 c1 be 29 06 ff  |.U.]..%..�.��).�|
```

i.e. 4 bytes (until `04 01 57`)

6. run `dd if=<bistringfile> bs=1 skip=<extrabytes> of=<rawkeyfile>`

e.g. `dd if=MinderaAlicerceRootCA.bitstring bs=1 skip=4 of=MinderaAlicerceRootCA.rawpub`

```
133+0 records in
133+0 records out
133 bytes transferred in 0.002893 secs (45973 bytes/sec)
```

## Retrieve SPKI SHA256 Base64 encoded hashes

### DER

```
openssl x509 -inform der -in <cert_name> -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
```

### PEM

```
openssl x509 -inform pem -in <cert_name> -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
```