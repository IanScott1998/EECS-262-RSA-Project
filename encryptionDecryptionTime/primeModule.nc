interface primeModule{
  command int32_t power(int32_t a, uint32_t n, int32_t p);
  command int32_t gcd(int32_t a, int32_t b);
  command bool isPrime(uint32_t n, int32_t k);
  command uint32_t genLargeNum();//could take input of seed later for now will use rand()
  command uint32_t genLargePrime();
  command uint32_t genSharedPrime();
}
