

// float eccentricAnomaly(float e, float M);

eccentricAnomaly: // S0 <-- e ; S1 <-- M ;

    VMOV S9, S0             // PRESERVE e IN S9
    PUSH { LR }             // PRESERVE LINKER

    VMOV S0, S1             // S0 == M 
    
    BL   SinDeg             // SinDeg(M)
    VMOV S4, S0             // S4 == SinDeg(M)

    BL   CosDeg             // CosDeg(M)
    VMOV S5, S0             // S5 == CosDeg(M)

    VMOV S2, #1             // S2 == 1
    
    VMUL.F32 S4, S4, S9     // (e * SinDeg(M))
    VMLA.F32 S2, S5, S9     // (1 + e * CosDeg(M))

    VMUL.F32 S4, S4, S2     // (e * SinDeg(M)) * (1 + e * CosDeg(M)

    VMOV S0, S4             // S0 == (e * SinDeg(M)) * (1 + e * CosDeg(M)

    BL Rad2Deg 

    VADD.F32 S0, S0, S1     // S0 == M + [(e * SinDeg(M)) * (1 + e * CosDeg(M))]

    POP { PC }

// float kepler(float m, float ecc);

//S REGS:: S0 <- function param, S1 <- ecc, S2 <- e, S3 <- m, S4 <- 

.FLOAT EPSILON 1E-6

kepler: // S0 <-- m ; S1 <-- ecc ;

    //preserve
    PUSH { LR }               // save linker
    // VMOV S9, S0            // S9 == m

    //setup
    BL   Deg2rad              // param( S0 <- m ) && returns Deg2rad(m)
    
    VMOV S3, S0               // S2 ==  e == Deg2rad(m)
    VMOV S4, S0               // S3 ==  m == Deg2rad(m)

loop: //DO I HAVE TO LOAD ALL THE VARIABLES USED (EVEN THE ONES THAT DON'T CHANGE) ??
    VLDR S2, [R2]             // load 'delta' to S2 from mem
    VLDR S3, [R3]             // load 'e' to S3 from mem

    VMOV S0, S3               // S0 == S3 == e

    //preserve 
    PUSH { LR }

    BL sinf                   // param( S0 <- e ) && returns SinDeg(e)
    VMOV S5, S0               // S5 == S0 == SinDeg(e)

    BL cosf                   // param( S0 <- e ) && returns CosDeg(e)
    VMOV S6, S0               // S6 == S0 == CosDeg(e)

    //pop but don't exist
    POP { LR }

    VMUL.F32 S2, S1, S5       // S2 == delta == ecc*sinf(e)
    VSUB.F32 S2, S3, S2       // S2 == delta == e - ecc*sinf(e)
    VSUB.F32 S2, S2, S4       // S2 == delta == e - ecc*sinf(e) - m

    VMUL.F32 S10, S1, S6      // S10 == e == ecc*cosf(e)
    VMOV S8, 1.0
    VSUB.F32 S10, S8, S10     // S10 == e == (1.0 - ecc*cosf(e))
    VDIV.F32 S10, S2, S10     // S10 == e == delta/(1.0 - ecc*cosf(e))

    VABS.F32 S7, S2           // fabsf(delta)
    VLDR S8, EPSILON          // S8 == EPSILON == 1E-6

    VSTR S2, [R2]             // store 'delta' to mem
    VSTR S3, [R3]             // store 'e' to mem

    VMOV S0, S3               // e

    VCMP.F32 S7, S8           // fabsf(delta) > EPSILON ?
    VMRS APSR_NZCV, FPSCR     //MOVE FLAGS TO MAIN PROCESSOR?

    //continue condition
    BGT loop
    //else
end:
    VLDR S0, [S3]             //LOAD LAST VALUE OF e into S0
    BX  LR                    //return 