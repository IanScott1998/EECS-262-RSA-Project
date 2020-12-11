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

#include "RSA.h"

module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface SimpleSend as Sender;

   uses interface CommandHandler;

   uses interface RSAinterface as RSAint;
}

implementation{
   pack sendPackage;
   uint16_t currentSeq = 0;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   event void Boot.booted(){

      //########RSA STUFF#########
      bool testRSA = 0;
      int i;
      char rsaMessage[] = "abc123";
      char* decryptedMessage;
      uint64_t* encryptedMessage;
      uint16_t randVal = 5;
      //randVal += 2*TOS_NODE_ID;
      //srand(time(NULL));
      srand(randVal);
      testRSA = call RSAint.RSAtest();
      dbg(GENERAL_CHANNEL, "RSA connected = %d \n", testRSA);
      call RSAint.gen_key();
      //########################

      call AMControl.start();
      dbg(GENERAL_CHANNEL, "Booted\n");

      //if(TOS_NODE_ID == 1){
         //signal CommandHandler.keyReq(2);
         //dbg(GENERAL_CHANNEL, "sent request \n");
      //}
   }

   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err){}

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      dbg(GENERAL_CHANNEL, "Packet Received\n");
      if(len==sizeof(pack)){
         pack* myMsg=(pack*) payload;
         if(myMsg->protocol == PROTOCOL_KEY_REQUEST){
           int64_t* modulusptr;
           int64_t* exponentptr;
           uint64_t sharedKey;
           int64_t exponent, modulus;
           int8_t i;
           //nodeInfo temp;
           uint8_t payloadArr[PACKET_MAX_PAYLOAD_SIZE];
           uint8_t* p;

           dbg(GENERAL_CHANNEL, "Node %d recieved encryption key request from node %d...\n", TOS_NODE_ID, myMsg->src);
           //unload the public key from the message payload

           for(i=0; i<16; i++){
             dbg(GENERAL_CHANNEL, "payload[%d] = %d\n", i, myMsg->payload[i]);
           }

           modulusptr = (int64_t*)&myMsg->payload[0];
           exponentptr = (int64_t*)&myMsg->payload[8];

           //dbg(GENERAL_CHANNEL, "Recieved key: exponent = %lli, modulus = %lli\n", *exponentptr, *modulusptr);

           exponent = *exponentptr;
           modulus = *modulusptr;

           dbg(GENERAL_CHANNEL, "Recieved key: exponent = %lli, modulus = %lli\n", exponent, modulus);

           //generate a large prime to be the shared encryption key
           sharedKey = call RSAint.gen_shared_key();
           dbg(GENERAL_CHANNEL, "The shared key is %llu\n", sharedKey);

           //use the recieved public key to encrypt the shared key
           sharedKey = call RSAint.encrypt_shared_key(sharedKey, exponent, modulus);
           dbg(GENERAL_CHANNEL, "The encrypted shared key is %llu\n", sharedKey);

           //send the encrypted shared key back to the sender of the message
           p = (uint8_t*)&sharedKey;

           for(i=0; i<8; i++){
             payloadArr[i] = p[i];
           }

           //sending message
           makePack(&sendPackage, TOS_NODE_ID, myMsg->src, MAX_TTL, PROTOCOL_KEY_RECEIVE, currentSeq, (uint8_t*)&payloadArr, PACKET_MAX_PAYLOAD_SIZE);
           currentSeq++;

           dbg(GENERAL_CHANNEL, "message created... \n");

           //send message
           call Sender.send(sendPackage, AM_BROADCAST_ADDR);

           return msg;
         }
         if(myMsg->protocol == PROTOCOL_KEY_RECEIVE){
           uint64_t* sharedKeyPtr;
           uint64_t sharedKey;

           dbg(GENERAL_CHANNEL, "Node %d recieved a shared key from node %d...\n", TOS_NODE_ID, myMsg->src);

           sharedKeyPtr = (int64_t*)&myMsg->payload[0];

           sharedKey = *sharedKeyPtr;

           dbg(GENERAL_CHANNEL, "The encrypted shared key is %lli \n", sharedKey);

           sharedKey = call RSAint.decrypt_shared_key(sharedKey);

           dbg(GENERAL_CHANNEL, "The decrypted shared key is %lli \n", sharedKey);

           return msg;
         }
         //dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
         return msg;
      }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }


   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
      makePack(&sendPackage, TOS_NODE_ID, destination, 0, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Sender.send(sendPackage, destination);
   }

   event void CommandHandler.keyReq(uint16_t destination){
     //nodeInfo temp;
      int64_t exponent, modulus, holder;
      int64_t* payloadKey;
      //uint8_t* payloadPtr;
      uint8_t payloadArr[PACKET_MAX_PAYLOAD_SIZE];
      uint8_t i, j;
      int8_t* p;
      int8_t* q;

      dbg(GENERAL_CHANNEL, "Node %d sending public key to node %d... \n", TOS_NODE_ID, destination);

      //call RSAint.gen_key();
      exponent = call RSAint.get_exponent();
      modulus = call RSAint.get_modulus();

      dbg(GENERAL_CHANNEL, "Public key: e = %llu, m = %llu \n", exponent, modulus);

      p = (uint8_t*)&modulus;
      q = (uint8_t*)&exponent;

      j=0;
      for(i=0; i<16; i++){
        if(i<8){
          payloadArr[i] = p[i];
        }else{
          payloadArr[i] = q[j];
          j++;
        }
        dbg(GENERAL_CHANNEL, "Arr[%d] = %d\n", i, payloadArr[i]);
      }

      //payloadPtr = payloadArr[0];

      //makePack(&sendPackage, TOS_NODE_ID, destination, MAX_TTL, PROTOCOL_KEY_REQUEST, currentSeq, payloadPtr, PACKET_MAX_PAYLOAD_SIZE);
      makePack(&sendPackage, TOS_NODE_ID, destination, MAX_TTL, PROTOCOL_KEY_REQUEST, currentSeq, (uint8_t*)&payloadArr, PACKET_MAX_PAYLOAD_SIZE);
      currentSeq++;

      dbg(GENERAL_CHANNEL, "message created... \n");

      //send message
      call Sender.send(sendPackage, AM_BROADCAST_ADDR);
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
