#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "nodesInitializer.h"

static void isValid(void *ptr);

StringNode *
string(const char *string)
{
    StringNode *node = malloc(sizeof *node);
    if(!isValid(node)) return NULL;

    node->type   = TYPE_STRING;
    node->string = calloc(strlen(string) + 1, sizeof(char));
    if(!isValid(node->string)) return node;
    
    strcpy(node->string, string);
    return node;
}

ConstantNode *
constant(const char *constant)
{
    ConstantNode *node = malloc(sizeof *node);
    if(!isValid(node)) return NULL;

    node->type     = TYPE_CONSTANT;
    node->constant = calloc(strlen(constant) + 1, sizeof(char));
    if(!isValid(node->constant)) return node;

    strcpy(node->constant, constant);
    return node;
}

VariableNode *
variable(const char *var)
{
    VariableNode *node = malloc(sizeof *node);
    if (!isValid(node)) return NULL;

    node->type     = TYPE_VARIABLE;
    node->stored   = NULL;
    node->declared = FALSE;
    node->name     = calloc(strlen(var) + 1, sizeof(char));
    if (!isValid(node->name)) return node;

    strcpy(node->name, var);
    return node;
}

OperationNode *
operation(const Node *first, const Node *second, const char *oper)
{
    OperationNode *node = malloc(sizeof *node);
    if(!isValid(node)) return NULL;

    node->type   = TYPE_OPERATION;
    node->first  = (Node *)first;
    node->second = (Node *)second;
    node->op     = calloc(strlen(oper) + 1, sizeof(char));
    if(!isValid(node->op)) return node;

    strcpy(node->op, oper);
    return node;
}

SingleOperationNode *
singleOperation(const Node *node, const char *oper) {
    SingleOperationNode *node = malloc(sizeof *node);
    if(!isValid(node)) return NULL;

    node->type = TYPE_SINGLE_OPERATION;
    node->node = (Node *)node;
    node->op   = calloc(3, sizeof(char)); /* 2 for the operation and 1 for the 0 */
    if(!isValid(node->op)) return node;

    strcpy(node->op, oper);
    return node;
}

IfNode *
ifNode(const Node *condition, const Node *elifN, const Node *elseN)
{
    IfNode *node    = malloc(sizeof *node);
    if(!isValid(node)) return NULL;
    node->type      = TYPE_IF;
    node->condition = (Node *)condition;
    node->elifNode  = (Node *)elifN;
    node->elseNode  = (Node *)elseN;
    return node;
}

CalculateWhileNode *
while(const Node *condition, const Node *block)
{
    CalculateWhileNode *node = malloc(sizeof *node);
    if(!isValid(node)) return NULL;

    node->type      = TYPE_WHILE;
    node->condition = (Node *)condition;
    node->block     = (Node *)block;
    return node;
}

ListNode *
instructionsList(const Node *node)
{
    ListNode *list = malloc(sizeof *list);
    if(!isValid(list)) return NULL;
    list->type = TYPE_INSTRUCTIONS;
    list->node = (Node *)node;
    list->next = NULL;
    return list;
}

ListNode *
addInstruction(const ListNode *list, const Node *node)
{
    ListNode *currentNode = (ListNode *)list;
    /* Move to the end of the list */
    while (currentNode->next != NULL) {
        currentNode = currentNode->next;
    }
    /* Add the node at the end */
    currentNode->next = instructionsList(node);

    return (ListNode *)list;
}

ReturnNode *
returnNode(const Node *expression)
{
    ReturnNode *node = malloc(sizeof *node);
    if(!isValid(node)) return NULL;
 
    node->type       = TYPE_RETURN;
    node->expression = (Node *)expression;
    return node;
}

BlockNode *
block(const ListNode *instructions)
{
    BlockNode *node    = malloc(sizeof *node);
    if(!isValid(node)) return NULL;
    node->type         = TYPE_BLOCK;
    node->instructions = (ListNode *)instructions;
    return node;
}

Node *empty()
{
    Node *node = malloc(sizeof *node);
    if(!isValid(node)) return NULL;
    node->type = TYPE_NULL;
    return node;
}

InstructionNode *
instruction(Node *instruction)
{
    InstructionNode *node = malloc(sizeof *node);
    if(!isValid(node)) return NULL;

    node->type        = TYPE_INSTRUCTION;
    node->instruction = instruction;
    return node;
}

NegationNode *
negation(Node *expression)
{
    NegationNode *node = malloc(sizeof *node);
    if(!isValid(node)) return NULL;
    node->type         = TYPE_NEGATION;
    node->expression   = expression;
    return node;
}

PrintNode *
print(Node *expression)
{
    PrintNode *node  = malloc(sizeof *node);
    if(!isValid(node)) return NULL;
    node->type       = TYPE_PRINT;
    node->expression = expression;
    return node;
}

static int
isValid(void *ptr) {
    if (ptr == NULL) {
        fprintf(stderr, "Error allocating heap space\n");
        return 0;
    }
    return 1;
}