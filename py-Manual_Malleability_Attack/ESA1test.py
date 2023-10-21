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
url = 'https://cryptpad.th-brandenburg.de:8443/crypto/cbc/inputs?uid=123456&user=username&cid=123456&course=THB-ITS-20-S23-123456'
fName = 'esa1test.json'
#loadJsonDataFromWeb(url)
data = loadJsonDataFromFile(fName)

cipher = data["cipher"]
iv = data["iv"]
target = data["target"]
uid = data["uid"]
user = data["user"]

print("--------------------------------------------------")
print("||                 TESTE ERGEBNISSE             ||")
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
print("Teste solution.json parsing")
solution = loadJsonDataFromFile("solution.json")
print(solution)
print()
print("message: "+solution["message"])
print("cipher2: "+solution["cipher2"])
print("iv2: "+solution["iv2"])
print("uid: "+str(solution["uid"]))
print("user: "+solution["user"])




