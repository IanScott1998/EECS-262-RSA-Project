#include "RSA.h"
#include <math.h>
#include "Timer.h"

//provides encryption/decryption
//stores public/private keys
//figure out how to generate prime numbers

module RSAP{
    provides interface RSAinterface;

    uses interface primeModule;
    uses interface Timer<TMilli>;
    uses interface LocalTime<TMilli>;
    //uses interface Hashmap<uint32_t>;
}
implementation{
    //MAY REQUIRE CHANGES TO SIGNED INT IN PLACES?
    public_key_class pubKey;
    private_key_class privKey;
    //char *PRIME_SOURCE_FILE = "primes.txt";
    char buffer[1024];
    const uint32_t MAX_DIGITS = 50;
    uint16_t i = 0;
    uint16_t j = 0;
    int32_t p1;
    int32_t p2;
    int32_t nVal;
    int32_t phiNval;
    int32_t startT;
    int32_t totT;
    int32_t genTime = 0;
    int32_t valTime = 0;
    int32_t curt;
    int32_t bert;
    int32_t kurt;

    /*
    int64_t gcd(int64_t a, int64_t h){
      int64_t temp;
    */
    event void Timer.fired(){

    }

    uint64_t gcd(uint64_t a, uint64_t h){
      uint64_t temp;
      while(TRUE){
        temp = a%h;
        if(temp==0){
          return h;
        }
        a = h;
        h = temp;
      }
    }

    int64_t ExtEuclid(int64_t a, int64_t b){
      int64_t x = 0;
      int64_t y = 1;
      int64_t u = 1;
      int64_t v = 0;
      int64_t gcdVar = b;
      int64_t m;
      int64_t n;
      int64_t q;
      int64_t r;
      while(a != 0){
        q = gcdVar/a;
        r = gcdVar%a;
        m = x-u*q;
        n = y-v*q;
        gcdVar = a;
        a = r;
        x = u;
        y = v;
        u = m;
        v = n;
      }
      return y;
    }

    int64_t ExtendEuclid(int64_t a, int64_t b, int64_t* x, int64_t* y){

    }

    int64_t ExtendedEuclidean(int64_t a, int64_t b, int64_t* x, int64_t* y){
      int64_t xTemp, yTemp;
      int64_t d;

      if(a == 0){
        *x = 0;
        *y = 1;
        return b;
      }

      d = ExtendedEuclidean(b%a, a, &xTemp, &yTemp);
      *x = yTemp - (b/a) * xTemp;
      *y = xTemp;
      return d;
    }

    size_t highestOne(uint64_t a){
      size_t bits = 0;
      while(a!=0){
        ++bits;
        a>>=1;
      }
      return bits;
    }

    bool bboverflow(uint64_t a, uint64_t b){
      size_t aBits, bBits;
      aBits = highestOne(a);
      bBits = highestOne(b);
      return(aBits+bBits>=64);
      //return(aBits+bBits>=58); //<- conservative tests to catch all overflow (will catch non overflow)
    }

    uint64_t rsa_bbcalc(uint64_t b1, uint64_t b2, uint64_t m){
      b1 = b1 % m;
      b2 = b2 % m;
      if (!bboverflow(b1,b2)){
      return(b1*b2 % m);
      }
      if(b1%2 == 0 && b2%2 == 0){
        //printf("case 1\n");
        return(rsa_bbcalc(2*b1 % m, b2/2, m) % m);
      }
      if(b1%2 == 1 && b2%2 == 1){
        //printf("case 2\n");
        return((rsa_bbcalc(b1 - 1,b2 - 1, m) + b1 + b2 - 1) % m);
      }
      if(b1%2 == 1 && b2%2 == 0){
        //printf("case 3\n");
        return((rsa_bbcalc(b1 - 1,b2, m) + b2) % m);
      }
      if(b1%2 == 0 && b2%2 == 1){
        //printf("case 4\n");
        return((rsa_bbcalc(b1,b2 - 1, m) + b1) % m);
      }
    }

    //int64_t rsa_modExp(int64_t b, int64_t e, int64_t m){
    uint64_t rsa_modExp(uint64_t b, uint64_t e, uint64_t m){
      uint64_t tempB;
      if(b<0 || e<0 || m<=0){
        exit(1);
      }
      b = b % m;
      if(e==0){
        return 1;
      }
      if(e==1){
        return b;
      }
      if(e%2 == 0){
        //if(bboverflow(b,b)){
          //dbg(GENERAL_CHANNEL, "Overflow Detected... \n");
          b = rsa_bbcalc(b,b,m);
          return(rsa_modExp(b, e/2, m) % m);
        /*
        }else{
          //dbg(GENERAL_CHANNEL, "B = %llu \n", b);
          return(rsa_modExp(b*b%m, e/2, m) % m);
        }
        */
      }
      if(e%2 == 1){

        b = rsa_bbcalc(b, rsa_modExp(b,(e-1),m), m);

        return(b);
        //return(b*rsa_modExp(b,(e-1), m) % m);
      }
    }

    int64_t inverse(int64_t a, int64_t n){
      int64_t t, r, newt, newr, quotient, temp;
      t = 0;
      r = n;
      newt = 1;
      newr = a;

      while(newr != 0){
        quotient = r / newr;
        temp = t;
        t = newt;
        newt = temp - quotient*newt;
        temp = r;
        r = newr;
        newr = temp - quotient*newr;
      }

      if(r<1){
        //dbg(GENERAL_CHANNEL, "not invertable\n");
        return 0;
      }
      if(t<0){
        return t+n;
      }
      return t;
    }

    command bool RSAinterface.RSAtest(){
      printf("p = %lu, q = %lu, n = %lu, phi n = %lu\n", p1, p2, nVal, phiNval);
      printfflush();
      return 1;
    }

    command void RSAinterface.rsa_test_prime(uint32_t a){
      int32_t k = 3;
      uint8_t v;
      call primeModule.isPrime(a, k);
      //call primeModule.is_prime(a, k);
      /*
      for(v=0; v<10; v++){
        call primeModule.genLargeNum();
      }
      */
      //a = call primeModule.genLargePrime();
    }

    command uint32_t RSAinterface.rsa_gen_prime(){
      uint32_t num;

      num = call primeModule.genLargePrime();

      return num;
    }

    command void RSAinterface.rsa_test_key(){

        pubKey.modulus = 3127;
        pubKey.exponent = 3;

        privKey.modulus = 3127;
        privKey.exponent = 2011;

        //dbg(GENERAL_CHANNEL, "VALUES ASSIGNED \n");

        //dbg(GENERAL_CHANNEL, "pub modulus: %d, pub exponent: %d \n", pubKey.modulus, pubKey.exponent);
        //dbg(GENERAL_CHANNEL, "priv modulus: %d, priv exponent: %d \n", privKey.modulus, privKey.exponent);
    }

    command void RSAinterface.gen_key(){
      //int32_t p, q, n, phi_n, e, d, x, y, dtest, dres;
      int32_t p, q, n, phi_n, e, d;
      int64_t e64, d64, n64, phi_n64;
      //uint16_t loops;

      //dbg(GENERAL_CHANNEL, "Key generation started...\n");

      p = call RSAinterface.rsa_gen_prime();
      q = call RSAinterface.rsa_gen_prime();
      n = p*q;
      n64 = (uint64_t)n;
      phi_n = (p-1)*(q-1);
      phi_n64 = (uint64_t)phi_n;

      pubKey.modulus = n;
      privKey.modulus = n;


      do{
        e64 = rand() % (phi_n64 - 2);
        e64 = e64+2;
      }while(gcd(e64, phi_n64) != 1 || gcd(e64, n64) != 1);

      /*
      for(e = 3; e<phi_n; e++){
        if(gcd(e, phi_n) == 1 && gcd(e, n) == 1){
          break;
        }
      }
      */
      //dbg(GENERAL_CHANNEL, "Encryption key generated...\n");

      /*
      ExtendedEuclidean(phi_n, e, &x, &y);

      //mpz_invert(&e, &phi_n, &d);

      d = y;

      if(d<0){
        d = phi_n - d;
      }
      */

      d64 = inverse(e64,phi_n64);
      //dbg(GENERAL_CHANNEL, "Decryption key generated...\n");

      d = (uint32_t)d64;
      e = (uint32_t)e64;

      pubKey.exponent = e;
      privKey.exponent = d;

      if(d <= 0 || e <= 0){
        call RSAinterface.gen_key();
      }else{
        //dbg(GENERAL_CHANNEL, "p: %lld, q: %lld, n or modulus: %lld, phi_n: %lld, e: %lld, d: %lld \n", p, q, n, phi_n, e, d);
        printf("p: %ld, q: %ld, n or modulus: %ld, phi_n: %ld, e: %ld, d: %ld \n", p, q, n, phi_n, e, d);
        p1 = p;
        p2 = q;
        nVal = n;
        phiNval = phi_n;
      }
    }

    //command int64_t* RSAinterface.rsa_encrypt(const char *message, const uint32_t message_size, const struct public_key_class *pub){
    command uint32_t* RSAinterface.rsa_encrypt(const char *message, const uint32_t message_size){
        uint32_t *encrypted = malloc(sizeof(uint32_t)*message_size);
        uint32_t k;

        //dbg(GENERAL_CHANNEL, "Beginning encryption \n");
        if(encrypted == NULL){
          //heap allocation fails
          //dbg(GENERAL_CHANNEL, "Heap allocation failed. \n");
          return NULL;
        }
        //dbg(GENERAL_CHANNEL, "start of loop \n");
        for(k=0; k<message_size; k++){
          encrypted[k] = rsa_modExp(message[k], pubKey.exponent, pubKey.modulus);
        }
        //dbg(GENERAL_CHANNEL, "End of loop \n");
        return encrypted;
    }

    //command char* RSAinterface.rsa_decrypt(const int64_t *message, const uint32_t message_size, const struct private_key_class *priv){
    command char* RSAinterface.rsa_decrypt(const uint32_t *message, const uint32_t message_size){

      char *decrypted;
      uint32_t *temp; //char
      uint32_t k = 0;

      if(message_size % sizeof(uint32_t) != 0){
        //message size not devisable, so decryption fails
        //dbg(GENERAL_CHANNEL, "Error: message not devisable.\n");
        return NULL;
      }

      decrypted = malloc(message_size/sizeof(uint32_t));
      temp = malloc(message_size);
      //dbg(GENERAL_CHANNEL, "size of temp: %d \n", message_size);

      if((decrypted == NULL) || (temp==NULL)){
        //heap allocation fails
        //dbg(GENERAL_CHANNEL, "Error: heap allocation failed.\n");
        return NULL;
      }

      //error storing in uint8_t char rather than uint64_t
      for(k=0; k<message_size/8; k++){
        //dbg(GENERAL_CHANNEL, "cyphertext: %llu \n", message[k]);
        temp[k] = rsa_modExp(message[k], privKey.exponent, privKey.modulus);
        //dbg(GENERAL_CHANNEL, "decrypted: %llu \n", temp[k]);
      }

      for(k=0; k<message_size/8; k++){
        decrypted[k] = (uint8_t)temp[k];
      }
      free(temp);
      return decrypted;
  }

  command void RSAinterface.test_key_gen(){
    uint16_t b, npasses, fails;
    uint32_t keyTest, keyRes;
    for(b = 1; b<100; b++){
      srand(b);
      call RSAinterface.gen_key();
      keyTest = rsa_modExp(97, pubKey.exponent, pubKey.modulus);
      keyRes = rsa_modExp(keyTest, privKey.exponent, privKey.modulus);
      if(keyRes == 97){
        npasses++;
      }else{
        fails++;
      }
    }
    //dbg(GENERAL_CHANNEL, "Test complete... %d passes... %d fails...\n", npasses, fails);
    npasses = 0;
    fails = 0;
  }

  command int32_t RSAinterface.get_modulus(){
    if(pubKey.modulus == NULL){
      return 0;
    }
    return pubKey.modulus;
  }

  command int32_t RSAinterface.get_exponent(){
    if(pubKey.exponent == NULL){
      return 0;
    }
    return pubKey.exponent;
  }

  command int32_t RSAinterface.get_private(){
    if(privKey.exponent == NULL){
      return 0;
    }
    return privKey.exponent;
  }

  command bool RSAinterface.checkKey(){
    uint32_t testVal = 65;
    testVal = rsa_modExp(testVal, pubKey.exponent, pubKey.modulus);
    testVal = rsa_modExp(testVal, privKey.exponent, privKey.modulus);
    if(testVal == 65){
      return TRUE;
    }
    //printf("testVal = %lu\n", testVal);
    //printfflush();
    return FALSE;
  }

  command void RSAinterface.gen_val_key(){
    int8_t tries = 0;
    bool valid = FALSE;
    kurt = 0;
    startT = call LocalTime.get();
    for(tries = 0; tries<10; tries++){
      bert = call LocalTime.get();
      call RSAinterface.gen_key();
      curt = call LocalTime.get();
      curt = curt - bert;
      kurt = kurt + curt;
      genTime = genTime + curt;
      valid = call RSAinterface.checkKey();
      if(valid == TRUE){
        totT = call LocalTime.get();
        totT = totT - startT;
        bert = totT-kurt;
        valTime = valTime + bert;
        //printf("valid key in %d tries. took %ld ms...\n", tries, totT);
        printf("valid key in %d tries. took %ld ms to generate %ld ms to validate. %ld ms total...\n", tries, kurt, bert, totT);
        printfflush();
        return;
      }
    }
    printf("failed to make valid key...\n");
    printfflush();
    return;
  }

  command void RSAinterface.print_time(){
    uint32_t avgGen;
    uint32_t avgVal;
    avgGen = genTime / 100;
    avgVal = valTime / 100;
    printf("Average time to generate a key: %ld \n", avgGen);
    printf("Average time to validate a key: %ld \n", avgVal);
    avgGen = avgGen+avgVal;
    printf("Average time to make a valid key: %ld \n", avgGen);
    printfflush();
  }

  command uint32_t RSAinterface.gen_shared_key(){
    uint32_t num;

    num = call primeModule.genSharedPrime();

    return num;
  }

  command uint32_t RSAinterface.encrypt_shared_key(uint32_t key, int32_t exponent, int32_t modulus){
    uint64_t tempKey, tempMod, tempExp;
    tempKey = (uint64_t)key;
    tempMod = (uint64_t)modulus;
    tempExp = (uint64_t)exponent;
    tempKey = rsa_modExp(tempKey, tempExp, tempMod);
    key = (uint32_t)tempKey;
    return key;
  }

  command uint32_t RSAinterface.decrypt_shared_key(uint32_t key){
    uint64_t tempKey, tempMod, tempExp;
    tempKey = (uint64_t)key;
    tempMod = (uint64_t)privKey.modulus;
    tempExp = (uint64_t)privKey.exponent;
    tempKey = rsa_modExp(tempKey, tempExp, tempMod);
    key = (uint32_t)tempKey;
    return key;
  }
}
