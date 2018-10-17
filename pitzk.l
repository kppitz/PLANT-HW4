%{
//Definitions

%}

/* Regular Expression Definitions */

WSPACE    [ \t\r]+
NEWLINE   \n

DIGIT     [0-9]
LETTER    [a-zA-Z]

IDENT     ({LETTER}|_)({LETTER}|{DIGIT}|_)*
INTCONST  [+-]?{DIGIT}+
STRCONST  \"[^\"\n]*\"

COMMENT   ";".*$

%%

{NEWLINE}     { numLines++; }

{WSPACE}      { }

{COMMENT}     { }

"let*"        {
                printTokenInfo("LETSTAR", yytext);
                beginScope();
                return T_LETSTAR;
              }

"lambda"      {
                printTokenInfo("LAMBDA", yytext);
                beginScope();
                return T_LAMBDA;
              }

"input"       {
                printTokenInfo("INPUT", yytext);
                return T_INPUT;
              }

"print"       {
                printTokenInfo("PRINT", yytext);
                return T_PRINT;
              }

"if"          {
                printTokenInfo("IF", yytext);
                return T_IF;
              }

"and"         {
                printTokenInfo("AND", yytext);
                return T_AND;
              }

"or"          {
                printTokenInfo("OR", yytext);
                return T_OR;
              }

"not"         {
                printTokenInfo("NOT", yytext);
                return T_NOT;
              }

"t"           {
                printTokenInfo("T", yytext);
                return T_T;
              }

"nil"         {
                printTokenInfo("NIL", yytext);
                return T_NIL;
              }

"("           {
                printTokenInfo("LPAREN", yytext);
                return T_LPAREN;
              }

")"           {
                printTokenInfo("RPAREN", yytext);
                return T_RPAREN;
              }

"+"           {
                printTokenInfo("ADD", yytext);
                return T_ADD;
              }

"*"           {
                printTokenInfo("MULT", yytext);
                return T_MULT;
              }

"/"           {
                printTokenInfo("DIV", yytext);
                return T_DIV;
              }

"-"           {
                printTokenInfo("SUB", yytext);
                return T_SUB;
              }

"<"           {
                printTokenInfo("LT", yytext);
                return T_LT;
              }

">"           {
                printTokenInfo("GT", yytext);
                return T_GT;
              }

"="           {
                printTokenInfo("EQ", yytext);
                return T_EQ;
              }

"/="          {
                printTokenInfo("NE", yytext);
                return T_NE;
              }

"<="          {
                printTokenInfo("LE", yytext);
                return T_LE;
              }

">="          {
                printTokenInfo("GE", yytext);
                return T_GE;
              }

{INTCONST}    {
                printTokenInfo("INTCONST", yytext);
                return T_INTCONST;
              }

{STRCONST}    {
                printTokenInfo("STRCONST", yytext);
                return T_STRCONST;
              }

{IDENT}       {
                yylval.text = strdup(yytext);
                printTokenInfo("IDENT", yytext);
                return T_IDENT;
              }

.             {
                printTokenInfo("UNKNOWN", yytext);
                return T_UNKNOWN;
              }


%%
