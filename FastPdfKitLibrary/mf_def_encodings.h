/*
 *  mf_def_encodings.h
 *  EncodingTest
 *
 *  Created by Nicolò Tosi on 12/27/10.
 *  Copyright 2010 MobFarm S.r.l. All rights reserved.
 *
 */

// 127 (decimal) 177 (octal) 0x007F (hex)	

// NEXT: logical not (p.999)

// Octal notation unicodes (i.e. 0213, 0255) means that the code is not specified in the encoding.

#ifndef _MF_DEF_ENCODINGS_H_
#define _MF_DEF_ENCODINGS_H_

extern const unsigned int mf_standard_encoding_len;
extern const unsigned int mf_standard_encoding [];

extern const unsigned int mf_macroman_encoding_len;
extern const unsigned int mf_macroman_encoding [];

extern const unsigned int mf_winansi_encoding_len;
extern const unsigned int mf_winansi_encoding [];

extern const unsigned int mf_pdfdoc_encoding_len;
extern const unsigned int mf_pdfdoc_encoding [];

extern const unsigned int mf_symbols_encoding_len;
extern const unsigned int mf_symbols_encoding [];

extern const unsigned int mf_macexpert_encoding_len;
extern const unsigned int mf_macexpert_encoding [];

// THIS IS INCOMPLETE
extern const unsigned int mf_zapfdingbats_encoding_len;
extern const unsigned int mf_zapfdingbats_encoding [];

#endif