	%{ 
	/* Para simplificar a notação, S é para sintetizar. A atualizar. V verificar */
    #include <string.h>
	#ifndef  ANALEX
	#include "analex.c"
	#define ANALEX
	#endif 
    #ifndef  CODIGO
	#include "codigo.h"
    #define CODIGO
    #endif
    #ifndef TIPOS
    #include "tipos.h"
    #define TIPOS
    #endif
    
	void verifica_numero_argumentos(int id, int num_args);
		
	%}

	%union{
		struct no{
			int place;
			char *code;
			int tipo;
		} node;
		int val;
		struct ids{
			int ids[50];
			int tam;
			char *code;
		} id_list;
	}

	%token <node> NUM
	%token <val> ID 
	%token WHILE
	%token IF 
	%token ELSE
	%token ENDIF
	%token CHAR
	%token INT
	%token FLOAT
	%token VOID
	%token OR
	%token AND
	%token NOT
	%token GE
	%token LE
	%token EQ
	%token NEQ
	%token DO
	%token STRING

	%type <val> Type TypeF
	%type <id_list> IDs ParamList ArgList
	%type <node> Atribuicao Exp Function Prog Statement Statement_Seq
	%type <node> If While Compound_Stt DoWhile FunctionCall Decl

	%right '='

	%left OR
	%left AND

	%nonassoc EQ NEQ

	%left '>' '<' GE LE

	%left '+' '-'
	%left '*' '/' '%'

	%right NOT

	%right '(' '['


	%start ProgL
	%% 
ProgL : Prog {
		printf("%s",$1.code);} /* S código. */
    ;
    
Prog : Prog Function {
		create_cod(&$$.code); 
		insert_cod(&$$.code,$1.code); 
		insert_cod(&$$.code,$2.code);} /* S código. */
	| Function {
        create_cod(&$$.code); 
		insert_cod(&$$.code,$1.code);}/* S código. */
	;	

Function :
    TypeF ID '(' ParamList ')' '{' Statement_Seq '}' { 
        adiciona_funcao_tabela(obtemNome($2), $1, &$4);
        create_cod(&$$.code);
        if($7.code != NULL)
            insert_cod(&$$.code, $7.code);
        Funct(&$$, $2, $7);}
    | TypeF ID '(' ')' '{'Statement_Seq '}' {
        adiciona_funcao_tabela(obtemNome($2), $1, NULL); 
        create_cod(&$$.code);
        if($6.code != NULL)
            insert_cod(&$$.code, $6.code);
            Funct(&$$, $2, $6);}
    ;
	
FunctionCall :
    ID '(' ArgList ')' {
        int funcPos = $1; 
        if (getTipo(funcPos) == -1) {
            yyerror("Uso de identificador nao declarado");
        } else if (Tabela[funcPos].tam_arg_list != $3.tam) {
            verifica_numero_argumentos($1, $3.tam);
            yyerror("Número de argumentos incompatível!");
        }
        create_cod(&$$.code);
        if($3.code != NULL)
            insert_cod(&$$.code, $3.code);
        Call(&$$, funcPos, $3);} /* V declaração, # argumentos. S código*/
    | ID '(' ')' {
        int funcPos = procura(obtemNome($1));
        if (funcPos == -1) {
            yyerror("Uso de identificador nao declarado");
        } else if (Tabela[funcPos].tam_arg_list != 0) {
            yyerror("Número de argumentos incompatível!");
        }
        Call_blank(&$$);} /* V declaração, # argumentos. S código*/
    ;

    
ArgList:
    Exp ',' ArgList {
        create_cod(&$$.code);
        $$.tam = $3.tam;
        for (int i = 0; i < $3.tam; i++) 
        {
            $$.ids[i] = $3.ids[i];
        }
        $$.ids[$$.tam] = $1.place;
        create_cod(&$$.code);
        if($1.code != NULL)
            insert_cod(&$$.code, $1.code);
        if($3.code != NULL)
            insert_cod(&$$.code, $3.code);
        $$.tam++;} /* S código e Lista de IDs*/
    | Exp {
        create_cod(&$$.code);
        $$.tam = 1;
        $$.ids[0] = $1.place;
        if($1.code != NULL)
            insert_cod(&$$.code, $1.code);} /* S código e Lista de IDs*/
    ;


ParamList: 
    ParamList ',' Type ID {
        $$.tam = $1.tam;
        for (int i = 0; i < $1.tam; i++) 
        {
            $$.ids[i] = $1.ids[i];
        }
        $$.ids[$$.tam] = $4;
        if(getTipo($4) == -1)
        {
            set_type($$.ids[$$.tam], $3);
        }
        else 
            if(getTipo($4) != $3)
                yyerror("Tipos de argumentos incompatíveis!");
        
        $$.tam++;
    } /* S Lista de IDs. A Tabela*/
    | Type ID {
        $$.tam = 1;
        $$.ids[0] = $2;  // Handle single ID
        if(getTipo($2) == -1)
        {
            set_type($$.ids[0], $1);
        }
        else 
            if(getTipo($2) != $1)
                yyerror("Tipos de argumentos incompatíveis!");} /* S Lista de IDs. A Tabela*/
    ;

Decl:
    Type IDs {
        int tipo;
        create_cod(&$$.code);
        if ($2.code != NULL)
            insert_cod(&$$.code, $2.code);
        for (int i = 0; i < $2.tam; i++)
         {
            tipo = getTipo($2.ids[i]);
            if (tipo != $1 && tipo != -1) 
            {
                yyerror("Erro Semântico Decl");
            }
            set_type($2.ids[i], $1);   
        }
        $2.tam = 0;}
    ;

	
IDs: 
    IDs ',' ID {
        for ($$.tam = 0; $$.tam < $1.tam; $$.tam++) 
        {
            $$.ids[$$.tam] = $1.ids[$$.tam];
        }
        $$.tam++;
        $$.ids[$$.tam] = $3;
        $$.tam++;  
    }
    | IDs ',' Atribuicao {
        for ($$.tam = 0;$$.tam < $1.tam; $$.tam++) 
        {
            $$.ids[$$.tam] = $1.ids[$$.tam];
        }
        int pos = $3.place;
        create_cod(&$$.code);
        insert_cod(&$$.code, $3.code);
        $$.tam++;
        $$.ids[$$.tam] = pos;
        $$.tam++;
    }
    | IDs ',' ID '[' NUM ']' {
        if(yytype != INT)
        {
            yyerror("Indices de vetor não inteiro");
        }
        for ($$.tam = 0; $$.tam < $1.tam; $$.tam++) 
        {
            $$.ids[$$.tam] = $1.ids[$$.tam];
        }
        $$.tam++;
        $$.ids[$$.tam] = $3;
        $$.tam++;}
    | ID '[' NUM ']' {
        if(yytype != INT)
            yyerror("Indices de vetor não inteiro");
                $$.ids[$$.tam] = $1;}
    | ID {
        $$.tam = 1;
        $$.ids[$$.tam] = $1;}
    | Atribuicao {
        int pos = $1.place;
        create_cod(&$$.code);
        insert_cod(&$$.code, $1.code);
        $$.tam++;
        $$.ids[$$.tam] = pos;}
    ;

TypeF :
	  VOID {$$ = VOID;} /* S Tipo. */
	| Type {$$ = $1;}
	;

Type :
	  INT {$$ = INT;} /* S Tipo. */
	| CHAR {$$ = CHAR;} /* S Tipo. */
	| FLOAT {$$ = FLOAT;} /* S Tipo. */
	;
			
Statement_Seq :
    Statement Statement_Seq {
        create_cod(&$$.code);
        insert_cod(&$$.code, $1.code);
        insert_cod(&$$.code, $2.code);} /* S Codigo. */
    | Statement {
        create_cod(&$$.code);
        insert_cod(&$$.code, $1.code);} /* S Codigo. Exemplo */
    ;
		
Statement: 
	  Atribuicao ';' {
        if(getTipo($1.place) == -1)
        {
            yyerror("Uso de variável não declarada");
        }
        if(invalidtype(getTipo($1.place), $1.tipo) == -1)
        {
            yyerror("Tipos incompatíveis");
        }
        create_cod(&$$.code);
        insert_cod(&$$.code, $1.code);} /* V declaracao, tipos atribuicao. */
	| If  
    {
        create_cod(&$$.code);
        insert_cod(&$$.code, $1.code);
    }/* S código. */
	| While 
    {
        create_cod(&$$.code);
        insert_cod(&$$.code, $1.code);
    } /* S código. */
	| DoWhile 
    {
        create_cod(&$$.code);
        insert_cod(&$$.code, $1.code);} /* S código. */
	| FunctionCall ';' {
        create_cod(&$$.code);
        insert_cod(&$$.code, $1.code);}  /* S código. */
    | Decl ';' {
        create_cod(&$$.code);
        insert_cod(&$$.code, $1.code);}
	;

Compound_Stt :
	  Statement  /* S código. Exemplo resolvido */
	| '{' Statement_Seq '}' {$$ = $2;}  /* S código. Exemplo resolvido */
	;
		
If :
	  IF '(' Exp ')' Compound_Stt ENDIF {If(&$$, $3 ,$5);} /* S código. Exemplo */
	| IF '(' Exp ')' Compound_Stt ELSE Compound_Stt ENDIF {IfElse(&$$, $3, $5, $7);} /* S código. */
	;

While:
    WHILE '(' Exp ')' Compound_Stt {While(&$$, $3, $5);}
	;

DoWhile:
    DO Compound_Stt WHILE '(' Exp ')' ';' {DoWhile(&$$, $2, $5);}
    ;

Atribuicao : 
    ID '[' NUM ']' '=' Exp 
    {
        if(invalidtype(getTipo($1), $6.tipo) == -1)
        {
            yyerror("Uso de Variável não declarada");
        }
        if(yytype != INT)
        {
            yyerror("Indices de vetor não inteiro");
        }
        $$.place = $1;
        Atrib(&$$, $3);
        $$.tipo = $6.tipo;} /* V tipo indice. S tipo, place, código. */
    | ID '=' Exp 
    {
        if(invalidtype(getTipo($1), $3.tipo) == -1)
        {
            yyerror("Tipos incompatíveis");
        }
        $$.place = $1;
        Atrib(&$$, $3);
        $$.tipo = rtd(getTipo($1), $3.tipo);} /* S tipo, place, código. */
    ;


	Exp :
		Exp '+' Exp {$$.tipo = rtd($1.tipo, $3.tipo); Exp_Ari(&$$, $1, $3, "add");} /* S tipo, cod */
		| Exp '-' Exp {$$.tipo = rtd($1.tipo, $3.tipo); Exp_Ari(&$$, $1, $3, "sub");} /* S tipo, cod */
		| Exp '*' Exp {$$.tipo = rtd($1.tipo, $3.tipo); Exp_Ari(&$$, $1, $3, "mul");} /* S tipo, cod */
		| Exp '/' Exp {$$.tipo = rtd($1.stipo, $3.tipo);Exp_Ari(&$$, $1, $3, "div");} /* S tipo, cod */
		| Exp '>' Exp {$$.tipo = rtd($1.tipo, $3.tipo); Exp_Rel(&$$, $1, $3, "bgt");} /* S tipo, cod (bgt) */
		| Exp '<' Exp {$$.tipo = rtd($1.tipo, $3.tipo); Exp_Rel(&$$, $1, $3, "blt");} /* S tipo, cod (blt) */
		| Exp GE Exp {$$.tipo = INT;} /*  S tipo. Não precisa implementar código */
		| Exp LE Exp {$$.tipo = INT;} /*  S tipo. Não precisa implementar código */
		| Exp EQ Exp {$$.tipo = INT;} /*  S tipo. Não precisa implementar código */
		| Exp NEQ Exp {$$.tipo = INT;} /*  S tipo. Não precisa implementar código */
		| Exp OR Exp {$$.tipo = INT; Exp_Log(&$$, $1, $3, "or");} /* S tipo, cod */
		| Exp AND Exp {$$.tipo = INT; Exp_Log(&$$, $1, $3, "and");} /* S tipo, cod */
		| NOT Exp {$$.tipo = INT;} /*  S tipo. Não precisa implementar código*/
		| '(' Exp ')' {        
            create_cod(&$$.code);
            if($2.code != NULL)
                insert_cod(&$$.code, $2.code);
		        $$.tipo = $2.tipo;
                $$ = $2;} /*  S tipo, cod */
		| NUM { 
            if (yytype == FLOAT) 
            {
                $$.tipo = FLOAT;
                Li(&$$, yylval.val);
            } else {
                $$.tipo = INT;
                Li(&$$, yylval.val);}} /* S tipo, código */
		| FLOAT {$$.tipo = FLOAT;}
	    | ID '[' NUM ']' {
            if(getTipo($1) == -1)
            {
                yyerror("Uso de variável não declarada");
            }
            if(yytype != INT)
            {
                yyerror("Indices de vetor não inteiro");
            }
            create_cod(&$$.code);
            if($3.code != NULL)
                insert_cod(&$$.code, $3.code);
            $$.tipo = getTipo($1);
            $$.place = newTemp();} /* V declaracao, indice. S tipo, codigo  */
	    | ID {
            int tipo = getTipo($1);
            if(tipo == -1){
                yyerror("Uso de variável não declarada");
            }
            create_cod(&$$.code);
            $$.tipo = tipo;} /* V declaracao. S tipo, codigo  */
	    | STRING {} /* Ignore, não precisa implementar  */
	    ; 
		
	%%  
	int main(int argc, char **argv) {     
	yyin = fopen(argv[1],"r");
	yyparse();      
	} 

	/* Funcoes auxiliares podem ser implementadas aqui */

void verifica_numero_argumentos(int id, int num_args) {
    if (Tabela[id].tam_arg_list != num_args) {
        fprintf(stderr, "Erro: Função %s esperava %d argumentos, mas recebeu %d.\n",
                Tabela[id].nome, Tabela[id].tam_arg_list, num_args);
        exit(1);
    }
}