/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"

#include "printf.h"

#include "RSA.h"

//java net.tinyos.tools.PrintfClient -comm serial@/dev/ttyUSB0:telosb

module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface SimpleSend as Sender;

   uses interface CommandHandler;

   uses{
      interface Timer<TMilli>;
      interface LocalTime<TMilli>;
   }

   uses interface RSAinterface as RSAint;
}

implementation{
   pack sendPackage;
   uint8_t* msgPayload = 1;
   uint8_t receivedPacks = 0;
   uint32_t startTime;
   uint32_t zaWarudo;
   //uint32_t totTime;
   uint32_t avgTime = 0;
   uint8_t loops = 0;
   //int32_t priv;
   uint32_t pub;
   uint32_t modulus;
   uint8_t payloadArr[PACKET_MAX_PAYLOAD_SIZE];
   uint32_t sharedKey;
   //int8_t* p;
   //int8_t* q;

   int32_t recievedInt, recievedInt2;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   void loadPayload(){
      uint32_t var1 = call RSAint.get_modulus();//2000000000
      uint32_t var2 = call RSAint.get_exponent();//1000000000
      uint32_t tp, p1, p2, p3;
      uint8_t temp[4] = {var1&255, (var1>>8)&255, (var1>>16)&255, (var1>>24)&255};
      uint8_t temp2[4] = {var2&255, (var2>>8)&255, (var2>>16)&255, (var2>>24)&255};
      payloadArr[0] = temp[0];
      payloadArr[1] = temp[1];
      payloadArr[2] = temp[2];
      payloadArr[3] = temp[3];
      //temp[4] = 
      payloadArr[4] = temp2[0];
      payloadArr[5] = temp2[1];
      payloadArr[6] = temp2[2];
      payloadArr[7] = temp2[3];
      /*
      printf("arr[0]: %d, arr[1]: %d, arr[2]: %d, arr[3]: %d \n", payloadArr[0], payloadArr[1], payloadArr[2], payloadArr[3]);
      printfflush();

      tp = payloadArr[0];
      p1 = payloadArr[1];
      p2 = payloadArr[2];
      p3 = payloadArr[3];

      p1 = (p1 << 8);
      p2 = (p2 << 16);
      p3 = (p3 << 24);

      printf("temp: %ld, temp1: %ld, temp2: %ld, temp3: %ld\n", tp, p1, p2, p3);
      printfflush();

      var2 = tp + p1 + p2 + p3;

      printf("output is: %ld \n", var2);
      printfflush();
      */
      return;
   }

   event void Boot.booted(){
      call AMControl.start();
      call Timer.startPeriodic(2000);
      
      if(TOS_NODE_ID == 1){
         call RSAint.rsa_test_key();
         modulus = call RSAint.get_modulus();
         pub = call RSAint.get_exponent();
      }
      //priv = call RSAint.get_private();
      //dbg(GENERAL_CHANNEL, "Booted\n");
   }

   event void Timer.fired(){
      //printf("TOS_NODE_ID: %d\n", TOS_NODE_ID);
      //printf("recieved packs: %d\n", receivedPacks);
      if(TOS_NODE_ID == 1){
         
         uint8_t i =0;
         uint8_t j =0;
         if(receivedPacks <= 100){
            loops++;
            if(receivedPacks > 0){
               printf("pack %d took %ld ms to be ACKed...\n", receivedPacks, zaWarudo);
               printfflush();
            }
            
            //if(receivedPacks < 5){
            //   printf("pub key: %ld, priv key: %ld, modulus: %ld\n");
            //   printfflush();
            //}
            
            startTime = call LocalTime.get();
            loadPayload();
            
            /*
            p = (uint8_t*)&modulus;
            q = (uint8_t*)&pub;
            for(i = 0; i<8; i++){
               if(i<4){
                  payloadArr[i] = p[i]; 
               }else{
                  payloadArr[i] = q[j];
                  j++;
               }
               printf("payloadArr[%d] = %d ", i, payloadArr[i]);
            }
            printf("\n");
            printfflush();
            */
            makePack(&sendPackage, TOS_NODE_ID, 2, 10, PROTOCOL_REQKEY, 1, payloadArr, PACKET_MAX_PAYLOAD_SIZE);
            //makePack(&sendPackage, TOS_NODE_ID, destination, 0, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
            call Sender.send(sendPackage, AM_BROADCAST_ADDR);
         }
         else{
         printf("Test over. %d retransmissions needed. Average two way delay was: %ld...\n", loops-receivedPacks, avgTime/receivedPacks);
         printfflush();
         }
      }
      
      if(TOS_NODE_ID == 2){
         if(receivedPacks > 0){
            printf("Recieved Int: %ld, recieved Int2: %ld\n", recievedInt, recievedInt2);
            printfflush();
            //printf("recieved key. Modulus: %lu, Exponent: %lu\n",modulus,pub);
         }
      }
   }

   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         //dbg(GENERAL_CHANNEL, "Radio On\n");
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err){}

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      //dbg(GENERAL_CHANNEL, "Packet Received\n");
      //receivedPacks++;
      if(len==sizeof(pack)){
         pack* myMsg=(pack*) payload;
         if(myMsg->protocol == PROTOCOL_REQKEY){
            //int32_t* modulusptr;
            //int32_t* exponentptr;
            uint32_t tp, p1, p2, p3;
            //uint32_t sharedKey;
            int8_t i;

            //printf("payload[0]: %d, payload[1]: %d, payload[2]: %d, payload[3]:%d\n", myMsg->payload[0], myMsg->payload[1], myMsg->payload[2], myMsg->payload[3]);
            tp = myMsg->payload[0];
            p1 = myMsg->payload[1];
            p2 = myMsg->payload[2];
            p3 = myMsg->payload[3];

            p1 = (p1 << 8);
            p2 = (p2 << 16);
            p3 = (p3 << 24);

            recievedInt = tp+p1+p2+p3;

            tp = myMsg->payload[4];
            p1 = myMsg->payload[5];
            p2 = myMsg->payload[6];
            p3 = myMsg->payload[7];

            p1 = (p1 << 8);
            p2 = (p2 << 16);
            p3 = (p3 << 24);

            recievedInt2 = tp+p1+p2+p3;

            sharedKey = call RSAint.rsa_gen_prime();
            printf("shared key = %ld\n", sharedKey);
            printfflush();
            //sharedKey = 1249;
            sharedKey = call RSAint.encrypt_shared_key(sharedKey, recievedInt2, recievedInt);

            if(sharedKey != NULL){
               uint8_t temp[4] = {sharedKey&255, (sharedKey>>8)&255, (sharedKey>>16)&255, (sharedKey>>24)&255};
               payloadArr[0] = temp[0];
               payloadArr[1] = temp[1];
               payloadArr[2] = temp[2];
               payloadArr[3] = temp[3];
            }

            //modulusptr = (int32_t*)&myMsg->payload[0];
            //exponentptr = (int32_t*)&myMsg->payload[4];

            //pub = *exponentptr;
            //modulus = *modulusptr;
            receivedPacks++;

            makePack(&sendPackage, TOS_NODE_ID, 1, 10, PROTOCOL_RECKEY, 1, payloadArr, PACKET_MAX_PAYLOAD_SIZE);
            call Sender.send(sendPackage, AM_BROADCAST_ADDR);
         }
         if(myMsg->protocol == PROTOCOL_RECKEY){
            uint32_t tp, p1, p2, p3;

            tp = myMsg->payload[0];
            p1 = myMsg->payload[1];
            p2 = myMsg->payload[2];
            p3 = myMsg->payload[3];

            p1 = (p1 << 8);
            p2 = (p2 << 16);
            p3 = (p3 << 24);

            sharedKey = tp+p1+p2+p3;
            sharedKey = call RSAint.decrypt_shared_key(sharedKey);

            printf("Shared key = %ld\n",sharedKey);

            zaWarudo = call LocalTime.get();
            zaWarudo = zaWarudo - startTime;
            avgTime = avgTime + zaWarudo;
            receivedPacks++;
         }
         //dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
         return msg;
      }
      //dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }


   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      //dbg(GENERAL_CHANNEL, "PING EVENT \n");
      makePack(&sendPackage, TOS_NODE_ID, destination, 0, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Sender.send(sendPackage, destination);
   }

   event void CommandHandler.printNeighbors(){}

   event void CommandHandler.printRouteTable(){}

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
}
