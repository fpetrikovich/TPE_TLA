%{
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "tokenFunctions.h"
#include "translationTokens.h"
#include "codeTranslator.h"

/* What parser will call when 
 * there is a syntactical error */
void yyerror(TokenList **list, char *s);
void check(Token *token);

/* Variable for the line count */
extern int yylineno;

int yylex();

VariableToken **variables;

TokenList *code;

%}

/* Specify the different types 
 * my lexical analyzer can return */
%union {
	char 	  		  string[500];
	struct Token     *token;
	struct TokenList *list;
}

/* Which of the productions that follow 
 * in the middle section is going to be
 * my starting rule */
%start main

%parse-param { struct TokenList ** code }

/* ----------------- TOKENS ---------------------
 * Token that I'm expecting from the lexical 
 * analyzer (will save as defines in tab.h) */

%token IF ELIF ELSE DO WHILE PRINT RETURN
%token ASSIGN_SUM ASSIGN_MULTI ASSIGN_DIV ASSIGN_SUBTRACT ASSIGN_FUNC
%token SUM SUM_ONE MULTI DIV SUBTRACT SUBTRACT_ONE MODULE ASSIGN
%token PRODUCT_OF SUM_OF SUMMATION PRODUCT FACTORIAL SLOPE
%token EQUAL_OP NOT_EQUAL_OP GT_OP GTE_OP LT_OP LTE_OP AND_OP OR_OP NOT_OP
%token COMA SEMI_COLON OPEN_BRACES CLOSE_BRACES OPEN_PARENTHESES CLOSE_PARENTHESES
%token NUMBER_LITERAL NUMBER_TYPE FUNCTION_TYPE COORDINATES VAR STRING_LITERAL STRING_TYPE
%token START END

/* ---------------------------------------------

/* Token will be saved in the member
 * in the union */
%type <list> instructions main
%type <token> block if_block loop_block declaration math_block math_condition /*slope_block */
%type <token> print_block return_block statement variable braces
%type <token> count_operation assign_operation relational_operation logic_operation one_operation
%type <token> simple_expression base_expression expression function_call function_block

%type <string> FUNCTION_TYPE COORDINATES NUMBER_LITERAL NUMBER_TYPE STRING_LITERAL VAR STRING_TYPE
%type <string> count_op assign_op relational_op logic_op one_op

%%

statement:
	  declaration SEMI_COLON		{ $$ = (Token *)createStatementToken($1); check($$); }
	| print_block SEMI_COLON 		{ $$ = (Token *)createStatementToken($1); check($$); }
	| assign_operation SEMI_COLON   { $$ = (Token *)createStatementToken($1); check($$); }
	| one_operation SEMI_COLON      { $$ = (Token *)createStatementToken($1); check($$); }
	| expression SEMI_COLON         { $$ = (Token *)createStatementToken($1); check($$); }
	| return_block SEMI_COLON 		{ $$ = (Token *)createStatementToken($1); check($$); }
	| math_block SEMI_COLON 		{ $$ = (Token *)createStatementToken($1); check($$); }
	;

declaration:
 	  NUMBER_TYPE VAR  				     { $$ = (Token *)createOrFindVariable($2); check($$); $$ = castVariable($$, DATA_NUMBER); check($$);}
 	| STRING_TYPE VAR 					 { $$ = (Token *)createOrFindVariable($2); check($$); $$ = castVariable($$, DATA_STRING); check($$);} 	
 	| declaration ASSIGN expression  	 { $$ = (Token *)createOperationToken($1, "=", $3); check($$); }
 	;

main:
	  START instructions END 	{ *code = createStatementList((Token *)$2); $$ = *code; check((Token *)$$);}
	| START END	  		 		{ *code = NULL; $$ = *code; }

instructions:
	  instructions block  { $$ = addStatement($1, $2); check((Token *)$$); }
	| block			      { $$ = createStatementList($1); check((Token *)$$); }
	;

block:
	  braces 				{ $$ = $1; }		//Check this action
	| if_block 				{ TokenList *list = createStatementList($1); check((Token *)list); $$ = (Token *)createBlockToken(list); check($$); }
	| loop_block			{ TokenList *list = createStatementList($1); check((Token *)list); $$ = (Token *)createBlockToken(list); check($$); }
	| statement 			{ TokenList *list = createStatementList($1); check((Token *)list); $$ = (Token *)createBlockToken(list); check($$); }				//Check this action
	| function_block 		{ TokenList *list = createStatementList($1); check((Token *)list); $$ = (Token *)createBlockToken(list); check($$); }
	| block braces 			{ if($1 == NULL) {TokenList *list = createStatementList($2); check((Token *)list); $$ = (Token *)createBlockToken(list); check($$);} else {TokenList *list = addStatement(((BlockToken *) $1)->statements, $2); check((Token *)list); $$ = $1; check($$);} }
	| block if_block 		{ if($1 == NULL) {TokenList *list = createStatementList($2); check((Token *)list); $$ = (Token *)createBlockToken(list); check($$);} else {TokenList *list = addStatement(((BlockToken *) $1)->statements, $2); check((Token *)list); $$ = $1; check($$);} }
	| block loop_block 		{ if($1 == NULL) {TokenList *list = createStatementList($2); check((Token *)list); $$ = (Token *)createBlockToken(list); check($$);} else {TokenList *list = addStatement(((BlockToken *) $1)->statements, $2); check((Token *)list); $$ = $1; check($$);} }
	| block statement 		{ if($1 == NULL) {TokenList *list = createStatementList($2); check((Token *)list); $$ = (Token *)createBlockToken(list); check($$);} else {TokenList *list = addStatement(((BlockToken *) $1)->statements, $2); check((Token *)list); $$ = $1; check($$);} }
	| block function_block 	{ if($1 == NULL) {TokenList *list = createStatementList($2); check((Token *)list); $$ = (Token *)createBlockToken(list); check($$);} else {TokenList *list = addStatement(((BlockToken *) $1)->statements, $2); check((Token *)list); $$ = $1; check($$);} }
	;

braces:
	  OPEN_BRACES CLOSE_BRACES				{ $$ = NULL; }
	| OPEN_BRACES block CLOSE_BRACES 		{ $$ = (Token *)$2; }
	;

function_block:
	 FUNCTION_TYPE VAR OPEN_PARENTHESES declaration CLOSE_PARENTHESES block SEMI_COLON { 
	 	Token *function_name = (Token *)createOrFindVariable($2); 
	 	check(function_name); 
	 	function_name = castVariable(function_name, DATA_FUNCTION); 
	 	check(function_name);
	 	((VariableToken *)$4)->declared = 1; 
	 	$$ = (Token *)createFunctionDefToken(function_name, $6, $4); check($$); 
	 }

if_block:
	  IF OPEN_PARENTHESES relational_operation CLOSE_PARENTHESES braces
	  	{ $$ = (Token *)createIfToken($3, $5, NULL, NULL, NULL); check($$); }
	| IF OPEN_PARENTHESES relational_operation CLOSE_PARENTHESES braces ELIF OPEN_PARENTHESES expression CLOSE_PARENTHESES braces
	  	{ $$ = (Token *)createIfToken($3, $5, $8, $10, NULL); check($$); }
	| IF OPEN_PARENTHESES relational_operation CLOSE_PARENTHESES braces ELIF OPEN_PARENTHESES expression CLOSE_PARENTHESES braces ELSE braces
	 	{ $$ = (Token *)createIfToken($3, $5, $8, $10, $12); check($$); }
	| IF OPEN_PARENTHESES relational_operation CLOSE_PARENTHESES braces ELSE braces
		{ $$ = (Token *)createIfToken($3, $5, NULL, NULL, $7); check($$); }
	|  IF OPEN_PARENTHESES logic_operation CLOSE_PARENTHESES braces
	  	{ $$ = (Token *)createIfToken($3, $5, NULL, NULL, NULL); check($$); }
	| IF OPEN_PARENTHESES logic_operation CLOSE_PARENTHESES braces ELIF OPEN_PARENTHESES expression CLOSE_PARENTHESES braces
	  	{ $$ = (Token *)createIfToken($3, $5, $8, $10, NULL); check($$); }
	| IF OPEN_PARENTHESES logic_operation CLOSE_PARENTHESES braces ELIF OPEN_PARENTHESES expression CLOSE_PARENTHESES braces ELSE braces
	 	{ $$ = (Token *)createIfToken($3, $5, $8, $10, $12); check($$); }
	| IF OPEN_PARENTHESES logic_operation CLOSE_PARENTHESES braces ELSE braces
		{ $$ = (Token *)createIfToken($3, $5, NULL, NULL, $7); check($$); }
	;

loop_block:
	  DO braces WHILE OPEN_PARENTHESES relational_operation CLOSE_PARENTHESES SEMI_COLON 
		{ $$ = (Token *)createCalculateWhileToken($5, $2); check($$); }
	| DO braces WHILE OPEN_PARENTHESES logic_operation CLOSE_PARENTHESES SEMI_COLON 
		{ $$ = (Token *)createCalculateWhileToken($5, $2); check($$); }
	;

print_block:
	PRINT OPEN_PARENTHESES expression CLOSE_PARENTHESES { $$ = (Token *)createPrintToken($3); check($$); }
	;

return_block:
	RETURN expression { $$ = (Token *)createReturnToken($2); check($$); }
	;

variable:
	VAR  { $$ = (Token *)createOrFindVariable($1); check($$); }
	;

base_expression:
	  NUMBER_LITERAL  { $$ = (Token *) createConstantToken($1); check($$); }
	| STRING_LITERAL  { $$ = (Token *) createStringToken($1); check($$);}
	| variable   { $$ = $1; }
    | OPEN_PARENTHESES expression CLOSE_PARENTHESES { $$ = (Token *)$2; }
    ;

simple_expression:
	  base_expression				{ $$ = $1; }
	| NOT_OP relational_operation 	{ $$ = (Token *)createNegationToken($2); check($$); }
	| NOT_OP logic_operation 		{ $$ = (Token *)createNegationToken($2); check($$); }
	;

expression:
	  simple_expression 	{ $$ = $1; }
	| count_operation		{ $$ = $1; }
	| relational_operation	{ $$ = $1; }
	| logic_operation		{ $$ = $1; }
	| function_call			{ $$ = $1; }
	;

function_call:
	VAR OPEN_PARENTHESES expression CLOSE_PARENTHESES { Token *function_name = (Token *)createOrFindVariable($1); check( function_name); $$ = (Token *)createFunctionCallToken(function_name, $3); check($$); }
	;

count_op:
	  MULTI 	{ strcpy($$, "*"); }
	| DIV 		{ strcpy($$, "/"); }
	| MODULE 	{ strcpy($$, "%"); }
	| SUM 		{ strcpy($$, "+"); }
	| SUBTRACT 	{ strcpy($$, "-"); }
	;

count_operation:
	expression count_op expression { $$ = (Token *)createOperationToken($1, $2, $3); check($$); }
	;

relational_op:
	  GT_OP 		{ strcpy($$, ">"); }
	| GTE_OP		{ strcpy($$,">="); }
	| LT_OP 		{ strcpy($$, "<"); }
	| LTE_OP 		{ strcpy($$,"<="); }
	| EQUAL_OP 		{ strcpy($$,"=="); }
	| NOT_EQUAL_OP  { strcpy($$,"!="); }
	;

relational_operation:
	expression relational_op expression { $$ = (Token *)createOperationToken($1, $2, $3); check($$); }
	;

logic_op:
	  AND_OP { strcpy($$, "&&"); }
	| OR_OP  { strcpy($$, "||"); }
	;

logic_operation:
	expression logic_op expression  { $$ = (Token *)createOperationToken($1, $2, $3); check($$); }
	;

one_op:
	  SUM_ONE		{ strcpy($$, "++"); }
	| SUBTRACT_ONE	{ strcpy($$, "--"); }
	;

one_operation:
	variable one_op { $$ = (Token *)createSingleOperationToken($1, $2); check($$); }
	;

assign_op:
	  ASSIGN 			{ strcpy($$, "="); }
	| ASSIGN_SUM 		{ strcpy($$,"+="); }
	| ASSIGN_SUBTRACT	{ strcpy($$,"-="); }
	| ASSIGN_DIV		{ strcpy($$,"/="); }
	| ASSIGN_MULTI		{ strcpy($$,"*="); }
	;

assign_operation:
	variable assign_op expression  { $$ = (Token *)createOperationToken($1, $2, $3); check($$); }


 math_block:
 	  SUMMATION OPEN_PARENTHESES variable SEMI_COLON math_condition CLOSE_PARENTHESES
 	  	{ $$ = (Token *)createSigmaPiToken(SUMMATION_TYPE, $3, $5); check($$); }
 	| PRODUCT OPEN_PARENTHESES variable SEMI_COLON math_condition CLOSE_PARENTHESES
 	  	{ $$ = (Token *)createSigmaPiToken(PRODUCTION_TYPE, $3, $5); check($$); }
 	| SUMMATION OPEN_PARENTHESES declaration SEMI_COLON math_condition CLOSE_PARENTHESES
 	  	{ $$ = (Token *)createSigmaPiToken(SUMMATION_TYPE, $3, $5); check($$); }
 	| PRODUCT OPEN_PARENTHESES declaration SEMI_COLON math_condition CLOSE_PARENTHESES
 	  	{ $$ = (Token *)createSigmaPiToken(PRODUCTION_TYPE, $3, $5); check($$); }
 	;

math_condition:
	assign_operation SEMI_COLON expression SEMI_COLON assign_operation  				
		{ $$ = (Token *)createSigmaPiConditionToken($1, $3, $5); check($$); }
	;

/* FUTURE IMPLEMENTATION
 * slope_block:
 *  	SLOPE OPEN_PARENTHESES COORDINATES COMA COORDINATES CLOSE_PARENTHESES SEMI_COLON
 *  	;
 */

%%



void 
yyerror(TokenList ** code, char *s) {
	fprintf(stderr, "%s\n", s);
	printf("-------------------------------------\n%s in line %d\n-------------------------------------\n", s, yylineno);
	freeToken((Token *) code);
	exit(EXIT_FAILURE);
}

void 
check(Token * token) {
	/* On error from malloc, token will be null */
	if (token == NULL) {
		yyerror(&code, "Error allocating memory");
	}

	/* Must check that the type is correct 
	 * Operation and assignment must have matching types */
	if (token->basicInfo.dataType == DATA_NULL) {
     	yyerror(&code, "Incorrect type in assignment or operation");
    }
}


int
main(void) {
	variables = malloc(MAX_VARIABLES * sizeof(VariableToken *));

	if (variables == NULL) {
		printf("Unable to allocate space for the variables\n");
		exit(EXIT_FAILURE);
	}
	memset(variables, '\0', sizeof(VariableToken *) * MAX_VARIABLES);
	
	yyparse(&code);

	char * translation = translateToC((Token *)code);
	//We should always call get functions after translateToC
	char * functionsTranslation = getFunctions();

	if (translation == NULL) printf("Error allocating memory for generated C code.\n");
	else {
		printf("#include <stdio.h>\n");
		printf("#include <stdlib.h>\n\n");
		if(functionsTranslation != NULL) {
			printf("%s\n", functionsTranslation);
		}
		printf("int main(int argc, char const *argv[]) {\n");
		printf("%s\n", translation);
		printf("\nreturn 0;\n}");
	}

	if(translation != NULL) {
		free(translation);
	}
	if(functionsTranslation != NULL) {
		free(functionsTranslation);
	}
	freeFunctions();
	freeToken((Token *) code);
	freeVariables();
	return 0;
}