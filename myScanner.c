%{
#include "myScanner.h"
}

digit		[0-9]
decimal		-?[0-9]+\.[0-9]+
integer 	-?[0-9]+
variable 	[a-zA-Z][a-zA-Z0-9]*
coordinates \(-?[0-9]+,-?[0-9]+\)
new_line 	\n

%%
"if"					return IF;
"else"					return ELSE;
"do"					return DO;
"while"					return WHILE;
"print"					return PRINT;
"(' ')?+=(' ')?"		return ASSIGN_SUM;
"(' ')?*=(' ')?"		return ASSIGN_MULTI;
"(' ')?\\=(' ')?"		return ASSIGN_DIV;
"(' ')?-=(' ')?"		return ASSIGN_SUBTRACT;
"(' ')?+(' ')?"     	return SUM;;
"++" 					return SUM_ONE;
"(' ')?*(' ')?"			return MULTI;
"(' ')?/(' ')?"			return DIV;
"(' ')?-(' ')?"			return SUBTRACT;
"--"					return SUBTRACT_ONE;
"(' ')?%%(' ')?"		return MODULE;
"(' ')?=(' ')?"   	 	return ASSIGN;
"product of"			return PRODUCT_OF;
"sum of"				return SUM_OF;
"summation"				return SUMMATION;
"product"				return PRODUCT;
"slope"					return SLOPE;
"!"						return FACTORIAL;
"function"				return FUNCTION; //NO SE SI VA ESTA?
"(' ')?==(' ')?"		return EQUAL_OP;
"(' ')?!=(' ')?"		return NOT_EQUAL_OP;
"(' ')?>(' ')?"			return GT_OP;
"(' ')?>=(' ')?"		return GTE_OP;
"(' ')?<(' ')?"			return LT_OP;
"(' ')?<=(' ')?"		return LTE_OP;
"(' ')?&&(' ')?"		return AND_OP;
"(' ')?||(' ')?"		return OR_OP;
":"						return COMA;
";"						return SEMI_COLON;
("{")					return OPEN_BRACES;
("}")					return CLOSE_BRACES;
"("						return OPEN_PARENTHESES;
")"						return CLOSE_PARENTHESES;

/* to do --> involves yacc and idk that yet */
{integer} 
{decimal}
{coordinates}
{variable}
{new_line}

	
%%
int yywrap(void) {
	return 1;
}