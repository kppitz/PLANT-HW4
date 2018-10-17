#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H
//Type Codes
#define NOT_APPLICABLE      -2
#define UNDEFINED           -1
#define FUNCTION            0
#define INT                 1
#define STR                 2
#define INT_OR_STR          3
#define BOOL                4
#define INT_OR_BOOL         5
#define STR_OR_BOOL         6
#define INT_OR_STR_OR_BOOL  7

#define ARITH_OP             11
#define LOG_OP               12
#define REL_OP               13

#include <map>
#include <string>
#include "SymbolTableEntry.h"
using namespace std;

typedef struct {
  int type;
  int numParams;
  int returnType;
  int opType;
} TYPE_INFO;

class SYMBOL_TABLE 
{
private:
  std::map<string, SYMBOL_TABLE_ENTRY> hashTable;

public:
  //Constructor
  SYMBOL_TABLE( ) { }

  // Add SYMBOL_TABLE_ENTRY x to this symbol table.
  // If successful, return true; otherwise, return false.
  bool addEntry(SYMBOL_TABLE_ENTRY x) 
  {
    // Make sure there isn't already an entry with the same name
    map<string, SYMBOL_TABLE_ENTRY>::iterator itr;
    if ((itr = hashTable.find(x.getName())) == hashTable.end()) 
    {
      hashTable.insert(make_pair(x.getName(), x));
      return(true);
    }
    else return(false);
  }

  // If a SYMBOL_TABLE_ENTRY with name theName is
  // found in this symbol table, then return true;
  // otherwise, return false.
  bool findEntry(string theName) 
  {
    map<string, SYMBOL_TABLE_ENTRY>::iterator itr;
    if ((itr = hashTable.find(theName)) == hashTable.end())
      return(false);
    else return(true);
  }

  SYMBOL_TABLE_ENTRY getEntry(string theName)
  {
    return hashTable.find(theName)->second;
  }

  int getSize()
  {
    return hashTable.size();
  }

};

#endif  // SYMBOL_TABLE_H
