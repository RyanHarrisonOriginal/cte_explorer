import sqlglot
import sqlglot.expressions as exp
from sql_formatter.core import format_sql

class CTEParser():
    def __init__(self, cte_code):
        self.cte_code = cte_code
        self.model = {}
        
    @staticmethod
    def table_ref(table):
        return "{0}.{1}".format(table.text("db"),table.text("this")) if table.text("db") else table.text("this")

    @staticmethod
    def select_star():
        return [{"name":'all',"sql":'*'}]

    def find_columns(self,select_statement):
        column_names = []
        for expression in select_statement:
            if isinstance(expression, exp.Alias):
                column_names.append({"name":expression.text("alias"),"sql":expression.sql()})
            elif isinstance(expression, exp.Column):
                column_names.append({"name":expression.text("this"),"sql":expression.sql()})
        return column_names if column_names else self.select_star()

    def find_tables(self,table_statement):
        cols = []
        if isinstance(table_statement, exp.From):
            for tables in table_statement.find_all(exp.Table):
                    cols.append(self.table_ref(tables))
        if isinstance(table_statement, list):
            for joins in table_statement:
                for tables in joins.find_all(exp.Table):
                    cols.append(self.table_ref(tables))
        return cols

    def run(self):
        for cte in sqlglot.parse_one(self.cte_code).find(exp.With).args['expressions']:
            
            cte_sql = format_sql(cte.sql().split(' ',2)[-1], max_len=15)
            cte_columns = []
            cte_tables = []
            cte_name = cte.find(exp.TableAlias).text("this")
        
            for selects in cte.find_all(exp.Select):
                cte_columns = self.find_columns(selects.args['expressions'])
                cte_tables.extend(self.find_tables(selects.args['from']))
                if selects.args['joins']: cte_tables.extend(self.find_tables(selects.args['joins'])) 

            self.model[cte_name] = {
                    "id": cte_name,
                    "parentIds": list(set(cte_tables)),
                    "sql": cte_sql,
                    "cols": cte_columns
                }
    
        base_tables = {}
        for _, model in self.model.items():
            for parent in model['parentIds']:
                if parent not in self.model:
                    base_tables[parent] = {
                        "id": parent,
                        "sql": f"select * from {parent}",
                        "cols": self.select_star()
                        }
            
        self.model.update(base_tables)

        self.model = [v for _,v in self.model.items()]
    
