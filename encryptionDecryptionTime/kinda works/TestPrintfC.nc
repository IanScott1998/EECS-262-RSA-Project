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
  uint16_t i = 0;
  uint16_t j = 0;
  uint32_t time;
  uint32_t startTime;
  uint32_t finishTime;
  uint32_t avgTime;
  uint32_t minTime = 4000000000;
  uint32_t maxTime = 0;

  event void Boot.booted() {
    call Timer.startPeriodic(1000);	
    //prime = call primeModule.genLargePrime();
  }

  event void Timer.fired() {
    if(j > 10){
      if(i<100){
        time = call LocalTime.get();
        srand(time);
        startTime = call LocalTime.get();
        //prime = call primeModule.genLargePrime();
        call RSAint.gen_key();
        //prime = call RSAint.gen
        finishTime = call LocalTime.get();
        finishTime = finishTime - startTime;
        if(finishTime > maxTime){
          maxTime = finishTime;
        }
        if(finishTime < minTime){
          minTime = finishTime;
        }
        avgTime = avgTime + finishTime;
        printf("Generated: %ld. Took %ld ms to generate\n", prime, finishTime);
        printfflush();
        i++;
      }
      else{
        printf("Test over. %d primes generated. Average generation time: %ld ms\n", i, avgTime/i);
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