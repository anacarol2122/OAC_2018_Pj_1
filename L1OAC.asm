.data
	
	
	filename: .asciiz "/home/ana/Documentos/OAC 22018/img.bmp"
	mensagem_inicial: .asciiz "Qual o nome do arquivo da imagem?"
	mensagem_inicial2: .asciiz "Sua imagem possui largura:\n"
	mensagem_inicial3: .asciiz "\nSua imagem possui altura:\n"
	mensagem_inicial4: .asciiz "\nAbra o btmap display, ajuste as dimensões e o direcione para memoria heap. Quando terminar precione enter.\n"
	mensagem_menu1: .asciiz "Qual efeito voce gostaria de realizar na imagem?\n1-Efeito de borramento\n2-Efeito de extração de bordas\n3-Efeito de binarização por limiar\n"
	mensagem_menu1_2: .asciiz "Qual a mascara usar para o efeito?\n1-Horizontal\n2-Vertical\n3-Cruz\n4-Quadrado 3x3\n"
	mensagem_menu1_2_1: .asciiz "Qual a intensidade do bytes R para a mascara?\n"
	mensagem_menu1_2_2: .asciiz "Qual a intensidade do bytes G para a mascara?\n"
	mensagem_menu1_2_3: .asciiz "Qual a intensidade do bytes B para a mascara?\n"
	mensagem_menu2: .asciiz "Opcao incorreta. Tente novamente.\n"
	men: .space 2
	.align 2
	men1: .space 52
	vetorEdge0: .space 12
	vetorEdge1: .space 12
	vetorEdge2: .space 12
	pixel_image: .space 12
	result: .space 4
	buffer_extractor: .space  10240
	buffer_extractor2: .space 10240

.text

	#la $a0, mensagem_inicial
	#li $v0, 4
	#syscall
	#la $a0, filename
	#li $a1, 256
	#li $v0, 8
	#syscall
	
	la $a0, filename
	li $a1, 0
	jal open_file
	
	move $s0, $v0 #salva o descritor original do arquivo em $s0
	move $a0, $v0
	la $a1, men
	li $a2, 2
	jal read_file
	
	li $a2, 52
	la $a1, men1
	jal read_file
	
	#variaveis globais 
	lw $s1, 0($a1) # Tamanho do arquivo
	lw $s2, 8($a1) # Offset para comeÃ§o dos dados da imagem
	sub $s1, $s1, $s2 #tamanho da imagem em bytes
	lw $s3, 16($a1) # Largura da imagem em pixels
	lw $s4, 20($a1) # Altura da imagem em pixels 

	li $t2, 0x10040000 #Prepara o endereco da memoria heap para armazenar a imagem
	mul $t3, $s4, $s3
	mul $t3, $t3, 4
	add $t2, $t2, $t3 #Abrindo espaço para imagem (Arquivo comeca dos pixels inferiores)
	mul $t3, $s3, 4
	move $t0, $0
	
load_image:
	beq $t0, $s1, exit_load_image
	sub $t2, $t2, $t3
	move $t1, $0
	loop_load_image: 
		beq $t1, $s3, exit_loop_load_image
		li $a2, 3
		la $a1, men1
		jal read_file
	
		lw $t4, 0($a1)
		sw $t4, 0($t2)
		addi $t0, $t0, 3 
		addi $t2, $t2, 4
		addi $t1, $t1, 1
		j loop_load_image
	exit_loop_load_image:
		sub $t2, $t2, $t3
		j load_image
exit_load_image:  
	move $a0, $s0
	jal close_file
	li $a0, 0x10040000
	move $a1, $s1 
	jal save_original_image
	jal menu
	#move $a0, $fp
	#move $a1, $s1
	#jal Edge_detector
	j exit
	 

	
open_file: #Funcao abre arquivo que recebe como argumento em $a0 o endereÃ§o onde esta armazenado o 
	# nome do arquivo e em $a1 a flag (0 - read, 1-write) e retorna em $v0 0 descritor do arquivo.
	
	li $v0, 13
	li $a2, 0
	syscall
	jr $ra

read_file: #Funcao ler arquivo que recebe como argumento em $a0 o descritor do arquivo, em $a1 o endereÃ§o do buffer 
	# na memoria e em $a2 o numero de bytes a serem lidos e retorna em $v0 o numero de bytes lidos ou 0 caso final do arquivo.
	
	li $v0, 14
	syscall
	jr $ra
	
close_file:#Funcao fecha arquivo que recebe como argumento em $a0 o descritor do arquivo.
		
	li $v0, 16
	syscall
	jr $ra
exit: 
	li $v0, 10
	syscall 
		
	


save_original_image: #Funcao que recebe como parametros: 1) o endereço da memoria onde foi carregada a imagem em $a0(memoria heap 0x10040000)
#2) o tamanho da imagem em bytes em $a1($s1). Esta funcao decrementa $gp de acordo com o tamanho da imagem(largura*altura*4(word))pega 
#os bytes da imagem original carregada na memoria heap e salva na pilha depois carrega o valor de $gp em $fp e retorna $fp como uma 
#barreira para que demais procedimentos nao ultrapasse $fp e extravie os dados referentes a imagem original.

	add $t0, $0,$0
	move $t1, $a0 #Endereço da memoria heap
	
	#Decrementando a pilha com um tamanho da imagem
	move $t2, $sp
	div $t3, $a1, 3 #$a1/3 == Quantidade de pixels da imagem
	add $t3, $t3, $a1 #$t3 = 4vezes a quantidade de pixels(tamanho da imagem na memoria heap)(pois cada pixel possui 4 bytes, ou uma word)
	sub $sp, $sp, $t3 #Abre o espaço na pilha

	Loop_save_image:#Loop que carrega word da memoria heap e salva na pilha de cima para baixo
		beq $t0, $a1, end_save_original_image
		lw $t3, 0($t1)
		sw $t3, 0($t2)
		addi $t2, $t2, -4
		addi $t1, $t1, 4
		addi $t0, $t0, 3
		j Loop_save_image
end_save_original_image:
	move $fp, $sp #Carrega em $fp o limite onde começa os dados da imagem original na pilha
	jr $ra
#######################################################################################################################################

show_original_image: # Funcao que recebe como parametros: 1) O endereço de delimitador $fp da pila onde se encontra a imagem original em $a0
#2) o tamanho da imagem em bytes em $a1($s1). Esta funcao carrega a imagem original na memoria heap para ser mostrada no bitmap display


	move $t0, $a0
	
	#Soma o endereço de base da memoria heap com o tamanho da imagem original (abre espaço na memoria heap)
	li $t1, 0x10040000
	div $t2, $a1, 3
	add $t2, $t2, $a1
	add $t1, $t1, $t2
	move $t2, $zero
	Loop_show_image: #Loop que desempilha os pixels de tras pra frente e ja carrega na posicao correta na memoria heap
		beq $t2, $a1, exit_show_original_image
		lw $t3, 0($t0)
		sw $t3, 0($t1)
		addi $t0, $t0, 4
		addi $t1, $t1, -4
		addi $t2, $t2, 3
		j Loop_show_image
exit_show_original_image:
		jr $ra

#######################################################################################################################################	
menu:

	la $a0, mensagem_menu1
	li $v0, 4
	syscall
	
	li $v0, 5
	syscall
	
  	li $t0, 1
  	li $t1, 2
  	li $t2, 3
  	bne $t0, $v0, nao_borramento
  	jal exit
  	nao_borramento:
  	bne $t1, $v0, nao_extracao
  	
  	la $a0, mensagem_menu1_2
	li $v0, 4
	syscall
	li $v0, 5
	syscall
	move $a0, $v0
	la $a0, mensagem_menu1_2_1
	li $v0, 4
	syscall
	li $v0, 5
	syscall
	move $a1, $v0
  	la $a0, mensagem_menu1_2_2
	li $v0, 4
	syscall
	li $v0, 5
	syscall
	move $a2, $v0
	la $a0, mensagem_menu1_2_3
	li $v0, 4
	syscall
	li $v0, 5
	syscall
	move $a3, $v0
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal Edge_Extractor
  	lw $ra, 0($sp)
  	addi $sp, $sp, 4
  	jr $ra
  	
	nao_extracao:
	bne $t2, $v0, opcao_errada
	jal exit
	opcao_errada:
	la $a0, mensagem_menu2
	li $v0, 4
	syscall
	j menu

####################################################################################################################################
Edge_Extractor: # Função recebe em $a0 o tipo de mascara, em $a1, $a2, $a3 as intencidades RGB dos pixels da mascara respectivamente

	#Empilhando todos os registradores salvos (Lembrar de desempilhar no final)
	addi $sp, $sp, -32
	sw $s0, 0($sp)
	sw $s1, 4($sp)	
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	sw $s4, 16($sp)
	sw $s5, 20($sp)
	sw $s6, 24($sp)
	sw $s7, 28($sp)

	move $s0, $s1 # $s0 = tamanho da imagem bytes
	move $s1, $s3 # $s1 = largura da imagem em pixels
	move $s2, $s4 # $s1 = altura da imagem em pixels
	
	la $s3, vetorEdge0
	la $s4, vetorEdge1
	la $s5, vetorEdge2
	
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $a0, 4($sp)
	sw $a1, 8($sp)
	move $a0, $fp
	move $a1, $s0
	jal show_original_image
	lw $a1, 8($sp)
	lw $a0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 12
	
	#preparando contadores da matriz
	move $t1, $0 #i
	move $t2, $0 #j
	addi $t3, $s1, -1 #Largura da imagem menos 1

	la $s7, pixel_image
	
	li $t9, 4
	beq $a0, $t9, Bquadrado 
	addi $t9, $t9, -1
	beq $a0, $t9, Bcruz
	addi $t9, $t9, -1
	beq $a0, $t9, Bvertical
#################################################################################################################################
Bhorizontal:
	
	Loop1_Bhorizontal:
		beq $t1, $s2, exit_loop1_Bhorizontal #Compara linhas (altura)
		la $s6, buffer_extractor
		Loop2_Bhorizontal:
			beq $t2, $s1, exit_loop2_Bhorizontal #Compara colunas (largura)
			
			bne $t2, $zero, nao_primeiro #Verifica se e o primeiro bit da linha
			
			li $t4, 255
			sb $t4, 0($s3)
			sb $t4, 0($s4)
			sb $t4, 0($s5)
			
			mul $t4, $t1, $s1 #linha vezes largura
			mul $t4, $t4, 4
			# add $t4, $t4, $t2 nao e necessário pois $t2==0
			
			li $t5, 0x10040000
			add $t5, $t5, $t4 #prepara o endereço do pixel na memoria heap
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo1_horizontal
			move $t4, $0
			nao_negativo1_horizontal: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo2_horizontal
			move $t4, $0
			nao_negativo2_horizontal: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo3_horizontal
			move $t4, $0
			nao_negativo3_horizontal: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo12_horizontal
			move $t4, $0
			nao_negativo12_horizontal: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo22_horizontal
			move $t4, $0
			nao_negativo22_horizontal: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo32_horizontal
			move $t4, $0
			nao_negativo32_horizontal: sb $t4, 2($s5)
			
			########################################################################################
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 3
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
		
			addi $t2, $t2, 1
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			j Loop2_Bhorizontal

			nao_primeiro:
			bne $t2, $t3, nao_ultimo #Verifica se o ultimo bit da linha
			
			li $t4, 255
			sb $t4, 2($s3)
			sb $t4, 2($s4)
			sb $t4, 2($s5)
			
			mul $t4, $t1, $s1 #linha vezes largura
			add $t4, $t4, $t2
			mul $t4, $t4, 4
			
			li $t5, 0x10040000
			add $t5, $t5, $t4 #prepara o endereço do pixel na memoria heap
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo4_horizontal
			move $t4, $0
			nao_negativo4_horizontal: sb $t4, 0($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo5_horizontal
			move $t4, $0
			nao_negativo5_horizontal: sb $t4, 0($s4)
			
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo6_horizontal
			move $t4, $0
			nao_negativo6_horizontal: sb $t4, 0($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo41_horizontal
			move $t4, $0
			nao_negativo41_horizontal: sb $t4, 1($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo51_horizontal
			move $t4, $0
			nao_negativo51_horizontal: sb $t4, 1($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo61_horizontal
			move $t4, $0
			nao_negativo61_horizontal: sb $t4, 1($s5)
			
			 ########################################################################################## 
			 
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 3
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
		
			addi $t2, $t2, 1
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
		
			j Loop2_Bhorizontal

			nao_ultimo:
			
			mul $t4, $t1, $s1 #linha vezes largura
			add $t4, $t4, $t2
			mul $t4, $t4, 4
			
			li $t5, 0x10040000
			add $t5, $t5, $t4 #prepara o endereço do pixel na memoria heap
			
			
			addi $t5, $t5, -4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo7_horizontal
			move $t4, $0
			nao_negativo7_horizontal: sb $t4, 0($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo8_horizontal
			move $t4, $0
			nao_negativo8_horizontal: sb $t4, 0($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo9_horizontal
			move $t4, $0
			nao_negativo9_horizontal: sb $t4, 0($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo71_horizontal
			move $t4, $0
			nao_negativo71_horizontal: sb $t4, 1($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo81_horizontal
			move $t4, $0
			nao_negativo81_horizontal: sb $t4, 1($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo91_horizontal
			move $t4, $0
			nao_negativo91_horizontal: sb $t4, 1($s5)
			
			 ########################################################################################## 
			 
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo72_horizontal
			move $t4, $0
			nao_negativo72_horizontal: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo82_horizontal
			move $t4, $0
			nao_negativo82_horizontal: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo92_horizontal
			move $t4, $0
			nao_negativo92_horizontal: sb $t4, 2($s5)
			
			#######################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 3
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
		
			addi $t2, $t2, 1
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			j Loop2_Bhorizontal
	
		exit_loop2_Bhorizontal:

			li $t5, 0x10040000
			mul $t4, $t1, $s1 #linha vezes largura
			mul $t4, $t4, 4
			add $t5, $t5, $t4

			move $t6, $0
			la $t7, buffer_extractor
		loop_carrega_linha:
			beq $t6, $s1, exit_loop_carrega_linha
			lw $t8, 0($t7)
			sw $t8, 0($t5)
			addi $t5, $t5, 4
			addi $t7, $t7, 4
			addi $t6, $t6, 1
			j loop_carrega_linha
		exit_loop_carrega_linha:
			move $t2, $0
			addi $t1, $t1, 1
					
			j Loop1_Bhorizontal
	
	exit_loop1_Bhorizontal:
	
		lw $s7, 28($sp)
		lw $s6, 24($sp)
		lw $s5, 20($sp)
		lw $s4, 16($sp)
		lw $s3, 12($sp)
		lw $s2, 8($sp)
		lw $s1, 4($sp)	
		lw $s0, 0($sp)
		addi $sp, $sp, 32
	
		j Exit_Edge_Extractor

#####################################################################################################################################

Bvertical:
	
	Loop1_Bvertical:
		beq $t1, $s2, exit_loop1_Bvertical #Compara linhas (altura)
		li $t4, 2
		div $t1, $t4
		mfhi $t4
		beq $t4, $zero, par
		la $s6, buffer_extractor
		j Loop2_Bvertical
		par:
		la $s6, buffer_extractor2
		
		Loop2_Bvertical:
			beq $t2, $s1, exit_loop2_Bvertical #Compara colunas (largura)
			
			bne $t1, $zero, nao_primeira_linha #Verifica se e o primeiro bit da linha
			
			
			li $t4, 255
			sb $t4, 0($s3)
			sb $t4, 0($s4)
			sb $t4, 0($s5)
			
			# mul $t4, $t1, $s1 #linha vezes largura nao precisa pois $t1==0
			add $t4, $0, $t2 
			mul $t4, $t4, 4
			
			
			li $t5, 0x10040000
			add $t5, $t5, $t4 #prepara o endereço do pixel na memoria heap
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo1_vertical
			move $t4, $0
			nao_negativo1_vertical: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo2_vertical
			move $t4, $0
			nao_negativo2_vertical: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo3_vertical
			move $t4, $0
			nao_negativo3_vertical: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			mul $t4, $s1, 4
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo11_vertical
			move $t4, $0
			nao_negativo11_vertical: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo21_vertical
			move $t4, $0
			nao_negativo21_vertical: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo31_vertical
			move $t4, $0
			nao_negativo31_vertical: sb $t4, 2($s5)
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 3
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
		
			addi $t2, $t2, 1
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			j Loop2_Bvertical
			
			nao_primeira_linha:
			bne $t1, $t3, nao_ultima_linha #Verifica se o ultimo bit da linha
			
			li $t4, 255
			sb $t4, 2($s3)
			sb $t4, 2($s4)
			sb $t4, 2($s5)
			
			mul $t4, $t1, $s1 #linha vezes largura nao precisa pois $t1==0
			add $t4, $t4, $t2 
			mul $t4, $t4, 4
			
			
			li $t5, 0x10040000
			add $t5, $t5, $t4 #prepara o endereço do pixel na memoria heap
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo4_vertical
			move $t4, $0
			nao_negativo4_vertical: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo5_vertical
			move $t4, $0
			nao_negativo5_vertical: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo6_vertical
			move $t4, $0
			nao_negativo6_vertical: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			mul $t4, $s1, 4
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo41_vertical
			move $t4, $0
			nao_negativo41_vertical: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo51_vertical
			move $t4, $0
			nao_negativo51_vertical: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo61_vertical
			move $t4, $0
			nao_negativo61_vertical: sb $t4, 2($s5)
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 3
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
		
			addi $t2, $t2, 1
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			j Loop2_Bvertical
		
	
			nao_ultima_linha:
			
			mul $t4, $t1, $s1 #linha vezes largura
			add $t4, $t4, $t2
			mul $t4, $t4, 4
			
			li $t5, 0x10040000
			add $t5, $t5, $t4 #prepara o endereço do pixel na memoria heap
			
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo7_vertical
			move $t4, $0
			nao_negativo7_vertical: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo8_vertical
			move $t4, $0
			nao_negativo8_vertical: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo9_vertical
			move $t4, $0
			nao_negativo9_vertical: sb $t4, 1($s5)
			 
			######################################################################################## 
			mul $t4, $s1, 4
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo71_vertical
			move $t4, $0
			nao_negativo71_vertical: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo81_vertical
			move $t4, $0
			nao_negativo81_vertical: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo91_vertical
			move $t4, $0
			nao_negativo91_vertical: sb $t4, 0($s5)
			
			 ########################################################################################## 
			mul $t4, $s1, 4
			mul $t4, $t4, 2
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo72_vertical
			move $t4, $0
			nao_negativo72_vertical: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo82_vertical
			move $t4, $0
			nao_negativo82_vertical: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo92_vertical
			move $t4, $0
			nao_negativo92_vertical: sb $t4, 2($s5)
			
			#######################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 3
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
		
			addi $t2, $t2, 1
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			j Loop2_Bhorizontal
	
		exit_loop2_Bvertical:
			
			slti $t4, $t1, 1
			beq $t4, $zero, carrega_pixel_vertical
			move $t2, $0
			addi $t1, $t1, 1	
			j Loop1_Bvertical
			
			carrega_pixel_vertical:
			
			li $t4, 2
			div $t1, $t4
			mfhi $t4
			beq $t4, $zero, parload
			li $t5, 0x10040000
			addi $t4, $t1, -1
			mul $t4, $t4, $s1 #linha menos 1 vezes largura
			mul $t4, $t4, 4
			add $t5, $t5, $t4

			move $t6, $0
			la $t7, buffer_extractor
			loop_carrega_linha_vertical:
				beq $t6, $s1, exit_loop_carrega_linha_vertical
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_vertical
			exit_loop_carrega_linha_vertical:
				move $t2, $0
				addi $t1, $t1, 1
				j Loop1_Bvertical
			
			parload:
				li $t5, 0x10040000
				addi $t4, $t1, -1
				mul $t4, $t4, $s1 #linha menos 1 vezes largura
				mul $t4, $t4, 4
				add $t5, $t5, $t4

				move $t6, $0
				la $t7, buffer_extractor2
			loop_carrega_linha_vertical2:
				beq $t6, $s1, exit_loop_carrega_linha_vertical2
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_vertical2
			exit_loop_carrega_linha_vertical2:
				move $t2, $0
				addi $t1, $t1, 1
					
				j Loop1_Bvertical
	
	exit_loop1_Bvertical:
	
			li $t4, 2
			div $t1, $t4
			mfhi $t4
			beq $t4, $zero, parload_ultimalinha
			li $t5, 0x10040000
			addi $t4, $t1, -1
			mul $t4, $t4, $s1 #linha menos 1 vezes largura
			mul $t4, $t4, 4
			add $t5, $t5, $t4
			move $t6, $0
			la $t7, buffer_extractor
			loop_carrega_linha_vertical_ultimalinha:
				beq $t6, $s1, exit_loop_carrega_linha_vertical_ultimalinha
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_vertical_ultimalinha
			exit_loop_carrega_linha_vertical_ultimalinha:
				move $t2, $0
				addi $t1, $t1, 1
				j exit2_loop1_Bvertical
			
			parload_ultimalinha:
				li $t5, 0x10040000
				addi $t4, $t1, -1
				mul $t4, $t4, $s1 #linha menos 1 vezes largura
				mul $t4, $t4, 4
				add $t5, $t5, $t4

				move $t6, $0
				la $t7, buffer_extractor2
			loop_carrega_linha_vertical2_ultimalinha:
				beq $t6, $s1, exit2_loop1_Bvertical
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_vertical2_ultimalinha
	
		exit2_loop1_Bvertical:
		lw $s7, 28($sp)
		lw $s6, 24($sp)
		lw $s5, 20($sp)
		lw $s4, 16($sp)
		lw $s3, 12($sp)
		lw $s2, 8($sp)
		lw $s1, 4($sp)	
		lw $s0, 0($sp)
		addi $sp, $sp, 32
	
		j Exit_Edge_Extractor
	

##################################################################################################################3
Bcruz:
	
	Loop1_Bcruz:
		beq $t1, $s2, exit_loop1_Bcruz #Compara linhas (altura)
		li $t4, 2
		div $t1, $t4
		mfhi $t4
		beq $t4, $zero, parcruz
		la $s6, buffer_extractor
		j Loop2_Bcruz
		parcruz:
		la $s6, buffer_extractor2
		
		Loop2_Bcruz:
			beq $t2, $s1, exit_loop2_Bcruz #Compara colunas (largura)
			
			bne $t1, $zero, nao_primeira_linha_cruz #Verifica se primeira linha		

			bne $t2, $zero, nao_primeira_coluna_cruz
				
			li $t4, 255
			sb $t4, 0($s3)
			sb $t4, 3($s3)
			sb $t4, 0($s4)
			sb $t4, 3($s4)
			sb $t4, 0($s5)
			sb $t4, 3($s5)
			
			li $t5, 0x10040000
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo1_cruz
			move $t4, $0
			nao_negativo1_cruz: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo2_cruz
			move $t4, $0
			nao_negativo2_cruz: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo3_cruz
			move $t4, $0
			nao_negativo3_cruz: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo12_cruz
			move $t4, $0
			nao_negativo12_cruz: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo22_cruz
			move $t4, $0
			nao_negativo22_cruz: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo32_cruz
			move $t4, $0
			nao_negativo32_cruz: sb $t4, 4($s5)
			
			########################################################################################
			
			mul $t4, $s1, 4
			addi $t5, $t5, -4
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo13_cruz
			move $t4, $0
			nao_negativo13_cruz: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo23_cruz
			move $t4, $0
			nao_negativo23_cruz: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo33_cruz
			move $t4, $0
			nao_negativo33_cruz: sb $t4, 2($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 5
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bcruz
				
			nao_primeira_coluna_cruz:
			bne $t2, $t3, nao_ultima_coluna_cruz
			
			
			li $t4, 255
			sb $t4, 0($s3)
			sb $t4, 0($s4)
			sb $t4, 0($s5)
			sb $t4, 4($s3)
			sb $t4, 4($s4)
			sb $t4, 4($s5)
			
			
			mul $t4, $t2, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo4_cruz
			move $t4, $0
			nao_negativo4_cruz: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo5_cruz
			move $t4, $0
			nao_negativo5_cruz: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo6_cruz
			move $t4, $0
			nao_negativo6_cruz: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, -4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo42_cruz
			move $t4, $0
			nao_negativo42_cruz: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo52_cruz
			move $t4, $0
			nao_negativo52_cruz: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo62_cruz
			move $t4, $0
			nao_negativo62_cruz: sb $t4, 3($s5)
			
			########################################################################################
			
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo43_cruz
			move $t4, $0
			nao_negativo43_cruz: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo53_cruz
			move $t4, $0
			nao_negativo53_cruz: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo63_cruz
			move $t4, $0
			nao_negativo63_cruz: sb $t4, 2($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 5
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bcruz
			
			
			nao_ultima_coluna_cruz:
			
			li $t4, 255
			sb $t4, 0($s3)
			sb $t4, 0($s4)
			sb $t4, 0($s5)
			
			mul $t4, $t2, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo7_cruz
			move $t4, $0
			nao_negativo7_cruz: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo8_cruz
			move $t4, $0
			nao_negativo8_cruz: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo9_cruz
			move $t4, $0
			nao_negativo9_cruz: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo72_cruz
			move $t4, $0
			nao_negativo72_cruz: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo82_cruz
			move $t4, $0
			nao_negativo82_cruz: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo92_cruz
			move $t4, $0
			nao_negativo92_cruz: sb $t4, 4($s5)
			
			########################################################################################
			
			addi $t5, $t5, -8
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo73_cruz
			move $t4, $0
			nao_negativo73_cruz: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo83_cruz
			move $t4, $0
			nao_negativo83_cruz: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo93_cruz
			move $t4, $0
			nao_negativo93_cruz: sb $t4, 3($s5)
			
			########################################################################################
			
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo74_cruz
			move $t4, $0
			nao_negativo74_cruz: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo84_cruz
			move $t4, $0
			nao_negativo84_cruz: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo94_cruz
			move $t4, $0
			nao_negativo94_cruz: sb $t4, 2($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 5
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			addi $t2, $t2, 1
			j Loop2_Bcruz
                        #########################################################################################
			
			nao_primeira_linha_cruz:
			bne $t1, $t3, nao_ultima_linha_cruz 
			#############################################################################
			bne $t2, $zero, nao_primeira_coluna_cruz2
				
				
					
			li $t4, 255
			sb $t4, 2($s3)
			sb $t4, 3($s3)
			sb $t4, 2($s4)
			sb $t4, 3($s4)
			sb $t4, 2($s5)
			sb $t4, 3($s5)
		
			mul $t4, $s1, $t1
			mul $t4, $t4, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_10_cruz
			move $t4, $0
			nao_negativo_10_cruz: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_11_cruz
			move $t4, $0
			nao_negativo_11_cruz: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_12_cruz
			move $t4, $0
			nao_negativo_12_cruz: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo102_cruz
			move $t4, $0
			nao_negativo102_cruz: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo112_cruz
			move $t4, $0
			nao_negativo112_cruz: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo122_cruz
			move $t4, $0
			nao_negativo122_cruz: sb $t4, 4($s5)
			
			########################################################################################
			
			mul $t4, $s1, 4
			addi $t5, $t5, -4
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo103_cruz
			move $t4, $0
			nao_negativo103_cruz: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo113_cruz
			move $t4, $0
			nao_negativo113_cruz: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo123_cruz
			move $t4, $0
			nao_negativo123_cruz: sb $t4, 0($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 5
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bcruz
			
			nao_primeira_coluna_cruz2:
			bne $t2, $t3, nao_ultima_coluna_cruz2
			
			li $t4, 255
			sb $t4, 2($s3)
			sb $t4, 4($s3)
			sb $t4, 2($s4)
			sb $t4, 4($s4)
			sb $t4, 2($s5)
			sb $t4, 4($s5)
		
			mul $t4, $s1, $t1
			add $t4, $t4, $t2
			mul $t4, $t4, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)	
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_13_cruz
			move $t4, $0
			nao_negativo_13_cruz: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_14_cruz
			move $t4, $0
			nao_negativo_14_cruz: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_15_cruz
			move $t4, $0
			nao_negativo_15_cruz: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, -4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo132_cruz
			move $t4, $0
			nao_negativo132_cruz: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo142_cruz
			move $t4, $0
			nao_negativo142_cruz: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo152_cruz
			move $t4, $0
			nao_negativo152_cruz: sb $t4, 3($s5)
			
			########################################################################################
			
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo133_cruz
			move $t4, $0
			nao_negativo133_cruz: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo143_cruz
			move $t4, $0
			nao_negativo143_cruz: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo153_cruz
			move $t4, $0
			nao_negativo153_cruz: sb $t4, 0($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 5
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bcruz	

			nao_ultima_coluna_cruz2:
			
			li $t4, 255
			sb $t4, 2($s3)
			sb $t4, 2($s4)
			sb $t4, 2($s5)
			
			mul $t4, $s1, $t1
			add $t4, $t4, $t2
			mul $t4, $t4, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo16_cruz
			move $t4, $0
			nao_negativo16_cruz: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo17_cruz
			move $t4, $0
			nao_negativo17_cruz: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo18_cruz
			move $t4, $0
			nao_negativo18_cruz: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo162_cruz
			move $t4, $0
			nao_negativo162_cruz: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo172_cruz
			move $t4, $0
			nao_negativo172_cruz: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo182_cruz
			move $t4, $0
			nao_negativo182_cruz: sb $t4, 4($s5)
			
			########################################################################################
			
			addi $t5, $t5, -8
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo163_cruz
			move $t4, $0
			nao_negativo163_cruz: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo173_cruz
			move $t4, $0
			nao_negativo173_cruz: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo183_cruz
			move $t4, $0
			nao_negativo183_cruz: sb $t4, 3($s5)
			
			########################################################################################
			
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo164_cruz
			move $t4, $0
			nao_negativo164_cruz: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo174_cruz
			move $t4, $0
			nao_negativo174_cruz: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo184_cruz
			move $t4, $0
			nao_negativo184_cruz: sb $t4, 0($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 5
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20

			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			addi $t2, $t2, 1
			j Loop2_Bcruz

			
			############################################################################
			nao_ultima_linha_cruz:

			bne $t2, $zero, nao_primeira_coluna_cruz3
			
			li $t4, 255
			
			sb $t4, 3($s3)
			sb $t4, 3($s4)
			sb $t4, 3($s5)
			
			li $t5, 0x10040000
			mul $t4, $s1, $t1
			mul $t4, $t4, 4
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo19_cruz
			move $t4, $0
			nao_negativo19_cruz: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo20_cruz
			move $t4, $0
			nao_negativo20_cruz: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo21_cruz
			move $t4, $0
			nao_negativo21_cruz: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo192_cruz
			move $t4, $0
			nao_negativo192_cruz: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo202_cruz
			move $t4, $0
			nao_negativo202_cruz: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo212_cruz
			move $t4, $0
			nao_negativo212_cruz: sb $t4, 4($s5)
			
			########################################################################################
			
			mul $t4, $s1, 4
			addi $t5, $t5, -4
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo193_cruz
			move $t4, $0
			nao_negativo193_cruz: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo203_cruz
			move $t4, $0
			nao_negativo203_cruz: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo213_cruz
			move $t4, $0
			nao_negativo213_cruz: sb $t4, 2($s5)
			
			########################################################################################
			
			mul $t4, $s1, 4
			mul $t4, $t4, 2
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo194_cruz
			move $t4, $0
			nao_negativo194_cruz: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo204_cruz
			move $t4, $0
			nao_negativo204_cruz: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo214_cruz
			move $t4, $0
			nao_negativo214_cruz: sb $t4, 0($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 5
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bcruz

			nao_primeira_coluna_cruz3:
			bne $t2, $t3, nao_ultima_coluna_cruz3
		
			li $t4, 255
			sb $t4, 4($s3)
			sb $t4, 4($s4)
			sb $t4, 4($s5)
		
			mul $t4, $s1, $t1
			add $t4, $t4, $t2
			mul $t4, $t4, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)	
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_22_cruz
			move $t4, $0
			nao_negativo_22_cruz: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_23_cruz
			move $t4, $0
			nao_negativo_23_cruz: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_24_cruz
			move $t4, $0
			nao_negativo_24_cruz: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, -4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo222_cruz
			move $t4, $0
			nao_negativo222_cruz: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo232_cruz
			move $t4, $0
			nao_negativo232_cruz: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo242_cruz
			move $t4, $0
			nao_negativo242_cruz: sb $t4, 3($s5)
			
			########################################################################################
			
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo223_cruz
			move $t4, $0
			nao_negativo223_cruz: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo233_cruz
			move $t4, $0
			nao_negativo233_cruz: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo243_cruz
			move $t4, $0
			nao_negativo243_cruz: sb $t4, 0($s5)
			
			########################################################################################
			
			mul $t4, $s1, 4
			mul $t4, $t4, 2
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo224_cruz
			move $t4, $0
			nao_negativo224_cruz: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo234_cruz
			move $t4, $0
			nao_negativo234_cruz: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo244_cruz
			move $t4, $0
			nao_negativo244_cruz: sb $t4, 2($s5)
			
			########################################################################################
		
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 5
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20

			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bcruz	
				
											
			nao_ultima_coluna_cruz3:
		
			mul $t4, $s1, $t1
			add $t4, $t4, $t2
			mul $t4, $t4, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo25_cruz
			move $t4, $0
			nao_negativo25_cruz: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo26_cruz
			move $t4, $0
			nao_negativo26_cruz: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo27_cruz
			move $t4, $0
			nao_negativo27_cruz: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo252_cruz
			move $t4, $0
			nao_negativo252_cruz: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo262_cruz
			move $t4, $0
			nao_negativo262_cruz: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo272_cruz
			move $t4, $0
			nao_negativo272_cruz: sb $t4, 4($s5)
			
			########################################################################################
			
			addi $t5, $t5, -8
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo253_cruz
			move $t4, $0
			nao_negativo253_cruz: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo263_cruz
			move $t4, $0
			nao_negativo263_cruz: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo273_cruz
			move $t4, $0
			nao_negativo273_cruz: sb $t4, 3($s5)
			
			########################################################################################
			
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo254_cruz
			move $t4, $0
			nao_negativo254_cruz: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo264_cruz
			move $t4, $0
			nao_negativo264_cruz: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo274_cruz
			move $t4, $0
			nao_negativo274_cruz: sb $t4, 0($s5)
			
			########################################################################################
			mul $t4, $s1, 4
			mul $t4, $t4, 2
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo255_cruz
			move $t4, $0
			nao_negativo255_cruz: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo265_cruz
			move $t4, $0
			nao_negativo265_cruz: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo275_cruz
			move $t4, $0
			nao_negativo275_cruz: sb $t4, 2($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)

			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 5
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20

			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			addi $t2, $t2, 1
			j Loop2_Bcruz
			
			############################################################################
			
	exit_loop2_Bcruz:
			
			slti $t4, $t1, 1
			beq $t4, $zero, carrega_pixel_cruz
			move $t2, $0
			addi $t1, $t1, 1	
			j Loop1_Bcruz
			
			carrega_pixel_cruz:
			
			li $t4, 2
			div $t1, $t4
			mfhi $t4
			beq $t4, $zero, parload_cruz
			li $t5, 0x10040000
			addi $t4, $t1, -1
			mul $t4, $t4, $s1 #linha menos 1 vezes largura
			mul $t4, $t4, 4
			add $t5, $t5, $t4
			move $t6, $0
			la $t7, buffer_extractor
			loop_carrega_linha_cruz:
				beq $t6, $s1, exit_loop_carrega_linha_cruz
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_cruz
			exit_loop_carrega_linha_cruz:
				move $t2, $0
				addi $t1, $t1, 1
				j Loop1_Bcruz
			
			parload_cruz:
				li $t5, 0x10040000
				addi $t4, $t1, -1
				mul $t4, $t4, $s1 #linha menos 1 vezes largura
				mul $t4, $t4, 4
				add $t5, $t5, $t4
				move $t6, $0
				la $t7, buffer_extractor2
			loop_carrega_linha_cruz2:
				beq $t6, $s1, exit_loop_carrega_linha_cruz2
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_cruz2
			exit_loop_carrega_linha_cruz2:
				move $t2, $0
				addi $t1, $t1, 1
					
				j Loop1_Bcruz

	exit_loop1_Bcruz:
	
			li $t4, 2
			div $t1, $t4
			mfhi $t4
			beq $t4, $zero, parload_ultimalinha_cruz
			li $t5, 0x10040000
			addi $t4, $t1, -1
			mul $t4, $t4, $s1 #linha menos 1 vezes largura
			mul $t4, $t4, 4
			add $t5, $t5, $t4
			move $t6, $0
			la $t7, buffer_extractor
			loop_carrega_linha_cruz_ultimalinha:
				beq $t6, $s1, exit_loop_carrega_linha_cruz_ultimalinha
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_cruz_ultimalinha
			exit_loop_carrega_linha_cruz_ultimalinha:
				move $t2, $0
				addi $t1, $t1, 1
				j exit2_loop1_Bcruz
			
			parload_ultimalinha_cruz:
				li $t5, 0x10040000
				addi $t4, $t1, -1
				mul $t4, $t4, $s1 #linha menos 1 vezes largura
				mul $t4, $t4, 4
				add $t5, $t5, $t4

				move $t6, $0
				la $t7, buffer_extractor2
			loop_carrega_linha_cruz2_ultimalinha:
				beq $t6, $s1, exit2_loop1_Bcruz
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_cruz2_ultimalinha

		exit2_loop1_Bcruz:
		lw $s7, 28($sp)
		lw $s6, 24($sp)
		lw $s5, 20($sp)
		lw $s4, 16($sp)
		lw $s3, 12($sp)
		lw $s2, 8($sp)
		lw $s1, 4($sp)	
		lw $s0, 0($sp)
		addi $sp, $sp, 32
	
		j Exit_Edge_Extractor
	

#########################################################################################################################################
Bquadrado:
	
	Loop1_Bquadrado:
		beq $t1, $s2, exit_loop1_Bquadrado #Compara linhas (altura)
		li $t4, 2
		div $t1, $t4
		mfhi $t4
		beq $t4, $zero, parquadrado
		la $s6, buffer_extractor
		j Loop2_Bquadrado
		parquadrado:
		la $s6, buffer_extractor2
		
		Loop2_Bquadrado:
			beq $t2, $s1, exit_loop2_Bquadrado #Compara colunas (largura)
			
			bne $t1, $zero, nao_primeira_linha_quadrado #Verifica se primeira linha		

                       #######################################################################################
			bne $t2, $zero, nao_primeira_coluna_quadrado
				
			li $t4, 255	
			sb $t4, 5($s3)
			sb $t4, 5($s4)
			sb $t4, 5($s5)
			sb $t4, 0($s3)
			sb $t4, 0($s4)
			sb $t4, 0($s5)
			sb $t4, 6($s3)
			sb $t4, 6($s4)
			sb $t4, 6($s5)
			sb $t4, 3($s3)
			sb $t4, 3($s4)
			sb $t4, 3($s5)
			sb $t4, 7($s3)
			sb $t4, 7($s4)
			sb $t4, 7($s5)
			
			
			li $t5, 0x10040000
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo1_quadrado
			move $t4, $0
			nao_negativo1_quadrado: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo2_quadrado
			move $t4, $0
			nao_negativo2_quadrado: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo3_quadrado
			move $t4, $0
			nao_negativo3_quadrado: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo1_2_quadrado
			move $t4, $0
			nao_negativo1_2_quadrado: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo2_2_quadrado
			move $t4, $0
			nao_negativo2_2_quadrado: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo3_2_quadrado
			move $t4, $0
			nao_negativo3_2_quadrado: sb $t4, 4($s5)
			
			########################################################################################
			
			mul $t4, $s1, 4
			addi $t5, $t5, -4
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo1_3_quadrado
			move $t4, $0
			nao_negativo1_3_quadrado: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo2_3_quadrado
			move $t4, $0
			nao_negativo2_3_quadrado: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo3_3_quadrado
			move $t4, $0
			nao_negativo3_3_quadrado: sb $t4, 2($s5)
			
			########################################################################################
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo1_4_quadrado
			move $t4, $0
			nao_negativo1_4_quadrado: sb $t4, 8($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo2_4_quadrado
			move $t4, $0
			nao_negativo2_4_quadrado: sb $t4, 8($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo3_4_quadrado
			move $t4, $0
			nao_negativo3_4_quadrado: sb $t4, 8($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 9
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bquadrado
				
			nao_primeira_coluna_quadrado:
			bne $t2, $t3, nao_ultima_coluna_quadrado
			
			li $t4, 255	
			sb $t4, 5($s3)
			sb $t4, 5($s4)
			sb $t4, 5($s5)
			sb $t4, 0($s3)
			sb $t4, 0($s4)
			sb $t4, 0($s5)
			sb $t4, 6($s3)
			sb $t4, 6($s4)
			sb $t4, 6($s5)
			sb $t4, 4($s3)
			sb $t4, 4($s4)
			sb $t4, 4($s5)
			sb $t4, 8($s3)
			sb $t4, 8($s4)
			sb $t4, 8($s5)
			
			
			
			mul $t4, $t2, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo4_quadrado
			move $t4, $0
			nao_negativo4_quadrado: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo5_quadrado
			move $t4, $0
			nao_negativo5_quadrado: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo6_quadrado
			move $t4, $0
			nao_negativo6_quadrado: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, -4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo4_2_quadrado
			move $t4, $0
			nao_negativo4_2_quadrado: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo5_2_quadrado
			move $t4, $0
			nao_negativo5_2_quadrado: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo6_2_quadrado
			move $t4, $0
			nao_negativo6_2_quadrado: sb $t4, 3($s5)
			
			########################################################################################
			
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo4_3_quadrado
			move $t4, $0
			nao_negativo4_3_quadrado: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo5_3_quadrado
			move $t4, $0
			nao_negativo5_3_quadrado: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo6_3_quadrado
			move $t4, $0
			nao_negativo6_3_quadrado: sb $t4, 2($s5)
			
			########################################################################################
			
			addi $t5, $t5, -4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo4_4_quadrado
			move $t4, $0
			nao_negativo4_4_quadrado: sb $t4, 7($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo5_4_quadrado
			move $t4, $0
			nao_negativo5_4_quadrado: sb $t4, 7($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo6_4_quadrado
			move $t4, $0
			nao_negativo6_4_quadrado: sb $t4, 7($s5)
			
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 9
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bquadrado
			
			
			nao_ultima_coluna_quadrado:
			
			li $t4, 255
			sb $t4, 0($s3)
			sb $t4, 0($s4)
			sb $t4, 0($s5)
			sb $t4, 5($s3)
			sb $t4, 5($s4)
			sb $t4, 5($s5)
			sb $t4, 6($s3)
			sb $t4, 6($s4)
			sb $t4, 6($s5)
			
			
			
			mul $t4, $t2, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo7_quadrado
			move $t4, $0
			nao_negativo7_quadrado: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo8_quadrado
			move $t4, $0
			nao_negativo8_quadrado: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo9_quadrado
			move $t4, $0
			nao_negativo9_quadrado: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo7_2_quadrado
			move $t4, $0
			nao_negativo7_2_quadrado: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo8_2_quadrado
			move $t4, $0
			nao_negativo8_2_quadrado: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo9_2_quadrado
			move $t4, $0
			nao_negativo9_2_quadrado: sb $t4, 4($s5)
			
			########################################################################################
			
			addi $t5, $t5, -8
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo7_3_quadrado
			move $t4, $0
			nao_negativo7_3_quadrado: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo8_3_quadrado
			move $t4, $0
			nao_negativo8_3_quadrado: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo9_3_quadrado
			move $t4, $0
			nao_negativo9_3_quadrado: sb $t4, 3($s5)
			
			########################################################################################
			
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo7_4_quadrado
			move $t4, $0
			nao_negativo7_4_quadrado: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo8_4_quadrado
			move $t4, $0
			nao_negativo8_4_quadrado: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo9_4_quadrado
			move $t4, $0
			nao_negativo9_4_quadrado: sb $t4, 2($s5)
			
			########################################################################################
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo7_5_quadrado
			move $t4, $0
			nao_negativo7_5_quadrado: sb $t4, 8($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo8_5_quadrado
			move $t4, $0
			nao_negativo8_5_quadrado: sb $t4, 8($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo9_5_quadrado
			move $t4, $0
			nao_negativo9_5_quadrado: sb $t4, 8($s5)
			
			########################################################################################
			
			addi $t5, $t5, -8
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo7_6_quadrado
			move $t4, $0
			nao_negativo7_6_quadrado: sb $t4, 7($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo8_6_quadrado
			move $t4, $0
			nao_negativo8_6_quadrado: sb $t4, 7($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo9_6_quadrado
			move $t4, $0
			nao_negativo9_6_quadrado: sb $t4, 7($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 9
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			addi $t2, $t2, 1
			j Loop2_Bquadrado
                        #########################################################################################
			
			nao_primeira_linha_quadrado:
			bne $t1, $t3, nao_ultima_linha_quadrado 
			
			bne $t2, $zero, nao_primeira_coluna_quadrado2
	
			li $t4, 255
			sb $t4, 2($s3)
			sb $t4, 2($s4)
			sb $t4, 2($s5)
			sb $t4, 7($s3)
			sb $t4, 7($s4)
			sb $t4, 7($s5)
			sb $t4, 8($s3)
			sb $t4, 8($s4)
			sb $t4, 8($s5)
			sb $t4, 3($s3)
			sb $t4, 3($s4)
			sb $t4, 3($s5)
			sb $t4, 5($s3)
			sb $t4, 5($s4)
			sb $t4, 5($s5)
			
			
			mul $t4, $s1, $t1
			mul $t4, $t4, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_10_quadrado
			move $t4, $0
			nao_negativo_10_quadrado: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_11_quadrado
			move $t4, $0
			nao_negativo_11_quadrado: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_12_quadrado
			move $t4, $0
			nao_negativo_12_quadrado: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo10_2_quadrado
			move $t4, $0
			nao_negativo10_2_quadrado: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo11_2_quadrado
			move $t4, $0
			nao_negativo11_2_quadrado: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo12_2_quadrado
			move $t4, $0
			nao_negativo12_2_quadrado: sb $t4, 4($s5)
			
			########################################################################################
			
			mul $t4, $s1, 4
			addi $t5, $t5, -4
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo10_3_quadrado
			move $t4, $0
			nao_negativo10_3_quadrado: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo11_3_quadrado
			move $t4, $0
			nao_negativo11_3_quadrado: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo12_3_quadrado
			move $t4, $0
			nao_negativo12_3_quadrado: sb $t4, 0($s5)
			
			########################################################################################
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo10_4_quadrado
			move $t4, $0
			nao_negativo10_4_quadrado: sb $t4, 6($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo11_4_quadrado
			move $t4, $0
			nao_negativo11_4_quadrado: sb $t4, 6($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo12_4_quadrado
			move $t4, $0
			nao_negativo12_4_quadrado: sb $t4, 6($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 9
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bquadrado
			
			nao_primeira_coluna_quadrado2:
			bne $t2, $t3, nao_ultima_coluna_quadrado2
			
			li $t4, 255
			sb $t4, 2($s3)
			sb $t4, 2($s4)
			sb $t4, 2($s5)
			sb $t4, 7($s3)
			sb $t4, 7($s4)
			sb $t4, 7($s5)
			sb $t4, 8($s3)
			sb $t4, 8($s4)
			sb $t4, 8($s5)
			sb $t4, 4($s3)
			sb $t4, 4($s4)
			sb $t4, 4($s5)
			sb $t4, 6($s3)
			sb $t4, 6($s4)
			sb $t4, 6($s5)
			
		
			mul $t4, $s1, $t1
			add $t4, $t4, $t2
			mul $t4, $t4, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)	
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_13_quadraddo
			move $t4, $0
			nao_negativo_13_quadraddo: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_14_quadraddo
			move $t4, $0
			nao_negativo_14_quadraddo: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_15_quadraddo
			move $t4, $0
			nao_negativo_15_quadraddo: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, -4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo13_2_quadrado
			move $t4, $0
			nao_negativo13_2_quadrado: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo14_2_quadrado
			move $t4, $0
			nao_negativo14_2_quadrado: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo15_2_quadrado
			move $t4, $0
			nao_negativo15_2_quadrado: sb $t4, 3($s5)
			
			########################################################################################
			
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo13_3_quadraddo
			move $t4, $0
			nao_negativo13_3_quadraddo: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo14_3_quadraddo
			move $t4, $0
			nao_negativo14_3_quadraddo: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo15_3_quadraddo
			move $t4, $0
			nao_negativo15_3_quadraddo: sb $t4, 0($s5)
			
			########################################################################################
			
			addi $t5, $t5, -4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo13_4_quadraddo
			move $t4, $0
			nao_negativo13_4_quadraddo: sb $t4, 5($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo14_4_quadraddo
			move $t4, $0
			nao_negativo14_4_quadraddo: sb $t4, 5($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo15_4_quadraddo
			move $t4, $0
			nao_negativo15_4_quadraddo: sb $t4, 5($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 9
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bquadrado	

			nao_ultima_coluna_quadrado2:
			
			li $t4, 255
			sb $t4, 2($s3)
			sb $t4, 2($s4)
			sb $t4, 2($s5)
			sb $t4, 7($s3)
			sb $t4, 7($s4)
			sb $t4, 7($s5)
			sb $t4, 8($s3)
			sb $t4, 8($s4)
			sb $t4, 8($s5)
			
			
			mul $t4, $s1, $t1
			add $t4, $t4, $t2
			mul $t4, $t4, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo16_quadrado
			move $t4, $0
			nao_negativo16_quadrado: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo17_quadrado
			move $t4, $0
			nao_negativo17_quadrado: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo18_quadrado
			move $t4, $0
			nao_negativo18_quadrado: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo16_2_quadrado
			move $t4, $0
			nao_negativo16_2_quadrado: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo17_2_quadrado
			move $t4, $0
			nao_negativo17_2_quadrado: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo18_2_quadrado
			move $t4, $0
			nao_negativo18_2_quadrado: sb $t4, 4($s5)
			
			########################################################################################
			
			addi $t5, $t5, -8
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo16_3_quadrado
			move $t4, $0
			nao_negativo16_3_quadrado: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo17_3_quadrado
			move $t4, $0
			nao_negativo17_3_quadrado: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo18_3_quadrado
			move $t4, $0
			nao_negativo18_3_quadrado: sb $t4, 3($s5)
			
			########################################################################################
			
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo16_4_quadrado
			move $t4, $0
			nao_negativo16_4_quadrado: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo17_4_quadrado
			move $t4, $0
			nao_negativo17_4_quadrado: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo18_4_quadrado
			move $t4, $0
			nao_negativo18_4_quadrado: sb $t4, 0($s5)
			
			########################################################################################
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo16_5_quadrado
			move $t4, $0
			nao_negativo16_5_quadrado: sb $t4, 6($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo17_5_quadrado
			move $t4, $0
			nao_negativo17_5_quadrado: sb $t4, 6($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo18_5_quadrado
			move $t4, $0
			nao_negativo18_5_quadrado: sb $t4, 6($s5)
			
			########################################################################################
			
			addi $t5, $t5, -8
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo16_6_quadrado
			move $t4, $0
			nao_negativo16_6_quadrado: sb $t4, 5($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo17_6_quadrado
			move $t4, $0
			nao_negativo17_6_quadrado: sb $t4, 5($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo18_6_quadrado
			move $t4, $0
			nao_negativo18_6_quadrado: sb $t4, 5($s5)
			
			########################################################################################
			
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 9
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20

			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			addi $t2, $t2, 1
			j Loop2_Bquadrado

			############################################################################
			nao_ultima_linha_quadrado:
			
			bne $t2, $zero, nao_primeira_coluna_quadrado3
			
			li $t4, 255
			
			sb $t4, 3($s3)
			sb $t4, 3($s4)
			sb $t4, 3($s5)
			sb $t4, 5($s3)
			sb $t4, 5($s4)
			sb $t4, 5($s5)
			sb $t4, 7($s3)
			sb $t4, 7($s4)
			sb $t4, 7($s5)

			li $t5, 0x10040000
			mul $t4, $s1, $t1
			mul $t4, $t4, 4
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo19_quadrado
			move $t4, $0
			nao_negativo19_quadrado: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo20_quadrado
			move $t4, $0
			nao_negativo20_quadrado: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo21_quadrado
			move $t4, $0
			nao_negativo21_quadrado: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo19_2_quadrado
			move $t4, $0
			nao_negativo19_2_quadrado: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo20_2_quadrado
			move $t4, $0
			nao_negativo20_2_quadrado: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo21_2_quadrado
			move $t4, $0
			nao_negativo21_2_quadrado: sb $t4, 4($s5)
			
			########################################################################################
			
			mul $t4, $s1, 4
			addi $t5, $t5, -4
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo19_3_quadrado
			move $t4, $0
			nao_negativo19_3_quadrado: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo20_3_quadrado
			move $t4, $0
			nao_negativo20_3_quadrado: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo21_3_quadrado
			move $t4, $0
			nao_negativo21_3_quadrado: sb $t4, 2($s5)
			
			########################################################################################
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo19_4_quadrado
			move $t4, $0
			nao_negativo19_4_quadrado: sb $t4, 8($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo20_4_quadrado
			move $t4, $0
			nao_negativo20_4_quadrado: sb $t4, 8($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo21_4_quadrado
			move $t4, $0
			nao_negativo21_4_quadrado: sb $t4, 8($s5)
			
			########################################################################################
			
			addi $t5, $t5, -4
			mul $t4, $s1, 4
			mul $t4, $t4, 2
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo19_5_quadrado
			move $t4, $0
			nao_negativo19_5_quadrado: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo20_5_quadrado
			move $t4, $0
			nao_negativo20_5_quadrado: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo21_5_quadrado
			move $t4, $0
			nao_negativo21_5_quadrado: sb $t4, 0($s5)
			
			########################################################################################
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo19_6_quadrado
			move $t4, $0
			nao_negativo19_6_quadrado: sb $t4, 6($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo20_6_quadrado
			move $t4, $0
			nao_negativo20_6_quadrado: sb $t4, 6($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo21_6_quadrado
			move $t4, $0
			nao_negativo21_6_quadrado: sb $t4, 6($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 9
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bquadrado

			nao_primeira_coluna_quadrado3:
			bne $t2, $t3, nao_ultima_coluna_quadrado3
		
			li $t4, 255
			sb $t4, 4($s3)
			sb $t4, 4($s4)
			sb $t4, 4($s5)
			sb $t4, 6($s3)
			sb $t4, 6($s4)
			sb $t4, 6($s5)
			sb $t4, 8($s3)
			sb $t4, 8($s4)
			sb $t4, 8($s5)
			
			
			mul $t4, $s1, $t1
			add $t4, $t4, $t2
			mul $t4, $t4, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)	
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_22_quadrado
			move $t4, $0
			nao_negativo_22_quadrado: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_23_quadrado
			move $t4, $0
			nao_negativo_23_quadrado: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_24_quadrado
			move $t4, $0
			nao_negativo_24_quadrado: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, -4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo22_2_quadrado
			move $t4, $0
			nao_negativo22_2_quadrado: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo23_2_quadrado
			move $t4, $0
			nao_negativo23_2_quadrado: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo24_2_quadrado
			move $t4, $0
			nao_negativo24_2_quadrado: sb $t4, 3($s5)
			
			########################################################################################
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo22_3_quadrado
			move $t4, $0
			nao_negativo22_3_quadrado: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo23_3_quadrado
			move $t4, $0
			nao_negativo23_3_quadrado: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo24_3_quadrado
			move $t4, $0
			nao_negativo24_3_quadrado: sb $t4, 0($s5)
			
			########################################################################################
			
			addi $t5, $t5, -4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo22_4_quadrado
			move $t4, $0
			nao_negativo22_4_quadrado: sb $t4, 5($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo23_4_quadrado
			move $t4, $0
			nao_negativo23_4_quadrado: sb $t4, 5($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo24_4_quadrado
			move $t4, $0
			nao_negativo24_4_quadrado: sb $t4, 5($s5)
			
			########################################################################################
			
			addi $t5, $t5, 4
			mul $t4, $s1, 4
			mul $t4, $t4, 2
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo22_5_quadrado
			move $t4, $0
			nao_negativo22_5_quadrado: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo23_5_quadrado
			move $t4, $0
			nao_negativo23_5_quadrado: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo24_5_quadrado
			move $t4, $0
			nao_negativo24_5_quadrado: sb $t4, 2($s5)
			
			########################################################################################
			
			addi $t5, $t5, -4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo22_6_quadrado
			move $t4, $0
			nao_negativo22_6_quadrado: sb $t4, 7($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo23_6_quadrado
			move $t4, $0
			nao_negativo23_6_quadrado: sb $t4, 7($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo24_6_quadrado
			move $t4, $0
			nao_negativo24_6_quadrado: sb $t4, 7($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 9
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20

			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bquadrado	
				
											
			nao_ultima_coluna_quadrado3:
		
			mul $t4, $s1, $t1
			add $t4, $t4, $t2
			mul $t4, $t4, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo25_quadrado
			move $t4, $0
			nao_negativo25_quadrado: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo26_quadrado
			move $t4, $0
			nao_negativo26_quadrado: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo27_quadrado
			move $t4, $0
			nao_negativo27_quadrado: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo25_2_quadrado
			move $t4, $0
			nao_negativo25_2_quadrado: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo26_2_quadrado
			move $t4, $0
			nao_negativo26_2_quadrado: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo27_2_quadrado
			move $t4, $0
			nao_negativo27_2_quadrado: sb $t4, 4($s5)
			
			########################################################################################
			
			addi $t5, $t5, -8
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo25_3_quadrado
			move $t4, $0
			nao_negativo25_3_quadrado: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo26_3_quadrado
			move $t4, $0
			nao_negativo26_3_quadrado: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo27_3_quadrado
			move $t4, $0
			nao_negativo27_3_quadrado: sb $t4, 3($s5)
			
			########################################################################################
			
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo25_4_quadrado
			move $t4, $0
			nao_negativo25_4_quadrado: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo26_4_quadrado
			move $t4, $0
			nao_negativo26_4_quadrado: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo27_4_quadrado
			move $t4, $0
			nao_negativo27_4_quadrado: sb $t4, 0($s5)
			
			########################################################################################
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo25_5_quadrado
			move $t4, $0
			nao_negativo25_5_quadrado: sb $t4, 6($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo26_5_quadrado
			move $t4, $0
			nao_negativo26_5_quadrado: sb $t4, 6($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo27_5_quadrado
			move $t4, $0
			nao_negativo27_5_quadrado: sb $t4, 6($s5)
			
			########################################################################################
			
			addi $t5, $t5, -8
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo25_6_quadrado
			move $t4, $0
			nao_negativo25_6_quadrado: sb $t4, 5($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo26_6_quadrado
			move $t4, $0
			nao_negativo26_6_quadrado: sb $t4, 5($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo27_6_quadrado
			move $t4, $0
			nao_negativo27_6_quadrado: sb $t4, 5($s5)
			
			########################################################################################
			
			addi $t5, $t5, 4
			mul $t4, $s1, 4
			mul $t4, $t4, 2
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo25_7_quadrado
			move $t4, $0
			nao_negativo25_7_quadrado: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo26_7_quadrado
			move $t4, $0
			nao_negativo26_7_quadrado: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo27_7_quadrado
			move $t4, $0
			nao_negativo27_7_quadrado: sb $t4, 2($s5)
			
			########################################################################################
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo25_8_quadrado
			move $t4, $0
			nao_negativo25_8_quadrado: sb $t4, 8($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo26_8_quadrado
			move $t4, $0
			nao_negativo26_8_quadrado: sb $t4, 8($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo27_8_quadrado
			move $t4, $0
			nao_negativo27_8_quadrado: sb $t4, 8($s5)
			
			########################################################################################
			
			addi $t5, $t5, -8
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo25_9_quadrado
			move $t4, $0
			nao_negativo25_9_quadrado: sb $t4, 7($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo26_9_quadrado
			move $t4, $0
			nao_negativo26_9_quadrado: sb $t4, 7($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo27_9_quadrado
			move $t4, $0
			nao_negativo27_9_quadrado: sb $t4, 7($s5)
			
			########################################################################################
			
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 9
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20

			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			addi $t2, $t2, 1
			j Loop2_Bquadrado
			
			############################################################################
			
	exit_loop2_Bquadrado:
			
			slti $t4, $t1, 1
			beq $t4, $zero, carrega_pixel_quadrado
			move $t2, $0
			addi $t1, $t1, 1	
			j Loop1_Bquadrado
			
			carrega_pixel_quadrado:
			
			li $t4, 2
			div $t1, $t4
			mfhi $t4
			beq $t4, $zero, parload_quadrado
			li $t5, 0x10040000
			addi $t4, $t1, -1
			mul $t4, $t4, $s1 #linha menos 1 vezes largura
			mul $t4, $t4, 4
			add $t5, $t5, $t4
			move $t6, $0
			la $t7, buffer_extractor
			loop_carrega_linha_quadrado:
				beq $t6, $s1, exit_loop_carrega_linha_quadrado
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_quadrado
			exit_loop_carrega_linha_quadrado:
				move $t2, $0
				addi $t1, $t1, 1
				j Loop1_Bcruz
			
			parload_quadrado:
				li $t5, 0x10040000
				addi $t4, $t1, -1
				mul $t4, $t4, $s1 #linha menos 1 vezes largura
				mul $t4, $t4, 4
				add $t5, $t5, $t4
				move $t6, $0
				la $t7, buffer_extractor2
			loop_carrega_linha_quadrado2:
				beq $t6, $s1, exit_loop_carrega_linha_quadrado2
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_quadrado2
			exit_loop_carrega_linha_quadrado2:
				move $t2, $0
				addi $t1, $t1, 1
					
				j Loop1_Bquadrado
					
	exit_loop1_Bquadrado:
	
			li $t4, 2
			div $t1, $t4
			mfhi $t4
			beq $t4, $zero, parload_ultimalinha_quadrado
			li $t5, 0x10040000
			addi $t4, $t1, -1
			mul $t4, $t4, $s1 #linha menos 1 vezes largura
			mul $t4, $t4, 4
			add $t5, $t5, $t4	
			move $t6, $0
			la $t7, buffer_extractor
			loop_carrega_linha_quadrado_ultimalinha:
				beq $t6, $s1, exit_loop_carrega_linha_quadrado_ultimalinha
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_quadrado_ultimalinha
			exit_loop_carrega_linha_quadrado_ultimalinha:
				move $t2, $0
				addi $t1, $t1, 1
				j exit2_loop1_Bquadrado
			
			parload_ultimalinha_quadrado:
				li $t5, 0x10040000
				addi $t4, $t1, -1
				mul $t4, $t4, $s1 #linha menos 1 vezes largura
				mul $t4, $t4, 4
				add $t5, $t5, $t4
				move $t6, $0
				la $t7, buffer_extractor2
			loop_carrega_linha_quadrado2_ultimalinha:
				beq $t6, $s1, exit2_loop1_Bquadrado
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_quadrado2_ultimalinha
		
		exit2_loop1_Bquadrado:
		lw $s7, 28($sp)
		lw $s6, 24($sp)
		lw $s5, 20($sp)
		lw $s4, 16($sp)
		lw $s3, 12($sp)
		lw $s2, 8($sp)
		lw $s1, 4($sp)	
		lw $s0, 0($sp)
		addi $sp, $sp, 32
	
		j Exit_Edge_Extractor

		
Exit_Edge_Extractor:

	addi $sp, $sp, -4
	sw $ra, 0($sp)
	move $a0, $fp
	move $a1, $s1 #tamanho da imagem em bytes(ja foi restaurado da pilha)
	jal Edge_detector
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
###########################################################################################################################################
						
Edge_detector: # Funcao que recebe como parametros: 1) O endereço de delimitador $fp da pila onde se encontra a imagem original em $a0
#2) o tamanho da imagem em bytes em $a1. Esta funcao carrega a imagem original na memoria heap para ser mostrada no bitmap display

	move $t0, $a0
	
	#Soma o endereço de base da memoria heap com o tamanho da imagem original (abre espaço na memoria heap)
	li $t1, 0x10040000
	div $t2, $a1, 3
	add $t2, $t2, $a1
	add $t1, $t1, $t2
	move $t2, $zero
	Loop_edge_detector: #Loop que desempilha os pixels de tras pra frente e ja carrega na posicao correta na memoria heap
		beq $t2, $a1, exit_edge_detector
		lw $t3, 0($t0)
		lw $t4, 0($t1)
		sub $t3, $t3, $t4
		sw $t3, 0($t1)
		addi $t0, $t0, 4
		addi $t1, $t1, -4
		addi $t2, $t2, 3
		j Loop_edge_detector
exit_edge_detector:
		jr $ra

######################################################################################################################################
minimiza: #Funcao que recebe como parametro o endereço dos vetores RGB em $a0, $a1, $a2 e o tamanho dos mesmo em $a3
#Esta funcao encontra o valor minimo de cada vetor e retorna um vetor resultado com esses minimos 
	
	move $t0, $0
	li $t1, 255
	la $t2, result
	sb $0, 3($t2)
	
	loop1_minimiza:
		beq $t0, $a3, exit1_minimiza 
		lbu $t3, 0($a0)
		slt $t4, $t3, $t1
		beq $t4, $0, nao_menor
		move $t1, $t3
		nao_menor:
		addi $a0, $a0, 1
		add $t0, $t0, 1
		j loop1_minimiza
	exit1_minimiza:	
		sb $t1, 2($t2)
		move $t0, $0
		li $t1, 255
		loop2_minimiza:
		beq $t0, $a3, exit2_minimiza 
		lbu $t3, 0($a1)
		slt $t4, $t3, $t1
		beq $t4, $0, nao_menor2
		move $t1, $t3
		nao_menor2:
		addi $a1, $a1, 1
		add $t0, $t0, 1
		j loop2_minimiza
	exit2_minimiza: 	
		sb $t1, 1($t2)
		move $t0, $0
		li $t1, 255
	loop3_minimiza:
		beq $t0, $a3, exit3_minimiza 
		lbu $t3, 0($a2)
		slt $t4, $t3, $t1
		beq $t4, $0, nao_menor3
		move $t1, $t3
		nao_menor3:
		addi $a2, $a2, 1
		add $t0, $t0, 1
		j loop3_minimiza
	exit3_minimiza:
		sb $t1, 0($t2)
		jr $ra
		
#################################################################################################################		
		
		

		
				
						
						
								
										
												
																
		
		
		
		
	
	
	
