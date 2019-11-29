%{

#include <stdio.h>
#include <stdlib.h>

#include "nodesInitializer.h"
#include "codeGenerator.h"

/* What parser will call when 
 * there is a syntactical error */
void yyerror(ListNode **list, char *s);

/* Variable for the line count */
extern int yylineno;

%}

/* Specify the different types 
 * my lexical analyzer can return */
%union {
	NodeType  
	char 	  string[500];
	Node     *node;
	NodeList *list;
}

/* Which of the productions that follow 
 * in the middle section is going to be
 * my starting rule */
%start instructions

%parse-param { ListNode ** code }

/* ----------------- TOKENS ---------------------
 * Token that I'm expecting from the lexical 
 * analyzer (will save as defines in tab.h) */

%token IF ELIF ELSE DO WHILE PRINT RETURN
%token ASSIGN_SUM ASSIGN_MULTI ASSIGN_DIV ASSIGN_SUBTRACT ASSIGN_FUNC
%token SUM SUM_ONE MULTI DIV SUBTRACT SUBTRACT_ONE MODULE ASSIGN
%token PRODUCT_OF SUM_OF SUMMATION PRODUCT FACTORIAL SLOPE
%token EQUAL_OP NOT_EQUAL_OP GT_OP GTE_OP LT_OP LTE_OP AND_OP OR_OP NOT_OP
%token COMA SEMI_COLON OPEN_BRACES CLOSE_BRACES OPEN_PARENTHESES CLOSE_PARENTHESES
%token NUMBER NUMBER_VAL FUNCTION COORDINATES VARIABLE STRING STRING_VAL
%token NEW_LINE ASSIGN_FUNC
%token BEGIN END

/* ---------------------------------------------

/* Token will be saved in the member
 * in the union */
%type <list> braces instructions
%type <node> type func_type block if_block loop_block math_block slope_block
%type <node> function_block print_block return_block 
%type <node> count_operation assign_operation relational_operation logic_operation one_operation
%type <node> simple_expression base_expression expression

%type <string> VARIABLE STRING_VAL NUMBER_VAL constant variable
%type <string> count_op assign_op relational_op logic_op one_op



%%

type:
	  func_type   { $$ = $1; }
	| FUNCTION    { $$ = node(??, DATA_FUNCTION); }
	| COORDINATES { $$ = node(??, DATA_COORDINATES); }
/* types allowed in a function */
func_type:
	  NUMBER  { $$ = node(TYPE_CONSTANT, DATA_NUMBER); }
	| STRING  { $$ = node(TYPE_STRING, DATA_STRING); }
	;

statement:
	  declaration SEMI_COLON
	| assign_operation SEMI_COLON
	| one_operation SEMI_COLON
	| expression SEMI_COLON
	;

 declaration:
 	  type VARIABLE  		{ $$ = variable($2, $1); } 	
 	| type assign_operation 
 		{	// CHECK!!!!
 			$$ = variable((VariableNode *)(((OperationNode *)($2->node))->first)->name, $1);
 		}	
 	| function_declaration

function_declaration:
	FUNCTION STRING_VAL OPEN_PARENTHESES func_type variable CLOSE_PARENTHESES function_definition
	;

function_definition:
	OPEN_BRACES function_value CLOSE_BRACES SEMI_COLON
	;

function_value:
	  function_value NEW_LINE
	| function_value function_value
	| STRING_VAL OPEN_PARENTHESES relational_operation CLOSE_PARENTHESES ASSIGN_FUNC expression SEMI_COLON
	;

instructions:
	  BEGIN block END { *code = instructionList($2);   $$ = *code; }
	| BEGIN END		  { *code = instructionList(NULL); $$ = *code; }
	;

block:
	  braces 			{ $$ = bloque($1); }
	| if_block 			{ $$ = $1; }
	| loop_block		{ $$ = $1; }
	| print_block		{ $$ = $1; }
	| return_block		{ $$ = $1; }
	| statement 		{ $$ = instruction($1); }
	| NEW_LINE 			{ $$ = empty(); }
	;

braces:
	  OPEN_BRACES CLOSE_BRACES				{ $$ = instructionList(NULL); }
	| OPEN_BRACES instructions CLOSE_BRACES { $$ = $2; }
	;

if_block:
	  IF OPEN_PARENTHESES expression CLOSE_PARENTHESES braces
	  	{ $$ = ifNode($3, $5, NULL, NULL, NULL); }
	| IF OPEN_PARENTHESES expression CLOSE_PARENTHESES braces ELIF OPEN_PARENTHESES expression CLOSE_PARENTHESES braces
	  	{ $$ = ifNode($3, $5, $8, $10, NULL); }
	| IF OPEN_PARENTHESES expression CLOSE_PARENTHESES braces ELIF OPEN_PARENTHESES expression CLOSE_PARENTHESES braces ELSE braces
	 	{ $$ = ifNode($3, $5, $8, $10, $12); }
	| IF OPEN_PARENTHESES expression CLOSE_PARENTHESES braces ELSE braces
		{ $$ = ifNode($3, $5, NULL, NULL, $7); }
	;

loop_block:
	DO braces WHILE OPEN_PARENTHESES expression CLOSE_PARENTHESES SEMI_COLON 
		{ $$ = whileNode($5, $2); }
	;

print_block:
	PRINT OPEN_PARENTHESES expression CLOSE_PARENTHESES SEMI_COLON { $$ = print($3); }
	;

return_block:
	RETURN expression SEMI_COLON { $$ = returnNode($2); }
	;

constant:
	NUMBER_VAL { $$ = constant($1); }
	;

variable:
	VARIABLE  { $$ = variable($1, NULL); }
	;

base_expression:
	  constant   { $$ = $1; }
	| variable   { $$ = $1; }
    | STRING_VAL { $$ = string($1); }
    | OPEN_PARENTHESES expression CLOSE_PARENTHESES { $$ = $2; }
    ;

simple_expression:
	  base_expression				{ $$ = $1; }
	| NOT_OP relational_operation 	{ $$ = negation($2); }
	| NOT_OP logic_operation 		{ $$ = negation($2); }
	;

expression:
	  simple_expression 	{ $$ = $1; }
	| count_operation		{ $$ = $1; }
	| relational_operation	{ $$ = $1; }
	| logic_operation		{ $$ = $1; }
	;

count_op:
	  MULTI 	{ strcpy($$, "*"); }
	| DIV 		{ strcpy($$, "/"); }
	| MODULE 	{ strcpy($$, "%"); }
	| SUM 		{ strcpy($$, "+"); }
	| SUBTRACT 	{ strcpy($$, "-"); }
	;

count_operation:
	expression count_op expression { 
		//matchingType(getType($1->node), getType($3->node));
		$$ = operation($1, $2, $3); 
	}
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
	expression relational_op expression { 
		//if (getType($1->node) != DATA_NUMBER || getType($3->node) != DATA_NUMBER) yyerror(*code, "Relational operations must involve numbers");
		$$ = operation($1, $2, $3); 
	}
	;

logic_op:
	  AND_OP { strcpy($$, "&&"); }
	| OR_OP  { strcpy($$, "||"); }
	;

logic_operation:
	expression logic_op expression  { 
		//if (getType($1->node) != DATA_NUMBER || getType($3->node) != DATA_NUMBER) yyerror(*code, "Logic operations must involve numbers");
		$$ = operation($1, $2, $3); 
	}
	;

one_op:
	  SUM_ONE		{ strcpy($$, "++"); }
	| SUBTRACT_ONE	{ strcpy($$, "--"); }
	;

one_operation:
	variable one_op { 
		//if (getType($1->node) != DATA_NUMBER) yyerror(*code, "Must only use ++ or -- with numbers");
		$$ = single_operation($1, $2); 
	}
	;

assign_op:
	  ASSIGN 			{ strcpy($$, "="); }
	| ASSIGN_SUM 		{ strcpy($$,"+="); }
	| ASSIGN_SUBTRACT	{ strcpy($$,"-="); }
	| ASSIGN_DIV		{ strcpy($$,"/="); }
	| ASSIGN_MULTI		{ strcpy($$,"*="); }
	;
code
assign_operation:
	  variable assign_op expression { $$ = operation($1, $2, $3);  }
	| variable assign_op math_block  { $$ = operation($1, $2, $3); }
	| variable assign_op slope_block { $$ = operation($1, $2, $3); }


math_block:
	  SUMMATION OPEN_PARENTHESES math_condition CLOSE_PARENTHESES SEMI_COLON
	| SUMMATION OPEN_PARENTHESES math_condition CLOSE_PARENTHESES braces SEMI_COLON
	| PRODUCT OPEN_PARENTHESES math_condition CLOSE_PARENTHESES SEMI_COLON
	| PRODUCT OPEN_PARENTHESES math_condition CLOSE_PARENTHESES braces SEMI_COLON

math_condition:
	NUMBER_VAL SEMI_COLON expression SEMI_COLON NUMBER_VAL
	;

slope_block:
	SLOPE OPEN_PARENTHESES COORDINATES COMA COORDINATES CLOSE_PARENTHESES SEMI_COLON
	;

%%

void 
yyerror(ListNode ** code, char *s) {
	fprintf(stderr, "%s\n", s);
	printf("-------------\n%s in line %d\n-------------\n", s, yylineno);
	exit(EXIT_FAILURE);
}

// do these validations go here??????????
int
getType(Node *node) {
	return node->data;
}

void
matchingType(int type1, int type2) {
	if (type1 != type2) {
		yyerror(*code, "Declaration and definition types do not match.\n");
	}
}

int
main(void) {
	/* Initializing global variable structure */
	variables = (variableStorage *)malloc(sizeof *variable);
	if (variables == NULL) {
		fprintf(stderr, "Unable to allocate memory for variables\n");
		exit(EXIT_FAILURE);
	}
}