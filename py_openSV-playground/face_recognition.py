import os
import cv2

imageList = os.listdir('./img')
# Cascade Datei von https://raw.githubusercontent.com/opencv/opencv/master/data/haarcascades/haarcascade_frontalface_default.xml
# Zur Gesichterkennung.
cascade = cv2.CascadeClassifier('./supplements/haarcascade_frontalface_default.xml')

for img in imageList:
    imagePath = './img/' + img
    actualImage = cv2.imread(imagePath)
    # Alle Bilder auf 512x512 bringen (alle sind eh schon quadratisch)
    if actualImage.shape[0] > 512:
        newDim = (512, 512)
        actualImage = cv2.resize(actualImage, newDim)
    # In Graustufen umwandeln, da cascade nur Graustufen kann.
    actualImageGray = cv2.cvtColor(actualImage, cv2.COLOR_BGR2GRAY)
    # Facerecognition mittels cascade (Bild, Scale Factor, minNeighbors
    actualFace = cascade.detectMultiScale(actualImageGray, 1.7, 7)
    # Rechteck malen (temporär) und croppen
    for (x, y, w, h) in actualFace:
        cv2.rectangle(actualImage, (x, y), (x + w, y + h), (255, 0, 0), 2)
        # print(actualFace)
        # print("x "+str(x)+", y "+str(y)+", w "+str(w)+", h "+str(h))
        croppedImg = actualImage[y:y + h, x:x + h]
    # cv2.imshow(img, actualImage)
    # print(actualImage.shape)
    # kPress = cv2.waitKey(0)
    cv2.imshow(img, croppedImg)
    # print(croppedImg.shape)
    kPress = cv2.waitKey(0)
