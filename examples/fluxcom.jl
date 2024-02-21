using YAXArrays, Zarr, DimensionalData

ds = open_dataset("https://swift.dkrz.de/v1/dkrz_a1e106384d7946408b9724b59858a536/fluxcom-x/FLUXCOMxBase/NEE")

ds_nee = ds["NEE"]