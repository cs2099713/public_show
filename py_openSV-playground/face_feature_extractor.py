import os
import cv2
import csv
import face_recognition

imgMorphsPath = './img/reference'
imgOriginalsPath = './img/input'
cascade = cv2.CascadeClassifier('./inc/haarcascade_frontalface_default.xml')
csv_folder_path = './output'


class Image:

    def __init__(self, filename, filepath, name, morph):
        self.filepath = filepath
        self.name = name
        self.filename = filename
        self.morph = morph
        self.gray = self.generate_grayscale()
        self.color = self.generate_color()
        self.face_cascade = self.generate_cascade(cascade)
        self.face_encoding = self.generate_encoding()

        # CreateObjects
        self.sift = cv2.SIFT_create()
        # self.surf = cv2.xfeatures2d.SURF_create()
        self.orb = cv2.ORB_create(nfeatures=1500)
        self.fast = cv2.FastFeatureDetector_create()
        self.agast = cv2.AgastFeatureDetector_create()

        # Keypoints
        self.sift_keypoints = self.generate_keypoints(self.sift)
        # self.surf_keypoints = self.generate_keypoints(self.surf)
        self.orb_keypoints = self.generate_keypoints(self.orb)
        self.fast_keypoints = self.generate_keypoints(self.fast)
        self.agast_keypoints = self.generate_keypoints(self.agast)

        # Colored Images with drawed Keypoints
        self.color_sift = self.draw_keypoints(self.sift_keypoints, 'sift')
        # self.color_surf = self.draw_keypoints(self.surf_keypoints, 'surf')
        self.color_orb = self.draw_keypoints(self.orb_keypoints, 'orb')
        self.color_fast = self.draw_keypoints(self.fast_keypoints, 'fast')
        self.color_agast = self.draw_keypoints(self.agast_keypoints, 'agast')

        # Entfernt da für fast und agast wegen 2d feature detection nicht verfügbar
        # https://docs.opencv.org/4.x/d2/dca/group__xfeatures2d__nonfree.html
        # compute descriptors
        # self.sift_descriptors = self.compute_des(self.sift, self.sift_keypoints)
        # self.surf_descriptors = self.compute_des(self.surf, self.surf_keypoints)
        # self.orb_descriptors = self.compute_des(self.orb, self.orb_keypoints)
        # self.fast_descriptors = self.compute_des(self.fast, self.fast_keypoints)
        # self.agast_descriptors = self.compute_des(self.agast, self.agast_keypoints)

        # generate length
        self.sift_kp_len = len(self.sift_keypoints)
        # self.surf_kp_len = len(self.surf_keypoints)
        self.orb_kp_len = len(self.orb_keypoints)
        self.fast_kp_len = len(self.fast_keypoints)
        self.agast_kp_len = len(self.agast_keypoints)

        # generate point2f vectors
        self.vector_sift = self.convert_kp_to_vector(self.sift_keypoints)
        # self.vector_surf = self.convert_kp_to_vector(self.surf_keypoints)
        self.vector_orb = self.convert_kp_to_vector(self.orb_keypoints)
        self.vector_fast = self.convert_kp_to_vector(self.fast_keypoints)
        self.vector_agast = self.convert_kp_to_vector(self.agast_keypoints)

    def __str__(self):
        if self.morph == True:
            return f"{self.name};{self.morph};{self.filepath};{self.filename}"
        else:
            return f"{self.name};{self.morph};{self.filepath};{self.filename}"

    def generate_color(self):
        color = cv2.imread(self.filepath)
        return color

    def generate_grayscale(self):
        gray = cv2.imread(self.filepath, cv2.IMREAD_GRAYSCALE)
        return gray

    def generate_cascade(self, cascade):
        face = cascade.detectMultiScale(self.gray, 1.7, 7)
        return face

    def generate_encoding(self):
        encoding = face_recognition.face_encodings(self.color)[0]
        return encoding

    def generate_keypoints(self, create_object):
        keypoints = create_object.detect(self.gray, None)
        return keypoints

    def compute_des(self, create_object, keypoints):
        kp, des = create_object.compute(self.color, keypoints)
        return des

    def draw_keypoints(self, keypoints, algorithm):
        if algorithm == 'sift':
            self.color_sift = self.generate_color()
            img = cv2.drawKeypoints(self.color, self.sift_keypoints, self.color_sift)
        # elif algorithm == 'surf':
        # self.color_surf = self.generate_color()
        # img = cv2.drawKeypoints(self.color,self.surf_keypoints,self.color_surf)
        elif algorithm == 'orb':
            self.color_orb = self.generate_color()
            img = cv2.drawKeypoints(self.color, self.orb_keypoints, self.color_orb)
        elif algorithm == 'fast':
            self.color_fast = self.generate_color()
            img = cv2.drawKeypoints(self.color, self.fast_keypoints, self.color_fast)
        elif algorithm == 'agast':
            self.color_agast = self.generate_color()
            img = cv2.drawKeypoints(self.color, self.agast_keypoints, self.color_agast)
        return img

    # Konvertieren der keypoints zu points2f Vektoren
    def convert_kp_to_vector(self, keypoints):
        vector = cv2.KeyPoint.convert(keypoints)
        return vector

    def features_len_to_csv(self, folder_path):
        if self.morph == True:
            morph_label = 1
        else:
            morph_label = 0
        csv_path = folder_path + "/" + str(morph_label) + "__" + self.filename.split(".")[0] + ".csv"
        #print(csv_path)
        header_row = ["filename", "filepath", "morph_label", "sift_kp_len", "orb_kp_len", "fast_kp_len", "agast_kp_len"]
        data_row = [self.filename, self.filepath, morph_label, self.sift_kp_len, self.orb_kp_len, self.fast_kp_len,
                    self.agast_kp_len]

        with open(csv_path, 'w', newline='') as csvfile:
            writer = csv.writer(csvfile, delimiter=';')
            writer.writerow(header_row)
            writer.writerow(data_row)
            csvfile.close()


# Vorbereiten von Array mit Dateipfaden zu Morphs und Originalen
imgMorphs = os.listdir(imgMorphsPath)
imgOriginals = os.listdir(imgOriginalsPath)
i = 0
images = []
for img in imgMorphs:
    fname = img
    name = img[0:5]
    #print(fname + " " + name)
    img = imgMorphsPath + "/" + img
    tmpImg = Image(fname, img, name, True)
    #print(tmpImg.__str__())
    images.append(tmpImg)
    i += 1

i = 0
#print(len(images))
for img in imgOriginals:
    fname = img
    name = img[0:5]
    #print(fname +" "+name)
    img = imgOriginalsPath + "/" + img
    tmpImg = Image(fname, img, name, False)
    #print(tmpImg.__str__())
    images.append(tmpImg)
    i += 1
#print(len(images))
debug = False

if debug == True:
    print(images[0].__str__())
    cv2.imshow("Img", images[0].color)
    cv2.imshow("SIFT", images[0].color_sift)
    # cv2.imshow("SURF", images[0].color_surf)
    cv2.imshow("ORB", images[0].color_orb)
    cv2.imshow("FAST", images[0].color_fast)
    cv2.imshow("AGAST", images[0].color_agast)
    kPress = cv2.waitKey(0)
    cv2.destroyAllWindows()
    print("SIFT Length: " + str(images[0].sift_kp_len))
    # print("SURF Length: "+str(images[0].surf_kp_len))
    print("ORB Length: " + str(images[0].orb_kp_len))
    print("FAST Length: " + str(images[0].fast_kp_len))
    print("AGAST Length: " + str(images[0].agast_kp_len))



for image in images:
    print("Exporting feature length for: "+str(image.filepath))
    image.features_len_to_csv(csv_folder_path)
