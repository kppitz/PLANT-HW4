%{
#include <stdio.h>
#include <stack>
#include "SymbolTable.h"
#include <iostream>

using namespace std;

int numLines = 1;
int numParams = 0;
stack <SYMBOL_TABLE> scopeStack;

void printRule(const char *lhs, const char *rhs);
int yyerror(const char *s);
void printTokenInfo(const char* tokenType, const char* lexeme);
bool findEntryInAnyScope(const string theName);
int getEntryTypeCode(const string theName);
void beginScope();
void endScope();

extern "C" {
              int yyparse(void);
              int yylex(void);
              int yywrap() { return 1; }
          }
%}

/* Token declarations */
%token T_IDENT T_INTCONST T_STRCONST T_LETSTAR T_LAMBDA T_INPUT T_PRINT  T_IF
T_LPAREN T_RPAREN T_ADD T_MULT T_DIV T_SUB T_AND T_OR T_NOT T_LT T_GT T_LE T_GE
T_EQ T_NE T_T T_NIL T_UNKNOWN

%type <text> T_IDENT
%type <typeInfo> N_CONST N_EXPR N_PARENTHESIZED_EXPR N_IF_EXPR 
N_ARITHLOGIC_EXPR N_BIN_OP N_LET_EXPR N_LAMBDA_EXPR N_PRINT_EXPR N_EXPR_LIST 
N_INPUT_EXPR N_ID_EXPR_LIST N_ID_LIST

/*union data structure */
%union
{
  char* text;
  TYPE_INFO typeInfo;
};

/* Starting point */
%start N_START

/* Translation rules */
%%
N_START : N_EXPR
          {
            printRule ("START", "EXPR");
            printf("\n---- Completed parsing ----\n\n");
            return 0;
            }
            ;

N_EXPR : N_CONST
          {
            printRule("EXPR", "CONST");
            $$.type = $1.type;
            $$.numParams = $1.numParams;
            $$.returnType = NOT_APPLICABLE;
          }
          | T_IDENT
          {
            printRule("EXPR", "IDENT");
            $$.type = getEntryTypeCode(string($1));
            $$.numParams = NOT_APPLICABLE;
            $$.returnType = NOT_APPLICABLE;
            bool found = findEntryInAnyScope(string($1));
            if(!found)
              yyerror("Undefined identifier");
          }
          | T_LPAREN N_PARENTHESIZED_EXPR T_RPAREN
          {
            printRule("EXPR", "( PARENTHESIZED_EXPR )");
            $$.type = $2.type;
            $$.numParams = $2.numParams;
            $$.returnType = $2.returnType;
          }
          ;

N_CONST : T_INTCONST
          {
            printRule("CONST", "INTCONST");
            $$.type = INT;
            $$.numParams = 1;
            $$.returnType = NOT_APPLICABLE;
          }
          | T_STRCONST
          {
            printRule("CONST", "STRCONST");
            $$.type = STR;
            $$.numParams = 1;
            $$.returnType = NOT_APPLICABLE;
          }
          | T_T
          {
            printRule("CONST", "t");
            $$.type = BOOL;
            $$.numParams = 1;
            $$.returnType = NOT_APPLICABLE;
          }
          | T_NIL
          {
            printRule("CONST", "nil");
            $$.type = BOOL;
            $$.numParams = 1;
            $$.returnType = NOT_APPLICABLE;
          }
          ;

N_PARENTHESIZED_EXPR : N_ARITHLOGIC_EXPR
                      {
                        printRule("PARENTHESIZED_EXPR", "ARITHLOGIC_EXPR");
                        $$.type = $1.type;
                        $$.numParams = $1.numParams;
                        $$.returnType = $1.returnType;
                      }
                      | N_IF_EXPR
                      {
                        printRule("PARENTHESIZED_EXPR", "IF_EXPR");
                        $$.type = $1.type;
                        $$.numParams = $1.numParams;
                        $$.returnType = $1.returnType;
                      }
                      | N_LET_EXPR
                      {
                        printRule("PARENTHESIZED_EXPR", "LET_EXPR");
                        $$.type = $1.type;
                        $$.numParams = $1.numParams;
                        $$.returnType = $1.returnType;
                      }
                      | N_LAMBDA_EXPR
                      {
                        printRule("PARENTHESIZED_EXPR", "LAMBDA_EXPR");
                        $$.type = FUNCTION;
                        $$.numParams = $1.numParams;
                        $$.returnType = $1.returnType;
                      }
                      | N_PRINT_EXPR
                      {
                        printRule("PARENTHESIZED_EXPR", "PRINT_EXPR");
                        $$.type = $1.type;
                        $$.numParams = $1.numParams;
                        $$.returnType = $1.returnType;
                      }
                      | N_INPUT_EXPR
                      {
                        printRule("PARENTHESIZED_EXPR", "INPUT_EXPR");
                        $$.type = $1.type;
                        $$.numParams = $1.numParams;
                        $$.returnType = $1.returnType;
                      }
                      | N_EXPR_LIST
                      {
                        printRule("PARENTHESIZED_EXPR", "EXPR_LIST");
                        $$.type = $1.type;
                        $$.numParams = $1.numParams;
                        $$.returnType = $1.returnType;
                      }
                      ;

N_ARITHLOGIC_EXPR : N_UN_OP N_EXPR
                  {
                    printRule("ARITHLOGIC_EXPR", "UN_OP EXPR");
                    if($2.type == FUNCTION)
                    {
                      yyerror("Arg 1 cannot be function");
                      return(1);
                    }
                    $$.type = $2.type;
                    $$.numParams = NOT_APPLICABLE;
                    $$.returnType = NOT_APPLICABLE;
                  }
                  | N_BIN_OP N_EXPR N_EXPR
                  {
                    printRule("ARITHLOGIC_EXPR", "BIN_OP EXPR EXPR");
                    if($1.opType == REL_OP)
                    {
                        if($2.type != INT && $2.type != STR && $2.type != INT_OR_STR)
                        {
                          yyerror("Arg 1 must be integer or string");
                          return(1);
                        }
                        if($3.type != INT && $3.type != STR && ($3.type & INT) == 0)
                        {
                          yyerror("Arg 2 must be integer or string");
                          return(1);                         
                        }
                        $$.type = BOOL;
                      }
                    else if($1.opType == LOG_OP)
                    {
                      if($2.type == FUNCTION)
                      {
                        yyerror("Arg 1 cannot be function");
                        return(1);
                      }
                      if($3.type == FUNCTION)
                      {
                        yyerror("Arg 2 cannot be function");
                        return(1);
                      }
                      $$.type = BOOL;
                    }
                    else if($1.opType == ARITH_OP)
                    {
                      // cout << "Type: " << $2.type << endl;
                      if(($2.type & INT) == 0)
                        {
                          yyerror("Arg 1 must be integer");
                          return(1);
                        }
                        if(($3.type & INT) == 0)
                        {
                          yyerror("Arg 2 must be integer");
                          return(1);                         
                        }
                      $$.type = INT;
                    }
                  }
                  ;

N_IF_EXPR : T_IF N_EXPR N_EXPR N_EXPR
            {
              printRule("IF_EXPR", "if EXPR EXPR EXPR");
              if($2.type == FUNCTION)
              {
                yyerror("Arg 1 cannot be function");
                return(1);
              }
              if ($3.type == FUNCTION)
              {
                yyerror("Arg 2 cannot be function");
                return(1);
              }
              if($4.type == FUNCTION)
              {
                yyerror("Arg 3 cannot be function");
                return(1);
              }
              $$.type = ($3.type | $4.type);
              $$.numParams = NOT_APPLICABLE;
              $$.returnType = NOT_APPLICABLE;
            }
            ;

N_LET_EXPR : T_LETSTAR T_LPAREN N_ID_EXPR_LIST T_RPAREN N_EXPR
            {
              printRule("LET_EXPR", "let* ( ID_EXPR_LIST ) EXPR");
              endScope();
              if($5.type == FUNCTION)
              {
                yyerror("Arg 2 cannot be function");
                return(1);
              }
              $$.type = $3.type;
              $$.numParams = $3.numParams;
              $$.returnType = $5.returnType;
            }
            ;

N_ID_EXPR_LIST : /* epsilon */
                {
                  printRule("ID_EXPR_LIST", "epsilon");
                }
                | N_ID_EXPR_LIST T_LPAREN T_IDENT N_EXPR T_RPAREN
                {
                  $$.type = $4.type;
                  $$.numParams = $4.numParams;
                  $$.returnType = $4.returnType;
                  printRule("ID_EXPR_LIST", "ID_EXPR_LIST ( IDENT EXPR )");
                  printf("___Adding %s to symbol table\n", $3);
                  if(!scopeStack.top().addEntry(SYMBOL_TABLE_ENTRY(string($3),
                    $4.type)))
                    yyerror("Multiply defined identifier");
                  numParams++;
                }
                ;

N_LAMBDA_EXPR : T_LAMBDA T_LPAREN N_ID_LIST T_RPAREN N_EXPR
                {
                  printRule("LAMBDA_EXPR", "lambda ( ID_LIST ) EXPR");
                  $$.type = FUNCTION;
                  $$.numParams = scopeStack.top().getSize();
                  endScope();
                  if($5.type == FUNCTION)
                  {
                    yyerror("Arg 2 cannot be function");
                    return(1);
                  }
                  $$.returnType = $5.type;
                }
                ;

N_ID_LIST : /* epsilon */
            {
              printRule("ID_LIST", "epsilon");
              numParams = 0;
            }
            | N_ID_LIST T_IDENT
            {
              $$.type = FUNCTION;
              printRule("ID_LIST", "ID_LIST IDENT");
              printf("___Adding %s to symbol table\n", $2);
              if(!scopeStack.top().addEntry(SYMBOL_TABLE_ENTRY(string($2),
                INT)))
                yyerror("Multiply defined identifier");
              numParams++;
            }
            ;

N_PRINT_EXPR : T_PRINT N_EXPR
              {
                printRule("PRINT_EXPR", "print EXPR");
                if($2.type == FUNCTION)
                {
                  yyerror("Arg 1 cannot be function");
                  return(1);
                }
                $$.type = $2.type;
                $$.numParams = NOT_APPLICABLE;
                $$.returnType = NOT_APPLICABLE;
              }
              ;

N_INPUT_EXPR : T_INPUT
              {
                printRule("INPUT_EXPR", "input");
                $$.type = INT_OR_STR;
                $$.numParams = NOT_APPLICABLE;
                $$.returnType = NOT_APPLICABLE;
              }
              ;

N_EXPR_LIST : N_EXPR N_EXPR_LIST
              {
                printRule("EXPR_LIST", "EXPR EXPR_LIST");
                if($2.type == FUNCTION)
                {
                  yyerror("Arg 2 cannot be function");
                  return(1);
                }
                $$.type = $2.type;
                $$.numParams = $2.numParams;
                $$.returnType = $1.returnType;
                if($1.type == FUNCTION)
                {
                  cout << "EXPR: " << $1.numParams << endl;
                  cout << "EXPR_LIST: " << $2.numParams << endl;
                  if($1.numParams < numParams)
                  {
                    yyerror("Too few parameters in function call");
                    return(1);
                  }
                  else if($1.numParams > numParams)
                  {
                    yyerror("Too many parameters in function call");
                    return(1);
                  }
                }
              }
              | N_EXPR
              {
                printRule("EXPR_LIST", "EXPR ");
                if ($1.type == FUNCTION) {
                  $$.type = $1.returnType;
                }
                else {
                  $$.type = $1.type;
                }
              }
              ;

N_BIN_OP : N_ARITH_OP
          {
            printRule("BIN_OP", "ARITH_OP");
            $$.opType = ARITH_OP;
          }
          | N_LOG_OP
          {
            printRule("BIN_OP", "LOG_OP");
            $$.opType = LOG_OP;
          }
          | N_REL_OP
          {
            printRule("BIN_OP", "REL_OP");
            $$.opType = REL_OP;
          }
          ;

N_ARITH_OP : T_MULT
            {
              printRule("ARITH_OP", "*");
            }
            | T_SUB
            {
              printRule("ARITH_OP", "-");
            }
            | T_DIV
            {
              printRule("ARITH_OP", "/");
            }
            | T_ADD
            {
              printRule("ARITH_OP", "+");
            }
            ;

N_LOG_OP : T_AND
            {
              printRule("LOG_OP", "and");
            }
            | T_OR
            {
              printRule("LOG_OP", "or");
            }
            ;

N_REL_OP : T_LT
          {
            printRule("REL_OP", "<");
          }
          | T_GT
          {
            printRule("REL_OP", ">");
          }
          | T_LE
          {
            printRule("REL_OP", "<=");
          }
          | T_GE
          {
            printRule("REL_OP", ">=");
          }
          | T_EQ
          {
            printRule("REL_OP", "=");
          }
          | T_NE
          {
            printRule("REL_OP", "/=");
          }
          ;

N_UN_OP : T_NOT
          {
            printRule("UN_OP", "not");
          }
          ;
%%

#include "lex.yy.c"
extern FILE *yyin;

void printRule(const char *lhs, const char *rhs)
{
 printf("%s -> %s\n", lhs, rhs);
 return;
}

int yyerror(const char *s)
{
 printf("Line %d: %s\n", numLines, s);
 exit(1);
}

void printTokenInfo(const char* tokenType, const char* lexeme)
{
 printf("TOKEN: %s  LEXEME: %s\n", tokenType, lexeme);
}

void beginScope()
{
  scopeStack.push(SYMBOL_TABLE());
  printf("\n___Entering new scope...\n\n");
}

void endScope()
{
  scopeStack.pop();
  printf("\n___Exiting scope...\n\n");
  numParams = 0;
}

bool findEntryInAnyScope(const string theName)
{
  if (scopeStack.empty( )) return(false);
    bool found = scopeStack.top( ).findEntry(theName);
  if (found)
    return(true);
  else { // check in "next higher" scope
    SYMBOL_TABLE symbolTable = scopeStack.top( );
    scopeStack.pop( );
    found = findEntryInAnyScope(theName);
    scopeStack.push(symbolTable); // restore the stack
    return(found);
    }
}

int getEntryTypeCode(const string theName)
{
  if (scopeStack.empty())
  {
    return -1;
  }
  else {
    auto code = scopeStack.top().getEntry(theName).getTypeCode();
    // cout << "Name: " << theName << "\nCode: " << code << endl;
    return code;
  }

}

int main() {
 do
  {
    yyparse();
  } while (!feof(yyin));

 return(0);
}
