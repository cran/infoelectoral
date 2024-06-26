#' @title Download data at the electoral constituency level (province or island)
#'
#' @description `provincias()` downloads, formats and imports to the environment the electoral results data of the selected election at electoral constituency level (province or island).
#'
#' @param tipo_eleccion The type of choice you want to download. The accepted values are "congreso", "senado", "europeas" o "municipales".
#' @param anno The year of the election in YYYY format.
#' @param mes The month of the election in MM format.
#'
#' @example R/examples/provincias.R
#'
#' @return data.frame with the electoral results data at the polling station level.
#'
#' @importFrom stringr str_trim
#' @importFrom stringr str_remove_all
#' @importFrom dplyr relocate
#' @importFrom dplyr desc
#' @importFrom dplyr full_join
#' @importFrom dplyr left_join
#' @importFrom dplyr %>%
#'
#' @export
provincias <- function(tipo_eleccion, anno, mes) {
  ### Construyo la url al zip de la elecciones
  tipo <- election_type_code(tipo_eleccion)
  url <- generate_url(tipo, anno, mes, "TOTA")

  ### Descargo el fichero zip en un directorio temporal y lo descomprimo
  tempd <- tempdir(check = TRUE)
  filename <- gsub(".+/", "", url)
  temp <- file.path(tempd, filename)
  tempd <- file.path(tempd, gsub(".zip", "", filename))
  download_bin(url, temp)
  unzip(temp, overwrite = TRUE, exdir = tempd)


  ### Construyo las rutas a los ficheros DAT necesarios
  codigo_eleccion <- paste0(substr(anno, nchar(anno) - 1, nchar(anno)), mes)
  todos <- list.files(tempd, recursive = TRUE)
  x <- todos[todos == paste0("03", tipo, codigo_eleccion, ".DAT")]
  xbasicos <- todos[todos == paste0("07", tipo, codigo_eleccion, ".DAT")]
  xcandidaturas <- todos[todos == paste0("08", tipo, codigo_eleccion, ".DAT")]


  ### Leo los ficheros DAT necesarios
  dfcandidaturas_basicos <- read03(x, tempd)
  dfbasicos <- read07(xbasicos, tempd)
  dfcandidaturas <- read08(xcandidaturas, tempd)

  ### Junto los datos de los tres ficheros
  df <- full_join(dfcandidaturas_basicos, dfcandidaturas,
    by = c("tipo_eleccion", "anno", "mes", "codigo_partido")
  )
  df <- left_join(dfbasicos, df,
    by = c(
      "tipo_eleccion", "anno", "mes", "vuelta", "codigo_ccaa",
      "codigo_provincia", "codigo_distrito_electoral"
    )
  )



  ### Limpieza: Quito los espacios en blanco a los lados de estas variables
  df$siglas <- str_trim(df$siglas)
  df$denominacion <- str_trim(df$denominacion)
  df$denominacion <- str_remove_all(df$denominacion, '"')
  df$ambito_territorial <- str_trim(df$ambito_territorial)


  # Inserto el nombre del municipio más reciente y reordeno algunas variables
  df <- df %>%
    relocate(
      "codigo_ccaa",
      "codigo_provincia",
      "codigo_distrito_electoral",
      .after = "vuelta"
    ) %>%
    relocate(
      "codigo_partido_autonomia",
      "codigo_partido_provincia",
      "codigo_partido",
      "denominacion",
      "siglas",
      "votos",
      "diputados",
      "datos_oficiales",
      .after = "codigo_partido_nacional"
    ) %>%
    relocate(
      "n_diputados",
      .after = "poblacion_derecho"
    ) %>%
    arrange(
      "codigo_ccaa",
      "codigo_provincia",
      "codigo_distrito_electoral",
      desc("votos")
    )

  cleanup(tempd)

  return(df)
}
