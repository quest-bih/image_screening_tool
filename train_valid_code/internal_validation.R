library(tidyverse)
library(caret)

#------------------------------------------------------------------------------------------
# functions
#------------------------------------------------------------------------------------------

binary_class_encoding <- function(label_table, class_labels, label_addon = "", use_flow = TRUE)
{
  if(!use_flow) {
    class_labels_int = class_labels[class_labels != "flow"]
    label_table[label_table$labels == "flow",]$labels <- "other"
  } else {
    class_labels_int = class_labels
  }

  label_list <- label_table$labels %>% str_split("_")
  label_results <- class_labels_int %>% map(function(y) (label_list %>% map_lgl(function(x) y %in% x)))
  names(label_results) <- paste0(class_labels_int, label_addon)

  label_results <- label_results %>%
    as_tibble() %>%
    add_column(image_name = label_table$image_name)

  return(label_results)
}

calc_performance <- function(validation_results, barzooka_results)
{
  #combine results and bring them into the right format for performance calculation
  compare_results <- validation_results %>%
    left_join(barzooka_results, by = "image_name")

  pred_cols <- colnames(barzooka_results) %>% head(-1)
  gold_cols <- colnames(validation_results) %>% head(-1)


  metrics_table <- map2(pred_cols, gold_cols,
                        function(x,y) performance_metrics(compare_results[[x]], compare_results[[y]]))
  metrics_table <- do.call(rbind, metrics_table)
  metrics_table <- cbind(pred_cols, metrics_table) %>%
    as_tibble() %>%
    rename(class = pred_cols) %>%
    mutate(class = class %>% str_remove("_barz"))

  return(metrics_table)
}

#calculate performance metrics
performance_metrics <- function(predictions, y)
{
  cont <- table(y, predictions)

  #special case if no positive predictions for one class
  if(length(colnames(cont)) == 1 && colnames(cont) == "FALSE")
  {
    tn <- cont[1,1]
    tp <- 0
    fp <- 0
    fn <- cont[2,1]
  } else {
    tn <- cont[1,1]
    tp <- cont[2,2]
    fp <- cont[1,2]
    fn <- cont[2,1]
  }

  count_manual <- tp + fn
  count_barzooka <- tp + fp

  prec <- tp / (tp + fp)
  rec <- tp / (tp + fn)

  sens <- rec
  spec <- tn / (tn + fp)

  F1 <- (2 * prec * rec) / (prec + rec)
  acc <- (tp + tn) / (tp + tn + fp + fn)

  metrics <- tibble(count_manual, count_barzooka, tp, tn, fp, fn, sens, spec, prec, rec, F1, acc)
  colnames(metrics) <- c("cases_manual", "cases_barzooka",
                         "true_positives", "true_negatives",
                         "false_positives", "false_negatives",
                         "sensitivity", "specificity",
                         "precision", "recall",
                         "F1", "accuracy")
  return(metrics)
}


preprocess_predicted <- function(pred_data)
{
  pred_labels <- pred_data[2:3]
  colnames(pred_labels) <- c("image_name", "labels")

  pred_labels$image_name <- pred_labels$image_name %>%
    str_split("/") %>%
    map_chr(last)
  pred_labels$labels <- pred_labels$labels %>%
    str_remove_all(fixed("['")) %>%
    str_remove_all(fixed("']")) %>%
    str_replace_all(fixed("', '"), "_")

  pred_labels <- pred_labels %>%
    arrange(image_name)

  return(pred_labels)
}


#------------------------------------------------------------------------------------------
# data loading and preprocessing
#------------------------------------------------------------------------------------------

valid_labels <- read_csv("training_images/labels.csv") %>%
  filter(is_valid)
valid_labels$image_name <- valid_labels$image_name %>% str_split("/") %>% map_chr(2)
valid_labels <- valid_labels %>%
  arrange(image_name)

pred_labels <- read_csv("results_csv/image_screening_tool_internal_validation.csv") %>%
  preprocess_predicted()

class_labels <- valid_labels$labels %>% str_split("_") %>% unlist() %>% unique() %>% sort()

valid_labels_binary <- binary_class_encoding(valid_labels, class_labels, "_valid")
pred_labels_binary <- binary_class_encoding(pred_labels, class_labels, "_pred")


#------------------------------------------------------------------------------------------
# comparison of results
#------------------------------------------------------------------------------------------

metrics_table_int <- calc_performance(valid_labels_binary, pred_labels_binary) %>%
  mutate(across(sensitivity:accuracy, ~ .x %>% round(2)))
write_csv(metrics_table_int, "results_csv/performance_metrics.csv")

#total number of labels so far
read_csv("training_images/labels.csv")$labels %>% str_split("_") %>% unlist() %>% table()

