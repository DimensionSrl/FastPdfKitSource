/*
 *  mfprofile.c
 *  FastPDFKitTest
 *
 *  Created by Nicolò Tosi on 2/3/11.
 *  Copyright 2011 com.mobfarm. All rights reserved.
 *
 */

#include "mfprofile.h"

void initProfile(MFProfile * profile) {
	
	profile->fpdfk_xtr_policy[0] = 1;
	profile->fpdfk_xtr_policy[1] = 1;
	profile->fpdfk_xtr_policy[2] = 1;
	profile->fpdfk_xtr_policy[3] = 1;
	profile->fpdfk_xtr_policy[4] = 1;
	
	profile->fpdfk_src_policy[0] = 3;
	profile->fpdfk_src_policy[1] = 3;
	profile->fpdfk_src_policy[2] = 3;
	profile->fpdfk_src_policy[3] = 3;
	profile->fpdfk_src_policy[4] = 3;
	
}

void initProfileWithSettings(MFProfile * profile, int xtr0, int xtr1, int xtr2, int xtr3, int xtr4, int src0, int src1, int src2, int src3, int src4) {
	
	profile->fpdfk_xtr_policy[0] = xtr0;
	profile->fpdfk_xtr_policy[1] = xtr1;
	profile->fpdfk_xtr_policy[2] = xtr2;
	profile->fpdfk_xtr_policy[3] = xtr3;
	profile->fpdfk_xtr_policy[4] = xtr4;
	
	profile->fpdfk_src_policy[0] = src0;
	profile->fpdfk_src_policy[1] = src1;
	profile->fpdfk_src_policy[2] = src2;
	profile->fpdfk_src_policy[3] = src3;
	profile->fpdfk_src_policy[4] = src4;
}
