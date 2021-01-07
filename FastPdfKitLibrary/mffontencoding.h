/*
 *  MFFontEncoding.h
 *  FastPDFKitTest
 *
 *  Created by Nicolò Tosi on 12/29/10.
 *  Copyright 2010 com.mobfarm. All rights reserved.
 *
 */

#ifndef _MFFONTENCODING_H_
#define _MFFONTENCODING_H_

typedef unsigned int fpk_unicode_t;

enum MFFontEncoding {
	MFFontEncodingStandard = 0,
	MFFontEncodingMacRoman = 1,
	MFFontEncodingWinAnsi = 2,
	MFFontEncodingPdfDoc = 3,
	MFFontEncodingMacExpert = 4,
	MFFontEncodingSymbol = 5,
	MFFontEncodingZapfDingbats = 6
};
typedef unsigned int MFFontEncoding;

typedef struct MFFontEncoder {
	
	unsigned int * unicodes;
	unsigned int unicodes_len;
	MFFontEncoding base_encoding;
	unsigned int notfound;
    
} MFFontEncoder;

void initFontEncoder(MFFontEncoder * encoder);
void initFontEncoderWithEncoding(MFFontEncoder * encoder, MFFontEncoding encoding);
void deleteFontEncoder(MFFontEncoder * encoder);
void fontEncoderSetUnicodeForCode(MFFontEncoder * encoder, char * unicode_name, unsigned char code);
unsigned int * fontEncoderUnicodeForCode(MFFontEncoder * encoder, unsigned char code, int * length);

int writeUnicodeToUTF8Buffer(unsigned int * character, unsigned char * buffer);
int unicodeToUTF8BufferSpaceRequired(unsigned int character);
unsigned char * UTF8StringFromUTF32buffer(unsigned int * utf32buffer, int utf32buffer_len, int * length);

#endif