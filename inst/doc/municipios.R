## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(echo = T, results = T, include = T, warning = F, message = F)

## -----------------------------------------------------------------------------
# devtools::install_github("ropenspain/elecciones") # <--- Instala la librería elecciones

library(infoelectoral)
# Cargo el resto de librerías
library(dplyr)
library(tidyr)


## -----------------------------------------------------------------------------

results <- municipios("congreso", "2015", "12") # Descargo los datos


## -----------------------------------------------------------------------------
library(mapSpain)
shp <- esp_munic.sf %>% select(LAU_CODE)

## -----------------------------------------------------------------------------

siglas_r <- results %>% 
  group_by(codigo_partido_nacional) %>% 
  summarise(siglas_r = siglas[1]) %>% 
  filter(siglas_r %in% c("PP", "PSE-EE (PSO", "PSOE", "PODEMOS-AHA",
                         "PODEMOS-COM", "PODEMOS-En", "C´s", "EN COMÚ",
                         "IU-UPeC", "IULV-CA,UPe")) %>% 
  mutate(siglas_r = case_when(
    siglas_r %in% c("PODEMOS-COM", "PODEMOS-En", "EN COMÚ", "PODEMOS-AHA") ~ "Podemos",
    siglas_r == "PSE-EE (PSO" ~ "PSOE",
    siglas_r == "C´s" ~ "Cs",
    siglas_r == "IULV-CA,UPe" ~ "IU",
    TRUE ~ siglas_r
    
  ))

results <- merge(results, siglas_r, by = "codigo_partido_nacional")

results <- results %>% 
  mutate(
    # Construyo la columna que identifica al municipio (LAU_CODE)
    LAU_CODE = paste0(codigo_provincia, codigo_municipio),
    # Calculo el % sobre censo
    pct = round((votos / censo_ine ) * 100, 2)
    ) %>% 
  # Selecciono las columnas necesarias
  select(codigo_ccaa, LAU_CODE, siglas_r, censo_ine, votos_candidaturas, pct) %>% 
  # Transformo los datos de formato long a wide
  pivot_wider(names_from = "siglas_r", values_from = "pct")


## -----------------------------------------------------------------------------
shp <- merge(shp, results, by = "LAU_CODE")

# Acercamos las Canarias a la peninsula
shp$geometry[shp$codigo_ccaa == "05"] <- shp$geometry[shp$codigo_ccaa == "05"] + c(5, 5)


## ----fig.align="center", fig.height = 12, fig.width=8-------------------------
colores5 <- list(c("#ededed", "#0cb2ff"), # PP
                 c("#ededed", "#E01021"), # PSOE
                 c("#ededed", "#612d62"), # Podemos
                 c("#ededed", "#E85B2D"), # Cs
                 c("#ededed", "#E01021")) # IU

breaks <- c(0,10,30,50,70,100)

library(tmap)
mapa <- tm_shape(shp) + 
  tm_polygons(col = c("PP", "PSOE", "Podemos", "Cs", "IU"), style = "fixed", 
              palette = colores5, breaks = breaks,
              title = "% sobre censo", 
              border.alpha = 0, lwd = 0, legend.show = T, legend.outside = T) +
  tm_layout(between.margin = 5, frame = FALSE,
            title = c("Partido Popular", "PSOE", "Podemos", "Ciudadanos", "Izquierda Unida"),
            title.fontface = "bold") +
  tm_legend(legend.text.size = 1, 
            legend.title.size = 1) +
  tm_facets(sync = TRUE, ncol = 2)
mapa

