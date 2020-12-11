#include "printf.h"
#include "Timer.h"
//java net.tinyos.tools.PrintfClient -comm serial@/dev/ttyUSB0:telosb
module TestPrintfC {
  uses {
    interface Boot;
    interface Timer<TMilli>;
    interface primeModule;
    interface LocalTime<TMilli>;
    interface RSAinterface as RSAint;
  }
}
implementation {
  uint32_t prime = 0;
  uint32_t encPrime = 0;
  uint32_t decPrime = 0;
  uint16_t i = 0;
  uint16_t j = 0;
  uint32_t time;
  uint32_t startTime;
  uint32_t startSegment;
  uint32_t finishTime;
  uint32_t avgTime;
  uint32_t minTime = 4000000000;
  uint32_t maxTime = 0;
  uint32_t rsaTime;
  uint32_t primeTime;
  uint32_t encTime;
  uint32_t decTime;
  //char testMsg = "a";
  //uint32_t* encMsg;
  //char* decMsg;

  event void Boot.booted() {
    call Timer.startPeriodic(2000);
    startTime = call LocalTime.get();
    call RSAint.gen_key();
    rsaTime = call LocalTime.get();
    rsaTime = rsaTime - startTime;
    call RSAint.rsa_test_key();	
    //prime = call primeModule.genLargePrime();
  }

  event void Timer.fired() {
    if(j > 10){
      if(i<100){
        time = call LocalTime.get();
        srand(time);
        startTime = call LocalTime.get();

        startSegment = call LocalTime.get();
        prime = call RSAint.rsa_gen_prime();
        primeTime = call LocalTime.get();
        primeTime = primeTime-startSegment; 

        startSegment = call LocalTime.get();
        encPrime = call RSAint.encrypt_shared_key(prime, 3, 3127);
        encTime = call LocalTime.get();
        encTime = encTime-startSegment;

        startSegment = call LocalTime.get();
        decPrime = call RSAint.decrypt_shared_key(encPrime);
        decTime = call LocalTime.get();
        decTime = decTime-startSegment;

        finishTime = call LocalTime.get();
        finishTime = finishTime - startTime;
        if(finishTime > maxTime){
          maxTime = finishTime;
        }
        if(finishTime < minTime){
          minTime = finishTime;
        }
        avgTime = avgTime + finishTime;
        printf("Prime: %ld, encPrime: %ld, decPrime: %ld\n",prime,encPrime,decPrime);
        printf("Generation time: %d\n",primeTime);
        printf("Encryption time: %d\n",encTime);
        printf("Decryption time: %d\n",decTime);
        printf("Total time: %d\n",finishTime);
        printfflush();
        i++;
      }
      else{
        printf("Test over. %d keys generated. Average generation time: %ld ms\n", i, avgTime/i);
        printf("min time: %ld, max time: %ld\n",minTime,maxTime);
        printfflush();
      }
    }else{
      printf("starting...\n");
      printfflush();
      j++;
    }
  }
}