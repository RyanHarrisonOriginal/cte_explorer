import sys
import sqlglot
import sqlglot.expressions as exp
from sql_formatter.core import format_sql
from sqlglot import ParseError
import traceback
import re
from cte_parser_syntax_removal import SQL_SYNTAX_REMOVAL


class CTEParser():
    def __init__(self, cte_code):
        self.cte_code = cte_code
        self.model = {}


    @staticmethod
    def table_ref(table):
        """
        creates table refrence by concatinating database name and table names
        if database name is not available, we only return the table name
        """
        return "{0}.{1}".format(table.text("db"), table.text("this")) if table.text("db") else table.text("this")

    @staticmethod
    def select_star():
        """
        generic column dict when select * is present
        """
        return [{"name": 'all', "sql": '*'}]

    def find_columns(self, select_statement):
        """
        finds all columns in select statement
        """
        column_names = []
        for expression in select_statement:
            if isinstance(expression, exp.Alias):
                column_names.append(
                    {"name": expression.text("alias"), "sql": expression.sql()})
            elif isinstance(expression, exp.Column):
                column_names.append(
                    {"name": expression.text("this"), "sql": expression.sql()})
        return column_names if column_names else self.select_star()

    def find_tables(self, table_statement):
        """
        find all tables in the from clause
        """
        table_names = []
        if isinstance(table_statement, exp.From):
            for tables in table_statement.find_all(exp.Table):
                table_names.append(self.table_ref(tables))
        if isinstance(table_statement, list):
            for joins in table_statement:
                for tables in joins.find_all(exp.Table):
                    table_names.append(self.table_ref(tables))
        return table_names

    def update_model(self, model, cte_name: str, tables: list, cols: list, sql: str):
        """
        add new cte to the final dict
        will set table to [] if cte is same name as table
        """
        if len(tables) == 1 and tables[0] == cte_name: tables = []

        model[cte_name] = {
            "id": cte_name,
            "parentIds": tables,
            "sql": sql,
            "cols": cols
        }
        return None

    def add_base_tables_roots(self):
        base_tables = {}
        for _, model in self.model.items():

            parents = model['parentIds']
    
            for parent in parents:
                if parent not in self.model:
                    self.update_model(
                        base_tables, 
                        parent, 
                        [], 
                        self.select_star(), 
                        f"select * from {parent}")
        
        self.model.update(base_tables)
        return None

    def finalize_model_format(self):
        self.model = [v for _, v in self.model.items()]

    def scrub_query(self):
        for syntax, replacement in SQL_SYNTAX_REMOVAL:
            self.cte_code = re.sub(syntax, replacement, self.cte_code)

    def run(self):

        self.scrub_query()

        try:
            cte_collection = sqlglot.parse_one(
                self.cte_code).find(exp.With).args['expressions']
        except ParseError:
            etype, evalue, tb = sys.exc_info()
            msg = ' '.join(traceback.format_exception_only(etype, evalue))
            return (False, msg)

        for cte in cte_collection:

            cte_sql = format_sql(cte.sql().split(' ', 2)[-1], max_len=15)
            cte_columns = []
            cte_tables = []
            cte_name = cte.find(exp.TableAlias).text("this")

            for selects in cte.find_all(exp.Select):
                cte_columns = self.find_columns(selects.args['expressions'])
                cte_tables.extend(self.find_tables(selects.args['from']))
                if selects.args['joins']:
                    cte_tables.extend(self.find_tables(selects.args['joins']))

            self.update_model(
                self.model,
                cte_name, 
                list(set(cte_tables)), 
                cte_columns, 
                cte_sql)

        self.add_base_tables_roots()
        self.finalize_model_format()

        return (True, "Success")
