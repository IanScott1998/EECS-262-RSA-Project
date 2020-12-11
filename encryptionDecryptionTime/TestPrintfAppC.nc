#define NEW_PRINTF_SEMANTICS
#include "printf.h"

configuration TestPrintfAppC{
}
implementation {
  components MainC, TestPrintfC;
  components new TimerMilliC(), LocalTimeMilliC;
  components PrintfC;
  components SerialStartC;
  components primeC;
  components RSAC as RSAint;

  TestPrintfC.Boot -> MainC;
  TestPrintfC.Timer -> TimerMilliC;
  TestPrintfC.LocalTime -> LocalTimeMilliC;
  TestPrintfC.primeModule -> primeC;
  TestPrintfC.RSAint -> RSAint;
}