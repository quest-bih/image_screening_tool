library(tidyverse)
library(magick)

#---------------------------------------------------------------------------------------------------------------
# create label csv with all info
#---------------------------------------------------------------------------------------------------------------

img_folder <- "C:/Datenablage/Image screening tool/classified_images/"
img_folder_dest <- "C:/Datenablage/Image screening tool/training_images/"

dirs <- list.dirs(img_folder)[-1]

label_table <- tibble(image_name = "",
                      labels = "",
                      image_name_full = "")

for(i in 1:length(dirs))
{
  labels <- dirs[i] %>% str_split(fixed("/")) %>% map_chr(tail, 1)
  image_name <- list.files(dirs[i])
  image_name_full <- paste0(dirs[i], "/", list.files(dirs[i]))

  label_table <- rbind(label_table, cbind(image_name, labels, image_name_full))
}

label_table <- label_table[-1,]
label_table <- label_table %>%
  arrange(image_name) %>%
  distinct(image_name, .keep_all = TRUE)

#add images from 'Similar' category to the 'Other' category,
#as a separate 'Similar' category makes no sense
label_table <- label_table %>%
  mutate(labels = labels %>% str_replace("Similar", "Other"))

#filter out non-jpg files
label_table <- label_table[label_table$image_name %>% str_detect("jpg"),]

write_csv(label_table, paste0(img_folder_dest, "labels.csv"))


#--------------------------------------------------------------------------------------------
# copy images to train folder
#--------------------------------------------------------------------------------------------

label_table <- read_csv(paste0(img_folder_dest, "labels.csv"))

for(image_filename in label_table$image_name_full)
{
  file.copy(image_filename, paste0(img_folder_dest, "train"))
}


#---------------------------------------------------------------------------------------------------------------
# split in train & validation set and move the images
#---------------------------------------------------------------------------------------------------------------

img_folder_out <- paste0(img_folder_dest, "valid/")
label_table <- read_csv(paste0(img_folder_dest, "labels.csv"))

set.seed(64881)
rand_perc <- 0.1
rand_num <- ceiling(length(label_table$image_name) * rand_perc)
valid_img_files <- sample(label_table$image_name, rand_num)


for(i in 1:length(valid_img_files))
{
  image_name <- paste0(img_folder_dest, "train/" , valid_img_files[i])
  file.copy(image_name, img_folder_out)
  file.remove(image_name)
}


#---------------------------------------------------------------------------------------------------------------
# add train/valid info to labels file
#---------------------------------------------------------------------------------------------------------------

#add column with information on train/valid split to the table
label_table_new <- label_table %>%
  add_column(is_valid = "")

train_files <- list.files(paste0(img_folder_dest, "train/"))
label_table_new$is_valid[label_table_new$image_name %in% train_files] <- "False"

valid_files <- list.files(paste0(img_folder_dest, "valid/"))
label_table_new$is_valid[label_table_new$image_name %in% valid_files] <- "True"

#add correct filepath to image_name column
label_table_new$image_name[label_table_new$is_valid == "True"] <- paste0("valid/", label_table_new$image_name[label_table_new$is_valid == "True"])
label_table_new$image_name[label_table_new$is_valid == "False"] <- paste0("train/", label_table_new$image_name[label_table_new$is_valid == "False"])

label_table_new <- label_table_new %>%
  select(-image_name_full)

write_csv(label_table_new, paste0(img_folder_dest, "labels.csv"))


#---------------------------------------------------------------------------------------------------------------
# convert image sizes
#---------------------------------------------------------------------------------------------------------------

resize_img <- function(img_filename, width = 560, height = 560)
{
  img <- magick::image_read(img_filename)
  img_trfm <- magick::image_resize(img, geometry_size_pixels(width, height, preserve_aspect = FALSE))
  magick::image_write(img_trfm, img_filename)
}

image_filenames <- paste0(img_folder_dest, label_table_new$image_name)
image_filenames %>% map(resize_img)
