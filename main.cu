#include "gdal.h"
#include "gdal_utils.h"
#include "cpl_conv.h"



// image resampling
__global__ void bicubicInterpolation(float * data, float * output, int width, int height, int outputw, int outputh){

}
// image resampling
__global__ void bilinearInterpolation(float * data, float * output, int width, int height, int outputw, int outputh){

}

// image resampling
__global__ void nearestNeighborInterpolation(float * data, float * output, int width, int height, int outputw, int outputh){

}

//convolution gaussian blur
__global__ void gaussianBlur(float * data, float * output, int width, int height){

}

//Convolution Sharpen
__global__ void sharpen(float * data, float * output, int width, int height){}

// Convolution https://en.wikipedia.org/wiki/Difference_of_Gaussians, Use shared memory here
__global__ void laplacianOfGaussian(float * data, float * output, int width, int height){
    
}

__global__ void ndvi(uint16_t* red, uint16_t* nir, float* output, int width, int height) {
    int tid = blockIdx.x * blockDim.x + threadIdx.x;

    if (tid < width * height) {

        int denom = nir[tid] + red[tid];
        if (denom == 0 || nir[tid] == 0|| red[tid] == 0)
        {
            output[tid] = nanf("");
        }else{
            output[tid] = float (nir[tid] - red[tid])/ float (nir[tid] + red[tid]);

        }
        
        
    }
}

void cpuCalc(uint16_t* red, uint16_t* nir, float* output, int width, int height){

    for (int tid = 0; tid < width * height; tid++)
    {
        int denom = nir[tid] + red[tid];
        if (denom == 0 || nir[tid] == 0|| red[tid] == 0)
        {
            output[tid] = nanf("");
        }else{
            output[tid] = float (nir[tid] - red[tid])/ float (nir[tid] + red[tid]);

        }
    }
    
}



uint16_t* loadBand(const char* fileName, int width, int height) {
    GDALAllRegister();

    GDALDatasetH dataset = GDALOpen(fileName, GA_ReadOnly);
    GDALRasterBandH band = GDALGetRasterBand(dataset, 1);

    uint16_t* data = (uint16_t*)malloc(width * height * sizeof(uint16_t));
    GDALRasterIO(band, GF_Read, 0, 0, width, height, data, width, height, GDT_UInt16, 0, 0);

    GDALClose(dataset);
    return data;
}




void ndviImageCUDA(const char* rName, const char* nName,  const char* outputFileName)
{

    GDALAllRegister();
    GDALDatasetH dataSetInfo = GDALOpen(rName, GA_ReadOnly);
    int width = GDALGetRasterXSize(dataSetInfo);
    int height = GDALGetRasterYSize(dataSetInfo);



    uint16_t* redBand = loadBand(rName, width, height);
    uint16_t* nirBand = loadBand(nName, width, height);


    float* output = (float*)malloc(width * height * sizeof(float));


    uint16_t* d_redBand;

    uint16_t* d_nirBand;

    int bs = 256;
    int gs = (width * height + bs - 1) / bs;

    float * d_output;
    cudaMalloc((void**)&d_redBand, width * height * sizeof(uint16_t));
    cudaMalloc((void**)&d_nirBand, width * height * sizeof(uint16_t));

    cudaMalloc((void**)&d_output, width * height * sizeof(float));


    cudaMemcpy(d_redBand, redBand, width * height * sizeof(uint16_t), cudaMemcpyHostToDevice);
    cudaMemcpy(d_nirBand, nirBand, width * height * sizeof(uint16_t), cudaMemcpyHostToDevice);

    

    ndvi<<<gs, bs>>>(d_redBand, d_nirBand, d_output, width, height);


    cudaMemcpy(output, d_output, width * height * sizeof(float), cudaMemcpyDeviceToHost);

    printf("NDVI CALC OK \n");

    free(redBand);
    free(nirBand);
    cudaFree(d_redBand);
    cudaFree(d_nirBand);
    cudaFree(d_output);
    // Create a TIFF dataset to save the image

    GDALDriverH driver = GDALGetDriverByName("GTiff");
    GDALDatasetH tiffDataset = GDALCreate(driver, outputFileName, width, height, 1, GDT_Float32, NULL);

    
    double adfGeoTransform[6];
    GDALGetGeoTransform(dataSetInfo, adfGeoTransform);
    const char* spatialRef = GDALGetProjectionRef(dataSetInfo);
    GDALSetGeoTransform(tiffDataset, adfGeoTransform);
    GDALSetProjection(tiffDataset, spatialRef);
    GDALRasterBandH outBand = GDALGetRasterBand(tiffDataset, 1);
    GDALRasterIO(outBand, GF_Write, 0, 0, width, height, output, width, height, GDT_Float32, 0, 0);


    GDALClose(tiffDataset);
    GDALClose(dataSetInfo);


    free(output);


}




int main(int argc, char const *argv[])
{
    const char* redFile = "B02.tif";

    const char* nirFile = "B08.tif";


    ndviImageCUDA(redFile, nirFile, "ndvitest.tiff");

    return 0;
}
