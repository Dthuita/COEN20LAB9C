

.syntax unified
.cpu cortex-m4
.text

// float EccentricAnomaly(float e, float M)
/* 
.global EccentricAnomaly
.thumb_func
.align

EccentricAnomaly: // S0 <-- e ; S1 <-- M ;

    VMOV S9, S0             // PRESERVE e IN S9
    PUSH { LR }             // PRESERVE LINKER

    VMOV S0, S1             // S0 == M 
    
    BL   sinDeg             // SinDeg(M)
    VMOV S4, S0             // S4 == SinDeg(M)

    VMOV S0, S1             // S0 == M 
    BL   cosDeg             // CosDeg(M)
    VMOV S5, S0             // S5 == CosDeg(M)
    
    @ VMUL.F32 S4, S4, S9     // (e * SinDeg(M))

    VMOV S2, 1.0             // S2 == 1
    VMLA.F32 S2, S5, S9     // (1 + e * CosDeg(M))

    VMUL.F32 S4, S4, S2     //SinDeg(M) * (1 + e * CosDeg(M)
    VMUL.F32 S4, S4, S9     // e * SinDeg(M) * (1 + e * CosDeg(M)

    @ VMUL.F32 S4, S4, S2     // (e * SinDeg(M)) * (1 + e * CosDeg(M)

    VMOV S0, S4             // S0 == (e * SinDeg(M)) * (1 + e * CosDeg(M)

    BL Rad2Deg 

    VADD.F32 S0, S0, S1     // S0 == M + Rad2Deg[(e * SinDeg(M)) * (1 + e * CosDeg(M))]

    POP { PC }

*/

// float kepler(float m, float ecc);

.global Kepler
.thumb_func
.align

Kepler: // S0 <-- m ; S1 <-- ecc ;
    //setup   
    PUSH { R4, LR }
    VPUSH { S16 - S19 } //SCTRACH REGIRSTERS????
    BL   Deg2Rad              // param( S0 <- m ) && returns Deg2rad(m)
    
    VMOV S16, S0               // S2 ==  e == Deg2rad(m)
    VMOV S4, S0               // S3 ==  m == Deg2rad(m)

loop: //DO I HAVE TO LOAD ALL THE VARIABLES USED (EVEN THE ONES THAT DON'T CHANGE) ??
    @ VLDR S2, [R2]             // load 'delta' to S2 from mem
    @ VLDR S3, [R3]             // load 'e' to S3 from mem

    VMOV S0, S3               // S0 == S3 == e
    BL sinf                   // param( S0 <- e ) && returns SinDeg(e)
    VMOV S5, S0               // S5 == S0 == SinDeg(e)

    VMOV S0, S3               // S0 == S3 == e
    BL cosf                   // param( S0 <- e ) && returns CosDeg(e)
    VMOV S6, S0               // S6 == S0 == CosDeg(e)

    VMUL.F32 S2, S1, S5       // S2 == delta = ecc*sinf(e)
    VSUB.F32 S2, S3, S2       // S2 == delta = e - ecc*sinf(e)
    VSUB.F32 S2, S2, S4       // S2 == delta = e - ecc*sinf(e) - m

    VMUL.F32 S10, S1, S6      // S10 == ecc*cosf(e)
    VMOV S8, 1.0
    VSUB.F32 S10, S8, S10     // S10 == (1.0 - ecc*cosf(e))
    VDIV.F32 S10, S2, S10     // S10 == delta/(1.0 - ecc*cosf(e))
    VSUB.F32 S3, S3, S10     // S3 == e = e - delta/(1.0 - ecc*cosf(e))

    VABS.F32 S7, S2           // fabsf(delta)
    VLDR S8, epsilon          // S8 == EPSILON == 1E-6

    VCMP.F32 S7, S8           // fabsf(delta) > EPSILON ?
    VMRS APSR_nzcv, FPSCR     //MOVE FLAGS TO MAIN PROCESSOR?

    //continue condition
    BGT loop
    //else
    VMOV S0, S3               // S0 == S3 == e
    POP { R4, PC }


.align
epsilon:
.float 1E-6

.end
