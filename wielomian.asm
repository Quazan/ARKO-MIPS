	.data
buf: 	.space 4
offset: .space 4
size: 	.space 4
width: 	.space 4
height:	.space 4
start:	.space 4
a:	.space 4
b:	.space 4
c:	.space 4
d:	.space 4

Info:	.asciiz "Rysowanie wielomianu trzeciego stopnia.\n"
Data:	.asciiz "Podaj wspolczynniki a, b, c, d\n"
Error:	.asciiz "Blad pliku\n"
In:	.asciiz "in.bmp"
Out:	.asciiz "out.bmp"

	.text
	.globl main	
main:
	#wyswietlenie informacji poczatkowej
	la $a0, Info
	li $v0, 4
	syscall
	
read:
	#otwieramy in.bmp
	la $a0, In
	li $a1, 0
	li $a2, 0
	li $v0, 13
	syscall
	
	move $t0, $v0	#deskryptor pliku
	bltz $t0, Error	
	
	#odczytanie 2 bajtow 'BM' z naglowka
	move $a0, $t0
	la $a1, buf
	li $a2, 2
	li $v0, 14  
	syscall	
	
	#nastepne 4 bajty to rozmiar pliku
	move $a0, $t0
	la $a1, size
	li $a2, 4
	li $v0, 14
	syscall
	
	lw $s0, size
	
	#alokacja pamieci na dane
	move $a0, $s0
	li $v0, 9
	syscall
	
	#adres zaalokowanej pamieci
	move $s1, $v0
	sw $s1, start
	
	#odczytujemy 4 kolejne bajty, nie bedziemy ich potrzebowac
	move $a0, $t0
	la $a1, buf
	li $a2, 4
	li $v0, 14
	syscall
	
	#czytanie offsetu
	move $a0, $t0
	la $a1, offset
	li $a2, 4
	li $v0, 14
	syscall
	
	#odczytanie 4 bajtow naglowka informacyjnego
	move $a0, $t0
	la $a1, buf
	li $a2, 4
	li $v0, 14
	syscall
	
	#odczytanie szerokosci obrazka
	move $a0, $t0
	la $a1, width
	li $a2, 4
	li $v0, 14
	syscall
	lw $s2, width

	#odczytanie wysokosci obrazka
	move $a0, $t0
	la $a1, height
	li $a2, 4
	li $v0, 14
	syscall
	lw $s3, height
	
	#zamkniecie pliku wejsciowego
	move $a0, $t0
	li $v0, 16
	syscall
	
readPixels:
	# wczytuje tablice pikseli pod adres zaalokowanej pamieci w $s1
	la $a0, In
	la $a1, 0
	la $a2, 0
	li $v0, 13
	syscall

	move $t0, $v0	#deskryptor pliku
	bltz $t0, Error		
	
	move $a0, $t0
	la $a1, ($s1)	#start
	la $a2, ($s0)	#size
	li $v0, 14
	syscall
	
	#zamkniecie pliku
	move $a0, $t0
	li $v0, 16
	syscall
	
	#czytamy parametry od uzytkownika
	#24 bity na czêœæ u³amkow¹ i 8 na ca³kowit¹
getData: 
	la $a0, Data
	li $v0, 4
	syscall
	li $v0, 5 
	syscall
	sll $v0, $v0, 24
	sw $v0, a
	
	li $v0, 5
	syscall
	sll $v0, $v0, 24
	sw $v0, b

	li $v0, 5 
	syscall
	sll $v0, $v0, 24
	sw $v0, c
	
	li $v0, 5 
	syscall
	sll $v0, $v0, 24
	sw $v0, d

set:
	li $s4, 0xfe000000 #wartosc minimalna (-2)
	li $s5, 0 #licznik
	
	#wysokoœæ/2
	srl $s6, $s3, 1

	#padding
	sll $t0, $s2, 1
	add $t0, $t0, $s2
	andi $s7, $t0, 0x03
		
loop:
	lw $t2, a
	lw $t3, b
	lw $t4, c
	lw $t5, d
	
	#obliczamy ax^3
	move $t0, $t2
	mult $t0, $s4
	mfhi $t6
	mflo $t7
	sll $t6, $t6, 8
	srl $t7, $t7 24
	or $t0, $t6, $t7
	
	mult $t0, $s4
	mfhi $t6
	mflo $t7
	sll $t6, $t6, 8
	srl $t7, $t7 24
	or $t0, $t6, $t7
	
	mult $t0, $s4
	mfhi $t6
	mflo $t7
	sll $t6, $t6, 8
	srl $t7, $t7 24
	or $t0, $t6, $t7
	
	#obliczamy bx^2
	mult $t3, $s4
	mfhi $t6
	mflo $t7
	sll $t6, $t6, 8
	srl $t7, $t7 24
	or $t3, $t6, $t7 
	
	mult $t3, $s4
	mfhi $t6
	mflo $t7
	sll $t6, $t6, 8
	srl $t7, $t7 24
	or $t3, $t6, $t7 
	
	#obliczamy cx
	mult $t4, $s4
	mfhi $t6
	mflo $t7
	sll $t6, $t6, 8
	srl $t7, $t7 24
	or $t4, $t6, $t7
	
	#dodajemy do siebie wszystkie sk³adniki
	addu $t0, $t0, $t3
	addu $t0, $t0, $t4
	addu $t0, $t0, $t5
	
	sra $t0, $t0, 16
	move $t1, $s5
	addi $s4, $s4, 0x00010000 #1/256
	addi $s5, $s5, 1 #nastepny pixel
	bgt $t0, 511, loop 
	blt $t0, -512, loop #wartoœæ "wysz³a" poza rysunek
	add $t0, $t0, $s6 
	
change:
	#s0 - offset
	#s1 - start
	#s2 - width
	#s3 - height
	#s4 - pozycja x
	#s5 - licznik
	#s6 - height/2
	#s7 - padding
	
	lw $s1, start
	lw $s0, offset
	addu $s1, $s1, $s0
	
	#wyznaczanie y pixela
	sll $t2, $s2, 1
	add $t2, $t2, $s2 
	mul $t2, $t2, $t0
	addu $s1, $s1, $t2
	
	#wyznaczanie x pixela
	move $t9, $t1
	sll $t1, $t1, 1
	add $t1, $t1, $t9 
	addu $s1, $s1, $t1
	
	#padding
	mul $t2, $t0, $s7
	addu $s1, $s1, $t2
	
	#kolorowanie pixeli
	li $t2, 0xff
	sb $t2, ($s1)
	addi $s1, $s1, 1
	li $t2, 0x00
	sb $t2, ($s1)
	addi $s1, $s1, 1
	sb $t2, ($s1)
	addi $s1, $s1, 1
	
	blt $s5, $s2, loop
	
save:
	#zapisujemy nowy obraz bmp
	la $a0, Out
	li $a1, 1
	li $a2, 0
	li $v0, 13
	syscall
	
	move $t0, $v0	#deskryptor pliku
	bltz $t0, fileError		

	lw $s0, size
	lw $s1, start
	
	#zapisujemy do pliku
	move $a0, $t0
	la $a1, ($s1)
	la $a2, ($s0)
	li $v0, 15 
	syscall
	
	#zamykamy plik
	move $a0, $t0
	li $v0, 16 
	syscall 
	
exit:
	li $v0, 10
	syscall
	
fileError:
	la $a0, Error
	li $v0, 4
	syscall
	b exit
