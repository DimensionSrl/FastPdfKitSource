//
//  resources.h
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 8/31/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#ifndef _FPK_RESOURCES_H_
#define _FPK_RESOURCES_H_

#import <CommonCrypto/CommonDigest.h>
#import <stdio.h>
#import <string.h>
#import <math.h>

static char const * const fpdfk_wlist [] = {    // 19102011
    "015bdf645d3697cffdebcfc6d7565dfb",
    "019e17c5a488f46023c7bda9d18ec838",
    "03d3c5f827dc882353977933ee1a61b9",
    "05cfcc892139fa5eb05b93316c9f911a",
    "080abab9b0344256ca151f2af8ac8db6",
    "09441b39238a5025ee672c6ea5b04203",
    "0a6c57c98f7d0e23f2856c131f564873",
    "0caaf3c46cec12cd9d13a3ea9262eb14",
    "0ec62c1ee9e2f22f720b0d8557758bba",
    "0fac253ea5fad783f8a709db4c6fb16a",
    "10da5bac448ae437716dec9f5f431cbb",
    "122112e79987886f9aea66e9da251e01",
    "1320b5d141d9be6e1c5a8371b7d40be2",
    "16607c5508a8505d0ce885f613723967",
    "1a5c77aaf4b913bed527374b66dd34a0",
    "1b4e50fb32508274dd52f2902cd3ef2e",
    "1cdf20e55d12a12ee6fee293876fb1d8",
    "1f1328baafab40a5ffe38525534d19a7",
    "201f1c4ee4732d33941954bb887f6cf3",
    "206156419768d2745347717b446b6495",
    "21389dc77983af87ca75714af2b17ac7",
    "222118d447470cf93fcabc9c140bf011",
    "23f554f2e297060567471d6ecb0f4816",
    "2511b3f60564cf495fd2fe2bc805441a",
    "26ae3fdedd5c2958d916eed02fc5a677",
    "2772948ee76265ee499e941710765560",
    "2a298c07d41421a26cd9e8b5908addee",
    "2c71f8273b37ab8814f09a3546baf307",
    "2f624c1947340a4306e55e67ab4982e1",
    "30f957777e126a7fe6619f2b2f5f904a",
    "30feaf36f01c097fbcabd06cdcd5b5ec",
    "39219f8c49a3843e5ada5a7425833cc8",
    "3a57177adbce4aa0d53fdc1790d6631b",
    "3bc9e2c4a08c1d74223de7caa9094bb6",
    "3ecf683820ad0a44b835a57db0ab6950",
    "3f6552b91b12c5f08edefe25d933f18c",
    "408c319e6cde819ffdf0957447cb2a62",
    "417b0aa95ebc0ef69f3005c5f560c6d6",
    "422868fcc725f9db5bdc27e9410b1aca",
    "440a6ae10ac3409a0a05adbbd916d2f5",
    "4832b633f58cea8f2360d44d31928d6a",
    "4d761c8094e69148ae4c04e3c4a09f63",
    "4e8f64fec16bcf59bb50d58ebffcd96e",
    "4eb32577b0e1a56f03633b931545cd2d",
    "52acce93af782115c47f68ffaacc00c9",
    "52f92a954e5409183552d2b4862d71f0",
    "5313f50c0435f45eec9dde948c44e723",
    "557b193963bff6732b38122a88d0e146",
    "5b3c8855e5cf00681bebaa14cf9c90fb",
    "5c7c0929de712e239e54f9aa3267e6ed",
    "5d045c1713ade6f1d6720d8eb70fa5ff",
    "5d88c886983c3a9e71df02eff22337d2",
    "5f1edc251f0aeaabab0c97e8ef2ffd7b",
    "60682aaffb08c4fc023819f2d8220145",
    "61ddc5f7b58ae81e14c2a56902ace817",
    "61fc21e098eb10cf50341b1a539cc309",
    "624abbbaa382ddf58cd51e52582608e9",
    "62f8e5f75127f1d2d54798062f40b462",
    "6437d0125a4029a317063d6e69b7e86e",
    "6c7ad2b0aefa09571834d7375e7ae2ab",
    "6cb511a1937eedc1a71499ad2f6228c5",
    "6cde15b292e7fac9f602dc90a4d665da",
    "6da7344da278a100323eda43f6df973e",
    "6e00fd5c50efecafdbf96db7fdf31343",
    "6e3c18aa1f530cd7b56651ced21d120a",
    "6e41797c07e7e6a3b4277bbdc16767cb",
    "6ec1d60b397b7c41c700c08a7a7ac279",
    "6f22d8b2fabbcb1029eeb69e586b3ead",
    "70d37e527d2a3cac70efb6a0c48f8c96",
    "711a73337e7ce498d7e718724cc83907",
    "714193e7a56f602c22c6c8a952604082",
    "73e40c1cbbd850d07e3a8ed96fc98861",
    "741617b8a11d413b99a4e7b13be44cd7",
    "778259d5c371cb19622b6d148f429245",
    "78b94f4a747882bfcc60ea73eb91e666",
    "7b7297b87e1144c08691e697cc00d550",
    "7c95573a544d1183e702eb08b76c5abd",
    "7c9fc676ed7d85dae9f00d0355d37f2c",
    "81eed9fb06d4f5c2384177c7ab8c745b",
    "83fe8fa8ddbcef1d23389ba7f1cc485e",
    "84451e60ae60677967ba3a02b763eb56",
    "867a76f90bc201d90e54bc0b4aa33fa5",
    "8730cbe7f513cd9265861abcadd40cb3",
    "876b1e988522e428789e5db7e0852764",
    "88368e0a943906f86267ce6d1a641aa6",
    "8a4b39e196f7f3957643ea603650fd7c",
    "8acebab8e099e8634898ef1586651750",
    "8b1b55ccd607051829ac80ae955bcc0f",
    "8bb3eddd859b280c26a7f57effe72b42",
    "9114f80c74c68f267c69f92d0c18ae3e",
    "9118adda63eb935270528a1397e07943",
    "91fd9c6023dcd8900ccb236bb9800ea4",
    "948d63a98d50efd8607bdca0b13fb787",
    "953d8efa746426ff0e95a032bd8f93a5",
    "9646ddf070b55862803400a284f4f59b",
    "96749efefde319f0f9e113143e8ff961",
    "96caf4bf33c51a904bc0b83f4fe5489e",
    "9a526815447a2004584082f7c6d777bb",
    "9a8e9974bb94f4ac27bf5b63336a2acd",
    "9c42f925bb3956f0f1f83bbe64b69111",
    "9c5c78956a89e9333873425fb0ac8cb6",
    "9d1963df6cebadda041ff879bff36312",
    "9d1addbde083b78fad1289a6e9c4ddb9",
    "9ff6a1dcd6093faf9547cfb7eeb9487f",
    "a115e6cb93437d9a7e2a75f0dd4ddc72",
    "a5a3e08670db5a145653fc4fad7aaa16",
    "a77dd309e309dc3f77bbd78a5728c9dc",
    "a8c582e01f88334fd509673fe631fa27",
    "aa77ff3f7d8270d9570d0d934edb887f",
    "ab22eee587658fa47ee560a0a37afcbe",
    "ad2974f46fcc532a8c6e35b775f34f1b",
    "ad964273d684de986ce91c3b247d0e76",
    "b0251bf8ac43eeaab93eead9502dcb8a",
    "b046516e0ffa091b5aab2be16c4f44cb",
    "b21e3315e227da333ec9096bac9905bc",
    "b289f46b45113e3076d0b8538af70011",
    "b54091f1f0b0998888b239e879f7854b",
    "b688ff979a4433be4ffb41d2d99aa790",
    "b6ab21e87754a12ff86bfac966896e12",
    "b8a6aadef8bfa7a93784d3778dad0051",
    "b9302cc37729072d65fc7872a5fde1f7",
    "b98bc9cc241851e0477b2a0b982c40ad",
    "bfc91674f28813cb2703191b2d224366",
    "c08c1326ccc431900777ab93abb3ea6e",
    "c255a4d28e48d51b1ed3aa5b57aa559d",
    "c730173e56d28d35536965a0ccd097b0",
    "c8cb31ea59a69f70b4d0fc65294f03ff",
    "c9a6cac4d72d1ae8a0321321d2fe6e79",
    "cb89c52666b7c965a296e303249c0142",
    "ce2cc20c00dd55d5a7c1059e80299a4a",
    "ce6843aa7c9262753d4ece346de7fd2e",
    "ce6b2ca6cd44bb4c6d867d83a5759c27",
    "cef9732535b149c4d51f813b08683ac9",
    "cf1459a4f454062097448ab4a8eb0e94",
    "d19dde2a09b2ebd0927ae3d6a0182229",
    "d43e63221fdb68f9d58139bb4eec2a1f",
    "d619ae4d7e55408c5a127db25e8a98da",
    "d66720321662d5745684f331b572981d",
    "d81e6333975dfc789b8e52d7e5c13c01",
    "d879f8fc3bfd68c34f8e024ef166b213",
    "dd0c7d1c96fdc84fdb6fbad8e0b86e28",
    "df6b518f2f65e14c40c3ce205dd0d4a7",
    "e06ab400c325f73e6dd5c394fa5baef3",
    "e29b0142208413a2cb39ad4c9e3cd0d3",
    "e5a085ce166916d8ac0e57d1e06b13f6",
    "e69965a82db95f37cc0582a274cec7e4",
    "e8c462d4cfdbdb8a6421924bfbb55804",
    "eaff322ef8ee55e3f87f89b72c1553f9",
    "eda33ad5506cb6ddaaa4b644d9e5355a",
    "ef351a0cf80ada28fcf4f8be00302c72",
    "ef5a52e44c6f0d25fdb5e9cc0310fe36",
    "efa8f52a20b99f9847a3e4cff765791c",
    "f25da89141a0e44008fbeff79052ef96",
    "f336b94404363b19d7b1e403f982bc29",
    "f51eec5e2b199039f5e8de6339dc278f",
    "f6f0f1d74cff21143f58f4b2e5b73e0c",
    "f787faeb98f921524fa93e5bbaf63577",
    "fb532b34ad601c3370afe7ce0a1b48d5",
    "fbcd02e3bba240c6092661f148031e7e",
    "fdee913ba7211892c5ce1364a7f63611",
    "fe16ffa97aad39905afd4f6ab50e5802"
};
static const int fpdfk_wlist_len = 161;

static inline void hexstringToArray(unsigned char * hex, int hex_len, const char * string, size_t string_len) {
    
    static const unsigned char lookup [] = {
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,        // 0...
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,        // 16...
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,        // 32...
        0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,        // 48...
        0,10,11,12,13,14,15,0,0,0,0,0,0,0,0,0,  // 64...
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,        // 80...
        0,10,11,12,13,14,15,0,0,0,0,0,0,0,0,0,  // 96...
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0        //112
    };
    
    int index;
    int count = hex_len <= (string_len/2) ? hex_len : (string_len/2); // Instead of fmin for the lulz.
    unsigned char tmp0, tmp1;
    
    for(index = 0; index < count; index++) {
        tmp0 = lookup[string[index*2]];
        tmp1 = lookup[string[index*2+1]];
        hex[index] = tmp0*16+tmp1;
    }
}

static inline int difference(unsigned char * a0, unsigned char * a1, int len) {
    int index;
    unsigned char diff;
    for(index = 0; index < len; index++) {
        if((diff=a0[index]-a1[index])!=0)
            return diff;
    }
    return 0;
}

static inline int lookupIndexForName(const char * name, const char * const * names, int min, int max) {
	
	// Binary search.
	
	if(min > max) 
		return -1;
	
	int mid = min + (max - min)/2;
	
	const char * lookedup = names[mid];
	
	int difference = strcmp(name,lookedup);
	
	if(difference == 0) { // No difference, we have found it!
		
		return mid;
		
	} else if (difference > 0)  { // Name is greater.
		
		return lookupIndexForName(name,names,mid+1,max);
		
	} else { // Name si smaller.
		
		return lookupIndexForName(name,names,min,mid-1);
		
	}
}

static inline void generate_hex2(unsigned char * hex, const char * bundle, size_t bundle_len, const char * salt, int salt_len,  unsigned int type) {
    
    static const char * codes [] = {"p4p3r1n0","n0nn4p4p3r4","g4st0n3"};
    static const int codes_sizes [] = {8,11,7};
    
    CC_MD5_CTX md5;
    unsigned char digest[16] = {0};
    unsigned char padding[16] = {0};
    
    CC_MD5_Init(&md5);
    CC_MD5_Update(&md5,"c0st1tuz10n3",12);
    CC_MD5_Update(&md5,bundle,bundle_len);
    CC_MD5_Update(&md5,codes[type],codes_sizes[type]);
	CC_MD5_Final(digest,&md5);
    
    CC_MD5_Init(&md5);
    CC_MD5_Update(&md5,"s0g3tth1s",9);
    CC_MD5_Update(&md5,bundle,bundle_len);
    CC_MD5_Final(padding,&md5);
    
    memcpy(hex, digest, 16);
    memcpy((hex+16), padding, 4);
}

static inline void generate_hex(char * dst, const char * bid, int bid_len, const char * s, int s_len) {
	
	CC_MD5_CTX md5;
	unsigned char digest [16] = {0};
	
	CC_MD5_Init(&md5);
	CC_MD5_Update(&md5,"c0st1tuz10n3",12);
	CC_MD5_Update(&md5,bid,bid_len);
	CC_MD5_Final(digest,&md5);
	
	sprintf(dst,"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",digest[0],digest[1],digest[2],digest[3],digest[4],digest[5],digest[6],digest[7],digest[8],digest[9],digest[10],digest[11],digest[12],digest[13],digest[14],digest[15]);
}

#pragma mark - Cidf

extern const unsigned char fpk_cidf_identity_h [];
extern const unsigned int fpk_cidf_identity_h_len;

extern const unsigned char fpk_cidf_identity_v [];
extern const unsigned int fpk_cidf_identity_v_len;

#pragma mark - Images

extern const unsigned int fpdfk_splash_256_len;
extern const unsigned char fpdfk_splash_256[];

extern const unsigned int fpdfk_splash_512_len;
extern const unsigned char fpdfk_splash_512[];


#endif
