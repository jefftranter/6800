EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr USLetter 11000 8500
encoding utf-8
Sheet 5 6
Title "6800 SIngle Board Computer"
Date "2022-02-07"
Rev "0.1"
Comp "Jeff Tranter"
Comment1 ""
Comment2 "CPU, RAM, ROM"
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L Device:C C25
U 1 1 61EF4899
P 2000 5050
F 0 "C25" H 2115 5096 50  0000 L CNN
F 1 "30 pF" H 2115 5005 50  0000 L CNN
F 2 "Capacitor_THT:C_Disc_D5.0mm_W2.5mm_P5.00mm" H 2038 4900 50  0001 C CNN
F 3 "~" H 2000 5050 50  0001 C CNN
	1    2000 5050
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR058
U 1 1 61EF489F
P 2000 5200
F 0 "#PWR058" H 2000 4950 50  0001 C CNN
F 1 "GND" H 2005 5027 50  0000 C CNN
F 2 "" H 2000 5200 50  0001 C CNN
F 3 "" H 2000 5200 50  0001 C CNN
	1    2000 5200
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR057
U 1 1 61EF48A5
P 1700 5200
F 0 "#PWR057" H 1700 4950 50  0001 C CNN
F 1 "GND" H 1705 5027 50  0000 C CNN
F 2 "" H 1700 5200 50  0001 C CNN
F 3 "" H 1700 5200 50  0001 C CNN
	1    1700 5200
	1    0    0    -1  
$EndComp
Wire Wire Line
	2350 4650 2000 4650
$Comp
L power:GND #PWR056
U 1 1 61EF48B3
P 2850 5050
F 0 "#PWR056" H 2850 4800 50  0001 C CNN
F 1 "GND" H 2855 4877 50  0000 C CNN
F 2 "" H 2850 5050 50  0001 C CNN
F 3 "" H 2850 5050 50  0001 C CNN
	1    2850 5050
	1    0    0    -1  
$EndComp
$Comp
L Memory_EPROM:27128 U20
U 1 1 61DA2B2B
P 9200 3350
F 0 "U20" H 9200 3350 50  0000 C CNN
F 1 "27128" H 9250 3250 50  0000 C CNN
F 2 "Package_DIP:DIP-28_W15.24mm" H 9200 3350 50  0001 C CNN
F 3 "http://eeshop.unl.edu/pdf/27128.pdf" H 9200 3350 50  0001 C CNN
	1    9200 3350
	1    0    0    -1  
$EndComp
Text GLabel 3450 2450 2    50   Output ~ 0
A0
Text GLabel 2250 2450 0    50   BiDi ~ 0
D0
Text GLabel 2250 2550 0    50   BiDi ~ 0
D1
Text GLabel 2250 2650 0    50   BiDi ~ 0
D2
Text GLabel 2250 2750 0    50   BiDi ~ 0
D3
Text GLabel 2250 2850 0    50   BiDi ~ 0
D4
Text GLabel 2250 2950 0    50   BiDi ~ 0
D5
Connection ~ 2000 4750
Wire Wire Line
	2000 4750 2000 4650
Wire Wire Line
	2000 4900 2000 4750
Wire Wire Line
	1700 4550 1700 4750
Connection ~ 1700 4750
Wire Wire Line
	1700 4550 2350 4550
Wire Wire Line
	1700 4900 1700 4750
$Comp
L Device:C C24
U 1 1 61EF4893
P 1700 5050
F 0 "C24" H 1586 5004 50  0000 R CNN
F 1 "30 pF" H 1586 5095 50  0000 R CNN
F 2 "Capacitor_THT:C_Disc_D5.0mm_W2.5mm_P5.00mm" H 1738 4900 50  0001 C CNN
F 3 "~" H 1700 5050 50  0001 C CNN
	1    1700 5050
	1    0    0    1   
$EndComp
$Comp
L Device:Crystal Y2
U 1 1 61EF488D
P 1850 4750
F 0 "Y2" H 1400 4800 50  0000 C CNN
F 1 "3.579545 kHz" H 1400 4700 50  0000 C CNN
F 2 "Crystal:Crystal_HC18-U_Vertical" H 1850 4750 50  0001 C CNN
F 3 "~" H 1850 4750 50  0001 C CNN
	1    1850 4750
	1    0    0    -1  
$EndComp
Text GLabel 3450 2550 2    50   Output ~ 0
A1
Text GLabel 2250 3150 0    50   BiDi ~ 0
D7
Text GLabel 2250 3050 0    50   BiDi ~ 0
D6
$Comp
L CPU_NXP_6800:MC6802 U21
U 1 1 61EF4887
P 2850 3650
F 0 "U21" H 2850 4150 50  0000 C CNN
F 1 "MC6802" H 2850 4000 50  0000 C CNN
F 2 "Package_DIP:DIP-40_W15.24mm" H 2850 2150 50  0001 C CNN
F 3 "https://www.jameco.com/Jameco/Products/ProdDS/43502.pdf" H 2850 3650 50  0001 C CNN
	1    2850 3650
	1    0    0    -1  
$EndComp
Wire Wire Line
	3350 2450 3450 2450
Wire Wire Line
	3350 2550 3450 2550
Wire Wire Line
	2250 2450 2350 2450
Wire Wire Line
	2250 2550 2350 2550
Wire Wire Line
	2250 2650 2350 2650
Wire Wire Line
	2250 2750 2350 2750
Wire Wire Line
	2250 2850 2350 2850
Wire Wire Line
	2250 2950 2350 2950
Wire Wire Line
	2250 3050 2350 3050
Wire Wire Line
	2250 3150 2350 3150
Text GLabel 3450 2650 2    50   Output ~ 0
A2
Text GLabel 3450 2750 2    50   Output ~ 0
A3
Text GLabel 3450 2850 2    50   Output ~ 0
A4
Text GLabel 3450 2950 2    50   Output ~ 0
A5
Text GLabel 3450 3050 2    50   Output ~ 0
A6
Text GLabel 3450 3150 2    50   Output ~ 0
A7
Text GLabel 3450 3250 2    50   Output ~ 0
A8
Text GLabel 3450 3350 2    50   Output ~ 0
A9
Text GLabel 3450 3450 2    50   Output ~ 0
A10
Text GLabel 3450 3550 2    50   Output ~ 0
A11
Text GLabel 3450 3650 2    50   Output ~ 0
A12
Text GLabel 3450 3750 2    50   Output ~ 0
A13
Text GLabel 3450 3850 2    50   Output ~ 0
A14
Text GLabel 3450 3950 2    50   Output ~ 0
A15
Wire Wire Line
	3350 2650 3450 2650
Wire Wire Line
	3350 2750 3450 2750
Wire Wire Line
	3350 2850 3450 2850
Wire Wire Line
	3350 2950 3450 2950
Wire Wire Line
	3350 3050 3450 3050
Wire Wire Line
	3350 3150 3450 3150
Wire Wire Line
	3350 3250 3450 3250
Wire Wire Line
	3350 3350 3450 3350
Wire Wire Line
	3350 3450 3450 3450
Wire Wire Line
	3350 3550 3450 3550
Wire Wire Line
	3350 3650 3450 3650
Wire Wire Line
	3350 3750 3450 3750
Wire Wire Line
	3350 3850 3450 3850
Wire Wire Line
	3350 3950 3450 3950
Text GLabel 3450 4250 2    50   Output ~ 0
VMA
Wire Wire Line
	3350 4250 3450 4250
Text GLabel 3450 4150 2    50   Output ~ 0
BA
Text GLabel 3450 4350 2    50   Output ~ 0
R~W
Text GLabel 3450 4550 2    50   Output ~ 0
E
Wire Wire Line
	3350 4150 3450 4150
Wire Wire Line
	3350 4350 3450 4350
Wire Wire Line
	3350 4550 3450 4550
Text GLabel 2250 3350 0    50   Input ~ 0
MR
Text GLabel 2250 3550 0    50   Input ~ 0
~RESET
Text GLabel 2250 3650 0    50   Input ~ 0
~NMI
Text GLabel 2250 3750 0    50   Input ~ 0
~HALT
Text GLabel 2250 3850 0    50   Input ~ 0
~IRQ
Wire Wire Line
	2250 3550 2350 3550
Wire Wire Line
	2250 3350 2350 3350
Wire Wire Line
	2250 3650 2350 3650
Wire Wire Line
	2250 3750 2350 3750
Wire Wire Line
	2250 3850 2350 3850
$Comp
L power:VCC #PWR051
U 1 1 61DEF516
P 2950 2250
F 0 "#PWR051" H 2950 2100 50  0001 C CNN
F 1 "VCC" H 2967 2423 50  0000 C CNN
F 2 "" H 2950 2250 50  0001 C CNN
F 3 "" H 2950 2250 50  0001 C CNN
	1    2950 2250
	1    0    0    -1  
$EndComp
Wire Wire Line
	2750 2250 2950 2250
Connection ~ 2950 2250
Text GLabel 9800 2450 2    50   Input ~ 0
D0
Text GLabel 9800 2550 2    50   Input ~ 0
D1
Text GLabel 9800 2650 2    50   Input ~ 0
D2
Text GLabel 9800 2750 2    50   Input ~ 0
D3
Text GLabel 9800 2850 2    50   Input ~ 0
D4
Text GLabel 9800 2950 2    50   Input ~ 0
D5
Text GLabel 9800 3050 2    50   Input ~ 0
D6
Text GLabel 9800 3150 2    50   Input ~ 0
D7
Text GLabel 8600 2450 0    50   Input ~ 0
A0
Wire Wire Line
	9600 2450 9800 2450
Wire Wire Line
	9600 2550 9800 2550
Wire Wire Line
	9600 2650 9800 2650
Wire Wire Line
	9600 2750 9800 2750
Wire Wire Line
	9600 2850 9800 2850
Wire Wire Line
	9600 2950 9800 2950
Wire Wire Line
	9600 3050 9800 3050
Wire Wire Line
	9600 3150 9800 3150
Wire Wire Line
	8600 2450 8800 2450
Text GLabel 8600 2550 0    50   Input ~ 0
A1
Text GLabel 8600 2650 0    50   Input ~ 0
A2
Text GLabel 8600 2750 0    50   Input ~ 0
A3
Text GLabel 8600 2850 0    50   Input ~ 0
A4
Text GLabel 8600 2950 0    50   Input ~ 0
A5
Text GLabel 8600 3050 0    50   Input ~ 0
A6
Text GLabel 8600 3150 0    50   Input ~ 0
A7
Text GLabel 8600 3250 0    50   Input ~ 0
A8
Text GLabel 8600 3350 0    50   Input ~ 0
A9
Text GLabel 8600 3450 0    50   Input ~ 0
A10
Text GLabel 8600 3550 0    50   Input ~ 0
A11
Text GLabel 8600 3650 0    50   Input ~ 0
A12
Text GLabel 8600 3750 0    50   Input ~ 0
A13
$Comp
L power:VCC #PWR053
U 1 1 61E0515C
P 8600 3950
F 0 "#PWR053" H 8600 3800 50  0001 C CNN
F 1 "VCC" V 8618 4077 50  0000 L CNN
F 2 "" H 8600 3950 50  0001 C CNN
F 3 "" H 8600 3950 50  0001 C CNN
	1    8600 3950
	0    -1   -1   0   
$EndComp
Wire Wire Line
	8600 3950 8700 3950
Text GLabel 8600 4150 0    50   Input ~ 0
~ROMEN
Wire Wire Line
	8600 2550 8800 2550
Wire Wire Line
	8600 4150 8800 4150
Wire Wire Line
	8600 2650 8800 2650
Wire Wire Line
	8600 2750 8800 2750
Wire Wire Line
	8600 2850 8800 2850
Wire Wire Line
	8600 2950 8800 2950
Wire Wire Line
	8600 3050 8800 3050
Wire Wire Line
	8600 3150 8800 3150
Wire Wire Line
	8600 3250 8800 3250
Wire Wire Line
	8600 3350 8800 3350
Wire Wire Line
	8600 3450 8800 3450
Wire Wire Line
	8600 3550 8800 3550
Wire Wire Line
	8600 3650 8800 3650
Wire Wire Line
	8600 3750 8800 3750
Text GLabel 8600 4250 0    50   Input ~ 0
~READ
Wire Wire Line
	8600 4250 8800 4250
$Comp
L Memory_RAM:CY62256-70PC U19
U 1 1 61DA8011
P 6000 3200
F 0 "U19" H 6000 3600 50  0000 C CNN
F 1 "62256 RAM" H 6000 3450 50  0000 C CNN
F 2 "Package_DIP:DIP-28_W15.24mm" H 6000 3100 50  0001 C CNN
F 3 "https://ecee.colorado.edu/~mcclurel/Cypress_SRAM_CY62256.pdf" H 6000 3100 50  0001 C CNN
	1    6000 3200
	1    0    0    -1  
$EndComp
Text GLabel 5300 2500 0    50   Input ~ 0
A0
Text GLabel 5300 2600 0    50   Input ~ 0
A1
Text GLabel 5300 2700 0    50   Input ~ 0
A2
Text GLabel 5300 2800 0    50   Input ~ 0
A3
Text GLabel 5300 2900 0    50   Input ~ 0
A4
Text GLabel 5300 3000 0    50   Input ~ 0
A5
Text GLabel 5300 3100 0    50   Input ~ 0
A6
Text GLabel 5300 3200 0    50   Input ~ 0
A7
Text GLabel 5300 3300 0    50   Input ~ 0
A8
Text GLabel 5300 3400 0    50   Input ~ 0
A9
Text GLabel 5300 3500 0    50   Input ~ 0
A10
Text GLabel 5300 3600 0    50   Input ~ 0
A11
Text GLabel 5300 3700 0    50   Input ~ 0
A12
Text GLabel 5300 3800 0    50   Input ~ 0
A13
Text GLabel 5300 3900 0    50   Input ~ 0
A14
Text GLabel 6800 2500 2    50   BiDi ~ 0
D0
Text GLabel 6800 2600 2    50   BiDi ~ 0
D1
Text GLabel 6800 2700 2    50   BiDi ~ 0
D2
Text GLabel 6800 2800 2    50   BiDi ~ 0
D3
Text GLabel 6800 2900 2    50   BiDi ~ 0
D4
Text GLabel 6800 3000 2    50   BiDi ~ 0
D5
Text GLabel 6800 3100 2    50   BiDi ~ 0
D6
Text GLabel 6800 3200 2    50   BiDi ~ 0
D7
Text GLabel 6800 3400 2    50   Input ~ 0
~RAMEN
Text GLabel 6800 3600 2    50   Input ~ 0
~READ
Text GLabel 6800 3700 2    50   Input ~ 0
~WRITE
$Comp
L power:GND #PWR054
U 1 1 61E46461
P 6000 4200
F 0 "#PWR054" H 6000 3950 50  0001 C CNN
F 1 "GND" H 6005 4027 50  0000 C CNN
F 2 "" H 6000 4200 50  0001 C CNN
F 3 "" H 6000 4200 50  0001 C CNN
	1    6000 4200
	1    0    0    -1  
$EndComp
$Comp
L power:VCC #PWR050
U 1 1 61E46926
P 6000 2200
F 0 "#PWR050" H 6000 2050 50  0001 C CNN
F 1 "VCC" H 6017 2373 50  0000 C CNN
F 2 "" H 6000 2200 50  0001 C CNN
F 3 "" H 6000 2200 50  0001 C CNN
	1    6000 2200
	1    0    0    -1  
$EndComp
Wire Wire Line
	6000 2200 6000 2300
Wire Wire Line
	6000 4100 6000 4200
Wire Wire Line
	6500 2500 6800 2500
Wire Wire Line
	6500 2600 6800 2600
Wire Wire Line
	6500 2700 6800 2700
Wire Wire Line
	6500 2800 6800 2800
Wire Wire Line
	6500 2900 6800 2900
Wire Wire Line
	6500 3000 6800 3000
Wire Wire Line
	6500 3100 6800 3100
Wire Wire Line
	6500 3200 6800 3200
Wire Wire Line
	6500 3400 6800 3400
Wire Wire Line
	6500 3600 6800 3600
Wire Wire Line
	6500 3700 6800 3700
Wire Wire Line
	5300 2500 5500 2500
Wire Wire Line
	5300 2600 5500 2600
Wire Wire Line
	5300 2700 5500 2700
Wire Wire Line
	5300 2800 5500 2800
Wire Wire Line
	5300 2900 5500 2900
Wire Wire Line
	5300 3000 5500 3000
Wire Wire Line
	5300 3100 5500 3100
Wire Wire Line
	5300 3200 5500 3200
Wire Wire Line
	5300 3300 5500 3300
Wire Wire Line
	5300 3400 5500 3400
Wire Wire Line
	5300 3500 5500 3500
Wire Wire Line
	5300 3600 5500 3600
Wire Wire Line
	5300 3700 5500 3700
Wire Wire Line
	5300 3800 5500 3800
Wire Wire Line
	5300 3900 5500 3900
$Comp
L power:GND #PWR055
U 1 1 61EA2EC1
P 9200 4550
F 0 "#PWR055" H 9200 4300 50  0001 C CNN
F 1 "GND" H 9205 4377 50  0000 C CNN
F 2 "" H 9200 4550 50  0001 C CNN
F 3 "" H 9200 4550 50  0001 C CNN
	1    9200 4550
	1    0    0    -1  
$EndComp
Wire Wire Line
	9200 4550 9200 4450
$Comp
L power:VCC #PWR049
U 1 1 61EA8E72
P 9200 2150
F 0 "#PWR049" H 9200 2000 50  0001 C CNN
F 1 "VCC" H 9217 2323 50  0000 C CNN
F 2 "" H 9200 2150 50  0001 C CNN
F 3 "" H 9200 2150 50  0001 C CNN
	1    9200 2150
	1    0    0    -1  
$EndComp
Wire Wire Line
	9200 2150 9200 2250
Text Notes 2700 1800 0    118  ~ 0
CPU
Text Notes 5700 1800 0    118  ~ 0
RAM (32K)
Text Notes 8650 1800 0    118  ~ 0
ROM (16K)
$Comp
L power:GND #PWR052
U 1 1 61F45D94
P 2350 3450
F 0 "#PWR052" H 2350 3200 50  0001 C CNN
F 1 "GND" V 2355 3322 50  0000 R CNN
F 2 "" H 2350 3450 50  0001 C CNN
F 3 "" H 2350 3450 50  0001 C CNN
	1    2350 3450
	0    1    1    0   
$EndComp
Wire Wire Line
	8800 4050 8700 4050
Wire Wire Line
	8700 4050 8700 3950
Connection ~ 8700 3950
Wire Wire Line
	8700 3950 8800 3950
$EndSCHEMATC
