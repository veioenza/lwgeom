#' Transform or convert coordinates of simple features directly with Proj.4 (bypassing GDAL)
#'
#' Transform or convert coordinates of simple features directly with Proj.4 (bypassing GDAL)
#'
#' @param x object of class sf, sfc or sfg
#' @param crs either an object of class \code{crs}, or input to \link[sf]{st_crs} (proj4string, or EPSG code), or a length 2 character vector with input proj4string and output proj4string
#' @param ... ignored
#' @details Transforms coordinates of object to new projection, using Proj.4 directly rather than the GDAL API used by \link[sf]{st_transform}.
#' 
#' If \code{crs} is a single CRS, it forms the target CRS, and in that case the source CRS is obtained as \code{st_crs(x)}. Since this presumes that the source CRS is accepted by GDAL (which is not always the case), a second option is to specify the source and target CRS as two proj4strings in argument \code{crs}. In the latter case, \code{st_crs(x)} is ignored and may well be \code{NA}.
#' @examples
#' library(sf)
#' p1 = st_point(c(7,52))
#' p2 = st_point(c(-30,20))
#' sfc = st_sfc(p1, p2, crs = 4326)
#' sfc
#' st_transform_proj(sfc, "+proj=wintri")
#' @export
st_transform_proj = function(x, crs, ...) UseMethod("st_transform_proj")

#' @name st_transform_proj
#' @export
st_transform_proj.sfc = function(x, crs, ...) {
	if (is.numeric(crs))
		crs = st_crs(crs)$proj4string
	if (inherits(crs, "crs"))
		crs = crs$proj4string
	stopifnot(length(crs) %in% c(1,2))
	if (length(crs) == 1) # only output
		crs = c(st_crs(x)$proj4string, crs) # c(input, output)
	st_sfc(CPL_lwgeom_transform(x, crs))
}

#' @name st_transform_proj
#' @export
#' @examples
#' library(sf)
#' nc = st_read(system.file("shape/nc.shp", package="sf"))
#' st_transform_proj(nc[1,], "+proj=wintri +over")
st_transform_proj.sf = function(x, crs, ...) {
	x[[ attr(x, "sf_column") ]] = st_transform_proj(st_geometry(x), crs, ...)
	x
}

#' @name st_transform_proj
#' @export
#' @details The \code{st_transform_proj} method for \code{sfg} objects assumes that the CRS of the object is available as an attribute of that name.
#' @examples
#' st_transform_proj(structure(p1, proj4string = "+init=epsg:4326"), "+init=epsg:3857")
st_transform_proj.sfg = function(x, crs, ...) {
	if (missing(crs))
		stop("argument crs cannot be missing") # nocov
	if (length(crs) == 1) {
		if (is.null(attr(x, "proj4string")))
			stop("x does not have a proj4string attribute") # nocov
		if (!is.character(attr(x, "proj4string")))
			stop("proj4string attribute should be a character string") # nocov
		crs = c(attr(x, "proj4string"), crs)
	}
	structure(st_transform_proj(st_sfc(x), crs, ...)[[1]], proj4string = tail(crs, 1))
}
