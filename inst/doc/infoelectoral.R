## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(echo = T, results = T, include = T, warning = F, message = F)
options(HTTPUserAgent="Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36")


## -----------------------------------------------------------------------------
library(infoelectoral)
library(dplyr)
df <- municipios(tipo_eleccion = "congreso", anno = "1982", mes = "10")
glimpse(df)
# Sys.sleep(4)

## -----------------------------------------------------------------------------
df <- mesas("congreso", "2019", "04")
glimpse(df)
# Sys.sleep(4)

## -----------------------------------------------------------------------------
df <- candidatos(tipo_eleccion = "senado", anno = "2019", mes = "11", nivel = "municipio")
glimpse(df)
# Sys.sleep(4)

## -----------------------------------------------------------------------------
df <- candidatos("europeas", "2019", "05")
glimpse(df)

