configuration RSAC{
    provides interface RSAinterface;
}

implementation{
    components RSAP as RSA;
    RSAinterface = RSA;
    //components new HashmapC(uint32_t, 20) as NeighMap;
    //RSA.Hashmap -> NeighMap;
    components primeC;
    components new TimerMilliC(), LocalTimeMilliC;
    RSA.Timer -> TimerMilliC;
    RSA.LocalTime -> LocalTimeMilliC;
    RSA.primeModule -> primeC;
}
