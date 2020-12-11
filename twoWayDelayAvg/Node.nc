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
   uint8_t delay = 0;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   event void Boot.booted(){
      call AMControl.start();
      call Timer.startPeriodic(1000);

      //dbg(GENERAL_CHANNEL, "Booted\n");
   }

   event void Timer.fired(){
      //printf("TOS_NODE_ID: %d\n", TOS_NODE_ID);
      //printf("recieved packs: %d\n", receivedPacks);
      if(TOS_NODE_ID == 1){
         if(delay > 10){
            if(receivedPacks <= 100){
               loops++;
               if(receivedPacks > 0){
                  printf("pack %d took %d ms to be ACKed...\n", receivedPacks, zaWarudo);
                  printfflush();
               }
               startTime = call LocalTime.get();
               makePack(&sendPackage, TOS_NODE_ID, 2, 10, PROTOCOL_REQKEY, 1, msgPayload, PACKET_MAX_PAYLOAD_SIZE);
               //makePack(&sendPackage, TOS_NODE_ID, destination, 0, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
               call Sender.send(sendPackage, AM_BROADCAST_ADDR);
            }
            else{
            printf("Test over. %d retransmissions needed. Average two way delay was: %ld...\n", loops-receivedPacks, avgTime/receivedPacks);
            printfflush();
            }
         }else{
            printf("startup...\n");
            printfflush();
            delay++;
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
            receivedPacks++;
            makePack(&sendPackage, TOS_NODE_ID, 1, 10, PROTOCOL_RECKEY, 1, msgPayload, PACKET_MAX_PAYLOAD_SIZE);
            call Sender.send(sendPackage, AM_BROADCAST_ADDR);
         }
         if(myMsg->protocol == PROTOCOL_RECKEY){
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
