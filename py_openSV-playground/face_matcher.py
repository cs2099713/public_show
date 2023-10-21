import os
import cv2
import face_recognition

cascade = cv2.CascadeClassifier('./inc/haarcascade_frontalface_default.xml')

# Einlesen des Eingabebildes (echt) >> imgInput
inputs = os.listdir('./img/input')
imgInput = './img/input/' + inputs[7]
print(imgInput)

# Einlesen des Referenzbildes (morph) >> imgReference
references = os.listdir('./img/reference')
referenceList = os.listdir('./img/reference')
imgReference = './img/reference/' + references[3]
print(imgReference)

# Bild als Bild einlesen
imageInput = cv2.imread(imgInput)
imageReference = cv2.imread(imgReference)
# InputImage auf 512x512 bringen
if imageInput.shape[0] > 512:
    newDim = (512, 512)
    imageInput = cv2.resize(imageInput, newDim)
# In Graustufen umwandeln, da cascade nur Graustufen kann.
imageInputGray = cv2.cvtColor(imageInput, cv2.COLOR_BGR2GRAY)
imageReferenceGray = cv2.cvtColor(imageReference, cv2.COLOR_BGR2GRAY)
# Facerecognition mittels cascade (Bild, Scale Factor, minNeighbors)
cascadeInput = cascade.detectMultiScale(imageInputGray, 1.7, 7)
cascadeReference = cascade.detectMultiScale(imageReferenceGray, 1.7, 7)
print(cascadeInput)
print()
print(cascadeReference)
# Erkanntes Gesicht mit Rechteck markieren cascade = [[x,y,w,h]]
cv2.rectangle(
    imageInput,
    (cascadeInput[0][0], cascadeInput[0][1]),
    (cascadeInput[0][0] + cascadeInput[0][2], cascadeInput[0][1] + cascadeInput[0][3]),
    (255, 0, 0),
    2
)
cv2.rectangle(
    imageReference,
    (cascadeReference[0][0], cascadeReference[0][1]),
    (cascadeReference[0][0] + cascadeReference[0][2], cascadeReference[0][1] + cascadeReference[0][3]),
    (255, 0, 0),
    2
)
# Crop auf erkannten Bereich
imageInputCropped = imageInput[cascadeInput[0][1]:cascadeInput[0][1] + cascadeInput[0][3],
                        cascadeInput[0][0]:cascadeInput[0][0] + cascadeInput[0][3]]
imageReferenceCropped = imageReference[cascadeReference[0][1]:cascadeReference[0][1] + cascadeReference[0][3],
                        cascadeReference[0][0]:cascadeReference[0][0] + cascadeReference[0][3]]
# Bilder anzeigen
#cv2.imshow("Original 1", imageInput)
#kPress = cv2.waitKey(0)
#cv2.imshow("Referenz (Morph)", imageReference)
#kPress = cv2.waitKey(0)

#Gesichtsmerkmale erkennen
encodingInput = face_recognition.face_encodings(imageInput)[0]
encodingReference = face_recognition.face_encodings(imageReference)[0]
#Vergleich
result = face_recognition.compare_faces([encodingInput],encodingReference, 0.5)
if result == [True]:
    print("0.5 Die biometrischen Merkmale stimmen überein.")
else:
    print("0.5 Die biometrischen Merkmale stimmen nicht überein.")
#Vergleich
result = face_recognition.compare_faces([encodingInput],encodingReference, 0.6)
if result == [True]:
    print("0.6 Die biometrischen Merkmale stimmen überein.")
else:
    print("0.6 Die biometrischen Merkmale stimmen nicht überein.")
#Vergleich
result = face_recognition.compare_faces([encodingInput],encodingReference, 0.7)
if result == [True]:
    print("0.7 Die biometrischen Merkmale stimmen überein.")
else:
    print("0.7 Die biometrischen Merkmale stimmen nicht überein.")

