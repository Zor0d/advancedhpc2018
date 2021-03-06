#include <stdio.h>
#include <include/labwork.h>
#include <cuda_runtime_api.h>
#include <omp.h>

#define ACTIVE_THREADS 4



int main(int argc, char **argv) {
    printf("USTH ICT Master 2018, Advanced Programming for HPC.\n");
    if (argc < 3) {
        printf("Usage: labwork <lwNum> <inputImage>\n");
        printf("   lwNum        labwork number\n");
        printf("   inputImage   the input file name, in JPEG format\n");
        return 0;
    }

    int lwNum = atoi(argv[1]);
    std::string inputFilename;
    std::string secondFilename;

    // pre-initialize CUDA to avoid incorrect profiling
    printf("Warming up...\n");
    char *temp;
    cudaMalloc(&temp, 1024);

    Labwork labwork;
    if (lwNum != 2 ) {
        inputFilename = std::string(argv[2]);
        labwork.loadInputImage(inputFilename);
    }
    if (lwNum == 6 ) {
        secondFilename = std::string(argv[3]);
        labwork.loadInputImage2(secondFilename);
    }
    
    


    printf("Starting labwork %d\n", lwNum);
    Timer timer;
    timer.start();
    switch (lwNum) {
        case 1:
            timer.start();
            labwork.labwork1_CPU();
            labwork.saveOutputImage("labwork2-cpu-out.jpg");
            printf("labwork 1 CPU ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
            timer.start();
            labwork.labwork1_OpenMP();
            labwork.saveOutputImage("labwork2-openmp-out.jpg");
            break;
        case 2:
            labwork.labwork2_GPU();
            break;
        case 3:
            labwork.labwork3_GPU();
            labwork.saveOutputImage("labwork3-gpu-out.jpg");
            break;
        case 4:
            labwork.labwork4_GPU();
            labwork.saveOutputImage("labwork4-gpu-out.jpg");
            break;
        case 5:
			timer.start();
            labwork.labwork5_CPU();
            printf("labwork 5 CPU ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
            labwork.saveOutputImage("labwork5-cpu-out.jpg");
            timer.start();
            labwork.labwork5_GPU();
            printf("labwork 5 GPU ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
            labwork.saveOutputImage("labwork5-gpu-out.jpg");
            break;
        case 6:
            labwork.labwork6_GPU();
            labwork.saveOutputImage("labwork6-gpu-out.jpg");
            break;
        case 7:
            labwork.labwork7_GPU();
            labwork.saveOutputImage("labwork7-gpu-out.jpg");
            break;
        case 8:
            labwork.labwork8_GPU();
            labwork.saveOutputImage("labwork8-gpu-out.jpg");
            break;
        case 9:
            labwork.labwork9_GPU();
            labwork.saveOutputImage("labwork9-gpu-out.jpg");
            break;
        case 10:
            labwork.labwork10_GPU();
            labwork.saveOutputImage("labwork10-gpu-out.jpg");
            break;
    }
    printf("labwork %d ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
}

void Labwork::loadInputImage(std::string inputFileName) {
    inputImage = jpegLoader.load(inputFileName);
    secondImage = jpegLoader.load(inputFileName);
}

void Labwork::loadInputImage2(std::string inputFileName) {
    secondImage = jpegLoader.load(inputFileName);
}

void Labwork::saveOutputImage(std::string outputFileName) {
    jpegLoader.save(outputFileName, outputImage, inputImage->width, inputImage->height, 90);
}

void Labwork::labwork1_CPU() {
    int pixelCount = inputImage->width * inputImage->height;
    outputImage = static_cast<char *>(malloc(pixelCount * 3));
    for (int j = 0; j < 100; j++) {		// let's do it 100 times, otherwise it's too fast!
        for (int i = 0; i < pixelCount; i++) {
            outputImage[i * 3] = (char) (((int) inputImage->buffer[i * 3] + (int) inputImage->buffer[i * 3 + 1] +
                                          (int) inputImage->buffer[i * 3 + 2]) / 3);
            outputImage[i * 3 + 1] = outputImage[i * 3];
            outputImage[i * 3 + 2] = outputImage[i * 3];
        }
    }
}

void Labwork::labwork1_OpenMP() {
    int pixelCount = inputImage->width * inputImage->height;
    outputImage = static_cast<char *>(malloc(pixelCount * 3));
    #pragma omp parallel for 
    for (int j = 0; j < 100; j++) {		// let's do it 100 times, otherwise it's too fast!
        for (int i = 0; i < pixelCount; i++) {
            outputImage[i * 3] = (char) (((int) inputImage->buffer[i * 3] + (int) inputImage->buffer[i * 3 + 1] +
                                          (int) inputImage->buffer[i * 3 + 2]) / 3);
            outputImage[i * 3 + 1] = outputImage[i * 3];
            outputImage[i * 3 + 2] = outputImage[i * 3];
        }
    }

}

int getSPcores(cudaDeviceProp devProp) {
    int cores = 0;
    int mp = devProp.multiProcessorCount;
    switch (devProp.major) {
        case 2: // Fermi
            if (devProp.minor == 1) cores = mp * 48;
            else cores = mp * 32;
            break;
        case 3: // Kepler
            cores = mp * 192;
            break;
        case 5: // Maxwell
            cores = mp * 128;
            break;
        case 6: // Pascal
            if (devProp.minor == 1) cores = mp * 128;
            else if (devProp.minor == 0) cores = mp * 64;
            else printf("Unknown device type\n");
            break;
        default:
            printf("Unknown device type\n");
            break;
    }
    return cores;
}

void Labwork::labwork2_GPU() {
   int numberOfDev = 0;
   cudaGetDeviceCount(&numberOfDev);
   printf("Number of Devices : %d\n", numberOfDev); 
   for (int i = 0; i< numberOfDev; i++){
	  cudaDeviceProp prop;
  	  cudaGetDeviceProperties(&prop, i);
	  printf(" Device num : %d\n", i);
   	  printf("    Name of device : %s\n", prop.name); 
   	  printf("    Clock rate : %d\n", prop.clockRate);
	  int nbCores = getSPcores(prop);
	  printf("    Number of cores : %d\n", nbCores);
   	  printf("    Number of multprocessor : %d\n", prop.multiProcessorCount);
   }
}

__global__ void grayscale(uchar3 *input, uchar3 *output) {
	int tid = threadIdx.x + blockIdx.x * blockDim.x;
	output[tid].x = (input[tid].x + input[tid].y + input[tid].z) / 3;
	output[tid].z = output[tid].y = output[tid].x;
}

void Labwork::labwork3_GPU() {
	// copy image from host memory to device memory
	int pixelCount = inputImage->width * inputImage->height;
	uchar3 *devInput;
	uchar3 *devGray;
    outputImage = static_cast<char *>(malloc(pixelCount * 3));
	cudaMalloc(&devInput, pixelCount * sizeof(uchar3));
	cudaMalloc(&devGray, pixelCount * sizeof(uchar3));
	cudaMemcpy(devInput, inputImage->buffer,pixelCount * sizeof(uchar3),cudaMemcpyHostToDevice);
	// execute the grayscale transformation on device
	int dimBlock = 1024;
	int dimGrid = pixelCount / dimBlock;
	grayscale<<<dimGrid, dimBlock>>>(devInput, devGray);
	// copy result from device to host
	cudaMemcpy(outputImage, devGray,pixelCount * sizeof(uchar3),cudaMemcpyDeviceToHost);
	// free memory
	cudaFree(devInput);
	cudaFree(devGray);
}

__global__ void grayscale2D(uchar3 *input, uchar3 *output, int width, int height) {
	int tid_x = threadIdx.x + blockIdx.x * blockDim.x;
	if (tid_x >= width) return; 
	int tid_y = threadIdx.y + blockIdx.y * blockDim.y;
	if (tid_y >= height) return; 
	int id = tid_x+tid_y*width;
	output[id].x = (input[id].x + input[id].y + input[id].z) / 3;
	output[id].z = output[id].y = output[id].x;
}
void Labwork::labwork4_GPU() {
    // copy image from host memory to device memory
	int pixelCount = inputImage->width * inputImage->height;
	uchar3 *devInput;
	uchar3 *devGray;
    outputImage = static_cast<char *>(malloc(pixelCount * 3));
	cudaMalloc(&devInput, pixelCount * sizeof(uchar3));
	cudaMalloc(&devGray, pixelCount * sizeof(uchar3));
	cudaMemcpy(devInput, inputImage->buffer,pixelCount * sizeof(uchar3),cudaMemcpyHostToDevice);
	// execute the grayscale transformation on device
	int blockSize_1D = 32;
	dim3 gridSize = dim3((inputImage->width + blockSize_1D-1) / blockSize_1D, (inputImage->height + blockSize_1D-1) / blockSize_1D);
	dim3 blockSize = dim3(blockSize_1D, blockSize_1D);
	grayscale2D<<<gridSize, blockSize>>>(devInput, devGray, inputImage->width, inputImage->height);
	// copy result from device to host
	cudaMemcpy(outputImage, devGray,pixelCount * sizeof(uchar3),cudaMemcpyDeviceToHost);
	// free memory
	cudaFree(devInput);
	cudaFree(devGray);
}

// CPU implementation of Gaussian Blur
void Labwork::labwork5_CPU() {
    int kernel[] = { 0, 0, 1, 2, 1, 0, 0,  
                     0, 3, 13, 22, 13, 3, 0,  
                     1, 13, 59, 97, 59, 13, 1,  
                     2, 22, 97, 159, 97, 22, 2,  
                     1, 13, 59, 97, 59, 13, 1,  
                     0, 3, 13, 22, 13, 3, 0,
                     0, 0, 1, 2, 1, 0, 0 };
    int pixelCount = inputImage->width * inputImage->height;
    outputImage = (char*) malloc(pixelCount * sizeof(char) * 3);
    for (int row = 0; row < inputImage->height; row++) {
        for (int col = 0; col < inputImage->width; col++) {
            int sum = 0;
            int c = 0;
            for (int y = -3; y <= 3; y++) {
                for (int x = -3; x <= 3; x++) {
                    int i = col + x;
                    int j = row + y;
                    if (i < 0) continue;
                    if (i >= inputImage->width) continue;
                    if (j < 0) continue;
                    if (j >= inputImage->height) continue;
                    int tid = j * inputImage->width + i;
                    unsigned char gray = (inputImage->buffer[tid * 3] + inputImage->buffer[tid * 3 + 1] + inputImage->buffer[tid * 3 + 2])/3;
                    int coefficient = kernel[(y+3) * 7 + x + 3];
                    sum = sum + gray * coefficient;
                    c += coefficient;
                }
            }
            sum /= c;
            int posOut = row * inputImage->width + col;
            outputImage[posOut * 3] = outputImage[posOut * 3 + 1] = outputImage[posOut * 3 + 2] = sum;
        }
    }
}

__global__ void blur(uchar3 *input, uchar3 *output, int width, int height, int *kernel) {
	int tid_x = threadIdx.x + blockIdx.x * blockDim.x;
	if (tid_x >= width) return; 
	int tid_y = threadIdx.y + blockIdx.y * blockDim.y;
	if (tid_y >= height) return; 
	int sum = 0;
	int c = 0;
	for (int y = -3; y <= 3; y++) {
		for (int x = -3; x <= 3; x++) {
			int i = tid_x + x;
			int j = tid_y + y;
			if (i < 0) return;
			if (i >= width) return;
			if (j < 0) return;
			if (j >= height) return;
			int tid = j * width + i;
			int coefficient = kernel[(y+3)*7+x+3];
			//printf(" coefficient : %d\n", coefficient); 
			unsigned char gray = (input[tid].x + input[tid].y + input[tid].z)/3;
			sum = sum + gray * coefficient;
			c += coefficient;
		}
	}
	sum /= c;
	int id = tid_x + width * tid_y;
	output[id].z = output[id].y = output[id].x = sum;
	//printf("nombre de pixels traité : %d\n", nbPixel);
}


__global__ void blurShared(uchar3 *input, uchar3 *output, int width, int height, int *kernel) {
	int tid_x = threadIdx.x + blockIdx.x * blockDim.x;
	if (tid_x >= width) return; 
	int tid_y = threadIdx.y + blockIdx.y * blockDim.y;
	if (tid_y >= height) return; 
	
	int localtid = threadIdx.x + threadIdx.y * blockDim.x;
	__shared__ int tile[49];
	if (localtid<49){
		tile[localtid] = kernel[localtid];
	}

	__syncthreads();
		
	int sum = 0;
	int c = 0;
	for (int y = -3; y <= 3; y++) {
		for (int x = -3; x <= 3; x++) {
			int i = tid_x + x;
			int j = tid_y + y;
			if (i < 0) return;
			if (i >= width) return;
			if (j < 0) return;
			if (j >= height) return;
			int tid = j * width + i;
			int coefficient = tile[(y+3)*7+x+3];
			unsigned char gray = (input[tid].x + input[tid].y + input[tid].z)/3;
			sum = sum + gray * coefficient;
			c += coefficient;
		}
	}
	sum /= c;
	int id = tid_x + width * tid_y;
	output[id].z = output[id].y = output[id].x = sum;
}


void Labwork::labwork5_GPU() {
	int kernel[] = { 0, 0, 1, 2, 1, 0, 0,  
                     0, 3, 13, 22, 13, 3, 0,  
                     1, 13, 59, 97, 59, 13, 1,  
                     2, 22, 97, 159, 97, 22, 2,  
                     1, 13, 59, 97, 59, 13, 1,  
                     0, 3, 13, 22, 13, 3, 0,
                     0, 0, 1, 2, 1, 0, 0 };
	// copy image from host memory to device memory
	int pixelCount = inputImage->width * inputImage->height;
	uchar3 *devInput;
	uchar3 *devGray;
	int *devKernel;
    outputImage = static_cast<char *>(malloc(pixelCount * 3));
	cudaMalloc(&devInput, pixelCount * sizeof(uchar3));
	cudaMalloc(&devGray, pixelCount * sizeof(uchar3));
	cudaMalloc(&devKernel, 49*4);
	cudaMemcpy(devInput, inputImage->buffer,pixelCount * sizeof(uchar3),cudaMemcpyHostToDevice);
	cudaMemcpy(devKernel, kernel, 49*4,cudaMemcpyHostToDevice);
	// execute the grayscale transformation on device
	int blockSize_1D = 32;
	dim3 gridSize = dim3((inputImage->width + blockSize_1D-1) / blockSize_1D, (inputImage->height + blockSize_1D-1) / blockSize_1D);
	dim3 blockSize = dim3(blockSize_1D, blockSize_1D);
	blurShared<<<gridSize, blockSize>>>(devInput, devGray, inputImage->width, inputImage->height, devKernel);
	// copy result from device to host
	cudaMemcpy(outputImage, devGray,pixelCount * sizeof(uchar3),cudaMemcpyDeviceToHost);
	// free memory
	cudaFree(devInput);
	cudaFree(devGray);
}

__global__ void grayscaleBinarization(uchar3 *input, uchar3 *output, int width, int height, int cutValue) {
	int tid_x = threadIdx.x + blockIdx.x * blockDim.x;
	if (tid_x >= width) return; 
	int tid_y = threadIdx.y + blockIdx.y * blockDim.y;
	if (tid_y >= height) return; 
	int id = tid_x+tid_y*width;
	int value = (input[id].x + input[id].y + input[id].z) / 3;
	output[id].z = output[id].y = output[id].x = (value/cutValue)*255;
}

__global__ void grayscaleBrightControl(uchar3 *input, uchar3 *output, int width, int height, int brightValue) {
	int tid_x = threadIdx.x + blockIdx.x * blockDim.x;
	if (tid_x >= width) return; 
	int tid_y = threadIdx.y + blockIdx.y * blockDim.y;
	if (tid_y >= height) return; 
	int id = tid_x+tid_y*width;
	output[id].x = min(255,max(0,input[id].x+brightValue));
	output[id].y = min(255,max(0,input[id].y+brightValue));
	output[id].z = min(255,max(0,input[id].z+brightValue));
}

__global__ void blend(uchar3 *input, uchar3 *output, int width, int height, int coeff, uchar3 *secondInput) {
	int tid_x = threadIdx.x + blockIdx.x * blockDim.x;
	if (tid_x >= width) return; 
	int tid_y = threadIdx.y + blockIdx.y * blockDim.y;
	if (tid_y >= height) return; 
	int id = tid_x+tid_y*width;
	output[id].x = input[id].x * coeff + secondInput[id].x * (1-coeff);
	output[id].y = input[id].y * coeff + secondInput[id].y * (1-coeff);
	output[id].z = input[id].z * coeff + secondInput[id].z * (1-coeff);
	
}

void Labwork::labwork6_GPU() {
	// copy image from host memory to device memory
	int pixelCount = inputImage->width * inputImage->height;
	uchar3 *devInput;
	uchar3 *devGray;
    outputImage = static_cast<char *>(malloc(pixelCount * 3));
	cudaMalloc(&devInput, pixelCount * sizeof(uchar3));
	cudaMalloc(&devGray, pixelCount * sizeof(uchar3));
	cudaMemcpy(devInput, inputImage->buffer,pixelCount * sizeof(uchar3),cudaMemcpyHostToDevice);
	// execute the grayscale transformation on device
	int blockSize_1D = 32;
	dim3 gridSize = dim3((inputImage->width + blockSize_1D-1) / blockSize_1D, (inputImage->height + blockSize_1D-1) / blockSize_1D);
	dim3 blockSize = dim3(blockSize_1D, blockSize_1D);
	int choice;
	printf("Veuillez choisir l'opération souhaitée :\n");
	printf("1) binarization \n");
	printf("2) brightness increase\n");
	printf("3) bleanding images \n");
	scanf("%d",&choice);
	if (choice==1){
		int cutValue;
		printf("Veuillez indiquer un seuil : ");
		scanf("%d", &cutValue);
		grayscaleBinarization<<<gridSize, blockSize>>>(devInput, devGray, inputImage->width, inputImage->height, cutValue);
	}else if (choice==2){
		int brightValue;
		printf("Veuillez indiquer l'intensité à ajouter (peut être négative) : ");
		scanf("%d", &brightValue);
		grayscaleBrightControl<<<gridSize, blockSize>>>(devInput, devGray, inputImage->width, inputImage->height, brightValue);	
	}else if (choice==3){
		std::string fileName;
		int coeff;
		uchar3 *devSecondImage;
		//printf("Veuillez indiquer le nom de la seconde image : ");
		//scanf("%s", &fileName);
		//printf("jpegloader created \n");
		//secondImage = jpegLoader.load(fileName);
		printf("load done \n");
		cudaMalloc(&devSecondImage, pixelCount * sizeof(uchar3));
		cudaMemcpy(devSecondImage, secondImage->buffer,pixelCount * sizeof(uchar3),cudaMemcpyHostToDevice);
		printf("Veuillez indiquer le coefficient choisie :");
		scanf("%s", &coeff);
		//blend<<<gridSize, blockSize>>>(devInput, devGray, inputImage->width, inputImage->height, coeff, devSecondImage);
	}else{
		
	}
	// copy result from device to host
	cudaMemcpy(outputImage, devGray,pixelCount * sizeof(uchar3),cudaMemcpyDeviceToHost);
	// free memory
	cudaFree(devInput);
	cudaFree(devGray);
}

void Labwork::labwork7_GPU() {

}

void Labwork::labwork8_GPU() {

}

void Labwork::labwork9_GPU() {

}

void Labwork::labwork10_GPU() {

}
