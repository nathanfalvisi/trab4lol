#ifndef SEMANTIC
#include "semantic.h"
#endif
#ifndef LISTA
#include "listacodigo.h"
#endif
#ifndef TABSIMB
#include "tabsimb.h"
#endif
#define CODIGO

int temp=-1;
int newTemp() {
	return temp--;
}

void freeTemp() {
	temp++;
}
int label = 0;
int label1, label2;
int newLabel() {
	return ++label;
}

char reg1[5];
char reg2[5];
char reg_temp[5];
void getName(int num, char *name) {
  if (num >= 0 ) {
    sprintf(name,"$s%d",num);
  }
  else 
    sprintf(name,"$t%d",-(num+1));
}

/* Geração de código para criar uma função. Exemplo */
void Funct(struct no* Funct, int Id, struct no Comandos) 
{
	create_cod(&Funct->code);
	obtemNome(Id);
	sprintf(instrucao, "%s:\n", nome);
	insert_cod(&Funct->code, instrucao);
	insert_cod(&Funct->code, Comandos.code);
	if (strcmp(nome,"main")==0) 
    {
		sprintf(instrucao,"\tli $v0,10\n"); //Define exit
		insert_cod(&Funct->code,instrucao);
		sprintf(instrucao,"\tsyscall\n\n"); //Call exit
		insert_cod(&Funct->code,instrucao);					
	} else {
		sprintf(instrucao,"\tjr $ra\n\n"); //Return to previous function
		insert_cod(&Funct->code,instrucao);
	}
}

/* Função pre-implementada para lidar com argumentos de forma simples */
void adiciona_argumentos(char **code, int id, struct ids Args){
  struct symbol simbolo = Tabela[id];
  char name_param[5];
  char name_arg[5];
  for(int i = 0; i<simbolo.tam_arg_list;i++){
    getName(simbolo.arg_list[i], name_param);
    getName(Args.ids[i], name_arg);
    sprintf(instrucao,"\tmove %s,%s\n",name_param,name_arg);
	  insert_cod(code,instrucao);
  }
}

/* Geração de código para chamada de função */
void Call(struct no* Call, int Id, struct ids Args) {
    create_cod(&Call->code);
    if (Args.tam > 0) { // Verifique se há argumentos
        adiciona_argumentos(&Call->code, Id, Args); 
    }
    sprintf(instrucao, "\tjal %s\n", nome);  
    insert_cod(&Call->code, instrucao);
}

/* Geração de código para chamada de função sem argumentos */
void Call_blank(struct no* Call) {
    create_cod(&Call->code);
    sprintf(instrucao, "\tjal %s\n", nome);  
    insert_cod(&Call->code, instrucao);
}

/* Geração de código para atribuições */
char* get_place(int id) {
    static char reg[10];
    sprintf(reg, "r%d", id);
    return reg;
}

void Atrib(struct no* atribuido, struct no exp)
{
	char dest[5], source[5];
	create_cod(&atribuido->code);
	getName(atribuido->place, dest);
	getName(exp.place, source);
	sprintf(instrucao,"\tmove %s, %s\n", dest, source);
	insert_cod(&atribuido->code, instrucao);
    if(exp.code != NULL)
	    insert_cod(&atribuido->code, exp.code);
}
/* Geração de código para carregar constantes */
void Li(struct no *Exp, int num) {
	char name_dest[5];
	create_cod(&Exp->code);
	Exp->place = newTemp();
	getName(Exp->place,name_dest);
	sprintf(instrucao,"\tli %s,%d\n",name_dest,num);
	insert_cod(&Exp->code,instrucao);
}

/* Geração de código para qualquer expressão aritmética referente parâmetros */
void Exp_Ari(struct no *Exp, struct no Exp1, struct no Exp2, char *op) {
	char name_reg1[5];
	char name_reg2[5];
	char name_temp[5];
	Exp->place = newTemp();
	create_cod(&Exp->code);
	insert_cod(&Exp->code,Exp1.code);
	insert_cod(&Exp->code,Exp2.code);
	getName(Exp1.place,name_reg1);
	getName(Exp2.place,name_reg2);
	getName(Exp->place,name_temp);
	sprintf(instrucao,"\t %s %s,%s,%s\n",op,name_temp,name_reg1, name_reg2);
	insert_cod(&Exp->code,instrucao);
}

/* Geração de código para qualquer expressão relacional referente parâmetros */
void Exp_Rel(struct no *Exp, struct no Exp1, struct no Exp2, char *branch){
	char name_reg1[5];
	char name_reg2[5];
	char name_temp[5];
	Exp->place = newTemp();
	getName(Exp->place,name_temp);
	create_cod(&Exp->code);
	insert_cod(&Exp->code,Exp1.code);
	insert_cod(&Exp->code,Exp2.code);
	getName(Exp1.place,name_reg1);
	getName(Exp2.place,name_reg2);
	getName(Exp->place,name_temp);
	sprintf(instrucao,"\tli %s,1\n",name_temp);
	insert_cod(&Exp->code,instrucao);
	newLabel();
	sprintf(instrucao,"\t%s,%s,%s,L%d\n",name_reg1,name_reg2,branch,label);
	insert_cod(&Exp->code,instrucao);
	sprintf(instrucao,"\tli %s,0\n",name_temp);
	insert_cod(&Exp->code,instrucao);
	sprintf(instrucao,"L%d:\n",label);
	insert_cod(&Exp->code,instrucao);
}

void Exp_Log(struct no *Exp, struct no Exp1, struct no Exp2, char *logic){
	char name_reg1[5];
	char name_reg2[5];
	char name_temp[5];
	Exp->place = newTemp();
	getName(Exp->place,name_temp);
	create_cod(&Exp->code);
	insert_cod(&Exp->code,Exp1.code);
	insert_cod(&Exp->code,Exp2.code);
	getName(Exp1.place,name_reg1);
	getName(Exp2.place,name_reg2);
	getName(Exp->place,name_temp);
	sprintf(instrucao,"\t%s,%s,%s\n",name_reg1,name_reg2, logic);
	insert_cod(&Exp->code,instrucao);
}

/* Geração de código para ifs sem else */
void If(struct no *If, struct no Exp, struct no Body)  
{  
    char name_cond[5];
    char label_end[8];
    create_cod(&If->code);
    insert_cod(&If->code, Exp.code);
    sprintf(label_end, "L%d", newLabel());
    getName(Exp.place, name_cond);
    sprintf(instrucao, "\tbeq %s, $zero, %s\n", name_cond, label_end);
    insert_cod(&If->code, instrucao);
    insert_cod(&If->code, Body.code);
    sprintf(instrucao, "%s:\n", label_end);
    insert_cod(&If->code, instrucao);
}


/* Geração de código para ifs com else */
void IfElse(struct no *IfElse, struct no Exp, struct no BodyIf, struct no BodyElse) {  
    char name_cond[5];
    char label_else[8];
    char label_end[8];
    create_cod(&IfElse->code);
    insert_cod(&IfElse->code, Exp.code);
    sprintf(label_else, "L%d", newLabel());
    sprintf(label_end, "L%d", newLabel());
    getName(Exp.place, name_cond);
    sprintf(instrucao, "\tbeq %s, $zero, %s\n", name_cond, label_else);
    insert_cod(&IfElse->code, instrucao);
    insert_cod(&IfElse->code, BodyIf.code);
    sprintf(instrucao, "\tj %s\n", label_end);
    insert_cod(&IfElse->code, instrucao);
    sprintf(instrucao, "%s:\n", label_else);
    insert_cod(&IfElse->code, instrucao);
    insert_cod(&IfElse->code, BodyElse.code);
    sprintf(instrucao, "%s:\n", label_end);
    insert_cod(&IfElse->code, instrucao);
}

/* Geração de código para whiles */
void While(struct no *While, struct no Exp, struct no Body) {
    char name_cond[5];
    char label_start[8];
    char label_end[8];
    create_cod(&While->code);
    sprintf(label_start, "L%d", newLabel());
    sprintf(label_end, "L%d", newLabel());
    sprintf(instrucao, "%s:\n", label_start);
    insert_cod(&While->code, instrucao);
    insert_cod(&While->code, Exp.code);
    getName(Exp.place, name_cond);
    sprintf(instrucao, "\tbeq %s, $zero, %s\n", name_cond, label_end);
    insert_cod(&While->code, instrucao);
    insert_cod(&While->code, Body.code);
    sprintf(instrucao, "\tj %s\n", label_start);
    insert_cod(&While->code, instrucao);
    sprintf(instrucao, "%s:\n", label_end);
    insert_cod(&While->code, instrucao);
}

/* Geração de código para do whiles */
void DoWhile(struct no *DoWhile, struct no Body, struct no Exp) {
    char name_cond[5];
    char label_start[8];
    char label_check[8];
    create_cod(&DoWhile->code);
    sprintf(label_start, "L%d", newLabel());
    sprintf(label_check, "L%d", newLabel());
    sprintf(instrucao, "%s:\n", label_start);
    insert_cod(&DoWhile->code, instrucao);
    insert_cod(&DoWhile->code, Body.code);
    sprintf(instrucao, "%s:\n", label_check);
    insert_cod(&DoWhile->code, instrucao);
    insert_cod(&DoWhile->code, Exp.code);
    getName(Exp.place, name_cond);
    sprintf(instrucao, "\tbne %s, $zero, %s\n", name_cond, label_start);
    insert_cod(&DoWhile->code, instrucao);
}

void adiciona_funcao_tabela(char *nome, int tipo, struct ids *parametros) 
{
    int pos;

    pos = procura(nome);

    if (pos == -1) 
    {
        pos = insere(nome);
    }

    set_type(pos, tipo);
    if (parametros != NULL) 
    {
        Tabela[pos].tam_arg_list = parametros->tam;

        for (int i = 0; i < parametros->tam; i++) 
        {
            Tabela[pos].arg_list[i] = parametros->ids[i];
        }
    } else {
        Tabela[pos].tam_arg_list = 0; 
    }
}



