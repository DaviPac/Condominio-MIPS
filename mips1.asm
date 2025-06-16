# CABEÇALHO
#
# Nome do grupo: Davi (Sou só eu :D)
# Aluno: Davi Pires Aquino de Carvalho
# Atividade: Projeto 1VA
# Disciplina: Arquitetura e Organização de Computadores
# Semestre: 2025.1
# Questão: Projeto Condominio 1VA
#
# Descrição do arquivo:
#
# Contem macros utilizadas apenas para imprimir labels, strings e ints
#
# Os dados sao guardados em uma string gigante no seguinte formato:
# ',': Separa argumentos dentro do apto (qtd_moradores,nome1,...,nome5,tipo_auto,modelo1,cor1,modelo2,cor2,)
# '-': Separa aptos (apto1-...-apto4-)
# ';': Separa andares (andar1;...;andar10)
#
# Guarda os dados na label dados
#
# Usa labels para guardar strings importantes, como os comandos e mensagens de erro, ou até mensagens de formatação
#
# Arquitetura geral do sistema:
# - carregar_dados <- carrega dados em "dados.txt"
# É necessário que exista o arquivo "dados.txt" no diretorio do sistema - Se "dados.txt" nao estiver formatado, o sistema formatará todo seu conteúdo
# --
# - OBSERVAÇÃO: Por algum motivo, syscall 13 (abrir arquivo) sempre retornava erro. Pesquisei sobre, e achei uma seção no stackoverflow que -
#            -> dizia ter o mesmo problema, e para corrigir teve que mover mars45.jar para o diretorio do arquivo, eu fiz isso e resolveu   -
# --
# - input <- Move comando do usuário para label 'cmd'
# - resolve_cmd <- interpreta cmd
# - (Adicionei também o comando 'sair', não estava nos requisitos mas é util ter essa forma de encerrar o programa)

# Pontos importantes:
#
# - get_arg(str, indice, separador) <- inicio da string após o enésimo separador. Ex:
#     * get_arg(comando-arg1-arg2, 1, '-') = arg1
#     * get_arg(comando-arg1, 2, '-') = "Erro poucos argumentos"
#
# - Adição / remoção de moradores ou automóveis:
#     * Campos de nome tanto de morador, quando te informações do auto tem 50 caracteres, digitar mais do que isso levará a comportamento inesperado
#     * Ao remover um morador, o sistema recursivamente sobreescreve ele com o proximo morador. Ex: rm_morador-101-maria ->
#         -> joao______,maria______,davi_____,jorge______,_______ -> joao_____,davi____,davi_____,jorge____ -> joao____,davi_____,jorge____,jorge ->
#         -> veja que 'jorge' etá repetido nesse caso. Mas não importa, pois o sistema sabe que só tem os primeiros 3 moradores
#     * A mesma coisa vale para remover automoveis. Existe apenas uma diferença sutil, pois o sistema guarda o tipo_automovel, que é: ->
#        {0: garagem vazia, 1: possui carro, 2: possui moto, 3: possui 2 motos}
#
# - Getters: O sistema possui algumas 'funções' getters, que retornam o inicio da string desejada. Ex: get_apto_data 0, 3 = primeiro andar, apto 4
#     * Esses getters geralmente funcionam pegando diretamente a posição. Por exemplo, se $a0 sao os dados de um apto, 257($a0) sempre é o tipo_automovel
#
# - Funçoes de string personalizadas: O sistema possui 'funçoes' como strcpy personalizadas por exemplo. strcpy(dest, src, endDest, endSrc) ->
#     -> dest/src : string, endDest: Caractere a ser colocado no final da copia, endsrc: caractere final de src. Ex: ->
#     -> strcpy("destino_", "Davi Pires\0", '_', '\0') = {destino = "Davi Pires_"}
#
# Fim de cabeçalho

.macro print_label (%str, %terminador) # Imprime label e quebra linha
    la $t2, %str # t2 <- string
    li $t1, %terminador # t1 <- terminador
    print_label_loop:
        lb $t0, 0($t2) # t0 <- caractere atual
        beq $t0, $zero, print_label_end # Se for '\0', encerra
        beq $t0, $t1, print_label_end # Se for terminador, encerra
        li $v0, 11 # Imprime caractere
        move $a0, $t0
        syscall
        addi $t2, $t2, 1 # Avança para próximo caractere
        j print_label_loop
    print_label_end:
        li $a0, 10 # Quebra linha
        li $v0, 11
        syscall
.end_macro

.macro print_label_s_quebra (%str, %terminador) # Imprime label
    la $t2, %str # t2 <- string
    li $t1, %terminador # t1 <- terminador
    print_label_s_quebra_loop:
        lb $t0, 0($t2) # t0 <- caractere atual
        beq $t0, $zero, print_label_s_quebra_end # Se for '\0', encerra
        beq $t0, $t1, print_label_s_quebra_end # Se for terminador, encerra
        li $v0, 11 # Imprime caractere
        move $a0, $t0
        syscall
        addi $t2, $t2, 1 # Avança para próximo caractere
        j print_label_s_quebra_loop
    print_label_s_quebra_end:
        nop
.end_macro

.macro print_string (%str, %terminador) # Imprime string e quebra linha
    move $t2, %str # t2 <- str
    li $t1, %terminador # t1 <- terminador
    print_string_loop:
        lb $t0, 0($t2) # t0 <- caractere atual
        beq $t0, $zero, print_string_end # Se for '\0', encerra
        beq $t0, $t1, print_string_end # Se for terminador, encerra
        li $v0, 11 # Imprime caractere
        move $a0, $t0
        syscall
        addi $t2, $t2, 1 # Avança para próximo caractere
        j print_string_loop
    print_string_end:
        li $a0, 10 # Quebra linha
        li $v0, 11
        syscall
.end_macro

.macro print_int (%int) # Imprime int e quebra linha
    move $a0, %int
    li $v0, 1
    syscall
    li $a0, 10
    li $v0, 11
    syscall
.end_macro

.macro print_int_s_quebra (%int) # Imprime int
    move $a0, %int
    li $v0, 1
    syscall
.end_macro
    
.data
# Espaços

cmd: .space 100 # cmd <- Espaço reservado para o input do usuario
dados: .space 20000 # dados <- Espaço reservado para dados do sistema

# Comandos

ad_morador: .asciiz "ad_morador"
rm_morador: .asciiz "rm_morador"
ad_auto: .asciiz "ad_auto"
rm_auto: .asciiz "rm_auto"
limpar_ap: .asciiz "limpar_ap"
info_ap: .asciiz "info_ap"
info_geral: .asciiz "info_geral"
salvar: .asciiz "salvar"
recarregar: .asciiz "recarregar"
formatar: .asciiz "formatar"
sair: .asciiz "sair"
all: .asciiz "all" # all <- string para comando info_ap-->all<-

# Strings
dados_txt: .asciiz "dados.txt" # dados_txt <- caminho para arquivo de salvamento
banner: .asciiz "D-shell>>" # banner <- banner a ser impresso
tab: .asciiz "    " # tab <- Espaço para formatação
erro_0: .asciiz "Funcao esperava mais argumentos"
AP: .asciiz "AP:"
Moradores: .asciiz "Moradores:"
Carro: .asciiz "Carro:"
Modelo: .asciiz "Modelo: "
Cor: .asciiz "Cor: "
Moto: .asciiz "Moto:"
Apartamento_vazio: .asciiz "Apartamento vazio"
Nao_vazios: .asciiz "Nao vazios:    "
espaco: .asciiz " "
Vazios: .asciiz "Vazios:        "

# Falhas

falha_ap_invalido: .asciiz "Falha: AP invalido"
falha_ap_qtd_maxima_moradores: .asciiz "Falha: AP com numero max de moradores"
falha_morador_nao_encontrado: .asciiz "Falha: morador nao encontrado"
falha_tipo_invalido: .asciiz "Falha: tipo invalido"
falha_automovel_nao_encontrado: .asciiz "Falha: automovel_nao_encontrado"
falha_qtd_maxima_auto: .asciiz "Falha: AP com numero max de automoveis"
Comando_invalido: .asciiz "Comando invalido"
Erro_ao_salvar: .asciiz "Erro ao salvar"

.text
.globl main

main:
    jal carregar_dados # Carrega dados do arquivo
    main_loop:
        jal print_banner # Imprime banner
        jal input # Lê string do teclado e armazena em cmd
        jal resolve_cmd # Interpreta comando do usuário
        bgez $v0, main_loop # Se retornou 0, repete
    li $v0, 10 # Senão, encerra programa
    syscall

input: # input: Lê input do teclado e salva em cmd
    la $t0, cmd # t0 <- cmd
    li $t1, 0 # t1 <- indice = 0
    input_loop:
        li $v0, 12 # Código do syscall para ler caractere  
        syscall # Lê caractere
        move $t2, $v0 # t2 <- caractere digitado
        add $t3, $t1, $t0 # $t3 <- cmd[ind]
        sb $t2, 0($t3) # cmd[ind] = caractere
        addi $t1, $t1, 1 # indice++
        bne $t2, 10, input_loop # Repete até digitar enter
    sb $zero, 0($t3) # String termina em caractere nulo
    move $v0, $t0 # Retorna inicio de cmd
    jr $ra # Retorna
        
get_arg: # recebe sequencia de strings em a0 separadas por um separador guardado em a2, e retorna a substring a1
    move $t0, $a0 # t0 <- string = a0
    move $t1, $a1 # t1 <- indice = a1
    move $t6, $a2 # t2 <- separador = a2
    li $t2, 0 # t2 <- indice atual
    li $t3, -1 # t3 <- contador de caracteres
    get_arg_loop: # Entra em loop até encontrar certa quantidade de separador
        addi $t3, $t3, 1 # t3 <- incrementa contador
        add $t4, $t0, $t3 # t4 <- string[contador]
        beq $t2, $t1 end_get_arg_loop # se indice atual == indice desejado, sai do loop
        lb $t5, 0($t4) # t5 <- caractere atual
        beqz $t5, print_error_few_args # Se string acabou, faltou argumentos
        beq $t5, $t6, incrementa_indice # Se encontrou um separador, incrementa indice atual
        j get_arg_loop # Repete
        incrementa_indice:
            addi $t2, $t2, 1 # t2 <- indice atual++
            j get_arg_loop # Repete
    
    end_get_arg_loop:
        move $v0, $t4 # Retorna o inicio da substring desejada
        jr $ra
        
    print_error_few_args: # Imprime erro de poucos argumentos
        li $v0, -1 # Retorna -1
        jr $ra
    

resolve_cmd: # Diz qual é o comando digitado pelo usuario, e executa funçao equivalente
    addi $sp, $sp, -4 # aloca espaço na pilha
    sw $ra, 0($sp) # salva endereço de retorno
    
    # verifica ad_morador
    la $a0, cmd # carrega cmd em a0
    la $a1, ad_morador
    li $a2, 45 # termina em '-'
    li $a3, 0 # segunda string termina em \0
    jal strcmp # compara cmd com "ad_morador"
    beqz $v0, run_ad_morador_cmd
    
    la $a0, cmd
    la $a1, info_ap
    li $a2, 45
    li $a3, 0 # segunda string termina em \0
    jal strcmp # compara cmd com "info_ap"
    beqz $v0, run_info_ap_cmd
    
    la $a0, cmd
    la $a1, rm_morador
    li $a2, 45
    li $a3, 0 # segunda string termina em \0
    jal strcmp # compara cmd com "rm_morador"
    beqz $v0, run_rm_morador_cmd
    
    la $a0, cmd
    la $a1, ad_auto
    li $a2, 45
    li $a3, 0 # segunda string termina em \0
    jal strcmp # compara cmd com "ad_auto"
    beqz $v0, run_ad_auto_cmd
    
    la $a0, cmd
    la $a1, rm_auto
    li $a2, 45
    li $a3, 0 # segunda string termina em \0
    jal strcmp # compara cmd com "rm_auto"
    beqz $v0, run_rm_auto_cmd
    
    la $a0, cmd
    la $a1, limpar_ap
    li $a2, 45
    li $a3, 0 # segunda string termina em \0
    jal strcmp # compara cmd com "limpar_ap"
    beqz $v0, run_limpar_ap_cmd
    
    la $a0, cmd
    la $a1, info_geral
    li $a2, 0
    li $a3, 0 # segunda string termina em \0
    jal strcmp # compara cmd com "info_geral"
    beqz $v0, run_info_geral_cmd
    
    la $a0, cmd
    la $a1, salvar
    li $a2, 0
    li $a3, 0 # segunda string termina em \0
    jal strcmp # compara cmd com "salvar"
    beqz $v0, run_salvar_cmd
    
    la $a0, cmd
    la $a1, recarregar
    li $a2, 0
    li $a3, 0 # segunda string termina em \0
    jal strcmp # compara cmd com "recarregar"
    beqz $v0, run_recarregar_cmd
    
    la $a0, cmd
    la $a1, formatar
    li $a2, 0
    li $a3, 0 # segunda string termina em \0
    jal strcmp # compara cmd com "formatar"
    beqz $v0, run_formatar_cmd
    
    la $a0, cmd
    la $a1, sair
    li $a2, 0
    li $a3, 0 # segunda string termina em \0
    jal strcmp # compara cmd com "sair"
    li $v0, -1 # retorna -1
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
    print_label Comando_invalido 0 # Senão, imprime comando invalido

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
    run_ad_morador_cmd:
        jal ad_morador_cmd
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
    run_info_ap_cmd:
        jal info_ap_cmd
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
    run_rm_morador_cmd:
        jal rm_morador_cmd
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
    run_ad_auto_cmd:
        jal ad_auto_cmd
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
    run_rm_auto_cmd:
        jal rm_auto_cmd
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
    run_limpar_ap_cmd:
        jal limpar_ap_cmd
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
    
    run_info_geral_cmd:
        jal info_geral_cmd
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
    run_salvar_cmd:
        jal salvar_dados
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
    run_recarregar_cmd:
        jal carregar_dados
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
    run_formatar_cmd:
        jal formatar_dados
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
    
info_geral_cmd: # Imprime panorama geral de aptos vazios e nao vazios
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    la $s1, dados # s1 <- dados
    li $s2, 0 # s1 <- contador de apartamentos nao vazios
    li $s3, 0 # s2 <- contador de andar
    info_geral_andar_loop:
        li $s4, 0 # s3 <- contador de aptos
        info_geral_apto_loop:
            move $a0, $s3 # a0 <- indice do andar
            move $a1, $s4 # a1 <- indice do apto
            jal get_apto_data # v0 <- dados do apto
            move $a0, $v0 # a0 <- dados do apto
            jal get_qtd_moradores_from_data # v0 <- qtd_moradores
            beqz $v0, info_geral_skip_incremento # Se vazio, nao incrementa
            addi $s2, $s2, 1 # Incrementa contador de aptos nao vazios
            info_geral_skip_incremento:
            addi $s4, $s4, 1 # Incrementa contador de apto
            blt $s4, 4, info_geral_apto_loop # Se nao contou os 4 aptos, repete
        addi $s3, $s3, 1 # Incrementa contador de andar
        blt $s3, 10, info_geral_andar_loop # Se nao contou os 10 aptos, repete
    # s5 <- aptos nao vazios, s4 <- porcentagem aptos nao vazios
    # s3 <- aptos vazios, s2 <- porcentagem aptos vazios
    move $s5, $s2 # s5 <- qtd aptos nao vazios
    mul $s4, $s5, 10 # s4 <- porcentagem aptos nao vazios
    div $s4, $s4, 4
    li $t0, 40 # t0 <- qtd aptos
    sub $s3, $t0, $s5 # s3 <- 40 - aptos nao vazios = aptos vazios
    mul $s2, $s3, 10
    div $s2, $s2, 4 # s2 <- porcentagem aptos vazios
    # Imprime info geral formatada
    jal quebra_linha
    print_label_s_quebra Nao_vazios 0 # Imprime "Nao vazios:    "
    print_int_s_quebra $s5 # Imprime qtd aptos nao vazios
    print_label_s_quebra espaco 0 # Imprime ' '
    li $a0, 40 # '(' em ascii
    li $v0 11 # imprimir caractere
    syscall # Imprime '('
    print_int_s_quebra $s4 # Imprime porcentagem de aptos nao vazios
    li $a0, 37 # '%' em ascii
    li $v0 11 # Imprimir caractere
    syscall # Imprime '%'
    li $a0, 41 # ')' em ascii
    li $v0 11 # Imprimir caractere
    syscall # Imprime ')'
    jal quebra_linha
    print_label_s_quebra Vazios 0 # Imprime "Vazios:        "
    print_int_s_quebra $s3 # Imprime qtd aptos vazios
    print_label_s_quebra espaco 0 # Imprime ' '
    li $a0, 40 # '(' em ascii
    li $v0 11 # imprimir caractere
    syscall # Imprime '('
    print_int_s_quebra $s2 # Imprime porcentagem de aptos vazios
    li $a0, 37 # '%' em ascii
    li $v0 11 # Imprimir caractere
    syscall # Imprime '%'
    li $a0, 41 # ')' em ascii
    li $v0 11 # Imprimir caractere
    syscall # Imprime ')'
    jal quebra_linha
    
    lw $ra, 0($sp) # finaliza
    jr $ra
    
print_info_ap: # Recebe em a0 o indice do andar, em a1 o indice do apto, imprime ap formatado e retorna 1. retorna 0 se ap estiver vazio 
    addi $sp, $sp, -4 # aloca espaço na pilha
    sw $ra, 0($sp) # salva endereço de retorno
    
    move $s5, $a0
    move $s6 $a1
    jal get_apto_data # v0 <- dados do apto
    move $s2, $v0 # s2 <- dados do apto
    move $a0, $s2 # a0 <- dados do apto
    jal get_qtd_moradores_from_data # v0 <- qtd_moradores
    beqz $v0, finaliza # se vazio vai para info_ap_vazio
    move $s3, $v0 # s3 <- qtd_moradores
    jal quebra_linha
    print_label_s_quebra AP 0 # Imprime "AP: "
    addi $t0, $s5, 1 # t0 <- Incrementa 1 para formatar o andar
    print_int_s_quebra $t0 # Imprime andar
    li $a0 0 # Imprime 0
    li $v0 1
    syscall
    addi $t0, $s6, 1 # t0 <- Incrementa 1 ao apto
    print_int_s_quebra $t0 # Imprime apto
    li $a0 10 # Quebra linha
    li $v0 11
    syscall
    
    print_label Moradores 0 # Imprime 'Moradores:'
    li $s4, 0 # s4 = contador <- 0
    print_moradores_loop:
        print_label_s_quebra tab 0 # Imprime 4 espaços
        move $a0, $s2 # a0 <- dados do apto
        move $a1, $s4 # a1 <- contador
        jal get_morador_from_idx # v0 <- nome do morador atual
        print_string $v0, 95 # Imprime nome com terminador '_'
        addi $s4, $s4, 1 # Incrementa contador
        bne $s4, $s3 print_moradores_loop # Se nao chegou no fim, repete
    move $a0, $s2 # a0 <- dados do apto
    jal get_tipo_auto_from_data # v0 <- tipo auto (0 = vazio, 1 = carro, 2 = moto, 3 = 2 motos)
    beqz $v0, finaliza # Se vazio, finaliza
    beq $v0, 1, print_carro # Se possui carro, vai para print_carro
    beq $v0, 2, print_moto # Se possui moto, vai para print moto
    beq $v0, 3, print_2_motos # Se possui 2 motos, vai para print_2_motos
    print_carro:
        print_label Carro 0
        move $a0, $s2 # s2 <- dados do apto
        li $a1, 0 # Carro sempre esta no indice 0
        jal get_auto_from_idx # v0 <- modelo, v1 <- cor
        move $s5, $v0 # s5 <- modelo
        move $s6, $v1 # s6 <- cor
        print_label_s_quebra tab 0
        print_label_s_quebra Modelo 0 # Imprime 'Modelo: '
        print_string $s5 95 # Imprime <modelo>
        print_label_s_quebra tab 0
        print_label_s_quebra Cor 0 # Imprime 'Cor: '
        print_string $s6 95 # Imprime <cor>
        jal quebra_linha
        j finaliza
    
    print_moto:
        print_label Moto 0
        move $a0, $s2 # s2 <- dados do apto
        li $a1, 0 # Moto esta no indice 0
        jal get_auto_from_idx # v0 <- modelo, v1 <- cor
        move $s5, $v0 # s5 <- modelo
        move $s6, $v1 # s6 <- cor
        print_label_s_quebra tab 0
        print_label_s_quebra Modelo 0 # Imprime 'Modelo: '
        print_string $s5 95 # Imprime <modelo>
        print_label_s_quebra tab 0
        print_label_s_quebra Cor 0 # Imprime 'Cor: '
        print_string $s6 95 # Imprime <cor>
        jal quebra_linha
        j finaliza
    
    print_2_motos:
        print_label Moto 0
        move $a0, $s2 # s2 <- dados do apto
        li $a1, 0 # Moto esta no indice 0
        jal get_auto_from_idx # v0 <- modelo, v1 <- cor
        move $s5, $v0 # s5 <- modelo
        move $s6, $v1 # s6 <- cor
        print_label_s_quebra tab 0
        print_label_s_quebra Modelo 0 # Imprime 'Modelo: '
        print_string $s5 95 # Imprime <modelo>
        print_label_s_quebra tab 0
        print_label_s_quebra Cor 0 # Imprime 'Cor: '
        print_string $s6 95 # Imprime <cor>
        move $a0, $s2 # s2 <- dados do apto
        li $a1, 1 # 2 moto esta no indice 1
        jal get_auto_from_idx # v0 <- modelo, v1 <- cor
        move $s5, $v0 # s5 <- modelo
        move $s6, $v1 # s6 <- cor
        print_label_s_quebra tab 0
        print_label_s_quebra Modelo 0 # Imprime 'Modelo: '
        print_string $s5 95 # Imprime <modelo>
        print_label_s_quebra tab 0
        print_label_s_quebra Cor 0 # Imprime 'Cor: '
        print_string $s6 95 # Imprime <cor>
        jal quebra_linha
        j finaliza
    
    finaliza:
        nop
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
info_ap_cmd:
    addi $sp, $sp, -4 # aloca espaço na pilha
    sw $ra, 0($sp) # salva endereço de retorno
    
    la $a0, cmd # Carrega o comando para a0
    li $a1, 1 # Indice <- 1
    li $a2, 45 # Separador <- -
    jal get_arg # Extrai o primeiro argumento da função (v0 <- apto)
    bltz $v0, info_ap_few_args
    move $s1, $v0 # s1 <- apto
    move $a0, $s1 # a0 <- primeiro argumento da funçao
    la $a1, all # a1 <- 'all'
    li $a2, 0 # argumento finaliza em \0
    li $a3, 0 # 'all' finaliza em \0
    jal strcmp # v0 <- 0 se a0 == "all", senão 1
    beqz $v0, print_all # se usuario digitou 'all' imprime todos os aptos
    move $a0, $s1 # a0 <- apto
    li $a1, 0 # terminador <- \0
    jal get_apto # v0 <- indice do andar, v1 <- indice do apto
    beq $v0, -1, info_ap_falha_ap_invalido
    move $s1, $v0 # s1 <- indice do andar
    move $s7, $v1 # s7 <- indice do apto
    move $a0, $v0 # a0 <- indice do andar
    move $a1, $v1 # v1 <- indice do apto
    jal get_apto_data # v0 <- dados do apto
    move $a0, $v0 # a0 <- dados do apto
    jal get_qtd_moradores_from_data # v0 <- qtd moradores
    beqz $v0, print_ap_vazio
    move $a0, $s1 # a0 <- indice do andar
    move $a1, $s7 # s7 <- indice do apto
    jal print_info_ap # Imprime apto
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
    print_all:
        li $s1, 0 # s1 <- contador de andar = 0
        print_andar_loop:
            li $s7, 0 # s7 <- contador de apto = 0
            print_apto_loop:
                move $a0, $s1 # a0 <- andar
                move $a1, $s7 # a1 <- apto
                jal print_info_ap # Imprime apto atual
                addi $s7, $s7, 1 # Passa para o proximo apto
                blt $s7, 4, print_apto_loop # Se nao imprimiu os 4 aptos, repete
            addi $s1, $s1, 1
            blt $s1, 10, print_andar_loop # Se nao imprimiu os 10 andares, repete
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
    
    print_ap_vazio:
        print_label Apartamento_vazio 0
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
    
    info_ap_falha_ap_invalido:
        print_label falha_ap_invalido 0
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
    info_ap_few_args:
        print_label erro_0 0
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra    
    
ad_morador_cmd: # Adiciona morador
    addi $sp, $sp, -4 # aloca espaço na pilha
    sw $ra, 0($sp) # salva endereço de retorno
    
    la $a0, cmd # Carrega o comando para a0
    li $a1, 1 # Indice <- 1
    li $a2, 45 # Separador <- '-'
    jal get_arg # Extrai o primeiro argumento da funçao (apto)
    bltz $v0, ad_morador_few_args
    move $s1, $v0 # s1 <- Apto
    move $a0, $s1 # a0 <- Apto
    li $a1, 45 # Terminador <- '-'
    jal get_apto_data_from_string # v0 <- dados do apto
    move $s4, $v0 # s4 <- dados do apto
    beq $v0, -1, ad_morador_ap_invalido
    
    move $a0, $s4 # a0 <- dados do apto
    jal get_qtd_moradores_from_data
    move $s5, $v0
    
    bge $s5, 5, qtd_maxima_moradores # 5 é a quantidade maxima
    
    la $a0, cmd # a0 <- comando
    li $a1, 2 # indice <- 2
    li $a2, 45 # separador <- '-'
    jal get_arg # v0 <- nome_morador
    bltz $v0, ad_morador_few_args
    move $s6, $v0 # s6 <- nome_morador
    
     # s5 <- andar[qtd_moradores + 1]
    addi $s5, $s5, 49
    sb $s5, 0($s4) # passa de int para ascii e salva
    addi $s5, $s5, -48 # qtd_moradores++
    move $a0, $s4 # a0 <- dados do andar
    move $a1, $s5 # a1 <- qtd_moradores
    li $a2, 44 # separador <- ','
    jal get_arg # v0 <- andar[qtd_moradores]
    bltz $v0, ad_morador_few_args
    move $s4, $v0 # s4 <- andar[qtd_moradores]
    move $a0, $s4 # a0 <- andar[qtd_moradores]
    move $a1, $s6 # a1 <- nome_morador
    li $a2, 95 # terminador <- '_'
    li $a3, 0 # terminador2 <- '\0'
    jal strcpy # andar[qtd_moradores] <- nome_morador
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
    ad_morador_ap_invalido:
        print_label falha_ap_invalido, 0
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
    qtd_maxima_moradores:
        print_label falha_ap_qtd_maxima_moradores, 0
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
    ad_morador_few_args:
        print_label erro_0, 0
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
rm_morador_cmd: # Remove morador
    addi $sp, $sp, -4 # aloca espaço na pilha
    sw $ra, 0($sp) # salva endereço de retorno
    
    la $a0, cmd # Carrega o comando para a0
    li $a1, 1 # Indice <- 1
    li $a2, 45 # Separador <- '-'
    jal get_arg # Extrai o primeiro argumento da funçao (apto)
    bltz $v0, rm_morador_few_args
    move $s1, $v0 # s1 <- Apto
    move $a0, $s1 # a0 <- Apto
    li $a1, 45 # Terminador <- '-'
    jal get_apto_data_from_string # v0 <- dados do apto
    move $s2, $v0 # s2 <- dados do apto
    beq $s2, -1, rm_morador_ap_invalido
    la $a0, cmd # Carrega o comando para a0
    li $a1, 2 # Indice <- 2
    li $a2, 45 # Separador <- '-'
    jal get_arg # v0 <- nome do morador
    bltz $v0, rm_morador_few_args
    move $s3, $v0 # s3 <- nome do morador
    move $a0, $s2 # a0 <- dados do apto
    move $a1, $s3 # a1 <- nome do morador
    jal get_morador_idx_from_string # v0 <- indice do morador
    move $s4, $v0 # s4 <- indice do morador
    beq $s4, -1, rm_morador_not_found
    move $a0, $s2 # s2 <- dados do apto
    jal get_qtd_moradores_from_data # v0 <- qtd_moradores
    move $s5, $v0 # s5 <- qtd_moradores
    addi $s5, $s5, -1 # Diminui 1 para achar indice
    rm_morador_loop: # Começando do morador a ser removido, copia o proximo para si, sobrescrevendo-o
        beq $s4, $s5, rm_morador_end # Se chegou no ultimo, finaliza
        move $a0, $s2 # a0 <- dados do apto
        move $a1, $s4 # a1 <- indice do morador atual
        jal get_morador_from_idx # v0 <- morador atual
        move $s6, $v0 # s6 <- morador atual
        addi $s4, $s4, 1 # incrementa indice
        move $a0, $s2 # a0 <- dados do projeto
        move $a1, $s4 # a1 <- indice do proximo morador
        jal get_morador_from_idx # v0 <- proximo morador
        move $s7, $v0 # s7 <- proximo morador
        move $a0, $s6 # a0 <- morador atual
        move $a1, $s7 # a0 <- proximo morador
        li $a2, 95 # Nome do morador termina em '_'
        li $a3, 95 
        jal strcpy # Copia proximo morador para morador atual
        j rm_morador_loop
    rm_morador_end:
        lb $t0, 0($s2) # t0 <- qtd_moradores
        addi $t0, $t0, -1 # qtd_moradores--
        sb $t0, 0($s2)
        bne $t0, 48, rm_morador_end_possui_morador # Se tem 0 moradores, esvazia garagem
        sb $t0, 257($s2) # tipo automovel = 0
    
    rm_morador_end_possui_morador:
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
    rm_morador_ap_invalido:
        print_label falha_ap_invalido, 0
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
    rm_morador_not_found:
        print_label falha_morador_nao_encontrado, 0
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
    rm_morador_few_args:
        print_label erro_0, 0
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
limpar_ap_cmd: # Limpa o ap (põe 0 em qtd moradores e 0 em garagem)
    addi $sp, $sp, -4 # aloca espaço na pilha
    sw $ra, 0($sp) # salva endereço de retorno
    
    la $a0, cmd # Carrega o comando para a0
    li $a1, 1 # Indice <- 1
    li $a2, 45 # Separador <- '-'
    jal get_arg # Extrai o primeiro argumento da funçao (apto)
    bltz $v0, limpar_ap_few_args
    move $s1, $v0 # s1 <- Apto
    move $a0, $s1 # a0 <- Apto
    li $a1, 0 # Terminador <- '\0'
    jal get_apto_data_from_string # v0 <- dados do apto
    move $s4, $v0 # s4 <- dados do apto
    beq $v0, -1, limpar_ap_ap_invalido
    li $t0, 48 # t0 <- '0' em ascii
    sb $t0, 0($s4) # qtd_moradores = 0
    sb $t0, 257($s4) # tipo automovel = 0
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
    limpar_ap_ap_invalido:
        print_label falha_ap_invalido 0
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
    limpar_ap_few_args:
        print_label erro_0 0
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra

ad_auto_cmd: # Adiciona automovel
    addi $sp, $sp, -4 # aloca espaço na pilha
    sw $ra, 0($sp) # salva endereço de retorno
    
    la $a0, cmd # Carrega o comando para a0
    li $a1, 1 # Indice <- 1
    li $a2, 45 # Separador <- '-'
    jal get_arg # Extrai o primeiro argumento da funçao (apto)
    bltz $v0, ad_auto_few_args
    move $s1, $v0 # s1 <- Apto
    move $a0, $s1 # a0 <- Apto
    li $a1, 45 # Terminador <- '-'
    jal get_apto_data_from_string # v0 <- dados do apto
    move $s4, $v0 # s4 <- dados do apto
    beq $v0, -1, ad_auto_ap_invalido
    
    la $a0, cmd
    li $a1 2 # Indice <- 2
    jal get_arg # v0 <- tipo novo automovel
    bltz $v0, ad_auto_few_args
    lb $v0, 0($v0)
    seq $s2, $v0, 99 # s2 <- (tipo == c)
    seq $s3, $v0, 109 # s3 <- (tipo == m)
    or $s3, $s2, $s3 # s3 <- carro ou moto
    beqz $s3, ad_auto_falha_tipo_invalido # se nem carro nem moto, falha tipo invalido
    
    la $a0, cmd # a0 <- comando
    li $a1, 3 # indice <- 2
    li $a2, 45 # separador <- '-'
    jal get_arg # v0 <- modelo_automovel
    bltz $v0, ad_auto_few_args
    move $s6, $v0 # s6 <- modelo_automovel
    la $a0, cmd # a0 <- comando
    li $a1, 4 # indice <- 3
    li $a2, 45 # separador <- '-'
    jal get_arg # v0 <- cor_automovel
    bltz $v0, ad_auto_few_args
    move $s7, $v0 # s7 <- cor_automovel
    
    move $a0, $s4 # a0 <- dados do apto
    jal get_tipo_auto_from_data # v0 <- tipo_auto ( 0 = vazio, 1 = carro, 2 = moto, 3 = 2 motos)
    move $s5, $v0 # s5 <- tipo auto
    seq $t0, $s5, 0 # Garagem vazia
    seq $t1, $s5, 1 # Possui carro
    seq $t2, $s5, 2 # Possui moto
    seq $t3, $s5, 3 # Possui 2 motos
    beq $t3, 1, ad_auto_falha_qtd_maxima_auto # Se possui 2 motos, atingiu limite de automoveis
    beq $t1, 1, ad_auto_falha_qtd_maxima_auto # Se possui carro, atingiu limite de automoveis
    and $t4, $t2, $s2 # t4 <- carro and possui moto
    beq $t4, 1, ad_auto_falha_qtd_maxima_auto # Se possui moto e deseja adicionar carro, atingiu limite de automoveis
    and $t5, $t0, $s2 # Se garagem vazia e adiciona carro
    beq $t5, 1, ad_auto_carro # Vai para adicionar carro
    not $s2, $s2 # s2 <- adicionar moto
    and $t5, $t0, $s2 # Se garagem vazia e adiciona moto
    beq $t5, 1, ad_auto_moto # Vai para adicionar moto
    and $t5, $t2, $s2 # Se possui 1 moto e deseja adicionar moto
    beq $t5, 1, ad_auto_2_moto # vai para adicionar 2 moto
    
    ad_auto_carro: #adiciona carro
        li $t0, 49 # t0 <- '1' em ascii (1 = possui carro)
        sb $t0, 257($s4) # Coloca '1' no espaço do tipo automovel
        move $a0, $s4 # a0 <- dados do apto
        li $a1, 0 # a1 <- indice do carro a ser adicionado (sempre é 0)
        jal get_auto_from_idx # v0 <- inicio da string do modelo, v1 <- inicio da string da cor
        move $s1, $v1 # s1 <- cor_automovel
        move $a0, $v0 # a0 <- inicio da string do modelo
        move $a1, $s6 # a1 <- modelo automovel
        li $a2, 95 # Finaliza string com '_'
        li $a3, 45 # Modelo termina com '-'
        jal strcpy # Copia modelo para o namespace de modelo
        move $a0, $s1 # a0 <- inicio da string da cor
        move $a1, $s7 # a1 <- cor automovel
        li $a2, 95 # Finaliza string com '_'
        li $a3, 0 # cor termina em '\0'
        jal strcpy # Copia cor para o namespace de cor
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
    
    ad_auto_moto:
        li $t0, 50 # t0 <- '2' em ascii
        sb $t0, 257($s4) # Coloca '2' no espaço do tipo automovel (2 = possui 1 moto)
        move $a0, $s4 # a0 <- dados do apto
        li $a1, 0 # a1 <- indice da moto a ser adicionada (sempre é 0)
        jal get_auto_from_idx # v0 <- inicio da string do modelo, v1 <- inicio da string da cor
        move $s1, $v1 # s1 <- cor_automovel
        move $a0, $v0 # a0 <- inicio da string do modelo
        move $a1, $s6 # a1 <- modelo automovel
        li $a2, 95 # Finaliza string com '_'
        li $a3, 45 # Modelo termina com '-'
        jal strcpy # Copia modelo para o namespace de modelo
        move $a0, $s1 # a0 <- inicio da string da cor
        move $a1, $s7 # a1 <- cor automovel
        li $a2, 95 # Finaliza string com '_'
        li $a3, 0 # cor termina em '\0'
        jal strcpy # Copia cor para o namespace de cor
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
    
    ad_auto_2_moto:
        li $t0, 51 # t0 <- '3' em ascii
        sb $t0, 257($s4) # Coloca '3' no espaço do tipo automovel (3 = possui 2 motos)
        move $a0, $s4 # a0 <- dados do apto
        li $a1, 1 # a1 <- indice da moto a ser adicionada (sempre é 1)
        jal get_auto_from_idx # v0 <- inicio da string do modelo, v1 <- inicio da string da cor
        move $s1, $v1 # s1 <- cor_automovel
        move $a0, $v0 # a0 <- inicio da string do modelo
        move $a1, $s6 # a1 <- modelo automovel
        li $a2, 95 # Finaliza string com '_'
        li $a3, 45 # Modelo termina com '-'
        jal strcpy # Copia modelo para o namespace de modelo
        move $a0, $s1 # a0 <- inicio da string da cor
        move $a1, $s7 # a1 <- cor automovel
        li $a2, 95 # Finaliza string com '_'
        li $a3, 0 # cor termina em '\0'
        jal strcpy # Copia cor para o namespace de cor
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
    
    ad_auto_falha_tipo_invalido:
        print_label falha_tipo_invalido, 0
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
    ad_auto_falha_qtd_maxima_auto:
        print_label falha_qtd_maxima_auto, 0
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
    ad_auto_ap_invalido:
        print_label falha_ap_invalido, 0
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
    
    ad_auto_few_args:
        print_label erro_0 0
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra

rm_auto_cmd: # Remove um automovel
    addi $sp, $sp, -4 # aloca espaço na pilha
    sw $ra, 0($sp) # salva endereço de retorno
    
    la $a0, cmd # Carrega o comando para a0
    li $a1, 1 # Indice <- 1
    li $a2, 45 # Separador <- '-'
    jal get_arg # Extrai o primeiro argumento da funçao (apto)
    bltz $v0, rm_auto_few_args
    move $s1, $v0 # s1 <- Apto
    move $a0, $s1 # a0 <- Apto
    li $a1, 45 # Terminador <- '-'
    jal get_apto_data_from_string # v0 <- dados do apto
    move $s2, $v0 # s2 <- dados do apto
    beq $v0, -1, rm_auto_ap_invalido # se retornou -1, ap invalido
    
    la $a0, cmd
    li $a1 2 # Indice <- 2
    jal get_arg # v0 <- tipo novo automovel
    bltz $v0, rm_auto_few_args
    lb $v0, 0($v0) # v0 <- tipo novo automovel
    seq $s3, $v0, 99 # s3 <- (tipo == c)
    seq $s4, $v0, 109 # s4 <- (tipo == m)
    or $s4, $s3, $s4 # s4 <- carro ou moto
    beqz $s4, rm_auto_falha_tipo_invalido # se nem carro nem moto, falha tipo invalido
    
    la $a0, cmd # a0 <- comando
    li $a1, 3 # indice <- 3
    li $a2, 45 # separador <- '-'
    jal get_arg # v0 <- modelo_automovel
    bltz $v0, rm_auto_few_args
    move $s4, $v0 # s4 <- modelo_automovel
    la $a0, cmd # a0 <- comando
    li $a1, 4 # indice <- 4
    li $a2, 45 # separador <- '-'
    jal get_arg # v0 <- cor_automovel
    bltz $v0, rm_auto_few_args
    move $s5, $v0 # s5 <- cor_automovel
    
    move $a0, $s2 # a0 <- dados do apto
    jal get_tipo_auto_from_data # v0 <- tipo_auto ( 0 = vazio, 1 = carro, 2 = moto, 3 = 2 motos)
    seq $t0, $v0, 0 # Garagem vazia
    seq $t1, $v0, 1 # Possui carro
    seq $t2, $v0, 2 # Possui moto
    seq $t3, $v0, 3 # Possui 2 motos
    beq $t0, 1, rm_auto_falha_automovel_nao_encontrado # Se garagem vazia nao foi encontrado
    xor $t5, $s3, $t1 # Se deseja remover carro e nao possui carro, ou deseja remover moto e possui carro
    beq $t5, 1, rm_auto_falha_automovel_nao_encontrado # Se possui carro e deseja remover moto, ou se deseja remover carro e nao o possui
    beq $s3, 1 rm_auto_carro # Se deseja remover carro e possui carro, vai para rm_auto_carro
    beq $t2, 1, rm_auto_moto # Se possui moto, vai para rm_auto_moto
    beq $t3, 1, rm_auto_2_motos # Se possui 2 motos, vai para rm_auto_2_motos
    
    rm_auto_carro: # Trecho de remover carro
        move $a0, $s2 # a0 <- dados do apto
        li $a1, 0 # Carro sempre esta no indice 0
        jal get_auto_from_idx # v0 <- modelo, v1 <- cor
        move $s6, $v0 # s6 <- modelo do carro guardado
        move $s7, $v1 # s7 <- cor do carro guardado
        move $a0, $s4 # a0 <- modelo desejado
        move $a1, $s6 # a1 <- modelo do carro
        li $a2, 45 # a2 <- primeira string termina em '-'
        li $a3, 95 # a3 <- segunda string termina em '_'
        jal strcmp # v0 <- 0 se tem mesmo modelo, senão 1
        bnez $v0, rm_auto_falha_automovel_nao_encontrado # Se difere, falha
        # Se for igual, confere cor
        move $a0, $s5 # a0 <- cor do carro desejado
        move $a1, $s7 # a1 <- cor do carro guardado
        li $a2, 0 # primeira string termina em '\0'
        li $a3, 95 # segunda string termina em '_"
        jal strcmp
        bnez $v0, rm_auto_falha_automovel_nao_encontrado # Se cor difere, falha
        # Senão, remove carro
        move $a0, $s2 # a0 <- dados do apto
        li $a1, 0 # a1 <- indice do automovel (0)
        jal rm_auto_from_idx # remove carro
        # retorna
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
    rm_auto_moto: # Trecho de remover moto
        move $a0, $s2 # a0 <- dados do apto
        li $a1, 0 # moto sempre esta no indice 0
        jal get_auto_from_idx # v0 <- modelo, v1 <- cor
        move $s6, $v0 # s6 <- modelo da moto guardada
        move $s7, $v1 # s7 <- cor da moto guardada
        move $a0, $s4 # a0 <- modelo desejado
        move $a1, $s6 # a1 <- modelo da moto
        li $a2, 45 # a2 <- primeira string termina em '-'
        li $a3, 95 # a3 <- segunda string termina em '_'
        jal strcmp # v0 <- 0 se tem mesmo modelo, senão 1
        bnez $v0, rm_auto_falha_automovel_nao_encontrado # Se difere, falha
        # Se for igual, confere cor
        move $a0, $s5 # a0 <- cor da moto desejada
        move $a1, $s7 # a1 <- cor da moto guardada
        li $a2, 0 # primeira string termina em '\0'
        li $a3, 95 # segunda string termina em '_"
        jal strcmp
        bnez $v0, rm_auto_falha_automovel_nao_encontrado # Se cor difere, falha
        # Senão, remove moto
        move $a0, $s2 # a0 <- dados do apto
        li $a1, 0 # a1 <- indice do automovel (0)
        jal rm_auto_from_idx # remove moto
        # retorna
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
    rm_auto_2_motos: # Trecho de remover moto quando se tem 2 motos
        move $a0, $s2 # a0 <- dados do apto
        li $a1, 0 # moto atual esta no indice 0
        jal get_auto_from_idx # v0 <- modelo, v1 <- cor
        move $s6, $v0 # s6 <- modelo da moto guardada
        move $s7, $v1 # s7 <- cor da moto guardada
        move $a0, $s4 # a0 <- modelo desejado
        move $a1, $s6 # a1 <- modelo da moto
        li $a2, 45 # a2 <- primeira string termina em '-'
        li $a3, 95 # a3 <- segunda string termina em '_'
        jal strcmp # v0 <- 0 se tem mesmo modelo, senão 1
        bnez $v0, rm_auto_segunda_moto # Se difere, vai para a segunda moto
        # Se for igual, confere cor
        move $a0, $s5 # a0 <- cor da moto desejada
        move $a1, $s7 # a1 <- cor da moto guardada
        li $a2, 0 # primeira string termina em '\0'
        li $a3, 95 # segunda string termina em '_"
        jal strcmp
        bnez $v0, rm_auto_segunda_moto # Se cor difere, vai para segunda moto
        # Senão, remove moto
        move $a0, $s2 # a0 <- dados do apto
        li $a1, 0 # a1 <- indice do automovel (0)
        jal rm_auto_from_idx # remove moto
        # retorna
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
    rm_auto_segunda_moto:
        move $a0, $s2 # a0 <- dados do apto
        li $a1, 1 # moto atual esta no indice 1
        jal get_auto_from_idx # v0 <- modelo, v1 <- cor
        move $s6, $v0 # s6 <- modelo da moto guardada
        move $s7, $v1 # s7 <- cor da moto guardada
        move $a0, $s4 # a0 <- modelo desejado
        move $a1, $s6 # a1 <- modelo da moto
        li $a2, 45 # a2 <- primeira string termina em '-'
        li $a3, 95 # a3 <- segunda string termina em '_'
        jal strcmp # v0 <- 0 se tem mesmo modelo, senão 1
        bnez $v0, rm_auto_falha_automovel_nao_encontrado # Se difere, falha
        # Se for igual, confere cor
        move $a0, $s5 # a0 <- cor da moto desejada
        move $a1, $s7 # a1 <- cor da moto guardada
        li $a2, 0 # primeira string termina em '\0'
        li $a3, 95 # segunda string termina em '_"
        jal strcmp
        bnez $v0, rm_auto_falha_automovel_nao_encontrado # Se cor difere, falha
        # Senão, remove moto
        move $a0, $s2 # a0 <- dados do apto
        li $a1, 1 # a1 <- indice do automovel (1)
        jal rm_auto_from_idx # remove moto
        # retorna
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
    rm_auto_falha_tipo_invalido:
        print_label falha_tipo_invalido, 0
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
    
    rm_auto_ap_invalido:
        print_label falha_ap_invalido, 0
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
    rm_auto_falha_automovel_nao_encontrado:
        print_label falha_automovel_nao_encontrado, 0
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
    rm_auto_few_args:
        print_label erro_0, 0
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
rm_auto_from_idx: # Rcebe em a0 dados do apto e em a1 indice do automovel, e o remove
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $s6, 4($sp)
    sw $s7, 8($sp)
    
    move $s7, $a0 # s7 <- dados do apto
    jal get_tipo_auto_from_data # v0 <- tipo_auto (0 = vazio, 1 = carro, 2 = moto, 3 = 2 motos)
    # Se so possui um automovel, so precisa mudar estado para vazio
    beq $v0, 1, rm_auto_from_idx_esvazia_garagem
    beq $v0, 2, rm_auto_from_idx_esvazia_garagem
    # Se possui 2 automoveis:
    beq $a1, 0, rm_auto_from_idx_primeira_moto # Se for a primeira, sobrescreve ela com a segunda
    beq $a1, 1, rm_auto_from_idx_segunda_moto # Se for a segunda, muda estado para apenas uma moto
    
    rm_auto_from_idx_esvazia_garagem:
        li $t0, 48 # '0' em ascii
        sb $t0, 257($a0) # tipo automovel = '0' (vazio)
        
        lw $ra 0($sp) # Restaura regs e retorna
        lw $s6 4($sp)
        lw $s7 8($sp)
        addi $sp, $sp, 12
        jr $ra
        
    rm_auto_from_idx_primeira_moto:
        move $a0, $s7 # a0 <- dados do apto
        li $a1, 1 # a1 <- indice 1
        jal get_auto_from_idx # v0 <- modelo segunda moto, v1 <- cor segunda moto
        move $s6, $v1 # s6 <- cor segunda moto
        addi $a0, $s7, 259 # a0 <- inicio da string modelo
        move $a1, $v0 # a1 <- modelo segunda moto
        li $a2, 95 # string deve terminar em '_'
        li $a3, 95 # string termina em '_'
        jal strcpy # Copia modelo 2 para modelo 1
        addi $a0, $s7, 310 # a0 <- inicio da string cor
        move $a1, $s6 # a1 <- cor segunda moto
        li $a2, 95 # string deve terminar em '_'
        li $a3, 95 # string termina em '_'
        jal strcpy # Copia cor 2 para cor 1
        li $t0, 49 # '1' em ascii
        sb $t0, 257($a0) # tipo automovel = '1' (Possui 1 moto)
        
        lw $ra 0($sp) # Restaura regs e retorna
        lw $s6 4($sp)
        lw $s7 8($sp)
        addi $sp, $sp, 12
        jr $ra
        
    rm_auto_from_idx_segunda_moto:
        # Apenas diz que so tem uma moto
        li $t0, 49 # '1' em ascii
        sb $t0, 257($a0) # tipo automovel = '1' (Possui 1 moto)
        
        lw $ra 0($sp) # Restaura regs e retorna
        lw $s6 4($sp)
        lw $s7 8($sp)
        addi $sp, $sp, 12
        jr $ra
    
get_morador_idx_from_string: # Recebe em a0 dados do apto, em a1 nome do morador e retorna seu indice
    addi $sp, $sp, -20
    sw $ra, 16($sp)
    sw $s7, 12($sp) # salva dados do apto em s7, nome do morador em s6, qtd moradores em s5 e contador em s4
    sw $s6, 8($sp)
    sw $s5, 4($sp)
    sw $s4, 0($sp)
    move $s7, $a0
    move $s6, $a1
    
    jal get_qtd_moradores_from_data # v0 <- qtd_moradores
    move $s5, $v0 # s5 <- qtd_moradores
    li $s4, 0 # s4 <- Indice inicial = 0
    get_morador_idx_from_string_loop: # Procura pelo morador até chegar no ultimo morador, ou até achar
        move $a0, $s7 # a0 <- dados do apto
        move $a1, $s4 # a1 <- indice
        jal get_morador_from_idx # v0 <- nome do morador atual
        move $a0, $s6 # a0 <- nome do morador desejado
        move $a1, $v0 # a1 <- nome do morador atual
        li $a2, 0 # terminador de str1 é '\0'
        li $a3, 95 # terminador de str2 é '_'
        jal strcmp # v0 <- strcmp(morador atual, morador desejado)
        beqz $v0, get_morador_idx_from_string_found # Se for igual, achou (s4 = indice)
        addi $s4, $s4, 1 # Senão, incrementa o contador
        bne $s4, $s5, get_morador_idx_from_string_loop # Se não chegou ao fim, repete
        lw $s4, 0($sp) # Se chegou ao fim e não achou, restaura registradores e retorna -1
        lw $s5, 4($sp)
        lw $s6, 8($sp)
        lw $s7, 12($sp)
        lw $ra, 16($sp)
        addi $sp, $sp, 20
        li $v0, -1
        jr $ra
    get_morador_idx_from_string_found: # Se achou, restaura registradores e retorna indice (s4 = indice)
        move $v0, $s4
        lw $s4, 0($sp) # Se chegou ao fim e não achou, restaura registradores e retorna -1
        lw $s5, 4($sp)
        lw $s6, 8($sp)
        lw $s7, 12($sp)
        lw $ra, 16($sp)
        addi $sp, $sp, 20
        jr $ra

get_morador_from_idx: # Recebe em a0 dados do apto, a1 indice e retorna nome do morador que termina em '_'
    # morador <- 2 + (idx * (51))
    mul $t0, $a1, 51 # t0 <- idx * 51
    add $t1, $a0, 2 # t1 += 2
    add $v0, $t0, $t1 # v0 <- 2 + (idx * (51)) = morador
    jr $ra

get_auto_from_idx: # Recebe em a0 dados do apto, a1 indice e retorna modelo do automovel em v0 e cor em v1
    mul $t0, $a1, 102 # t0 <- indice * tamanho do automovel
    addi $v0, $a0, 259
    add $v0, $v0, $t0
    addi $v1, $a0, 310
    add $v1, $v1, $t0
    jr $ra

get_tipo_auto_from_data: # Recebe dados do apto em a0 e retorna tipo de automovel ( 0 = vazio, 1 = carro, 2 = moto, 3 = 2 motos)
    lb $v0, 257($a0) # tipo do automovel esta na posiçao 257 da string
    addi $v0, $v0, -48 # parse int
    jr $ra

get_qtd_moradores_from_data: # Recebe dados do apto em a0 e retorna quantidade de moradores
    lb $v0, 0($a0)
    addi $v0, $v0, -48 # parse int
    jr $ra

get_apto_data_from_string: # Recebe string em a0 (ex: 201), terminador da string em a1 e retorna string do apto em v0
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    jal get_apto # v0 <- indice do andar, v1 <- indice do apto
    beq $v0, -1 get_apto_data_falha_ap_invalido
    move $a0, $v0 # a0 <- indice do andar
    move $a1, $v1 # a1 <- indice do apto
    jal get_apto_data # v0 <- string do apto
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
    get_apto_data_falha_ap_invalido:
        li $v0, -1 # Se invalido, retorna -1
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra

get_apto_data: # Recebe indice do andar em a0, indice do apto em a1 e retorna string do apto em v0
    la $v0, dados # v0 <- dados
    li $t1, 1857 # t1 <- tamanho do andar
    mul $t1, $t1, $a0 # t1 <- tamanho do andar * indice do andar
    add $v0, $v0, $t1 # v0 <- dados[andar]
    li $t1, 464 # t1 <- tamanho do apto
    mul $t1, $t1, $a1 # t1 <- tamanho do apto * indice do apto
    add $v0, $v0, $t1 # v0 <- dados[andar][apto]
    jr $ra # retorna

get_apto: # recebe string em a0, terminador da string em a1 e retorna o indice do andar em v0 e o indice do apto em v1
    addi $sp, $sp, -4 # aloca espaço na pilha
    sw $ra, 0($sp) # salva endereço de retorno
    addi $sp, $sp, -4   # Aloca espaço para guardar o registrador s0 e guarda ele
    sw $s0, 0($sp)
    
    move $s0, $a0 # s0 <- Apto
    li $a1, 45 # terminador <- '-'
    jal strlen # v0 <- tamanho de Apto
    move $t0, $v0 # t0 <- tamanho de Apto
    beq $t0, 3, get_apto_tamanho3 # Se apto tem 3 caracteres, vai para tamanho3
    beq $t0, 4, get_apto_tamanho4 # Se apto tem 4 caracteres, vai para tamanho4
    j get_apto_invalido # Senão, apto invalido
    get_apto_tamanho3:
        lb $t0, 0($s0) # t0 <- Andar
        addi $t0, $t0, -49 # Formata de ascii para int
        bge $t0, 9, get_apto_invalido # Se andar >= 10 é invalido
        blt $t0, 0, get_apto_invalido # Se andar < 0 é invalido
        lb $t1, 1($s0) # t1 <- 0 (O segundo numero do apto tem que ser 0)
        addi $t1, $t1, -48 # Formata de ascii para int
        bne $t1, 0, get_apto_invalido # Se nao for 0, é invalido
        lb $t1, 2($s0) # t1 <- apto (40>2<)
        addi $t1, $t1, -49 # Formata de ascii para int
        bge $t1, 4, get_apto_invalido # 4 AP por andar
        blt $t1, 0, get_apto_invalido # menor que 0, invalido
        j fim_get_apto
    get_apto_tamanho4:
        lb $t0, 0($s0) # t0 <- primeiro digito do andar
        addi $t0, $t0, -48 # Formata de ascii para int
        bne $t0, 1, get_apto_invalido # Andar só vai até 10, entao primeiro digito deve ser 1
        lb $t0, 1($s0) # t0 <- segundo digito do andar
        addi $t0, $t0, -48 # Formata de ascii para int
        bnez $t0, get_apto_invalido # Se segundo digito não é 0, ap invalido
        li $t0 9 # t0 <- 9 (andar = 10, indice = 9)
        lb $t1, 2($s0) # t1 <- 0 (O terceiro digito do apto deve ser 0)
        addi $t1, $t1, -48 # Formata de ascii para int
        bne $t1, 0, get_apto_invalido # Se nao for 0, é invalido
        lb $t1, 3($s0) # s3 <- apto (100>2<)
        addi $t1, $t1, -49 # Formata de ascii para int
        bge $t1, 4, get_apto_invalido # 4 AP por andar
        blt $t1, 0, get_apto_invalido # menor que 0, invalido
        j fim_get_apto
    fim_get_apto:
        move $v0, $t0 # salva indice do andar em v0
        move $v1, $t1 # salva indice do apto em v1
        lw $s0, 0($sp) # restaura s0
        addi $sp, $sp, 4
        lw $ra, 0($sp) # restaura ra
        addi $sp, $sp, 4
        jr $ra
    get_apto_invalido:
        li $v0, -1 # retorna erro -1 em v0
        li $v1, -1 # retorna erro -1 em v1
        lw $s0, 0($sp) # restaura s0
        addi $sp, $sp, 4
        lw $ra, 0($sp) # restaura ra
        addi $sp, $sp, 4
        jr $ra
        
formatar_dados: # Formata os dados
    la $t0, dados # t0 <- dados
    li $t1, 0 # t1 <- contador de andar
    andar_loop: # Loop para cada andar (repete 10 vezes)
        li $t2, 0 # t2 <- contador de apartamentos
        apto_loop: # Loop para cada apto (repete 4 vezes)
            li $t3, 48 # Caractere '0'
            sb $t3, 0($t0) # Qtd moradores = 0
            addi $t0, $t0, 1 # passa para o proximo caractere
            li $t3, 44 # Caractere ','
            sb $t3, 0($t0) # armazena ','
            addi $t0, $t0, 1 # passa para o proximo caractere
            li $t4, 0 # t4 <- contador de moradores
            moradores_loop: # Loop para cada possivel morador
                li $t5, 0 # t5 <- contador de namespace
                moradores_namespace_loop: # Loop para preencher namespace com '_'
                    li $t3, 95 # t3 <- '_'
                    sb $t3, 0($t0) # armazena '_'
                    addi $t0, $t0, 1 # passa para o proximo caractere
                    addi $t5, $t5, 1 # Incrementa contador de namespace
                    blt $t5, 50, moradores_namespace_loop # Se nao tem 50 '_', repete
                li $t3, 44 # Caractere ','
                sb $t3, 0($t0) # Coloca virgula
                addi $t0, $t0, 1 # Passa para o proximo caractere
                addi $t4, $t4, 1 # Incrementa contador de moradores
                blt $t4, 5, moradores_loop
            li $t3, 48 # Caractere '0'
            sb $t3, 0($t0) # Tipo de automovel = 0 ( 0 = sem automovel, 1 = possui carro, 2 = possui moto, 3 = possui 2 motos )
            addi $t0, $t0, 1 # Passa para o proximo caractere
            li $t3, 44 # Caractere ','
            sb $t3, 0($t0) # Coloca virgula
            addi $t0, $t0, 1 # Passa para o proximo caractere
            li $t4, 0 # t4 <- contador de automoveis
            automoveis_loop: # Loop para cada possivel automovel
                li $t5, 0 # t5 <- contador de namespace
                automoveis_namespace_loop: # Loop para preencher namespace com '_'
                    li $t3, 95 # t3 <- '_'
                    sb $t3, 0($t0) # armazena '_'
                    addi $t0, $t0, 1 # passa para o proximo caractere
                    addi $t5, $t5, 1 # Incrementa contador de namespace
                    blt $t5, 50, automoveis_namespace_loop # Se nao tem 50 '_', repete
                li $t3, 44 # Caractere ','
                sb $t3, 0($t0) # Coloca virgula
                addi $t0, $t0, 1 # Passa para o proximo caractere
                addi $t4, $t4, 1 # Incrementa contador de automoveis
                blt $t4, 4, automoveis_loop
            li $t3, 45 # Caractere '-'
            sb $t3, 0($t0) # Coloca '-'
            addi $t0, $t0, 1 # Passa para o proximo caractere
            addi $t2, $t2, 1 # Incrementa contador de apartamentos
            blt $t2, 4, apto_loop
        li $t3, 59 # Caractere ';'
        sb $t3, 0($t0) # Coloca ';'
        addi $t0, $t0, 1 # Passa para o proximo caractere
        addi $t1, $t1, 1 # Incrementa contador de andares
        blt $t1, 10, andar_loop # Se nao atingiu 10 andares, repete
    li $t3, 0
    sb $t3, 0($t0) # finaliza com \0
    la $v0, dados
    jr $ra
  
strlen:  # recebe string em a0, terminador da string em a1 e retorna seu tamanho
    li $t0, 0 # contador
    strlen_loop:
        lb $t1, 0($a0) # carrega caractere atual
        beqz $t1, strlen_end # Se caractere é '\0' retorna
        beq $t1, $a1, strlen_end # Se encontrou terminador, retorna
        addi $a0, $a0, 1 # Senao, passa pro proximo caractere, incrementa contador e repete
        addi $t0, $t0, 1
        j strlen_loop
    strlen_end:
        move $v0, $t0 # move contador para a saída v0
        jr $ra # retorna
    
strcpy: # copia a1 para a0, e coloca a2 no final, a3 é finalizador de a1
    li $t0, 0 # contador
    strcopy_loop:
        lb $t1, 0($a1) # caractere da string origem
        beqz $t1, strcpy_end # se '\0' finaliza
        beq $t1, 10, strcpy_end # se '\n' finaliza
        beq $t1, $a3, strcpy_end # se achou caractere finalizador, finaliza
        sb $t1, 0($a0) # copia caractere
        addi $a0, $a0, 1 # passa para o proximo caractere
        addi $a1, $a1, 1
        j strcopy_loop
    strcpy_end:
        sb $a2, 0($a0) # substitui o caractere finalizador por a2
        jr $ra
    
strcmp: # Compara strings, 0 significa igual (a primeira string termina em terminador $a2, e a segunda em terminador $a3), $a0 -> str1 $a1 -> str2
    move $t0, $a0 # Carrega strings em t0 e t1
    move $t1, $a1
    move $t7, $a2 # Carrega em t7 caractere finalizador de str1
    strcmp_loop:
        lb $t2, 0($t0) # Carrega em t2 o caractere atual de str1
        lb $t3, 0($t1) # Carrega em t3 o caractere atual de str2
        seq $t4, $t2, $t7 # Se caractere atual de str1 é finalizador, terminou str1
        seq $t5, $t2, 0 # Se caractere atual de str1 é \0, terminou str1
        or $t4, $t5, $t4 # Se caractere é nulo ou finalizador, terminou str1
        seq $t5, $t3, 0 # Se caractere atual de str2 é \0, terminou str2
        seq $t6, $t3, $a3 # Se caractere atual de str2 é finalizador, terminou str2
        or $t5, $t5, $t6 # Se caractere atual de str2 é nulo ou finalizador, terminou str2
        and $t6, $t4, $t5 # Se as 2 strings terminaram, elas sao iguais
        beq $t6, 1, retorna_true
        beq $t4, 1, retorna_falso # Se apenas uma terminou, retorna falso
        beq $t5, 1, retorna_falso
        bne $t2, $t3, retorna_falso # Se os caracteres diferem, retorna falso
        addi $t0, $t0, 1 # Passa para o proximo caractere
        addi $t1, $t1, 1
        j strcmp_loop
    retorna_true:
        li $v0, 0
        jr $ra
    retorna_falso:
        li $v0, 1
        jr $ra
    
quebra_linha:
    li $v0, 11
    la $a0, 10
    syscall
    jr $ra
    
print_banner:
    li $v0, 4 # Código do syscall para imprimir string
    la $a0, banner # carrega banner
    syscall
    jr $ra
    
salvar_dados:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    li $v0, 13 # syscall de abrir arquivo
    la $a0, dados_txt # a0 <- caminho para arquivo
    li $a1, 1 # write mode
    li $a2, 0
    syscall
    move $s0, $v0 # s0 <- file descriptor
    bltz $s0, salvar_dados_erro
    
    li $v0, 15 # syscall de escrever no arquivo
    move $a0, $s0 # a0 <- file descriptor
    la $a1, dados # a1 <- inicio da string dados
    li $a2, 18570 # a2 <- tamanho da string dados
    syscall
    
    li $v0, 16 # syscall de fechar arquivo
    move $a0, $s0 # a0 <- file descriptor
    syscall
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra
    
    salvar_dados_erro:
        print_label Erro_ao_salvar 0
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra

carregar_dados: # Carrega os dados do arquivo
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    li $v0, 13 # syscall de abrir arquivo
    la $a0, dados_txt # a0 <- caminho para arquivo
    li $a1, 0 # read mode
    li $a2, 0
    syscall
    move $s0, $v0 # s0 <- file descriptor
    bltz $s0, carregar_dados_erro # Se der erro, formata
    
    li $v0, 14 # syscall de ler do arquivo
    move $a0, $s0 # a0 <- file descriptor
    la $a1, dados # a1 <- inicio da string dados
    li $a2, 18570 # a2 <- tamanho da string dados
    syscall
    move $t0, $v0 # t0 <- qtd bytes lidos
    
    li $v0, 16 # syscall de fechar arquivo
    move $a0, $s0 # a0 <- file descriptor
    syscall
    
    bne $t0, 18570, carregar_dados_erro # Se nao leu 18570 caracteres, arquivo deve estar corrompido
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra
    
    carregar_dados_erro: # formata
        jal formatar_dados
        jal salvar_dados
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
