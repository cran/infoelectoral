## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(echo = T, results = T, include = T, warning = F, message = F)

## -----------------------------------------------------------------------------
# install_packages("infoelectoral")
library(infoelectoral)
# Cargo el resto de librerías
library(dplyr)
library(tidyr)

## -----------------------------------------------------------------------------
results <- municipios("congreso", "2015", "12") # Descargo los datos

## -----------------------------------------------------------------------------
library(mapSpain)
shp <- esp_get_munic(year = "2016") %>% select(LAU_CODE)
shp_ccaa <- mapSpain::esp_get_ccaa()

## -----------------------------------------------------------------------------
results %>%
  group_by(codigo_partido_nacional) %>%
  summarise(
    siglas_r = paste(unique(siglas)[1], collapse = ", "),
    votos = sum(votos)
  ) %>%
  arrange(-votos)

## -----------------------------------------------------------------------------
results <-
  results %>%
  mutate(
    siglas_r = case_when(
      codigo_partido_nacional == "903316" ~ "PP",
      codigo_partido_nacional == "903484" ~ "PSOE",
      codigo_partido_nacional == "901079" ~ "Cs",
      codigo_partido_nacional %in% c("903736", "905033", "905008", "905041") ~ "Podemos",
      codigo_partido_nacional == "904850" ~ "IU"
    ),
    # Construyo la columna que identifica al municipio (LAU_CODE)
    LAU_CODE = paste0(codigo_provincia, codigo_municipio),
    # Calculo el % sobre censo
    pct = round((votos / censo_ine) * 100, 2)
  ) %>%
  filter(!is.na(siglas_r)) %>%
  # Selecciono las columnas necesarias
  select(codigo_ccaa, LAU_CODE, siglas_r, censo_ine, votos_candidaturas, pct)

## -----------------------------------------------------------------------------
shp <- left_join(shp, results, by = "LAU_CODE")

## ----fig.align="center", fig.height = 12, fig.width=8-------------------------
library(ggplot2)
library(purrr)
library(patchwork)

colores <- c("#0cb2ff", "#E01021", "#612d62", "#E85B2D", "#E01021")
names(colores) <- c("PP", "PSOE", "Podemos", "Cs", "IU")

# Creo una lista de plots
maps <-
  map(names(colores), function(p) {
    shp %>%
      filter(siglas_r == p) %>%
      ggplot() +
      geom_sf(
        aes(fill = pct, color = pct),
        linewidth = 0, show.legend = F
      ) +
      geom_sf(
        data = shp_ccaa, fill = NA, color = "black",
        linewidth = 0.1
      ) +
      facet_wrap(~siglas_r) +
      scale_fill_gradient(
        low = "white", high = colores[p],
        na.value = "grey90", aesthetics = c("fill", "color")
      ) +
      theme_void()
  })


# Uso patchworks para mostrar los plots
wrap_plots(maps, ncol = 2)

