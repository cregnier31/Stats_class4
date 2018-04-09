FUNCTION find_indice,boite,zone

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; Choix de la zone
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      CASE zone OF
 	 'BALTIC': BEGIN
	   INDICE=WHERE(boite GE 3110 AND boite LE 3120,COUNT)
	 ENDCASE 
	 'NORDSEA':BEGIN
	   INDICE1=WHERE(boite GE 3090 AND boite LE 3100,COUNT)
	   INDICE2=WHERE(boite EQ 3190, COUNT)
	   INDICE=[INDICE1,INDICE2]
	 ENDCASE
	 'FACADE':BEGIN
	    INDICE1=WHERE(boite EQ 3180, COUNT)  
	    INDICE2=WHERE(boite GE 3200 AND boite LE 3230,COUNT)
	    INDICE3=WHERE(boite GE 3330 AND boite LE 3340,COUNT)
	    INDICE=[INDICE1,INDICE2,INDICE3]
         ENDCASE
         'GS1_3250':BEGIN
;; Boite Gulf stream Box near the coast under florida
            INDICE=WHERE(boite EQ 3250)
         ENDCASE
         'GS2_3260':BEGIN
;; Gulf stream Box off florida
            INDICE=WHERE(boite EQ 3260)
         ENDCASE
         'GS3_3270':BEGIN
;; Gulf stream off florida
            INDICE=WHERE(boite EQ 3270)
         ENDCASE
         'GS4_3280':BEGIN
;; Gulf stream off florida
            INDICE=WHERE(boite EQ 3280)
         ENDCASE
         'GS5_3290':BEGIN
;; Gulf stream off florida
            INDICE=WHERE(boite EQ 3290)
         ENDCASE
         'GS6_3300':BEGIN
;; Gulf stream off florida
            INDICE=WHERE(boite EQ 3300)
         ENDCASE
         'GS7_2260':BEGIN
;; Atl tropical zone
            INDICE=WHERE(boite EQ 2260)
         ENDCASE
         'GS8_1180':BEGIN
;; Atl tropical zone
            INDICE=WHERE(boite EQ 1180)
         ENDCASE
         'ATL':BEGIN
      ;; Atlantique 2000 à 4000
            INDICE=WHERE(boite GE 2000 AND boite LT 4000, COUNT)
         ENDCASE
         'NAT':BEGIN
      ;; Atlantique NORD 3000 à 4000
            ;INDICE=WHERE(boite GE 3000 AND boite LT 4000, COUNT)
            INDICE=WHERE(boite GE 3000 AND boite LT 3450, COUNT)
         ENDCASE
         'SAT':BEGIN
      ;; Atlantique SUD 2000 à 3000
            INDICE=WHERE(boite GE 2000 AND boite LT 3000, COUNT)
         ENDCASE
         'MED':BEGIN
      ;; MED 1000 à 1220
            INDICE=WHERE(boite GE 1000 AND boite LE 1220, COUNT)
         ENDCASE
         'IND':BEGIN
      ;; Indien de 6000 à 6770
      ;;      INDICE=WHERE(boite GE 6000 AND boite LE 6770, COUNT)   
           INDICE=WHERE(boite GE 6190 AND boite LE 6770, COUNT)   
         ENDCASE
         'NPA':BEGIN
      ;; Pacifique nord 5000 à 6000
            INDICE=WHERE(boite GE 5000 AND boite LT 6000, COUNT)
         ENDCASE
         'SPA':BEGIN
      ;; Pacifique sud et trop de 4000  à 4730
            INDICE=WHERE(boite GE 4000 AND boite LE 4730, COUNT)
         ENDCASE
         'ACC': BEGIN
      ;; 'ACC antartique 4770-4800'
          INDICE1=WHERE(boite GE 4610 AND boite LE 4900, COUNT) ;; Pacifique
          INDICE2=WHERE(boite GE 2050 AND boite LE 2110, COUNT) ;; Atlantique
          INDICE3=WHERE(boite GE 6000 AND boite LE 6070, COUNT) ;; Indien
          INDICE=[INDICE1,INDICE2,INDICE3] 
       ENDCASE
         'ARC': BEGIN
      ;; 'ARC arctique 7000-7200 '
          INDICE1=WHERE(boite GE 3000 AND boite LE 3200, COUNT) 
          INDICE2=WHERE(boite GE 7000 AND boite LE 7200, COUNT)
	  INDICE=[INDICE1,INDICE2]
       ENDCASE
         'TAT': BEGIN
      ;; TAT 2120-2360 ; 3440-3790 ; 30N-30S
      ;;    INDICE1=WHERE(boite GE 2120 AND boite LE 2360, COUNT)
      ;;    INDICE2=WHERE(boite GE 3440 AND boite LE 3790, COUNT)
      ;;    INDICE=[INDICE1,INDICE2]
      ; TAT  20N-20S
          INDICE1=WHERE(boite GE 2120 AND boite LE 2310, COUNT)
          INDICE2=WHERE(boite GE 3590 AND boite LE 3790, COUNT)
          INDICE=[INDICE1,INDICE2]
      
       ENDCASE
	'TAT_WEST':BEGIN
	   INDICE1=WHERE(boite GE 2120 AND boite LE 2130,COUNT)
	   INDICE2=WHERE(boite GE 2200,COUNT)
	   INDICE3=WHERE(boite GE 2210,COUNT)
	   INDICE4=WHERE(boite GE 2240 AND boite LE 2250,COUNT)
	   INDICE5=WHERE(boite GE 2280 AND boite LE 2290,COUNT)
	   INDICE6=WHERE(boite GE 3590,COUNT)
	   INDICE7=WHERE(boite GE 3610 AND boite LE 3630,COUNT)
	   INDICE8=WHERE(boite GE 3660 AND boite LE 3680,COUNT)
	   INDICE9=WHERE(boite GE 3710 AND boite LE 3730,COUNT)
           INDICE=[INDICE1,INDICE2,INDICE3,INDICE4,INDICE5,INDICE6,INDICE7,INDICE8,INDICE9]
	ENDCASE

	'TAT_EST':BEGIN
	   INDICE1=WHERE(boite GE 2140 AND boite LE 2190,COUNT)
	   INDICE2=WHERE(boite GE 2210,COUNT)
	   INDICE3=WHERE(boite GE 2230,COUNT)
	   INDICE4=WHERE(boite GE 2260 AND boite LE 2270,COUNT)
	   INDICE5=WHERE(boite GE 2300 AND boite LE 2310,COUNT)
           INDICE6=WHERE(boite GE 3600,COUNT)
           INDICE7=WHERE(boite GE 3640 AND boite LE 3650,COUNT)
           INDICE8=WHERE(boite GE 3690 AND boite LE 3700,COUNT)
           INDICE9=WHERE(boite GE 3740 AND boite LE 3790,COUNT)
           INDICE=[INDICE1,INDICE2,INDICE3,INDICE4,INDICE5,INDICE6,INDICE7,INDICE8,INDICE9]
        ENDCASE
       'MED_EST':BEGIN
           INDICE1=WHERE(boite GE 1080 AND boite LE 1110, COUNT)
           INDICE2=WHERE(boite GE 1130 AND boite LE 1500, COUNT)
           INDICE=[INDICE1,INDICE2]
        ENDCASE
       'MED_WEST':BEGIN
           INDICE1=WHERE(boite GE 1000 AND boite LE 1070, COUNT)
	   INDICE2=WHERE(boite GE 1120,COUNT)
           INDICE=[INDICE1,INDICE2]
        ENDCASE

        'TPA': BEGIN
      ;; TPA 4000-4530 ; 5260-5880 ; 30N-30S
      ;;    INDICE1=WHERE(boite GE 4000 AND boite LE 4530, COUNT)
      ;;    INDICE2=WHERE(boite GE 5260 AND boite LE 5880, COUNT)
      ;;    INDICE=[INDICE1,INDICE2]
          INDICE1=WHERE(boite GE 4000 AND boite LE 4530, COUNT)
          INDICE2=WHERE(boite GE 5430 AND boite LE 5880, COUNT)
          INDICE=[INDICE1,INDICE2]
       ENDCASE
        'Golf_stream':BEGIN
      ;; golf stream
      ;INDICE=WHERE(boite EQ 3310, COUNT)
      ;;INDICE=WHERE(boite GE 3260 AND boite LE 3280, COUNT)   ENDCASE
         INDICE=WHERE(boite GE 3250 AND boite LE 3280, COUNT)
         ;;FIND=WHERE(boite GE 3280 AND boite LE 3300, COUNT)
        ENDCASE
        'GLO':BEGIN
      ;; GLOBAL
           INDICE=WHERE(boite GE 0, COUNT)
        ENDCASE
        'ATL12':BEGIN
      ;; GLOBAL ATL12
           INDICE=WHERE(boite GE 0, COUNT)
        ENDCASE
        ELSE:
           ;print ,'Zone non reconnue'
           ;exit,/NO_CONFIRM
         ENDCASE

         RETURN, INDICE
END
