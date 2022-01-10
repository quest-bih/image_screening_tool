#!/usr/bin/env python3

from fastai.vision.all import *
from matplotlib import pyplot
import numpy as np
import pandas as pd
np.set_printoptions(threshold=sys.maxsize)

#---------------------------------------------------------------------------------
# run configs
#---------------------------------------------------------------------------------

import image_screening_tool

label_file = 'labels.csv'

run_specs_label = 'test'

tmp_folder_run = './tmp/'


#---------------------------------------------------------------------------------
# train screening tool
#---------------------------------------------------------------------------------

np.random.seed(42)

#load dataset from csv with labels & filenames
df = pd.read_csv('./training_images/' + label_file)
df = df.sample(frac = 1)
data = ImageDataLoaders.from_df(df, path='./training_images',
    valid_col='is_valid', bs=16, label_delim = "_",
    item_tfms=Resize(560))

#choose the pretrained network architecture & re-train on new dataset 
learn = cnn_learner(data, resnet50, metrics=accuracy_multi) 
#learn.lr_find(show_plot=False) # estimation: lr_min=0.030, lr_steep=0.040
learn.fine_tune(3)

#save trained model
model_export_file = 'image_screening_tool_' + run_specs_label + '.pkl'
learn.export(model_export_file)


#---------------------------------------------------------------------------------
# calculate internal validation
#---------------------------------------------------------------------------------

screening_tool = image_screening_tool.Screening_Tool('./training_images/' + model_export_file)
screening_result = screening_tool.predict_from_img_folder('./training_images/valid/')
screening_result = pd.DataFrame(screening_result).transpose()

screening_result.to_csv('./results_csv/image_screening_tool_' + run_specs_label + '.csv')
