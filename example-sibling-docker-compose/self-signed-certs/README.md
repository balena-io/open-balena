# Create a Certificate Authority and generate a cert from that

## Create the CA and cert for your domain
```bash
./create_install_certificates.sh yourdomain.com
```

The `root` folder contains everything as per easy-rsa specs.

For convenience you can also find the rootCA and the cert in the `cert` folder and the corresponding key in the `key` folder.

Re-running the command will not destroy the certificates.

### Create a new CA
To create a new CA, simply delete the root folder.

## Install the cert on your machine

### Ubuntu

```bash
sudo cp ./root/ca.crt /usr/local/share/ca-certificates/yourdomain.com.crt
sudo update-ca-certificates --fresh
```

You can test the validity:
```bash
sudo openssl x509 -in /etc/ssl/certs/aivero.lan.pem -noout -text

# requires some server serving the certs
sudo openssl s_client -connect yourdomain.com:443 -CApath /etc/ssl/certs
# Ctrl+c to exit
```


### Firefox
Firefox ignores the certificate store of the OS, you need to manually install it.
```
Settings->
    click 'Privacy & Security'->
        scroll to 'Security' section ->
            click 'View Certificates' ->
                select tab 'Authorities' ->
                    click 'Import' and select your cert ->
                        click 'This certificate can identify websites'->
                            save
```
