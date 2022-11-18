#!/usr/bin/env python3
#
# Utility to generate private/public key pair.
# The private key may be used to generate a UBX-CFG-OTP message to write the eFuse

from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import serialization
import binascii
import sys

private_key = ec.generate_private_key(ec.SECP192R1())
vals = private_key.private_numbers()
no_bits=vals.private_value.bit_length()
print (f"Private key value: {vals.private_value}. Number of bits {no_bits}")
print (f"Private (d): {hex(vals.private_value)}")

public_key = private_key.public_key()
vals=public_key.public_numbers()
print (f"Public (Px): {hex(vals.x)}")
print (f"Public (Py): {hex(vals.y)}")

enc_point=binascii.b2a_hex(public_key.public_bytes(encoding=serialization.Encoding.PEM,
    format=serialization.PublicFormat.SubjectPublicKeyInfo)).decode()
print (f"\nPublic key encoded point: {enc_point} \nx={enc_point[2:(len(enc_point)-2)//2+2]} \ny={enc_point[(len(enc_point)-2)//2+2:]}")

pem = private_key.private_bytes(encoding=serialization.Encoding.PEM,format=serialization.PrivateFormat.PKCS8,encryption_algorithm=serialization.NoEncryption())
der = private_key.private_bytes(encoding=serialization.Encoding.DER,format=serialization.PrivateFormat.PKCS8,encryption_algorithm=serialization.NoEncryption())
print ("\nPrivate key (PEM):\n",pem.decode())
print ("Private key (DER):\n",binascii.b2a_hex(der))

pem = public_key.public_bytes(encoding=serialization.Encoding.PEM,format=serialization.PublicFormat.SubjectPublicKeyInfo)
der = public_key.public_bytes(encoding=serialization.Encoding.DER,format=serialization.PublicFormat.SubjectPublicKeyInfo)
print ("\nPublic key (PEM):\n",pem.decode())
print ("Public key (DER):\n",binascii.b2a_hex(der))
