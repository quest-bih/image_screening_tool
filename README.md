# Image screening tool

This image screening tool is designed to screen biomedical publications for different image types. It is based on a deep convolutional network trained using the fastai python package (https://docs.fast.ai/). It screens a publication on the page level and can detect multiple image types per page. The following image types can currently be detected:

 - blots
 - electron microscope images
 - microscopy photographs
 - other photographs

This tool is still work in progress. Further updates are planned that improve the performance of the tool and that add additional detected classes.


## Contributors

Nico Riedel - 
QUEST Center for Transforming Biomedical Research, Berlin Institute of Health (BIH) at Charité – Universitätsmedizin Berlin, Berlin, Germany
https://orcid.org/0000-0002-3808-1163

Małgorzata Anna Gazda - 
CIBIO/InBIO, Centro de Investigação em Biodiversidade e Recursos Genéticos, Campus Agrário de Vairão, Universidade do Porto, Vairão, Portugal, Departamento de Biologia, Faculdade de Ciências, Universidade do Porto, Porto, Portugal, https://orcid.org/0000-0001-8369-1350
 
Alberto Antonietti - 
Department of Electronics, Information and Bioengineering, Politecnico di Milano, Italy, Department of Brain and Behavioral Sciences, University of Pavia, Pavia, Italy
https://orcid.org/0000-0003-0388-6321
 
Susann Auer - 
Department of Plant Physiology, Faculty of Biology, Technische Universität Dresden, Dresden, Germany
https://orcid.org/0000-0001-6566-5060

Tracey Weissgerber - 
QUEST Center for Transforming Biomedical Research, Berlin Institute of Health (BIH) at Charité – Universitätsmedizin Berlin, Berlin, Germany
https://orcid.org/0000-0002-7490-2600

Conceptualization: All \
Data curation: TLW, MAG, AA, SA \
Methodology: All \
Software: NR \


## Usage

The main file 'image_screening_tool.py' exposes several functions that can be used to screen individual images, PDF files or folders containing PDF files.

First, you need to create an instance of the Screening_Tool class using the model file path as input parameter
```python
from image_screening_tool import Screening_Tool
st = Screening_Tool("model_file.pkl")
```

Then, several functions can be used to make predictions on sets of images or PDF files.

```python
st.predict_from_folder(pdf_folder, save_filename, tmp_folder='./tmp/')
```
Takes the path to a pdf folder and screens all the PDFs in that folder. Saves a csv of the results under save_filename. The temp folder is used to temporarily store the extracted images from the pages of the PDF. Requires the poppler library to be pre-installed on the system to convert the PDFs to images. If not pre-installed, you can for example install the library via conda like this:

```python
conda install poppler
```


```python
st.predict_from_file(pdf_file, tmp_folder='./tmp/', pagewise=False)
```
Prediction on a single PDF file. If ```pagewise=False```, returns summarized results for PDF (how many pages were detected for each class), otherwise returns list of predicted classes for each page.

```python
st.predict_from_img(img_files)
```

Returns prediction for list of image files. 

```python
st.predict_from_img_folder(img_folder)
```

Same as predict_from_img, just takes path to folder containing image files as input and screens all images in that folder.


## Performance

Those are the current performance metric on the validation dataset, consisting of 10% of the entire dataset that were not used for training of the model.

| class | cases_manual | cases_tool | true_pos | true_neg | false_pos | false_neg | sensitivity | specificity | precision | recall | F1 | accuracy |
|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|
| Blot | 197 | 189 | 186 | 786 | 3 | 11 | 0.94 | 1 | 0.98 | 0.94 | 0.96 | 0.99 |
| EM | 24 | 26 | 20 | 956 | 6 | 4 | 0.83 | 0.99 | 0.77 | 0.83 | 0.8 | 0.99 |
| Medical | 5 | 3 | 1 | 979 | 2 | 4 | 0.2 | 1 | 0.33 | 0.2 | 0.25 | 0.99 |
| MicroPhoto | 235 | 240 | 220 | 731 | 20 | 15 | 0.94 | 0.97 | 0.92 | 0.94 | 0.93 | 0.96 |
| Other | 485 | 492 | 476 | 485 | 16 | 9 | 0.98 | 0.97 | 0.97 | 0.98 | 0.97 | 0.97 |
| Photo | 88 | 71 | 66 | 893 | 5 | 22 | 0.75 | 0.99 | 0.93 | 0.75 | 0.83 | 0.97 |
| Text | 60 | 60 | 59 | 925 | 1 | 1 | 0.98 | 1 | 0.98 | 0.98 | 0.98 | 1 |


## Additional files

Folder 'train_valid_code'

 - training_data_create_labels.R:
   generates label.csv file and train/valid image folders from folder of classified images (with the images sorted in different folders accoring to the detected labels; if multiple labels apply to one image, it has to be sorted into all relevant folders)

 - train_valid.py:
   trains the model given the label.csv file and the train/valid image folders

 - internal_validation.R:
   calculates the different performance metrics using the images contained in the valid folder


Folder 'training_images':

Contains the label.csv file. Unfortunately the train/valid image folders cannot be shared publically due to potential copyright issues for the journal articles used to train the model.

Folder 'results_csv':

Contains the results of the model for the validation data + the derived performance metrics table
