# author: cyber40014
# Matrikelnr: 123456

from Crypto.Util.strxor import strxor


def loadJsonDataFromWeb(url):
    import requests
    r = requests.get(url,headers={'Accept':'application/json'})
    d = r.json()
    import json
    with open("esa1.json","w") as outfile:
        outfile.write(json.dumps(d))
    outfile.close()


def loadJsonDataFromFile(fName):
    import json
    with open(fName) as f:
        data = json.load(f)
    return data


#-----------------------------------------------------------
url = 'https://cryptpad.th-brandenburg.de:8443/crypto/cbc/inputs?uid=xxxx&user=username&cid=xxxx&course=THB-ITS-20-S23-1234'
fName = 'esa1.json'
#loadJsonDataFromWeb(url)
data = loadJsonDataFromFile(fName)

cipher = data["cipher"]
iv = data["iv"]
target = data["target"]
uid = data["uid"]
user = data["user"]

print("--------------------------------------------------")
print("||                     TEIL 1                   ||")
print("--------------------------------------------------")
length = len(cipher)/32 #sollte 3.0 ergeben
if((length*10)%10==0):
    blocks = int(length)
cipher_block = [None] * blocks
cipher_decrypted_block = [None] * blocks
cipher_decrypted = ""
message_block = [None] * blocks
message = ""

#Bewusst simpel gehalten
#Cipher String in 3 Blöcke je 16 Byte trennen
print()
print("Cipher enthält "+str(blocks)+" Blöcke zu 16 Byte")
for x in range(0,blocks):
    cipher_block[x] = cipher[int((x*32)):int(((x+1)*32))]
print(cipher_block)
print()
#Entschluesselungsorakel nutzen um für jeden Cipherblock
#Cipher_Decrypted_Block abzuholen
print("Cipher_Decrypted enthält "+str(blocks)+" Blöcke zu 16 Byte")
for x in range(0,blocks):
    url = 'https://cryptpad.th-brandenburg.de:8443/crypto/cbc/decrypt/'+cipher_block[x]
    import requests
    r = requests.get(url)
    import time
    time.sleep(0.5)
    cipher_decrypted_block[x] = r.text
    cipher_decrypted += cipher_decrypted_block[x]
print(cipher_decrypted_block)
print()

#Entschlüsseln
print("Entschlüsseln von "+str(blocks)+" Blöcken zu 16 Byte")
for x in range(0,blocks):
    #cipher_decrypted_block von hex in bytes konvertieren
    ci_d_byte = bytes.fromhex(cipher_decrypted_block[x])

    #XOR um Messageblock zu erstellen
    if(x == 0):
        #iv in bytes konvertieren
        iv_byte = bytes.fromhex(iv)
        message_block[x] = strxor(ci_d_byte,iv_byte).decode('utf-8')
    else:
        #Letzten Cipher Block in bytes konvertieren
        ci_previousBlock_byte = bytes.fromhex(cipher_block[(x-1)])
        message_block[x] = strxor(ci_d_byte,ci_previousBlock_byte).decode('utf-8')
print(message_block)
print()

#Kombinieren der Message
for x in range(0,blocks):
    message += message_block[x]
print("Die Nachricht lautet:")
print(message)

print()
print()
print("--------------------------------------------------")
print("||                     TEIL 2                   ||")
print("--------------------------------------------------")

cipher2_block = [None] * blocks
cipher2_decrypted_block = [None] * blocks
cipher2_decrypted = ""
message2_block = [None] * blocks
message2_hex_block= [None] * blocks
message2 = target

print("Die Nachricht lautet:")
print(message2)

#message2 in Blöcke teilen
print()
print("Zerlege Message2 in "+str(blocks)+" Blöcke zu je 16 Buchstaben")
for x in range(0,blocks):
    message2_block[x] = message2[int((x*16)):int(((x+1)*16))]
print(message2_block)

#Cipher2_Block[2] entspricht Cipher_Block[2]
#Cipher2_Decrypted_Block[2] entspricht Cipher_Decrypted_Block[2]

cipher2_block[2] = cipher_block[2]
cipher2_decrypted_block[2] = cipher_decrypted_block[2]

#Wandle message2_block in hex um.
for x in range(0,blocks):
    message2_hex_block[x] = bytes(message2_block[x],'utf-8').hex()
print(message2_hex_block)
print()

#
print("cipher2_block[2] = cipher_block[2]")
print(cipher2_block[2])

#message2_hex_block[2] XOR Cipher2_Decrypted_Block[2]
#   = Cipher2_Block[1]
print("message2_hex_block[2] XOR cipher2_decrypted_block[2] =")
print("cipher2_block[1]")
msg2hex2_bytes = bytes.fromhex(message2_hex_block[2])
ci2_dec2_bytes = bytes.fromhex(cipher2_decrypted_block[2])
cipher2_block[1] = strxor(msg2hex2_bytes, ci2_dec2_bytes).hex()
print(cipher2_block[1])
print()

#Für cipher2_block[1], cipher2_decrypted_block[1] mittels Orakel abholen
url = 'https://cryptpad.th-brandenburg.de:8443/crypto/cbc/decrypt/'+cipher2_block[1]
import requests
r = requests.get(url)
import time
time.sleep(0.5)
cipher2_decrypted_block[1] = r.text


#message2_hex_block[1] XOR Cipher2_Decrypted_Block[1]
#   = Cipher2_Block[0]
print("message2_hex_block[1] XOR cipher2_decrypted_block[1] =")
print("cipher2_block[0]")
msg2hex1_bytes = bytes.fromhex(message2_hex_block[1])
ci2_dec1_bytes = bytes.fromhex(cipher2_decrypted_block[1])
cipher2_block[0] = strxor(msg2hex1_bytes, ci2_dec1_bytes).hex()
print(cipher2_block[0])
print()

#Für cipher2_block[0], cipher2_decrypted_block[0] mittels Orakel abholen
url = 'https://cryptpad.th-brandenburg.de:8443/crypto/cbc/decrypt/'+cipher2_block[0]
import requests
r = requests.get(url)
import time
time.sleep(0.5)
cipher2_decrypted_block[0] = r.text

#message2_hex_block[0] XOR Cipher2_Decrypted_Block[0]
#   = iv2
print("message2_hex_block[0] XOR Cipher2_Decrypted_Block[0]  =")
print("iv2")
msg2hex0_bytes = bytes.fromhex(message2_hex_block[0])
ci2_dec0_bytes = bytes.fromhex(cipher2_decrypted_block[0])
iv2 = strxor(msg2hex0_bytes, ci2_dec0_bytes).hex()
print(iv2)
print()



#Testfile schreiben
outCipher = ""
outIV = iv2
outTarget = message
for x in range(0,blocks):
    outCipher += cipher2_block[x]

jsonstr = '{"cipher": "'+outCipher+'", "iv": "'+outIV+'", "target": "'+outTarget+'", "uid": 42219, "user": "schopchris"}'


import json
with open("esa1test.json","w") as outfile:
    outfile.write(jsonstr)
outfile.close()

outMsgSolution = message
jsonstr = '{"cipher2": "'+outCipher+'", "iv2": "'+outIV+'", "message": "'+outMsgSolution+'", "uid": 42219, "user": "schopchris"}'

import json
with open("solution.json","w") as outfile:
    outfile.write(jsonstr)
outfile.close()