---
layout: post
title:  "Самоподписанный сертификат"
date:   2022-03-26
categories: security
permalink: /self-signed-certificate
---

Инструкция по созданию сертификата SSL(TLS) консольной утилитой openssl.

## Создание центра сертификации (CA – Certificate Authority)

Создание ключа:

```
openssl genrsa -aes256 -out CA.key 4096
```

- -out CA.key - корневой ключ.
- -aes256 - установка пароля на ключ. Рекомендуется устанавливать

Создание сертификата:

```
openssl req -x509 -new -nodes -key CA.key -sha256 -days 18250 -out CA.pem
```

Вводим пароль от корневого ключа. 
Нужно заполнить поле `Common Name (eg, fully qualified host name)`, остальное - опционально.

- CA.pem - корневой сертификат
- -x509 - output a x509 structure instead of a cert. req
- -new - new request.
- -nodes - don't encrypt the output key
- -key file - use the private key contained in file
- -days - number of days a certificate generated by -x509 is valid for. (18250 дней == 50 лет)

## Установка сертификата в систему

macos добавление сертификата в keychain:

```
sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" CA.pem
```

macos удаление сертификата из keychain:

```
sudo security remove-trusted-cert -d CA.pem
```

ubuntu:

```
sudo apt-get update
sudo apt-get install -y ca-certificates
openssl x509 -outform der -in CA.pem -out CA.crt
sudo cp CA.crt /usr/local/share/ca-certificates
sudo update-ca-certificates
```

## Создание серверного ключа

```
export DOMAIN=example.com
openssl genrsa -out "$DOMAIN.key" 2048
```

- -aes256 - установка пароля на ключ. В примере этот параметр упущен.
  Если поставить пароль, 
  его придётся вводить при старте приложения 
  (или прописывать в конфигах путь к файлу с паролем).

## Создание серверного сертификата

Установим переменную DOMAIN. Должен соответствовать вашему домену

```
export DOMAIN=domain.example.com
```

- Переменная DOMAIN используется в дальнейших командах. 

```
openssl req -new -key "$DOMAIN.key" -out "$DOMAIN.csr" -subj "/CN=$DOMAIN"
```

- -subj - Избавляет от интерактивного ввода информации о домене. 
  Можно упустить этот аргумент

```
cat > "$DOMAIN.ext" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}
EOF
```

```
openssl x509 -req -in "$DOMAIN.csr" -CA CA.pem -CAkey CA.key -CAcreateserial -out "$DOMAIN.crt" -days 397 -sha256 -extfile "$DOMAIN.ext"
```

- -req            - input is a certificate request, sign and output.
- -in arg         - input file - default stdin
- -CA arg         - set the CA certificate, must be PEM format.
- -extfile        - configuration file with X509V3 extensions to add
- -CAkey arg      - set the CA key, must be PEM format
- -CAcreateserial - create serial number file if it does not exist
- -out arg        - output file - default stdout
- -days arg       - How long till expiry of a signed certificate - def 30 days
- -extfile        - configuration file with X509V3 extensions to add