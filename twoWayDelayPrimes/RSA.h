#ifndef __RSA_H__
#define __RSA_H__

typedef struct public_key_class{
  int32_t modulus;
  int32_t exponent;
}public_key_class;

typedef struct private_key_class{
  int32_t modulus;
  int32_t exponent;
}private_key_class;

/*
struct public_key_class{
  int64_t modulus;
  int64_t exponent;
};

struct private_key_class{
  int64_t modulus;
  int64_t exponent;
};
*/

#endif
