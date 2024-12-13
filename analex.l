%{
    #ifndef SEMANTICA
    #include "semantic.h"
    #define SEMANTICA
    #endif
    #ifndef TABSIMB
    #define TABSIMB 
    #include "tabsimb.h"
    #endif
	#include <stdlib.h>
int yytype, linha = 1;

int yyerror(char *s) { 
  printf("%s na linha %d\n",s,linha);
  exit(1); 
}
%}

dig [0-9]
zero [0]
letra [a-zA-Z_]
underscore["_"]

%%


"while" {return WHILE;}
"if"	{return IF;}
"else"	{return ELSE;}
"int"  {return INT;}
"float" {return FLOAT;}
"char"  {return CHAR;} 
"void" {return VOID;}
"endif" {return ENDIF;}


"+" {return '+';}
"-" {return '-';}
"*" {return '*';}
"/" {return '/';}
"%" {return '%';}


">="  {return GE;}
"<=" {return LE;}
">" {return '>';}
"<" {return '<';}
"==" {return EQ;} 	


"&&" {return AND;}
"||" {return OR;}
"!" {return NOT;}


"=" {return '=';}


"["	  {return '[';}
"]"	  {return ']';}
"("	  {return '(';}
")"   {return ')';}
"{"	  {return '{';}
"}"   {return '}';}
";"   {return ';';}
","   {return ',';}

("-")?{dig}+("."{zero}+)? {
    yylval.val = atoi(yytext);
    yytype = INT;
    return NUM;
    }

("-")?{dig}+("."{dig}+)? {
    yylval.val = atof(yytext);
    yytype = FLOAT;

	return NUM;
	}

{letra}({letra}|{dig}|{underscore})*  {
    yylval.val = insere(yytext); 
    return ID;
    } 
                           
\"[^\"]*\"   { return STRING; }
[ \t\r] {}
\n	{ linha++; }
.	{printf("erro lexico na linha %d - %s\n",
             linha, yytext); }
%%

#ifndef yywrap
int yywrap() { return 1; }
#endif
